module DiscordSync exposing
    ( addDiscordChannel
    , addUploadResponsesToDiscordAttachments
    , attachmentsToFileData
    , closeEventCodeToInt
    , discordUserWebsocketMsg
    , getForumChannelReload
    , getManyMessages
    , getThreadsForMessages
    , handleCreateMessage
    , handleEditMessage
    , handleForumPostRenamed
    , http
    , messagesAndLinks
    , reloadChannelMaxMessages
    , sendMessage
    , threadName
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
import CustomEmoji exposing (CustomEmojiData, CustomEmojiUrl(..))
import Discord exposing (OptionalData(..))
import DiscordAttachmentId exposing (DiscordAttachmentId)
import DiscordUserData exposing (DiscordFullUserData, DiscordUserData(..))
import Duration
import Effect.Command as Command exposing (BackendOnly, Command)
import Effect.Http as Http
import Effect.Lamdera as Lamdera exposing (SessionId)
import Effect.Process as Process
import Effect.Task as Task exposing (Task)
import Effect.Time as Time
import Effect.Websocket as Websocket
import Emoji exposing (EmojiOrCustomEmoji(..))
import FileName
import FileStatus exposing (FileData, FileHash, FileId, FileMetadata)
import GuildName
import Id exposing (AnyGuildOrDmId(..), ChannelMessageId, CustomEmojiId, DiscordGuildOrDmId(..), Id, StickerId, ThreadMessageId, ThreadRoute(..), ThreadRouteWithMaybeMessage(..), ThreadRouteWithMessage(..), UserId)
import IdArray exposing (IdArray)
import Json.Decode
import Json.Encode
import List.Extra
import List.Nonempty exposing (Nonempty(..))
import LocalState exposing (ChannelStatus(..), DiscordBackendChannel, DiscordBackendGuild, DiscordMessageAlreadyExists(..), DiscordRole, DiscordThreadReload, WebsocketClosedEvent(..))
import Log
import MembersAndOwner exposing (MembersAndOwner)
import Message exposing (ChangeAttachments(..), Message(..))
import NonemptyDict exposing (NonemptyDict)
import OneToOne exposing (OneToOne)
import Pages.Admin
import PersonName
import Quantity
import RichText exposing (DiscordCustomEmojiIdAndName, RichText)
import SecretId exposing (SecretId, ServerSecret)
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import Sticker exposing (StickerData, StickerUrl(..))
import String.Nonempty exposing (NonemptyString(..))
import Thread exposing (DiscordBackendThread)
import Types exposing (BackendModel, BackendMsg(..), DiscordAttachmentData, LocalChange(..), LocalMsg(..), MessageFromGuildOrDm(..), ServerChange(..), ToFrontend(..))
import UInt64
import User
import UserSession exposing (DiscordFrontendUser, UserSession)


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
    let
        customEmojiData :
            { tasks : List (Task BackendOnly x ( Id CustomEmojiId, Result Http.Error FileStatus.UploadResponse ))
            , customEmojis : SeqDict (Id CustomEmojiId) CustomEmojiData
            , discordCustomEmojis : OneToOne DiscordCustomEmojiIdAndName (Id CustomEmojiId)
            }
        customEmojiData =
            handleCustomEmojis
                model.serverSecret
                (emojiDataToEmojiIdAndName [ reaction.emoji ])
                { tasks = [], customEmojis = model.customEmojis, discordCustomEmojis = model.discordCustomEmojis }

        emoji : EmojiOrCustomEmoji
        emoji =
            emojiFromDiscord customEmojiData.discordCustomEmojis reaction.emoji

        loadCustomEmojiCmd : MessageFromGuildOrDm -> Command BackendOnly ToFrontend BackendMsg
        loadCustomEmojiCmd guildOrDmId =
            case customEmojiData.tasks of
                [] ->
                    Command.none

                tasks ->
                    Task.sequence tasks
                        |> Task.andThen
                            (\customEmojis2 ->
                                Task.map (GotDiscordMessageCustomEmojis guildOrDmId customEmojis2) Time.now
                            )
                        |> Task.perform identity
    in
    case reaction.guildId of
        Included guildId ->
            case SeqDict.get guildId model.discordGuilds of
                Just guild ->
                    case discordChannelIdToChannelId reaction.channelId reaction.messageId guild of
                        Just ( channelId, channel, threadRoute ) ->
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
                                                    { joinedAt = Nothing, roles = SeqSet.empty }
                                                    guild.membersAndOwner
                                                    |> Result.withDefault guild.membersAndOwner
                                        }
                                        model.discordGuilds
                                , customEmojis = customEmojiData.customEmojis
                                , discordCustomEmojis = customEmojiData.discordCustomEmojis
                              }
                            , Command.batch
                                [ Broadcast.toDiscordGuildChannel
                                    guildId
                                    reaction.channelId
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
                                , loadCustomEmojiCmd (MessageFromGuildOrDm_Guild guildId)
                                ]
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
                                , customEmojis = customEmojiData.customEmojis
                                , discordCustomEmojis = customEmojiData.discordCustomEmojis
                              }
                            , Command.batch
                                [ Broadcast.toDiscordDmChannel
                                    dmChannelId
                                    ((if isAdding then
                                        Server_DiscordAddReactionDmEmoji reaction.userId dmChannelId messageId emoji

                                      else
                                        Server_DiscordRemoveReactionDmEmoji reaction.userId dmChannelId messageId emoji
                                     )
                                        |> ServerChange
                                    )
                                    model
                                , loadCustomEmojiCmd (MessageFromGuildOrDm_Dm dmChannelId)
                                ]
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
    -> SeqDict (Id FileId) { fileData : FileData, isSpoilered : Bool }
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
                            RichText.fromDiscord
                                edit.content
                                attachments
                                (Included edit.embeds)
                                model.discordCustomEmojis
                                (case edit.stickerItems of
                                    Missing ->
                                        []

                                    Included stickers ->
                                        List.filterMap
                                            (\sticker -> OneToOne.second sticker.id model.discordStickers)
                                            stickers
                                )
                                edit.messageSnapshots
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


{-| The Discord user that wrote a message, in the form the frontend shows names in. It's
sent along with the message because the receiver might not have that user loaded yet. That
happens whenever the message comes from a guild they aren't looking at, which is most of
the time for messages that show up in the unread overview.
-}
messageSender : Discord.User -> BackendModel -> DiscordFrontendUser
messageSender author model =
    case SeqDict.get author.id model.discordUsers of
        Just discordUser ->
            User.discordUserDataToFrontendUser discordUser

        Nothing ->
            { name = PersonName.fromStringLossy author.username, icon = Nothing }


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
    -> SeqDict (Id FileId) { fileData : FileData, isSpoilered : Bool }
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleDiscordGuildEditMessage guildId guild edit attachments model =
    let
        richText : Nonempty (RichText (Discord.Id Discord.UserId))
        richText =
            RichText.fromDiscord
                edit.content
                attachments
                (Included edit.embeds)
                model.discordCustomEmojis
                (case edit.stickerItems of
                    Missing ->
                        []

                    Included stickers ->
                        List.filterMap (\sticker -> OneToOne.second sticker.id model.discordStickers) stickers
                )
                edit.messageSnapshots
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
                            , Broadcast.toDiscordGuildChannel
                                guildId
                                edit.channelId
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
                            , Broadcast.toDiscordGuildChannel
                                guildId
                                edit.channelId
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
                                    , Broadcast.toDiscordGuildChannel
                                        discordGuildId
                                        discordChannelId
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
                                                            , Broadcast.toDiscordGuildChannel
                                                                discordGuildId
                                                                discordChannelId
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
    -> { b | linkedMessageIds : OneToOne (Discord.Id Discord.MessageId) (Id messageId), messages : IdArray messageId (Message messageId (Discord.Id Discord.UserId)) }
    ->
        Maybe
            ( Id messageId
            , { b | linkedMessageIds : OneToOne (Discord.Id Discord.MessageId) (Id messageId), messages : IdArray messageId (Message messageId (Discord.Id Discord.UserId)) }
            )
