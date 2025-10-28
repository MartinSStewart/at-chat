module Broadcast exposing
    ( PushNotification
    , adminUserId
    , broadcastDm
    , discordMessageNotification
    , getSessionFromSessionIdHash
    , getUserFromSessionId
    , messageNotification
    , notification
    , pushNotification
    , pushNotificationCodec
    , toDiscordGuildExcludingOne
    , toDmChannel
    , toEveryone
    , toEveryoneWhoCanSeeUser
    , toGuild
    , toGuildExcludingOne
    , toOtherAdmins
    , toSession
    , toUser
    , userGetAllSessions
    )

import Codec exposing (Codec)
import Discord.Id
import Duration
import Effect.Command as Command exposing (BackendOnly, Command)
import Effect.Http as Http
import Effect.Lamdera as Lamdera exposing (ClientId, SessionId)
import Effect.Time as Time
import Env
import FileStatus exposing (FileData, FileId)
import Id exposing (AnyGuildOrDmId(..), ChannelId, DiscordGuildOrDmId(..), GuildId, GuildOrDmId(..), Id, ThreadRoute(..), ThreadRouteWithMaybeMessage(..), UserId)
import List.Nonempty exposing (Nonempty)
import Local exposing (ChangeId)
import LocalState exposing (PrivateVapidKey(..))
import NonemptyDict
import PersonName
import RichText exposing (RichText)
import Route exposing (ChannelRoute(..), DiscordChannelRoute(..), Route(..), ShowMembersTab(..), ThreadRouteWithFriends(..))
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import SessionIdHash exposing (SessionIdHash)
import Types exposing (BackendModel, BackendMsg(..), DiscordUserData(..), LocalChange(..), LocalMsg(..), ServerChange(..), ToFrontend(..))
import Url
import User exposing (BackendUser)
import UserSession exposing (NotificationMode(..), PushSubscription(..), SubscribeData, UserSession)


adminUserId : Id UserId
adminUserId =
    Id.fromInt 0


toGuildExcludingOne : ClientId -> Id GuildId -> LocalMsg -> BackendModel -> Command BackendOnly ToFrontend msg
toGuildExcludingOne clientToSkip _ msg model =
    List.concatMap
        (\( _, otherClientIds ) ->
            NonemptyDict.keys otherClientIds
                |> List.Nonempty.toList
                |> List.filterMap
                    (\otherClientId ->
                        if clientToSkip == otherClientId then
                            Nothing

                        else
                            ChangeBroadcast msg
                                |> Lamdera.sendToFrontend otherClientId
                                |> Just
                    )
        )
        (SeqDict.toList model.connections)
        |> Command.batch


toDiscordGuildExcludingOne : ClientId -> Discord.Id.Id Discord.Id.GuildId -> LocalMsg -> BackendModel -> Command BackendOnly ToFrontend msg
toDiscordGuildExcludingOne clientToSkip _ msg model =
    List.concatMap
        (\( _, otherClientIds ) ->
            NonemptyDict.keys otherClientIds
                |> List.Nonempty.toList
                |> List.filterMap
                    (\otherClientId ->
                        if clientToSkip == otherClientId then
                            Nothing

                        else
                            ChangeBroadcast msg
                                |> Lamdera.sendToFrontend otherClientId
                                |> Just
                    )
        )
        (SeqDict.toList model.connections)
        |> Command.batch


toGuild : Id GuildId -> LocalMsg -> BackendModel -> Command BackendOnly ToFrontend msg
toGuild _ msg model =
    List.concatMap
        (\( _, otherClientIds ) ->
            NonemptyDict.keys otherClientIds
                |> List.Nonempty.toList
                |> List.map
                    (\otherClientId ->
                        ChangeBroadcast msg
                            |> Lamdera.sendToFrontend otherClientId
                    )
        )
        (SeqDict.toList model.connections)
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
        (\sessionId otherUserSession ->
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
                                user2
                                plainText
                                (GuildRoute guildId (ChannelRoute channelId threadRouteWithFriends) |> Just)
                                model
                                :: cmds

                        Nothing ->
                            cmds
            )
            []
        |> Command.batch


discordMessageNotification :
    SeqSet (Discord.Id.Id Discord.Id.UserId)
    -> Time.Posix
    -> Discord.Id.Id Discord.Id.UserId
    -> Discord.Id.Id Discord.Id.GuildId
    -> Discord.Id.Id Discord.Id.ChannelId
    -> ThreadRoute
    -> Nonempty (RichText (Discord.Id.Id Discord.Id.UserId))
    -> List (Discord.Id.Id Discord.Id.UserId)
    -> BackendModel
    -> Command restriction toMsg BackendMsg
discordMessageNotification usersMentioned time sender guildId channelId threadRoute content members model =
    let
        plainText : String
        plainText =
            RichText.toString
                (SeqDict.map
                    (\userId user ->
                        { name =
                            case user of
                                BasicData data ->
                                    PersonName.fromStringLossy data.user.username

                                FullData data ->
                                    PersonName.fromStringLossy data.user.username
                        }
                    )
                    model.discordUsers
                )
                content

        alwaysNotify : SeqSet (Discord.Id.Id Discord.Id.UserId)
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
                                        user2
                                        plainText
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
    -> BackendUser
    -> String
    -> Maybe Route
    -> BackendModel
    -> Command restriction toMsg BackendMsg
notification time userToNotify sender text navigateTo model =
    SeqDict.foldl
        (\sessionId session cmds ->
            if session.userId == userToNotify then
                case ( session.notificationMode, session.pushSubscription ) of
                    ( PushNotifications, Subscribed pushSubscription ) ->
                        pushNotification
                            sessionId
                            session.userId
                            time
                            (PersonName.toString sender.name)
                            text
                            (case sender.icon of
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


toDmChannel :
    ClientId
    -> Id UserId
    -> Id UserId
    -> (Id UserId -> ServerChange)
    -> BackendModel
    -> Command BackendOnly ToFrontend BackendMsg
toDmChannel clientId userId otherUserId serverMsg model =
    if userId == otherUserId then
        toUser (Just clientId) Nothing userId (serverMsg otherUserId |> ServerChange) model

    else
        Command.batch
            [ toUser (Just clientId) Nothing userId (serverMsg otherUserId |> ServerChange) model
            , toUser (Just clientId) Nothing otherUserId (serverMsg userId |> ServerChange) model
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
            if userId == guild.owner || SeqDict.member userId guild.members then
                guild.owner :: SeqDict.keys guild.members |> List.foldl SeqSet.insert state

            else
                state
        )
        SeqSet.empty
        model.guilds
        |> SeqSet.foldl (\userId2 cmds -> toUser (Just clientId) Nothing userId2 change model :: cmds) []
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
        , toDmChannel
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
                        otherUser
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
