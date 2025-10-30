module DiscordSync exposing
    ( addDiscordGuilds
    , discordUserWebsocketMsg
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
import Effect.Lamdera as Lamdera
import Effect.Process as Process
import Effect.Task as Task exposing (Task)
import Effect.Time as Time
import Effect.Websocket as Websocket
import Emoji exposing (Emoji)
import Env
import FileStatus
import GuildName
import Id exposing (AnyGuildOrDmId(..), ChannelId, ChannelMessageId, DiscordGuildOrDmId(..), GuildId, GuildOrDmId(..), Id, ThreadMessageId, ThreadRoute(..), ThreadRouteWithMaybeMessage(..), ThreadRouteWithMessage(..), UserId)
import Json.Encode
import List.Extra
import List.Nonempty exposing (Nonempty)
import LocalState exposing (BackendChannel, BackendGuild, ChannelStatus(..), DiscordBackendChannel, DiscordBackendGuild, DiscordMessageAlreadyExists(..))
import Message exposing (Message(..))
import NonemptyDict
import OneToOne exposing (OneToOne)
import PersonName
import RichText exposing (RichText)
import Route exposing (Route(..), ShowMembersTab(..), ThreadRouteWithFriends(..))
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import Types exposing (BackendModel, BackendMsg(..), DiscordUserData(..), LocalChange(..), LocalMsg(..), ServerChange(..), ToFrontend(..))
import UInt64
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
            channelMessagesAndLinks =
                messagesAndLinks messages

            linkedMessages : OneToOne (Discord.Id.Id Discord.Id.MessageId) (Id ChannelMessageId)
            linkedMessages =
                List.map Tuple.first channelMessagesAndLinks |> OneToOne.fromList
        in
        { name =
            case discordChannel.name of
                Included name ->
                    ChannelName.fromStringLossy name

                Missing ->
                    ChannelName.fromStringLossy "Missing"
        , messages = List.map Tuple.second channelMessagesAndLinks |> Array.fromList
        , status = ChannelActive
        , lastTypedAt = SeqDict.empty
        , linkedMessageIds = linkedMessages
        , threads =
            case SeqDict.get discordChannel.id threads of
                Just threads2 ->
                    List.filterMap
                        (\( threadChannel, threadMessages ) ->
                            case OneToOne.second (Discord.Id.toUInt64 threadChannel.id |> Discord.Id.fromUInt64) linkedMessages of
                                Just channelMessageIndex ->
                                    let
                                        threadMessagesAndLinks :
                                            List
                                                ( ( Discord.Id.Id Discord.Id.MessageId, Id ThreadMessageId )
                                                , Message ThreadMessageId (Discord.Id.Id Discord.Id.UserId)
                                                )
                                        threadMessagesAndLinks =
                                            messagesAndLinks threadMessages
                                    in
                                    ( channelMessageIndex
                                    , { messages = List.map Tuple.second threadMessagesAndLinks |> Array.fromList
                                      , lastTypedAt = SeqDict.empty
                                      , linkedMessageIds = List.map Tuple.first threadMessagesAndLinks |> OneToOne.fromList
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
        List
            ( ( Discord.Id.Id Discord.Id.MessageId, Id messageId )
            , Message messageId (Discord.Id.Id Discord.Id.UserId)
            )
messagesAndLinks messages =
    List.indexedMap
        (\index message ->
            ( ( message.id, Id.fromInt index )
            , UserTextMessage
                { createdAt = message.timestamp
                , createdBy = message.author.id
                , content = RichText.fromDiscord message.content
                , reactions = SeqDict.empty
                , editedAt = Nothing
                , repliedTo = Nothing
                , attachedFiles = SeqDict.empty
                }
            )
        )
        messages



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


addDiscordGuilds :
    SeqDict
        (Discord.Id.Id Discord.Id.GuildId)
        { guild : Discord.GatewayGuild
        , channels : List ( Discord.Channel, List Discord.Message )
        , icon : Maybe FileStatus.UploadResponse
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
                                    SeqDict.empty

                                --List.foldl
                                --    (\( channel, messages ) dict ->
                                --        case (Tuple.first channel).parentId of
                                --            Included (Just parentId) ->
                                --                SeqDict.update
                                --                    parentId
                                --                    (\maybe2 ->
                                --                        case maybe2 of
                                --                            Just list ->
                                --                                Just (( channel, messages ) :: list)
                                --
                                --                            Nothing ->
                                --                                Just [ ( channel, messages ) ]
                                --                    )
                                --                    dict
                                --
                                --            _ ->
                                --                dict
                                --    )
                                --    SeqDict.empty
                                --    data.channels
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
                    Debug.todo ""

                --let
                --    richText : Nonempty (RichText (Discord.Id.Id Discord.Id.UserId))
                --    richText =
                --        RichText.fromDiscord model.linkedDiscordUsers message.content
                --
                --    dmChannelId : DmChannelId
                --    dmChannelId =
                --        DmChannel.channelIdFromUserIds userId Broadcast.adminUserId
                --
                --    dmChannel : DmChannel
                --    dmChannel =
                --        Maybe.withDefault DmChannel.init (SeqDict.get dmChannelId model.dmChannels)
                --
                --    replyTo : Maybe (Id ChannelMessageId)
                --    replyTo =
                --        case message.referencedMessage of
                --            Discord.Referenced referenced ->
                --                OneToOne.second (DiscordMessageId referenced.id) dmChannel.linkedMessageIds
                --
                --            Discord.ReferenceDeleted ->
                --                Nothing
                --
                --            Discord.NoReference ->
                --                Nothing
                --in
                --( { model
                --    | dmChannels =
                --        SeqDict.insert
                --            dmChannelId
                --            (LocalState.createChannelMessageBackend
                --                (Just (DiscordMessageId message.id))
                --                (UserTextMessage
                --                    { createdAt = message.timestamp
                --                    , createdBy = userId
                --                    , content = richText
                --                    , reactions = SeqDict.empty
                --                    , editedAt = Nothing
                --                    , repliedTo =
                --                        case message.referencedMessage of
                --                            Discord.Referenced referenced ->
                --                                OneToOne.second
                --                                    (DiscordMessageId referenced.id)
                --                                    dmChannel.linkedMessageIds
                --
                --                            Discord.ReferenceDeleted ->
                --                                Nothing
                --
                --                            Discord.NoReference ->
                --                                Nothing
                --                    , attachedFiles = SeqDict.empty
                --                    }
                --                )
                --                dmChannel
                --            )
                --            model.dmChannels
                --    , discordDms = OneToOne.insert message.channelId dmChannelId model.discordDms
                --  }
                --, Command.batch
                --    [ Broadcast.toUser
                --        Nothing
                --        Nothing
                --        Broadcast.adminUserId
                --        (Server_DiscordDirectMessage message.timestamp userId richText replyTo
                --            |> ServerChange
                --        )
                --        model
                --    , case NonemptyDict.get userId model.users of
                --        Just user ->
                --            Broadcast.notification
                --                message.timestamp
                --                Broadcast.adminUserId
                --                user
                --                (RichText.toString (NonemptyDict.toSeqDict model.users) richText)
                --                (DmRoute userId (NoThreadWithFriends Nothing HideMembersTab) |> Just)
                --                model
                --
                --        Nothing ->
                --            Command.none
                --    ]
                --)
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
                                    SeqDict.remove ( message.author.id, channelId ) model.pendingDiscordCreateMessages
                              }
                            , Command.batch
                                [ case SeqDict.get ( message.author.id, channelId ) model.pendingDiscordCreateMessages of
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

                        Discord.UserOutMsg_UserEditedMessage messageUpdate ->
                            let
                                ( model3, cmd2 ) =
                                    handleDiscordEditMessage messageUpdate model2
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

                        Discord.UserOutMsg_InitialData readyData ->
                            let
                                ( model3, cmd2 ) =
                                    handleReadyData userData.auth readyData model2
                            in
                            ( model3, cmd2 :: cmds )

                        Discord.UserOutMsg_SupplementalInitialData readySupplementalData ->
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
        , List.map
            (\gatewayGuild ->
                Task.map2
                    (\channels maybeIcon ->
                        ( gatewayGuild.properties.id
                        , { guild = gatewayGuild
                          , channels = channels
                          , icon = maybeIcon
                          }
                        )
                    )
                    (List.map
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
             --(Discord.listActiveThreadsPayload auth partialGuild.id
             --    |> http
             --    |> Task.andThen
             --        (\activeThreads ->
             --            List.map
             --                (\thread ->
             --                    Discord.getMessagesPayload
             --                        auth
             --                        { channelId = thread.id
             --                        , limit = 100
             --                        , relativeTo = Discord.MostRecent
             --                        }
             --                        |> http
             --                        |> Task.onError (\_ -> Task.succeed [])
             --                        |> Task.map (Tuple.pair thread)
             --                )
             --                activeThreads.threads
             --                |> Task.sequence
             --        )
             --)
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
            |> Task.attempt (HandleReadyDataStep2 readyData.user.id)
        ]
    )


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
    , List.map
        (\guildMember ->
            Task.map
                (\maybeAvatar -> ( guildMember.user.id, maybeAvatar ))
                (case guildMember.user.avatar of
                    Just avatar ->
                        loadImage
                            (Discord.userAvatarUrl
                                { size = Discord.DefaultImageSize
                                , imageType = Discord.Choice1 Discord.Png
                                }
                                guildMember.user.id
                                avatar
                            )

                    Nothing ->
                        Task.succeed Nothing
                )
        )
        chunkData.members
        |> Task.sequence
        |> Task.attempt GotDiscordUserAvatars
    )


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