deleteMessageHelper discordMessageId channel =
    case OneToOne.second discordMessageId channel.linkedMessageIds of
        Just messageId ->
            case IdArray.get messageId channel.messages of
                Just (UserTextMessage message) ->
                    ( messageId
                    , { channel
                        | messages =
                            IdArray.set
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
                    True

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
        , isForum = discordChannel.type_ == Discord.GuildForum
        , messages = IdArray.empty
        , status = ChannelActive
        , lastTypedAt = SeqDict.empty
        , linkedMessageIds = OneToOne.empty
        , threads = SeqDict.empty
        , dateDividerDrawings = SeqDict.empty
        , permissionOverwrites =
            case discordChannel.permissionOverwrites of
                Missing ->
                    []

                Included permissions ->
                    permissions
        }
            |> Just

    else
        Nothing


messagesAndLinks :
    { a
        | messages : IdArray messageId (Message messageId (Discord.Id Discord.UserId))
        , linkedMessageIds : OneToOne (Discord.Id Discord.MessageId) (Id messageId)
    }
    -> List Discord.Message
    -> OneToOne DiscordCustomEmojiIdAndName (Id CustomEmojiId)
    -> OneToOne (Discord.Id Discord.StickerId) (Id StickerId)
    -> SeqDict DiscordAttachmentId DiscordAttachmentData
    ->
        ( IdArray messageId (Message messageId (Discord.Id Discord.UserId))
        , OneToOne (Discord.Id Discord.MessageId) (Id messageId)
        )
messagesAndLinks existingChannelOrThread messages customEmojis discordStickers discordAttachments =
    let
        -- The ids of the messages a thread can hang off of. A thread created message isn't one
        -- of them, it stands in for a thread that has no message to hang off of.
        threadStarterIds : SeqSet (Discord.Id Discord.MessageId)
        threadStarterIds =
            List.filterMap
                (\message ->
                    case message.type_ of
                        Discord.ThreadCreated ->
                            Nothing

                        _ ->
                            Just message.id
                )
                messages
                |> SeqSet.fromList

        messages2 : List Discord.Message
        messages2 =
            List.filter
                (\message ->
                    case message.type_ of
                        Discord.ThreadStarterMessage ->
                            -- Discord posts this as the first message of a thread that was started
                            -- from a message. It never has any content, it only points back at the
                            -- message the thread was started from, which is the message the thread
                            -- hangs off of here, so there's nothing to show.
                            False

                        Discord.ThreadCreated ->
                            -- If the thread this announces was started from a message we are also
                            -- loading then the thread hangs off that message and this message would
                            -- be a second copy of it.
                            SeqSet.member (messageLinkId message) threadStarterIds |> not

                        _ ->
                            True
                )
                messages

        linkedMessageIds : OneToOne (Discord.Id Discord.MessageId) (Id messageId)
        linkedMessageIds =
            List.indexedMap (\index message -> ( messageLinkId message, Id.fromInt index )) messages2
                |> OneToOne.fromList
    in
    ( List.map
        (\message ->
            let
                attachments : SeqDict (Id FileId) { fileData : FileData, isSpoilered : Bool }
                attachments =
                    messageToFileData message discordAttachments
            in
            Message.userTextMessageNoEmbeds
                message.timestamp
                message.author.id
                (RichText.fromDiscord
                    message.content
                    attachments
                    message.embeds
                    customEmojis
                    (case message.stickerItems of
                        Missing ->
                            []

                        Included stickers ->
                            List.filterMap (\sticker -> OneToOne.second sticker.id discordStickers) stickers
                    )
                    message.messageSnapshots
                )
                (case OneToOne.second message.id existingChannelOrThread.linkedMessageIds of
                    Just messageId ->
                        case IdArray.get messageId existingChannelOrThread.messages of
                            Just existingMessage ->
                                Message.reactionEmojis existingMessage

                            Nothing ->
                                SeqDict.empty

                    Nothing ->
                        SeqDict.empty
                )
                (case message.referencedMessage of
                    Discord.Referenced referenced ->
                        OneToOne.second referenced.id linkedMessageIds

                    Discord.ReferenceDeleted ->
                        Nothing

                    Discord.NoReference ->
                        Nothing
                )
                (SeqDict.map (\_ attachment -> attachment.fileData) attachments)
        )
        messages2
        |> IdArray.fromList
    , linkedMessageIds
    )


{-| The Discord message id a message gets linked to. Threads hang off a message here, so a
thread created message (which Discord posts in the parent channel when a thread is created
without a message or from a message that is old) stands in for the thread it announces:
linking it to the thread instead of to itself means messages written in the thread end up
in it, and lets us notice when the thread was started from a message we already have, since
the thread reuses that message's id.
-}
messageLinkId : Discord.Message -> Discord.Id Discord.MessageId
messageLinkId message =
    case ( message.type_, message.messageReference ) of
        ( Discord.ThreadCreated, Included reference ) ->
            case reference.channelId of
                Included threadId ->
                    Discord.idToUInt64 threadId |> Discord.idFromUInt64

                Missing ->
                    message.id

        _ ->
            message.id


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
                        { fileHash = uploadResponse.fileHash, metadata = FileStatus.uploadResponseMetadata uploadResponse }
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


taskResult : Task restriction a value -> Task restriction x (Result a value)
taskResult task =
    Task.map Ok task |> Task.onError (\error -> Task.succeed (Err error))


nonemptyTaskSequence : Nonempty (Task restriction x a) -> Task restriction x (Nonempty a)
nonemptyTaskSequence nonempty =
    Task.map2 Nonempty (List.Nonempty.head nonempty) (Task.sequence (List.Nonempty.tail nonempty))


joinThread :
    SecretId ServerSecret
    -> Discord.UserAuth
    -> Discord.Id Discord.GuildId
    -> Discord.Id Discord.MessageId
    -> Command BackendOnly toMsg BackendMsg
joinThread secretKey authentication guildId threadId =
    Discord.joinThreadPayload (Discord.userToken authentication) threadId
        |> http secretKey
        |> taskResult
        |> Task.andThen (\result -> Task.map (JoinedDiscordThread guildId result) Time.now)
        |> Task.perform identity


handleCreateMessage :
    String
    -> Discord.Message
    -> SeqDict (Id FileId) { fileData : FileData, isSpoilered : Bool }
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
                                RichText.fromDiscord
                                    discordMessage.content
                                    attachments
                                    discordMessage.embeds
                                    model.discordCustomEmojis
                                    (case discordMessage.stickerItems of
                                        Missing ->
                                            []

                                        Included stickers ->
                                            List.filterMap
                                                (\sticker -> OneToOne.second sticker.id model.discordStickers)
                                                stickers
                                    )
                                    discordMessage.messageSnapshots

                            replyTo : Maybe (Id ChannelMessageId)
                            replyTo =
                                referencedMessageToMessageId discordMessage channel

                            attachments2 : SeqDict (Id FileId) FileData
                            attachments2 =
                                SeqDict.map (\_ attachment -> attachment.fileData) attachments

                            ( message, embedCmds, stickersToFrontend ) =
                                Message.userTextMessageBackend
                                    model.serverSecret
                                    discordMessage.timestamp
                                    discordMessage.author.id
                                    richText
                                    replyTo
                                    attachments2
                                    model.stickers

                            guildOrDmId : DiscordGuildOrDmId
                            guildOrDmId =
                                DiscordGuildOrDmId_Dm { currentUserId = discordMessage.author.id, channelId = dmChannelId }
                        in
                        case LocalState.createDiscordDmChannelMessageBackend discordMessage.id (Message.UserTextMessage message) channel of
                            Ok ( messageId, channel2 ) ->
                                let
                                    ( sessions, notification ) =
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
                                            (RichText.toStringWithGetter Time.utc DiscordUserData.username True model.discordUsers richText)
                                            message
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
                                    , sessions = sessions
                                  }
                                , Command.batch
                                    [ case
                                        SeqDict.get
                                            { currentUserId = discordMessage.author.id, channelId = dmChannelId }
                                            model2.pendingDiscordCreateDmMessages
                                      of
                                        Just ( clientId, changeId, timezone ) ->
                                            Command.batch
                                                [ LocalChangeResponse
                                                    changeId
                                                    (Local_Discord_SendMessage
                                                        discordMessage.timestamp
                                                        timezone
                                                        guildOrDmId
                                                        (RichText.toStringWithGetter
                                                            timezone
                                                            DiscordUserData.username
                                                            False
                                                            model2.discordUsers
                                                            richText
                                                            |> String.Nonempty.fromString
                                                            |> Maybe.withDefault (NonemptyString ' ' "")
                                                        )
                                                        (NoThreadWithMaybeMessage replyTo)
                                                        attachments2
                                                    )
                                                    |> Lamdera.sendToFrontend clientId
                                                , Broadcast.toDiscordDmChannelExcludingOne
                                                    clientId
                                                    dmChannelId
                                                    (Server_Discord_SendMessage
                                                        discordMessage.timestamp
                                                        guildOrDmId
                                                        (messageSender discordMessage.author model2)
                                                        richText
                                                        (NoThreadWithMaybeMessage replyTo)
                                                        attachments2
                                                        stickersToFrontend
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
                                                        (messageSender discordMessage.author model2)
                                                        richText
                                                        (NoThreadWithMaybeMessage replyTo)
                                                        attachments2
                                                        stickersToFrontend
                                                        |> ServerChange
                                                    )
                                                    model2
                                                ]
                                    , Command.batch notification
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
    -> SeqDict (Id FileId) { fileData : FileData, isSpoilered : Bool }
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleDiscordCreateGuildMessage websocketJson discordGuildId content discordMessage attachments model =
    case SeqDict.get discordGuildId model.discordGuilds of
        Just guild ->
            case discordGetGuildChannel discordMessage guild of
                Just ( channelId, channel, threadRoute ) ->
                    let
                        linkedMessageId : Discord.Id Discord.MessageId
                        linkedMessageId =
                            messageLinkId discordMessage

                        alreadyHaveMessage : Bool
                        alreadyHaveMessage =
                            case threadRoute of
                                -- The text of a forum post has the same id as the thread it's
                                -- written in, which is the id its title is linked under, so
                                -- looking in the channel would mistake it for a message we
                                -- already have
                                ViewThreadWithMaybeMessage threadId _ ->
                                    case SeqDict.get threadId channel.threads of
                                        Just thread ->
                                            OneToOne.memberFirst linkedMessageId thread.linkedMessageIds

                                        Nothing ->
                                            False

                                NoThreadWithMaybeMessage _ ->
                                    OneToOne.memberFirst linkedMessageId channel.linkedMessageIds
                    in
                    if alreadyHaveMessage then
                        ( model, Command.none )

                    else
                        case discordMessage.type_ of
                            Discord.ThreadStarterMessage ->
                                -- Discord posts this as the first message of a thread that was started
                                -- from a message. It never has any content, it only points back at the
                                -- message the thread was started from, which is the message the thread
                                -- hangs off of here, so there's nothing to show.
                                ( model, Command.none )

                            Discord.GuildMemberJoin ->
                                let
                                    message : Message messageId (Discord.Id Discord.UserId)
                                    message =
                                        Message.userJoined discordMessage.timestamp discordMessage.author.id
                                in
                                case LocalState.createDiscordChannelMessageBackend linkedMessageId message channel of
                                    Ok ( _, channel4 ) ->
                                        let
                                            userAvatars : Command BackendOnly ToFrontend BackendMsg
                                            userAvatars =
                                                getUserAvatars model.serverSecret model.discordUsers [ discordMessage.author ]

                                            model2 : BackendModel
                                            model2 =
                                                { model
                                                    | discordGuilds =
                                                        SeqDict.insert
                                                            discordGuildId
                                                            { guild
                                                                | channels = SeqDict.insert channelId channel4 guild.channels
                                                                , membersAndOwner =
                                                                    MembersAndOwner.addMember
                                                                        discordMessage.author.id
                                                                        { joinedAt = Just discordMessage.timestamp
                                                                        , roles = SeqSet.empty
                                                                        }
                                                                        guild.membersAndOwner
                                                                        |> Result.withDefault guild.membersAndOwner
                                                            }
                                                            model.discordGuilds
                                                    , discordUsers =
                                                        addDiscordUserData
                                                            (Discord.userToPartialUser discordMessage.author)
                                                            model.discordUsers
                                                }

                                            ( sessions, notificationCmds ) =
                                                Broadcast.discordGuildMessageNotification
                                                    SeqSet.empty
                                                    discordMessage.timestamp
                                                    discordMessage.author.id
                                                    discordGuildId
                                                    channelId
                                                    NoThread
                                                    message
                                                    (MembersAndOwner.membersAndOwner guild.membersAndOwner)
                                                    model2
                                        in
                                        ( { model2 | sessions = sessions }
                                        , Command.batch
                                            [ Broadcast.toDiscordGuildChannel
                                                discordGuildId
                                                channelId
                                                (Server_DiscordGuildMemberJoined
                                                    discordMessage.timestamp
                                                    discordGuildId
                                                    discordMessage.channelId
                                                    discordMessage.author.id
                                                    (PersonName.fromStringLossy discordMessage.author.username)
                                                    |> ServerChange
                                                )
                                                model2
                                            , userAvatars
                                            , Command.batch notificationCmds
                                            ]
                                        )

                                    Err DiscordMessageAlreadyExists ->
                                        ( model, Command.none )

                            _ ->
                                let
                                    richText : Nonempty (RichText (Discord.Id Discord.UserId))
                                    richText =
                                        RichText.fromDiscord
                                            content
                                            attachments
                                            discordMessage.embeds
                                            model.discordCustomEmojis
                                            (case discordMessage.stickerItems of
                                                Missing ->
                                                    []

                                                Included stickers ->
                                                    List.filterMap
                                                        (\sticker -> OneToOne.second sticker.id model.discordStickers)
                                                        stickers
                                            )
                                            discordMessage.messageSnapshots

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
                                        DiscordGuildOrDmId_Guild { currentUserId = discordMessage.author.id, guildId = discordGuildId, channelId = channelId }

                                    channelResult : Result DiscordMessageAlreadyExists ( ( ( SeqDict SessionId UserSession, List (Command BackendOnly toMsg BackendMsg) ), DiscordBackendChannel ), Command BackendOnly ToFrontend BackendMsg, SeqDict (Id StickerId) StickerData )
                                    channelResult =
                                        case threadRoute of
                                            ViewThreadWithMaybeMessage threadId maybeReplyTo ->
                                                let
                                                    ( message2, embedCmds, stickers ) =
                                                        Message.userTextMessageBackend
                                                            model.serverSecret
                                                            discordMessage.timestamp
                                                            discordMessage.author.id
                                                            richText
                                                            maybeReplyTo
                                                            (SeqDict.map (\_ attachment -> attachment.fileData) attachments)
                                                            model.stickers
                                                in
                                                case LocalState.createDiscordThreadMessageBackend discordMessage.id threadId (Message.UserTextMessage message2) channel of
                                                    Ok ( messageId, channel3 ) ->
                                                        ( ( Broadcast.discordGuildMessageNotification
                                                                usersMentioned
                                                                discordMessage.timestamp
                                                                discordMessage.author.id
                                                                discordGuildId
                                                                channelId
                                                                threadRouteNoReply
                                                                (Message.UserTextMessage message2)
                                                                (MembersAndOwner.membersAndOwner guild.membersAndOwner)
                                                                model
                                                          , channel3
                                                          )
                                                        , Command.map
                                                            identity
                                                            (DiscordGotGuildMessageEmbed discordGuildId channelId (ViewThreadWithMessage threadId messageId))
                                                            embedCmds
                                                        , stickers
                                                        )
                                                            |> Ok

                                                    Err DiscordMessageAlreadyExists ->
                                                        Err DiscordMessageAlreadyExists

                                            NoThreadWithMaybeMessage maybeReplyTo ->
                                                let
                                                    ( message, embedCmds, stickers ) =
                                                        Message.userTextMessageBackend
                                                            model.serverSecret
                                                            discordMessage.timestamp
                                                            discordMessage.author.id
                                                            richText
                                                            maybeReplyTo
                                                            (SeqDict.map (\_ attachment -> attachment.fileData) attachments)
                                                            model.stickers
                                                in
                                                case LocalState.createDiscordChannelMessageBackend linkedMessageId (Message.UserTextMessage message) channel of
                                                    Ok ( messageId, channel3 ) ->
                                                        ( ( Broadcast.discordGuildMessageNotification
                                                                usersMentioned
                                                                discordMessage.timestamp
                                                                discordMessage.author.id
                                                                discordGuildId
                                                                channelId
                                                                threadRouteNoReply
                                                                (Message.UserTextMessage message)
                                                                (MembersAndOwner.membersAndOwner guild.membersAndOwner)
                                                                model
                                                          , channel3
                                                          )
                                                        , Command.map
                                                            identity
                                                            (DiscordGotGuildMessageEmbed discordGuildId channelId (NoThreadWithMessage messageId))
                                                            embedCmds
                                                        , stickers
                                                        )
                                                            |> Ok

                                                    Err DiscordMessageAlreadyExists ->
                                                        Err DiscordMessageAlreadyExists
                                in
                                case channelResult of
                                    Ok ( ( ( sessions, notificationCmds ), channel4 ), embedCmds, stickers ) ->
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
                                                                { joinedAt = Nothing, roles = SeqSet.empty }
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
                                                                        Broadcast.userGetAllConnections data.linkedTo model2
                                                                            |> List.any
                                                                                (\connection ->
                                                                                    UserSession.isViewing (DiscordGuildOrDmId guildOrDmId) threadRouteNoReply connection.currentlyViewing
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
                                            , sessions = sessions
                                          }
                                        , Command.batch
                                            [ case SeqDict.get ( discordMessage.author.id, threadOrChannelId ) model2.pendingDiscordCreateMessages of
                                                Just ( clientId, changeId, timezone ) ->
                                                    Command.batch
                                                        [ LocalChangeResponse
                                                            changeId
                                                            (Local_Discord_SendMessage
                                                                discordMessage.timestamp
                                                                timezone
                                                                guildOrDmId
                                                                (RichText.toStringWithGetter
                                                                    timezone
                                                                    DiscordUserData.username
                                                                    False
                                                                    model2.discordUsers
                                                                    richText
                                                                    |> String.Nonempty.fromString
                                                                    |> Maybe.withDefault (NonemptyString ' ' "")
                                                                )
                                                                threadRoute
                                                                (SeqDict.map (\_ attachment -> attachment.fileData) attachments)
                                                            )
                                                            |> Lamdera.sendToFrontend clientId
                                                        , Broadcast.toDiscordGuildChannelExcludingOne
                                                            clientId
                                                            discordGuildId
                                                            channelId
                                                            (Server_Discord_SendMessage
                                                                discordMessage.timestamp
                                                                guildOrDmId
                                                                (messageSender discordMessage.author model2)
                                                                richText
                                                                threadRoute
                                                                (SeqDict.map (\_ attachment -> attachment.fileData) attachments)
                                                                stickers
                                                                |> ServerChange
                                                            )
                                                            model2
                                                        ]

                                                Nothing ->
                                                    Broadcast.toDiscordGuildChannel
                                                        discordGuildId
                                                        channelId
                                                        (Server_Discord_SendMessage
                                                            discordMessage.timestamp
                                                            guildOrDmId
                                                            (messageSender discordMessage.author model2)
                                                            richText
                                                            threadRoute
                                                            (SeqDict.map (\_ attachment -> attachment.fileData) attachments)
                                                            stickers
                                                            |> ServerChange
                                                        )
                                                        model2
                                            , getUserAvatars model2.serverSecret model2.discordUsers [ discordMessage.author ]
                                            , Command.batch notificationCmds
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


{-| A new post in a guild forum arrives as a thread create event and nothing else. A post
in a normal channel would have arrived as a message in that channel, so this event is the
only chance we get to add the post to the forum it was posted in.

The post's text follows right after this as a message in the new thread. The text hangs off
the post's title the same way it does when a forum is reloaded, so the title has to be
added now or the text has nowhere to go.

Discord sends this event for threads the user is added to as well as for threads that were
just created, so a post we already have is left alone.

-}
handleForumPostCreated : Discord.UserAuth -> Discord.Channel -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleForumPostCreated authentication thread model =
    case ( thread.guildId, thread.parentId, thread.name ) of
        ( Included guildId, Included (Just forumId), Included name ) ->
            case ( thread.ownerId, LocalState.getDiscordGuildAndChannel guildId forumId model ) of
                ( Included ownerId, Just ( guild, channel ) ) ->
                    if channel.isForum then
                        addForumPost
                            authentication
                            { guildId = guildId, forumId = forumId, threadId = thread.id, name = name, ownerId = ownerId }
                            guild
                            channel
                            model

                    else
                        -- A thread in a normal channel is announced by a message in that
                        -- channel instead, which is what the thread hangs off of there
                        ( model, Command.none )

                _ ->
                    ( model, Command.none )

        _ ->
            ( model, Command.none )


addForumPost :
    Discord.UserAuth
    ->
        { guildId : Discord.Id Discord.GuildId
        , forumId : Discord.Id Discord.ChannelId
        , threadId : Discord.Id Discord.ChannelId
        , name : String
        , ownerId : Discord.Id Discord.UserId
        }
    -> DiscordBackendGuild
    -> DiscordBackendChannel
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
addForumPost authentication post guild channel model =
    let
        createdAt : Time.Posix
        createdAt =
            discordIdCreatedAt post.threadId

        richText : Nonempty (RichText (Discord.Id Discord.UserId))
        richText =
            RichText.fromDiscord post.name SeqDict.empty Missing model.discordCustomEmojis [] Missing

        message : Message ChannelMessageId (Discord.Id Discord.UserId)
        message =
            Message.userTextMessageNoEmbeds createdAt post.ownerId richText SeqDict.empty Nothing SeqDict.empty
    in
    -- A forum post's thread has the same id as the message the post hangs off of, the same
    -- as every other thread
    case
        LocalState.createDiscordChannelMessageBackend
            (Discord.idToUInt64 post.threadId |> Discord.idFromUInt64)
            message
            channel
    of
        Ok ( _, channel2 ) ->
            let
                model2 : BackendModel
                model2 =
                    { model
                        | discordGuilds =
                            SeqDict.insert
                                post.guildId
                                { guild | channels = SeqDict.insert post.forumId channel2 guild.channels }
                                model.discordGuilds
                    }

                ( sessions, notificationCmds ) =
                    Broadcast.discordGuildMessageNotification
                        SeqSet.empty
                        createdAt
                        post.ownerId
                        post.guildId
                        post.forumId
                        NoThread
                        message
                        (MembersAndOwner.membersAndOwner guild.membersAndOwner)
                        model2
            in
            ( { model2 | sessions = sessions }
            , Command.batch
                [ Broadcast.toDiscordGuildChannel
                    post.guildId
                    post.forumId
                    (Server_Discord_SendMessage
                        createdAt
                        (DiscordGuildOrDmId_Guild { currentUserId = post.ownerId, guildId = post.guildId, channelId = post.forumId })
                        (forumPostSender post.ownerId model2)
                        richText
                        (NoThreadWithMaybeMessage Nothing)
                        SeqDict.empty
                        SeqDict.empty
                        |> ServerChange
                    )
                    model2

                -- The post's text and the replies to it are written in the thread, and we
                -- only get told about messages in a thread we're a member of
                , joinThread
                    model2.serverSecret
                    authentication
                    post.guildId
                    (Discord.idToUInt64 post.threadId |> Discord.idFromUInt64)
                , Command.batch notificationCmds
                ]
            )

        Err DiscordMessageAlreadyExists ->
            -- We were added to a post we already have rather than told about a new one
            ( model, Command.none )


{-| A renamed forum post arrives as a thread update event. The post's title is a message
here, so renaming the post edits that message.

Discord sends this event for everything else that can change about a thread too, such as
being archived or having its tags changed, and for threads in normal channels, where the
name isn't a message of ours. Editing a message to the content it already has does nothing,
so all of those leave the forum alone without having to be told apart.

-}
handleForumPostRenamed :
    Discord.Channel
    -> Time.Posix
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleForumPostRenamed thread time model =
    case ( thread.guildId, thread.parentId, thread.name ) of
        ( Included guildId, Included (Just forumId), Included name ) ->
            case ( thread.ownerId, LocalState.getDiscordGuildAndChannel guildId forumId model ) of
                ( Included ownerId, Just ( _, channel ) ) ->
                    case
                        -- A thread in a normal channel has the same id as the message it hangs
                        -- off of, so without this the message would be mistaken for a title and
                        -- rewritten to the thread's name
                        if channel.isForum then
                            OneToOne.second
                                (Discord.idToUInt64 thread.id |> Discord.idFromUInt64)
                                channel.linkedMessageIds

                        else
                            Nothing
                    of
                        Just messageId ->
                            let
                                richText : Nonempty (RichText (Discord.Id Discord.UserId))
                                richText =
                                    RichText.fromDiscord name SeqDict.empty Missing model.discordCustomEmojis [] Missing
                            in
                            case
                                LocalState.editMessageHelper
                                    time
                                    ownerId
                                    richText
                                    DoNotChangeAttachments
                                    (NoThreadWithMessage messageId)
                                    channel
                            of
                                Ok channel2 ->
                                    let
                                        model2 : BackendModel
                                        model2 =
                                            { model
                                                | discordGuilds =
                                                    SeqDict.updateIfExists
                                                        guildId
                                                        (LocalState.updateChannel (\_ -> channel2) forumId)
                                                        model.discordGuilds
                                            }
                                    in
                                    ( model2
                                    , Broadcast.toDiscordGuildChannel
                                        guildId
                                        forumId
                                        (Server_DiscordSendEditGuildMessage
                                            time
                                            ownerId
                                            guildId
                                            forumId
                                            (NoThreadWithMessage messageId)
                                            richText
                                            |> ServerChange
                                        )
                                        model2
                                    )

                                Err () ->
                                    -- The title is already what the post is called
                                    ( model, Command.none )

                        Nothing ->
                            ( model, Command.none )

                _ ->
                    ( model, Command.none )

        _ ->
            ( model, Command.none )


{-| A deleted forum post arrives as a thread delete event. Deleting a post deletes
everything written in it too, so the post's title and the thread hanging off it both go,
unlike deleting the message a thread in a normal channel hangs off of.

Discord sends this for threads in normal channels as well, where the thread outlives the
message it hangs off of and there's nothing for us to do.

-}
handleForumPostDeleted : Discord.Channel -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleForumPostDeleted thread model =
    case ( thread.guildId, thread.parentId ) of
        ( Included guildId, Included (Just forumId) ) ->
            case LocalState.getDiscordGuildAndChannel guildId forumId model of
                Just ( guild, channel ) ->
                    case
                        -- A thread in a normal channel has the same id as the message it hangs
                        -- off of, and that message outlives the thread, so without this it
                        -- would be deleted along with it
                        if channel.isForum then
                            OneToOne.second
                                (Discord.idToUInt64 thread.id |> Discord.idFromUInt64)
                                channel.linkedMessageIds

                        else
                            Nothing
                    of
                        Just messageId ->
                            let
                                channel2 : DiscordBackendChannel
                                channel2 =
                                    case IdArray.get messageId channel.messages of
                                        Just (UserTextMessage message) ->
                                            { channel
                                                | messages =
                                                    IdArray.set
                                                        messageId
                                                        (DeletedMessage message.createdAt)
                                                        channel.messages
                                                , threads = SeqDict.remove messageId channel.threads
                                            }

                                        _ ->
                                            { channel | threads = SeqDict.remove messageId channel.threads }

                                model2 : BackendModel
                                model2 =
                                    { model
                                        | discordGuilds =
                                            SeqDict.insert
                                                guildId
                                                { guild | channels = SeqDict.insert forumId channel2 guild.channels }
                                                model.discordGuilds
                                    }
                            in
                            ( model2
                            , Broadcast.toDiscordGuildChannel
                                guildId
                                forumId
                                (Server_DiscordForumPostDeleted guildId forumId messageId |> ServerChange)
                                model2
                            )

                        Nothing ->
                            -- A post older than the ones we loaded, so there's no title of ours
                            -- for it to have come from
                            ( model, Command.none )

                Nothing ->
                    ( model, Command.none )

        _ ->
            ( model, Command.none )


forumPostSender : Discord.Id Discord.UserId -> BackendModel -> DiscordFrontendUser
forumPostSender userId model =
    case SeqDict.get userId model.discordUsers of
        Just discordUser ->
            User.discordUserDataToFrontendUser discordUser

        Nothing ->
            { name = PersonName.fromStringLossy "Missing", icon = Nothing }


{-| When a snowflake id was created. The top bits of the id hold the number of milliseconds
that had passed since the start of 2015 when Discord handed the id out.
-}
discordIdCreatedAt : Discord.Id idType -> Time.Posix
discordIdCreatedAt id =
    Discord.idToUInt64 id
        |> UInt64.shiftRightZfBy 22
        |> UInt64.toFloat
        |> round
        |> (+) 1420070400000
        |> Time.millisToPosix


websocketCreateHandle : String -> (Websocket.Connection -> msg) -> String -> Command restriction toMsg msg
websocketCreateHandle debugName msg url =
    let
        _ =
            Debug.log "websocket created" debugName
    in
    Websocket.createHandle msg url


websocketClose : (Time.Posix -> WebsocketClosedEvent) -> Websocket.Connection -> Task BackendOnly x WebsocketClosedEvent
websocketClose debugName connection =
    Websocket.close connection |> Task.andThen (\() -> Time.now |> Task.map debugName)


{-| Discord decides whether a session can be resumed based on the websocket close code, so we need
the number rather than the name. Note that Effect.Websocket skips 1004 (it's reserved), so the
constructors after UnsupportedData are all one higher than their name suggests.
-}
closeEventCodeToInt : Websocket.CloseEventCode -> Int
closeEventCodeToInt code =
    case code of
        Websocket.NormalClosure ->
            1000

        Websocket.GoingAway ->
            1001

        Websocket.ProtocolError ->
            1002

        Websocket.UnsupportedData ->
            1003

        Websocket.NoStatusReceived ->
            1005

        Websocket.AbnormalClosure ->
            1006

        Websocket.InvalidFramePayloadData ->
            1007

        Websocket.PolicyViolation ->
            1008

        Websocket.MessageTooBig ->
            1009

        Websocket.MissingExtension ->
            1010

        Websocket.InternalError ->
            1011

        Websocket.ServiceRestart ->
            1012

        Websocket.TryAgainLater ->
            1013

        Websocket.BadGateway ->
            1014

        Websocket.TlsHandshake ->
            1015

        Websocket.UnknownCode int ->
            int


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
                        Discord.UserOutMsg_CloseAndReopenHandle connection reconnectTo ->
                            ( model2
                            , Task.perform
                                (WebsocketClosedByBackendForUser discordUserId (Just reconnectTo))
                                (websocketClose (WebsocketClosed_CloseAndReopenForUser discordUserId) connection)
                                :: cmds
                            )

                        Discord.UserOutMsg_OpenHandle maybeResumeGatewayUrl ->
                            ( model2
                            , websocketCreateHandle
                                "OpenHandle"
                                (WebsocketCreatedHandleForUser discordUserId)
                                (Maybe.withDefault Discord.websocketGatewayUrl maybeResumeGatewayUrl)
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
                                attachments : SeqDict (Id FileId) { fileData : FileData, isSpoilered : Bool }
                                attachments =
                                    messageToFileData message model2.discordAttachments

                                joinThreadCmd : Command BackendOnly ToFrontend BackendMsg
                                joinThreadCmd =
                                    case ( message.guildId, message.flags ) of
                                        ( Included guildId, Included flags ) ->
                                            if flags.hasThread then
                                                joinThread model2.serverSecret userData.auth guildId message.id

                                            else
                                                Command.none

                                        _ ->
                                            Command.none

                                ( model3, stickerCmds ) =
                                    case message.stickerItems of
                                        Included stickers ->
                                            let
                                                stickerData =
                                                    handleStickers
                                                        model2.serverSecret
                                                        (List.map
                                                            (\sticker ->
                                                                { id = sticker.id
                                                                , -- Assume that these are all custom stickers since we very likely have loaded all of the built-in stickers
                                                                  stickerType = Discord.GuildSticker
                                                                , formatType = sticker.formatType
                                                                , name = sticker.name
                                                                }
                                                            )
                                                            stickers
                                                        )
                                                        { tasks = []
                                                        , stickers = model2.stickers
                                                        , discordStickers = model2.discordStickers
                                                        }
                                            in
                                            ( { model2
                                                | stickers = stickerData.stickers
                                                , discordStickers = stickerData.discordStickers
                                              }
                                            , Task.sequence stickerData.tasks
                                                |> Task.andThen
                                                    (\stickers2 ->
                                                        Task.map
                                                            (GotDiscordMessageStickers
                                                                (case message.guildId of
                                                                    Included guildId ->
                                                                        MessageFromGuildOrDm_Guild guildId

                                                                    Missing ->
                                                                        Discord.idToUInt64 message.channelId
                                                                            |> Discord.idFromUInt64
                                                                            |> MessageFromGuildOrDm_Dm
                                                                )
                                                                stickers2
                                                            )
                                                            Time.now
                                                    )
                                                |> Task.perform identity
                                            )

                                        Missing ->
                                            ( model2, Command.none )

                                ( model4, customEmojiCmds ) =
                                    let
                                        customEmojisInMessage : List DiscordCustomEmojiIdAndName
                                        customEmojisInMessage =
                                            RichText.customEmojisFromDiscord message.content

                                        customEmojiData =
                                            handleCustomEmojis
                                                model3.serverSecret
                                                (customEmojisInMessage
                                                    ++ (case message.reactions of
                                                            Included reactions ->
                                                                emojiDataToEmojiIdAndName (List.map .emoji reactions)

                                                            Missing ->
                                                                []
                                                       )
                                                )
                                                { tasks = []
                                                , customEmojis = model3.customEmojis
                                                , discordCustomEmojis = model3.discordCustomEmojis
                                                }
                                    in
                                    ( { model3
                                        | customEmojis = customEmojiData.customEmojis
                                        , discordCustomEmojis = customEmojiData.discordCustomEmojis
                                      }
                                    , Task.sequence customEmojiData.tasks
                                        |> Task.andThen
                                            (\customEmojis2 ->
                                                Task.map
                                                    (GotDiscordMessageCustomEmojis
                                                        (case message.guildId of
                                                            Included guildId ->
                                                                MessageFromGuildOrDm_Guild guildId

                                                            Missing ->
                                                                Discord.idToUInt64 message.channelId
                                                                    |> Discord.idFromUInt64
                                                                    |> MessageFromGuildOrDm_Dm
                                                        )
                                                        customEmojis2
                                                    )
                                                    Time.now
                                            )
                                        |> Task.perform identity
                                    )
                            in
                            case
                                ( SeqDict.size attachments == List.length message.attachments
                                , List.Nonempty.fromList message.attachments
                                )
                            of
                                ( False, Just nonempty ) ->
                                    ( model4
                                    , joinThreadCmd
                                        :: stickerCmds
                                        :: customEmojiCmds
                                        :: Task.perform
                                            (DiscordMessageCreate_AttachmentsUploaded message)
                                            (nonemptyTaskSequence (List.Nonempty.map (loadMessageAttachment model4.serverSecret) nonempty))
                                        :: cmds
                                    )

                                _ ->
                                    let
                                        ( model5, cmd2 ) =
                                            handleCreateMessage
                                                (case discordMsg of
                                                    Discord.GotWebsocketData data ->
                                                        data

                                                    Discord.WebsocketClosed data ->
                                                        data.reason
                                                )
                                                message
                                                attachments
                                                model4
                                    in
                                    ( model5
                                    , joinThreadCmd
                                        :: stickerCmds
                                        :: customEmojiCmds
                                        :: cmd2
                                        :: cmds
                                    )

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
                                attachments : SeqDict (Id FileId) { fileData : FileData, isSpoilered : Bool }
                                attachments =
                                    messageToFileData edit model2.discordAttachments

                                joinThreadCmd : Command BackendOnly ToFrontend BackendMsg
                                joinThreadCmd =
                                    case ( edit.guildId, edit.flags.hasThread ) of
                                        ( Included guildId, True ) ->
                                            joinThread model2.serverSecret userData.auth guildId edit.id

                                        _ ->
                                            Command.none
                            in
                            case ( SeqDict.size attachments == List.length edit.attachments, List.Nonempty.fromList edit.attachments ) of
                                ( False, Just nonempty ) ->
                                    ( model2
                                    , Task.perform
                                        (DiscordMessageUpdate_AttachmentsUploaded edit)
                                        (nonemptyTaskSequence (List.Nonempty.map (loadMessageAttachment model2.serverSecret) nonempty))
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

                        Discord.UserOutMsg_ThreadCreatedOrUserAddedToThread thread ->
                            let
                                ( model3, cmd2 ) =
                                    handleForumPostCreated userData.auth thread model2
                            in
                            ( model3, cmd2 :: cmds )

                        Discord.UserOutMsg_ThreadUpdated thread ->
                            -- The event says nothing about when the thread was changed, and
                            -- renaming a post edits the message its title is
                            ( model2
                            , Task.perform (GotTimeForDiscordForumPostRenamed thread) Time.now :: cmds
                            )

                        Discord.UserOutMsg_ThreadDeleted thread ->
                            let
                                ( model3, cmd2 ) =
                                    handleForumPostDeleted thread model2
                            in
                            ( model3, cmd2 :: cmds )

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
                                    handleReadyData userData.linkedTo readyData model2
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
                                                                            { joinedAt = Nothing, roles = SeqSet.empty }
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
                                                                                        { joinedAt = Just member.joinedAt
                                                                                        , roles = SeqSet.empty
                                                                                        }
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
                                                    , getUserAvatars model2.serverSecret model2.discordUsers users2
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
                                            , getUserAvatars model2.serverSecret model2.discordUsers users2
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

                        Discord.UserOutMsg_GuildRoleUpdate roleUpdate ->
                            let
                                ( model3, cmd2 ) =
                                    handleGuildRoleUpdate roleUpdate model2
                            in
                            ( model3, cmd2 :: cmds )

                        Discord.UserOutMsg_GuildEmojisUpdate emojisUpdate ->
                            let
                                ( model3, cmd2 ) =
                                    handleGuildEmojisUpdate userData.linkedTo emojisUpdate model2
                            in
                            ( model3, cmd2 :: cmds )

                        Discord.UserOutMsg_ChannelPinsUpdate _ ->
                            ( model2, cmds )

                        Discord.UserOutMsg_UserUpdate user ->
                            ( { model2
                                | discordUsers =
                                    addDiscordUserData
                                        (Discord.userToPartialUser user)
                                        model2.discordUsers
                              }
                            , getUserAvatars model2.serverSecret model2.discordUsers [ user ] :: cmds
                            )

                        Discord.UserOutMsg_GuildScheduledEventUserAdd _ ->
                            ( model2, cmds )

                        Discord.UserOutMsg_GuildScheduledEventUserRemove _ ->
                            ( model2, cmds )
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
    ( { model | discordGuilds = addDiscordGuild model.discordStickers model.discordCustomEmojis [] gatewayGuild model.discordGuilds }
    , getDiscordGuildData model.serverSecret gatewayGuild
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
            ( model, Command.none )

        Included guildId ->
            let
                model2 : BackendModel
                model2 =
                    { model
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
                                                        , permissionOverwrites =
                                                            case channel.permissionOverwrites of
                                                                Missing ->
                                                                    existingChannel.permissionOverwrites

                                                                Included permissions ->
                                                                    permissions
                                                    }
                                                )
                                                guild.channels
                                    }
                                )
                                model.discordGuilds
                    }

                newOverwrites : List Discord.Overwrite
                newOverwrites =
                    case
                        SeqDict.get guildId model2.discordGuilds
                            |> Maybe.andThen (\guild -> SeqDict.get channel.id guild.channels)
                    of
                        Just updatedChannel ->
                            updatedChannel.permissionOverwrites

                        Nothing ->
                            []
            in
            ( model2
              -- Broadcast against the updated model so recipients are resolved with the
              -- new overwrites: users who just lost access are excluded.
            , Broadcast.toDiscordGuildChannel
                guildId
                channel.id
                (Server_DiscordUpdateChannel guildId channel.id channel.name channel.topic newOverwrites |> ServerChange)
                model2
            )


{-| A GUILD\_ROLE\_UPDATE event carries a role's current permissions. Those
permissions feed LocalState.canViewDiscordChannel (both the `administrator`
short-circuit and the base `viewChannel` value), so we must keep the stored role
in sync. Ignoring the event would let a user keep seeing channels after the role
granting that access has had the permission revoked on Discord.
-}
handleGuildRoleUpdate : Discord.GuildRoleUpdate -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleGuildRoleUpdate roleUpdate model =
    case SeqDict.get roleUpdate.guildId model.discordGuilds of
        Just guild ->
            let
                role : Discord.Role
                role =
                    roleUpdate.role

                discordRole : DiscordRole
                discordRole =
                    { name = role.name
                    , description = role.description
                    , permissions = role.permissions
                    }
            in
            ( { model
                | discordGuilds =
                    SeqDict.insert
                        roleUpdate.guildId
                        { guild | roles = SeqDict.insert role.id discordRole guild.roles }
                        model.discordGuilds
              }
            , Broadcast.toDiscordGuild
                roleUpdate.guildId
                (Server_DiscordUpdateRole roleUpdate.guildId role.id discordRole |> ServerChange)
                model
            )

        Nothing ->
            ( model, Command.none )


{-| A GUILD\_EMOJIS\_UPDATE event carries the guild's complete emoji list as it
looks after the change, not just the emojis that were added or removed. Emojis we
haven't seen before get downloaded and stored, and the guild's emoji set is
replaced so that deleted emojis stop appearing in the emoji picker.

Renaming an emoji on Discord also shows up here. Custom emojis are keyed by id
_and_ name, so a rename is stored as a new custom emoji and the old name drops
out of the guild's set.

-}
handleGuildEmojisUpdate :
    Id UserId
    -> Discord.GuildEmojisUpdate
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleGuildEmojisUpdate userId emojisUpdate model =
    case SeqDict.get emojisUpdate.guildId model.discordGuilds of
        Just guild ->
            let
                emojis : List DiscordCustomEmojiIdAndName
                emojis =
                    emojiDataToEmojiIdAndName emojisUpdate.emojis

                customEmojiData :
                    { tasks : List (Task BackendOnly Never ( Id CustomEmojiId, Result Http.Error FileStatus.UploadResponse ))
                    , customEmojis : SeqDict (Id CustomEmojiId) CustomEmojiData
                    , discordCustomEmojis : OneToOne DiscordCustomEmojiIdAndName (Id CustomEmojiId)
                    }
                customEmojiData =
                    handleCustomEmojis
                        model.serverSecret
                        emojis
                        { tasks = []
                        , customEmojis = model.customEmojis
                        , discordCustomEmojis = model.discordCustomEmojis
                        }

                guildCustomEmojis : SeqSet (Id CustomEmojiId)
                guildCustomEmojis =
                    List.filterMap
                        (\emoji -> OneToOne.second emoji customEmojiData.discordCustomEmojis)
                        emojis
                        |> SeqSet.fromList

                model2 : BackendModel
                model2 =
                    { model
                        | discordGuilds =
                            SeqDict.insert
                                emojisUpdate.guildId
                                { guild | customEmojis = guildCustomEmojis }
                                model.discordGuilds
                        , customEmojis = customEmojiData.customEmojis
                        , discordCustomEmojis = customEmojiData.discordCustomEmojis
                    }
            in
            ( model2
            , Command.batch
                [ Broadcast.toDiscordGuild
                    emojisUpdate.guildId
                    (Server_DiscordUpdateGuildCustomEmojis emojisUpdate.guildId guildCustomEmojis |> ServerChange)
                    model2
                , Task.sequence customEmojiData.tasks
                    |> Task.andThen (\customEmojis -> Task.map (GotDiscordReadyDataCustomEmojis userId customEmojis) Time.now)
                    |> Task.perform identity
                ]
            )

        Nothing ->
            ( model, Command.none )


handleGuildMemberUpdate :
    Discord.Id Discord.GuildId
    -> { b | user : Discord.User, joinedAt : Time.Posix, roles : List (Discord.Id Discord.RoleId) }
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
                                    { joinedAt = Just guildMember.joinedAt
                                    , roles = SeqSet.fromList guildMember.roles
                                    }
                                    guild.membersAndOwner
                        }
                        model2.discordGuilds
              }
            , getUserAvatars model2.serverSecret model2.discordUsers [ guildMember.user ]
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
                                , Broadcast.toDiscordGuildChannel
                                    guildId
                                    channelId
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
    -> SeqDict (Id FileId) { fileData : FileData, isSpoilered : Bool }
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
    SecretId ServerSecret
    -> Discord.Attachment
    -> Task restriction x (Result Http.Error ( Discord.Id Discord.AttachmentId, FileStatus.UploadResponse ))
