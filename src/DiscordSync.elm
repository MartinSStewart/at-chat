module DiscordSync exposing
    ( addDiscordChannel
    , addUploadResponsesToDiscordAttachments
    , attachmentsToFileData
    , backendSessionIdHash
    , discordUserWebsocketMsg
    , getManyMessages
    , handleCreateMessage
    , handleEditMessage
    , http
    , messagesAndLinks
    , reloadChannelMaxMessages
    , sendMessage
    , uploadAttachmentsForMessages
    , websocketClose
    , websocketCreateHandle
    )

import Array exposing (Array)
import Array.Extra
import BackendExtra
import Broadcast
import Bytes exposing (Bytes)
import ChannelDescription
import ChannelName exposing (ChannelName)
import Discord exposing (OptionalData(..))
import Discord.Markdown
import DiscordAttachmentId exposing (DiscordAttachmentId)
import DiscordUserData exposing (DiscordFullUserData, DiscordUserData(..))
import DmChannel
import Duration
import Effect.Command as Command exposing (BackendOnly, Command)
import Effect.Http as Http
import Effect.Lamdera as Lamdera
import Effect.Process as Process
import Effect.Task as Task exposing (Task)
import Effect.Time as Time
import Effect.Websocket as Websocket
import Emoji exposing (Emoji)
import Env
import FileName
import FileStatus exposing (FileData, FileHash, FileId)
import GuildName
import Id exposing (AnyGuildOrDmId(..), ChannelMessageId, DiscordGuildOrDmId(..), Id, StickerId, ThreadMessageId, ThreadRoute(..), ThreadRouteWithMaybeMessage(..), ThreadRouteWithMessage(..))
import Json.Decode
import Json.Encode
import List.Extra
import List.Nonempty exposing (Nonempty(..))
import LocalState exposing (ChannelStatus(..), DiscordBackendChannel, DiscordBackendGuild, DiscordMessageAlreadyExists(..))
import Log
import MembersAndOwner exposing (MembersAndOwner)
import Message exposing (ChangeAttachments(..), Message(..))
import NonemptyDict exposing (NonemptyDict)
import OneToOne exposing (OneToOne)
import PersonName
import Quantity
import RichText exposing (RichText(..))
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import SessionIdHash exposing (SessionIdHash)
import Sticker exposing (StickerData, StickerUrl(..))
import Thread exposing (DiscordBackendThread)
import Types exposing (BackendModel, BackendMsg(..), DiscordAttachmentData, LocalChange(..), LocalMsg(..), ServerChange(..), ToFrontend(..))
import User


addOrRemoveDiscordReaction :
    Bool
    ->
        { a
            | userId : Discord.Id Discord.UserId
            , channelId : Discord.Id Discord.ChannelId
            , messageId : Discord.Id Discord.MessageId
            , guildId : OptionalData (Discord.Id Discord.GuildId)
            , emoji : Discord.EmojiData
        }
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
addOrRemoveDiscordReaction isAdding reaction model =
    case reaction.guildId of
        Included guildId ->
            case SeqDict.get guildId model.discordGuilds of
                Just guild ->
                    case discordChannelIdToChannelId reaction.channelId reaction.messageId guild of
                        Just ( channelId, channel, threadRoute ) ->
                            let
                                emoji : Emoji
                                emoji =
                                    Emoji.fromDiscord reaction.emoji
                            in
                            ( { model
                                | discordGuilds =
                                    SeqDict.insert
                                        guildId
                                        { guild
                                            | channels =
                                                SeqDict.insert
                                                    channelId
                                                    (if isAdding then
                                                        LocalState.addReactionEmoji emoji reaction.userId threadRoute channel

                                                     else
                                                        LocalState.removeReactionEmoji emoji reaction.userId threadRoute channel
                                                    )
                                                    guild.channels
                                            , membersAndOwner =
                                                MembersAndOwner.addMember
                                                    reaction.userId
                                                    { joinedAt = Nothing }
                                                    guild.membersAndOwner
                                                    |> Result.withDefault guild.membersAndOwner
                                        }
                                        model.discordGuilds
                              }
                            , Broadcast.toDiscordGuild
                                guildId
                                ((if isAdding then
                                    Server_DiscordAddReactionGuildEmoji
                                        reaction.userId
                                        guildId
                                        channelId
                                        threadRoute
                                        emoji

                                  else
                                    Server_DiscordRemoveReactionGuildEmoji
                                        reaction.userId
                                        guildId
                                        channelId
                                        threadRoute
                                        emoji
                                 )
                                    |> ServerChange
                                )
                                model
                            )

                        Nothing ->
                            ( model, Command.none )

                Nothing ->
                    ( model, Command.none )

        Missing ->
            let
                dmChannelId : Discord.Id Discord.PrivateChannelId
                dmChannelId =
                    Discord.idToUInt64 reaction.channelId |> Discord.idFromUInt64
            in
            case SeqDict.get dmChannelId model.discordDmChannels of
                Just channel ->
                    case OneToOne.second reaction.messageId channel.linkedMessageIds of
                        Just messageId ->
                            let
                                emoji : Emoji
                                emoji =
                                    Emoji.fromDiscord reaction.emoji
                            in
                            ( { model
                                | discordDmChannels =
                                    SeqDict.updateIfExists
                                        dmChannelId
                                        (if isAdding then
                                            LocalState.addReactionEmojiHelper emoji reaction.userId messageId

                                         else
                                            LocalState.removeReactionEmojiHelper emoji reaction.userId messageId
                                        )
                                        model.discordDmChannels
                              }
                            , Broadcast.toDiscordDmChannel
                                dmChannelId
                                ((if isAdding then
                                    Server_DiscordAddReactionDmEmoji reaction.userId dmChannelId messageId emoji

                                  else
                                    Server_DiscordRemoveReactionDmEmoji reaction.userId dmChannelId messageId emoji
                                 )
                                    |> ServerChange
                                )
                                model
                            )

                        Nothing ->
                            ( model, Command.none )

                Nothing ->
                    ( model, Command.none )


handleDiscordRemoveAllReactions : Discord.ReactionRemoveAll -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleDiscordRemoveAllReactions _ model =
    ( model, Command.none )


handleDiscordRemoveReactionForEmoji : Discord.ReactionRemoveEmoji -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleDiscordRemoveReactionForEmoji _ model =
    ( model, Command.none )


handleDiscordDmEditMessage :
    Discord.UserMessageUpdate
    -> SeqDict (Id FileId) FileData
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleDiscordDmEditMessage edit attachments model =
    let
        channelId =
            Discord.idToUInt64 edit.channelId |> Discord.idFromUInt64
    in
    case SeqDict.get channelId model.discordDmChannels of
        Just channel ->
            case OneToOne.second edit.id channel.linkedMessageIds of
                Just messageIndex ->
                    let
                        richText : Nonempty (RichText (Discord.Id Discord.UserId))
                        richText =
                            RichText.fromDiscord edit.content attachments (Included edit.embeds)
                    in
                    case
                        LocalState.editMessageHelperNoThread
                            edit.timestamp
                            edit.author.id
                            richText
                            DoNotChangeAttachments
                            messageIndex
                            channel
                    of
                        Ok channel2 ->
                            ( { model
                                | discordDmChannels =
                                    SeqDict.insert channelId channel2 model.discordDmChannels
                              }
                            , Broadcast.toDiscordDmChannel
                                channelId
                                (Server_DiscordSendEditDmMessage
                                    edit.timestamp
                                    { currentUserId = edit.author.id, channelId = channelId }
                                    messageIndex
                                    richText
                                    |> ServerChange
                                )
                                model
                            )

                        Err _ ->
                            ( model, Command.none )

                _ ->
                    ( model, Command.none )

        Nothing ->
            ( model, Command.none )


discordChannelIdToChannelId :
    Discord.Id Discord.ChannelId
    -> Discord.Id Discord.MessageId
    -> DiscordBackendGuild
    -> Maybe ( Discord.Id Discord.ChannelId, DiscordBackendChannel, ThreadRouteWithMessage )
discordChannelIdToChannelId channelId messageId guild =
    case SeqDict.get channelId guild.channels of
        Just channel ->
            case OneToOne.second messageId channel.linkedMessageIds of
                Just messageId2 ->
                    Just ( channelId, channel, NoThreadWithMessage messageId2 )

                Nothing ->
                    Nothing

        Nothing ->
            List.Extra.findMap
                (\( channelId2, channel ) ->
                    case
                        List.Extra.findMap
                            (\( threadId, thread ) ->
                                case OneToOne.second messageId thread.linkedMessageIds of
                                    Just messageIndex ->
                                        Just ( threadId, messageIndex )

                                    Nothing ->
                                        Nothing
                            )
                            (SeqDict.toList channel.threads)
                    of
                        Just ( threadId, messageIndex ) ->
                            Just ( channelId2, channel, ViewThreadWithMessage threadId messageIndex )

                        Nothing ->
                            Nothing
                )
                (SeqDict.toList guild.channels)


discordChannelIdToChannelIdNoMessage :
    Discord.Id Discord.ChannelId
    -> DiscordBackendGuild
    -> Maybe ( Discord.Id Discord.ChannelId, DiscordBackendChannel, Maybe { threadId : Id ChannelMessageId, thread : DiscordBackendThread } )
discordChannelIdToChannelIdNoMessage channelId guild =
    case SeqDict.get channelId guild.channels of
        Just channel ->
            Just ( channelId, channel, Nothing )

        Nothing ->
            List.Extra.findMap
                (\( otherChannelId, channel ) ->
                    case
                        List.Extra.find
                            (\( threadId, _ ) ->
                                case OneToOne.first threadId channel.linkedMessageIds of
                                    Just discordThreadId ->
                                        Discord.idFromUInt64 (Discord.idToUInt64 discordThreadId) == channelId

                                    Nothing ->
                                        False
                            )
                            (SeqDict.toList channel.threads)
                    of
                        Just ( threadId, thread ) ->
                            Just ( otherChannelId, channel, Just { threadId = threadId, thread = thread } )

                        Nothing ->
                            Nothing
                )
                (SeqDict.toList guild.channels)


