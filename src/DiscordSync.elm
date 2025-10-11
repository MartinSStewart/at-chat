module DiscordSync exposing
    ( addDiscordGuilds
    , addDiscordUsers
    , addReactionEmoji
    , discordUserWebsocketMsg
    , gotCurrentUserGuildsForUser
    , http
    , loadImage
    )

import Array
import Broadcast
import ChannelName
import Discord exposing (OptionalData(..))
import Discord.Id
import DmChannel exposing (DmChannel, DmChannelId, ExternalChannelId(..), ExternalMessageId(..))
import Duration
import Effect.Command as Command exposing (BackendOnly, Command)
import Effect.Http as Http
import Effect.Process as Process
import Effect.Task as Task exposing (Task)
import Effect.Time as Time
import Effect.Websocket as Websocket
import Emoji exposing (Emoji)
import Env
import FileStatus
import GuildName
import Id exposing (ChannelId, ChannelMessageId, GuildId, GuildOrDmIdNoThread(..), Id, ThreadRoute(..), ThreadRouteWithMaybeMessage(..), ThreadRouteWithMessage(..), UserId)
import Json.Encode
import List.Extra
import List.Nonempty exposing (Nonempty)
import LocalState exposing (BackendChannel, BackendGuild, ChannelStatus(..))
import Message exposing (Message(..))
import NonemptyDict
import OneToOne
import PersonName
import RichText exposing (RichText)
import Route exposing (Route(..), ShowMembersTab(..), ThreadRouteWithFriends(..))
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import Types exposing (BackendModel, BackendMsg(..), DiscordUserData(..), LocalMsg(..), ServerChange(..), ToFrontend)
import UInt64
import User exposing (BackendUser, EmailStatus(..))


addReactionEmoji :
    Id GuildId
    -> BackendGuild (Id ChannelId)
    -> Id ChannelId
    -> ThreadRouteWithMessage
    -> Id UserId
    -> Emoji
    -> BackendModel
    -> Command BackendOnly ToFrontend msg
    -> ( BackendModel, Command BackendOnly ToFrontend msg )
addReactionEmoji guildId guild channelId threadRoute userId emoji model cmds =
    ( { model
        | guilds =
            SeqDict.insert
                guildId
                (LocalState.updateChannel (LocalState.addReactionEmoji emoji userId threadRoute) channelId guild)
                model.guilds
      }
    , Command.batch
        [ cmds
        , Broadcast.toGuild
            guildId
            (Server_AddReactionEmoji userId (GuildOrDmId_Guild guildId channelId) threadRoute emoji |> ServerChange)
            model
        ]
    )


removeReactionEmoji :
    Id GuildId
    -> BackendGuild (Id ChannelId)
    -> Id ChannelId
    -> ThreadRouteWithMessage
    -> Id UserId
    -> Emoji
    -> BackendModel
    -> Command BackendOnly ToFrontend msg
    -> ( BackendModel, Command BackendOnly ToFrontend msg )
removeReactionEmoji guildId guild channelId threadRoute userId emoji model cmds =
    ( { model
        | guilds =
            SeqDict.insert
                guildId
                (LocalState.updateChannel (LocalState.removeReactionEmoji emoji userId threadRoute) channelId guild)
                model.guilds
      }
    , Command.batch
        [ cmds
        , Broadcast.toGuild
            guildId
            (Server_RemoveReactionEmoji userId (GuildOrDmId_Guild guildId channelId) threadRoute emoji |> ServerChange)
            model
        ]
    )


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


handleDiscordEditMessage :
    Discord.MessageUpdate
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleDiscordEditMessage edit model =
    Debug.todo ""



