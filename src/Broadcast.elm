module Broadcast exposing
    ( PushNotification
    , adminUserId
    , broadcastDm
    , discordDmNotification
    , discordGuildMessageNotification
    , getSessionFromSessionIdHash
    , getUserFromSessionId
    , messageNotification
    , notification
    , pushNotification
    , pushNotificationCodec
    , toAdmins
    , toDiscordDmChannel
    , toDiscordDmChannelExcludingOne
    , toDiscordGuild
    , toDiscordGuildExcludingOne
    , toDmChannel
    , toDmChannelExcludingOne
    , toEveryone
    , toEveryoneWhoCanSeeUser
    , toEveryoneWhoCanSeeUserIncludingUser
    , toGuild
    , toGuildExcludingOne
    , toOtherAdmins
    , toSession
    , toUser
    , userGetAllSessions
    )

import Codec exposing (Codec)
import Discord
import DiscordUserData exposing (DiscordUserData(..))
import Duration
import Effect.Command as Command exposing (BackendOnly, Command)
import Effect.Http as Http
import Effect.Lamdera as Lamdera exposing (ClientId, SessionId)
import Effect.Time as Time
import Env
import FileStatus exposing (FileData, FileHash, FileId)
import Id exposing (AnyGuildOrDmId(..), ChannelId, DiscordGuildOrDmId(..), GuildId, GuildOrDmId(..), Id, ThreadRoute(..), ThreadRouteWithMaybeMessage(..), UserId)
import List.Nonempty exposing (Nonempty)
import Local exposing (ChangeId)
import LocalState exposing (PrivateVapidKey(..))
import NonemptyDict
import NonemptySet
import PersonName
import RichText exposing (RichText)
import Route exposing (ChannelRoute(..), DiscordChannelRoute(..), Route(..), ShowMembersTab(..), ThreadRouteWithFriends(..))
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import SessionIdHash exposing (SessionIdHash)
import Types exposing (BackendModel, BackendMsg(..), LocalChange(..), LocalMsg(..), ServerChange(..), ToFrontend(..))
import Url
import User exposing (BackendUser)
import UserSession exposing (NotificationMode(..), PushSubscription(..), SubscribeData, UserSession)


adminUserId : Id UserId
adminUserId =
    Id.fromInt 0


toGuildExcludingOne : ClientId -> Id GuildId -> LocalMsg -> BackendModel -> Command BackendOnly ToFrontend msg
toGuildExcludingOne clientToSkip guildId msg model =
    List.filterMap
        (\clientId ->
            if clientToSkip == clientId then
                Nothing

            else
                ChangeBroadcast msg
                    |> Lamdera.sendToFrontend clientId
                    |> Just
        )
        (guildConnections guildId model)
        |> Command.batch


toDiscordGuildExcludingOne : ClientId -> Discord.Id Discord.GuildId -> LocalMsg -> BackendModel -> Command BackendOnly ToFrontend msg
toDiscordGuildExcludingOne clientToSkip guildId msg model =
    List.filterMap
        (\clientId ->
            if clientToSkip == clientId then
                Nothing

            else
                ChangeBroadcast msg
                    |> Lamdera.sendToFrontend clientId
                    |> Just
        )
        (discordGuildConnections guildId model)
        |> Command.batch


guildConnections : Id GuildId -> BackendModel -> List ClientId
guildConnections guildId model =
    case SeqDict.get guildId model.guilds of
        Just guild ->
            List.concatMap
                (\member ->
                    List.concatMap
                        (\( _, clientIds ) -> List.Nonempty.toList clientIds)
                        (userConnections member model)
                )
                (guild.owner :: SeqDict.keys guild.members)

        Nothing ->
            []


discordGuildConnections : Discord.Id Discord.GuildId -> BackendModel -> List ClientId
discordGuildConnections guildId model =
    case SeqDict.get guildId model.discordGuilds of
        Just guild ->
            List.concatMap
                (\member ->
                    case SeqDict.get member model.discordUsers of
                        Just (FullData discordUser) ->
                            List.concatMap
                                (\( _, clientIds ) -> List.Nonempty.toList clientIds)
                                (userConnections discordUser.linkedTo model)

                        _ ->
                            []
                )
                (guild.owner :: SeqDict.keys guild.members)

        Nothing ->
            []