handleDiscordGuildEditMessage :
    Discord.Id Discord.GuildId
    -> DiscordBackendGuild
    -> Discord.UserMessageUpdate
    -> SeqDict (Id FileId) FileData
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleDiscordGuildEditMessage guildId guild edit attachments model =
    let
        richText : Nonempty (RichText (Discord.Id Discord.UserId))
        richText =
            RichText.fromDiscord edit.content attachments (Included edit.embeds)
    in
    case SeqDict.get edit.channelId guild.channels of
        Just channel ->
            case OneToOne.second edit.id channel.linkedMessageIds of
                Just messageIndex ->
                    case
                        LocalState.editMessageHelper
                            edit.timestamp
                            edit.author.id
                            richText
                            DoNotChangeAttachments
                            (NoThreadWithMessage messageIndex)
                            channel
                    of
                        Ok channel2 ->
                            ( { model
                                | discordGuilds =
                                    SeqDict.updateIfExists
                                        guildId
                                        (LocalState.updateChannel (\_ -> channel2) edit.channelId)
                                        model.discordGuilds
                              }
                            , Broadcast.toDiscordGuild
                                guildId
                                (Server_DiscordSendEditGuildMessage
                                    edit.timestamp
                                    edit.author.id
                                    guildId
                                    edit.channelId
                                    (NoThreadWithMessage messageIndex)
                                    richText
                                    |> ServerChange
                                )
                                model
                            )

                        Err _ ->
                            ( model, Command.none )

                _ ->
                    ( model, Command.none )

        Nothing ->
            let
                maybeThread : Maybe ( Discord.Id Discord.ChannelId, DiscordBackendChannel, ( Id ChannelMessageId, Id ThreadMessageId ) )
                maybeThread =
                    List.Extra.findMap
                        (\( channelId, channel ) ->
                            case
                                List.Extra.findMap
                                    (\( threadId, thread ) ->
                                        case OneToOne.second edit.id thread.linkedMessageIds of
                                            Just messageIndex ->
                                                Just ( threadId, messageIndex )

                                            Nothing ->
                                                Nothing
                                    )
                                    (SeqDict.toList channel.threads)
                            of
                                Just ( threadId, messageIndex ) ->
                                    Just ( channelId, channel, ( threadId, messageIndex ) )

                                Nothing ->
                                    Nothing
                        )
                        (SeqDict.toList guild.channels)
            in
            case maybeThread of
                Just ( channelId, channel, ( threadId, messageIndex ) ) ->
                    case
                        LocalState.editMessageHelper
                            edit.timestamp
                            edit.author.id
                            richText
                            DoNotChangeAttachments
                            (ViewThreadWithMessage threadId messageIndex)
                            channel
                    of
                        Ok channel2 ->
                            ( { model
                                | discordGuilds =
                                    SeqDict.updateIfExists
                                        guildId
                                        (LocalState.updateChannel (\_ -> channel2) channelId)
                                        model.discordGuilds
                              }
                            , Broadcast.toDiscordGuild
                                guildId
                                (Server_DiscordSendEditGuildMessage
                                    edit.timestamp
                                    edit.author.id
                                    guildId
                                    channelId
                                    (ViewThreadWithMessage threadId messageIndex)
                                    richText
                                    |> ServerChange
                                )
                                model
                            )

                        Err _ ->
                            ( model, Command.none )

                Nothing ->
                    ( model, Command.none )


handleDiscordDeleteGuildMessage :
    Discord.Id Discord.GuildId
    -> Discord.Id Discord.ChannelId
    -> Discord.Id Discord.MessageId
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleDiscordDeleteGuildMessage discordGuildId discordChannelId discordMessageId model =
    case SeqDict.get discordGuildId model.discordGuilds of
        Just guild ->
            let
                ( guild2, cmd ) =
                    case SeqDict.get discordChannelId guild.channels of
                        Just channel ->
                            case deleteMessageHelper discordMessageId channel of
                                Just ( messageId, channel2 ) ->
                                    ( { guild | channels = SeqDict.insert discordChannelId channel2 guild.channels }
                                    , Broadcast.toDiscordGuild
                                        discordGuildId
                                        (Server_DiscordDeleteGuildMessage
                                            discordGuildId
                                            discordChannelId
                                            (NoThreadWithMessage messageId)
                                            |> ServerChange
                                        )
                                        model
                                    )

                                Nothing ->
                                    ( guild, Command.none )

                        Nothing ->
                            List.Extra.findMap
                                (\( channelId, channel ) ->
                                    case
                                        OneToOne.second
                                            (Discord.idToUInt64 discordChannelId |> Discord.idFromUInt64)
                                            channel.linkedMessageIds
                                    of
                                        Just threadId ->
                                            case SeqDict.get threadId channel.threads of
                                                Just thread ->
                                                    case deleteMessageHelper discordMessageId thread of
                                                        Just ( messageId, thread2 ) ->
                                                            ( { guild
                                                                | channels =
                                                                    SeqDict.insert
                                                                        channelId
                                                                        { channel
                                                                            | threads =
                                                                                SeqDict.insert threadId thread2 channel.threads
                                                                        }
                                                                        guild.channels
                                                              }
                                                            , Broadcast.toDiscordGuild
                                                                discordGuildId
                                                                (Server_DiscordDeleteGuildMessage
                                                                    discordGuildId
                                                                    discordChannelId
                                                                    (ViewThreadWithMessage threadId messageId)
                                                                    |> ServerChange
                                                                )
                                                                model
                                                            )
                                                                |> Just

                                                        Nothing ->
                                                            Nothing

                                                Nothing ->
                                                    Nothing

                                        Nothing ->
                                            Nothing
                                )
                                (SeqDict.toList guild.channels)
                                |> Maybe.withDefault ( guild, Command.none )
            in
            ( { model | discordGuilds = SeqDict.insert discordGuildId guild2 model.discordGuilds }, cmd )

        Nothing ->
            ( model, Command.none )


deleteMessageHelper :
    Discord.Id Discord.MessageId
    -> { b | linkedMessageIds : OneToOne (Discord.Id Discord.MessageId) (Id messageId), messages : Array (Message messageId (Discord.Id Discord.UserId)) }
    ->
        Maybe
            ( Id messageId
            , { b | linkedMessageIds : OneToOne (Discord.Id Discord.MessageId) (Id messageId), messages : Array (Message messageId (Discord.Id Discord.UserId)) }
            )
deleteMessageHelper discordMessageId channel =
    case OneToOne.second discordMessageId channel.linkedMessageIds of
        Just messageId ->
            case DmChannel.getArray messageId channel.messages of
                Just (UserTextMessage message) ->
                    ( messageId
                    , { channel
                        | messages =
                            DmChannel.setArray
                                messageId
                                (DeletedMessage message.createdAt)
                                channel.messages
                      }
                    )
                        |> Just

                _ ->
                    Nothing

        Nothing ->
            Nothing


handleDiscordDeleteDmMessage :
    Discord.Id Discord.PrivateChannelId
    -> Discord.Id Discord.MessageId
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleDiscordDeleteDmMessage discordChannelId discordMessageId model =
    case SeqDict.get discordChannelId model.discordDmChannels of
        Just channel ->
            case deleteMessageHelper discordMessageId channel of
                Just ( messageId, channel2 ) ->
                    ( { model | discordDmChannels = SeqDict.insert discordChannelId channel2 model.discordDmChannels }
                    , Broadcast.toDiscordDmChannel
                        discordChannelId
                        (Server_DiscordDeleteDmMessage discordChannelId messageId |> ServerChange)
                        model
                    )

                Nothing ->
                    ( model, Command.none )

        Nothing ->
            ( model, Command.none )


addDiscordChannel : Discord.Channel -> Maybe DiscordBackendChannel
addDiscordChannel discordChannel =
    let
        isTextChannel : Bool
        isTextChannel =
            case discordChannel.type_ of
                Discord.GuildAnnouncement ->
                    True

                Discord.GuildText ->
                    True

                Discord.DirectMessage ->
                    True

                Discord.GuildVoice ->
                    False

                Discord.GroupDirectMessage ->
                    True

                Discord.GuildCategory ->
                    False

                Discord.AnnouncementThread ->
                    True

                Discord.PublicThread ->
                    True

                Discord.PrivateThread ->
                    True

                Discord.GuildStageVoice ->
                    False

                Discord.GuildDirectory ->
                    False

                Discord.GuildForum ->
                    False

                Discord.GuildMedia ->
                    False
    in
    if isTextChannel then
        { name =
            case discordChannel.name of
                Included name ->
                    ChannelName.fromStringLossy name

                Missing ->
                    ChannelName.fromStringLossy "Missing"
        , description = LocalState.discordTopicToDescription discordChannel.topic ChannelDescription.empty
        , messages = Array.empty
        , status = ChannelActive
        , lastTypedAt = SeqDict.empty
        , linkedMessageIds = OneToOne.empty
        , threads = SeqDict.empty
        }
            |> Just

    else
        Nothing


messagesAndLinks :
    List Discord.Message
    -> SeqDict DiscordAttachmentId DiscordAttachmentData
    ->
        ( Array (Message messageId (Discord.Id Discord.UserId))
        , OneToOne (Discord.Id Discord.MessageId) (Id messageId)
        )
messagesAndLinks messages discordAttachments =
    let
        linkedMessageIds : OneToOne (Discord.Id Discord.MessageId) (Id messageId)
        linkedMessageIds =
            List.indexedMap (\index message -> ( message.id, Id.fromInt index )) messages |> OneToOne.fromList
    in
    ( List.map
        (\message ->
            let
                attachments : SeqDict (Id FileId) FileData
                attachments =
                    messageToFileData message discordAttachments
            in
            Message.userTextMessageNoEmbeds
                message.timestamp
                message.author.id
                (RichText.fromDiscord message.content attachments message.embeds)
                (case message.referencedMessage of
                    Discord.Referenced referenced ->
                        OneToOne.second referenced.id linkedMessageIds

                    Discord.ReferenceDeleted ->
                        Nothing

                    Discord.NoReference ->
                        Nothing
                )
                attachments
        )
        messages
        |> Array.fromList
    , linkedMessageIds
    )


addUploadResponsesToDiscordAttachments :
    List (Result Http.Error ( DiscordAttachmentId, FileStatus.UploadResponse ))
    -> SeqDict DiscordAttachmentId DiscordAttachmentData
    -> SeqDict DiscordAttachmentId DiscordAttachmentData
addUploadResponsesToDiscordAttachments uploadResponses existingDiscordAttachments =
    List.foldl
        (\result dict2 ->
            case result of
                Ok ( attachmentUrl, uploadResponse ) ->
                    SeqDict.insert
                        attachmentUrl
                        { fileHash = uploadResponse.fileHash, imageMetadata = uploadResponse.imageSize }
                        dict2

                Err _ ->
                    dict2
        )
        existingDiscordAttachments
        uploadResponses


referencedMessageToMessageId :
    Discord.Message
    -> { a | linkedMessageIds : OneToOne (Discord.Id Discord.MessageId) (Id messageId) }
    -> Maybe (Id messageId)
referencedMessageToMessageId message channel =
    case message.referencedMessage of
        Discord.Referenced referenced ->
            OneToOne.second referenced.id channel.linkedMessageIds

        Discord.ReferenceDeleted ->
            Nothing

        Discord.NoReference ->
            Nothing


backendSessionIdHash : SessionIdHash
backendSessionIdHash =
    SessionIdHash.fromString Env.secretKey


taskResult : Task restriction a value -> Task restriction x (Result a value)
taskResult task =
    Task.map Ok task |> Task.onError (\error -> Task.succeed (Err error))


