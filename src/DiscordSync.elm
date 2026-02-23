module DiscordSync exposing
    ( addDiscordDms
    , addDiscordGuilds
    , discordUserToPartialUser
    , discordUserWebsocketMsg
    , http
    )

import Array exposing (Array)
import Array.Extra
import Broadcast
import ChannelName exposing (ChannelName)
import Discord exposing (OptionalData(..))
import Discord.Id
import DmChannel exposing (DiscordDmChannel)
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
import FileStatus
import GuildName
import Id exposing (AnyGuildOrDmId(..), ChannelMessageId, DiscordGuildOrDmId(..), Id, ThreadMessageId, ThreadRoute(..), ThreadRouteWithMaybeMessage(..), ThreadRouteWithMessage(..))
import Json.Encode
import List.Extra
import List.Nonempty exposing (Nonempty(..))
import LocalState exposing (ChangeAttachments(..), ChannelStatus(..), DiscordBackendChannel, DiscordBackendGuild, DiscordMessageAlreadyExists(..))
import Message exposing (Message(..))
import NonemptyDict
import NonemptySet exposing (NonemptySet)
import OneToOne exposing (OneToOne)
import RichText exposing (RichText)
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import Types exposing (BackendModel, BackendMsg(..), DiscordUserData(..), LocalChange(..), LocalMsg(..), ServerChange(..), ToFrontend(..))
import User