--case getGuildFromDiscordId edit.guildId model of
--    Just ( guildId, guild ) ->
--        case LocalState.linkedChannel (DiscordChannelId edit.channelId) guild of
--            Just ( channelId, channel ) ->
--                case
--                    ( OneToOne.second (DiscordMessageId edit.id) channel.linkedMessageIds
--                    , SeqDict.get edit.author.id model.linkedDiscordUsers
--                    )
--                of
--                    ( Just messageIndex, Just userId ) ->
--                        let
--                            richText : Nonempty (RichText (Id UserId))
--                            richText =
--                                RichText.fromDiscord model.discordUser edit.content
--                        in
--                        case
--                            LocalState.editMessageHelper
--                                edit.timestamp
--                                userId
--                                richText
--                                SeqDict.empty
--                                (NoThreadWithMessage messageIndex)
--                                channel
--                        of
--                            Ok channel2 ->
--                                ( { model
--                                    | guilds =
--                                        SeqDict.updateIfExists
--                                            guildId
--                                            (LocalState.updateChannel (\_ -> channel2) channelId)
--                                            model.guilds
--                                  }
--                                , Broadcast.toGuild
--                                    guildId
--                                    (Server_SendEditMessage
--                                        edit.timestamp
--                                        userId
--                                        (GuildOrDmId_Guild guildId channelId)
--                                        (NoThreadWithMessage messageIndex)
--                                        richText
--                                        SeqDict.empty
--                                        |> ServerChange
--                                    )
--                                    model
--                                )
--
--                            Err _ ->
--                                ( model, Command.none )
--
--                    _ ->
--                        -- TODO handle edit thread messages
--                        ( model, Command.none )
--
--            Nothing ->
--                ( model, Command.none )
--
--    Nothing ->
--        ( model, Command.none )


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


addDiscordUsers :
    Time.Posix
    -> SeqDict (Discord.Id.Id Discord.Id.UserId) Discord.GuildMember
    -> BackendModel
    -> BackendModel
addDiscordUsers time newUsers model =
    SeqDict.foldl
        (\discordUserId discordUser model2 ->
            { model2
                | discordUser =
                    SeqDict.update
                        discordUserId
                        (\maybe ->
                            case maybe of
                                Just _ ->
                                    maybe

                                Nothing ->
                                    BasicData discordUser |> Just
                        )
                        model2.discordUser
            }
        )
        model
        newUsers


addDiscordChannel :
    Time.Posix
    -> Id UserId
    -> BackendModel
    -> SeqDict (Discord.Id.Id Discord.Id.ChannelId) (List ( Discord.Channel, List Discord.Message ))
    -> Int
    -> Discord.Channel2
    -> List Discord.Message
    -> Maybe ( Id ChannelId, BackendChannel )
addDiscordChannel time ownerId model threads index discordChannel messages =
    Debug.todo ""



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


addDiscordMessages : ThreadRoute -> List Discord.Message -> BackendModel -> BackendChannel -> BackendChannel
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


addDiscordGuilds :
    Time.Posix
    ->
        SeqDict
            (Discord.Id.Id Discord.Id.GuildId)
            { guild : Discord.Guild
            , members : List Discord.GuildMember
            , channels : List ( Discord.Channel2, List Discord.Message )
            , icon : Maybe FileStatus.UploadResponse
            , threads : List ( Discord.Channel, List Discord.Message )
            }
    -> BackendModel
    -> BackendModel
addDiscordGuilds time guilds model =
    Debug.todo ""



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
    Debug.todo ""