nonemptyTaskSequence : Nonempty (Task restriction x a) -> Task restriction x (Nonempty a)
nonemptyTaskSequence nonempty =
    Task.map2 Nonempty (List.Nonempty.head nonempty) (Task.sequence (List.Nonempty.tail nonempty))


joinThread : Discord.UserAuth -> Discord.Id Discord.GuildId -> Discord.Id Discord.MessageId -> Command restriction toMsg BackendMsg
joinThread authentication guildId threadId =
    Discord.joinThreadPayload (Discord.userToken authentication) threadId
        |> http
        |> taskResult
        |> Task.andThen (\result -> Task.map (JoinedDiscordThread guildId result) Time.now)
        |> Task.perform identity


handleCreateMessage :
    String
    -> Discord.Message
    -> SeqDict (Id FileId) FileData
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleCreateMessage websocketJson discordMessage attachments model =
    case discordMessage.guildId of
        Missing ->
            let
                dmChannelId : Discord.Id Discord.PrivateChannelId
                dmChannelId =
                    Discord.idToUInt64 discordMessage.channelId |> Discord.idFromUInt64
            in
            case SeqDict.get dmChannelId model.discordDmChannels of
                Just channel ->
                    if OneToOne.memberFirst discordMessage.id channel.linkedMessageIds then
                        ( model, Command.none )

                    else
                        let
                            richText : Nonempty (RichText (Discord.Id Discord.UserId))
                            richText =
                                RichText.fromDiscord discordMessage.content attachments discordMessage.embeds

                            replyTo : Maybe (Id ChannelMessageId)
                            replyTo =
                                referencedMessageToMessageId discordMessage channel

                            ( message, embedCmds ) =
                                Message.userTextMessage
                                    discordMessage.timestamp
                                    discordMessage.author.id
                                    richText
                                    replyTo
                                    attachments

                            guildOrDmId : DiscordGuildOrDmId
                            guildOrDmId =
                                DiscordGuildOrDmId_Dm { currentUserId = discordMessage.author.id, channelId = dmChannelId }
                        in
                        case LocalState.createDiscordDmChannelMessageBackend discordMessage.id message channel of
                            Ok ( messageId, channel2 ) ->
                                let
                                    notification : Command BackendOnly toMsg BackendMsg
                                    notification =
                                        Broadcast.discordDmNotification
                                            discordMessage.timestamp
                                            dmChannelId
                                            discordMessage.author.id
                                            discordMessage.author.username
                                            (case SeqDict.get discordMessage.author.id model.discordUsers of
                                                Just discordUser ->
                                                    DiscordUserData.icon discordUser

                                                Nothing ->
                                                    Nothing
                                            )
                                            (RichText.toStringWithGetter DiscordUserData.username model.discordUsers richText)
                                            model

                                    ( model2, logCmd ) =
                                        if richText == RichText.emptyPlaceholder then
                                            BackendExtra.addLog
                                                discordMessage.timestamp
                                                (Log.EmptyDiscordMessage websocketJson)
                                                model

                                        else
                                            ( model, Command.none )
                                in
                                ( { model2
                                    | discordDmChannels =
                                        SeqDict.insert dmChannelId channel2 model2.discordDmChannels
                                    , discordUsers =
                                        addDiscordUserData
                                            (Discord.userToPartialUser discordMessage.author)
                                            model2.discordUsers
                                  }
                                , Command.batch
                                    [ case
                                        SeqDict.get
                                            { currentUserId = discordMessage.author.id, channelId = dmChannelId }
                                            model2.pendingDiscordCreateDmMessages
                                      of
                                        Just ( clientId, changeId ) ->
                                            Command.batch
                                                [ LocalChangeResponse
                                                    changeId
                                                    (Local_Discord_SendMessage
                                                        discordMessage.timestamp
                                                        guildOrDmId
                                                        richText
                                                        (NoThreadWithMaybeMessage replyTo)
                                                        attachments
                                                    )
                                                    |> Lamdera.sendToFrontend clientId
                                                , Broadcast.toDiscordDmChannelExcludingOne
                                                    clientId
                                                    dmChannelId
                                                    (Server_Discord_SendMessage
                                                        discordMessage.timestamp
                                                        guildOrDmId
                                                        richText
                                                        (NoThreadWithMaybeMessage replyTo)
                                                        attachments
                                                        |> ServerChange
                                                    )
                                                    model2
                                                ]

                                        Nothing ->
                                            Command.batch
                                                [ Broadcast.toDiscordDmChannel
                                                    dmChannelId
                                                    (Server_Discord_SendMessage
                                                        discordMessage.timestamp
                                                        guildOrDmId
                                                        richText
                                                        (NoThreadWithMaybeMessage replyTo)
                                                        attachments
                                                        |> ServerChange
                                                    )
                                                    model2
                                                ]
                                    , notification
                                    , Command.map identity (DiscordGotDmMessageEmbed dmChannelId messageId) embedCmds
                                    , logCmd
                                    ]
                                )

                            Err _ ->
                                ( model, Command.none )

                Nothing ->
                    ( model, Command.none )

        Included discordGuildId ->
            handleDiscordCreateGuildMessage
                websocketJson
                discordGuildId
                discordMessage.content
                discordMessage
                attachments
                model


discordGetGuildChannel :
    Discord.Message
    -> DiscordBackendGuild
    -> Maybe ( Discord.Id Discord.ChannelId, DiscordBackendChannel, ThreadRouteWithMaybeMessage )
discordGetGuildChannel message guild =
    case SeqDict.get message.channelId guild.channels of
        Just channel ->
            let
                replyTo : Maybe (Id ChannelMessageId)
                replyTo =
                    referencedMessageToMessageId message channel
            in
            Just ( message.channelId, channel, NoThreadWithMaybeMessage replyTo )

        Nothing ->
            List.Extra.findMap
                (\( channelId2, channel ) ->
                    case OneToOne.second (Discord.idToUInt64 message.channelId |> Discord.idFromUInt64) channel.linkedMessageIds of
                        Just messageIndex ->
                            let
                                replyTo : Maybe (Id ThreadMessageId)
                                replyTo =
                                    case SeqDict.get messageIndex channel.threads of
                                        Just thread ->
                                            referencedMessageToMessageId message thread

                                        Nothing ->
                                            Nothing
                            in
                            ( channelId2
                            , channel
                            , ViewThreadWithMaybeMessage messageIndex replyTo
                            )
                                |> Just

                        _ ->
                            Nothing
                )
                (SeqDict.toList guild.channels)