addOrRemoveDiscordReaction :
    Bool
    ->
        { a
            | userId : Discord.Id.Id Discord.Id.UserId
            , channelId : Discord.Id.Id Discord.Id.ChannelId
            , messageId : Discord.Id.Id Discord.Id.MessageId
            , guildId : OptionalData (Discord.Id.Id Discord.Id.GuildId)
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
                dmChannelId : Discord.Id.Id Discord.Id.PrivateChannelId
                dmChannelId =
                    Discord.Id.toUInt64 reaction.channelId |> Discord.Id.fromUInt64
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
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleDiscordDmEditMessage edit model =
    let
        channelId =
            Discord.Id.toUInt64 edit.channelId |> Discord.Id.fromUInt64
    in
    case SeqDict.get channelId model.discordDmChannels of
        Just channel ->
            case OneToOne.second edit.id channel.linkedMessageIds of
                Just messageIndex ->
                    let
                        richText : Nonempty (RichText (Discord.Id.Id Discord.Id.UserId))
                        richText =
                            RichText.fromDiscord edit.content
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
    Discord.Id.Id Discord.Id.ChannelId
    -> Discord.Id.Id Discord.Id.MessageId
    -> DiscordBackendGuild
    -> Maybe ( Discord.Id.Id Discord.Id.ChannelId, DiscordBackendChannel, ThreadRouteWithMessage )
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


handleDiscordGuildEditMessage :
    Discord.Id.Id Discord.Id.GuildId
    -> DiscordBackendGuild
    -> Discord.UserMessageUpdate
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleDiscordGuildEditMessage guildId guild edit model =
    let
        richText : Nonempty (RichText (Discord.Id.Id Discord.Id.UserId))
        richText =
            RichText.fromDiscord edit.content
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
                maybeThread : Maybe ( Discord.Id.Id Discord.Id.ChannelId, DiscordBackendChannel, ( Id ChannelMessageId, Id ThreadMessageId ) )
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
    Discord.Id.Id Discord.Id.GuildId
    -> Discord.Id.Id Discord.Id.ChannelId
    -> Discord.Id.Id Discord.Id.MessageId
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
                                            (Discord.Id.toUInt64 discordChannelId |> Discord.Id.fromUInt64)
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
    Discord.Id.Id Discord.Id.MessageId
    -> { b | linkedMessageIds : OneToOne (Discord.Id.Id Discord.Id.MessageId) (Id messageId), messages : Array (Message messageId (Discord.Id.Id Discord.Id.UserId)) }
    ->
        Maybe
            ( Id messageId
            , { b | linkedMessageIds : OneToOne (Discord.Id.Id Discord.Id.MessageId) (Id messageId), messages : Array (Message messageId (Discord.Id.Id Discord.Id.UserId)) }
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
    Discord.Id.Id Discord.Id.PrivateChannelId
    -> Discord.Id.Id Discord.Id.MessageId
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


addDiscordChannel :
    SeqDict (Discord.Id.Id Discord.Id.ChannelId) (List ( Discord.Channel, List Discord.Message ))
    -> Discord.Channel
    -> List Discord.Message
    -> Maybe DiscordBackendChannel
addDiscordChannel threads discordChannel messages =
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
        let
            ( channelMessages, channelLinks ) =
                messagesAndLinks messages
        in
        { name =
            case discordChannel.name of
                Included name ->
                    ChannelName.fromStringLossy name

                Missing ->
                    ChannelName.fromStringLossy "Missing"
        , messages = channelMessages
        , status = ChannelActive
        , lastTypedAt = SeqDict.empty
        , linkedMessageIds = channelLinks
        , threads =
            case SeqDict.get discordChannel.id threads of
                Just threads2 ->
                    List.filterMap
                        (\( threadChannel, threadMessages ) ->
                            case OneToOne.second (Discord.Id.toUInt64 threadChannel.id |> Discord.Id.fromUInt64) channelLinks of
                                Just channelMessageIndex ->
                                    let
                                        ( messages2, links ) =
                                            messagesAndLinks threadMessages
                                    in
                                    ( channelMessageIndex
                                    , { messages = messages2
                                      , lastTypedAt = SeqDict.empty
                                      , linkedMessageIds = links
                                      }
                                    )
                                        |> Just

                                Nothing ->
                                    Nothing
                        )
                        threads2
                        |> SeqDict.fromList

                -- threads2
                Nothing ->
                    SeqDict.empty
        }
            |> Just

    else
        Nothing


messagesAndLinks :
    List Discord.Message
    ->
        ( Array (Message messageId (Discord.Id.Id Discord.Id.UserId))
        , OneToOne (Discord.Id.Id Discord.Id.MessageId) (Id messageId)
        )
messagesAndLinks messages =
    List.indexedMap
        (\index message ->
            ( UserTextMessage
                { createdAt = message.timestamp
                , createdBy = message.author.id
                , content = RichText.fromDiscord message.content
                , reactions = SeqDict.empty
                , editedAt = Nothing
                , repliedTo = Nothing
                , attachedFiles = SeqDict.empty
                }
            , ( message.id, Id.fromInt index )
            )
        )
        messages
        |> (\list ->
                ( List.map Tuple.first list |> Array.fromList
                , List.map Tuple.second list |> OneToOne.fromList
                )
           )


addDiscordDms :
    List ( Discord.Id.Id Discord.Id.PrivateChannelId, DiscordDmChannel, List Discord.Message )
    -> BackendModel
    -> BackendModel
addDiscordDms dmChannels model =
    { model
        | discordDmChannels =
            List.foldl
                (\( dmChannelId, channel, messages ) dmChannels2 ->
                    SeqDict.update
                        dmChannelId
                        (\maybe ->
                            case maybe of
                                Just _ ->
                                    maybe

                                Nothing ->
                                    let
                                        ( messages2, links ) =
                                            messagesAndLinks messages
                                    in
                                    { messages = messages2
                                    , lastTypedAt = SeqDict.empty
                                    , linkedMessageIds = links
                                    , members = channel.members
                                    }
                                        |> Just
                        )
                        dmChannels2
                )
                model.discordDmChannels
                dmChannels
    }


addDiscordGuilds :
    SeqDict
        (Discord.Id.Id Discord.Id.GuildId)
        { guild : Discord.GatewayGuild
        , channels : List ( Discord.Channel, List Discord.Message )
        , icon : Maybe FileStatus.UploadResponse
        , threads : List ( Discord.Id.Id Discord.Id.ChannelId, Discord.Channel, List Discord.Message )
        }
    -> BackendModel
    -> BackendModel
addDiscordGuilds guilds model =
    { model
        | discordGuilds =
            SeqDict.foldl
                (\guildId data discordGuilds ->
                    SeqDict.updateIfExists
                        guildId
                        (\guild ->
                            let
                                threads : SeqDict (Discord.Id.Id Discord.Id.ChannelId) (List ( Discord.Channel, List Discord.Message ))
                                threads =
                                    List.foldl
                                        (\( parentId, channel, messages ) dict ->
                                            SeqDict.update
                                                parentId
                                                (\maybe2 ->
                                                    case maybe2 of
                                                        Just list ->
                                                            Just (( channel, messages ) :: list)

                                                        Nothing ->
                                                            Just [ ( channel, messages ) ]
                                                )
                                                dict
                                        )
                                        SeqDict.empty
                                        data.threads
                            in
                            { name = GuildName.fromStringLossy data.guild.properties.name
                            , icon = Maybe.map .fileHash data.icon
                            , channels =
                                List.foldl
                                    (\( channel, messages ) channels ->
                                        SeqDict.update
                                            channel.id
                                            (\maybe ->
                                                case maybe of
                                                    Just _ ->
                                                        maybe

                                                    Nothing ->
                                                        addDiscordChannel threads channel messages
                                            )
                                            channels
                                    )
                                    guild.channels
                                    data.channels
                            , members = guild.members
                            , owner = data.guild.properties.ownerId
                            }
                        )
                        discordGuilds
                )
                model.discordGuilds
                guilds
    }


referencedMessageToMessageId :
    Discord.Message
    -> { a | linkedMessageIds : OneToOne (Discord.Id.Id Discord.Id.MessageId) (Id messageId) }
    -> Maybe (Id messageId)
referencedMessageToMessageId message channel =
    case message.referencedMessage of
        Discord.Referenced referenced ->
            OneToOne.second referenced.id channel.linkedMessageIds

        Discord.ReferenceDeleted ->
            Nothing

        Discord.NoReference ->
            Nothing


handleDiscordCreateMessage :
    Discord.Message
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleDiscordCreateMessage message model =
    case message.type_ of
        Discord.ThreadCreated ->
            ( model, Command.none )

        Discord.ThreadStarterMessage ->
            ( model, Command.none )

        _ ->
            case message.guildId of
                Missing ->
                    let
                        dmChannelId : Discord.Id.Id Discord.Id.PrivateChannelId
                        dmChannelId =
                            Discord.Id.toUInt64 message.channelId |> Discord.Id.fromUInt64
                    in
                    case SeqDict.get dmChannelId model.discordDmChannels of
                        Just channel ->
                            let
                                richText : Nonempty (RichText (Discord.Id.Id Discord.Id.UserId))
                                richText =
                                    RichText.fromDiscord message.content

                                replyTo : Maybe (Id ChannelMessageId)
                                replyTo =
                                    referencedMessageToMessageId message channel

                                channel2Result =
                                    LocalState.createDiscordDmChannelMessageBackend
                                        message.id
                                        (UserTextMessage
                                            { createdAt = message.timestamp
                                            , createdBy = message.author.id
                                            , content = richText
                                            , reactions = SeqDict.empty
                                            , editedAt = Nothing
                                            , repliedTo = replyTo
                                            , attachedFiles = SeqDict.empty
                                            }
                                        )
                                        channel

                                guildOrDmId : DiscordGuildOrDmId
                                guildOrDmId =
                                    DiscordGuildOrDmId_Dm { currentUserId = message.author.id, channelId = dmChannelId }
                            in
                            case channel2Result of
                                Ok channel2 ->
                                    ( { model
                                        | discordDmChannels =
                                            SeqDict.insert dmChannelId channel2 model.discordDmChannels
                                      }
                                    , case
                                        SeqDict.get
                                            { currentUserId = message.author.id, channelId = dmChannelId }
                                            model.pendingDiscordCreateDmMessages
                                      of
                                        Just ( clientId, changeId ) ->
                                            Command.batch
                                                [ LocalChangeResponse
                                                    changeId
                                                    (Local_Discord_SendMessage
                                                        message.timestamp
                                                        guildOrDmId
                                                        richText
                                                        (NoThreadWithMaybeMessage replyTo)
                                                        SeqDict.empty
                                                    )
                                                    |> Lamdera.sendToFrontend clientId
                                                , Broadcast.toDiscordDmChannelExcludingOne
                                                    clientId
                                                    dmChannelId
                                                    (Server_Discord_SendMessage
                                                        message.timestamp
                                                        guildOrDmId
                                                        richText
                                                        (NoThreadWithMaybeMessage replyTo)
                                                        SeqDict.empty
                                                        |> ServerChange
                                                    )
                                                    model
                                                ]

                                        Nothing ->
                                            Broadcast.toDiscordDmChannel
                                                dmChannelId
                                                (Server_Discord_SendMessage
                                                    message.timestamp
                                                    guildOrDmId
                                                    richText
                                                    (NoThreadWithMaybeMessage replyTo)
                                                    SeqDict.empty
                                                    |> ServerChange
                                                )
                                                model
                                      --, case NonemptyDict.get message.author.id model.discordUsers of
                                      --    Just user ->
                                      --        Broadcast.notification
                                      --            message.timestamp
                                      --            Broadcast.adminUserId
                                      --            user
                                      --            (RichText.toString (NonemptyDict.toSeqDict model.users) richText)
                                      --            (DiscordDmRoute userId (NoThreadWithFriends Nothing HideMembersTab) |> Just)
                                      --            model
                                      --
                                      --    Nothing ->
                                      --        Command.none
                                    )

                                Err _ ->
                                    ( model, Command.none )

                        Nothing ->
                            ( model, Command.none )

                Included discordGuildId ->
                    handleDiscordCreateGuildMessage discordGuildId message model


discordGetGuildChannel :
    Discord.Message
    -> DiscordBackendGuild
    -> Maybe ( Discord.Id.Id Discord.Id.ChannelId, DiscordBackendChannel, ThreadRouteWithMaybeMessage )
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
                    case OneToOne.second (Discord.Id.toUInt64 message.channelId |> Discord.Id.fromUInt64) channel.linkedMessageIds of
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
    Discord.Id.Id Discord.Id.GuildId
    -> Discord.Message
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleDiscordCreateGuildMessage discordGuildId message model =
    case SeqDict.get discordGuildId model.discordGuilds of
        Just guild ->
            case discordGetGuildChannel message guild of
                Just ( channelId, channel, threadRoute ) ->
                    let
                        richText : Nonempty (RichText (Discord.Id.Id Discord.Id.UserId))
                        richText =
                            RichText.fromDiscord message.content

                        threadOrChannelId : Discord.Id.Id Discord.Id.ChannelId
                        threadOrChannelId =
                            case threadRoute of
                                ViewThreadWithMaybeMessage threadId _ ->
                                    case OneToOne.first threadId channel.linkedMessageIds of
                                        Just messageId ->
                                            Discord.Id.toUInt64 messageId |> Discord.Id.fromUInt64

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

                        usersMentioned : SeqSet (Discord.Id.Id Discord.Id.UserId)
                        usersMentioned =
                            LocalState.usersMentionedOrRepliedToBackend
                                threadRoute
                                richText
                                (guild.owner :: SeqDict.keys guild.members)
                                channel

                        guildOrDmId : DiscordGuildOrDmId
                        guildOrDmId =
                            DiscordGuildOrDmId_Guild message.author.id discordGuildId channelId

                        channel2 : Result DiscordMessageAlreadyExists DiscordBackendChannel
                        channel2 =
                            case threadRoute of
                                ViewThreadWithMaybeMessage threadId maybeReplyTo ->
                                    LocalState.createDiscordThreadMessageBackend
                                        message.id
                                        threadId
                                        (UserTextMessage
                                            { createdAt = message.timestamp
                                            , createdBy = message.author.id
                                            , content = richText
                                            , reactions = SeqDict.empty
                                            , editedAt = Nothing
                                            , repliedTo = maybeReplyTo
                                            , attachedFiles = SeqDict.empty
                                            }
                                        )
                                        channel

                                NoThreadWithMaybeMessage maybeReplyTo ->
                                    LocalState.createDiscordChannelMessageBackend
                                        message.id
                                        (UserTextMessage
                                            { createdAt = message.timestamp
                                            , createdBy = message.author.id
                                            , content = richText
                                            , reactions = SeqDict.empty
                                            , editedAt = Nothing
                                            , repliedTo = maybeReplyTo
                                            , attachedFiles = SeqDict.empty
                                            }
                                        )
                                        channel
                    in
                    case channel2 of
                        Ok channel3 ->
                            ( { model
                                | discordGuilds =
                                    SeqDict.insert
                                        discordGuildId
                                        { guild | channels = SeqDict.insert channelId channel3 guild.channels }
                                        model.discordGuilds
                                , users =
                                    SeqSet.foldl
                                        (\discordUserId2 users ->
                                            case SeqDict.get discordUserId2 model.discordUsers of
                                                Just (FullData data) ->
                                                    let
                                                        isViewing =
                                                            Broadcast.userGetAllSessions data.linkedTo model
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
                                        model.users
                                        usersMentioned
                                , pendingDiscordCreateMessages =
                                    SeqDict.remove ( message.author.id, threadOrChannelId ) model.pendingDiscordCreateMessages
                              }
                            , Command.batch
                                [ case SeqDict.get ( message.author.id, threadOrChannelId ) model.pendingDiscordCreateMessages of
                                    Just ( clientId, changeId ) ->
                                        Command.batch
                                            [ LocalChangeResponse
                                                changeId
                                                (Local_Discord_SendMessage message.timestamp guildOrDmId richText threadRoute SeqDict.empty)
                                                |> Lamdera.sendToFrontend clientId
                                            , Broadcast.toDiscordGuildExcludingOne
                                                clientId
                                                discordGuildId
                                                (Server_Discord_SendMessage message.timestamp guildOrDmId richText threadRoute SeqDict.empty
                                                    |> ServerChange
                                                )
                                                model
                                            ]

                                    Nothing ->
                                        Broadcast.toDiscordGuild
                                            discordGuildId
                                            (Server_Discord_SendMessage
                                                message.timestamp
                                                guildOrDmId
                                                richText
                                                threadRoute
                                                SeqDict.empty
                                                |> ServerChange
                                            )
                                            model

                                --, Broadcast.messageNotification
                                --    usersMentioned
                                --    message.timestamp
                                --    userId
                                --    discordGuildId
                                --    channelId
                                --    threadRouteNoReply
                                --    richText
                                --    (guild.owner :: SeqDict.keys guild.members)
                                --    model
                                ]
                            )

                        Err DiscordMessageAlreadyExists ->
                            ( model, Command.none )

                Nothing ->
                    ( model, Command.none )

        _ ->
            ( model, Command.none )


discordUserWebsocketMsg : Discord.Id.Id Discord.Id.UserId -> Discord.Msg -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
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
                            , Task.perform (\() -> WebsocketClosedByBackendForUser discordUserId True) (Websocket.close connection)
                                :: cmds
                            )

                        Discord.UserOutMsg_OpenHandle ->
                            ( model2
                            , Websocket.createHandle (WebsocketCreatedHandleForUser discordUserId) Discord.websocketGatewayUrl
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
                                ( model3, cmd2 ) =
                                    handleDiscordCreateMessage message model2
                            in
                            ( model3, cmd2 :: cmds )

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
                                ( model3, cmd2 ) =
                                    case edit.guildId of
                                        Included guildId ->
                                            case SeqDict.get guildId model2.discordGuilds of
                                                Just guild ->
                                                    handleDiscordGuildEditMessage guildId guild edit model2

                                                Nothing ->
                                                    ( model2, Command.none )

                                        Missing ->
                                            handleDiscordDmEditMessage edit model2
                            in
                            ( model3, cmd2 :: cmds )

                        Discord.UserOutMsg_FailedToParseWebsocketMessage error ->
                            let
                                _ =
                                    Debug.log "gateway error" error
                            in
                            ( model2, cmds )

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
                                    handleReadyData userData.auth readyData model2
                            in
                            ( model3, cmd2 :: cmds )

                        Discord.UserOutMsg_SupplementalReadyData readySupplementalData ->
                            ( handleReadySupplementalData readySupplementalData model2, cmds )

                        Discord.UserOutMsg_ChannelCreated channel ->
                            let
                                ( model3, cmd2 ) =
                                    handleChannelCreated channel model2
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


handleChannelCreated : Discord.Channel -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleChannelCreated channel model =
    case channel.guildId of
        Missing ->
            case channel.recipients of
                Included (head :: rest) ->
                    let
                        channelId : Discord.Id.Id Discord.Id.PrivateChannelId
                        channelId =
                            Discord.Id.toUInt64 channel.id |> Discord.Id.fromUInt64

                        members : NonemptySet (Discord.Id.Id Discord.Id.UserId)
                        members =
                            NonemptySet.fromNonemptyList
                                (Nonempty head.id (List.map .id rest))

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
                        , getUserAvatars (head :: rest)
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
                                                Just _ ->
                                                    maybeChannel

                                                Nothing ->
                                                    { name = name
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
                (Server_DiscordChannelCreated guildId channel.id name |> ServerChange)
                model
            )


handleReadySupplementalData : Discord.ReadySupplementalData -> BackendModel -> BackendModel
handleReadySupplementalData data model =
    List.map2
        (\{ id } mergedMembers ->
            ( id, mergedMembers )
        )
        data.guilds
        data.mergedMembers
        |> List.foldl
            (\( guildId, mergedMembers ) model2 ->
                { model2
                    | discordGuilds =
                        SeqDict.updateIfExists
                            guildId
                            (\guild ->
                                { guild
                                    | members =
                                        List.foldl
                                            (\mergedMembers2 members ->
                                                SeqDict.insert
                                                    mergedMembers2.userId
                                                    { joinedAt = mergedMembers2.joinedAt }
                                                    members
                                            )
                                            guild.members
                                            mergedMembers
                                }
                            )
                            model2.discordGuilds
                }
            )
            model


handleReadyData : Discord.UserAuth -> Discord.ReadyData -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleReadyData userAuth readyData model =
    let
        auth : Discord.Authentication
        auth =
            Discord.userToken userAuth

        discordDmChannels : SeqDict (Discord.Id.Id Discord.Id.PrivateChannelId) DiscordDmChannel
        discordDmChannels =
            case readyData.privateChannels of
                Included privateChannels ->
                    List.foldl
                        (\dmChannel dmChannels ->
                            SeqDict.insert
                                dmChannel.id
                                (DmChannel.discordBackendInit readyData.user.id dmChannel)
                                dmChannels
                        )
                        model.discordDmChannels
                        privateChannels

                Missing ->
                    model.discordDmChannels
    in
    ( { model
        | discordGuilds =
            List.foldl
                (\data discordGuilds ->
                    SeqDict.update
                        data.properties.id
                        (\maybe ->
                            case maybe of
                                Just _ ->
                                    maybe

                                Nothing ->
                                    { name = GuildName.fromStringLossy data.properties.name
                                    , icon = Nothing
                                    , channels = SeqDict.empty -- Gets filled after LinkDiscordUserStep2 is triggered
                                    , members = SeqDict.empty -- Gets filled in via the websocket connection
                                    , owner = data.properties.ownerId
                                    }
                                        |> Just
                        )
                        discordGuilds
                )
                model.discordGuilds
                readyData.guilds
        , discordUsers = List.foldl addDiscordUserData model.discordUsers readyData.users
      }
    , Command.batch
        [ Websocket.createHandle (WebsocketCreatedHandleForUser readyData.user.id) Discord.websocketGatewayUrl
        , getUserAvatars readyData.users
        , Task.map2
            Tuple.pair
            (List.filterMap
                (\( dmChannelId, dmChannel ) ->
                    if SeqDict.member dmChannelId model.discordDmChannels then
                        Nothing

                    else
                        Discord.getDirectMessagesPayload
                            userAuth
                            { channelId = dmChannelId
                            , limit = 100
                            , relativeTo = Discord.MostRecent
                            }
                            |> http
                            |> Task.onError (\_ -> Task.succeed [])
                            |> Task.map (\a -> ( dmChannelId, dmChannel, List.reverse a ))
                            |> Just
                )
                (SeqDict.toList discordDmChannels)
                |> Task.sequence
            )
            (List.map (getDiscordGuildData auth) readyData.guilds |> Task.sequence)
            |> Task.andThen (\data -> Task.map (\time -> HandleReadyDataStep2 time readyData.user.id (Ok data)) Time.now)
            |> Task.onError (\error -> Task.map (\time -> HandleReadyDataStep2 time readyData.user.id (Err error)) Time.now)
            |> Task.perform identity
        ]
    )


getDiscordGuildData :
    Discord.Authentication
    -> Discord.GatewayGuild
    ->
        Task
            BackendOnly
            Discord.HttpError
            ( Discord.Id.Id Discord.Id.GuildId
            , { guild : Discord.GatewayGuild
              , channels : List ( Discord.Channel, List Discord.Message )
              , icon : Maybe FileStatus.UploadResponse
              , threads : List ( Discord.Id.Id Discord.Id.ChannelId, Discord.Channel, List Discord.Message )
              }
            )
getDiscordGuildData auth gatewayGuild =
    Task.map3
        (\channels maybeIcon threads ->
            ( gatewayGuild.properties.id
            , { guild = gatewayGuild
              , channels = channels
              , icon = maybeIcon
              , threads = threads
              }
            )
        )
        (List.map
            (\channel ->
                getManyMessages auth { channelId = channel.id, limit = 1000 }
                    |> Task.onError (\_ -> Task.succeed [])
                    |> Task.map (\a -> ( channel, List.reverse a ))
            )
            gatewayGuild.channels
            |> Task.sequence
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
        (Task.map2
            Tuple.pair
            (List.map
                (\channel ->
                    Discord.getPublicArchivedThreadsPayload
                        auth
                        { channelId = channel.id
                        , before = Nothing
                        , limit = Just 100
                        }
                        |> http
                        |> Task.map .threads
                        |> Task.onError (\_ -> Task.succeed [])
                )
                gatewayGuild.channels
                |> Task.sequence
                |> Task.map List.concat
            )
            (List.map
                (\channel ->
                    Discord.getPrivateArchivedThreadsPayload
                        auth
                        { channelId = channel.id
                        , before = Nothing
                        , limit = Just 100
                        }
                        |> http
                        |> Task.map .threads
                        |> Task.onError (\_ -> Task.succeed [])
                )
                gatewayGuild.channels
                |> Task.sequence
                |> Task.map List.concat
            )
            |> Task.andThen
                (\( publicArchivedThreads, privateArchivedThreads ) ->
                    let
                        allThreads : List Discord.Channel
                        allThreads =
                            gatewayGuild.threads ++ publicArchivedThreads ++ privateArchivedThreads
                    in
                    List.filterMap
                        (\thread ->
                            case thread.parentId of
                                Included (Just parentId) ->
                                    getManyMessages auth { channelId = thread.id, limit = 1000 }
                                        |> Task.onError (\_ -> Task.succeed [])
                                        |> Task.map (\a -> ( parentId, thread, List.reverse a ))
                                        |> Just

                                _ ->
                                    Nothing
                        )
                        allThreads
                        |> Task.sequence
                )
        )


getManyMessages : Discord.Authentication -> { a | channelId : Discord.Id.Id Discord.Id.ChannelId, limit : Int } -> Task BackendOnly Discord.HttpError (List Discord.Message)
getManyMessages authentication { channelId, limit } =
    Discord.getMessagesPayload authentication { channelId = channelId, limit = min limit 100, relativeTo = Discord.MostRecent }
        |> http
        |> Task.andThen (\messages -> getManyMessagesHelper authentication channelId (limit - 100) Array.empty (Array.fromList messages))


getManyMessagesHelper :
    Discord.Authentication
    -> Discord.Id.Id Discord.Id.ChannelId
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
    -> SeqDict (Discord.Id.Id Discord.Id.UserId) DiscordUserData
    -> SeqDict (Discord.Id.Id Discord.Id.UserId) DiscordUserData
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


discordUserToPartialUser :
    { a
        | id : Discord.Id.Id Discord.Id.UserId
        , username : String
        , avatar : Maybe (Discord.ImageHash Discord.AvatarHash)
        , discriminator : Discord.UserDiscriminator
    }
    -> Discord.PartialUser
discordUserToPartialUser user =
    { id = user.id
    , username = user.username
    , avatar = user.avatar
    , discriminator = user.discriminator
    }


handleListGuildMembersResponse :
    Discord.GuildMembersChunkData
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleListGuildMembersResponse chunkData model =
    ( { model
        | discordUsers =
            List.foldl
                (\member discordUsers -> addDiscordUserData (discordUserToPartialUser member.user) discordUsers)
                model.discordUsers
                chunkData.members
        , discordGuilds =
            SeqDict.updateIfExists
                chunkData.guildId
                (\guild ->
                    { guild
                        | members =
                            List.foldl
                                (\member guildMembers ->
                                    SeqDict.update
                                        member.user.id
                                        (\maybe ->
                                            case maybe of
                                                Just _ ->
                                                    maybe

                                                Nothing ->
                                                    { joinedAt = member.joinedAt }
                                                        |> Just
                                        )
                                        guildMembers
                                )
                                guild.members
                                chunkData.members
                    }
                )
                model.discordGuilds
      }
    , List.map .user chunkData.members |> getUserAvatars
    )


getUserAvatars :
    List { a | id : Discord.Id.Id Discord.Id.UserId, avatar : Maybe (Discord.ImageHash Discord.AvatarHash) }
    -> Command restriction toMsg BackendMsg
getUserAvatars users =
    List.map
        (\user ->
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
        )
        users
        |> Task.sequence
        |> Task.attempt GotDiscordUserAvatars


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
                        FileStatus.uploadBytes Env.secretKey bytes
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
