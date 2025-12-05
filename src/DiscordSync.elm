module DiscordSync exposing
    ( addDiscordDms
    , addDiscordGuilds
    , discordUserWebsocketMsg
    , http
    , loadImage
    , messagesAndLinks
    )

import Array exposing (Array)
import Array.Extra
import Broadcast
import ChannelName
import Discord exposing (OptionalData(..))
import Discord.Id
import DmChannel exposing (DiscordDmChannel, DmChannel, DmChannelId)
import Duration
import Effect.Command as Command exposing (BackendOnly, Command)
import Effect.Http as Http
import Effect.Lamdera as Lamdera
import Effect.Process as Process
import Effect.Task as Task exposing (Task)
import Effect.Websocket as Websocket
import Env
import FileStatus
import GuildName
import Id exposing (AnyGuildOrDmId(..), ChannelId, ChannelMessageId, DiscordGuildOrDmId(..), GuildId, GuildOrDmId(..), Id, ThreadMessageId, ThreadRoute(..), ThreadRouteWithMaybeMessage(..), ThreadRouteWithMessage(..), UserId)
import Json.Encode
import List.Extra
import List.Nonempty exposing (Nonempty(..))
import LocalState exposing (BackendChannel, BackendGuild, ChannelStatus(..), DiscordBackendChannel, DiscordBackendGuild, DiscordMessageAlreadyExists(..))
import Message exposing (Message(..))
import NonemptyDict
import NonemptySet
import OneToOne exposing (OneToOne)
import RichText exposing (RichText)
import Route exposing (Route(..))
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import Thread exposing (DiscordBackendThread)
import Types exposing (BackendModel, BackendMsg(..), DiscordUserData(..), LocalChange(..), LocalMsg(..), ServerChange(..), ToFrontend(..))
import User exposing (BackendUser)


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
    Debug.todo ""