handleDiscordCreateGuildMessage :
    String
    -> Discord.Id Discord.GuildId
    -> String
    -> Discord.Message
    -> SeqDict (Id FileId) FileData
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleDiscordCreateGuildMessage websocketJson discordGuildId content discordMessage attachments model =
    case SeqDict.get discordGuildId model.discordGuilds of
        Just guild ->
            case discordGetGuildChannel discordMessage guild of
                Just ( channelId, channel, threadRoute ) ->
                    if OneToOne.memberFirst discordMessage.id channel.linkedMessageIds then
                        ( model, Command.none )

                    else
                        case discordMessage.type_ of
                            Discord.GuildMemberJoin ->
                                let
                                    message : Message messageId (Discord.Id Discord.UserId)
                                    message =
                                        UserJoinedMessage
                                            discordMessage.timestamp
                                            discordMessage.author.id
                                            SeqDict.empty
                                in
                                case LocalState.createDiscordChannelMessageBackend discordMessage.id message channel of
                                    Ok ( _, channel4 ) ->
                                        ( { model
                                            | discordGuilds =
                                                SeqDict.insert
                                                    discordGuildId
                                                    { guild
                                                        | channels = SeqDict.insert channelId channel4 guild.channels
                                                        , membersAndOwner =
                                                            MembersAndOwner.addMember
                                                                discordMessage.author.id
                                                                { joinedAt = Just discordMessage.timestamp }
                                                                guild.membersAndOwner
                                                                |> Result.withDefault guild.membersAndOwner
                                                    }
                                                    model.discordGuilds
                                            , discordUsers =
                                                addDiscordUserData
                                                    (Discord.userToPartialUser discordMessage.author)
                                                    model.discordUsers
                                          }
                                        , Command.batch
                                            [ Broadcast.toDiscordGuild
                                                discordGuildId
                                                (Server_DiscordGuildMemberJoined
                                                    discordMessage.timestamp
                                                    discordGuildId
                                                    discordMessage.channelId
                                                    discordMessage.author.id
                                                    (PersonName.fromStringLossy discordMessage.author.username)
                                                    |> ServerChange
                                                )
                                                model
                                            , getUserAvatars model.discordUsers [ discordMessage.author ]
                                            , Broadcast.discordGuildMessageNotification
                                                SeqSet.empty
                                                discordMessage.timestamp
                                                discordMessage.author.id
                                                discordGuildId
                                                channelId
                                                NoThread
                                                (Nonempty (UserMention discordMessage.author.id) [ NormalText ' ' "joined!" ])
                                                (MembersAndOwner.membersAndOwner guild.membersAndOwner)
                                                model
                                            ]
                                        )

                                    Err DiscordMessageAlreadyExists ->
                                        ( model, Command.none )

                            _ ->
                                let
                                    richText : Nonempty (RichText (Discord.Id Discord.UserId))
                                    richText =
                                        RichText.fromDiscord content attachments discordMessage.embeds

                                    threadOrChannelId : Discord.Id Discord.ChannelId
                                    threadOrChannelId =
                                        case threadRoute of
                                            ViewThreadWithMaybeMessage threadId _ ->
                                                case OneToOne.first threadId channel.linkedMessageIds of
                                                    Just messageId ->
                                                        Discord.idToUInt64 messageId |> Discord.idFromUInt64

                                                    Nothing ->
                                                        channelId

                                            NoThreadWithMaybeMessage _ ->
                                                channelId

                                    threadRouteNoReply : ThreadRoute
                                    threadRouteNoReply =
                                        case threadRoute of
                                            ViewThreadWithMaybeMessage threadId _ ->
                                                ViewThread threadId

                                            NoThreadWithMaybeMessage _ ->
                                                NoThread

                                    usersMentioned : SeqSet (Discord.Id Discord.UserId)
                                    usersMentioned =
                                        LocalState.usersMentionedOrRepliedToBackend
                                            threadRoute
                                            richText
                                            (MembersAndOwner.membersAndOwner guild.membersAndOwner)
                                            channel

                                    guildOrDmId : DiscordGuildOrDmId
                                    guildOrDmId =
                                        DiscordGuildOrDmId_Guild discordMessage.author.id discordGuildId channelId

                                    channelResult : Result DiscordMessageAlreadyExists ( DiscordBackendChannel, Command BackendOnly ToFrontend BackendMsg )
                                    channelResult =
                                        case threadRoute of
                                            ViewThreadWithMaybeMessage threadId maybeReplyTo ->
                                                let
                                                    ( message2, embedCmds ) =
                                                        Message.userTextMessage
                                                            discordMessage.timestamp
                                                            discordMessage.author.id
                                                            richText
                                                            maybeReplyTo
                                                            attachments
                                                in
                                                case LocalState.createDiscordThreadMessageBackend discordMessage.id threadId message2 channel of
                                                    Ok ( messageId, channel3 ) ->
                                                        ( channel3
                                                        , Command.map
                                                            identity
                                                            (DiscordGotGuildMessageEmbed discordGuildId channelId (ViewThreadWithMessage threadId messageId))
                                                            embedCmds
                                                        )
                                                            |> Ok

                                                    Err DiscordMessageAlreadyExists ->
                                                        Err DiscordMessageAlreadyExists

                                            NoThreadWithMaybeMessage maybeReplyTo ->
                                                let
                                                    ( message, embedCmds ) =
                                                        Message.userTextMessage
                                                            discordMessage.timestamp
                                                            discordMessage.author.id
                                                            richText
                                                            maybeReplyTo
                                                            attachments
                                                in
                                                case LocalState.createDiscordChannelMessageBackend discordMessage.id message channel of
                                                    Ok ( messageId, channel3 ) ->
                                                        ( channel3
                                                        , Command.map
                                                            identity
                                                            (DiscordGotGuildMessageEmbed discordGuildId channelId (NoThreadWithMessage messageId))
                                                            embedCmds
                                                        )
                                                            |> Ok

                                                    Err DiscordMessageAlreadyExists ->
                                                        Err DiscordMessageAlreadyExists
                                in
                                case channelResult of
                                    Ok ( channel4, embedCmds ) ->
                                        let
                                            ( model2, logCmd ) =
                                                if richText == RichText.emptyPlaceholder then
                                                    BackendExtra.addLog
                                                        discordMessage.timestamp
                                                        (Log.EmptyDiscordMessage websocketJson)
                                                        model

                                                else
                                                    ( model, Command.none )
                                        in
                                        ( { model2
                                            | discordGuilds =
                                                SeqDict.insert
                                                    discordGuildId
                                                    { guild
                                                        | channels = SeqDict.insert channelId channel4 guild.channels
                                                        , membersAndOwner =
                                                            MembersAndOwner.addMember
                                                                discordMessage.author.id
                                                                { joinedAt = Nothing }
                                                                guild.membersAndOwner
                                                                |> Result.withDefault guild.membersAndOwner
                                                    }
                                                    model2.discordGuilds
                                            , discordUsers =
                                                addDiscordUserData
                                                    (Discord.userToPartialUser discordMessage.author)
                                                    model2.discordUsers
                                            , users =
                                                SeqSet.foldl
                                                    (\discordUserId2 users ->
                                                        case SeqDict.get discordUserId2 model2.discordUsers of
                                                            Just (FullData data) ->
                                                                let
                                                                    isViewing =
                                                                        Broadcast.userGetAllSessions data.linkedTo model2
                                                                            |> List.any
                                                                                (\( _, userSession ) ->
                                                                                    userSession.currentlyViewing == Just ( DiscordGuildOrDmId guildOrDmId, threadRouteNoReply )
                                                                                )
                                                                in
                                                                if isViewing then
                                                                    users

                                                                else
                                                                    NonemptyDict.updateIfExists
                                                                        data.linkedTo
                                                                        (User.addDiscordDirectMention discordGuildId channelId threadRouteNoReply)
                                                                        users

                                                            _ ->
                                                                users
                                                    )
                                                    model2.users
                                                    usersMentioned
                                            , pendingDiscordCreateMessages =
                                                SeqDict.remove ( discordMessage.author.id, threadOrChannelId ) model2.pendingDiscordCreateMessages
                                          }
                                        , Command.batch
                                            [ case SeqDict.get ( discordMessage.author.id, threadOrChannelId ) model2.pendingDiscordCreateMessages of
                                                Just ( clientId, changeId ) ->
                                                    Command.batch
                                                        [ LocalChangeResponse
                                                            changeId
                                                            (Local_Discord_SendMessage discordMessage.timestamp guildOrDmId richText threadRoute attachments)
                                                            |> Lamdera.sendToFrontend clientId
                                                        , Broadcast.toDiscordGuildExcludingOne
                                                            clientId
                                                            discordGuildId
                                                            (Server_Discord_SendMessage discordMessage.timestamp guildOrDmId richText threadRoute attachments
                                                                |> ServerChange
                                                            )
                                                            model2
                                                        ]

                                                Nothing ->
                                                    Broadcast.toDiscordGuild
                                                        discordGuildId
                                                        (Server_Discord_SendMessage
                                                            discordMessage.timestamp
                                                            guildOrDmId
                                                            richText
                                                            threadRoute
                                                            attachments
                                                            |> ServerChange
                                                        )
                                                        model2
                                            , getUserAvatars model2.discordUsers [ discordMessage.author ]
                                            , Broadcast.discordGuildMessageNotification
                                                usersMentioned
                                                discordMessage.timestamp
                                                discordMessage.author.id
                                                discordGuildId
                                                channelId
                                                threadRouteNoReply
                                                richText
                                                (MembersAndOwner.membersAndOwner guild.membersAndOwner)
                                                model2
                                            , embedCmds
                                            , logCmd
                                            ]
                                        )

                                    Err DiscordMessageAlreadyExists ->
                                        ( model, Command.none )

                Nothing ->
                    ( model, Command.none )

        _ ->
            ( model, Command.none )


websocketCreateHandle : String -> (Websocket.Connection -> msg) -> String -> Command restriction toMsg msg
websocketCreateHandle debugName msg url =
    let
        _ =
            Debug.log "websocket created" debugName
    in
    Websocket.createHandle msg url


websocketClose : String -> Websocket.Connection -> Task restriction x ()
websocketClose debugName connection =
    Task.map
        (\() ->
            let
                _ =
                    Debug.log ("websocketClose " ++ debugName) connection
            in
            ()
        )
        (Task.succeed ())
        |> Task.andThen (\() -> Websocket.close connection)