loadMessageAttachment secretKey attachment =
    FileStatus.uploadUrl secretKey attachment.url
        |> Task.map (\uploadResponse -> Ok ( attachment.id, uploadResponse ))
        |> Task.onError (\error -> Task.succeed (Err error))


messageToFileData :
    { a | attachments : List Discord.Attachment }
    -> SeqDict DiscordAttachmentId DiscordAttachmentData
    -> SeqDict (Id FileId) { fileData : FileData, isSpoilered : Bool }
messageToFileData message discordAttachments =
    List.filterMap
        (\attachment ->
            case SeqDict.get (DiscordAttachmentId.fromUrl attachment.url) discordAttachments of
                Just { fileHash, metadata } ->
                    { fileData = attachmentsToFileData attachment fileHash metadata
                    , isSpoilered =
                        case attachment.flags of
                            Included flag ->
                                flag.isSpoiler

                            Missing ->
                                False
                    }
                        |> Just

                Nothing ->
                    Nothing
        )
        message.attachments
        |> List.indexedMap (\index fileData -> ( Id.fromInt (index + 1), fileData ))
        |> SeqDict.fromList


attachmentsToFileData : Discord.Attachment -> FileHash -> Maybe FileMetadata -> FileData
attachmentsToFileData attachment fileHash metadata =
    { fileName = FileName.fromString attachment.filename
    , fileSize = attachment.size
    , metadata = metadata
    , contentType =
        case attachment.contentType of
            Included contentType ->
                FileStatus.contentType contentType

            Missing ->
                case metadata of
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
                                                    { messages = IdArray.empty
                                                    , lastTypedAt = SeqDict.empty
                                                    , linkedMessageIds = OneToOne.empty
                                                    , members = members
                                                    , dateDividerDrawings = SeqDict.empty
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
                        , getUserAvatars model2.serverSecret existingUsers (head :: rest)
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

                overwrites : List Discord.Overwrite
                overwrites =
                    case channel.permissionOverwrites of
                        Missing ->
                            []

                        Included permissions ->
                            permissions

                isForum : Bool
                isForum =
                    channel.type_ == Discord.GuildForum

                model2 : BackendModel
                model2 =
                    { model
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
                                                                    , isForum = isForum
                                                                    , permissionOverwrites = overwrites
                                                                }

                                                        Nothing ->
                                                            addDiscordChannel channel
                                                )
                                                guild.channels
                                    }
                                )
                                model.discordGuilds
                    }
            in
            ( model2
              -- Broadcast against the updated model so the newly created channel is found
              -- and delivered to exactly the members who are allowed to view it.
            , Broadcast.toDiscordGuildChannel
                guildId
                channel.id
                (Server_DiscordChannelCreated guildId channel.id isForum name channel.topic overwrites |> ServerChange)
                model2
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
                            mergedMembers2 : MembersAndOwner (Discord.Id Discord.UserId) { joinedAt : Maybe Time.Posix, roles : SeqSet (Discord.Id Discord.RoleId) }
                            mergedMembers2 =
                                List.foldl
                                    (\mergedMember state ->
                                        MembersAndOwner.addOrUpdateMember
                                            mergedMember.userId
                                            { joinedAt = Just mergedMember.joinedAt
                                            , roles = SeqSet.fromList mergedMember.roles
                                            }
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


handleStickers :
    SecretId ServerSecret
    ->
        List
            { a
                | id : Discord.Id Discord.StickerId
                , stickerType : Discord.StickerType
                , formatType : Discord.StickerFormatType
                , name : String
            }
    ->
        { tasks : List (Task BackendOnly x ( Id StickerId, Result Http.Error FileStatus.UploadResponse ))
        , stickers : SeqDict (Id StickerId) StickerData
        , discordStickers : OneToOne (Discord.Id Discord.StickerId) (Id StickerId)
        }
    ->
        { tasks : List (Task BackendOnly x ( Id StickerId, Result Http.Error FileStatus.UploadResponse ))
        , stickers : SeqDict (Id StickerId) StickerData
        , discordStickers : OneToOne (Discord.Id Discord.StickerId) (Id StickerId)
        }
handleStickers secretKey stickersToCheck state =
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
                                    secretKey
                                    (Discord.stickerUrl sticker.stickerType sticker.formatType sticker.id)
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
        stickersToCheck


handleCustomEmojis :
    SecretId ServerSecret
    -> List DiscordCustomEmojiIdAndName
    ->
        { tasks : List (Task BackendOnly x ( Id CustomEmojiId, Result Http.Error FileStatus.UploadResponse ))
        , customEmojis : SeqDict (Id CustomEmojiId) CustomEmojiData
        , discordCustomEmojis : OneToOne DiscordCustomEmojiIdAndName (Id CustomEmojiId)
        }
    ->
        { tasks : List (Task BackendOnly x ( Id CustomEmojiId, Result Http.Error FileStatus.UploadResponse ))
        , customEmojis : SeqDict (Id CustomEmojiId) CustomEmojiData
        , discordCustomEmojis : OneToOne DiscordCustomEmojiIdAndName (Id CustomEmojiId)
        }
handleCustomEmojis secretKey emojisToCheck state =
    List.foldl
        (\emoji acc ->
            case OneToOne.second emoji acc.discordCustomEmojis of
                Just _ ->
                    acc

                Nothing ->
                    let
                        customEmojiId : Id CustomEmojiId
                        customEmojiId =
                            Id.nextId acc.customEmojis
                    in
                    { tasks =
                        (FileStatus.uploadUrl
                            secretKey
                            (Discord.customEmojiUrl
                                (Discord.TwoToNthPower 7)
                                Nothing
                                (Discord.idToUInt64 emoji.id |> Discord.idFromUInt64)
                            )
                            |> taskResult
                            |> Task.map (\result -> ( customEmojiId, result ))
                        )
                            :: acc.tasks
                    , customEmojis =
                        SeqDict.insert
                            customEmojiId
                            { url = CustomEmojiLoading
                            , name = emoji.name
                            , isAnimated = emoji.isAnimated
                            }
                            acc.customEmojis
                    , discordCustomEmojis = OneToOne.insert emoji customEmojiId acc.discordCustomEmojis
                    }
        )
        state
        emojisToCheck


emojiDataToEmojiIdAndName : List Discord.EmojiData -> List DiscordCustomEmojiIdAndName
emojiDataToEmojiIdAndName emojis =
    List.filterMap
        (\emoji ->
            case emoji.type_ of
                Discord.UnicodeEmojiType _ ->
                    Nothing

                Discord.CustomEmojiType idAndName ->
                    maybeEmojiNameAndIdToNameAndId emoji.animated idAndName
        )
        emojis


handleReadyData : Id UserId -> Discord.ReadyData -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleReadyData userId readyData model =
    let
        discordDmChannels : List { dmChannelId : Discord.Id Discord.PrivateChannelId, members : List (Discord.Id Discord.UserId) }
        discordDmChannels =
            case readyData.privateChannels of
                Included privateChannels ->
                    List.filterMap
                        (\dmChannel ->
                            if SeqDict.member dmChannel.id model.discordDmChannels then
                                Nothing

                            else
                                Just { dmChannelId = dmChannel.id, members = dmChannel.recipientIds }
                        )
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
                (\guild state -> handleStickers model.serverSecret guild.stickers state)
                { tasks = [], stickers = model.stickers, discordStickers = model.discordStickers }
                readyData.guilds

        customEmojiData :
            { tasks : List (Task BackendOnly x ( Id CustomEmojiId, Result Http.Error FileStatus.UploadResponse ))
            , customEmojis : SeqDict (Id CustomEmojiId) CustomEmojiData
            , discordCustomEmojis : OneToOne DiscordCustomEmojiIdAndName (Id CustomEmojiId)
            }
        customEmojiData =
            List.foldl
                (\guild state -> handleCustomEmojis model.serverSecret (emojiDataToEmojiIdAndName guild.emojis) state)
                { tasks = [], customEmojis = model.customEmojis, discordCustomEmojis = model.discordCustomEmojis }
                readyData.guilds
    in
    ( { model
        | discordGuilds =
            List.foldl
                (\guild ( mergedMembers, guilds ) ->
                    case mergedMembers of
                        head :: rest ->
                            ( rest, addDiscordGuild stickerData.discordStickers customEmojiData.discordCustomEmojis head guild guilds )

                        [] ->
                            ( [], addDiscordGuild stickerData.discordStickers customEmojiData.discordCustomEmojis [] guild guilds )
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
        , discordCustomEmojis = customEmojiData.discordCustomEmojis
        , customEmojis = customEmojiData.customEmojis
      }
    , Command.batch
        [ getUserAvatars model.serverSecret model.discordUsers discordUsers
        , Task.sequence stickerData.tasks
            |> Task.andThen (\stickers -> Task.map (GotDiscordReadyDataStickers userId stickers) Time.now)
            |> Task.perform identity
        , Task.sequence customEmojiData.tasks
            |> Task.andThen (\customEmojis -> Task.map (GotDiscordReadyDataCustomEmojis userId customEmojis) Time.now)
            |> Task.perform identity
        , (List.filterMap
            (\guild ->
                if SeqDict.member guild.properties.id model.discordGuilds then
                    Nothing

                else
                    getDiscordGuildData model.serverSecret guild |> Just
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


emojiFromDiscord : OneToOne DiscordCustomEmojiIdAndName (Id CustomEmojiId) -> Discord.EmojiData -> EmojiOrCustomEmoji
emojiFromDiscord customEmojis emoji =
    case emoji.type_ of
        Discord.UnicodeEmojiType string ->
            EmojiOrCustomEmoji_Emoji (Emoji.fromString string)

        Discord.CustomEmojiType idAndName ->
            case maybeEmojiNameAndIdToNameAndId emoji.animated idAndName of
                Just idAndName2 ->
                    case OneToOne.second idAndName2 customEmojis of
                        Just customEmojiId ->
                            EmojiOrCustomEmoji_CustomEmoji customEmojiId

                        Nothing ->
                            EmojiOrCustomEmoji_Emoji (Emoji.fromString "❓")

                Nothing ->
                    EmojiOrCustomEmoji_Emoji (Emoji.fromString "❓")


maybeEmojiNameAndIdToNameAndId : OptionalData Bool -> { a | name : Maybe String, id : Discord.Id Discord.CustomEmojiId } -> Maybe DiscordCustomEmojiIdAndName
maybeEmojiNameAndIdToNameAndId isAnimated nameAndId =
    case nameAndId.name of
        Just name ->
            case CustomEmoji.emojiNameFromString name of
                Ok name3 ->
                    Just
                        { isAnimated =
                            case isAnimated of
                                Included bool ->
                                    bool

                                Missing ->
                                    False
                        , id = nameAndId.id
                        , name = name3
                        }

                Err () ->
                    Nothing

        Nothing ->
            Nothing


addDiscordGuild :
    OneToOne (Discord.Id Discord.StickerId) (Id StickerId)
    -> OneToOne DiscordCustomEmojiIdAndName (Id CustomEmojiId)
    -> List Discord.MergedMember
    -> Discord.GatewayGuild
    -> SeqDict (Discord.Id Discord.GuildId) DiscordBackendGuild
    -> SeqDict (Discord.Id Discord.GuildId) DiscordBackendGuild
addDiscordGuild existingStickers existingCustomEmojis members guild discordGuilds =
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
                                        { joinedAt = Just member.joinedAt, roles = SeqSet.fromList member.roles }
                                        dict
                                )
                                existingGuild.membersAndOwner
                                members
                        , stickers =
                            List.filterMap
                                (\sticker -> OneToOne.second sticker.id existingStickers)
                                guild.stickers
                                |> SeqSet.fromList
                        , customEmojis =
                            List.filterMap
                                (\emoji ->
                                    case emoji.type_ of
                                        Discord.CustomEmojiType nameAndId ->
                                            case maybeEmojiNameAndIdToNameAndId emoji.animated nameAndId of
                                                Just nameAndId2 ->
                                                    OneToOne.second nameAndId2 existingCustomEmojis

                                                Nothing ->
                                                    Nothing

                                        Discord.UnicodeEmojiType _ ->
                                            Nothing
                                )
                                guild.emojis
                                |> SeqSet.fromList
                        , roles = Pages.Admin.rolesToDict guild.roles
                    }
                        |> Just

                Nothing ->
                    { name = GuildName.fromStringLossy guild.properties.name
                    , icon = Nothing
                    , channels = SeqDict.empty -- Gets filled after LinkDiscordUserStep2 is triggered
                    , membersAndOwner =
                        MembersAndOwner.init
                            (List.map
                                (\member ->
                                    ( member.userId
                                    , { joinedAt = Just member.joinedAt, roles = SeqSet.fromList member.roles }
                                    )
                                )
                                members
                                |> SeqDict.fromList
                            )
                            guild.properties.ownerId
                    , stickers =
                        List.filterMap
                            (\sticker -> OneToOne.second sticker.id existingStickers)
                            guild.stickers
                            |> SeqSet.fromList
                    , customEmojis =
                        List.filterMap
                            (\emoji ->
                                case emoji.type_ of
                                    Discord.CustomEmojiType nameAndId ->
                                        case maybeEmojiNameAndIdToNameAndId emoji.animated nameAndId of
                                            Just nameAndId2 ->
                                                OneToOne.second nameAndId2 existingCustomEmojis

                                            Nothing ->
                                                Nothing

                                    Discord.UnicodeEmojiType _ ->
                                        Nothing
                            )
                            guild.emojis
                            |> SeqSet.fromList
                    , roles = Pages.Admin.rolesToDict guild.roles
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
                FileStatus.uploadUrl model.serverSecret attachment.url
                    |> Task.map (\uploadResponse -> Ok ( DiscordAttachmentId.fromUrl attachment.url, uploadResponse ))
                    |> Task.onError (\error -> Task.succeed (Err error))
            )
        |> Task.sequence


getDiscordGuildData :
    SecretId ServerSecret
    -> Discord.GatewayGuild
    ->
        Task
            BackendOnly
            Discord.HttpError
            ( Discord.Id Discord.GuildId
            , { guild : Discord.GatewayGuild, channels : List Discord.Channel, icon : Maybe FileStatus.UploadResponse }
            )
getDiscordGuildData secretKey gatewayGuild =
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
                    secretKey
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


{-| Loads the messages of the threads hanging off the given channel messages, so that
reloading a channel brings its threads back as well.

Discord sets the has-thread flag on the message a thread was started from, and on the
thread created message that stands in for a thread that was started without one, so the
messages themselves say which threads exist. That works for archived threads too, unlike
listing a guild's active threads, which is a bot-only endpoint.

Loading a thread's messages can fail on its own without the whole reload being worth
failing over, so a thread we can't load is left out instead.

-}
getThreadsForMessages :
    SecretId ServerSecret
    -> Discord.Authentication
    -> List Discord.Message
    -> Task BackendOnly x (List DiscordThreadReload)
getThreadsForMessages secretKey authentication messages =
    List.filterMap
        (\message ->
            case message.flags of
                Included flags ->
                    if flags.hasThread then
                        -- A thread has the same id as the message it hangs off of
                        messageLinkId message |> Discord.idToUInt64 |> Discord.idFromUInt64 |> Just

                    else
                        Nothing

                Missing ->
                    Nothing
        )
        messages
        |> List.Extra.uniqueBy Discord.idToString
        |> List.map
            (\threadId ->
                getManyMessages
                    secretKey
                    authentication
                    { channelId = threadId, limit = reloadThreadMaxMessages }
                    |> Task.onError (\_ -> Task.succeed [])
                    |> Task.map (\threadMessages -> { threadId = threadId, messages = threadMessages })
            )
        |> Task.sequence


{-| Loads everything in a guild forum channel.

A forum holds no messages of its own, so asking it for messages always comes back empty.
Every post in a forum is a thread instead, and the post's text is the first message inside
that thread rather than a message in the forum, so the only way to find out which posts
exist is to ask the forum for its threads.

Discord announces a thread that was started without a message by posting a `ThreadCreated`
message named after the thread into the channel, and that message is what the thread hangs
off of here. Forum posts get the same treatment: each post becomes a `ThreadCreated`
message carrying the post's title, and the post's text and replies become the messages of
the thread hanging off of it.

A post we can't load the messages of is left out, the same as a thread we can't load when
a normal channel is reloaded.

-}
getForumChannelReload :
    SecretId ServerSecret
    -> Discord.Authentication
    -> Discord.Id Discord.ChannelId
    -> Task BackendOnly Discord.HttpError LocalState.DiscordChannelReload
getForumChannelReload secretKey authentication forumId =
    getForumPosts secretKey authentication forumId
        |> Task.andThen
            (\posts ->
                List.map
                    (\post ->
                        getManyMessages
                            secretKey
                            authentication
                            { channelId = post.threadId, limit = reloadThreadMaxMessages }
                            |> Task.map
                                (\messages ->
                                    -- Messages come back newest first, so the post's text is the last one
                                    case List.Extra.last messages of
                                        Just firstMessage ->
                                            Just { post = post, firstMessage = firstMessage, messages = messages }

                                        Nothing ->
                                            Nothing
                                )
                            |> Task.onError (\_ -> Task.succeed Nothing)
                    )
                    posts
                    |> Task.sequence
            )
        |> Task.map
            (\loadedPosts ->
                let
                    -- Newest post first, to match the order Discord returns messages in
                    loadedPosts2 : List { post : ForumPost, firstMessage : Discord.Message, messages : List Discord.Message }
                    loadedPosts2 =
                        List.filterMap identity loadedPosts
                            |> List.sortBy
                                (\loadedPost -> -(Time.posixToMillis loadedPost.firstMessage.timestamp))
                in
                { messages =
                    List.map
                        (\loadedPost -> forumPostTitleMessage loadedPost.post loadedPost.firstMessage)
                        loadedPosts2
                , threads =
                    List.map
                        (\loadedPost ->
                            { threadId = loadedPost.post.threadId, messages = loadedPost.messages }
                        )
                        loadedPosts2
                }
            )


type alias ForumPost =
    { threadId : Discord.Id Discord.ChannelId, name : String }


{-| The `ThreadCreated` message that stands in for a forum post. Discord doesn't send one
for forum posts, so we make it out of the post's first message, which is the message that
carries the author and the time the post was created.

The title is all this message shows. The post's text stays in the thread, so the
attachments, embeds, stickers and mentions that belong to it are dropped here to avoid
showing them twice.

-}
forumPostTitleMessage : ForumPost -> Discord.Message -> Discord.Message
forumPostTitleMessage post firstMessage =
    { firstMessage
        | id = Discord.idToUInt64 post.threadId |> Discord.idFromUInt64
        , content = post.name
        , type_ = Discord.ThreadCreated
        , messageReference =
            Included { messageId = Missing, channelId = Included post.threadId, guildId = Missing }

        -- The flags aren't ours to make up. Nothing needs them, since the thread this
        -- announces is loaded by getForumChannelReload rather than found via the
        -- has-thread flag the way a normal channel's threads are.
        , flags = Missing
        , editedTimestamp = Nothing
        , pinned = False
        , mentionEveryone = False
        , mentionRoles = []
        , attachments = []
        , embeds = Included []
        , reactions = Included []
        , referencedMessage = Discord.NoReference
        , stickerItems = Included []
        , stickers = Included []
        , messageSnapshots = Included []
    }


{-| The posts of a guild forum, newest first.

Searching a forum's threads is the only way to list its posts with a user token. Listing a
guild's active threads is bot-only, and the archived thread endpoints leave out the posts
that haven't been archived yet. Forum posts are archived after a few days of inactivity by
default, so most of the posts in a busy forum are archived and both have to be asked for.

-}
getForumPosts :
    SecretId ServerSecret
    -> Discord.Authentication
    -> Discord.Id Discord.ChannelId
    -> Task BackendOnly Discord.HttpError (List ForumPost)
getForumPosts secretKey authentication forumId =
    Task.map2
        (\activePosts archivedPosts ->
            activePosts
                ++ archivedPosts
                |> List.Extra.uniqueBy (\post -> Discord.idToString post.threadId)
                |> List.take reloadForumMaxPosts
        )
        (getForumPostsHelper secretKey authentication forumId { archived = False } 0 [])
        (getForumPostsHelper secretKey authentication forumId { archived = True } 0 [])


getForumPostsHelper :
    SecretId ServerSecret
    -> Discord.Authentication
    -> Discord.Id Discord.ChannelId
    -> { archived : Bool }
    -> Int
    -> List ForumPost
    -> Task BackendOnly Discord.HttpError (List ForumPost)
getForumPostsHelper secretKey authentication forumId { archived } offset postsSoFar =
    Discord.searchThreadsPayload
        authentication
        { channelId = forumId
        , name = Nothing
        , slop = Nothing
        , tag = Nothing
        , tagSetting = Nothing
        , archived = Just archived
        , sortBy = Just Discord.CreationTime
        , sortOrder = Just Discord.Descending
        , limit = Just forumPostsPerRequest
        , offset = Just offset
        , maxId = Nothing
        , minId = Nothing
        }
        |> http secretKey
        |> retryWhenRateLimited
        |> Task.andThen
            (\result ->
                let
                    postsSoFar2 : List ForumPost
                    postsSoFar2 =
                        postsSoFar
                            ++ List.filterMap
                                (\thread ->
                                    case thread.name of
                                        Included name ->
                                            Just { threadId = thread.id, name = name }

                                        Missing ->
                                            Nothing
                                )
                                result.threads
                in
                if
                    result.hasMore
                        && not (List.isEmpty result.threads)
                        && (List.length postsSoFar2 < reloadForumMaxPosts)
                then
                    getForumPostsHelper
                        secretKey
                        authentication
                        forumId
                        { archived = archived }
                        (offset + forumPostsPerRequest)
                        postsSoFar2

                else
                    Task.succeed (List.take reloadForumMaxPosts postsSoFar2)
            )


retryWhenRateLimited : Task BackendOnly Discord.HttpError a -> Task BackendOnly Discord.HttpError a
retryWhenRateLimited task =
    Task.onError
        (\error ->
            case error of
                Discord.TooManyRequests429 rateLimit ->
                    Process.sleep rateLimit.retryAfter |> Task.andThen (\() -> task)

                _ ->
                    Task.fail error
        )
        task


getManyMessages :
    SecretId ServerSecret
    -> Discord.Authentication
    -> { a | channelId : Discord.Id Discord.ChannelId, limit : Int }
    -> Task BackendOnly Discord.HttpError (List Discord.Message)
getManyMessages secretKey authentication { channelId, limit } =
    Discord.getMessagesPayload authentication { channelId = channelId, limit = min limit 100, relativeTo = Discord.MostRecent }
        |> http secretKey
        |> Task.andThen
            (\messages ->
                getManyMessagesHelper secretKey authentication channelId (limit - 100) Array.empty (Array.fromList messages)
            )


getManyMessagesHelper :
    SecretId ServerSecret
    -> Discord.Authentication
    -> Discord.Id Discord.ChannelId
    -> Int
    -> Array Discord.Message
    -> Array Discord.Message
    -> Task BackendOnly Discord.HttpError (List Discord.Message)
getManyMessagesHelper secretKey authentication channelId limit restOfMessages messages =
    case Array.Extra.last messages of
        Just last ->
            if Array.length messages >= 100 && limit > 0 then
                Discord.getMessagesPayload
                    authentication
                    { channelId = channelId, limit = min limit 100, relativeTo = Discord.Before last.id }
                    |> http secretKey
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
                                                    |> http secretKey
                                            )

                                _ ->
                                    Task.fail error
                        )
                    |> Task.andThen
                        (\newMessages ->
                            getManyMessagesHelper
                                secretKey
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
                                        { joinedAt = Just member.joinedAt, roles = SeqSet.fromList member.roles }
                                        guildMembers
                                )
                                guild.membersAndOwner
                                chunkData.members
                    }
                )
                model.discordGuilds
      }
    , List.map .user chunkData.members |> getUserAvatars model.serverSecret model.discordUsers
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
    SecretId ServerSecret
    -> SeqDict (Discord.Id Discord.UserId) DiscordUserData
    -> List { a | id : Discord.Id Discord.UserId, avatar : Maybe (Discord.ImageHash Discord.AvatarHash) }
    -> Command restriction toMsg BackendMsg