--case ( reaction.guildId, SeqDict.get reaction.userId model.linkedDiscordUsers ) of
--    ( Included discordGuildId, Just userId ) ->
--        case discordGuildIdToGuild discordGuildId model of
--            Just ( guildId, guild ) ->
--                case OneToOne.second (DiscordChannelId reaction.channelId) guild.linkedChannelIds of
--                    Just channelId ->
--                        case SeqDict.get channelId guild.channels of
--                            Just channel ->
--                                case OneToOne.second (DiscordMessageId reaction.messageId) channel.linkedMessageIds of
--                                    Just messageId ->
--                                        (if isAdding then
--                                            addReactionEmoji
--
--                                         else
--                                            removeReactionEmoji
--                                        )
--                                            guildId
--                                            guild
--                                            channelId
--                                            (NoThreadWithMessage messageId)
--                                            userId
--                                            (Emoji.fromDiscord reaction.emoji)
--                                            model
--                                            Command.none
--
--                                    Nothing ->
--                                        ( model, Command.none )
--
--                            Nothing ->
--                                ( model, Command.none )
--
--                    -- If we don't find the channel ID among the guild channels then the Discord channel ID is actually a thread channel ID
--                    Nothing ->
--                        let
--                            maybeThread : Maybe ( Id ChannelId, BackendChannel, Id ChannelMessageId )
--                            maybeThread =
--                                List.Extra.findMap
--                                    (\( channelId, channel ) ->
--                                        case
--                                            OneToOne.second
--                                                (DiscordChannelId reaction.channelId)
--                                                channel.linkedThreadIds
--                                        of
--                                            Just threadId ->
--                                                Just ( channelId, channel, threadId )
--
--                                            Nothing ->
--                                                Nothing
--                                    )
--                                    (SeqDict.toList guild.channels)
--                        in
--                        case maybeThread of
--                            Just ( channelId, channel, threadId ) ->
--                                case SeqDict.get threadId channel.threads of
--                                    Just thread ->
--                                        case OneToOne.second (DiscordMessageId reaction.messageId) thread.linkedMessageIds of
--                                            Just messageId ->
--                                                (if isAdding then
--                                                    addReactionEmoji
--
--                                                 else
--                                                    removeReactionEmoji
--                                                )
--                                                    guildId
--                                                    guild
--                                                    channelId
--                                                    (ViewThreadWithMessage threadId messageId)
--                                                    userId
--                                                    (Emoji.fromDiscord reaction.emoji)
--                                                    model
--                                                    Command.none
--
--                                            Nothing ->
--                                                ( model, Command.none )
--
--                                    Nothing ->
--                                        ( model, Command.none )
--
--                            Nothing ->
--                                ( model, Command.none )
--
--            Nothing ->
--                ( model, Command.none )
--
--    _ ->
--        ( model, Command.none )


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
                        LocalState.editMessageHelper2
                            edit.timestamp
                            edit.author.id
                            richText
                            SeqDict.empty
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
                                (Server_DiscordSendEditMessage
                                    edit.timestamp
                                    (DiscordGuildOrDmId_Dm edit.author.id channelId)
                                    (NoThreadWithMessage messageIndex)
                                    richText
                                    SeqDict.empty
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
                            SeqDict.empty
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
                                (Server_DiscordSendEditMessage
                                    edit.timestamp
                                    (DiscordGuildOrDmId_Guild edit.author.id guildId edit.channelId)
                                    (NoThreadWithMessage messageIndex)
                                    richText
                                    SeqDict.empty
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
                            SeqDict.empty
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
                                (Server_DiscordSendEditMessage
                                    edit.timestamp
                                    (DiscordGuildOrDmId_Guild edit.author.id guildId channelId)
                                    (ViewThreadWithMessage threadId messageIndex)
                                    richText
                                    SeqDict.empty
                                    |> ServerChange
                                )
                                model
                            )

                        Err _ ->
                            ( model, Command.none )

                Nothing ->
                    ( model, Command.none )


handleDiscordDeleteMessage :
    Discord.Id.Id Discord.Id.GuildId
    -> Discord.Id.Id Discord.Id.ChannelId
    -> Discord.Id.Id Discord.Id.MessageId
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleDiscordDeleteMessage discordGuildId discordChannelId messageId model =
    Debug.todo ""



--case getGuildFromDiscordId discordGuildId model of
--    Just ( guildId, guild ) ->
--        case LocalState.linkedChannel (DiscordChannelId discordChannelId) guild of
--            Just ( channelId, channel ) ->
--                case OneToOne.second (DiscordMessageId messageId) channel.linkedMessageIds of
--                    Just messageIndex ->
--                        case DmChannel.getArray messageIndex channel.messages of
--                            Just (UserTextMessage data) ->
--                                ( { model
--                                    | guilds =
--                                        SeqDict.insert
--                                            guildId
--                                            { guild
--                                                | channels =
--                                                    SeqDict.insert
--                                                        channelId
--                                                        { channel
--                                                            | messages =
--                                                                DmChannel.setArray
--                                                                    messageIndex
--                                                                    (DeletedMessage data.createdAt)
--                                                                    channel.messages
--                                                            , linkedMessageIds =
--                                                                OneToOne.removeFirst
--                                                                    (DiscordMessageId messageId)
--                                                                    channel.linkedMessageIds
--                                                        }
--                                                        guild.channels
--                                            }
--                                            model.guilds
--                                  }
--                                , Broadcast.toGuild
--                                    guildId
--                                    (Server_DiscordDeleteMessage
--                                        { guildId = guildId
--                                        , channelId = channelId
--                                        , messageIndex = messageIndex
--                                        }
--                                        |> ServerChange
--                                    )
--                                    model
--                                )
--
--                            _ ->
--                                ( model, Command.none )
--
--                    Nothing ->
--                        ( model, Command.none )
--
--            Nothing ->
--                ( model, Command.none )
--
--    Nothing ->
--        ( model, Command.none )


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



--let
--    isTextChannel : Bool
--    isTextChannel =
--        case discordChannel.type_ of
--            Discord.GuildAnnouncement ->
--                True
--
--            Discord.GuildText ->
--                True
--
--            Discord.DirectMessage ->
--                True
--
--            Discord.GuildVoice ->
--                False
--
--            Discord.GroupDirectMessage ->
--                True
--
--            Discord.GuildCategory ->
--                False
--
--            Discord.AnnouncementThread ->
--                True
--
--            Discord.PublicThread ->
--                True
--
--            Discord.PrivateThread ->
--                True
--
--            Discord.GuildStageVoice ->
--                False
--
--            Discord.GuildDirectory ->
--                False
--
--            Discord.GuildForum ->
--                False
--
--            Discord.GuildMedia ->
--                False
--in
--if not (List.any (\a -> a.deny.viewChannel) discordChannel.permissionOverwrites) && isTextChannel then
--    let
--        channel : BackendChannel
--        channel =
--            { createdAt = time
--            , createdBy = ownerId
--            , name =
--                (case discordChannel.name of
--                    Included name ->
--                        name
--
--                    Missing ->
--                        "Channel " ++ String.fromInt index
--                )
--                    |> ChannelName.fromStringLossy
--            , messages = Array.empty
--            , status = ChannelActive
--            , lastTypedAt = SeqDict.empty
--            , threads = SeqDict.empty
--            }
--                |> addDiscordMessages NoThread messages model
--    in
--    ( Id.fromInt index
--    , List.foldl
--        (\( thread, threadMessages ) channel2 ->
--            case
--                OneToOne.second
--                    (Discord.Id.toUInt64 thread.id |> Discord.Id.fromUInt64 |> DiscordMessageId)
--                    channel2.linkedMessageIds
--            of
--                Just messageId ->
--                    addDiscordMessages (ViewThread messageId) threadMessages model channel2
--
--                Nothing ->
--                    channel2
--        )
--        channel
--        (SeqDict.get discordChannel.id threads |> Maybe.withDefault [])
--    )
--        |> Just
--
--else
--    Nothing


addDiscordMessages : ThreadRoute -> List Discord.Message -> BackendModel -> DiscordBackendChannel -> DiscordBackendChannel
addDiscordMessages threadRoute messages model channel =
    Debug.todo ""



--List.foldr
--    (\message channel2 ->
--        case ( message.type_, SeqDict.get message.author.id model.linkedDiscordUsers ) of
--            ( Discord.ThreadCreated, Nothing ) ->
--                channel2
--
--            ( Discord.ThreadStarterMessage, Nothing ) ->
--                channel2
--
--            ( _, Just userId ) ->
--                handleDiscordCreateGuildMessageHelper
--                    message.id
--                    message.channelId
--                    (case threadRoute of
--                        ViewThread threadId ->
--                            ViewThreadWithMaybeMessage
--                                threadId
--                                (discordReplyTo message channel2 |> Maybe.map Id.changeType)
--
--                        NoThread ->
--                            NoThreadWithMaybeMessage (discordReplyTo message channel2)
--                    )
--                    userId
--                    (RichText.fromDiscord model.linkedDiscordUsers message.content)
--                    message
--                    channel2
--
--            _ ->
--                channel2
--    )
--    channel
--    messages


addDiscordDms :
    Discord.Id.Id Discord.Id.UserId
    -> List ( Discord.Id.Id Discord.Id.PrivateChannelId, DiscordDmChannel, List Discord.Message )
    -> BackendModel
    -> BackendModel
addDiscordDms currentUserId dmChannels model =
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



--SeqDict.foldl
--    (\discordGuildId data model2 ->
--        case OneToOne.second discordGuildId model2.discordGuilds of
--            Just _ ->
--                model2
--
--            Nothing ->
--                let
--                    ownerId : Id UserId
--                    ownerId =
--                        case SeqDict.get data.guild.ownerId model2.linkedDiscordUsers of
--                            Just ownerId2 ->
--                                ownerId2
--
--                            Nothing ->
--                                Broadcast.adminUserId
--
--                    threads : SeqDict (Discord.Id.Id Discord.Id.ChannelId) (List ( Discord.Channel, List Discord.Message ))
--                    threads =
--                        List.foldl
--                            (\a dict ->
--                                case (Tuple.first a).parentId of
--                                    Included (Just parentId) ->
--                                        SeqDict.update
--                                            parentId
--                                            (\maybe ->
--                                                case maybe of
--                                                    Just list ->
--                                                        Just (a :: list)
--
--                                                    Nothing ->
--                                                        Just [ a ]
--                                            )
--                                            dict
--
--                                    _ ->
--                                        dict
--                            )
--                            SeqDict.empty
--                            data.threads
--
--                    members : SeqDict (Id UserId) { joinedAt : Time.Posix }
--                    members =
--                        List.filterMap
--                            (\guildMember ->
--                                case SeqDict.get guildMember.user.id model2.linkedDiscordUsers of
--                                    Just userId ->
--                                        if userId == ownerId then
--                                            Nothing
--
--                                        else
--                                            Just ( userId, { joinedAt = time } )
--
--                                    Nothing ->
--                                        Nothing
--                            )
--                            data.members
--                            |> SeqDict.fromList
--
--                    newGuild : BackendGuild (Id ChannelId)
--                    newGuild =
--                        { createdAt = time
--                        , createdBy = ownerId
--                        , name = GuildName.fromStringLossy data.guild.name
--                        , icon = Maybe.map .fileHash data.icon
--                        , channels = SeqDict.empty
--                        , members = members
--                        , owner = ownerId
--                        , invites = SeqDict.empty
--                        }
--
--                    newGuild2 =
--                        List.sortBy
--                            (\( channel, _ ) ->
--                                case channel.position of
--                                    Included position ->
--                                        position
--
--                                    Missing ->
--                                        9999
--                            )
--                            data.channels
--                            |> List.indexedMap Tuple.pair
--                            |> List.foldl
--                                (\( index, ( discordChannel, messages ) ) guild2 ->
--                                    case addDiscordChannel time ownerId model2 threads index discordChannel messages of
--                                        Just ( channelId, channel ) ->
--                                            { newGuild
--                                                | channels =
--                                                    SeqDict.insert
--                                                        channelId
--                                                        channel
--                                                        guild2.channels
--                                                , linkedChannelIds =
--                                                    OneToOne.insert
--                                                        (DiscordChannelId discordChannel.id)
--                                                        channelId
--                                                        guild2.linkedChannelIds
--                                            }
--
--                                        Nothing ->
--                                            guild2
--                                )
--                                newGuild
--
--                    newGuild3 : BackendGuild
--                    newGuild3 =
--                        LocalState.addMember time Broadcast.adminUserId newGuild2
--                            |> Result.withDefault newGuild2
--
--                    guildId : Id GuildId
--                    guildId =
--                        Id.nextId model2.guilds
--                in
--                { model2
--                    | discordGuilds =
--                        OneToOne.insert discordGuildId guildId model2.discordGuilds
--                    , guilds = SeqDict.insert guildId newGuild3 model2.guilds
--                    , users =
--                        SeqDict.foldl
--                            (\userId _ users ->
--                                NonemptyDict.updateIfExists
--                                    userId
--                                    (\user ->
--                                        SeqDict.foldl
--                                            (\channelId channel user2 ->
--                                                { user2
--                                                    | lastViewed =
--                                                        SeqDict.insert
--                                                            (GuildOrDmId_Guild guildId channelId)
--                                                            (DmChannel.latestMessageId channel)
--                                                            user2.lastViewed
--                                                    , lastViewedThreads =
--                                                        SeqDict.foldl
--                                                            (\threadId thread lastViewedThreads ->
--                                                                SeqDict.insert
--                                                                    ( GuildOrDmId_Guild guildId channelId, threadId )
--                                                                    (DmChannel.latestThreadMessageId thread)
--                                                                    lastViewedThreads
--                                                            )
--                                                            user2.lastViewedThreads
--                                                            channel.threads
--                                                }
--                                            )
--                                            user
--                                            newGuild3.channels
--                                    )
--                                    users
--                            )
--                            model2.users
--                            members
--                }
--    )
--    model
--    guilds


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
                                    case message.referencedMessage of
                                        Discord.Referenced referenced ->
                                            OneToOne.second referenced.id channel.linkedMessageIds

                                        Discord.ReferenceDeleted ->
                                            Nothing

                                        Discord.NoReference ->
                                            Nothing

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
                                    DiscordGuildOrDmId_Dm message.author.id dmChannelId
                            in
                            case channel2Result of
                                Ok channel2 ->
                                    ( { model
                                        | discordDmChannels =
                                            SeqDict.insert dmChannelId channel2 model.discordDmChannels
                                      }
                                    , case SeqDict.get ( message.author.id, dmChannelId ) model.pendingDiscordCreateDmMessages of
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

                                Err error ->
                                    ( model, Command.none )

                        Nothing ->
                            ( model, Command.none )

                Included discordGuildId ->
                    handleDiscordCreateGuildMessage discordGuildId message model


discordGetGuildChannel :
    Maybe (Id ChannelMessageId)
    -> Discord.Id.Id Discord.Id.ChannelId
    -> DiscordBackendGuild
    -> Maybe ( Discord.Id.Id Discord.Id.ChannelId, DiscordBackendChannel, ThreadRouteWithMaybeMessage )
discordGetGuildChannel replyTo channelId guild =
    case SeqDict.get channelId guild.channels of
        Just channel ->
            Just ( channelId, channel, NoThreadWithMaybeMessage replyTo )

        Nothing ->
            List.Extra.findMap
                (\( channelId2, channel ) ->
                    case OneToOne.second (Discord.Id.toUInt64 channelId |> Discord.Id.fromUInt64) channel.linkedMessageIds of
                        Just messageIndex ->
                            ( channelId2
                            , channel
                            , ViewThreadWithMaybeMessage messageIndex (Maybe.map Id.changeType replyTo)
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
    let
        richText : Nonempty (RichText (Discord.Id.Id Discord.Id.UserId))
        richText =
            RichText.fromDiscord message.content

        --maybeData :
        --    Maybe
        --        { guildId : Discord.Id.Id Discord.Id.GuildId
        --        , guild : BackendGuild
        --        , channelId : Discord.Id.Id Discord.Id.ChannelId
        --        , channel : BackendChannel
        --        , threadRoute : ThreadRouteWithMaybeMessage
        --        }
        --maybeData =
        --    case discordGuildIdToGuild discordGuildId model of
        --        Just ( guildId, guild ) ->
        --            case LocalState.linkedChannel (DiscordChannelId message.channelId) guild of
        --                Just ( channelId, channel ) ->
        --                    Just
        --                        { guildId = guildId
        --                        , guild = guild
        --                        , channelId = channelId
        --                        , channel = channel
        --                        , threadRoute = NoThreadWithMaybeMessage (discordReplyTo message channel)
        --                        }
        --
        --                Nothing ->
        --                    List.Extra.findMap
        --                        (\( channelId, channel ) ->
        --                            case
        --                                OneToOne.second
        --                                    (Discord.Id.toUInt64 message.channelId
        --                                        |> Discord.Id.fromUInt64
        --                                        |> DiscordMessageId
        --                                    )
        --                                    channel.linkedMessageIds
        --                            of
        --                                Just messageIndex ->
        --                                    { guildId = guildId
        --                                    , guild = guild
        --                                    , channelId = channelId
        --                                    , channel = channel
        --                                    , threadRoute =
        --                                        ViewThreadWithMaybeMessage
        --                                            messageIndex
        --                                            (discordReplyTo message channel |> Maybe.map Id.changeType)
        --                                    }
        --                                        |> Just
        --
        --                                _ ->
        --                                    Nothing
        --                        )
        --                        (SeqDict.toList guild.channels)
        --
        --        Nothing ->
        --            Nothing
    in
    case SeqDict.get discordGuildId model.discordGuilds of
        Just guild ->
            case discordGetGuildChannel Nothing {- Fix later with actual message replied to -} message.channelId guild of
                Just ( channelId, channel, threadRoute ) ->
                    let
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


discordGatewayIntents : Discord.Intents
discordGatewayIntents =
    let
        a =
            Discord.noIntents
    in
    { a
        | guild = True
        , guildMembers = True
        , guildModeration = True
        , guildExpressions = True
        , guildVoiceStates = True
        , guildMessages = True
        , guildMessageReactions = True
        , guildMessageTyping = True
        , directMessages = True
        , directMessageReactions = True
        , directMessageTyping = True
        , messageContent = True
    }


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
                                _ =
                                    Debug.log "message" (Discord.Id.toString message.channelId)

                                ( model3, cmd2 ) =
                                    handleDiscordCreateMessage message model2
                            in
                            ( model3, cmd2 :: cmds )

                        Discord.UserOutMsg_UserDeletedMessage discordGuildId discordChannelId messageId ->
                            let
                                ( model3, cmd2 ) =
                                    handleDiscordDeleteMessage discordGuildId discordChannelId messageId model2
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
            (List.map
                (\gatewayGuild ->
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
                                            gatewayGuild.threads
                                                ++ Debug.log "public" publicArchivedThreads
                                                ++ Debug.log "private" privateArchivedThreads
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
                )
                readyData.guilds
                --(if Env.isProduction then
                --    readyData.guilds
                --
                -- else
                --    List.filter
                --        (\guild ->
                --            Just guild.properties.id == Maybe.map Discord.Id.fromUInt64 (UInt64.fromString "705745250815311942")
                --        )
                --        readyData.guilds
                --)
                |> Task.sequence
            )
            |> Task.attempt (HandleReadyDataStep2 readyData.user.id)
        ]
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
    let
        _ =
            Debug.log "length" ( channelId, Array.length restOfMessages )
    in
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
                (\member discordUsers ->
                    addDiscordUserData
                        { id = member.user.id
                        , username = member.user.username
                        , avatar = member.user.avatar
                        , discriminator = member.user.discriminator
                        }
                        discordUsers
                )
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