discordUserWebsocketMsg : Discord.Id Discord.UserId -> Discord.Msg -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
discordUserWebsocketMsg discordUserId discordMsg model =
    case SeqDict.get discordUserId model.discordUsers of
        Just (FullData userData) ->
            let
                ( discordModel2, outMsgs ) =
                    Discord.userUpdate userData.auth Discord.noIntents discordMsg userData.connection
            in
            List.foldl
                (\outMsg ( model2, cmds ) ->
                    case outMsg of
                        Discord.UserOutMsg_CloseAndReopenHandle connection ->
                            ( model2
                            , Task.perform (\() -> WebsocketClosedByBackendForUser discordUserId True) (websocketClose "UserOutMsg_CloseAndReopenHandle" connection)
                                :: cmds
                            )

                        Discord.UserOutMsg_OpenHandle ->
                            ( model2
                            , websocketCreateHandle "OpenHandle" (WebsocketCreatedHandleForUser discordUserId) Discord.websocketGatewayUrl
                                :: cmds
                            )

                        Discord.UserOutMsg_AuthenticationIsNoLongerValid ->
                            ( { model2
                                | discordUsers =
                                    SeqDict.insert
                                        discordUserId
                                        (NeedsAuthAgain
                                            { user = userData.user
                                            , icon = userData.icon
                                            , linkedTo = userData.linkedTo
                                            , linkedAt = userData.linkedAt
                                            }
                                        )
                                        model2.discordUsers
                              }
                            , Broadcast.toUser
                                Nothing
                                Nothing
                                userData.linkedTo
                                (Server_DiscordNeedsAuthAgain discordUserId |> ServerChange)
                                model2
                                :: cmds
                            )

                        Discord.UserOutMsg_SendWebsocketData connection data ->
                            ( model2
                            , Task.attempt (WebsocketSentDataForUser discordUserId) (Websocket.sendString connection data)
                                :: cmds
                            )

                        Discord.UserOutMsg_SendWebsocketDataWithDelay connection duration data ->
                            ( model2
                            , (Process.sleep duration
                                |> Task.andThen (\() -> Websocket.sendString connection data)
                                |> Task.attempt (WebsocketSentDataForUser discordUserId)
                              )
                                :: cmds
                            )

                        Discord.UserOutMsg_UserCreatedMessage _ message ->
                            let
                                attachments : SeqDict (Id FileId) FileData
                                attachments =
                                    messageToFileData message model2.discordAttachments

                                joinThreadCmd : Command BackendOnly ToFrontend BackendMsg
                                joinThreadCmd =
                                    case ( message.guildId, message.flags ) of
                                        ( Included guildId, Included flags ) ->
                                            if flags.hasThread then
                                                joinThread userData.auth guildId message.id

                                            else
                                                Command.none

                                        _ ->
                                            Command.none
                            in
                            case ( SeqDict.size attachments == List.length message.attachments, List.Nonempty.fromList message.attachments ) of
                                ( False, Just nonempty ) ->
                                    ( model2
                                    , joinThreadCmd
                                        :: Task.perform
                                            (DiscordMessageCreate_AttachmentsUploaded message)
                                            (nonemptyTaskSequence (List.Nonempty.map loadMessageAttachment nonempty))
                                        :: cmds
                                    )

                                _ ->
                                    let
                                        ( model3, cmd2 ) =
                                            handleCreateMessage
                                                (case discordMsg of
                                                    Discord.GotWebsocketData data ->
                                                        data

                                                    Discord.WebsocketClosed data ->
                                                        data
                                                )
                                                message
                                                attachments
                                                model2
                                    in
                                    ( model3, joinThreadCmd :: cmd2 :: cmds )

                        Discord.UserOutMsg_UserDeletedGuildMessage discordGuildId discordChannelId messageId ->
                            let
                                ( model3, cmd2 ) =
                                    handleDiscordDeleteGuildMessage discordGuildId discordChannelId messageId model2
                            in
                            ( model3, cmd2 :: cmds )

                        Discord.UserOutMsg_UserDeletedDmMessage discordChannelId messageId ->
                            let
                                ( model3, cmd2 ) =
                                    handleDiscordDeleteDmMessage discordChannelId messageId model2
                            in
                            ( model3, cmd2 :: cmds )

                        Discord.UserOutMsg_UserEditedMessage edit ->
                            let
                                attachments : SeqDict (Id FileId) FileData
                                attachments =
                                    messageToFileData edit model2.discordAttachments

                                joinThreadCmd : Command BackendOnly ToFrontend BackendMsg
                                joinThreadCmd =
                                    case ( edit.guildId, edit.flags.hasThread ) of
                                        ( Included guildId, True ) ->
                                            joinThread userData.auth guildId edit.id

                                        _ ->
                                            Command.none
                            in
                            case ( SeqDict.size attachments == List.length edit.attachments, List.Nonempty.fromList edit.attachments ) of
                                ( False, Just nonempty ) ->
                                    ( model2
                                    , Task.perform
                                        (DiscordMessageUpdate_AttachmentsUploaded edit)
                                        (nonemptyTaskSequence (List.Nonempty.map loadMessageAttachment nonempty))
                                        :: joinThreadCmd
                                        :: cmds
                                    )

                                _ ->
                                    let
                                        ( model3, cmd2 ) =
                                            handleEditMessage edit attachments model2
                                    in
                                    ( model3, cmd2 :: joinThreadCmd :: cmds )

                        Discord.UserOutMsg_FailedToParseWebsocketMessage error ->
                            let
                                _ =
                                    Debug.log "gateway error" (Json.Decode.errorToString error)
                            in
                            ( model2
                            , Task.perform
                                (GotTimeForFailedToParseDiscordWebsocket
                                    (case discordMsg of
                                        Discord.GotWebsocketData text ->
                                            Json.Decode.decodeString (Json.Decode.field "t" Json.Decode.string) text
                                                |> Result.toMaybe

                                        Discord.WebsocketClosed _ ->
                                            Just "Websocket closed"
                                    )
                                    (Json.Decode.errorToString error)
                                )
                                Time.now
                                :: cmds
                            )

                        Discord.UserOutMsg_ThreadCreatedOrUserAddedToThread _ ->
                            ( model2, cmds )

                        Discord.UserOutMsg_UserAddedReaction reaction ->
                            let
                                ( model3, cmd2 ) =
                                    addOrRemoveDiscordReaction True reaction model2
                            in
                            ( model3, cmd2 :: cmds )

                        Discord.UserOutMsg_UserRemovedReaction reaction ->
                            let
                                ( model3, cmd2 ) =
                                    addOrRemoveDiscordReaction False reaction model2
                            in
                            ( model3, cmd2 :: cmds )

                        Discord.UserOutMsg_AllReactionsRemoved reactionRemoveAll ->
                            let
                                ( model3, cmd2 ) =
                                    handleDiscordRemoveAllReactions reactionRemoveAll model2
                            in
                            ( model3, cmd2 :: cmds )

                        Discord.UserOutMsg_ReactionsRemoveForEmoji reactionRemoveEmoji ->
                            let
                                ( model3, cmd2 ) =
                                    handleDiscordRemoveReactionForEmoji reactionRemoveEmoji model2
                            in
                            ( model3, cmd2 :: cmds )

                        Discord.UserOutMsg_ListGuildMembersResponse chunkData ->
                            let
                                ( model3, cmd2 ) =
                                    handleListGuildMembersResponse chunkData model2
                            in
                            ( model3, cmd2 :: cmds )

                        Discord.UserOutMsg_ReadyData readyData ->
                            let
                                ( model3, cmd2 ) =
                                    handleReadyData readyData model2
                            in
                            ( model3, cmd2 :: cmds )

                        Discord.UserOutMsg_SupplementalReadyData readySupplementalData ->
                            let
                                ( model3, cmd2 ) =
                                    handleReadySupplementalData readySupplementalData model2
                            in
                            ( model3, Command.batch cmd2 :: cmds )

                        Discord.UserOutMsg_ChannelCreated channel ->
                            let
                                ( model3, cmd2 ) =
                                    handleChannelCreated channel model2
                            in
                            ( model3, cmd2 :: cmds )

                        Discord.UserOutMsg_TypingStarted typingStart ->
                            let
                                ( model3, cmd2 ) =
                                    handleTypingStarted typingStart model2
                            in
                            ( model3, cmd2 :: cmds )

                        Discord.UserOutMsg_PresenceUpdate presence ->
                            let
                                ( model3, cmd2 ) =
                                    case presence.guildId of
                                        Included guildId ->
                                            case SeqDict.get guildId model2.discordGuilds of
                                                Just guild ->
                                                    ( { model2
                                                        | discordGuilds =
                                                            SeqDict.insert
                                                                guildId
                                                                { guild
                                                                    | membersAndOwner =
                                                                        MembersAndOwner.addMember
                                                                            presence.userId
                                                                            { joinedAt = Nothing }
                                                                            guild.membersAndOwner
                                                                            |> Result.withDefault guild.membersAndOwner
                                                                }
                                                                model2.discordGuilds
                                                      }
                                                    , Command.none
                                                    )

                                                Nothing ->
                                                    ( model2, Command.none )

                                        Missing ->
                                            ( model2, Command.none )
                            in
                            ( model3, cmd2 :: cmds )

                        Discord.UserOutMsg_EmbeddedActivityUpdateV2 embeddedActivityUpdateV2 ->
                            let
                                ( model3, cmd2 ) =
                                    case embeddedActivityUpdateV2.location.guildId of
                                        Included guildId ->
                                            case SeqDict.get guildId model2.discordGuilds of
                                                Just guild ->
                                                    let
                                                        ( discordUsers, guild3, users2 ) =
                                                            List.foldl
                                                                (\participant ( dict, guild2, users ) ->
                                                                    case participant.member of
                                                                        Included member ->
                                                                            ( addDiscordUserData
                                                                                (Discord.userToPartialUser member.user)
                                                                                dict
                                                                            , { guild2
                                                                                | membersAndOwner =
                                                                                    MembersAndOwner.addOrUpdateMember
                                                                                        participant.userId
                                                                                        { joinedAt = Just member.joinedAt }
                                                                                        guild2.membersAndOwner
                                                                              }
                                                                            , member.user :: users
                                                                            )

                                                                        Missing ->
                                                                            ( dict, guild2, users )
                                                                )
                                                                ( model2.discordUsers, guild, [] )
                                                                embeddedActivityUpdateV2.participants
                                                    in
                                                    ( { model2
                                                        | discordUsers = discordUsers
                                                        , discordGuilds =
                                                            SeqDict.insert guildId guild3 model2.discordGuilds
                                                      }
                                                    , getUserAvatars model2.discordUsers users2
                                                    )

                                                Nothing ->
                                                    ( model2, Command.none )

                                        Missing ->
                                            let
                                                ( discordUsers, users2 ) =
                                                    List.foldl
                                                        (\participant ( dict, users ) ->
                                                            case participant.member of
                                                                Included member ->
                                                                    ( addDiscordUserData
                                                                        (Discord.userToPartialUser member.user)
                                                                        dict
                                                                    , member.user :: users
                                                                    )

                                                                Missing ->
                                                                    ( dict, users )
                                                        )
                                                        ( model2.discordUsers, [] )
                                                        embeddedActivityUpdateV2.participants
                                            in
                                            ( { model2 | discordUsers = discordUsers }
                                            , getUserAvatars model2.discordUsers users2
                                            )
                            in
                            ( model3, cmd2 :: cmds )

                        Discord.UserOutMsg_GuildMemberAddEvent guildId guildMember ->
                            let
                                ( model3, cmd2 ) =
                                    handleGuildMemberUpdate guildId guildMember model2
                            in
                            ( model3, cmd2 :: cmds )

                        Discord.UserOutMsg_GuildMemberRemoveEvent guildId userId ->
                            ( case SeqDict.get guildId model2.discordGuilds of
                                Just guild ->
                                    { model2
                                        | discordGuilds =
                                            SeqDict.insert
                                                guildId
                                                { guild
                                                    | membersAndOwner =
                                                        MembersAndOwner.removeMember userId guild.membersAndOwner
                                                }
                                                model2.discordGuilds
                                    }

                                Nothing ->
                                    model2
                            , cmds
                            )

                        Discord.UserOutMsg_GuildMemberUpdateEvent guildMemberUpdate ->
                            let
                                ( model3, cmd2 ) =
                                    handleGuildMemberUpdate guildMemberUpdate.guildId guildMemberUpdate model2
                            in
                            ( model3, cmd2 :: cmds )

                        Discord.UserOutMsg_VoiceStateUpdate voiceStateUpdate ->
                            let
                                ( model3, cmd2 ) =
                                    case ( voiceStateUpdate.guildId, voiceStateUpdate.member ) of
                                        ( Included (Just guildId), Included member ) ->
                                            handleGuildMemberUpdate guildId member model2

                                        _ ->
                                            ( model2, Command.none )
                            in
                            ( model3, cmd2 :: cmds )

                        Discord.UserOutMsg_JoinedOrCreatedGuild gatewayGuild ->
                            let
                                ( model3, cmd2 ) =
                                    handleJoinOrCreateGuild discordUserId gatewayGuild model2
                            in
                            ( model3, cmd2 :: cmds )

                        Discord.UserOutMsg_ChannelUpdated channel ->
                            let
                                ( model3, cmd2 ) =
                                    handleChannelUpdated channel model2
                            in
                            ( model3, cmd2 :: cmds )
                )
                ( { model
                    | discordUsers =
                        SeqDict.insert
                            discordUserId
                            (FullData { userData | connection = discordModel2 })
                            model.discordUsers
                  }
                , []
                )
                outMsgs
                |> Tuple.mapSecond Command.batch

        _ ->
            ( model, Command.none )


handleJoinOrCreateGuild :
    Discord.Id Discord.UserId
    -> Discord.GatewayGuild
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleJoinOrCreateGuild discordUserId gatewayGuild model =
    ( { model | discordGuilds = addDiscordGuild model.discordStickers [] gatewayGuild model.discordGuilds }
    , getDiscordGuildData gatewayGuild
        |> Task.map (\( _, guildData ) -> Ok guildData)
        |> Task.onError (\error -> Err error |> Task.succeed)
        |> Task.andThen (\result -> Task.map (Tuple.pair result) Time.now)
        |> Task.perform
            (\( result, time ) ->
                DiscordGotDataForJoinedOrCreatedGuild
                    discordUserId
                    gatewayGuild.properties.id
                    time
                    result
            )
    )


handleChannelUpdated : Discord.Channel -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleChannelUpdated channel model =
    case channel.guildId of
        Missing ->
            --let
            --    channelId : Discord.Id Discord.PrivateChannelId
            --    channelId =
            --        Discord.idToUInt64 channel.id |> Discord.idFromUInt64
            --in
            --case SeqDict.get channelId model.discordDmChannels of
            --    Just existingChannel ->
            --        { model
            --            | discordDmChannels =
            --                SeqDict.insert
            --                    channelId
            --                    { existingChannel | members =  channel.recipients }
            --                    model.discordDmChannels
            --        }
            --
            --    Nothing ->
            --        ( model, Command.none )
            ( model, Command.none )

        Included guildId ->
            ( { model
                | discordGuilds =
                    SeqDict.updateIfExists
                        guildId
                        (\guild ->
                            { guild
                                | channels =
                                    SeqDict.updateIfExists
                                        channel.id
                                        (\existingChannel ->
                                            { existingChannel
                                                | name =
                                                    case channel.name of
                                                        Included name ->
                                                            ChannelName.fromStringLossy name

                                                        Missing ->
                                                            existingChannel.name
                                                , description =
                                                    LocalState.discordTopicToDescription
                                                        channel.topic
                                                        existingChannel.description
                                            }
                                        )
                                        guild.channels
                            }
                        )
                        model.discordGuilds
              }
            , Broadcast.toDiscordGuild
                guildId
                (Server_DiscordUpdateChannel guildId channel.id channel.name channel.topic |> ServerChange)
                model
            )