discordDmConnections : Discord.Id Discord.PrivateChannelId -> BackendModel -> List ClientId
discordDmConnections channelId model =
    case SeqDict.get channelId model.discordDmChannels of
        Just channel ->
            NonemptyDict.keys channel.members
                |> List.Nonempty.toList
                |> List.concatMap
                    (\member ->
                        case SeqDict.get member model.discordUsers of
                            Just (FullData discordUser) ->
                                List.concatMap
                                    (\( _, clientIds ) -> List.Nonempty.toList clientIds)
                                    (userConnections discordUser.linkedTo model)

                            _ ->
                                []
                    )

        Nothing ->
            []


toDiscordDmChannelExcludingOne : ClientId -> Discord.Id Discord.PrivateChannelId -> LocalMsg -> BackendModel -> Command BackendOnly ToFrontend msg
toDiscordDmChannelExcludingOne clientToSkip channelId msg model =
    List.filterMap
        (\clientId ->
            if clientToSkip == clientId then
                Nothing

            else
                ChangeBroadcast msg
                    |> Lamdera.sendToFrontend clientId
                    |> Just
        )
        (discordDmConnections channelId model)
        |> Command.batch


toDiscordDmChannel : Discord.Id Discord.PrivateChannelId -> LocalMsg -> BackendModel -> Command BackendOnly ToFrontend msg
toDiscordDmChannel channelId msg model =
    List.map
        (\clientId -> ChangeBroadcast msg |> Lamdera.sendToFrontend clientId)
        (discordDmConnections channelId model)
        |> Command.batch


toGuild : Id GuildId -> LocalMsg -> BackendModel -> Command BackendOnly ToFrontend msg
toGuild guildId msg model =
    List.map
        (\clientId -> ChangeBroadcast msg |> Lamdera.sendToFrontend clientId)
        (guildConnections guildId model)
        |> Command.batch


toDiscordGuild : Discord.Id Discord.GuildId -> LocalMsg -> BackendModel -> Command BackendOnly ToFrontend msg
toDiscordGuild guildId msg model =
    List.map
        (\otherClientId -> ChangeBroadcast msg |> Lamdera.sendToFrontend otherClientId)
        (discordGuildConnections guildId model)
        |> Command.batch


toSession : SessionId -> ServerChange -> BackendModel -> Command BackendOnly ToFrontend msg
toSession sessionId msg model =
    let
        toFrontend : ToFrontend
        toFrontend =
            ServerChange msg |> ChangeBroadcast
    in
    case SeqDict.get sessionId model.connections of
        Just connections ->
            NonemptyDict.keys connections
                |> List.Nonempty.toList
                |> List.map (\clientId -> Lamdera.sendToFrontend clientId toFrontend)
                |> Command.batch

        Nothing ->
            Command.none


toEveryone : ClientId -> ServerChange -> BackendModel -> Command BackendOnly ToFrontend msg
toEveryone clientToSkip serverChange model =
    let
        toFrontend : ToFrontend
        toFrontend =
            ChangeBroadcast (ServerChange serverChange)
    in
    SeqDict.filterMap
        (\sessionId _ ->
            case SeqDict.get sessionId model.connections of
                Just clientIds ->
                    List.filterMap
                        (\( otherClientId, _ ) ->
                            if clientToSkip == otherClientId then
                                Nothing

                            else
                                Lamdera.sendToFrontend otherClientId toFrontend |> Just
                        )
                        (NonemptyDict.toList clientIds)
                        |> Command.batch
                        |> Just

                Nothing ->
                    Nothing
        )
        model.sessions
        |> SeqDict.values
        |> Command.batch


toUser : Maybe ClientId -> Maybe SessionId -> Id UserId -> LocalMsg -> BackendModel -> Command BackendOnly ToFrontend msg
toUser clientToSkip sessionToSkip userId msg model =
    SeqDict.filterMap
        (\sessionId otherUserSession ->
            if sessionToSkip /= Just sessionId && userId == otherUserSession.userId then
                case SeqDict.get sessionId model.connections of
                    Just clientIds ->
                        List.filterMap
                            (\( otherClientId, _ ) ->
                                if clientToSkip == Just otherClientId then
                                    Nothing

                                else
                                    ChangeBroadcast msg
                                        |> Lamdera.sendToFrontend otherClientId
                                        |> Just
                            )
                            (NonemptyDict.toList clientIds)
                            |> Command.batch
                            |> Just

                    Nothing ->
                        Nothing

            else
                Nothing
        )
        model.sessions
        |> SeqDict.values
        |> Command.batch