--case message.type_ of
--    Discord.ThreadCreated ->
--        ( model, Command.none )
--
--    Discord.ThreadStarterMessage ->
--        ( model, Command.none )
--
--    _ ->
--        case ( SeqDict.get message.author.id model.linkedDiscordUsers, message.guildId ) of
--            ( Just userId, Missing ) ->
--                let
--                    richText : Nonempty (RichText (Id UserId))
--                    richText =
--                        RichText.fromDiscord model.linkedDiscordUsers message.content
--
--                    dmChannelId : DmChannelId
--                    dmChannelId =
--                        DmChannel.channelIdFromUserIds userId Broadcast.adminUserId
--
--                    dmChannel : DmChannel
--                    dmChannel =
--                        Maybe.withDefault DmChannel.init (SeqDict.get dmChannelId model.dmChannels)
--
--                    replyTo : Maybe (Id ChannelMessageId)
--                    replyTo =
--                        case message.referencedMessage of
--                            Discord.Referenced referenced ->
--                                OneToOne.second (DiscordMessageId referenced.id) dmChannel.linkedMessageIds
--
--                            Discord.ReferenceDeleted ->
--                                Nothing
--
--                            Discord.NoReference ->
--                                Nothing
--                in
--                ( { model
--                    | dmChannels =
--                        SeqDict.insert
--                            dmChannelId
--                            (LocalState.createChannelMessageBackend
--                                (Just (DiscordMessageId message.id))
--                                (UserTextMessage
--                                    { createdAt = message.timestamp
--                                    , createdBy = userId
--                                    , content = richText
--                                    , reactions = SeqDict.empty
--                                    , editedAt = Nothing
--                                    , repliedTo =
--                                        case message.referencedMessage of
--                                            Discord.Referenced referenced ->
--                                                OneToOne.second
--                                                    (DiscordMessageId referenced.id)
--                                                    dmChannel.linkedMessageIds
--
--                                            Discord.ReferenceDeleted ->
--                                                Nothing
--
--                                            Discord.NoReference ->
--                                                Nothing
--                                    , attachedFiles = SeqDict.empty
--                                    }
--                                )
--                                dmChannel
--                            )
--                            model.dmChannels
--                    , discordDms = OneToOne.insert message.channelId dmChannelId model.discordDms
--                  }
--                , Command.batch
--                    [ Broadcast.toUser
--                        Nothing
--                        Nothing
--                        Broadcast.adminUserId
--                        (Server_DiscordDirectMessage message.timestamp userId richText replyTo
--                            |> ServerChange
--                        )
--                        model
--                    , case NonemptyDict.get userId model.users of
--                        Just user ->
--                            Broadcast.notification
--                                message.timestamp
--                                Broadcast.adminUserId
--                                user
--                                (RichText.toString (NonemptyDict.toSeqDict model.users) richText)
--                                (DmRoute userId (NoThreadWithFriends Nothing HideMembersTab) |> Just)
--                                model
--
--                        Nothing ->
--                            Command.none
--                    ]
--                )
--
--            ( Just userId, Included discordGuildId ) ->
--                handleDiscordCreateGuildMessage userId discordGuildId message model
--
--            _ ->
--                let
--                    _ =
--                        Debug.log "user id not found for message" message
--                in
--                ( model, Command.none )


handleDiscordCreateGuildMessage :
    Id UserId
    -> Discord.Id.Id Discord.Id.GuildId
    -> Discord.Message
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleDiscordCreateGuildMessage userId discordGuildId message model =
    Debug.todo ""