handleGuildMemberUpdate :
    Discord.Id Discord.GuildId
    -> { b | user : Discord.User, joinedAt : Time.Posix }
    -> BackendModel
    -> ( BackendModel, Command restriction toMsg BackendMsg )
handleGuildMemberUpdate guildId guildMember model2 =
    case SeqDict.get guildId model2.discordGuilds of
        Just guild ->
            ( { model2
                | discordUsers = addDiscordUserData (Discord.userToPartialUser guildMember.user) model2.discordUsers
                , discordGuilds =
                    SeqDict.insert
                        guildId
                        { guild
                            | membersAndOwner =
                                MembersAndOwner.addOrUpdateMember
                                    guildMember.user.id
                                    { joinedAt = Just guildMember.joinedAt }
                                    guild.membersAndOwner
                        }
                        model2.discordGuilds
              }
            , getUserAvatars model2.discordUsers [ guildMember.user ]
            )

        Nothing ->
            ( model2, Command.none )


handleTypingStarted : Discord.TypingStart -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend msg )
handleTypingStarted typingStart model =
    case typingStart.guildId of
        Included guildId ->
            case SeqDict.get guildId model.discordGuilds of
                Just guild ->
                    case discordChannelIdToChannelIdNoMessage typingStart.channelId guild of
                        Just ( channelId, channel, threadRoute ) ->
                            let
                                ( lastTypedAt, channel2 ) =
                                    case threadRoute of
                                        Nothing ->
                                            ( SeqDict.get typingStart.userId channel.lastTypedAt |> Maybe.map .time
                                            , { channel
                                                | lastTypedAt =
                                                    SeqDict.insert
                                                        typingStart.userId
                                                        { time = typingStart.timestamp, messageIndex = Nothing }
                                                        channel.lastTypedAt
                                              }
                                            )

                                        Just { threadId, thread } ->
                                            ( SeqDict.get typingStart.userId thread.lastTypedAt |> Maybe.map .time
                                            , { channel
                                                | threads =
                                                    SeqDict.insert
                                                        threadId
                                                        { thread
                                                            | lastTypedAt =
                                                                SeqDict.insert
                                                                    typingStart.userId
                                                                    { time = typingStart.timestamp, messageIndex = Nothing }
                                                                    thread.lastTypedAt
                                                        }
                                                        channel.threads
                                              }
                                            )
                            in
                            if
                                -- If we just got a typing indicator two seconds ago then skip this new one
                                Duration.from (Maybe.withDefault (Time.millisToPosix 0) lastTypedAt) typingStart.timestamp
                                    |> Quantity.lessThan (Duration.seconds 2)
                            then
                                ( model, Command.none )

                            else
                                ( { model
                                    | discordGuilds =
                                        SeqDict.insert
                                            guildId
                                            { guild | channels = SeqDict.insert channelId channel2 guild.channels }
                                            model.discordGuilds
                                  }
                                , Broadcast.toDiscordGuild
                                    guildId
                                    (Server_DiscordGuildMemberTyping
                                        typingStart.timestamp
                                        typingStart.userId
                                        guildId
                                        channelId
                                        (case threadRoute of
                                            Just a ->
                                                ViewThread a.threadId

                                            Nothing ->
                                                NoThread
                                        )
                                        |> ServerChange
                                    )
                                    model
                                )

                        Nothing ->
                            ( model, Command.none )

                Nothing ->
                    ( model, Command.none )

        Missing ->
            let
                channelId : Discord.Id Discord.PrivateChannelId
                channelId =
                    Discord.idToUInt64 typingStart.channelId |> Discord.idFromUInt64
            in
            case SeqDict.get channelId model.discordDmChannels of
                Just channel ->
                    ( { model
                        | discordDmChannels =
                            SeqDict.insert
                                channelId
                                { channel
                                    | lastTypedAt =
                                        SeqDict.insert
                                            typingStart.userId
                                            { time = typingStart.timestamp, messageIndex = Nothing }
                                            channel.lastTypedAt
                                }
                                model.discordDmChannels
                      }
                    , Broadcast.toDiscordDmChannel
                        channelId
                        (Server_DiscordDmMemberTyping typingStart.timestamp typingStart.userId channelId
                            |> ServerChange
                        )
                        model
                    )

                Nothing ->
                    ( model, Command.none )


handleEditMessage :
    Discord.UserMessageUpdate
    -> SeqDict (Id FileId) FileData
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleEditMessage edit attachments model2 =
    case edit.guildId of
        Included guildId ->
            case SeqDict.get guildId model2.discordGuilds of
                Just guild ->
                    handleDiscordGuildEditMessage guildId guild edit attachments model2

                Nothing ->
                    ( model2, Command.none )

        Missing ->
            handleDiscordDmEditMessage edit attachments model2


loadMessageAttachment :
    Discord.Attachment
    -> Task restriction x (Result Http.Error ( Discord.Id Discord.AttachmentId, FileStatus.UploadResponse ))
loadMessageAttachment attachment =
    FileStatus.uploadUrl { sessionId = backendSessionIdHash, url = attachment.url }
        |> Task.map (\uploadResponse -> Ok ( attachment.id, uploadResponse ))
        |> Task.onError (\error -> Task.succeed (Err error))


messageToFileData :
    { a | attachments : List Discord.Attachment }
    -> SeqDict DiscordAttachmentId DiscordAttachmentData
    -> SeqDict (Id FileId) FileData
messageToFileData message discordAttachments =
    List.filterMap
        (\attachment ->
            case SeqDict.get (DiscordAttachmentId.fromUrl attachment.url) discordAttachments of
                Just { fileHash, imageMetadata } ->
                    attachmentsToFileData attachment fileHash imageMetadata |> Just

                Nothing ->
                    Nothing
        )
        message.attachments
        |> List.indexedMap (\index fileData -> ( Id.fromInt index, fileData ))
        |> SeqDict.fromList


attachmentsToFileData : Discord.Attachment -> FileHash -> Maybe FileStatus.ImageMetadata -> FileData
attachmentsToFileData attachment fileHash imageSize =
    { fileName = FileName.fromString attachment.filename
    , fileSize = attachment.size
    , imageMetadata = imageSize
    , contentType =
        case attachment.contentType of
            Included contentType ->
                FileStatus.contentType contentType

            Missing ->
                case imageSize of
                    Just _ ->
                        FileStatus.webpContent

                    Nothing ->
                        FileStatus.unknownContentType
    , fileHash = fileHash
    }


handleChannelCreated : Discord.Channel -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleChannelCreated channel model =
    case channel.guildId of
        Missing ->
            case channel.recipients of
                Included (head :: rest) ->
                    let
                        channelId : Discord.Id Discord.PrivateChannelId
                        channelId =
                            Discord.idToUInt64 channel.id |> Discord.idFromUInt64

                        members : NonemptyDict (Discord.Id Discord.UserId) { messagesSent : Int }
                        members =
                            Nonempty
                                ( head.id, { messagesSent = 0 } )
                                (List.map (\user -> ( user.id, { messagesSent = 0 } )) rest)
                                |> NonemptyDict.fromNonemptyList

                        existingUsers : SeqDict (Discord.Id Discord.UserId) DiscordUserData
                        existingUsers =
                            model.discordUsers

                        model2 : BackendModel
                        model2 =
                            { model
                                | discordDmChannels =
                                    SeqDict.update
                                        channelId
                                        (\maybeChannel ->
                                            case maybeChannel of
                                                Just _ ->
                                                    maybeChannel

                                                Nothing ->
                                                    { messages = Array.empty
                                                    , lastTypedAt = SeqDict.empty
                                                    , linkedMessageIds = OneToOne.empty
                                                    , members = members
                                                    }
                                                        |> Just
                                        )
                                        model.discordDmChannels
                                , discordUsers =
                                    List.map
                                        (\user ->
                                            { id = user.id
                                            , username = user.username
                                            , avatar = user.avatar
                                            , discriminator = user.discriminator
                                            }
                                        )
                                        (head :: rest)
                                        |> List.foldl addDiscordUserData model.discordUsers
                            }
                    in
                    ( model2
                    , Command.batch
                        [ Broadcast.toDiscordDmChannel
                            channelId
                            (Server_DiscordDmChannelCreated channelId members |> ServerChange)
                            model2
                        , getUserAvatars existingUsers (head :: rest)
                        ]
                    )

                _ ->
                    ( model, Command.none )

        Included guildId ->
            let
                name : ChannelName
                name =
                    case channel.name of
                        Included name2 ->
                            ChannelName.fromStringLossy name2

                        Missing ->
                            ChannelName.fromStringLossy "New channel"
            in
            ( { model
                | discordGuilds =
                    SeqDict.updateIfExists
                        guildId
                        (\guild ->
                            { guild
                                | channels =
                                    SeqDict.update
                                        channel.id
                                        (\maybeChannel ->
                                            case maybeChannel of
                                                Just existingChannel ->
                                                    Just
                                                        { existingChannel
                                                            | name = name
                                                            , description =
                                                                LocalState.discordTopicToDescription
                                                                    channel.topic
                                                                    existingChannel.description
                                                        }

                                                Nothing ->
                                                    { name = name
                                                    , description =
                                                        LocalState.discordTopicToDescription
                                                            channel.topic
                                                            ChannelDescription.empty
                                                    , messages = Array.empty
                                                    , status = ChannelActive
                                                    , lastTypedAt = SeqDict.empty
                                                    , linkedMessageIds = OneToOne.empty
                                                    , threads = SeqDict.empty
                                                    }
                                                        |> Just
                                        )
                                        guild.channels
                            }
                        )
                        model.discordGuilds
              }
            , Broadcast.toDiscordGuild
                guildId
                (Server_DiscordChannelCreated guildId channel.id name channel.topic |> ServerChange)
                model
            )


handleReadySupplementalData :
    Discord.ReadySupplementalData
    -> BackendModel
    -> ( BackendModel, List (Command BackendOnly ToFrontend BackendMsg) )
