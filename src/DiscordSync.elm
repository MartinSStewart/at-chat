module DiscordSync exposing
    ( addDiscordGuilds
    , addDiscordUsers
    , addReactionEmoji
    , botTokenToAuth
    , discordWebsocketMsg
    , gotCurrentUserGuilds
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
import List.Extra
import List.Nonempty exposing (Nonempty)
import LocalState exposing (BackendChannel, BackendGuild, ChannelStatus(..), DiscordBotToken(..))
import Message exposing (Message(..))
import NonemptyDict
import OneToOne
import PersonName
import RichText exposing (RichText)
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import Types exposing (BackendModel, BackendMsg(..), LocalMsg(..), ServerChange(..), ToFrontend)
import UInt64
import User exposing (BackendUser, EmailStatus(..))


getGuildFromDiscordId : Discord.Id.Id Discord.Id.GuildId -> BackendModel -> Maybe ( Id GuildId, BackendGuild )
getGuildFromDiscordId discordGuildId model =
    case OneToOne.second discordGuildId model.discordGuilds of
        Just guildId ->
            case SeqDict.get guildId model.guilds of
                Just guild ->
                    Just ( guildId, guild )

                Nothing ->
                    Nothing

        Nothing ->
            Nothing


discordGuildIdToGuild : Discord.Id.Id Discord.Id.GuildId -> BackendModel -> Maybe ( Id GuildId, BackendGuild )
discordGuildIdToGuild discordGuildId model =
    case OneToOne.second discordGuildId model.discordGuilds of
        Just guildId ->
            SeqDict.get guildId model.guilds |> Maybe.map (Tuple.pair guildId)

        Nothing ->
            Nothing


addReactionEmoji :
    Id GuildId
    -> BackendGuild
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
    -> BackendGuild
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
    if Just reaction.userId == model.discordBotId then
        ( model, Command.none )

    else
        case ( reaction.guildId, OneToOne.second reaction.userId model.discordUsers ) of
            ( Included discordGuildId, Just userId ) ->
                case discordGuildIdToGuild discordGuildId model of
                    Just ( guildId, guild ) ->
                        case OneToOne.second (DiscordChannelId reaction.channelId) guild.linkedChannelIds of
                            Just channelId ->
                                case SeqDict.get channelId guild.channels of
                                    Just channel ->
                                        case OneToOne.second (DiscordMessageId reaction.messageId) channel.linkedMessageIds of
                                            Just messageId ->
                                                (if isAdding then
                                                    addReactionEmoji

                                                 else
                                                    removeReactionEmoji
                                                )
                                                    guildId
                                                    guild
                                                    channelId
                                                    (NoThreadWithMessage messageId)
                                                    userId
                                                    (Emoji.fromDiscord reaction.emoji)
                                                    model
                                                    Command.none

                                            Nothing ->
                                                ( model, Command.none )

                                    Nothing ->
                                        ( model, Command.none )

                            -- If we don't find the channel ID among the guild channels then the Discord channel ID is actually a thread channel ID
                            Nothing ->
                                let
                                    maybeThread : Maybe ( Id ChannelId, BackendChannel, Id ChannelMessageId )
                                    maybeThread =
                                        List.Extra.findMap
                                            (\( channelId, channel ) ->
                                                case
                                                    OneToOne.second
                                                        (DiscordChannelId reaction.channelId)
                                                        channel.linkedThreadIds
                                                of
                                                    Just threadId ->
                                                        Just ( channelId, channel, threadId )

                                                    Nothing ->
                                                        Nothing
                                            )
                                            (SeqDict.toList guild.channels)
                                in
                                case maybeThread of
                                    Just ( channelId, channel, threadId ) ->
                                        case SeqDict.get threadId channel.threads of
                                            Just thread ->
                                                case OneToOne.second (DiscordMessageId reaction.messageId) thread.linkedMessageIds of
                                                    Just messageId ->
                                                        (if isAdding then
                                                            addReactionEmoji

                                                         else
                                                            removeReactionEmoji
                                                        )
                                                            guildId
                                                            guild
                                                            channelId
                                                            (ViewThreadWithMessage threadId messageId)
                                                            userId
                                                            (Emoji.fromDiscord reaction.emoji)
                                                            model
                                                            Command.none

                                                    Nothing ->
                                                        ( model, Command.none )

                                            Nothing ->
                                                ( model, Command.none )

                                    Nothing ->
                                        ( model, Command.none )

                    Nothing ->
                        ( model, Command.none )

            _ ->
                ( model, Command.none )


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
    if Just edit.author.id == model.discordBotId then
        ( model, Command.none )

    else
        case getGuildFromDiscordId edit.guildId model of
            Just ( guildId, guild ) ->
                case LocalState.linkedChannel (DiscordChannelId edit.channelId) guild of
                    Just ( channelId, channel ) ->
                        case
                            ( OneToOne.second (DiscordMessageId edit.id) channel.linkedMessageIds
                            , OneToOne.second edit.author.id model.discordUsers
                            )
                        of
                            ( Just messageIndex, Just userId ) ->
                                let
                                    richText : Nonempty RichText
                                    richText =
                                        RichText.fromDiscord model.discordUsers edit.content
                                in
                                case
                                    LocalState.editMessageHelper
                                        edit.timestamp
                                        userId
                                        richText
                                        SeqDict.empty
                                        (NoThreadWithMessage messageIndex)
                                        channel
                                of
                                    Ok channel2 ->
                                        ( { model
                                            | guilds =
                                                SeqDict.updateIfExists
                                                    guildId
                                                    (LocalState.updateChannel (\_ -> channel2) channelId)
                                                    model.guilds
                                          }
                                        , Broadcast.toGuild
                                            guildId
                                            (Server_SendEditMessage
                                                edit.timestamp
                                                userId
                                                (GuildOrDmId_Guild guildId channelId)
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
                                -- TODO handle edit thread messages
                                ( model, Command.none )

                    Nothing ->
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
    case getGuildFromDiscordId discordGuildId model of
        Just ( guildId, guild ) ->
            case LocalState.linkedChannel (DiscordChannelId discordChannelId) guild of
                Just ( channelId, channel ) ->
                    case OneToOne.second (DiscordMessageId messageId) channel.linkedMessageIds of
                        Just messageIndex ->
                            case DmChannel.getArray messageIndex channel.messages of
                                Just (UserTextMessage data) ->
                                    ( { model
                                        | guilds =
                                            SeqDict.insert
                                                guildId
                                                { guild
                                                    | channels =
                                                        SeqDict.insert
                                                            channelId
                                                            { channel
                                                                | messages =
                                                                    DmChannel.setArray
                                                                        messageIndex
                                                                        (DeletedMessage data.createdAt)
                                                                        channel.messages
                                                                , linkedMessageIds =
                                                                    OneToOne.removeFirst
                                                                        (DiscordMessageId messageId)
                                                                        channel.linkedMessageIds
                                                            }
                                                            guild.channels
                                                }
                                                model.guilds
                                      }
                                    , Broadcast.toGuild
                                        guildId
                                        (Server_DiscordDeleteMessage
                                            { guildId = guildId
                                            , channelId = channelId
                                            , messageIndex = messageIndex
                                            }
                                            |> ServerChange
                                        )
                                        model
                                    )

                                _ ->
                                    ( model, Command.none )

                        Nothing ->
                            ( model, Command.none )

                Nothing ->
                    ( model, Command.none )

        Nothing ->
            ( model, Command.none )


addDiscordUsers :
    Time.Posix
    -> SeqDict (Discord.Id.Id Discord.Id.UserId) Discord.GuildMember
    -> BackendModel
    -> BackendModel
addDiscordUsers time newUsers model =
    SeqDict.foldl
        (\discordUserId discordUser model2 ->
            case OneToOne.second discordUserId model2.discordUsers of
                Just _ ->
                    model2

                Nothing ->
                    let
                        userId : Id UserId
                        userId =
                            Id.nextId (NonemptyDict.toSeqDict model2.users)

                        user : BackendUser
                        user =
                            LocalState.createNewUser
                                time
                                (PersonName.fromStringLossy discordUser.user.username)
                                RegisteredFromDiscord
                                False
                    in
                    { model2
                        | discordUsers = OneToOne.insert discordUserId userId model2.discordUsers
                        , users = NonemptyDict.insert userId user model2.users
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
    if not (List.any (\a -> a.deny.viewChannel) discordChannel.permissionOverwrites) && isTextChannel then
        let
            channel : BackendChannel
            channel =
                { createdAt = time
                , createdBy = ownerId
                , name =
                    (case discordChannel.name of
                        Included name ->
                            name

                        Missing ->
                            "Channel " ++ String.fromInt index
                    )
                        |> ChannelName.fromStringLossy
                , messages = Array.empty
                , status = ChannelActive
                , lastTypedAt = SeqDict.empty
                , linkedMessageIds = OneToOne.empty
                , threads = SeqDict.empty
                , linkedThreadIds = OneToOne.empty
                }
                    |> addDiscordMessages NoThread messages model
        in
        ( Id.fromInt index
        , List.foldl
            (\( thread, threadMessages ) channel2 ->
                case
                    OneToOne.second
                        (Discord.Id.toUInt64 thread.id |> Discord.Id.fromUInt64 |> DiscordMessageId)
                        channel2.linkedMessageIds
                of
                    Just messageId ->
                        addDiscordMessages (ViewThread messageId) threadMessages model channel2

                    Nothing ->
                        channel2
            )
            channel
            (SeqDict.get discordChannel.id threads |> Maybe.withDefault [])
        )
            |> Just

    else
        Nothing


addDiscordMessages : ThreadRoute -> List Discord.Message -> BackendModel -> BackendChannel -> BackendChannel
addDiscordMessages threadRoute messages model channel =
    List.foldr
        (\message channel2 ->
            case ( message.type_, OneToOne.second message.author.id model.discordUsers ) of
                ( Discord.ThreadCreated, Nothing ) ->
                    channel2

                ( Discord.ThreadStarterMessage, Nothing ) ->
                    channel2

                ( _, Just userId ) ->
                    handleDiscordCreateGuildMessageHelper
                        message.id
                        message.channelId
                        (case threadRoute of
                            ViewThread threadId ->
                                ViewThreadWithMaybeMessage
                                    threadId
                                    (discordReplyTo message channel2 |> Maybe.map Id.changeType)

                            NoThread ->
                                NoThreadWithMaybeMessage (discordReplyTo message channel2)
                        )
                        userId
                        (RichText.fromDiscord model.discordUsers message.content)
                        message
                        channel2

                _ ->
                    channel2
        )
        channel
        messages


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
    SeqDict.foldl
        (\discordGuildId data model2 ->
            case OneToOne.second discordGuildId model2.discordGuilds of
                Just _ ->
                    model2

                Nothing ->
                    let
                        ownerId : Id UserId
                        ownerId =
                            case OneToOne.second data.guild.ownerId model2.discordUsers of
                                Just ownerId2 ->
                                    ownerId2

                                Nothing ->
                                    Broadcast.adminUserId

                        threads : SeqDict (Discord.Id.Id Discord.Id.ChannelId) (List ( Discord.Channel, List Discord.Message ))
                        threads =
                            List.foldl
                                (\a dict ->
                                    case (Tuple.first a).parentId of
                                        Included (Just parentId) ->
                                            SeqDict.update
                                                parentId
                                                (\maybe ->
                                                    case maybe of
                                                        Just list ->
                                                            Just (a :: list)

                                                        Nothing ->
                                                            Just [ a ]
                                                )
                                                dict

                                        _ ->
                                            dict
                                )
                                SeqDict.empty
                                data.threads

                        members : SeqDict (Id UserId) { joinedAt : Time.Posix }
                        members =
                            List.filterMap
                                (\guildMember ->
                                    case OneToOne.second guildMember.user.id model2.discordUsers of
                                        Just userId ->
                                            if userId == ownerId then
                                                Nothing

                                            else
                                                Just ( userId, { joinedAt = time } )

                                        Nothing ->
                                            Nothing
                                )
                                data.members
                                |> SeqDict.fromList

                        newGuild : BackendGuild
                        newGuild =
                            { createdAt = time
                            , createdBy = ownerId
                            , name = GuildName.fromStringLossy data.guild.name
                            , icon = Maybe.map .fileHash data.icon
                            , channels = SeqDict.empty
                            , linkedChannelIds = OneToOne.empty
                            , members = members
                            , owner = ownerId
                            , invites = SeqDict.empty
                            }

                        newGuild2 =
                            List.sortBy
                                (\( channel, _ ) ->
                                    case channel.position of
                                        Included position ->
                                            position

                                        Missing ->
                                            9999
                                )
                                data.channels
                                |> List.indexedMap Tuple.pair
                                |> List.foldl
                                    (\( index, ( discordChannel, messages ) ) guild2 ->
                                        case addDiscordChannel time ownerId model2 threads index discordChannel messages of
                                            Just ( channelId, channel ) ->
                                                { newGuild
                                                    | channels =
                                                        SeqDict.insert
                                                            channelId
                                                            channel
                                                            guild2.channels
                                                    , linkedChannelIds =
                                                        OneToOne.insert
                                                            (DiscordChannelId discordChannel.id)
                                                            channelId
                                                            guild2.linkedChannelIds
                                                }

                                            Nothing ->
                                                guild2
                                    )
                                    newGuild

                        newGuild3 : BackendGuild
                        newGuild3 =
                            LocalState.addMember time Broadcast.adminUserId newGuild2
                                |> Result.withDefault newGuild2

                        guildId : Id GuildId
                        guildId =
                            Id.nextId model2.guilds
                    in
                    { model2
                        | discordGuilds =
                            OneToOne.insert discordGuildId guildId model2.discordGuilds
                        , guilds = SeqDict.insert guildId newGuild3 model2.guilds
                        , users =
                            SeqDict.foldl
                                (\userId _ users ->
                                    NonemptyDict.updateIfExists
                                        userId
                                        (\user ->
                                            SeqDict.foldl
                                                (\channelId channel user2 ->
                                                    { user2
                                                        | lastViewed =
                                                            SeqDict.insert
                                                                (GuildOrDmId_Guild guildId channelId)
                                                                (DmChannel.latestMessageId channel)
                                                                user2.lastViewed
                                                        , lastViewedThreads =
                                                            SeqDict.foldl
                                                                (\threadId thread lastViewedThreads ->
                                                                    SeqDict.insert
                                                                        ( GuildOrDmId_Guild guildId channelId, threadId )
                                                                        (DmChannel.latestThreadMessageId thread)
                                                                        lastViewedThreads
                                                                )
                                                                user2.lastViewedThreads
                                                                channel.threads
                                                    }
                                                )
                                                user
                                                newGuild3.channels
                                        )
                                        users
                                )
                                model2.users
                                members
                    }
        )
        model
        guilds


handleDiscordCreateMessage :
    Discord.Message
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleDiscordCreateMessage message model =
    case ( Just message.author.id == model.discordBotId, message.type_ ) of
        ( True, _ ) ->
            ( model, Command.none )

        ( _, Discord.ThreadCreated ) ->
            ( model, Command.none )

        ( _, Discord.ThreadStarterMessage ) ->
            ( model, Command.none )

        _ ->
            case ( OneToOne.second message.author.id model.discordUsers, message.guildId ) of
                ( Just userId, Missing ) ->
                    let
                        richText : Nonempty RichText
                        richText =
                            RichText.fromDiscord model.discordUsers message.content

                        dmChannelId : DmChannelId
                        dmChannelId =
                            DmChannel.channelIdFromUserIds userId Broadcast.adminUserId

                        dmChannel : DmChannel
                        dmChannel =
                            Maybe.withDefault DmChannel.init (SeqDict.get dmChannelId model.dmChannels)

                        replyTo : Maybe (Id ChannelMessageId)
                        replyTo =
                            case message.referencedMessage of
                                Discord.Referenced referenced ->
                                    OneToOne.second (DiscordMessageId referenced.id) dmChannel.linkedMessageIds

                                Discord.ReferenceDeleted ->
                                    Nothing

                                Discord.NoReference ->
                                    Nothing
                    in
                    ( { model
                        | dmChannels =
                            SeqDict.insert
                                dmChannelId
                                (LocalState.createChannelMessageBackend
                                    (Just (DiscordMessageId message.id))
                                    (UserTextMessage
                                        { createdAt = message.timestamp
                                        , createdBy = userId
                                        , content = richText
                                        , reactions = SeqDict.empty
                                        , editedAt = Nothing
                                        , repliedTo =
                                            case message.referencedMessage of
                                                Discord.Referenced referenced ->
                                                    OneToOne.second
                                                        (DiscordMessageId referenced.id)
                                                        dmChannel.linkedMessageIds

                                                Discord.ReferenceDeleted ->
                                                    Nothing

                                                Discord.NoReference ->
                                                    Nothing
                                        , attachedFiles = SeqDict.empty
                                        }
                                    )
                                    dmChannel
                                )
                                model.dmChannels
                        , discordDms = OneToOne.insert message.channelId dmChannelId model.discordDms
                      }
                    , Command.batch
                        [ Broadcast.toUser
                            Nothing
                            Nothing
                            Broadcast.adminUserId
                            (Server_DiscordDirectMessage message.timestamp userId richText replyTo
                                |> ServerChange
                            )
                            model
                        , case NonemptyDict.get userId model.users of
                            Just user ->
                                Broadcast.notification
                                    message.timestamp
                                    Broadcast.adminUserId
                                    user
                                    (RichText.toString (NonemptyDict.toSeqDict model.users) richText)
                                    model

                            Nothing ->
                                Command.none
                        ]
                    )

                ( Just userId, Included discordGuildId ) ->
                    handleDiscordCreateGuildMessage userId discordGuildId message model

                _ ->
                    let
                        _ =
                            Debug.log "user id not found for message" message
                    in
                    ( model, Command.none )


handleDiscordCreateGuildMessage :
    Id UserId
    -> Discord.Id.Id Discord.Id.GuildId
    -> Discord.Message
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleDiscordCreateGuildMessage userId discordGuildId message model =
    let
        richText : Nonempty RichText
        richText =
            RichText.fromDiscord model.discordUsers message.content

        maybeData : Maybe { guildId : Id GuildId, guild : BackendGuild, channelId : Id ChannelId, channel : BackendChannel, threadRoute : ThreadRouteWithMaybeMessage }
        maybeData =
            case discordGuildIdToGuild discordGuildId model of
                Just ( guildId, guild ) ->
                    case LocalState.linkedChannel (DiscordChannelId message.channelId) guild of
                        Just ( channelId, channel ) ->
                            Just
                                { guildId = guildId
                                , guild = guild
                                , channelId = channelId
                                , channel = channel
                                , threadRoute = NoThreadWithMaybeMessage (discordReplyTo message channel)
                                }

                        Nothing ->
                            List.Extra.findMap
                                (\( channelId, channel ) ->
                                    case
                                        OneToOne.second
                                            (Discord.Id.toUInt64 message.channelId
                                                |> Discord.Id.fromUInt64
                                                |> DiscordMessageId
                                            )
                                            channel.linkedMessageIds
                                    of
                                        Just messageIndex ->
                                            { guildId = guildId
                                            , guild = guild
                                            , channelId = channelId
                                            , channel = channel
                                            , threadRoute =
                                                ViewThreadWithMaybeMessage
                                                    messageIndex
                                                    (discordReplyTo message channel |> Maybe.map Id.changeType)
                                            }
                                                |> Just

                                        _ ->
                                            Nothing
                                )
                                (SeqDict.toList guild.channels)

                Nothing ->
                    Nothing
    in
    case maybeData of
        Just { guildId, guild, channelId, channel, threadRoute } ->
            let
                threadRouteNoReply : ThreadRoute
                threadRouteNoReply =
                    case threadRoute of
                        ViewThreadWithMaybeMessage threadId _ ->
                            ViewThread threadId

                        NoThreadWithMaybeMessage _ ->
                            NoThread

                usersMentioned : SeqSet (Id UserId)
                usersMentioned =
                    LocalState.usersMentionedOrRepliedToBackend
                        threadRoute
                        richText
                        (guild.owner :: SeqDict.keys guild.members)
                        channel

                guildOrDmId =
                    GuildOrDmId_Guild guildId channelId
            in
            ( { model
                | guilds =
                    SeqDict.insert
                        guildId
                        { guild
                            | channels =
                                SeqDict.insert
                                    channelId
                                    (handleDiscordCreateGuildMessageHelper
                                        message.id
                                        message.channelId
                                        threadRoute
                                        userId
                                        richText
                                        message
                                        channel
                                    )
                                    guild.channels
                        }
                        model.guilds
                , users =
                    SeqSet.foldl
                        (\userId2 users ->
                            let
                                isViewing =
                                    Broadcast.userGetAllSessions userId2 model
                                        |> List.any
                                            (\( _, userSession ) ->
                                                userSession.currentlyViewing == Just ( guildOrDmId, threadRouteNoReply )
                                            )
                            in
                            if isViewing then
                                users

                            else
                                NonemptyDict.updateIfExists
                                    userId2
                                    (User.addDirectMention guildId channelId threadRouteNoReply)
                                    users
                        )
                        model.users
                        usersMentioned
              }
            , Command.batch
                [ Broadcast.toGuild
                    guildId
                    (Server_SendMessage userId message.timestamp guildOrDmId richText threadRoute SeqDict.empty
                        |> ServerChange
                    )
                    model
                , Broadcast.messageNotification
                    usersMentioned
                    message.timestamp
                    userId
                    guildOrDmId
                    threadRouteNoReply
                    richText
                    (guild.owner :: SeqDict.keys guild.members)
                    model
                ]
            )

        _ ->
            ( model, Command.none )


discordReplyTo : Discord.Message -> BackendChannel -> Maybe (Id ChannelMessageId)
discordReplyTo message channel =
    case message.referencedMessage of
        Discord.Referenced referenced ->
            OneToOne.second (DiscordMessageId referenced.id) channel.linkedMessageIds

        Discord.ReferenceDeleted ->
            Nothing

        Discord.NoReference ->
            Nothing


handleDiscordCreateGuildMessageHelper :
    Discord.Id.Id Discord.Id.MessageId
    -> Discord.Id.Id Discord.Id.ChannelId
    -> ThreadRouteWithMaybeMessage
    -> Id UserId
    -> Nonempty RichText
    -> Discord.Message
    -> BackendChannel
    -> BackendChannel
handleDiscordCreateGuildMessageHelper discordMessageId discordChannelId threadRouteWithMaybeReplyTo userId richText message channel =
    case threadRouteWithMaybeReplyTo of
        ViewThreadWithMaybeMessage threadId maybeReplyTo ->
            LocalState.createThreadMessageBackend
                (Just ( DiscordMessageId discordMessageId, DiscordChannelId discordChannelId ))
                threadId
                (UserTextMessage
                    { createdAt = message.timestamp
                    , createdBy = userId
                    , content = richText
                    , reactions = SeqDict.empty
                    , editedAt = Nothing
                    , repliedTo = maybeReplyTo
                    , attachedFiles = SeqDict.empty
                    }
                )
                channel

        NoThreadWithMaybeMessage maybeReplyTo ->
            LocalState.createChannelMessageBackend
                (Just (DiscordMessageId discordMessageId))
                (UserTextMessage
                    { createdAt = message.timestamp
                    , createdBy = userId
                    , content = richText
                    , reactions = SeqDict.empty
                    , editedAt = Nothing
                    , repliedTo = maybeReplyTo
                    , attachedFiles = SeqDict.empty
                    }
                )
                channel


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


botTokenToAuth : DiscordBotToken -> Discord.Authentication
botTokenToAuth (DiscordBotToken botToken) =
    Discord.botToken botToken


discordWebsocketMsg : Discord.Msg -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
discordWebsocketMsg discordMsg model =
    case model.botToken of
        Just botToken ->
            let
                ( discordModel2, outMsgs ) =
                    Discord.update (botTokenToAuth botToken) discordGatewayIntents discordMsg model.discordModel
            in
            List.foldl
                (\outMsg ( model2, cmds ) ->
                    case outMsg of
                        Discord.CloseAndReopenHandle connection ->
                            ( model2
                            , Task.perform (\() -> WebsocketClosedByBackend True) (Websocket.close connection)
                                :: cmds
                            )

                        Discord.OpenHandle ->
                            ( model2
                            , Websocket.createHandle WebsocketCreatedHandle Discord.websocketGatewayUrl
                                :: cmds
                            )

                        Discord.SendWebsocketData connection data ->
                            ( model2
                            , Task.attempt WebsocketSentData (Websocket.sendString connection data)
                                :: cmds
                            )

                        Discord.SendWebsocketDataWithDelay connection duration data ->
                            ( model2
                            , (Process.sleep duration
                                |> Task.andThen (\() -> Websocket.sendString connection data)
                                |> Task.attempt WebsocketSentData
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
                ( { model | discordModel = discordModel2 }, [] )
                outMsgs
                |> Tuple.mapSecond Command.batch

        Nothing ->
            ( model, Command.none )


gotCurrentUserGuilds :
    Time.Posix
    -> DiscordBotToken
    -> Result error ( Discord.User, List Discord.PartialGuild )
    -> BackendModel
    -> ( BackendModel, Command restriction toMsg BackendMsg )
gotCurrentUserGuilds time botToken result model =
    case result of
        Ok ( botUser, guilds ) ->
            let
                botToken2 =
                    botTokenToAuth botToken
            in
            ( { model
                | discordBotId = Just botUser.id
                , discordUsers = OneToOne.insert botUser.id Broadcast.adminUserId model.discordUsers
              }
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
                        (Discord.getGuild botToken2 partialGuild.id)
                        (Discord.listGuildMembers
                            botToken2
                            { guildId = partialGuild.id
                            , limit = 1000
                            , after = Discord.Missing
                            }
                        )
                        (Discord.getGuildChannels botToken2 partialGuild.id
                            |> Task.andThen
                                (\channels ->
                                    List.map
                                        (\channel ->
                                            Discord.getMessages
                                                botToken2
                                                { channelId = channel.id
                                                , limit = 100
                                                , relativeTo = Discord.MostRecent
                                                }
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
                        (Discord.listActiveThreads botToken2 partialGuild.id
                            |> Task.andThen
                                (\activeThreads ->
                                    List.map
                                        (\thread ->
                                            Discord.getMessages
                                                botToken2
                                                { channelId = thread.id
                                                , limit = 100
                                                , relativeTo = Discord.MostRecent
                                                }
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
                |> Task.attempt (GotDiscordGuilds time botUser.id)
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