--let
--    richText : Nonempty RichText
--    richText =
--        RichText.fromDiscord model.linkedDiscordUsers message.content
--
--    maybeData : Maybe { guildId : Id GuildId, guild : BackendGuild, channelId : Id ChannelId, channel : BackendChannel, threadRoute : ThreadRouteWithMaybeMessage }
--    maybeData =
--        case discordGuildIdToGuild discordGuildId model of
--            Just ( guildId, guild ) ->
--                case LocalState.linkedChannel (DiscordChannelId message.channelId) guild of
--                    Just ( channelId, channel ) ->
--                        Just
--                            { guildId = guildId
--                            , guild = guild
--                            , channelId = channelId
--                            , channel = channel
--                            , threadRoute = NoThreadWithMaybeMessage (discordReplyTo message channel)
--                            }
--
--                    Nothing ->
--                        List.Extra.findMap
--                            (\( channelId, channel ) ->
--                                case
--                                    OneToOne.second
--                                        (Discord.Id.toUInt64 message.channelId
--                                            |> Discord.Id.fromUInt64
--                                            |> DiscordMessageId
--                                        )
--                                        channel.linkedMessageIds
--                                of
--                                    Just messageIndex ->
--                                        { guildId = guildId
--                                        , guild = guild
--                                        , channelId = channelId
--                                        , channel = channel
--                                        , threadRoute =
--                                            ViewThreadWithMaybeMessage
--                                                messageIndex
--                                                (discordReplyTo message channel |> Maybe.map Id.changeType)
--                                        }
--                                            |> Just
--
--                                    _ ->
--                                        Nothing
--                            )
--                            (SeqDict.toList guild.channels)
--
--            Nothing ->
--                Nothing
--in
--case maybeData of
--    Just { guildId, guild, channelId, channel, threadRoute } ->
--        let
--            threadRouteNoReply : ThreadRoute
--            threadRouteNoReply =
--                case threadRoute of
--                    ViewThreadWithMaybeMessage threadId _ ->
--                        ViewThread threadId
--
--                    NoThreadWithMaybeMessage _ ->
--                        NoThread
--
--            usersMentioned : SeqSet (Id UserId)
--            usersMentioned =
--                LocalState.usersMentionedOrRepliedToBackend
--                    threadRoute
--                    richText
--                    (guild.owner :: SeqDict.keys guild.members)
--                    channel
--
--            guildOrDmId =
--                GuildOrDmId_Guild guildId channelId
--        in
--        ( { model
--            | guilds =
--                SeqDict.insert
--                    guildId
--                    { guild
--                        | channels =
--                            SeqDict.insert
--                                channelId
--                                (handleDiscordCreateGuildMessageHelper
--                                    message.id
--                                    message.channelId
--                                    threadRoute
--                                    userId
--                                    richText
--                                    message
--                                    channel
--                                )
--                                guild.channels
--                    }
--                    model.guilds
--            , users =
--                SeqSet.foldl
--                    (\userId2 users ->
--                        let
--                            isViewing =
--                                Broadcast.userGetAllSessions userId2 model
--                                    |> List.any
--                                        (\( _, userSession ) ->
--                                            userSession.currentlyViewing == Just ( guildOrDmId, threadRouteNoReply )
--                                        )
--                        in
--                        if isViewing then
--                            users
--
--                        else
--                            NonemptyDict.updateIfExists
--                                userId2
--                                (User.addDirectMention guildId channelId threadRouteNoReply)
--                                users
--                    )
--                    model.users
--                    usersMentioned
--          }
--        , Command.batch
--            [ Broadcast.toGuild
--                guildId
--                (Server_SendMessage userId message.timestamp guildOrDmId richText threadRoute SeqDict.empty
--                    |> ServerChange
--                )
--                model
--            , Broadcast.messageNotification
--                usersMentioned
--                message.timestamp
--                userId
--                guildId
--                channelId
--                threadRouteNoReply
--                richText
--                (guild.owner :: SeqDict.keys guild.members)
--                model
--            ]
--        )
--
--    _ ->
--        ( model, Command.none )


handleDiscordCreateGuildMessageHelper :
    Discord.Id.Id Discord.Id.MessageId
    -> Discord.Id.Id Discord.Id.ChannelId
    -> ThreadRouteWithMaybeMessage
    -> Id UserId
    -> Nonempty (RichText (Id UserId))
    -> Discord.Message
    -> BackendChannel
    -> BackendChannel
handleDiscordCreateGuildMessageHelper discordMessageId discordChannelId threadRouteWithMaybeReplyTo userId richText message channel =
    Debug.todo ""