handleReadySupplementalData data model =
    List.map2 (\{ id } mergedMembers -> ( id, mergedMembers )) data.guilds data.mergedMembers
        |> List.foldl
            (\( guildId, mergedMembers ) ( model2, cmds ) ->
                case SeqDict.get guildId model2.discordGuilds of
                    Just guild ->
                        let
                            mergedMembers2 : MembersAndOwner (Discord.Id Discord.UserId) { joinedAt : Maybe Time.Posix }
                            mergedMembers2 =
                                List.foldl
                                    (\mergedMember state ->
                                        MembersAndOwner.addOrUpdateMember
                                            mergedMember.userId
                                            { joinedAt = Just mergedMember.joinedAt }
                                            state
                                    )
                                    guild.membersAndOwner
                                    mergedMembers

                            model3 : BackendModel
                            model3 =
                                { model2
                                    | discordGuilds =
                                        SeqDict.insert
                                            guildId
                                            { guild | membersAndOwner = mergedMembers2 }
                                            model2.discordGuilds
                                }
                        in
                        ( model3
                        , Broadcast.toDiscordGuild
                            guildId
                            (Server_UpdateDiscordMembers guildId mergedMembers2 |> ServerChange)
                            model3
                            :: cmds
                        )

                    Nothing ->
                        ( model2, cmds )
            )
            ( model, [] )


handleReadyData : Discord.ReadyData -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleReadyData readyData model =
    let
        discordDmChannels : List { dmChannelId : Discord.Id Discord.PrivateChannelId, members : List (Discord.Id Discord.UserId) }
        discordDmChannels =
            case readyData.privateChannels of
                Included privateChannels ->
                    List.map
                        (\dmChannel -> { dmChannelId = dmChannel.id, members = dmChannel.recipientIds })
                        privateChannels

                Missing ->
                    []

        discordUsers : List Discord.PartialUser
        discordUsers =
            Discord.userToPartialUser readyData.user :: readyData.users

        stickerData :
            { tasks : List (Task BackendOnly x ( Id StickerId, Result Http.Error FileStatus.UploadResponse ))
            , stickers : SeqDict (Id StickerId) StickerData
            , discordStickers : OneToOne (Discord.Id Discord.StickerId) (Id StickerId)
            }
        stickerData =
            List.foldl
                (\guild state ->
                    List.foldl
                        (\sticker { stickers, tasks, discordStickers } ->
                            case OneToOne.second sticker.id discordStickers of
                                Just _ ->
                                    { tasks = tasks, stickers = stickers, discordStickers = discordStickers }

                                Nothing ->
                                    case sticker.stickerType of
                                        Discord.StandardSticker ->
                                            { tasks = tasks
                                            , stickers = stickers
                                            , discordStickers = discordStickers
                                            }

                                        Discord.GuildSticker ->
                                            let
                                                stickerId : Id StickerId
                                                stickerId =
                                                    Id.nextId stickers
                                            in
                                            { tasks =
                                                (FileStatus.uploadUrl
                                                    { sessionId = backendSessionIdHash
                                                    , url = Discord.stickerUrl sticker.stickerType sticker.formatType sticker.id
                                                    }
                                                    |> taskResult
                                                    |> Task.map (\result -> ( stickerId, result ))
                                                )
                                                    :: tasks
                                            , stickers =
                                                SeqDict.insert
                                                    stickerId
                                                    { url = StickerLoading
                                                    , name = sticker.name
                                                    , format = sticker.formatType
                                                    }
                                                    stickers
                                            , discordStickers = OneToOne.insert sticker.id stickerId discordStickers
                                            }
                        )
                        state
                        guild.stickers
                )
                { tasks = [], stickers = model.stickers, discordStickers = model.discordStickers }
                readyData.guilds
    in
    ( { model
        | discordGuilds =
            List.foldl
                (\guild ( mergedMembers, guilds ) ->
                    case mergedMembers of
                        head :: rest ->
                            ( rest, addDiscordGuild stickerData.discordStickers head guild guilds )

                        [] ->
                            ( [], addDiscordGuild stickerData.discordStickers [] guild guilds )
                )
                ( case readyData.mergedMembers of
                    Included members2 ->
                        members2

                    Missing ->
                        []
                , model.discordGuilds
                )
                readyData.guilds
                |> Tuple.second
        , discordUsers = List.foldl addDiscordUserData model.discordUsers discordUsers
        , discordStickers = stickerData.discordStickers
        , stickers = stickerData.stickers
      }
    , Command.batch
        [ getUserAvatars model.discordUsers discordUsers
        , Task.sequence stickerData.tasks
            |> Task.andThen (\stickers -> Task.map (GotDiscordGuildStickers stickers) Time.now)
            |> Task.perform identity
        , (List.filterMap
            (\guild ->
                if SeqDict.member guild.properties.id model.discordGuilds then
                    Nothing

                else
                    getDiscordGuildData guild |> Just
            )
            readyData.guilds
            |> Task.sequence
          )
            |> Task.andThen
                (\data ->
                    Task.map
                        (\time ->
                            HandleReadyDataStep2 time readyData.user.id (Ok ( discordDmChannels, data ))
                        )
                        Time.now
                )
            |> Task.onError (\error -> Task.map (\time -> HandleReadyDataStep2 time readyData.user.id (Err error)) Time.now)
            |> Task.perform identity
        ]
    )


addDiscordGuild :
    OneToOne (Discord.Id Discord.StickerId) (Id StickerId)
    -> List Discord.MergedMember
    -> Discord.GatewayGuild
    -> SeqDict (Discord.Id Discord.GuildId) DiscordBackendGuild
    -> SeqDict (Discord.Id Discord.GuildId) DiscordBackendGuild
addDiscordGuild existingStickers members guild discordGuilds =
    SeqDict.update
        guild.properties.id
        (\maybe ->
            case maybe of
                Just existingGuild ->
                    { existingGuild
                        | name = GuildName.fromStringLossy guild.properties.name
                        , membersAndOwner =
                            List.foldl
                                (\member dict ->
                                    MembersAndOwner.addOrUpdateMember
                                        member.userId
                                        { joinedAt = Just member.joinedAt }
                                        dict
                                )
                                existingGuild.membersAndOwner
                                members
                        , stickers =
                            List.filterMap
                                (\sticker -> OneToOne.second sticker.id existingStickers)
                                guild.stickers
                                |> SeqSet.fromList
                    }
                        |> Just

                Nothing ->
                    { name = GuildName.fromStringLossy guild.properties.name
                    , icon = Nothing
                    , channels = SeqDict.empty -- Gets filled after LinkDiscordUserStep2 is triggered
                    , membersAndOwner =
                        MembersAndOwner.init
                            (List.map (\member -> ( member.userId, { joinedAt = Just member.joinedAt } )) members
                                |> SeqDict.fromList
                            )
                            guild.properties.ownerId
                    , stickers =
                        List.filterMap
                            (\sticker -> OneToOne.second sticker.id existingStickers)
                            guild.stickers
                            |> SeqSet.fromList
                    }
                        |> Just
        )
        discordGuilds


uploadAttachmentsForMessages :
    BackendModel
    -> List Discord.Message
    -> Task restriction x (List (Result Http.Error ( DiscordAttachmentId, FileStatus.UploadResponse )))
uploadAttachmentsForMessages model messages =
    List.concatMap
        (\message ->
            List.filterMap
                (\attachment ->
                    if SeqDict.member (DiscordAttachmentId.fromUrl attachment.url) model.discordAttachments then
                        Nothing

                    else
                        Just ( DiscordAttachmentId.fromUrl attachment.url, attachment )
                )
                message.attachments
        )
        messages
        |> SeqDict.fromList
        |> SeqDict.toList
        |> List.map
            (\( _, attachment ) ->
                FileStatus.uploadUrl { sessionId = backendSessionIdHash, url = attachment.url }
                    |> Task.map (\uploadResponse -> Ok ( DiscordAttachmentId.fromUrl attachment.url, uploadResponse ))
                    |> Task.onError (\error -> Task.succeed (Err error))
            )
        |> Task.sequence


getDiscordGuildData :
    Discord.GatewayGuild
    ->
        Task
            BackendOnly
            Discord.HttpError
            ( Discord.Id Discord.GuildId
            , { guild : Discord.GatewayGuild, channels : List Discord.Channel, icon : Maybe FileStatus.UploadResponse }
            )
getDiscordGuildData gatewayGuild =
    Task.map
        (\maybeIcon ->
            ( gatewayGuild.properties.id
            , { guild = gatewayGuild
              , channels = gatewayGuild.channels
              , icon = maybeIcon
              }
            )
        )
        (case gatewayGuild.properties.icon of
            Just icon ->
                loadImage
                    (Discord.guildIconUrl
                        { size = Discord.DefaultImageSize
                        , imageType = Discord.Choice1 Discord.Png
                        }
                        gatewayGuild.properties.id
                        icon
                    )

            Nothing ->
                Task.succeed Nothing
        )



--Task.map2
--    (\public private -> ( public, private ))
--    (Discord.getPublicArchivedThreadsPayload
--        auth
--        { channelId = channelId
--        , before = Nothing
--        , limit = Just 100
--        }
--        |> http
--        |> Task.map .threads
--        |> Task.onError (\_ -> Task.succeed [])
--    )
--    (Discord.getPrivateArchivedThreadsPayload
--        auth
--        { channelId = channelId
--        , before = Nothing
--        , limit = Just 100
--        }
--        |> http
--        |> Task.map .threads
--        |> Task.onError (\_ -> Task.succeed [])
--    )
--    |> Task.andThen
--        (\( publicArchivedThreads, privateArchivedThreads ) ->
--            let
--                allThreads : List Discord.Channel
--                allThreads =
--                    publicArchivedThreads ++ privateArchivedThreads
--            in
--            List.filterMap
--                (\thread ->
--                    case thread.parentId of
--                        Included (Just parentId) ->
--                            if parentId == channelId then
--                                getManyMessages auth { channelId = thread.id, limit = 1000 }
--                                    |> Task.onError (\_ -> Task.succeed [])
--                                    |> Task.andThen
--                                        (\messages ->
--                                            Task.map
--                                                (\uploadResponses ->
--                                                    { channelId = parentId
--                                                    , channel = thread
--                                                    , messages = List.reverse messages
--                                                    , uploadResponses = uploadResponses
--                                                    }
--                                                )
--                                                (uploadAttachmentsForMessages model messages)
--                                        )
--                                    |> Just
--
--                            else
--                                Nothing
--
--                        _ ->
--                            Nothing
--                )
--                allThreads
--                |> Task.sequence
--        )


getManyMessages : Discord.Authentication -> { a | channelId : Discord.Id Discord.ChannelId, limit : Int } -> Task BackendOnly Discord.HttpError (List Discord.Message)
getManyMessages authentication { channelId, limit } =
    Discord.getMessagesPayload authentication { channelId = channelId, limit = min limit 100, relativeTo = Discord.MostRecent }
        |> http
        |> Task.andThen (\messages -> getManyMessagesHelper authentication channelId (limit - 100) Array.empty (Array.fromList messages))


getManyMessagesHelper :
    Discord.Authentication
    -> Discord.Id Discord.ChannelId
    -> Int
    -> Array Discord.Message
    -> Array Discord.Message
    -> Task BackendOnly Discord.HttpError (List Discord.Message)