toAdmins : BackendModel -> LocalMsg -> Command BackendOnly ToFrontend msg
toAdmins model broadcastMsg =
    List.concatMap
        (\( sessionId, clientIds ) ->
            case getUserFromSessionId sessionId model of
                Just ( _, user ) ->
                    if user.isAdmin then
                        NonemptyDict.toList clientIds
                            |> List.map
                                (\( clientId2, _ ) ->
                                    ChangeBroadcast broadcastMsg
                                        |> Lamdera.sendToFrontend clientId2
                                )

                    else
                        []

                Nothing ->
                    []
        )
        (SeqDict.toList model.connections)
        |> Command.batch


toOtherAdmins : ClientId -> BackendModel -> LocalMsg -> Command BackendOnly ToFrontend msg
toOtherAdmins currentClientId model broadcastMsg =
    List.concatMap
        (\( sessionId, clientIds ) ->
            case getUserFromSessionId sessionId model of
                Just ( _, user ) ->
                    if user.isAdmin then
                        NonemptyDict.toList clientIds
                            |> List.filterMap
                                (\( clientId2, _ ) ->
                                    if clientId2 == currentClientId then
                                        Nothing

                                    else
                                        ChangeBroadcast broadcastMsg
                                            |> Lamdera.sendToFrontend clientId2
                                            |> Just
                                )

                    else
                        []

                Nothing ->
                    []
        )
        (SeqDict.toList model.connections)
        |> Command.batch


getUserFromSessionId : SessionId -> BackendModel -> Maybe ( UserSession, BackendUser )
getUserFromSessionId sessionId model =
    SeqDict.get sessionId model.sessions
        |> Maybe.andThen (\session -> NonemptyDict.get session.userId model.users |> Maybe.map (Tuple.pair session))


userConnections : Id UserId -> BackendModel -> List ( UserSession, Nonempty ClientId )
userConnections userId model =
    SeqDict.foldl
        (\sessionId session list ->
            if session.userId == userId then
                case SeqDict.get sessionId model.connections of
                    Just connection ->
                        ( session, NonemptyDict.keys connection ) :: list

                    Nothing ->
                        list

            else
                list
        )
        []
        model.sessions


getSessionFromSessionIdHash : SessionIdHash -> BackendModel -> Maybe ( SessionId, UserSession )
getSessionFromSessionIdHash sessionIdHash model =
    SeqDict.foldl
        (\sessionId session state ->
            case state of
                Just _ ->
                    state

                Nothing ->
                    if session.sessionIdHash == sessionIdHash then
                        Just ( sessionId, session )

                    else
                        Nothing
        )
        Nothing
        model.sessions


messageNotification :
    SeqSet (Id UserId)
    -> Time.Posix
    -> Id UserId
    -> Id GuildId
    -> Id ChannelId
    -> ThreadRoute
    -> Nonempty (RichText (Id UserId))
    -> List (Id UserId)
    -> BackendModel
    -> Command restriction toMsg BackendMsg
messageNotification usersMentioned time sender guildId channelId threadRoute content members model =
    let
        plainText : String
        plainText =
            RichText.toString (NonemptyDict.toSeqDict model.users) content

        alwaysNotify : SeqSet (Id UserId)
        alwaysNotify =
            List.filter
                (\userId ->
                    case NonemptyDict.get userId model.users of
                        Just user ->
                            SeqSet.member guildId user.notifyOnAllMessages

                        Nothing ->
                            False
                )
                members
                |> SeqSet.fromList

        threadRouteWithFriends : ThreadRouteWithFriends
        threadRouteWithFriends =
            case threadRoute of
                NoThread ->
                    NoThreadWithFriends Nothing HideMembersTab

                ViewThread threadId ->
                    ViewThreadWithFriends threadId Nothing HideMembersTab
    in
    SeqSet.union alwaysNotify usersMentioned
        |> SeqSet.remove sender
        |> SeqSet.foldl
            (\userId2 cmds ->
                let
                    isViewing =
                        List.any
                            (\( _, userSession ) ->
                                case userSession.currentlyViewing of
                                    Just ( GuildOrDmId (GuildOrDmId_Guild viewingGuildId viewingChannelId), viewingThreadRoute ) ->
                                        viewingGuildId == guildId && viewingChannelId == channelId && viewingThreadRoute == threadRoute

                                    _ ->
                                        False
                            )
                            (userGetAllSessions userId2 model)
                in
                if isViewing then
                    cmds

                else
                    case NonemptyDict.get sender model.users of
                        Just user2 ->
                            notification
                                time
                                userId2
                                (PersonName.toString user2.name)
                                user2.icon
                                plainText
                                (GuildRoute guildId (ChannelRoute channelId threadRouteWithFriends) |> Just)
                                model
                                :: cmds

                        Nothing ->
                            cmds
            )
            []
        |> Command.batch