--case threadRouteWithMaybeReplyTo of
--    ViewThreadWithMaybeMessage threadId maybeReplyTo ->
--        LocalState.createThreadMessageBackend
--            (Just ( DiscordMessageId discordMessageId, DiscordChannelId discordChannelId ))
--            threadId
--            (UserTextMessage
--                { createdAt = message.timestamp
--                , createdBy = userId
--                , content = richText
--                , reactions = SeqDict.empty
--                , editedAt = Nothing
--                , repliedTo = maybeReplyTo
--                , attachedFiles = SeqDict.empty
--                }
--            )
--            channel
--
--    NoThreadWithMaybeMessage maybeReplyTo ->
--        LocalState.createChannelMessageBackend
--            (Just (DiscordMessageId discordMessageId))
--            (UserTextMessage
--                { createdAt = message.timestamp
--                , createdBy = userId
--                , content = richText
--                , reactions = SeqDict.empty
--                , editedAt = Nothing
--                , repliedTo = maybeReplyTo
--                , attachedFiles = SeqDict.empty
--                }
--            )
--            channel


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
    case SeqDict.get discordUserId model.discordUser of
        Just (FullData userData) ->
            let
                _ =
                    Debug.log "discordUserWebsocketMsg" discordUserId
            in
            let
                ( discordModel2, outMsgs ) =
                    Discord.update (Discord.userToken userData.auth) Discord.noIntents discordMsg userData.connection
                        |> Debug.log "outMsgs"
            in
            List.foldl
                (\outMsg ( model2, cmds ) ->
                    case outMsg of
                        Discord.CloseAndReopenHandle connection ->
                            ( model2
                            , Task.perform (\() -> WebsocketClosedByBackendForUser discordUserId True) (Websocket.close connection)
                                :: cmds
                            )

                        Discord.OpenHandle ->
                            ( model2
                            , Websocket.createHandle (WebsocketCreatedHandleForUser discordUserId) Discord.websocketGatewayUrl
                                :: cmds
                            )

                        Discord.SendWebsocketData connection data ->
                            ( model2
                            , Task.attempt (WebsocketSentDataForUser discordUserId) (Websocket.sendString connection data)
                                :: cmds
                            )

                        Discord.SendWebsocketDataWithDelay connection duration data ->
                            ( model2
                            , (Process.sleep duration
                                |> Task.andThen (\() -> Websocket.sendString connection data)
                                |> Task.attempt (WebsocketSentDataForUser discordUserId)
                              )
                                :: cmds
                            )

                        Discord.UserCreatedMessage _ message ->
                            let
                                ( model3, cmd2 ) =
                                    handleDiscordCreateMessage message model2
                            in
                            ( model3, cmd2 :: cmds )

                        Discord.UserDeletedMessage discordGuildId discordChannelId messageId ->
                            let
                                ( model3, cmd2 ) =
                                    handleDiscordDeleteMessage discordGuildId discordChannelId messageId model2
                            in
                            ( model3, cmd2 :: cmds )

                        Discord.UserEditedMessage messageUpdate ->
                            let
                                ( model3, cmd2 ) =
                                    handleDiscordEditMessage messageUpdate model2
                            in
                            ( model3, cmd2 :: cmds )

                        Discord.FailedToParseWebsocketMessage error ->
                            let
                                _ =
                                    Debug.log "gateway error" error
                            in
                            ( model2, cmds )

                        Discord.ThreadCreatedOrUserAddedToThread _ ->
                            ( model2, cmds )

                        Discord.UserAddedReaction reaction ->
                            let
                                ( model3, cmd2 ) =
                                    addOrRemoveDiscordReaction True reaction model2
                            in
                            ( model3, cmd2 :: cmds )

                        Discord.UserRemovedReaction reaction ->
                            let
                                ( model3, cmd2 ) =
                                    addOrRemoveDiscordReaction False reaction model2
                            in
                            ( model3, cmd2 :: cmds )

                        Discord.AllReactionsRemoved reactionRemoveAll ->
                            let
                                ( model3, cmd2 ) =
                                    handleDiscordRemoveAllReactions reactionRemoveAll model2
                            in
                            ( model3, cmd2 :: cmds )

                        Discord.ReactionsRemoveForEmoji reactionRemoveEmoji ->
                            let
                                ( model3, cmd2 ) =
                                    handleDiscordRemoveReactionForEmoji reactionRemoveEmoji model2
                            in
                            ( model3, cmd2 :: cmds )
                )
                ( { model
                    | discordUser =
                        SeqDict.insert
                            discordUserId
                            (FullData { userData | connection = discordModel2 })
                            model.discordUser
                  }
                , []
                )
                outMsgs
                |> Tuple.mapSecond Command.batch

        _ ->
            ( model, Command.none )


