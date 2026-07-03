module Broadcast exposing
    ( PushNotification
    , adminUserId
    , broadcastDm
    , discordDmNotification
    , discordGuildMessageNotification
    , getSessionFromSessionIdHash
    , getUserFromSessionId
    , messageNotification
    , notificationEmailContent
    , notificationEmailSubject
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
    , toUserAlt
    , userGetAllConnections
    )

import Codec exposing (Codec)
import Discord
import DiscordUserData exposing (DiscordUserData(..))
import DmChannel
import Duration
import Effect.Command as Command exposing (BackendOnly, Command)
import Effect.Http as Http
import Effect.Lamdera as Lamdera exposing (ClientId, SessionId)
import Effect.Time as Time
import Email.Html
import Email.Html.Attributes
import EmailAddress exposing (EmailAddress)
import Env
import FileStatus exposing (FileData, FileHash, FileId)
import Id exposing (AnyGuildOrDmId(..), ChannelId, DiscordGuildOrDmId(..), GuildId, GuildOrDmId(..), Id, StickerId, ThreadRoute(..), ThreadRouteWithMaybeMessage(..), UserId)
import List.Nonempty exposing (Nonempty)
import Local exposing (ChangeId)
import LocalState exposing (PrivateVapidKey(..))
import MembersAndOwner exposing (IsMember(..))
import Message exposing (Message(..), UserTextMessageData)
import MyUi
import NonemptyDict
import PersonName
import Ports exposing (SubscribeData)
import Postmark
import RichText
import Route exposing (ChannelRoute(..), DiscordChannelRoute(..), Route(..), ShowMembersTab(..), ThreadRouteWithFriends(..))
import SecretId exposing (SecretId, ServerSecret)
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import SessionIdHash exposing (SessionIdHash)
import Sticker exposing (StickerData)
import String.Nonempty exposing (NonemptyString(..))
import Types exposing (BackendModel, BackendMsg(..), LocalChange(..), LocalMsg(..), ServerChange(..), ToFrontend(..))
import Unsafe
import Url
import User exposing (BackendUser, EmailNotifications(..))
import UserSession exposing (NotificationMode(..), PushSubscription(..), UserSession)


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
                (MembersAndOwner.membersAndOwner guild.membersAndOwner)

        Nothing ->
            []


discordGuildConnections : Discord.Id Discord.GuildId -> BackendModel -> List ClientId
discordGuildConnections guildId model =
    case SeqDict.get guildId model.discordGuilds of
        Just guild ->
            List.foldl
                (\member set ->
                    case SeqDict.get member model.discordUsers of
                        Just (FullData discordUser) ->
                            SeqSet.insert discordUser.linkedTo set

                        _ ->
                            set
                )
                SeqSet.empty
                (MembersAndOwner.membersAndOwner guild.membersAndOwner)
                |> SeqSet.toList
                |> List.concatMap
                    (\linkedTo ->
                        List.concatMap
                            (\( _, clientIds ) -> List.Nonempty.toList clientIds)
                            (userConnections linkedTo model)
                    )

        Nothing ->
            []