discordGuildMessageNotification :
    SeqSet (Discord.Id Discord.UserId)
    -> Time.Posix
    -> Discord.Id Discord.UserId
    -> Discord.Id Discord.GuildId
    -> Discord.Id Discord.ChannelId
    -> ThreadRoute
    -> Nonempty (RichText (Discord.Id Discord.UserId))
    -> List (Discord.Id Discord.UserId)
    -> BackendModel
    -> Command restriction toMsg BackendMsg
discordGuildMessageNotification usersMentioned time sender guildId channelId threadRoute content members model =
    let
        alwaysNotify : SeqSet (Discord.Id Discord.UserId)
        alwaysNotify =
            List.filter
                (\userId ->
                    case SeqDict.get userId model.discordUsers of
                        Just (FullData discordUser) ->
                            case NonemptyDict.get discordUser.linkedTo model.users of
                                Just user ->
                                    SeqSet.member guildId user.discordNotifyOnAllMessages

                                Nothing ->
                                    False

                        _ ->
                            False
                )
                members
                |> SeqSet.fromList

        threadRouteWithFriends : ThreadRouteWithFriends
        threadRouteWithFriends =
            case threadRoute of
                NoThread ->
                    NoThreadWithFriends Nothing HideMembersTab

                ViewThread threadId ->
                    ViewThreadWithFriends threadId Nothing HideMembersTab
    in
    SeqSet.union alwaysNotify usersMentioned
        |> SeqSet.remove sender
        |> SeqSet.foldl
            (\userId2 cmds ->
                case SeqDict.get userId2 model.discordUsers of
                    Just (FullData discordUser) ->
                        let
                            isViewing : Bool
                            isViewing =
                                List.any
                                    (\( _, userSession ) ->
                                        case userSession.currentlyViewing of
                                            Just ( DiscordGuildOrDmId (DiscordGuildOrDmId_Guild _ viewingGuildId viewingChannelId), viewingThreadRoute ) ->
                                                viewingGuildId == guildId && viewingChannelId == channelId && viewingThreadRoute == threadRoute

                                            _ ->
                                                False
                                    )
                                    (userGetAllSessions discordUser.linkedTo model)
                        in
                        if isViewing then
                            cmds

                        else
                            case NonemptyDict.get discordUser.linkedTo model.users of
                                Just user2 ->
                                    notification
                                        time
                                        discordUser.linkedTo
                                        (PersonName.toString user2.name)
                                        user2.icon
                                        (RichText.toStringWithGetter DiscordUserData.username model.discordUsers content)
                                        (DiscordGuildRoute
                                            { currentDiscordUserId = userId2
                                            , guildId = guildId
                                            , channelRoute = DiscordChannel_ChannelRoute channelId threadRouteWithFriends
                                            }
                                            |> Just
                                        )
                                        model
                                        :: cmds

                                Nothing ->
                                    cmds

                    _ ->
                        cmds
            )
            []
        |> Command.batch


userGetAllSessions : Id UserId -> BackendModel -> List ( SessionId, UserSession )
userGetAllSessions userId model =
    SeqDict.toList model.sessions
        |> List.filter (\( _, session ) -> session.userId == userId)


notification :
    Time.Posix
    -> Id UserId
    -> String
    -> Maybe FileHash
    -> String
    -> Maybe Route
    -> BackendModel
    -> Command restriction toMsg BackendMsg
notification time userToNotify senderName senderIcon text navigateTo model =
    SeqDict.foldl
        (\sessionId session cmds ->
            if session.userId == userToNotify then
                case ( session.notificationMode, session.pushSubscription ) of
                    ( PushNotifications, Subscribed pushSubscription ) ->
                        pushNotification
                            sessionId
                            session.userId
                            time
                            senderName
                            text
                            (case senderIcon of
                                Just icon ->
                                    FileStatus.fileUrl FileStatus.pngContent icon

                                Nothing ->
                                    Env.domain ++ "/at-logo-no-background.png"
                            )
                            navigateTo
                            pushSubscription
                            model
                            :: cmds

                    _ ->
                        cmds

            else
                cmds
        )
        []
        model.sessions
        |> Command.batch