getUserAvatars secretKey existingUsers users =
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
                                    secretKey
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


loadImage : SecretId ServerSecret -> String -> Task restriction x (Maybe FileStatus.UploadResponse)
loadImage secretKey url =
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
                        FileStatus.uploadBytes secretKey bytes
                            |> Task.map Just
                            |> Task.onError (\_ -> Task.succeed Nothing)

                    Nothing ->
                        Task.succeed Nothing
            )


http : SecretId ServerSecret -> Discord.HttpRequest value -> Task BackendOnly Discord.HttpError value
http secretKey request =
    Http.task
        { method = "POST"
        , headers = [ FileStatus.secretKeyHeader secretKey ]
        , url = FileStatus.domain ++ "/file/internal/custom-request"
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
        , timeout = Just Duration.minute
        }


{-| Discord rejects thread names that are empty or longer than 100 characters. Since we derive
the name from the message the thread was started from, we need to collapse whitespace (a name
can't span multiple lines), shorten it, and fall back to a placeholder if nothing is left.
-}
threadName : String -> String
threadName text =
    case String.words text |> String.join " " |> String.left 100 |> String.trimRight of
        "" ->
            "Thread"

        name ->
            name


sendMessage :
    SecretId ServerSecret
    -> DiscordFullUserData
    -> Discord.Id Discord.ChannelId
    -> Maybe (Discord.Id Discord.MessageId)
    -> SeqDict (Id FileId) FileData
    -> OneToOne (Discord.Id Discord.StickerId) (Id StickerId)
    -> String
    -> Nonempty (RichText (Discord.Id Discord.UserId))
    -> Task BackendOnly Discord.HttpError Discord.Message
sendMessage secretKey discordUser channelId maybeReplyTo attachedFiles discordStickers discordText text =
    List.map
        (\( attachmentId, attachment ) ->
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
                |> Task.map (\bytes -> Ok ( attachmentId, attachment, bytes ))
                |> Task.onError (\() -> Task.succeed (Err ()))
        )
        (SeqDict.toList attachedFiles)
        |> Task.sequence
        |> Task.andThen
            (\attachments ->
                let
                    attachments2 : List ( Id FileId, FileData, Bytes )
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
                            (\( _, fileData, bytes ) ->
                                { fileSize = Bytes.width bytes
                                , filename = FileName.toString fileData.fileName
                                }
                            )
                            attachments2
                        )
                        |> http secretKey
                )
                    |> Task.andThen
                        (\uploadAttachmentsResponse ->
                            uploadAttachments attachments2 uploadAttachmentsResponse
                                |> Task.andThen
                                    (\_ ->
                                        let
                                            uploadAttachmentDict : SeqDict (Id FileId) { filename : String, uploadedFilename : String, contentType : String }
                                            uploadAttachmentDict =
                                                List.map2
                                                    (\a ( fileId, fileData, _ ) ->
                                                        ( fileId
                                                        , { filename = FileName.toString fileData.fileName
                                                          , uploadedFilename = a.uploadFilename
                                                          , contentType =
                                                                OneToOne.second fileData.contentType FileStatus.contentTypes
                                                                    |> Maybe.withDefault ""
                                                          }
                                                        )
                                                    )
                                                    uploadAttachmentsResponse
                                                    attachments2
                                                    |> SeqDict.fromList
                                        in
                                        Discord.createMessagePayload
                                            (Discord.userToken discordUser.auth)
                                            { channelId = channelId
                                            , content = discordText
                                            , replyTo = maybeReplyTo
                                            , attachments =
                                                List.filterMap
                                                    (\attachment ->
                                                        case SeqDict.get attachment.attachmentId uploadAttachmentDict of
                                                            Just data ->
                                                                { filename = data.filename
                                                                , uploadedFilename = data.uploadedFilename
                                                                , contentType = data.contentType
                                                                , isSpoilered = attachment.isSpoilered
                                                                }
                                                                    |> Just

                                                            Nothing ->
                                                                Nothing
                                                    )
                                                    (RichText.attachments text)
                                            , stickers =
                                                RichText.stickers text
                                                    |> List.filterMap (\stickerId -> OneToOne.first stickerId discordStickers)
                                                    |> SeqSet.fromList
                                                    |> SeqSet.toList
                                                    -- Discord will reject the message if it has more than 3 stickers
                                                    |> List.take 3
                                            }
                                            |> http secretKey
                                    )
                        )
            )