getManyMessagesHelper authentication channelId limit restOfMessages messages =
    case Array.Extra.last messages of
        Just last ->
            if Array.length messages >= 100 && limit > 0 then
                Discord.getMessagesPayload
                    authentication
                    { channelId = channelId, limit = min limit 100, relativeTo = Discord.Before last.id }
                    |> http
                    |> Task.onError
                        (\error ->
                            case error of
                                Discord.TooManyRequests429 rateLimit ->
                                    Process.sleep rateLimit.retryAfter
                                        |> Task.andThen
                                            (\() ->
                                                Discord.getMessagesPayload
                                                    authentication
                                                    { channelId = channelId
                                                    , limit = min limit 100
                                                    , relativeTo = Discord.Before last.id
                                                    }
                                                    |> http
                                            )

                                _ ->
                                    Task.fail error
                        )
                    |> Task.andThen
                        (\newMessages ->
                            getManyMessagesHelper
                                authentication
                                channelId
                                (limit - 100)
                                (Array.append restOfMessages messages)
                                (Array.fromList newMessages)
                        )

            else
                Task.succeed (Array.append restOfMessages messages |> Array.toList)

        Nothing ->
            Task.succeed (Array.append restOfMessages messages |> Array.toList)


addDiscordUserData :
    Discord.PartialUser
    -> SeqDict (Discord.Id Discord.UserId) DiscordUserData
    -> SeqDict (Discord.Id Discord.UserId) DiscordUserData
addDiscordUserData user discordUsers =
    SeqDict.update
        user.id
        (\maybe ->
            (case maybe of
                Just (FullData data) ->
                    let
                        fullUser =
                            data.user
                    in
                    FullData
                        { data
                            | user =
                                { fullUser
                                    | username = user.username
                                    , avatar = user.avatar
                                    , discriminator = user.discriminator
                                }
                        }

                Just (BasicData data) ->
                    BasicData { data | user = user }

                Just (NeedsAuthAgain data) ->
                    let
                        fullUser =
                            data.user
                    in
                    NeedsAuthAgain
                        { data
                            | user =
                                { fullUser
                                    | username = user.username
                                    , avatar = user.avatar
                                    , discriminator = user.discriminator
                                }
                        }

                Nothing ->
                    BasicData { user = user, icon = Nothing }
            )
                |> Just
        )
        discordUsers


handleListGuildMembersResponse :
    Discord.GuildMembersChunkData
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleListGuildMembersResponse chunkData model =
    ( { model
        | discordUsers =
            List.foldl
                (\member discordUsers -> addDiscordUserData (Discord.userToPartialUser member.user) discordUsers)
                model.discordUsers
                chunkData.members
        , discordGuilds =
            SeqDict.updateIfExists
                chunkData.guildId
                (\guild ->
                    { guild
                        | membersAndOwner =
                            List.foldl
                                (\member guildMembers ->
                                    MembersAndOwner.addOrUpdateMember
                                        member.user.id
                                        { joinedAt = Just member.joinedAt }
                                        guildMembers
                                )
                                guild.membersAndOwner
                                chunkData.members
                    }
                )
                model.discordGuilds
      }
    , List.map .user chunkData.members |> getUserAvatars model.discordUsers
    )


userAvatar : DiscordUserData -> Maybe (Discord.ImageHash Discord.AvatarHash)
userAvatar user =
    case user of
        BasicData data ->
            data.user.avatar

        FullData data ->
            data.user.avatar

        NeedsAuthAgain data ->
            data.user.avatar


getUserAvatars :
    SeqDict (Discord.Id Discord.UserId) DiscordUserData
    -> List { a | id : Discord.Id Discord.UserId, avatar : Maybe (Discord.ImageHash Discord.AvatarHash) }
    -> Command restriction toMsg BackendMsg
getUserAvatars existingUsers users =
    Task.map2
        GotDiscordUserAvatars
        (List.filterMap
            (\user ->
                let
                    needsUpdate : Bool
                    needsUpdate =
                        case SeqDict.get user.id existingUsers of
                            Just existingUser ->
                                userAvatar existingUser /= user.avatar

                            Nothing ->
                                True
                in
                if needsUpdate then
                    Task.map
                        (\maybeAvatar -> ( user.id, maybeAvatar ))
                        (case user.avatar of
                            Just avatar ->
                                loadImage
                                    (Discord.userAvatarUrl
                                        { size = Discord.DefaultImageSize
                                        , imageType = Discord.Choice1 Discord.Png
                                        }
                                        user.id
                                        avatar
                                    )

                            Nothing ->
                                Task.succeed Nothing
                        )
                        |> Just

                else
                    Nothing
            )
            users
            |> Task.sequence
            |> taskResult
        )
        Time.now
        |> Task.perform identity


loadImage : String -> Task restriction x (Maybe FileStatus.UploadResponse)
loadImage url =
    Http.task
        { method = "GET"
        , headers = []
        , url = url
        , body = Http.emptyBody
        , resolver =
            Http.bytesResolver
                (\result2 ->
                    case result2 of
                        Http.GoodStatus_ _ body ->
                            Ok (Just body)

                        _ ->
                            Ok Nothing
                )
        , timeout = Just (Duration.seconds 30)
        }
        |> Task.andThen
            (\maybeBytes ->
                case maybeBytes of
                    Just bytes ->
                        FileStatus.uploadBytes backendSessionIdHash bytes
                            |> Task.map Just
                            |> Task.onError (\_ -> Task.succeed Nothing)

                    Nothing ->
                        Task.succeed Nothing
            )


http : Discord.HttpRequest value -> Task restriction Discord.HttpError value
http request =
    Http.task
        { method = "POST"
        , headers = []
        , url = FileStatus.domain ++ "/file/custom-request"
        , body =
            Json.Encode.object
                [ ( "method", Json.Encode.string request.method )
                , ( "url", Json.Encode.string request.url )
                , ( "headers"
                  , Json.Encode.list
                        (\( key, value ) ->
                            Json.Encode.object
                                [ ( "key", Json.Encode.string key )
                                , ( "value", Json.Encode.string value )
                                ]
                        )
                        ((if request.method == "GET" then
                            []

                          else
                            [ ( "Content-Type", "application/json" ) ]
                         )
                            ++ request.headers
                        )
                  )
                , ( "body"
                  , case request.body of
                        Just body ->
                            Json.Encode.encode 0 body |> Json.Encode.string

                        Nothing ->
                            Json.Encode.null
                  )
                ]
                |> Http.jsonBody
        , resolver =
            Http.stringResolver
                (\response ->
                    case response of
                        Http.BadUrl_ badUrl ->
                            "Bad url " ++ badUrl |> Discord.UnexpectedError |> Err

                        Http.Timeout_ ->
                            Err Discord.Timeout

                        Http.NetworkError_ ->
                            Err Discord.NetworkError

                        Http.BadStatus_ metadata body ->
                            Discord.handleBadStatus metadata body

                        Http.GoodStatus_ _ body ->
                            Discord.handleGoodStatus request.decoder body
                )
        , timeout = Nothing
        }


sendMessage :
    DiscordFullUserData
    -> Discord.Id Discord.ChannelId
    -> Maybe (Discord.Id Discord.MessageId)
    -> SeqDict (Id FileId) FileData
    -> Nonempty (RichText (Discord.Id Discord.UserId))
    -> Task BackendOnly Discord.HttpError Discord.Message
sendMessage discordUser channelId maybeReplyTo attachedFiles text =
    List.map
        (\attachment ->
            Http.task
                { method = "GET"
                , headers = []
                , url = FileStatus.fileUrl attachment.contentType attachment.fileHash
                , body = Http.emptyBody
                , resolver =
                    Http.bytesResolver
                        (\response ->
                            case response of
                                Http.BadUrl_ _ ->
                                    Err ()

                                Http.Timeout_ ->
                                    Err ()

                                Http.NetworkError_ ->
                                    Err ()

                                Http.BadStatus_ _ _ ->
                                    Err ()

                                Http.GoodStatus_ _ body ->
                                    Ok body
                        )
                , timeout = Duration.seconds 30 |> Just
                }
                |> Task.map (\bytes -> Ok ( attachment, bytes ))
                |> Task.onError (\() -> Task.succeed (Err ()))
        )
        (SeqDict.values attachedFiles)
        |> Task.sequence
        |> Task.andThen
            (\attachments ->
                let
                    attachments2 : List ( FileData, Bytes )
                    attachments2 =
                        List.filterMap Result.toMaybe attachments
                in
                (if List.isEmpty attachments2 then
                    Task.succeed []

                 else
                    Discord.uploadAttachmentsPayload
                        discordUser.auth
                        channelId
                        (List.map
                            (\( fileData, bytes ) ->
                                { fileSize = Bytes.width bytes
                                , filename = FileName.toString fileData.fileName
                                }
                            )
                            attachments2
                        )
                        |> http
                )
                    |> Task.andThen
                        (\uploadAttachmentsResponse ->
                            uploadAttachments attachments2 uploadAttachmentsResponse
                                |> Task.andThen
                                    (\_ ->
                                        Discord.createMessagePayload
                                            (Discord.userToken discordUser.auth)
                                            { channelId = channelId
                                            , content = RichText.toDiscord text |> Discord.Markdown.toString
                                            , replyTo = maybeReplyTo
                                            , attachments =
                                                List.map2
                                                    (\a ( fileData, _ ) ->
                                                        { filename = FileName.toString fileData.fileName
                                                        , uploadedFilename = a.uploadFilename
                                                        , contentType =
                                                            OneToOne.second fileData.contentType FileStatus.contentTypes
                                                                |> Maybe.withDefault ""
                                                        }
                                                    )
                                                    uploadAttachmentsResponse
                                                    attachments2
                                            , stickers = []
                                            }
                                            |> http
                                    )
                        )
            )


uploadAttachments : List ( FileData, Bytes ) -> List Discord.UploadAttachmentResponse -> Task BackendOnly x (List (Result () ()))
uploadAttachments files uploadAttachmentsResponses =
    List.map2
        (\( _, bytes ) uploadAttachmentsResponse ->
            Http.task
                { method = "PUT"
                , headers = []
                , url = uploadAttachmentsResponse.uploadUrl
                , body = Http.bytesBody "application/octet-stream" bytes
                , resolver =
                    Http.bytesResolver
                        (\response ->
                            case response of
                                Http.BadUrl_ _ ->
                                    Err ()

                                Http.Timeout_ ->
                                    Err ()

                                Http.NetworkError_ ->
                                    Err ()

                                Http.BadStatus_ _ _ ->
                                    Err ()

                                Http.GoodStatus_ _ _ ->
                                    Ok ()
                        )
                , timeout = Duration.seconds 30 |> Just
                }
                |> Task.map (\() -> Ok ())
                |> Task.onError (\() -> Task.succeed (Err ()))
        )
        files
        uploadAttachmentsResponses
        |> Task.sequence


reloadChannelMaxMessages : Int
reloadChannelMaxMessages =
    10000