isViewingDiscordDm : Discord.Id Discord.PrivateChannelId -> Id UserId -> BackendModel -> Bool
isViewingDiscordDm channelId userId2 model =
    List.any
        (\( _, userSession ) ->
            case userSession.currentlyViewing of
                Just ( DiscordGuildOrDmId (DiscordGuildOrDmId_Dm data), _ ) ->
                    data.channelId == channelId

                _ ->
                    False
        )
        (userGetAllSessions userId2 model)


discordDmNotification :
    Time.Posix
    -> Discord.Id Discord.PrivateChannelId
    -> Discord.Id Discord.UserId
    -> String
    -> Maybe FileHash
    -> String
    -> BackendModel
    -> Command restriction toMsg BackendMsg
discordDmNotification time channelId senderId senderName senderIcon text model =
    let
        usersToNotify : SeqDict (Id UserId) (Discord.Id Discord.UserId)
        usersToNotify =
            case SeqDict.get channelId model.discordDmChannels of
                Just channel ->
                    NonemptyDict.keys channel.members
                        |> List.Nonempty.toList
                        |> List.filterMap
                            (\member ->
                                if member == senderId then
                                    Nothing

                                else
                                    case SeqDict.get member model.discordUsers of
                                        Just (FullData discordUser) ->
                                            if isViewingDiscordDm channelId discordUser.linkedTo model then
                                                Nothing

                                            else
                                                Just ( discordUser.linkedTo, member )

                                        _ ->
                                            Nothing
                            )
                        |> SeqDict.fromList

                Nothing ->
                    SeqDict.empty
    in
    List.map
        (\( userId, discordUserId ) ->
            notification
                time
                userId
                senderName
                senderIcon
                text
                (Route.DiscordDmRoute
                    { currentDiscordUserId = discordUserId
                    , channelId = channelId
                    , viewingMessage = Nothing
                    , showMembersTab = HideMembersTab
                    }
                    |> Just
                )
                model
        )
        (SeqDict.toList usersToNotify)
        |> Command.batch


toDmChannelExcludingOne :
    ClientId
    -> Id UserId
    -> Id UserId
    -> (Id UserId -> ServerChange)
    -> BackendModel
    -> Command BackendOnly ToFrontend BackendMsg
toDmChannelExcludingOne clientId userId otherUserId serverMsg model =
    if userId == otherUserId then
        toUser (Just clientId) Nothing userId (serverMsg otherUserId |> ServerChange) model

    else
        Command.batch
            [ toUser (Just clientId) Nothing userId (serverMsg otherUserId |> ServerChange) model
            , toUser (Just clientId) Nothing otherUserId (serverMsg userId |> ServerChange) model
            ]


toDmChannel :
    Id UserId
    -> Id UserId
    -> (Id UserId -> ServerChange)
    -> BackendModel
    -> Command BackendOnly ToFrontend BackendMsg
toDmChannel userId otherUserId serverMsg model =
    if userId == otherUserId then
        toUser Nothing Nothing userId (serverMsg otherUserId |> ServerChange) model

    else
        Command.batch
            [ toUser Nothing Nothing userId (serverMsg otherUserId |> ServerChange) model
            , toUser Nothing Nothing otherUserId (serverMsg userId |> ServerChange) model
            ]


type alias PushNotification =
    { endpoint : String
    , p256dh : String
    , auth : String
    , privateKey : PrivateVapidKey
    , title : String
    , body : String
    , icon : String
    , navigate : String
    , data : Maybe String
    }


pushNotificationCodec : Codec PushNotification
pushNotificationCodec =
    Codec.object PushNotification
        |> Codec.field "endpoint" .endpoint Codec.string
        |> Codec.field "p256dh" .p256dh Codec.string
        |> Codec.field "auth" .auth Codec.string
        |> Codec.field "private_key" .privateKey privateKeyCodec
        |> Codec.field "title" .title Codec.string
        |> Codec.field "body" .body Codec.string
        |> Codec.field "icon" .icon Codec.string
        |> Codec.field "navigate" .navigate Codec.string
        |> Codec.field "data" .data (Codec.nullable Codec.string)
        |> Codec.buildObject


privateKeyCodec : Codec PrivateVapidKey
privateKeyCodec =
    Codec.map PrivateVapidKey (\(PrivateVapidKey a) -> a) Codec.string


pushNotification :
    SessionId
    -> Id UserId
    -> Time.Posix
    -> String
    -> String
    -> String
    -> Maybe Route
    -> SubscribeData
    -> BackendModel
    -> Command restriction toFrontend BackendMsg