uploadAttachments : List ( Id FileId, FileData, Bytes ) -> List Discord.UploadAttachmentResponse -> Task BackendOnly x (List (Result () ()))
uploadAttachments files uploadAttachmentsResponses =
    List.map2
        (\( _, fileData, bytes ) uploadAttachmentsResponse ->
            Http.task
                { method = "PUT"
                , headers = []
                , url = uploadAttachmentsResponse.uploadUrl
                , body =
                    Http.bytesBody
                        (OneToOne.second fileData.contentType FileStatus.contentTypes
                            |> Maybe.withDefault "application/octet-stream"
                        )
                        bytes
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


{-| How many messages to load from each of a channel's threads when the channel is
reloaded. A channel can have a lot of threads and each of them costs a request per 100
messages, so this is much lower than reloadChannelMaxMessages.
-}
reloadThreadMaxMessages : Int
reloadThreadMaxMessages =
    1000


{-| How many posts to load when a guild forum is reloaded. Every post is a thread that
costs at least one request of its own, so a forum is much more expensive to reload than a
channel of the same size.
-}
reloadForumMaxPosts : Int
reloadForumMaxPosts =
    200


{-| How many threads searching a forum's threads returns at most.
-}
forumPostsPerRequest : Int
forumPostsPerRequest =
    25