gotCurrentUserGuildsForUser :
    Time.Posix
    -> Id UserId
    -> Discord.UserAuth
    -> Discord.User
    -> Result error ( List Discord.PartialGuild, List Discord.Relationship )
    -> BackendModel
    -> ( BackendModel, Command restriction toMsg BackendMsg )
gotCurrentUserGuildsForUser time userId userAuth discordUser result model =
    case result of
        Ok ( guilds, relationships ) ->
            let
                auth : Discord.Authentication
                auth =
                    Discord.userToken userAuth
            in
            ( { model
                | linkedDiscordUsers = SeqDict.insert discordUser.id userId model.linkedDiscordUsers
                , discordUser =
                    SeqDict.insert
                        discordUser.id
                        (FullData
                            { auth = userAuth
                            , data = discordUser
                            , connection = Discord.init
                            }
                        )
                        model.discordUser
              }
            , Command.batch
                [ Websocket.createHandle (WebsocketCreatedHandleForUser discordUser.id) Discord.websocketGatewayUrl
                , List.map
                    (\partialGuild ->
                        Task.map5
                            (\guild members channels maybeIcon threads ->
                                ( guild.id
                                , { guild = guild
                                  , members = members
                                  , channels = channels
                                  , icon = maybeIcon
                                  , threads = threads
                                  }
                                )
                            )
                            (Discord.getGuildPayload auth partialGuild.id |> http)
                            (Discord.listGuildMembersPayload
                                auth
                                { guildId = partialGuild.id
                                , limit = 1000
                                , after = Discord.Missing
                                }
                                |> http
                            )
                            (Discord.getGuildChannelsPayload auth partialGuild.id
                                |> http
                                |> Task.andThen
                                    (\channels ->
                                        List.map
                                            (\channel ->
                                                Discord.getMessagesPayload
                                                    auth
                                                    { channelId = channel.id
                                                    , limit = 100
                                                    , relativeTo = Discord.MostRecent
                                                    }
                                                    |> http
                                                    |> Task.onError (\_ -> Task.succeed [])
                                                    |> Task.map (Tuple.pair channel)
                                            )
                                            channels
                                            |> Task.sequence
                                    )
                            )
                            (case partialGuild.icon of
                                Just icon ->
                                    loadImage
                                        (Discord.guildIconUrl
                                            { size = Discord.DefaultImageSize
                                            , imageType = Discord.Choice1 Discord.Png
                                            }
                                            partialGuild.id
                                            icon
                                        )

                                Nothing ->
                                    Task.succeed Nothing
                            )
                            (Discord.listActiveThreadsPayload auth partialGuild.id
                                |> http
                                |> Task.andThen
                                    (\activeThreads ->
                                        List.map
                                            (\thread ->
                                                Discord.getMessagesPayload
                                                    auth
                                                    { channelId = thread.id
                                                    , limit = 100
                                                    , relativeTo = Discord.MostRecent
                                                    }
                                                    |> http
                                                    |> Task.onError (\_ -> Task.succeed [])
                                                    |> Task.map (Tuple.pair thread)
                                            )
                                            activeThreads.threads
                                            |> Task.sequence
                                    )
                            )
                    )
                    (if Env.isProduction then
                        guilds

                     else
                        List.filter
                            (\guild ->
                                Just guild.id == Maybe.map Discord.Id.fromUInt64 (UInt64.fromString "705745250815311942")
                            )
                            guilds
                    )
                    |> Task.sequence
                    |> Task.attempt (GotLinkedDiscordGuilds time discordUser.id)
                ]
            )

        Err error ->
            let
                _ =
                    Debug.log "GotCurrentUserGuilds" error
            in
            ( model, Command.none )


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
        { method = request.method
        , headers = []
        , url = FileStatus.domain ++ "/custom-request"
        , body =
            Json.Encode.object
                []
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