pushNotification sessionId userId time title body icon navigateTo pushSubscription model =
    Http.request
        { method = "POST"
        , headers = []
        , url = FileStatus.domain ++ "/file/push-notification"
        , body =
            Codec.encodeToValue
                pushNotificationCodec
                { endpoint = Url.toString pushSubscription.endpoint
                , p256dh = pushSubscription.p256dh
                , auth = pushSubscription.auth
                , privateKey = model.privateVapidKey
                , title = title
                , body = body
                , icon = icon
                , navigate = Env.domain
                , data =
                    case navigateTo of
                        Just navigateTo2 ->
                            Env.domain ++ Route.encode navigateTo2 |> Just

                        Nothing ->
                            Nothing
                }
                |> Http.jsonBody
        , expect =
            Http.expectStringResponse
                (SentNotification sessionId userId time)
                (\response ->
                    case response of
                        Http.BadUrl_ url ->
                            Http.BadUrl url |> Err

                        Http.Timeout_ ->
                            Err Http.Timeout

                        Http.NetworkError_ ->
                            Err Http.NetworkError

                        Http.BadStatus_ metadata text ->
                            Http.BadBody (String.fromInt metadata.statusCode ++ " " ++ text) |> Err

                        Http.GoodStatus_ _ _ ->
                            Ok ()
                )
        , timeout = Duration.seconds 30 |> Just
        , tracker = Nothing
        }


toEveryoneWhoCanSeeUser :
    ClientId
    -> Id UserId
    -> LocalMsg
    -> BackendModel
    -> Command BackendOnly ToFrontend msg
toEveryoneWhoCanSeeUser clientId userId change model =
    SeqDict.foldl
        (\_ guild state ->
            if LocalState.isGuildMemberOrOwner userId guild then
                guild.owner :: SeqDict.keys guild.members |> List.foldl SeqSet.insert state

            else
                state
        )
        SeqSet.empty
        model.guilds
        |> SeqSet.foldl (\userId2 cmds -> toUser (Just clientId) Nothing userId2 change model :: cmds) []
        |> Command.batch


toEveryoneWhoCanSeeUserIncludingUser :
    Id UserId
    -> LocalMsg
    -> BackendModel
    -> Command BackendOnly ToFrontend msg
toEveryoneWhoCanSeeUserIncludingUser userId change model =
    SeqDict.foldl
        (\_ guild state ->
            if LocalState.isGuildMemberOrOwner userId guild then
                guild.owner :: SeqDict.keys guild.members |> List.foldl SeqSet.insert state

            else
                state
        )
        SeqSet.empty
        model.guilds
        |> SeqSet.foldl (\userId2 cmds -> toUser Nothing Nothing userId2 change model :: cmds) []
        |> Command.batch


broadcastDm :
    ChangeId
    -> Time.Posix
    -> ClientId
    -> Id UserId
    -> Id UserId
    -> Nonempty (RichText (Id UserId))
    -> ThreadRouteWithMaybeMessage
    -> SeqDict (Id FileId) FileData
    -> BackendModel
    -> Command BackendOnly ToFrontend BackendMsg
broadcastDm changeId time clientId userId otherUserId text threadRouteWithReplyTo attachedFiles model =
    Command.batch
        [ LocalChangeResponse
            changeId
            (Local_SendMessage time (GuildOrDmId_Dm otherUserId) text threadRouteWithReplyTo attachedFiles)
            |> Lamdera.sendToFrontend clientId
        , toDmChannelExcludingOne
            clientId
            userId
            otherUserId
            (\otherUserId2 ->
                Server_SendMessage
                    userId
                    time
                    (GuildOrDmId_Dm otherUserId2)
                    text
                    threadRouteWithReplyTo
                    attachedFiles
            )
            model
        , if userId == otherUserId then
            Command.none

          else
            case NonemptyDict.get otherUserId model.users of
                Just otherUser ->
                    notification
                        time
                        otherUserId
                        (PersonName.toString otherUser.name)
                        otherUser.icon
                        (RichText.toString (NonemptyDict.toSeqDict model.users) text)
                        (DmRoute
                            otherUserId
                            (case threadRouteWithReplyTo of
                                NoThreadWithMaybeMessage _ ->
                                    NoThreadWithFriends Nothing HideMembersTab

                                ViewThreadWithMaybeMessage threadId _ ->
                                    ViewThreadWithFriends threadId Nothing HideMembersTab
                            )
                            |> Just
                        )
                        model

                Nothing ->
                    Command.none
        ]