discordDmConnections : Discord.Id Discord.PrivateChannelId -> BackendModel -> List ClientId
discordDmConnections channelId model =
    case SeqDict.get channelId model.discordDmChannels of
        Just channel ->
            NonemptyDict.keys channel.members
                |> List.Nonempty.foldl
                    (\member set ->
                        case SeqDict.get member model.discordUsers of
                            Just (FullData discordUser) ->
                                SeqSet.insert discordUser.linkedTo set

                            _ ->
                                set
                    )
                    SeqSet.empty
                |> SeqSet.toList
                |> List.concatMap
                    (\linkedTo ->
                        List.concatMap
                            (\( _, clientIds ) -> List.Nonempty.toList clientIds)
                            (userConnections linkedTo model)
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


toUserAlt : Id UserId -> (UserSession -> LocalState.ConnectionData -> LocalMsg) -> BackendModel -> Command BackendOnly ToFrontend msg
toUserAlt userId sessionToMsg model =
    SeqDict.filterMap
        (\sessionId otherUserSession ->
            if userId == otherUserSession.userId then
                case SeqDict.get sessionId model.connections of
                    Just clientIds ->
                        List.map
                            (\( otherClientId, connection ) ->
                                sessionToMsg otherUserSession connection
                                    |> ChangeBroadcast
                                    |> Lamdera.sendToFrontend otherClientId
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
    -> UserTextMessageData messageId (Id UserId)
    -> List (Id UserId)
    -> BackendModel
    -> ( SeqDict SessionId UserSession, List (Command BackendOnly toMsg BackendMsg) )
messageNotification usersMentioned time sender guildId channelId threadRoute message members model =
    let
        plainText : String
        plainText =
            RichText.toString True (NonemptyDict.toSeqDict model.users) message.content

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
            (\userId2 ( sessions, cmds ) ->
                let
                    isViewing =
                        List.any
                            (\connection ->
                                case connection.currentlyViewing of
                                    Just ( GuildOrDmId (GuildOrDmId_Guild viewingGuildId viewingChannelId), viewingThreadRoute ) ->
                                        viewingGuildId == guildId && viewingChannelId == channelId && viewingThreadRoute == threadRoute

                                    _ ->
                                        False
                            )
                            (userGetAllConnections userId2 model)
                in
                if isViewing then
                    ( sessions, cmds )

                else
                    case NonemptyDict.get sender model.users of
                        Just user2 ->
                            notification
                                time
                                userId2
                                (PersonName.toString user2.name)
                                user2.icon
                                (\userId3 ->
                                    case NonemptyDict.get userId3 model.users of
                                        Just user3 ->
                                            PersonName.toString user3.name

                                        Nothing ->
                                            "<missing>"
                                )
                                plainText
                                (UserTextMessage message)
                                (GuildRoute guildId (ChannelRoute channelId threadRouteWithFriends Nothing) |> Just)
                                sessions
                                model
                                |> Tuple.mapSecond (\a -> Command.batch a :: cmds)

                        Nothing ->
                            ( sessions, cmds )
            )
            ( model.sessions, [] )


discordGuildMessageNotification :
    SeqSet (Discord.Id Discord.UserId)
    -> Time.Posix
    -> Discord.Id Discord.UserId
    -> Discord.Id Discord.GuildId
    -> Discord.Id Discord.ChannelId
    -> ThreadRoute
    -> Message messageId (Discord.Id Discord.UserId)
    -> List (Discord.Id Discord.UserId)
    -> BackendModel
    -> ( SeqDict SessionId UserSession, List (Command BackendOnly toMsg BackendMsg) )
discordGuildMessageNotification usersMentioned time sender guildId channelId threadRoute message members model =
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
            (\userId2 ( sessions, cmds ) ->
                case SeqDict.get userId2 model.discordUsers of
                    Just (FullData discordUser) ->
                        let
                            isViewing : Bool
                            isViewing =
                                List.any
                                    (\connection ->
                                        case connection.currentlyViewing of
                                            Just ( DiscordGuildOrDmId (DiscordGuildOrDmId_Guild _ viewingGuildId viewingChannelId), viewingThreadRoute ) ->
                                                viewingGuildId == guildId && viewingChannelId == channelId && viewingThreadRoute == threadRoute

                                            _ ->
                                                False
                                    )
                                    (userGetAllConnections discordUser.linkedTo model)
                        in
                        if isViewing then
                            ( sessions, cmds )

                        else
                            case NonemptyDict.get discordUser.linkedTo model.users of
                                Just user2 ->
                                    notification
                                        time
                                        discordUser.linkedTo
                                        (PersonName.toString user2.name)
                                        user2.icon
                                        (\userId3 ->
                                            case SeqDict.get userId3 model.discordUsers of
                                                Just user3 ->
                                                    DiscordUserData.username user3

                                                Nothing ->
                                                    "<missing>"
                                        )
                                        (case message of
                                            UserTextMessage message2 ->
                                                RichText.toStringWithGetter DiscordUserData.username True model.discordUsers message2.content

                                            UserJoinedMessage _ _ _ _ ->
                                                "New user joined!"

                                            DeletedMessage _ ->
                                                ""

                                            CallStarted _ endTime _ _ _ ->
                                                LocalState.callStartedText endTime

                                            GameStarted _ _ _ _ game ->
                                                LocalState.gameStartedText game
                                        )
                                        message
                                        (DiscordGuildRoute
                                            { currentDiscordUserId = userId2
                                            , guildId = guildId
                                            , channelRoute = DiscordChannel_ChannelRoute channelId threadRouteWithFriends Nothing
                                            }
                                            |> Just
                                        )
                                        sessions
                                        model
                                        |> Tuple.mapSecond (\a -> Command.batch a :: cmds)

                                Nothing ->
                                    ( sessions, cmds )

                    _ ->
                        ( sessions, cmds )
            )
            ( model.sessions, [] )


userGetAllConnections : Id UserId -> BackendModel -> List LocalState.ConnectionData
userGetAllConnections userId model =
    SeqDict.toList model.sessions
        |> List.concatMap
            (\( sessionId, session ) ->
                if session.userId == userId then
                    case SeqDict.get sessionId model.connections of
                        Just connection ->
                            NonemptyDict.values connection |> List.Nonempty.toList

                        Nothing ->
                            []

                else
                    []
            )


notification :
    Time.Posix
    -> Id UserId
    -> String
    -> Maybe FileHash
    -> (userId -> String)
    -> String
    -> Message messageId userId
    -> Maybe Route
    -> SeqDict SessionId UserSession
    ->
        { a
            | serverSecret : SecretId ServerSecret
            , privateVapidKey : PrivateVapidKey
            , users : NonemptyDict.NonemptyDict (Id UserId) BackendUser
            , postmarkApiKey : Postmark.ApiKey
        }
    -> ( SeqDict SessionId UserSession, List (Command BackendOnly toMsg BackendMsg) )
notification time userToNotify senderName senderIcon userToString plainText message navigateTo sessions model =
    let
        -- Email notifications are a user setting (not a session setting like push
        -- notifications) so we send at most one email per notification, regardless
        -- of how many sessions the user has open.
        emailCmds : List (Command BackendOnly toMsg BackendMsg)
        emailCmds =
            case NonemptyDict.get userToNotify model.users of
                Just user ->
                    case user.emailNotifications of
                        NotifyMeWhenMentioned ->
                            [ notificationEmail time user.email senderName userToString plainText message model.postmarkApiKey ]

                        NeverNotifyMe ->
                            []

                Nothing ->
                    []
    in
    SeqDict.foldl
        (\sessionId session ( sessions2, cmds ) ->
            if session.userId == userToNotify then
                case ( session.notificationMode, session.pushSubscription ) of
                    ( PushNotifications, Subscribed pushSubscription _ ) ->
                        ( SeqDict.insert
                            sessionId
                            { session | pushSubscription = Subscribed pushSubscription time }
                            sessions2
                        , pushNotification
                            sessionId
                            session.userId
                            time
                            senderName
                            plainText
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
                        )

                    _ ->
                        ( sessions2, cmds )

            else
                ( sessions2, cmds )
        )
        ( sessions, emailCmds )
        sessions


{-| Send an email notifying a user that they were mentioned or sent a message.
Sent when the user has enabled email notifications in their settings.
-}
notificationEmail :
    Time.Posix
    -> EmailAddress
    -> String
    -> (userId -> String)
    -> String
    -> Message messageId userId
    -> Postmark.ApiKey
    -> Command BackendOnly toMsg BackendMsg
notificationEmail time email senderName userToString plainText message postmarkApiKey =
    let
        helper subject body =
            Postmark.sendEmail
                (SentNotificationEmail time email)
                postmarkApiKey
                { from = { name = "", email = notificationEmailFrom }
                , to = List.Nonempty.fromElement { name = "", email = email }
                , subject = subject
                , body = body
                , messageStream = "outbound"
                }
    in
    case message of
        UserTextMessage data ->
            helper
                (notificationEmailSubject senderName)
                (Postmark.BodyBoth
                    (notificationEmailContent userToString senderName data)
                    (senderName ++ ": " ++ plainText ++ "\n\nOpen " ++ Env.domain ++ " to reply.")
                )

        UserJoinedMessage _ _ _ _ ->
            helper
                (NonemptyString 'N' "ew user joined")
                (Postmark.BodyText (senderName ++ " joined!"))

        DeletedMessage _ ->
            Command.none

        CallStarted _ _ _ _ _ ->
            helper
                (NonemptyString 'C' "all started")
                (Postmark.BodyText (senderName ++ " started a call"))

        GameStarted _ _ _ _ _ ->
            helper
                (NonemptyString 'G' "ame started")
                (Postmark.BodyText (senderName ++ " started a game"))


notificationEmailSubject : String -> NonemptyString
notificationEmailSubject senderName =
    NonemptyString 'N' ("ew message from " ++ senderName)


{-| Render the message that triggered a notification roughly the way it looks in
at-chat: a dark message card with the sender's name in bold above the message
text. Email clients only support a small subset of CSS, so this sticks to inline
styles and basic block elements.
-}
notificationEmailContent : (userId -> String) -> String -> UserTextMessageData messageId userId -> Email.Html.Html
notificationEmailContent userToString senderName message =
    Email.Html.div
        [ Email.Html.Attributes.backgroundColor (MyUi.colorToStyle MyUi.background3)
        , Email.Html.Attributes.padding "8px"
        , Email.Html.Attributes.borderRadius "8px"
        , Email.Html.Attributes.fontFamily "Arial, Helvetica, sans-serif"
        ]
        [ Email.Html.div
            [ Email.Html.Attributes.color "#ffffff"
            , Email.Html.Attributes.fontSize "16px"
            , Email.Html.Attributes.paddingBottom "4px"
            ]
            [ Email.Html.strong [] [ Email.Html.text senderName ] ]
        , Email.Html.div
            [ Email.Html.Attributes.color "#ffffff"
            , Email.Html.Attributes.fontSize "15px"
            , Email.Html.Attributes.lineHeight "1.4"
            , Email.Html.Attributes.style "white-space" "pre-wrap"
            ]
            (RichText.emailView { userToString = userToString, attachedFiles = message.attachedFiles } message.content)
        , Email.Html.div
            [ Email.Html.Attributes.paddingTop "20px" ]
            [ Email.Html.b
                []
                [ Email.Html.a
                    [ Email.Html.Attributes.href Env.domain
                    , Email.Html.Attributes.backgroundColor "#407ab2"
                    , Email.Html.Attributes.color "#ffffff"
                    , Email.Html.Attributes.fontSize "14px"
                    , Email.Html.Attributes.padding "4px 8px"
                    , Email.Html.Attributes.borderRadius "4px"
                    , Email.Html.Attributes.style "text-decoration" "none"
                    , Email.Html.Attributes.style "display" "inline-block"
                    ]
                    [ Email.Html.text "Open at-chat" ]
                ]
            ]
        ]


notificationEmailFrom : EmailAddress
notificationEmailFrom =
    Unsafe.emailAddress "no-reply@at-chat.app"


isViewingDiscordDm : Discord.Id Discord.PrivateChannelId -> Id UserId -> BackendModel -> Bool
isViewingDiscordDm channelId userId2 model =
    List.any
        (\connection ->
            case connection.currentlyViewing of
                Just ( DiscordGuildOrDmId (DiscordGuildOrDmId_Dm data), _ ) ->
                    data.channelId == channelId

                _ ->
                    False
        )
        (userGetAllConnections userId2 model)


discordDmNotification :
    Time.Posix
    -> Discord.Id Discord.PrivateChannelId
    -> Discord.Id Discord.UserId
    -> String
    -> Maybe FileHash
    -> String
    -> UserTextMessageData messageId (Discord.Id Discord.UserId)
    -> BackendModel
    -> ( SeqDict SessionId UserSession, List (Command BackendOnly toMsg BackendMsg) )
discordDmNotification time channelId senderId senderName senderIcon text message model =
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
    SeqDict.foldl
        (\userId discordUserId ( sessions, cmds ) ->
            notification
                time
                userId
                senderName
                senderIcon
                (\userId2 ->
                    case SeqDict.get userId2 model.discordUsers of
                        Just user ->
                            DiscordUserData.username user

                        Nothing ->
                            "<missing>"
                )
                text
                (UserTextMessage message)
                (Route.DiscordDmRoute
                    { currentDiscordUserId = discordUserId
                    , channelId = channelId
                    , viewingMessage = Nothing
                    , showMembersTab = HideMembersTab
                    , tab = Nothing
                    }
                    |> Just
                )
                sessions
                model
                |> Tuple.mapSecond (\a -> Command.batch a :: cmds)
        )
        ( model.sessions, [] )
        usersToNotify


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
    -> Command BackendOnly ToFrontend msg
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
    -> { a | serverSecret : SecretId ServerSecret, privateVapidKey : PrivateVapidKey }
    -> Command restriction toFrontend BackendMsg
pushNotification sessionId userId time title body icon navigateTo subscribeData model =
    Http.request
        { method = "POST"
        , headers = [ FileStatus.secretKeyHeader model.serverSecret ]
        , url = FileStatus.domain ++ "/file/internal/push-notification"
        , body =
            Codec.encodeToValue
                pushNotificationCodec
                { endpoint = Url.toString subscribeData.endpoint
                , p256dh = subscribeData.keys.p256dh
                , auth = subscribeData.keys.auth
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
                (SentNotification sessionId userId time subscribeData)
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
            case MembersAndOwner.isMember userId guild.membersAndOwner of
                IsNotMember ->
                    state

                _ ->
                    MembersAndOwner.membersAndOwner guild.membersAndOwner |> List.foldl SeqSet.insert state
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
            case MembersAndOwner.isMember userId guild.membersAndOwner of
                IsNotMember ->
                    state

                _ ->
                    MembersAndOwner.membersAndOwner guild.membersAndOwner |> List.foldl SeqSet.insert state
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
    -> NonemptyString
    -> UserTextMessageData messageId (Id UserId)
    -> ThreadRouteWithMaybeMessage
    -> SeqDict (Id FileId) FileData
    -> SeqDict (Id StickerId) StickerData
    -> BackendModel
    -> ( SeqDict SessionId UserSession, Command BackendOnly ToFrontend BackendMsg )
broadcastDm changeId time clientId userId otherUserId text message threadRouteWithReplyTo attachedFiles stickers model =
    let
        threadRouteNoReply : ThreadRoute
        threadRouteNoReply =
            case threadRouteWithReplyTo of
                NoThreadWithMaybeMessage _ ->
                    NoThread

                ViewThreadWithMaybeMessage threadId _ ->
                    ViewThread threadId

        isViewing : Bool
        isViewing =
            List.any
                (\connection ->
                    case connection.currentlyViewing of
                        Just ( GuildOrDmId (GuildOrDmId_Dm viewingUserId), viewingThreadRoute ) ->
                            viewingUserId == userId && viewingThreadRoute == threadRouteNoReply

                        _ ->
                            False
                )
                (userGetAllConnections otherUserId model)

        ( sessions, cmds ) =
            if userId == otherUserId || isViewing then
                ( model.sessions, [] )

            else
                case NonemptyDict.get otherUserId model.users of
                    Just otherUser ->
                        notification
                            time
                            otherUserId
                            (PersonName.toString otherUser.name)
                            otherUser.icon
                            (\userId2 ->
                                case NonemptyDict.get userId2 model.users of
                                    Just user ->
                                        PersonName.toString user.name

                                    Nothing ->
                                        "<missing>"
                            )
                            (String.Nonempty.toString text)
                            (UserTextMessage message)
                            (DmRoute
                                { channelId = DmChannel.channelIdFromUserIds userId otherUserId
                                , threadRoute =
                                    case threadRouteWithReplyTo of
                                        NoThreadWithMaybeMessage _ ->
                                            NoThreadWithFriends Nothing HideMembersTab

                                        ViewThreadWithMaybeMessage threadId _ ->
                                            ViewThreadWithFriends threadId Nothing HideMembersTab
                                , tab = Nothing
                                }
                                |> Just
                            )
                            model.sessions
                            model

                    Nothing ->
                        ( model.sessions, [] )
    in
    ( sessions
    , Command.batch
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
                    message.content
                    threadRouteWithReplyTo
                    attachedFiles
                    stickers
            )
            model
        , Command.batch cmds
        ]
    )
