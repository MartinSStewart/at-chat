module Backend exposing
    ( adminUser
    , app
    , app_
    , emailToNotifyWhenErrorsAreLogged
    , loginEmailContent
    , loginEmailSubject
    )

import AiChat
import Array exposing (Array)
import Broadcast
import Discord exposing (OptionalData(..))
import Discord.Id
import Discord.Markdown
import DiscordSync
import DmChannel exposing (DmChannel, DmChannelId, ExternalChannelId(..), ExternalMessageId(..), LastTypedAt, Thread)
import Duration
import Effect.Command as Command exposing (BackendOnly, Command)
import Effect.Http as Http
import Effect.Lamdera as Lamdera exposing (ClientId, SessionId)
import Effect.Subscription as Subscription exposing (Subscription)
import Effect.Task as Task exposing (Task)
import Effect.Time as Time
import Effect.Websocket as Websocket
import Email.Html
import Email.Html.Attributes
import EmailAddress exposing (EmailAddress)
import Env
import FileStatus exposing (FileData, FileHash, FileId)
import Hex
import Id exposing (AnyGuildOrDmId(..), ChannelId, ChannelMessageId, DiscordGuildOrDmId(..), GuildId, GuildOrDmId(..), Id, InviteLinkId, ThreadRoute(..), ThreadRouteWithMaybeMessage(..), ThreadRouteWithMessage(..), UserId)
import Lamdera as LamderaCore
import List.Extra
import List.Nonempty exposing (Nonempty(..))
import Local exposing (ChangeId)
import LocalState exposing (BackendChannel, BackendGuild, ChannelStatus(..), DiscordBackendChannel, DiscordBackendGuild, JoinGuildError(..), PrivateVapidKey(..))
import Log exposing (Log)
import LoginForm
import Message exposing (Message(..))
import NonemptyDict exposing (NonemptyDict)
import OneToOne exposing (OneToOne)
import Pages.Admin exposing (InitAdminData)
import Pagination
import PersonName
import Postmark
import Quantity
import RichText exposing (RichText)
import SecretId exposing (SecretId)
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import Slack exposing (Channel(..))
import String.Nonempty exposing (NonemptyString(..))
import TOTP.Key
import TextEditor
import Toop exposing (T4(..))
import TwoFactorAuthentication
import Types exposing (AdminStatusLoginData(..), BackendFileData, BackendModel, BackendMsg(..), DiscordFullUserData, DiscordUserData(..), LastRequest(..), LocalChange(..), LocalDiscordChange(..), LocalMsg(..), LoginData, LoginResult(..), LoginTokenData(..), ServerChange(..), ToBackend(..), ToFrontend(..))
import Unsafe
import User exposing (BackendUser)
import UserAgent exposing (UserAgent)
import UserSession exposing (PushSubscription(..), SetViewing(..), ToBeFilledInByBackend(..), UserSession)
import VisibleMessages


app :
    { init : ( BackendModel, Cmd BackendMsg )
    , update : BackendMsg -> BackendModel -> ( BackendModel, Cmd BackendMsg )
    , updateFromFrontend : String -> String -> ToBackend -> BackendModel -> ( BackendModel, Cmd BackendMsg )
    , subscriptions : BackendModel -> Sub BackendMsg
    }
app =
    Lamdera.backend LamderaCore.broadcast LamderaCore.sendToFrontend app_


app_ :
    { init : ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
    , update : BackendMsg -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
    , updateFromFrontend : SessionId -> ClientId -> ToBackend -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
    , subscriptions : BackendModel -> Subscription BackendOnly BackendMsg
    }
app_ =
    { init = init
    , update = update
    , updateFromFrontend = updateFromFrontend
    , subscriptions = subscriptions
    }


adminUser : BackendUser
adminUser =
    User.init
        (Time.millisToPosix 0)
        (Unsafe.personName "AT")
        (Unsafe.emailAddress Env.adminEmail)
        True


init : ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
init =
    let
        guild : BackendGuild
        guild =
            { createdAt = Time.millisToPosix 0
            , createdBy = Broadcast.adminUserId
            , name = Unsafe.guildName "First guild"
            , icon = Nothing
            , channels =
                SeqDict.fromList
                    [ ( Id.fromInt 0
                      , { createdAt = Time.millisToPosix 0
                        , createdBy = Broadcast.adminUserId
                        , name = Unsafe.channelName "Welcome"
                        , messages = Array.empty
                        , status = ChannelActive
                        , lastTypedAt = SeqDict.empty
                        , threads = SeqDict.empty
                        }
                      )
                    , ( Id.fromInt 1
                      , { createdAt = Time.millisToPosix 0
                        , createdBy = Broadcast.adminUserId
                        , name = Unsafe.channelName "General"
                        , messages = Array.empty
                        , status = ChannelActive
                        , lastTypedAt = SeqDict.empty
                        , threads = SeqDict.empty
                        }
                      )
                    ]
            , members = SeqDict.fromList []
            , owner = Broadcast.adminUserId
            , invites = SeqDict.empty
            }
    in
    ( { users =
            Nonempty ( Broadcast.adminUserId, adminUser ) []
                |> NonemptyDict.fromNonemptyList
      , sessions = SeqDict.empty
      , connections = SeqDict.empty
      , secretCounter = 0
      , pendingLogins = SeqDict.empty
      , logs = Array.empty
      , emailNotificationsEnabled = True
      , lastErrorLogEmail = Time.millisToPosix -10000000000
      , twoFactorAuthentication = SeqDict.empty
      , twoFactorAuthenticationSetup = SeqDict.empty
      , guilds = SeqDict.fromList [ ( Id.fromInt 0, guild ) ]
      , backendInitialized = True
      , discordGuilds = SeqDict.empty
      , dmChannels = SeqDict.empty
      , discordDms = OneToOne.empty
      , slackWorkspaces = OneToOne.empty
      , slackUsers = OneToOne.empty
      , slackServers = OneToOne.empty
      , slackDms = OneToOne.empty
      , slackToken = Nothing
      , files = SeqDict.empty
      , publicVapidKey =
            if Env.isProduction then
                ""

            else
                "BJQi8slSWU9MNhpLBnkj40QgKnPA6ayBlI0ktidyrLtZz4YiwCJwfivC5RAXWp3MEzJ68B9E8FeUKmn3PKXJLa0"
      , privateVapidKey =
            if Env.isProduction then
                PrivateVapidKey ""

            else
                PrivateVapidKey "tmWabWMceLrqTcFCKWCX2Ifj-0L5vRjGz_ZwSyJUnLQ"
      , slackClientSecret = Nothing
      , openRouterKey = Nothing
      , textEditor = TextEditor.initLocalState
      , discordUsers = SeqDict.empty
      }
    , Command.none
    )


adminData : BackendModel -> Int -> InitAdminData
adminData model lastLogPageViewed =
    { lastLogPageViewed = lastLogPageViewed
    , users = model.users
    , emailNotificationsEnabled = model.emailNotificationsEnabled
    , twoFactorAuthentication = SeqDict.map (\_ a -> a.finishedAt) model.twoFactorAuthentication
    , privateVapidKey = model.privateVapidKey
    , slackClientSecret = model.slackClientSecret
    , openRouterKey = model.openRouterKey
    }


subscriptions : BackendModel -> Subscription BackendOnly BackendMsg
subscriptions model =
    Subscription.batch
        [ Lamdera.onConnect UserConnected
        , Lamdera.onDisconnect UserDisconnected
        , List.filterMap
            (\( discordUserId, data ) ->
                case data of
                    FullData data2 ->
                        Discord.subscription
                            (\connection onData onClose -> Websocket.listen connection onData (\_ -> onClose))
                            data2.connection
                            |> Maybe.map (Subscription.map (DiscordUserWebsocketMsg discordUserId))

                    BasicData _ ->
                        Nothing
            )
            (SeqDict.toList model.discordUsers)
            |> Subscription.batch
        ]


update : BackendMsg -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
update msg model =
    case msg of
        UserConnected sessionId clientId ->
            ( { model
                | connections =
                    SeqDict.update
                        sessionId
                        (\maybeValue ->
                            case maybeValue of
                                Just value ->
                                    NonemptyDict.insert clientId NoRequestsMade value |> Just

                                Nothing ->
                                    NonemptyDict.singleton clientId NoRequestsMade |> Just
                        )
                        model.connections
              }
            , Lamdera.sendToFrontend clientId YouConnected
            )

        UserDisconnected sessionId clientId ->
            let
                model2 : BackendModel
                model2 =
                    { model
                        | connections =
                            SeqDict.update
                                sessionId
                                (Maybe.andThen
                                    (\value ->
                                        NonemptyDict.toSeqDict value
                                            |> SeqDict.remove clientId
                                            |> NonemptyDict.fromSeqDict
                                    )
                                )
                                model.connections
                    }
            in
            case SeqDict.get sessionId model2.sessions of
                Just session ->
                    ( { model2
                        | sessions =
                            SeqDict.insert
                                sessionId
                                (UserSession.setCurrentlyViewing Nothing session)
                                model2.sessions
                      }
                    , Broadcast.toUser
                        Nothing
                        Nothing
                        session.userId
                        (Server_CurrentlyViewing session.sessionIdHash Nothing |> ServerChange)
                        model2
                    )

                Nothing ->
                    ( model2, Command.none )

        BackendGotTime sessionId clientId toBackend time ->
            updateFromFrontendWithTime time sessionId clientId toBackend model

        SentLoginEmail time emailAddress result ->
            addLog time (Log.LoginEmail result emailAddress) model

        SentLogErrorEmail time email result ->
            case result of
                Ok () ->
                    ( model, Command.none )

                Err error ->
                    addLog time (Log.SendLogErrorEmailFailed error email) model

        DiscordUserWebsocketMsg discordUserId discordMsg ->
            DiscordSync.discordUserWebsocketMsg discordUserId discordMsg model

        GotSlackChannels time userId result ->
            case result of
                Ok data ->
                    ( addSlackUsers time userId data.currentUser data.users model
                        |> addSlackServer time userId data.team data.users data.channels
                    , Command.none
                    )

                Err error ->
                    let
                        _ =
                            Debug.log "GotSlackChannels" error
                    in
                    ( model, Command.none )

        SentDiscordGuildMessage time changeId sessionId clientId guildId channelId threadRouteWithMaybeReplyTo text attachedFiles discordUserId result ->
            case result of
                Ok message ->
                    asDiscordGuildMember
                        model
                        sessionId
                        guildId
                        discordUserId
                        (sentDiscordGuildMessage
                            model
                            time
                            clientId
                            changeId
                            guildId
                            channelId
                            threadRouteWithMaybeReplyTo
                            text
                            attachedFiles
                            discordUserId
                            message
                        )

                Err _ ->
                    ( model, invalidChangeResponse changeId clientId )

        DeletedDiscordMessage ->
            ( model, Command.none )

        EditedDiscordMessage ->
            ( model, Command.none )

        AiChatBackendMsg aiChatMsg ->
            ( model, Command.map AiChatToFrontend AiChatBackendMsg (AiChat.backendUpdate aiChatMsg) )

        SentDirectMessageToDiscord dmChannelId messageId result ->
            Debug.todo ""

        --case result of
        --    Ok message ->
        --        ( { model
        --            | dmChannels =
        --                SeqDict.updateIfExists
        --                    dmChannelId
        --                    (\dmChannel ->
        --                        { dmChannel
        --                            | linkedMessageIds =
        --                                OneToOne.insert
        --                                    (DiscordMessageId message.id)
        --                                    messageId
        --                                    dmChannel.linkedMessageIds
        --                        }
        --                    )
        --                    model.dmChannels
        --          }
        --        , Command.none
        --        )
        --
        --    Err _ ->
        --        ( model, Command.none )
        GotDiscordUserAvatars result ->
            case result of
                Ok userAvatars ->
                    ( { model
                        | discordUsers =
                            List.foldl
                                (\( discordUserId, maybeAvatar ) discordUsers ->
                                    SeqDict.updateIfExists
                                        discordUserId
                                        (\user ->
                                            case user of
                                                FullData data ->
                                                    FullData { data | icon = Maybe.map .fileHash maybeAvatar }

                                                BasicData data ->
                                                    BasicData { data | icon = Maybe.map .fileHash maybeAvatar }
                                        )
                                        discordUsers
                                )
                                model.discordUsers
                                userAvatars
                      }
                    , Command.none
                    )

                Err _ ->
                    ( model, Command.none )

        SentNotification sessionId userId time result ->
            case result of
                Ok () ->
                    ( model, Command.none )

                Err error ->
                    addLogWithCmd
                        time
                        (Log.PushNotificationError userId error)
                        { model
                            | sessions =
                                SeqDict.updateIfExists
                                    sessionId
                                    (\session -> { session | pushSubscription = SubscriptionError error })
                                    model.sessions
                        }
                        (if Env.isProduction && userId /= Broadcast.adminUserId then
                            Broadcast.toSession
                                sessionId
                                (Server_PushNotificationFailed (Http.BadBody "Something went wrong when sending notifications"))
                                model

                         else
                            Broadcast.toSession
                                sessionId
                                (Server_PushNotificationFailed error)
                                model
                        )

        GotVapidKeys result ->
            ( case result of
                Ok keys ->
                    case String.split "," keys of
                        [ publicKey, privateKey ] ->
                            { model
                                | publicVapidKey = publicKey
                                , privateVapidKey = PrivateVapidKey privateKey
                            }

                        _ ->
                            model

                Err _ ->
                    model
            , Command.none
            )

        GotSlackOAuth time userId result ->
            case result of
                Ok ok ->
                    ( model
                    , Task.map4
                        T4
                        (Slack.getCurrentUser ok.userAccessToken)
                        (Slack.teamInfo ok.botAccessToken)
                        (Slack.listUsers ok.botAccessToken 100 Nothing)
                        (Slack.loadWorkspaceChannels ok.userAccessToken ok.teamId)
                        |> Task.andThen
                            (\(T4 currentUser teamInfo ( users, _ ) channels) ->
                                List.map
                                    (\channel ->
                                        Slack.loadMessages ok.userAccessToken (Slack.channelId channel) 100
                                            |> Task.map (\messages -> ( channel, messages ))
                                    )
                                    channels
                                    |> Task.sequence
                                    |> Task.map
                                        (\channels2 ->
                                            { currentUser = currentUser
                                            , team = teamInfo
                                            , users = users
                                            , channels = channels2
                                            }
                                        )
                            )
                        |> Task.attempt (GotSlackChannels time userId)
                    )

                Err _ ->
                    ( model, Command.none )

        LinkDiscordUserStep1 clientId userId auth result ->
            case result of
                Ok discordUser ->
                    ( { model
                        | discordUsers =
                            SeqDict.insert
                                discordUser.id
                                (FullData
                                    { auth = auth
                                    , user = discordUser
                                    , connection = Discord.init
                                    , linkedTo = userId
                                    , icon = Nothing
                                    }
                                )
                                model.discordUsers
                      }
                    , Command.batch
                        [ Lamdera.sendToFrontend clientId (LinkDiscordResponse result)
                        , Broadcast.toUser
                            Nothing
                            Nothing
                            userId
                            (Server_LinkDiscordUser discordUser.id discordUser.username |> ServerChange)
                            model
                        , Websocket.createHandle (WebsocketCreatedHandleForUser discordUser.id) Discord.websocketGatewayUrl
                        ]
                    )

                Err _ ->
                    ( model
                    , Lamdera.sendToFrontend clientId (LinkDiscordResponse result)
                    )

        HandleReadyDataStep2 discordUserId result ->
            case Debug.log "discordGuildsReuslt" result of
                Ok data ->
                    ( DiscordSync.addDiscordGuilds (SeqDict.fromList data) model
                    , Command.none
                      --, case SeqDict.get discordUserId model.discordUsers of
                      --    Just (FullData user) ->
                      --        Discord.requestGuildMembers
                      --            (\connection data2 ->
                      --                Websocket.sendString connection data2
                      --                    |> Task.attempt (WebsocketSentDataForUser discordUserId)
                      --            )
                      --            (List.map Tuple.first data)
                      --            user.connection
                      --            |> Result.withDefault Command.none
                      --
                      --    _ ->
                      --        Command.none
                    )

                Err error ->
                    let
                        _ =
                            Debug.log "GotDiscordGuilds" error
                    in
                    ( model, Command.none )

        WebsocketCreatedHandleForUser discordUserId connection ->
            ( { model
                | discordUsers =
                    SeqDict.updateIfExists
                        discordUserId
                        (\userData ->
                            case userData of
                                FullData userData2 ->
                                    { userData2 | connection = Discord.createdHandle connection userData2.connection }
                                        |> FullData

                                BasicData _ ->
                                    userData
                        )
                        model.discordUsers
              }
            , Command.none
            )

        WebsocketClosedByBackendForUser discordUserId reopen ->
            ( model
            , if reopen then
                Websocket.createHandle (WebsocketCreatedHandleForUser discordUserId) Discord.websocketGatewayUrl

              else
                Command.none
            )

        WebsocketSentDataForUser discordUserId result ->
            case result of
                Ok () ->
                    ( model, Command.none )

                Err Websocket.ConnectionClosed ->
                    let
                        _ =
                            Debug.log "WebsocketSentDataForUser" ( discordUserId, "ConnectionClosed" )
                    in
                    ( model, Command.none )


addSlackServer :
    Time.Posix
    -> Id UserId
    -> Slack.Team
    -> List Slack.User
    -> List ( Channel, List Slack.Message )
    -> BackendModel
    -> BackendModel
addSlackServer time currentUserId team slackUsers channels model =
    Debug.todo ""



--case OneToOne.second team.id model.slackServers of
--    Just _ ->
--        model
--
--    Nothing ->
--        let
--            ownerId : Id UserId
--            ownerId =
--                --case OneToOne.second data.guild.ownerId model.slackUsers of
--                --    Just ownerId2 ->
--                --        ownerId2
--                --
--                --    Nothing ->
--                Broadcast.adminUserId
--
--            threads : SeqDict (Slack.Id Slack.ChannelId) (List ( Channel, List Slack.Message ))
--            threads =
--                SeqDict.empty
--
--            --List.foldl
--            --    (\a dict ->
--            --        case (Tuple.first a).parentId of
--            --            Included (Just parentId) ->
--            --                SeqDict.update
--            --                    parentId
--            --                    (\maybe ->
--            --                        case maybe of
--            --                            Just list ->
--            --                                Just (a :: list)
--            --
--            --                            Nothing ->
--            --                                Just [ a ]
--            --                    )
--            --                    dict
--            --
--            --            _ ->
--            --                dict
--            --    )
--            --    SeqDict.empty
--            --    data.threads
--            members : SeqDict (Id UserId) { joinedAt : Time.Posix }
--            members =
--                List.filterMap
--                    (\guildMember ->
--                        case OneToOne.second guildMember.id model.slackUsers of
--                            Just userId ->
--                                if userId == ownerId then
--                                    Nothing
--
--                                else
--                                    Just ( userId, { joinedAt = time } )
--
--                            Nothing ->
--                                Nothing
--                    )
--                    slackUsers
--                    |> SeqDict.fromList
--
--            newGuild : BackendGuild (Id ChannelId)
--            newGuild =
--                { createdAt = time
--                , createdBy = ownerId
--                , name = GuildName.fromStringLossy team.name
--                , icon = Nothing
--                , channels = SeqDict.empty
--                , members = members
--                , owner = ownerId
--                , invites = SeqDict.empty
--                }
--
--            newGuild2 =
--                List.foldl
--                    (\( index, ( slackChannel, messages ) ) guild2 ->
--                        case addSlackChannel time ownerId model threads index slackChannel messages of
--                            Just ( slackChannelId, channelId, channel ) ->
--                                { newGuild
--                                    | channels = SeqDict.insert channelId channel guild2.channels
--                                    , linkedChannelIds =
--                                        OneToOne.insert
--                                            (SlackChannelId slackChannelId)
--                                            channelId
--                                            guild2.linkedChannelIds
--                                }
--
--                            Nothing ->
--                                guild2
--                    )
--                    newGuild
--                    (List.indexedMap Tuple.pair channels)
--
--            newGuild3 : BackendGuild
--            newGuild3 =
--                LocalState.addMember time Broadcast.adminUserId newGuild2
--                    |> Result.withDefault newGuild2
--
--            guildId : Id GuildId
--            guildId =
--                Id.nextId model.guilds
--        in
--        { model
--            | slackServers = OneToOne.insert team.id guildId model.slackServers
--            , guilds = SeqDict.insert guildId newGuild3 model.guilds
--            , users =
--                SeqDict.foldl
--                    (\userId _ users ->
--                        NonemptyDict.updateIfExists
--                            userId
--                            (\user ->
--                                SeqDict.foldl
--                                    (\channelId channel user2 ->
--                                        { user2
--                                            | lastViewed =
--                                                SeqDict.insert
--                                                    (GuildOrDmId_Guild guildId channelId)
--                                                    (DmChannel.latestMessageId channel)
--                                                    user2.lastViewed
--                                            , lastViewedThreads =
--                                                SeqDict.foldl
--                                                    (\threadId thread lastViewedThreads ->
--                                                        SeqDict.insert
--                                                            ( GuildOrDmId_Guild guildId channelId, threadId )
--                                                            (DmChannel.latestThreadMessageId thread)
--                                                            lastViewedThreads
--                                                    )
--                                                    user2.lastViewedThreads
--                                                    channel.threads
--                                        }
--                                    )
--                                    user
--                                    newGuild3.channels
--                            )
--                            users
--                    )
--                    model.users
--                    members
--            , dmChannels =
--                List.foldl
--                    (\( channel, messages ) dmChannels ->
--                        case channel of
--                            ImChannel data ->
--                                case OneToOne.second data.user model.slackUsers of
--                                    Just otherUserId ->
--                                        SeqDict.update
--                                            (DmChannel.channelIdFromUserIds
--                                                currentUserId
--                                                otherUserId
--                                            )
--                                            (\maybe ->
--                                                case maybe of
--                                                    Just dmChannel ->
--                                                        dmChannel
--                                                            |> addSlackMessages NoThread messages model
--                                                            |> Just
--
--                                                    Nothing ->
--                                                        DmChannel.init
--                                                            |> addSlackMessages NoThread messages model
--                                                            |> Just
--                                            )
--                                            dmChannels
--
--                                    Nothing ->
--                                        dmChannels
--
--                            NormalChannel _ ->
--                                dmChannels
--                    )
--                    model.dmChannels
--                    channels
--        }


addSlackUsers : Time.Posix -> Id UserId -> Slack.CurrentUser -> List Slack.User -> BackendModel -> BackendModel
addSlackUsers time currentUserId currentUser newUsers model =
    Debug.todo ""


addSlackChannel :
    Time.Posix
    -> Id UserId
    -> BackendModel
    -> SeqDict (Slack.Id Slack.ChannelId) (List ( Channel, List Slack.Message ))
    -> Int
    -> Channel
    -> List Slack.Message
    -> Maybe ( Slack.Id Slack.ChannelId, Id ChannelId, BackendChannel )
addSlackChannel time ownerId model _ index slackChannel messages =
    Debug.todo ""


addSlackMessages :
    ThreadRoute
    -> List Slack.Message
    -> BackendModel
    ->
        { d
            | messages : Array (Message ChannelMessageId (Id UserId))
            , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
            , linkedMessageIds : OneToOne ExternalMessageId (Id ChannelMessageId)
        }
    ->
        { d
            | messages : Array (Message ChannelMessageId (Id UserId))
            , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
            , linkedMessageIds : OneToOne ExternalMessageId (Id ChannelMessageId)
        }
addSlackMessages _ messages model channel =
    List.foldr
        (\message channel2 ->
            case ( message.messageType, OneToOne.second message.createdBy model.slackUsers ) of
                ( Slack.UserJoinedMessage, Nothing ) ->
                    channel2

                ( Slack.JoinerNotificationForInviter, Nothing ) ->
                    channel2

                ( Slack.BotMessage, Nothing ) ->
                    channel2

                ( Slack.UserMessage messageId data, Just userId ) ->
                    case OneToOne.second (SlackMessageId messageId) channel2.linkedMessageIds of
                        Just _ ->
                            channel2

                        Nothing ->
                            LocalState.createChannelMessageBackend
                                (UserTextMessage
                                    { createdAt = message.createdAt
                                    , createdBy = userId
                                    , content = Debug.todo "" --RichText.fromSlack model.slackUsers data
                                    , reactions = SeqDict.empty
                                    , editedAt = Nothing
                                    , repliedTo = Nothing --maybeReplyTo
                                    , attachedFiles = SeqDict.empty
                                    }
                                )
                                channel2

                --handleDiscordCreateGuildMessageHelper
                --    message.id
                --    message.channelId
                --    (case threadRoute of
                --        ViewThread threadId ->
                --            ViewThreadWithMaybeMessage
                --                threadId
                --                Nothing
                --
                --        --(discordReplyTo message channel2 |> Maybe.map Id.changeType)
                --        NoThread ->
                --            NoThreadWithMaybeMessage Nothing
                --     --(discordReplyTo message channel2)
                --    )
                --    userId
                --    (RichText.fromDiscord model.discordUsers message.content)
                --    message
                --    channel2
                _ ->
                    channel2
        )
        channel
        messages


updateFromFrontend :
    SessionId
    -> ClientId
    -> ToBackend
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
updateFromFrontend sessionId clientId msg model =
    ( model, Task.perform (BackendGotTime sessionId clientId msg) Time.now )


getLoginData :
    SessionId
    -> UserSession
    -> BackendUser
    -> Maybe ( AnyGuildOrDmId, ThreadRoute )
    -> BackendModel
    -> LoginData
getLoginData sessionId session user requestMessagesFor model =
    let
        ( otherDiscordUsers, linkedDiscordUsers ) =
            SeqDict.foldl
                (\discordUserId userData ( otherDiscordUsers2, linkedDiscordUsers2 ) ->
                    case userData of
                        FullData data ->
                            if data.linkedTo == session.userId then
                                ( otherDiscordUsers2
                                , SeqDict.insert
                                    discordUserId
                                    { name = PersonName.fromStringLossy data.user.username
                                    , icon = data.icon
                                    , email =
                                        case data.user.email of
                                            Included maybeText ->
                                                case maybeText of
                                                    Just text ->
                                                        EmailAddress.fromString text

                                                    Nothing ->
                                                        Nothing

                                            Missing ->
                                                Nothing
                                    }
                                    linkedDiscordUsers2
                                )

                            else
                                ( SeqDict.insert
                                    discordUserId
                                    { name = PersonName.fromStringLossy data.user.username, icon = data.icon }
                                    otherDiscordUsers2
                                , linkedDiscordUsers2
                                )

                        BasicData data ->
                            ( SeqDict.insert
                                discordUserId
                                { name = PersonName.fromStringLossy data.user.username, icon = data.icon }
                                otherDiscordUsers2
                            , linkedDiscordUsers2
                            )
                )
                ( SeqDict.empty, SeqDict.empty )
                model.discordUsers
    in
    { session = session
    , adminData =
        if user.isAdmin then
            IsAdminLoginData (adminData model user.lastLogPageViewed)

        else
            IsNotAdminLoginData
    , twoFactorAuthenticationEnabled =
        SeqDict.get session.userId model.twoFactorAuthentication |> Maybe.map .finishedAt
    , guilds =
        SeqDict.filterMap
            (\guildId guild ->
                LocalState.guildToFrontendForUser
                    (case requestMessagesFor of
                        Just ( GuildOrDmId (GuildOrDmId_Guild guildIdB channelId), threadRoute ) ->
                            if guildId == guildIdB then
                                Just ( channelId, threadRoute )

                            else
                                Nothing

                        _ ->
                            Nothing
                    )
                    session.userId
                    guild
            )
            model.guilds
    , discordGuilds =
        SeqDict.filterMap
            (\guildId guild ->
                LocalState.discordGuildToFrontendForUser Nothing guild
            )
            model.discordGuilds
    , dmChannels =
        SeqDict.foldl
            (\dmChannelId dmChannel dict ->
                case DmChannel.otherUserId session.userId dmChannelId of
                    Just otherUserId ->
                        SeqDict.insert otherUserId
                            (DmChannel.toFrontend
                                (case requestMessagesFor of
                                    Just ( GuildOrDmId (GuildOrDmId_Dm otherUserIdB), threadRoute ) ->
                                        if otherUserId == otherUserIdB then
                                            Just threadRoute

                                        else
                                            Nothing

                                    _ ->
                                        Nothing
                                )
                                dmChannel
                            )
                            dict

                    Nothing ->
                        dict
            )
            SeqDict.empty
            model.dmChannels
    , user = User.backendToFrontendCurrent user
    , otherUsers =
        NonemptyDict.toList model.users
            |> List.filterMap
                (\( otherUserId, otherUser ) ->
                    if otherUserId == session.userId then
                        Nothing

                    else
                        Just ( otherUserId, User.backendToFrontendForUser otherUser )
                )
            |> SeqDict.fromList
    , otherDiscordUsers = otherDiscordUsers
    , linkedDiscordUsers = linkedDiscordUsers
    , otherSessions =
        SeqDict.remove sessionId model.sessions
            |> SeqDict.toList
            |> List.filterMap
                (\( _, otherSession ) ->
                    case UserSession.toFrontend session.userId otherSession of
                        Just frontendSession ->
                            Just ( otherSession.sessionIdHash, frontendSession )

                        Nothing ->
                            Nothing
                )
            |> SeqDict.fromList
    , publicVapidKey = model.publicVapidKey
    , textEditor = model.textEditor
    }


updateFromFrontendWithTime :
    Time.Posix
    -> SessionId
    -> ClientId
    -> ToBackend
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
updateFromFrontendWithTime time sessionId clientId msg model =
    let
        model2 : BackendModel
        model2 =
            { model
                | connections =
                    SeqDict.updateIfExists
                        sessionId
                        (NonemptyDict.updateIfExists clientId (\_ -> LastRequest time))
                        model.connections
            }
    in
    case msg of
        CheckLoginRequest requestMessagesFor ->
            let
                cmd : Command BackendOnly ToFrontend backendMsg
                cmd =
                    case Broadcast.getUserFromSessionId sessionId model2 of
                        Just ( session, user ) ->
                            getLoginData sessionId session user requestMessagesFor model2
                                |> Ok
                                |> CheckLoginResponse
                                |> Lamdera.sendToFrontend clientId

                        Nothing ->
                            CheckLoginResponse (Err ()) |> Lamdera.sendToFrontend clientId
            in
            if model2.backendInitialized then
                ( { model2 | backendInitialized = False }
                , Command.batch
                    [ Http.get
                        { url = FileStatus.domain ++ "/file/vapid"
                        , expect = Http.expectString GotVapidKeys
                        }
                    , cmd
                    ]
                )

            else
                ( model2, cmd )

        LoginWithTokenRequest requestMessagesFor loginCode userAgent ->
            loginWithToken time sessionId clientId loginCode requestMessagesFor userAgent model2

        FinishUserCreationRequest requestMessagesFor personName userAgent ->
            case SeqDict.get sessionId model2.pendingLogins of
                Just (WaitingForUserDataForSignup pendingLogin) ->
                    if
                        NonemptyDict.values model2.users
                            |> List.Nonempty.any (\a -> a.email == pendingLogin.emailAddress)
                    then
                        -- It's maybe possible to end up here if a user initiates two account creations for the same email address and then completes both. We'll just silently fail in that case, not worth the effort to give a good error message.
                        ( model2, Command.none )

                    else
                        let
                            userId : Id UserId
                            userId =
                                Id.nextId (NonemptyDict.toSeqDict model2.users)

                            session : UserSession
                            session =
                                UserSession.init sessionId userId requestMessagesFor userAgent

                            newUser : BackendUser
                            newUser =
                                User.init time personName pendingLogin.emailAddress False

                            model3 : BackendModel
                            model3 =
                                { model2
                                    | sessions = SeqDict.insert sessionId session model2.sessions
                                    , pendingLogins = SeqDict.remove sessionId model2.pendingLogins
                                    , users = NonemptyDict.insert userId newUser model2.users
                                }
                        in
                        ( model3
                        , getLoginData sessionId session newUser requestMessagesFor model3
                            |> LoginSuccess
                            |> LoginWithTokenResponse
                            |> Lamdera.sendToFrontends sessionId
                        )

                _ ->
                    ( model2, Command.none )

        LoginWithTwoFactorRequest requestMessagesFor loginCode userAgent ->
            case SeqDict.get sessionId model2.pendingLogins of
                Just (WaitingForTwoFactorToken pendingLogin) ->
                    if
                        (pendingLogin.loginAttempts < LoginForm.maxLoginAttempts)
                            && (Duration.from pendingLogin.creationTime time |> Quantity.lessThan Duration.hour)
                    then
                        case
                            ( NonemptyDict.get pendingLogin.userId model2.users
                            , SeqDict.get pendingLogin.userId model2.twoFactorAuthentication
                            )
                        of
                            ( Just user, Just { secret } ) ->
                                if TwoFactorAuthentication.isValidCode time loginCode secret then
                                    let
                                        session : UserSession
                                        session =
                                            UserSession.init sessionId pendingLogin.userId requestMessagesFor userAgent
                                    in
                                    ( { model2
                                        | sessions = SeqDict.insert sessionId session model2.sessions
                                        , pendingLogins = SeqDict.remove sessionId model2.pendingLogins
                                      }
                                    , Command.batch
                                        [ getLoginData sessionId session user requestMessagesFor model2
                                            |> LoginSuccess
                                            |> LoginWithTokenResponse
                                            |> Lamdera.sendToFrontends sessionId
                                        , Broadcast.toUser
                                            (Just clientId)
                                            Nothing
                                            pendingLogin.userId
                                            (Server_NewSession
                                                session.sessionIdHash
                                                { notificationMode = session.notificationMode
                                                , currentlyViewing = session.currentlyViewing
                                                , userAgent = session.userAgent
                                                }
                                                |> ServerChange
                                            )
                                            model2
                                        ]
                                    )

                                else
                                    ( { model2
                                        | pendingLogins =
                                            SeqDict.insert
                                                sessionId
                                                (WaitingForTwoFactorToken
                                                    { pendingLogin | loginAttempts = pendingLogin.loginAttempts + 1 }
                                                )
                                                model2.pendingLogins
                                      }
                                    , LoginTokenInvalid loginCode
                                        |> LoginWithTokenResponse
                                        |> Lamdera.sendToFrontend clientId
                                    )

                            _ ->
                                ( model2
                                , LoginTokenInvalid loginCode
                                    |> LoginWithTokenResponse
                                    |> Lamdera.sendToFrontend clientId
                                )

                    else
                        ( model2
                        , LoginTokenInvalid loginCode
                            |> LoginWithTokenResponse
                            |> Lamdera.sendToFrontend clientId
                        )

                _ ->
                    ( model2
                    , LoginTokenInvalid loginCode |> LoginWithTokenResponse |> Lamdera.sendToFrontend clientId
                    )

        GetLoginTokenRequest email ->
            let
                ( model3, result ) =
                    getLoginCode time model2
            in
            case
                ( NonemptyDict.toList model3.users
                    |> List.Extra.find (\( _, user ) -> user.email == email)
                , result
                )
            of
                ( Just ( userId, user ), Ok loginCode ) ->
                    if shouldRateLimit time user then
                        let
                            ( model4, cmd ) =
                                addLog time (Log.LoginsRateLimited userId) model3
                        in
                        ( model4
                        , Command.batch [ cmd, Lamdera.sendToFrontend clientId GetLoginTokenRateLimited ]
                        )

                    else
                        ( { model3
                            | pendingLogins =
                                SeqDict.insert
                                    sessionId
                                    (WaitingForLoginToken
                                        { creationTime = time
                                        , userId = userId
                                        , loginAttempts = 0
                                        , loginCode = loginCode
                                        }
                                    )
                                    model3.pendingLogins
                            , users =
                                NonemptyDict.insert
                                    userId
                                    { user | recentLoginEmails = time :: List.take 100 user.recentLoginEmails }
                                    model3.users
                          }
                        , sendLoginEmail (SentLoginEmail time email) email loginCode
                        )

                ( Nothing, Ok loginCode ) ->
                    ( { model3
                        | pendingLogins =
                            SeqDict.insert
                                sessionId
                                (WaitingForLoginTokenForSignup
                                    { creationTime = time
                                    , loginAttempts = 0
                                    , emailAddress = email
                                    , loginCode = loginCode
                                    }
                                )
                                model3.pendingLogins
                      }
                    , sendLoginEmail (SentLoginEmail time email) email loginCode
                    )

                ( _, Err () ) ->
                    ( model3, Command.none )

        AdminToBackend adminToBackend ->
            asAdmin
                model2
                sessionId
                (\_ _ -> updateFromFrontendAdmin clientId adminToBackend model2)

        LogOutRequest ->
            asUser
                model2
                sessionId
                (\session _ ->
                    ( { model2 | sessions = SeqDict.remove sessionId model2.sessions }
                    , Command.batch
                        [ Lamdera.sendToFrontends sessionId LoggedOutSession
                        , Broadcast.toUser
                            Nothing
                            (Just sessionId)
                            session.userId
                            (Server_LoggedOut session.sessionIdHash |> ServerChange)
                            model2
                        ]
                    )
                )

        LocalModelChangeRequest changeId localMsg ->
            case localMsg of
                Local_Invalid ->
                    ( model2, invalidChangeResponse changeId clientId )

                Local_Admin adminChange ->
                    asAdmin
                        model2
                        sessionId
                        (adminChangeUpdate clientId changeId adminChange model2 time)

                Local_SendMessage _ guildOrDmId text threadRoute attachedFiles ->
                    case guildOrDmId of
                        GuildOrDmId_Guild guildId channelId ->
                            asGuildMember
                                model2
                                sessionId
                                guildId
                                (sendGuildMessage
                                    model2
                                    time
                                    clientId
                                    changeId
                                    guildId
                                    channelId
                                    threadRoute
                                    text
                                    (validateAttachedFiles model2.files attachedFiles)
                                )

                        GuildOrDmId_Dm otherUserId ->
                            asUser
                                model2
                                sessionId
                                (sendDirectMessage
                                    model2
                                    time
                                    clientId
                                    changeId
                                    otherUserId
                                    threadRoute
                                    text
                                    (validateAttachedFiles model2.files attachedFiles)
                                )

                Local_Discord_SendMessage _ guildOrDmId text threadRouteWithMaybeReplyTo attachedFiles ->
                    case guildOrDmId of
                        DiscordGuildOrDmId_Guild currentDiscordUserId guildId channelId ->
                            asDiscordGuildMember
                                model2
                                sessionId
                                guildId
                                currentDiscordUserId
                                (\session discordUser user guild ->
                                    let
                                        attachedFiles2 =
                                            validateAttachedFiles model2.files attachedFiles
                                    in
                                    case SeqDict.get channelId guild.channels of
                                        Just channel ->
                                            ( model
                                            , case threadRouteWithMaybeReplyTo of
                                                NoThreadWithMaybeMessage maybeReplyTo ->
                                                    Discord.createMarkdownMessagePayload
                                                        (Discord.userToken discordUser.auth)
                                                        { channelId = channelId
                                                        , content = RichText.toDiscord attachedFiles2 text
                                                        , replyTo =
                                                            case maybeReplyTo of
                                                                Just replyTo ->
                                                                    OneToOne.first replyTo channel.linkedMessageIds

                                                                Nothing ->
                                                                    Nothing
                                                        }
                                                        |> DiscordSync.http
                                                        |> Task.attempt
                                                            (SentDiscordGuildMessage
                                                                time
                                                                changeId
                                                                sessionId
                                                                clientId
                                                                guildId
                                                                channelId
                                                                threadRouteWithMaybeReplyTo
                                                                text
                                                                attachedFiles2
                                                                currentDiscordUserId
                                                            )

                                                ViewThreadWithMaybeMessage threadId maybeReplyTo ->
                                                    Debug.todo ""
                                              --Discord.createMessagePayload
                                              --    discordUser.auth
                                              --    { channelId = Debug.todo ""
                                              --    , content = text
                                              --    , replyTo = Maybe.andThen (OneToOne.first channel.linkedMessageIds) maybeReplyTo
                                              --    }
                                            )

                                        Nothing ->
                                            ( model
                                            , invalidChangeResponse changeId clientId
                                            )
                                )

                        DiscordGuildOrDmId_Dm otherUserId ->
                            Debug.todo ""

                --asUser
                --    model2
                --    sessionId
                --    (sendDirectMessage
                --        model2
                --        time
                --        clientId
                --        changeId
                --        otherUserId
                --        threadRoute
                --        text
                --        (validateAttachedFiles model2.files attachedFiles)
                --    )
                Local_NewChannel _ guildId channelName ->
                    asGuildOwner
                        model2
                        sessionId
                        guildId
                        (\userId _ guild ->
                            ( { model2
                                | guilds =
                                    SeqDict.insert
                                        guildId
                                        (LocalState.createChannel time userId channelName guild)
                                        model2.guilds
                              }
                            , Command.batch
                                [ Local_NewChannel time guildId channelName
                                    |> LocalChangeResponse changeId
                                    |> Lamdera.sendToFrontend clientId
                                , Broadcast.toGuildExcludingOne
                                    clientId
                                    guildId
                                    (Server_NewChannel time guildId channelName |> ServerChange)
                                    model2
                                ]
                            )
                        )

                Local_EditChannel guildId channelId channelName ->
                    asGuildOwner
                        model2
                        sessionId
                        guildId
                        (\_ _ guild ->
                            ( { model2
                                | guilds =
                                    SeqDict.insert
                                        guildId
                                        (LocalState.editChannel channelName channelId guild)
                                        model2.guilds
                              }
                            , Command.batch
                                [ LocalChangeResponse changeId localMsg
                                    |> Lamdera.sendToFrontend clientId
                                , Broadcast.toGuildExcludingOne
                                    clientId
                                    guildId
                                    (Server_EditChannel guildId channelId channelName |> ServerChange)
                                    model2
                                ]
                            )
                        )

                Local_DeleteChannel guildId channelId ->
                    asGuildOwner
                        model2
                        sessionId
                        guildId
                        (\userId _ guild ->
                            ( { model2
                                | guilds =
                                    SeqDict.insert
                                        guildId
                                        (LocalState.deleteChannel time userId channelId guild)
                                        model2.guilds
                              }
                            , Command.batch
                                [ LocalChangeResponse changeId localMsg
                                    |> Lamdera.sendToFrontend clientId
                                , Broadcast.toGuildExcludingOne
                                    clientId
                                    guildId
                                    (Server_DeleteChannel guildId channelId |> ServerChange)
                                    model2
                                ]
                            )
                        )

                Local_NewInviteLink _ guildId _ ->
                    asGuildMember
                        model2
                        sessionId
                        guildId
                        (\{ userId } _ guild ->
                            let
                                ( model3, id ) =
                                    SecretId.getShortUniqueId time model2
                            in
                            ( { model3
                                | guilds =
                                    SeqDict.insert
                                        guildId
                                        (LocalState.addInvite id userId time guild)
                                        model3.guilds
                              }
                            , Command.batch
                                [ Local_NewInviteLink time guildId (FilledInByBackend id)
                                    |> LocalChangeResponse changeId
                                    |> Lamdera.sendToFrontend clientId
                                , Broadcast.toGuildExcludingOne
                                    clientId
                                    guildId
                                    (Server_NewInviteLink time userId guildId id |> ServerChange)
                                    model3
                                ]
                            )
                        )

                Local_NewGuild _ guildName _ ->
                    asUser
                        model2
                        sessionId
                        (\{ userId } _ ->
                            let
                                guildId : Id GuildId
                                guildId =
                                    Id.nextId model2.guilds

                                newGuild : BackendGuild
                                newGuild =
                                    LocalState.createGuild time userId guildName
                            in
                            ( { model2
                                | guilds = SeqDict.insert guildId newGuild model2.guilds
                              }
                            , Command.batch
                                [ Local_NewGuild time guildName (FilledInByBackend guildId)
                                    |> LocalChangeResponse changeId
                                    |> Lamdera.sendToFrontend clientId
                                , Broadcast.toUser
                                    (Just clientId)
                                    Nothing
                                    userId
                                    (Local_NewGuild time guildName (FilledInByBackend guildId) |> LocalChange userId)
                                    model2
                                ]
                            )
                        )

                Local_MemberTyping _ ( guildOrDmId, threadRoute ) ->
                    case guildOrDmId of
                        GuildOrDmId (GuildOrDmId_Guild guildId channelId) ->
                            asGuildMember
                                model2
                                sessionId
                                guildId
                                (\{ userId } _ guild ->
                                    ( { model2
                                        | guilds =
                                            SeqDict.insert
                                                guildId
                                                (LocalState.updateChannel
                                                    (LocalState.memberIsTyping userId time threadRoute)
                                                    channelId
                                                    guild
                                                )
                                                model2.guilds
                                      }
                                    , Command.batch
                                        [ Local_MemberTyping time ( guildOrDmId, threadRoute )
                                            |> LocalChangeResponse changeId
                                            |> Lamdera.sendToFrontend clientId
                                        , Broadcast.toGuildExcludingOne
                                            clientId
                                            guildId
                                            (Server_MemberTyping time userId ( guildOrDmId, threadRoute ) |> ServerChange)
                                            model2
                                        ]
                                    )
                                )

                        GuildOrDmId (GuildOrDmId_Dm otherUserId) ->
                            asUser
                                model2
                                sessionId
                                (\{ userId } _ ->
                                    let
                                        dmChannelId =
                                            DmChannel.channelIdFromUserIds userId otherUserId
                                    in
                                    ( { model2
                                        | dmChannels =
                                            SeqDict.updateIfExists
                                                dmChannelId
                                                (LocalState.memberIsTyping userId time threadRoute)
                                                model2.dmChannels
                                      }
                                    , Command.batch
                                        [ Local_MemberTyping time ( guildOrDmId, threadRoute )
                                            |> LocalChangeResponse changeId
                                            |> Lamdera.sendToFrontend clientId
                                        , Broadcast.toUser
                                            (Just clientId)
                                            Nothing
                                            otherUserId
                                            (Server_MemberTyping
                                                time
                                                userId
                                                ( GuildOrDmId (GuildOrDmId_Dm userId), threadRoute )
                                                |> ServerChange
                                            )
                                            model2
                                        ]
                                    )
                                )

                        DiscordGuildOrDmId (DiscordGuildOrDmId_Guild currentDiscordUserId guildId channelId) ->
                            asDiscordGuildMember
                                model2
                                sessionId
                                guildId
                                currentDiscordUserId
                                (\session _ _ guild ->
                                    ( { model2
                                        | discordGuilds =
                                            SeqDict.insert
                                                guildId
                                                (LocalState.updateChannel
                                                    (LocalState.memberIsTyping currentDiscordUserId time threadRoute)
                                                    channelId
                                                    guild
                                                )
                                                model2.discordGuilds
                                      }
                                    , Command.batch
                                        [ Local_MemberTyping time ( guildOrDmId, threadRoute )
                                            |> LocalChangeResponse changeId
                                            |> Lamdera.sendToFrontend clientId
                                        , Broadcast.toDiscordGuildExcludingOne
                                            clientId
                                            guildId
                                            (Server_MemberTyping time session.userId ( guildOrDmId, threadRoute )
                                                |> ServerChange
                                            )
                                            model2
                                        ]
                                    )
                                )

                        DiscordGuildOrDmId (DiscordGuildOrDmId_Dm dmChannelId) ->
                            Debug.todo ""

                --asUser
                --    model2
                --    sessionId
                --    (\{ userId } _ ->
                --        let
                --            dmChannelId =
                --                DmChannel.channelIdFromUserIds userId otherUserId
                --        in
                --        ( { model2
                --            | dmChannels =
                --                SeqDict.updateIfExists
                --                    dmChannelId
                --                    (LocalState.memberIsTyping userId time threadRoute)
                --                    model2.dmChannels
                --          }
                --        , Command.batch
                --            [ Local_MemberTyping time ( guildOrDmId, threadRoute )
                --                |> LocalChangeResponse changeId
                --                |> Lamdera.sendToFrontend clientId
                --            , Broadcast.toUser
                --                (Just clientId)
                --                Nothing
                --                otherUserId
                --                (Server_MemberTyping
                --                    time
                --                    userId
                --                    ( GuildOrDmId (GuildOrDmId_Dm userId), threadRoute )
                --                    |> ServerChange
                --                )
                --                model2
                --            ]
                --        )
                --    )
                Local_AddReactionEmoji guildOrDmId threadRoute emoji ->
                    case guildOrDmId of
                        GuildOrDmId (GuildOrDmId_Guild guildId channelId) ->
                            asGuildMember
                                model2
                                sessionId
                                guildId
                                (\{ userId } _ guild ->
                                    ( { model2
                                        | guilds =
                                            SeqDict.insert
                                                guildId
                                                (LocalState.updateChannel (LocalState.addReactionEmoji emoji userId threadRoute) channelId guild)
                                                model2.guilds
                                      }
                                    , Command.batch
                                        [ Lamdera.sendToFrontend clientId (LocalChangeResponse changeId localMsg)
                                        , Broadcast.toGuild
                                            guildId
                                            (Server_AddReactionEmoji userId guildOrDmId threadRoute emoji |> ServerChange)
                                            model2
                                        ]
                                    )
                                )

                        GuildOrDmId (GuildOrDmId_Dm otherUserId) ->
                            asUser
                                model2
                                sessionId
                                (\{ userId } _ ->
                                    let
                                        dmChannelId =
                                            DmChannel.channelIdFromUserIds userId otherUserId
                                    in
                                    ( { model2
                                        | dmChannels =
                                            SeqDict.updateIfExists
                                                dmChannelId
                                                (LocalState.addReactionEmoji emoji userId threadRoute)
                                                model2.dmChannels
                                      }
                                    , Command.batch
                                        [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                                        , Broadcast.toDmChannel
                                            clientId
                                            userId
                                            otherUserId
                                            (\otherUserId2 ->
                                                Server_AddReactionEmoji
                                                    userId
                                                    (GuildOrDmId (GuildOrDmId_Dm otherUserId2))
                                                    threadRoute
                                                    emoji
                                            )
                                            model2
                                        ]
                                    )
                                )

                        DiscordGuildOrDmId _ ->
                            Debug.todo ""

                Local_RemoveReactionEmoji guildOrDmId threadRoute emoji ->
                    case guildOrDmId of
                        GuildOrDmId (GuildOrDmId_Guild guildId channelId) ->
                            asGuildMember
                                model2
                                sessionId
                                guildId
                                (\{ userId } _ guild ->
                                    ( { model2
                                        | guilds =
                                            SeqDict.insert
                                                guildId
                                                (LocalState.updateChannel
                                                    (LocalState.removeReactionEmoji emoji userId threadRoute)
                                                    channelId
                                                    guild
                                                )
                                                model2.guilds
                                      }
                                    , Command.batch
                                        [ Local_RemoveReactionEmoji guildOrDmId threadRoute emoji
                                            |> LocalChangeResponse changeId
                                            |> Lamdera.sendToFrontend clientId
                                        , Broadcast.toGuildExcludingOne
                                            clientId
                                            guildId
                                            (Server_RemoveReactionEmoji userId guildOrDmId threadRoute emoji
                                                |> ServerChange
                                            )
                                            model2
                                        ]
                                    )
                                )

                        GuildOrDmId (GuildOrDmId_Dm otherUserId) ->
                            asUser
                                model2
                                sessionId
                                (\{ userId } _ ->
                                    let
                                        dmChannelId : DmChannelId
                                        dmChannelId =
                                            DmChannel.channelIdFromUserIds userId otherUserId
                                    in
                                    ( { model2
                                        | dmChannels =
                                            SeqDict.updateIfExists
                                                dmChannelId
                                                (LocalState.removeReactionEmoji emoji userId threadRoute)
                                                model2.dmChannels
                                      }
                                    , Command.batch
                                        [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                                        , Broadcast.toDmChannel
                                            clientId
                                            userId
                                            otherUserId
                                            (\otherUserId2 ->
                                                Server_RemoveReactionEmoji
                                                    userId
                                                    (GuildOrDmId (GuildOrDmId_Dm otherUserId2))
                                                    threadRoute
                                                    emoji
                                            )
                                            model2
                                        ]
                                    )
                                )

                        DiscordGuildOrDmId _ ->
                            Debug.todo ""

                Local_SendEditMessage _ guildOrDmId threadRoute newContent attachedFiles ->
                    let
                        attachedFiles2 : SeqDict (Id FileId) FileData
                        attachedFiles2 =
                            validateAttachedFiles model2.files attachedFiles
                    in
                    case guildOrDmId of
                        GuildOrDmId_Guild guildId channelId ->
                            asGuildMember
                                model2
                                sessionId
                                guildId
                                (\{ userId } _ guild ->
                                    sendEditMessage
                                        clientId
                                        changeId
                                        time
                                        newContent
                                        attachedFiles2
                                        guildId
                                        channelId
                                        threadRoute
                                        model2
                                        userId
                                        guild
                                )

                        GuildOrDmId_Dm otherUserId ->
                            asUser
                                model2
                                sessionId
                                (\{ userId } _ ->
                                    let
                                        dmChannelId : DmChannelId
                                        dmChannelId =
                                            DmChannel.channelIdFromUserIds userId otherUserId
                                    in
                                    case SeqDict.get dmChannelId model2.dmChannels of
                                        Just dmChannel ->
                                            case
                                                LocalState.editMessageHelper
                                                    time
                                                    userId
                                                    newContent
                                                    attachedFiles2
                                                    threadRoute
                                                    dmChannel
                                            of
                                                Ok dmChannel2 ->
                                                    ( { model2
                                                        | dmChannels =
                                                            SeqDict.insert dmChannelId dmChannel2 model2.dmChannels
                                                      }
                                                    , Command.batch
                                                        [ Local_SendEditMessage
                                                            time
                                                            guildOrDmId
                                                            threadRoute
                                                            newContent
                                                            attachedFiles2
                                                            |> LocalChangeResponse changeId
                                                            |> Lamdera.sendToFrontend clientId
                                                        , Broadcast.toDmChannel
                                                            clientId
                                                            userId
                                                            otherUserId
                                                            (\otherUserId2 ->
                                                                Server_SendEditMessage
                                                                    time
                                                                    userId
                                                                    (GuildOrDmId_Dm otherUserId2)
                                                                    threadRoute
                                                                    newContent
                                                                    attachedFiles2
                                                            )
                                                            model2
                                                        ]
                                                    )

                                                Err () ->
                                                    ( model2
                                                    , LocalChangeResponse changeId Local_Invalid
                                                        |> Lamdera.sendToFrontend clientId
                                                    )

                                        Nothing ->
                                            ( model2
                                            , LocalChangeResponse changeId Local_Invalid |> Lamdera.sendToFrontend clientId
                                            )
                                )

                Local_MemberEditTyping _ guildOrDmId threadRoute ->
                    case guildOrDmId of
                        GuildOrDmId (GuildOrDmId_Guild guildId channelId) ->
                            asGuildMember
                                model2
                                sessionId
                                guildId
                                (\{ userId } _ guild ->
                                    case
                                        LocalState.memberIsEditTyping
                                            userId
                                            time
                                            channelId
                                            threadRoute
                                            guild
                                    of
                                        Ok guild2 ->
                                            ( { model2 | guilds = SeqDict.insert guildId guild2 model2.guilds }
                                            , Command.batch
                                                [ Local_MemberEditTyping time guildOrDmId threadRoute
                                                    |> LocalChangeResponse changeId
                                                    |> Lamdera.sendToFrontend clientId
                                                , Broadcast.toGuildExcludingOne
                                                    clientId
                                                    guildId
                                                    (Server_MemberEditTyping time userId guildOrDmId threadRoute
                                                        |> ServerChange
                                                    )
                                                    model2
                                                ]
                                            )

                                        Err () ->
                                            ( model2
                                            , LocalChangeResponse changeId Local_Invalid |> Lamdera.sendToFrontend clientId
                                            )
                                )

                        GuildOrDmId (GuildOrDmId_Dm otherUserId) ->
                            asUser
                                model2
                                sessionId
                                (\{ userId } _ ->
                                    let
                                        dmChannelId : DmChannelId
                                        dmChannelId =
                                            DmChannel.channelIdFromUserIds userId otherUserId
                                    in
                                    case SeqDict.get dmChannelId model2.dmChannels of
                                        Just dmChannel ->
                                            case LocalState.memberIsEditTypingHelper time userId threadRoute dmChannel of
                                                Ok dmChannel2 ->
                                                    ( { model2
                                                        | dmChannels =
                                                            SeqDict.insert dmChannelId dmChannel2 model2.dmChannels
                                                      }
                                                    , Command.batch
                                                        [ Local_MemberEditTyping time guildOrDmId threadRoute
                                                            |> LocalChangeResponse changeId
                                                            |> Lamdera.sendToFrontend clientId
                                                        , Broadcast.toUser
                                                            (Just clientId)
                                                            Nothing
                                                            otherUserId
                                                            (Server_MemberEditTyping
                                                                time
                                                                userId
                                                                guildOrDmId
                                                                threadRoute
                                                                |> ServerChange
                                                            )
                                                            model2
                                                        ]
                                                    )

                                                _ ->
                                                    ( model2
                                                    , LocalChangeResponse changeId Local_Invalid |> Lamdera.sendToFrontend clientId
                                                    )

                                        Nothing ->
                                            ( model2
                                            , LocalChangeResponse changeId Local_Invalid |> Lamdera.sendToFrontend clientId
                                            )
                                )

                        DiscordGuildOrDmId _ ->
                            Debug.todo ""

                Local_SetLastViewed guildOrDmId threadRoute ->
                    asUser
                        model2
                        sessionId
                        (\{ userId } user ->
                            ( { model2
                                | users =
                                    NonemptyDict.insert
                                        userId
                                        (case threadRoute of
                                            ViewThreadWithMessage threadMessageId messageId ->
                                                { user
                                                    | lastViewedThreads =
                                                        SeqDict.insert
                                                            ( guildOrDmId, threadMessageId )
                                                            messageId
                                                            user.lastViewedThreads
                                                }

                                            NoThreadWithMessage messageId ->
                                                { user
                                                    | lastViewed = SeqDict.insert guildOrDmId messageId user.lastViewed
                                                }
                                        )
                                        model2.users
                              }
                            , Command.batch
                                [ LocalChangeResponse changeId localMsg
                                    |> Lamdera.sendToFrontend clientId
                                , Broadcast.toUser (Just clientId) Nothing userId (LocalChange userId localMsg) model2
                                ]
                            )
                        )

                Local_DeleteMessage guildOrDmId threadRoute ->
                    case guildOrDmId of
                        GuildOrDmId (GuildOrDmId_Guild guildId channelId) ->
                            asGuildMember
                                model2
                                sessionId
                                guildId
                                (\{ userId } _ guild ->
                                    case LocalState.deleteMessageBackend userId channelId threadRoute guild of
                                        Ok guild2 ->
                                            ( { model2 | guilds = SeqDict.insert guildId guild2 model2.guilds }
                                            , Command.batch
                                                [ Lamdera.sendToFrontend
                                                    clientId
                                                    (LocalChangeResponse changeId localMsg)
                                                , Broadcast.toGuildExcludingOne
                                                    clientId
                                                    guildId
                                                    (Server_DeleteMessage userId guildOrDmId threadRoute |> ServerChange)
                                                    model2
                                                ]
                                            )

                                        Err _ ->
                                            ( model2
                                            , Lamdera.sendToFrontend
                                                clientId
                                                (LocalChangeResponse changeId Local_Invalid)
                                            )
                                )

                        GuildOrDmId (GuildOrDmId_Dm otherUserId) ->
                            asUser
                                model2
                                sessionId
                                (\{ userId } _ ->
                                    let
                                        dmChannelId : DmChannelId
                                        dmChannelId =
                                            DmChannel.channelIdFromUserIds userId otherUserId
                                    in
                                    case SeqDict.get dmChannelId model2.dmChannels of
                                        Just dmChannel ->
                                            case LocalState.deleteMessageBackendHelper userId threadRoute dmChannel of
                                                Ok dmChannel2 ->
                                                    ( { model2 | dmChannels = SeqDict.insert dmChannelId dmChannel2 model2.dmChannels }
                                                    , Command.batch
                                                        [ Lamdera.sendToFrontend
                                                            clientId
                                                            (LocalChangeResponse changeId localMsg)
                                                        , Broadcast.toDmChannel
                                                            clientId
                                                            userId
                                                            otherUserId
                                                            (\otherUserId2 ->
                                                                Server_DeleteMessage
                                                                    userId
                                                                    (GuildOrDmId (GuildOrDmId_Dm otherUserId2))
                                                                    threadRoute
                                                            )
                                                            model2
                                                        ]
                                                    )

                                                Err _ ->
                                                    ( model2
                                                    , Lamdera.sendToFrontend
                                                        clientId
                                                        (LocalChangeResponse changeId Local_Invalid)
                                                    )

                                        Nothing ->
                                            ( model2
                                            , Lamdera.sendToFrontend
                                                clientId
                                                (LocalChangeResponse changeId Local_Invalid)
                                            )
                                )

                        DiscordGuildOrDmId _ ->
                            Debug.todo ""

                Local_CurrentlyViewing viewing ->
                    let
                        viewingChannel : Maybe ( AnyGuildOrDmId, ThreadRoute )
                        viewingChannel =
                            UserSession.setViewingToCurrentlyViewing viewing

                        updateSession : UserSession -> UserSession
                        updateSession session =
                            UserSession.setCurrentlyViewing viewingChannel session

                        broadcastCmd : UserSession -> Command BackendOnly ToFrontend msg
                        broadcastCmd session =
                            Broadcast.toUser
                                Nothing
                                (Just sessionId)
                                session.userId
                                (Server_CurrentlyViewing session.sessionIdHash viewingChannel |> ServerChange)
                                model2
                    in
                    case viewing of
                        ViewDm otherUserId _ ->
                            asUser
                                model2
                                sessionId
                                (\session user ->
                                    case SeqDict.get (DmChannel.channelIdFromUserIds otherUserId session.userId) model2.dmChannels of
                                        Just channel ->
                                            ( { model2
                                                | users =
                                                    NonemptyDict.insert
                                                        session.userId
                                                        (User.setLastDmViewed otherUserId NoThread user)
                                                        model2.users
                                                , sessions =
                                                    SeqDict.insert sessionId (updateSession session) model2.sessions
                                              }
                                            , Command.batch
                                                [ ViewDm otherUserId (loadMessagesHelper channel)
                                                    |> Local_CurrentlyViewing
                                                    |> LocalChangeResponse changeId
                                                    |> Lamdera.sendToFrontend clientId
                                                , broadcastCmd session
                                                ]
                                            )

                                        Nothing ->
                                            ( model2
                                            , Lamdera.sendToFrontend clientId (LocalChangeResponse changeId Local_Invalid)
                                            )
                                )

                        ViewDmThread otherUserId threadId _ ->
                            asUser
                                model2
                                sessionId
                                (\session user ->
                                    case SeqDict.get (DmChannel.channelIdFromUserIds session.userId otherUserId) model2.dmChannels of
                                        Just dmChannel ->
                                            ( { model2
                                                | users =
                                                    NonemptyDict.insert
                                                        session.userId
                                                        (User.setLastDmViewed otherUserId (ViewThread threadId) user)
                                                        model2.users
                                                , sessions =
                                                    SeqDict.insert sessionId (updateSession session) model2.sessions
                                              }
                                            , Command.batch
                                                [ ViewDmThread
                                                    otherUserId
                                                    threadId
                                                    (SeqDict.get threadId dmChannel.threads
                                                        |> Maybe.withDefault DmChannel.threadInit
                                                        |> loadMessagesHelper
                                                    )
                                                    |> Local_CurrentlyViewing
                                                    |> LocalChangeResponse changeId
                                                    |> Lamdera.sendToFrontend clientId
                                                , broadcastCmd session
                                                ]
                                            )

                                        Nothing ->
                                            ( model2
                                            , Lamdera.sendToFrontend clientId (LocalChangeResponse changeId Local_Invalid)
                                            )
                                )

                        ViewDiscordDm otherUserId _ ->
                            Debug.todo ""

                        ViewDiscordDmThread otherUserId threadId _ ->
                            Debug.todo ""

                        ViewChannel guildId channelId _ ->
                            asGuildMember
                                model2
                                sessionId
                                guildId
                                (\session user guild ->
                                    case SeqDict.get channelId guild.channels of
                                        Just channel ->
                                            ( { model2
                                                | users =
                                                    NonemptyDict.insert
                                                        session.userId
                                                        (User.setLastChannelViewed guildId channelId NoThread user)
                                                        model2.users
                                                , sessions =
                                                    SeqDict.insert sessionId (updateSession session) model2.sessions
                                              }
                                            , Command.batch
                                                [ ViewChannel guildId channelId (loadMessagesHelper channel)
                                                    |> Local_CurrentlyViewing
                                                    |> LocalChangeResponse changeId
                                                    |> Lamdera.sendToFrontend clientId
                                                , broadcastCmd session
                                                ]
                                            )

                                        Nothing ->
                                            ( model2
                                            , Lamdera.sendToFrontend clientId (LocalChangeResponse changeId Local_Invalid)
                                            )
                                )

                        ViewChannelThread guildId channelId threadId _ ->
                            asGuildMember
                                model2
                                sessionId
                                guildId
                                (\session user guild ->
                                    case SeqDict.get channelId guild.channels of
                                        Just channel ->
                                            ( { model2
                                                | users =
                                                    NonemptyDict.insert
                                                        session.userId
                                                        (User.setLastChannelViewed
                                                            guildId
                                                            channelId
                                                            (ViewThread threadId)
                                                            user
                                                        )
                                                        model2.users
                                                , sessions =
                                                    SeqDict.insert sessionId (updateSession session) model2.sessions
                                              }
                                            , Command.batch
                                                [ ViewChannelThread
                                                    guildId
                                                    channelId
                                                    threadId
                                                    (SeqDict.get threadId channel.threads
                                                        |> Maybe.withDefault DmChannel.threadInit
                                                        |> loadMessagesHelper
                                                    )
                                                    |> Local_CurrentlyViewing
                                                    |> LocalChangeResponse changeId
                                                    |> Lamdera.sendToFrontend clientId
                                                , broadcastCmd session
                                                ]
                                            )

                                        Nothing ->
                                            ( model2
                                            , Command.batch
                                                [ Lamdera.sendToFrontend clientId (LocalChangeResponse changeId Local_Invalid)
                                                , broadcastCmd session
                                                ]
                                            )
                                )

                        StopViewingChannel ->
                            asUser
                                model2
                                sessionId
                                (\session _ ->
                                    ( { model2
                                        | sessions = SeqDict.insert sessionId (updateSession session) model2.sessions
                                      }
                                    , LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                                    )
                                )

                        ViewDiscordChannel guildId channelId currentDiscordUserId _ ->
                            asDiscordGuildMember
                                model2
                                sessionId
                                guildId
                                currentDiscordUserId
                                (\session discordData user guild ->
                                    case SeqDict.get channelId guild.channels of
                                        Just channel ->
                                            ( { model2
                                                | users =
                                                    NonemptyDict.insert
                                                        session.userId
                                                        (User.setLastDiscordChannelViewed guildId channelId NoThread user)
                                                        model2.users
                                                , sessions =
                                                    SeqDict.insert sessionId (updateSession session) model2.sessions
                                              }
                                            , Command.batch
                                                [ ViewDiscordChannel guildId channelId currentDiscordUserId (loadMessagesHelper channel)
                                                    |> Local_CurrentlyViewing
                                                    |> LocalChangeResponse changeId
                                                    |> Lamdera.sendToFrontend clientId
                                                , broadcastCmd session
                                                ]
                                            )

                                        Nothing ->
                                            ( model2
                                            , Lamdera.sendToFrontend clientId (LocalChangeResponse changeId Local_Invalid)
                                            )
                                )

                        ViewDiscordChannelThread guildId channelId currentDiscordUserId threadId _ ->
                            Debug.todo ""

                Local_SetName name ->
                    asUser
                        model2
                        sessionId
                        (\{ userId } user ->
                            ( { model2
                                | users = NonemptyDict.insert userId { user | name = name } model2.users
                              }
                            , Command.batch
                                [ Lamdera.sendToFrontend clientId (LocalChangeResponse changeId localMsg)
                                , Broadcast.toEveryoneWhoCanSeeUser
                                    clientId
                                    userId
                                    (ServerChange (Server_SetName userId name))
                                    model2
                                ]
                            )
                        )

                Local_LoadChannelMessages guildOrDmId oldestVisibleMessage _ ->
                    case guildOrDmId of
                        GuildOrDmId_Guild guildId channelId ->
                            asGuildMember
                                model2
                                sessionId
                                guildId
                                (\_ _ guild ->
                                    ( model2
                                    , case SeqDict.get channelId guild.channels of
                                        Just channel ->
                                            handleMessagesRequest oldestVisibleMessage channel
                                                |> Local_LoadChannelMessages guildOrDmId oldestVisibleMessage
                                                |> LocalChangeResponse changeId
                                                |> Lamdera.sendToFrontend clientId

                                        Nothing ->
                                            LocalChangeResponse changeId Local_Invalid
                                                |> Lamdera.sendToFrontend clientId
                                    )
                                )

                        GuildOrDmId_Dm otherUserId ->
                            asUser
                                model2
                                sessionId
                                (\{ userId } _ ->
                                    ( model2
                                    , SeqDict.get (DmChannel.channelIdFromUserIds userId otherUserId) model2.dmChannels
                                        |> Maybe.withDefault DmChannel.init
                                        |> handleMessagesRequest oldestVisibleMessage
                                        |> Local_LoadChannelMessages guildOrDmId oldestVisibleMessage
                                        |> LocalChangeResponse changeId
                                        |> Lamdera.sendToFrontend clientId
                                    )
                                )

                Local_LoadThreadMessages guildOrDmId threadId oldestVisibleMessage _ ->
                    case guildOrDmId of
                        GuildOrDmId_Guild guildId channelId ->
                            asGuildMember
                                model2
                                sessionId
                                guildId
                                (\_ _ guild ->
                                    ( model2
                                    , case SeqDict.get channelId guild.channels of
                                        Just channel ->
                                            SeqDict.get threadId channel.threads
                                                |> Maybe.withDefault DmChannel.threadInit
                                                |> handleMessagesRequest oldestVisibleMessage
                                                |> Local_LoadThreadMessages guildOrDmId threadId oldestVisibleMessage
                                                |> LocalChangeResponse changeId
                                                |> Lamdera.sendToFrontend clientId

                                        Nothing ->
                                            LocalChangeResponse changeId Local_Invalid
                                                |> Lamdera.sendToFrontend clientId
                                    )
                                )

                        GuildOrDmId_Dm otherUserId ->
                            asUser
                                model2
                                sessionId
                                (\{ userId } _ ->
                                    ( model2
                                    , SeqDict.get (DmChannel.channelIdFromUserIds userId otherUserId) model2.dmChannels
                                        |> Maybe.withDefault DmChannel.init
                                        |> .threads
                                        |> SeqDict.get threadId
                                        |> Maybe.withDefault DmChannel.threadInit
                                        |> handleMessagesRequest oldestVisibleMessage
                                        |> Local_LoadThreadMessages guildOrDmId threadId oldestVisibleMessage
                                        |> LocalChangeResponse changeId
                                        |> Lamdera.sendToFrontend clientId
                                    )
                                )

                Local_Discord_LoadChannelMessages guildOrDmId oldestVisibleMessage _ ->
                    case guildOrDmId of
                        DiscordGuildOrDmId_Guild currentUserId guildId channelId ->
                            asDiscordGuildMember
                                model2
                                sessionId
                                guildId
                                currentUserId
                                (\_ _ _ guild ->
                                    ( model2
                                    , case SeqDict.get channelId guild.channels of
                                        Just channel ->
                                            handleMessagesRequest oldestVisibleMessage channel
                                                |> Local_Discord_LoadChannelMessages guildOrDmId oldestVisibleMessage
                                                |> LocalChangeResponse changeId
                                                |> Lamdera.sendToFrontend clientId

                                        Nothing ->
                                            LocalChangeResponse changeId Local_Invalid
                                                |> Lamdera.sendToFrontend clientId
                                    )
                                )

                        DiscordGuildOrDmId_Dm dmChannelId ->
                            Debug.todo ""

                --asUser
                --    model2
                --    sessionId
                --    (\{ userId } _ ->
                --        ( model2
                --        , SeqDict.get dmChannelId model2.dmChannels
                --            |> Maybe.withDefault DmChannel.init
                --            |> handleMessagesRequest oldestVisibleMessage
                --            |> Local_LoadChannelMessages guildOrDmId oldestVisibleMessage
                --            |> LocalChangeResponse changeId
                --            |> Lamdera.sendToFrontend clientId
                --        )
                --    )
                Local_Discord_LoadThreadMessages guildOrDmId threadId oldestVisibleMessage _ ->
                    case guildOrDmId of
                        DiscordGuildOrDmId_Guild currentDiscordUserId guildId channelId ->
                            asDiscordGuildMember
                                model2
                                sessionId
                                guildId
                                currentDiscordUserId
                                (\_ _ _ guild ->
                                    ( model2
                                    , case SeqDict.get channelId guild.channels of
                                        Just channel ->
                                            SeqDict.get threadId channel.threads
                                                |> Maybe.withDefault DmChannel.discordThreadInit
                                                |> handleMessagesRequest oldestVisibleMessage
                                                |> Local_Discord_LoadThreadMessages guildOrDmId threadId oldestVisibleMessage
                                                |> LocalChangeResponse changeId
                                                |> Lamdera.sendToFrontend clientId

                                        Nothing ->
                                            LocalChangeResponse changeId Local_Invalid
                                                |> Lamdera.sendToFrontend clientId
                                    )
                                )

                        DiscordGuildOrDmId_Dm otherUserId ->
                            Debug.todo ""

                --asUser
                --    model2
                --    sessionId
                --    (\{ userId } _ ->
                --        ( model2
                --        , SeqDict.get (DmChannel.channelIdFromUserIds userId otherUserId) model2.dmChannels
                --            |> Maybe.withDefault DmChannel.init
                --            |> .threads
                --            |> SeqDict.get threadId
                --            |> Maybe.withDefault DmChannel.threadInit
                --            |> handleMessagesRequest oldestVisibleMessage
                --            |> Local_LoadThreadMessages guildOrDmId threadId oldestVisibleMessage
                --            |> LocalChangeResponse changeId
                --            |> Lamdera.sendToFrontend clientId
                --        )
                --    )
                Local_SetGuildNotificationLevel guildId notificationLevel ->
                    asUser
                        model2
                        sessionId
                        (\{ userId } user ->
                            ( { model
                                | users =
                                    NonemptyDict.insert
                                        userId
                                        (User.setGuildNotificationLevel guildId notificationLevel user)
                                        model2.users
                              }
                            , Command.batch
                                [ LocalChangeResponse changeId localMsg
                                    |> Lamdera.sendToFrontend clientId
                                , Broadcast.toUser
                                    (Just clientId)
                                    Nothing
                                    userId
                                    (Server_SetGuildNotificationLevel guildId notificationLevel |> ServerChange)
                                    model2
                                ]
                            )
                        )

                Local_SetNotificationMode notificationMode ->
                    asUser
                        model2
                        sessionId
                        (\session _ ->
                            ( { model2
                                | sessions =
                                    SeqDict.insert
                                        sessionId
                                        { session | notificationMode = notificationMode }
                                        model2.sessions
                              }
                            , LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                            )
                        )

                Local_RegisterPushSubscription pushSubscription ->
                    asUser
                        model2
                        sessionId
                        (\session _ ->
                            ( { model2
                                | sessions =
                                    SeqDict.insert
                                        sessionId
                                        { session | pushSubscription = Subscribed pushSubscription }
                                        model2.sessions
                              }
                            , Command.batch
                                [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                                , Broadcast.pushNotification
                                    sessionId
                                    session.userId
                                    time
                                    "Success!"
                                    "Push notifications enabled"
                                    "https://at-chat.app/at-logo-no-background.png"
                                    Nothing
                                    pushSubscription
                                    model2
                                ]
                            )
                        )

                Local_TextEditor localChange ->
                    asUser
                        model2
                        sessionId
                        (\session user ->
                            let
                                ( textEditor, serverChange ) =
                                    TextEditor.backendChangeUpdate session.userId localChange model.textEditor
                            in
                            ( { model | textEditor = textEditor }
                            , Command.batch
                                [ Lamdera.sendToFrontend clientId (LocalChangeResponse changeId localMsg)
                                , Broadcast.toEveryone clientId (Server_TextEditor serverChange) model
                                ]
                            )
                        )

                Local_DiscordChange currentUserId discordChange ->
                    case discordChange of
                        Local_Discord_NewChannel posix id channelName ->
                            Debug.todo ""

                        Local_Discord_EditChannel guildId channelId channelName ->
                            Debug.todo ""

                        Local_Discord_DeleteChannel guildId channelId ->
                            Debug.todo ""

                        Local_Discord_SendEditMessage posix discordGuildOrDmIdNoThread threadRouteWithMessage nonempty seqDict ->
                            Debug.todo ""

                        Local_Discord_SetName personName ->
                            Debug.todo ""

                        Local_Discord_SetGuildNotificationLevel id notificationLevel ->
                            Debug.todo ""

        TwoFactorToBackend toBackend2 ->
            asUser
                model2
                sessionId
                (twoFactorAuthenticationUpdateFromFrontend clientId time toBackend2 model2)

        AiChatToBackend aiChatToBackend ->
            ( model2
            , Command.map
                AiChatToFrontend
                AiChatBackendMsg
                (AiChat.updateFromFrontend clientId aiChatToBackend model2.openRouterKey)
            )

        JoinGuildByInviteRequest guildId inviteLinkId ->
            asUser
                model2
                sessionId
                (joinGuildByInvite inviteLinkId time sessionId clientId guildId model2)

        ReloadDataRequest requestMessagesFor ->
            ( model2
            , case Broadcast.getUserFromSessionId sessionId model2 of
                Just ( userId, user ) ->
                    getLoginData sessionId userId user requestMessagesFor model2
                        |> Ok
                        |> ReloadDataResponse
                        |> Lamdera.sendToFrontend clientId

                Nothing ->
                    Lamdera.sendToFrontend clientId (ReloadDataResponse (Err ()))
            )

        LinkSlackOAuthCode oAuthCode sessionId2 ->
            case Broadcast.getSessionFromSessionIdHash sessionId2 model2 of
                Just ( _, session ) ->
                    ( model2
                    , case model2.slackClientSecret of
                        Just clientSecret ->
                            Slack.exchangeCodeForToken clientSecret Env.slackClientId oAuthCode
                                |> Task.attempt (GotSlackOAuth time session.userId)

                        Nothing ->
                            Command.none
                    )

                Nothing ->
                    ( model2, Command.none )

        LinkDiscordRequest data ->
            asUser
                model2
                sessionId
                (\session user ->
                    ( model2
                    , Discord.getCurrentUserPayload (Discord.userToken data)
                        |> DiscordSync.http
                        |> Task.attempt (LinkDiscordUserStep1 clientId session.userId data)
                    )
                )


loadMessagesHelper :
    { a | messages : Array (Message messageId userId) }
    -> ToBeFilledInByBackend (SeqDict (Id messageId) (Message messageId userId))
loadMessagesHelper channel =
    let
        messageCount : Int
        messageCount =
            Array.length channel.messages

        indexStart : Int
        indexStart =
            max (messageCount - VisibleMessages.pageSize) 0
    in
    FilledInByBackend
        (Array.slice indexStart messageCount channel.messages
            |> Array.toList
            |> List.indexedMap
                (\index message ->
                    ( index + indexStart |> Id.fromInt, message )
                )
            |> SeqDict.fromList
        )


handleMessagesRequest :
    Id messageId
    -> { b | messages : Array (Message messageId userId) }
    -> ToBeFilledInByBackend (SeqDict (Id messageId) (Message messageId userId))
handleMessagesRequest oldestVisibleMessage channel =
    let
        oldestVisibleMessage2 =
            Id.toInt oldestVisibleMessage

        nextOldestVisible =
            max (oldestVisibleMessage2 - VisibleMessages.pageSize) 0
    in
    Array.slice nextOldestVisible oldestVisibleMessage2 channel.messages
        |> Array.toList
        |> List.indexedMap (\index message -> ( Id.fromInt (index + nextOldestVisible), message ))
        |> SeqDict.fromList
        |> FilledInByBackend


sendEditMessage :
    ClientId
    -> ChangeId
    -> Time.Posix
    -> Nonempty (RichText (Id UserId))
    -> SeqDict (Id FileId) FileData
    -> Id GuildId
    -> Id ChannelId
    -> ThreadRouteWithMessage
    -> BackendModel
    -> Id UserId
    -> BackendGuild
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
sendEditMessage clientId changeId time newContent attachedFiles2 guildId channelId threadRoute model2 userId guild =
    case SeqDict.get channelId guild.channels of
        Just channel ->
            case
                LocalState.editMessageHelper
                    time
                    userId
                    newContent
                    attachedFiles2
                    threadRoute
                    channel
            of
                Ok channel2 ->
                    ( { model2
                        | guilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.updateChannel (\_ -> channel2) channelId)
                                model2.guilds
                      }
                    , Command.batch
                        [ Local_SendEditMessage
                            time
                            (GuildOrDmId_Guild guildId channelId)
                            threadRoute
                            newContent
                            attachedFiles2
                            |> LocalChangeResponse changeId
                            |> Lamdera.sendToFrontend clientId
                        , Broadcast.toGuildExcludingOne
                            clientId
                            guildId
                            (Server_SendEditMessage
                                time
                                userId
                                (GuildOrDmId_Guild guildId channelId)
                                threadRoute
                                newContent
                                attachedFiles2
                                |> ServerChange
                            )
                            model2
                        ]
                    )

                Err () ->
                    ( model2
                    , LocalChangeResponse changeId Local_Invalid |> Lamdera.sendToFrontend clientId
                    )

        Nothing ->
            ( model2
            , LocalChangeResponse changeId Local_Invalid |> Lamdera.sendToFrontend clientId
            )


toDiscordContent :
    BackendModel
    -> SeqDict (Id FileId) FileData
    -> Nonempty (RichText (Discord.Id.Id Discord.Id.UserId))
    -> String
toDiscordContent model attachedFiles content =
    Discord.Markdown.toString (RichText.toDiscord attachedFiles content)


joinGuildByInvite :
    SecretId InviteLinkId
    -> Time.Posix
    -> SessionId
    -> ClientId
    -> Id GuildId
    -> BackendModel
    -> UserSession
    -> BackendUser
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
joinGuildByInvite inviteLinkId time sessionId clientId guildId model session user =
    case SeqDict.get guildId model.guilds of
        Just guild ->
            case ( SeqDict.get inviteLinkId guild.invites, LocalState.addMember time session.userId guild ) of
                ( Just _, Ok guild2 ) ->
                    let
                        modelWithoutUser : BackendModel
                        modelWithoutUser =
                            model

                        model2 : BackendModel
                        model2 =
                            { model
                                | guilds = SeqDict.insert guildId guild2 model.guilds
                                , users =
                                    NonemptyDict.insert
                                        session.userId
                                        (LocalState.markAllChannelsAsViewed guildId guild2 user)
                                        model.users
                            }
                    in
                    ( model2
                    , Command.batch
                        [ Broadcast.toGuildExcludingOne
                            clientId
                            guildId
                            (Server_MemberJoined
                                time
                                session.userId
                                guildId
                                (User.backendToFrontendForUser user)
                                |> ServerChange
                            )
                            modelWithoutUser
                        , case
                            ( NonemptyDict.get guild2.owner model2.users
                            , LocalState.guildToFrontendForUser
                                (Just ( LocalState.announcementChannel guild2, NoThread ))
                                session.userId
                                guild2
                            )
                          of
                            ( Just owner, Just frontendGuild ) ->
                                { guildId = guildId
                                , guild = frontendGuild
                                , owner = User.backendToFrontendForUser owner
                                , members =
                                    SeqDict.filterMap
                                        (\userId2 _ ->
                                            NonemptyDict.get userId2 model2.users
                                                |> Maybe.map User.backendToFrontendForUser
                                        )
                                        guild2.members
                                }
                                    |> Ok
                                    |> Server_YouJoinedGuildByInvite
                                    |> ServerChange
                                    |> ChangeBroadcast
                                    |> Lamdera.sendToFrontends sessionId

                            _ ->
                                Command.none
                        ]
                    )

                ( _, Err () ) ->
                    ( model
                    , Err AlreadyJoined
                        |> Server_YouJoinedGuildByInvite
                        |> ServerChange
                        |> ChangeBroadcast
                        |> Lamdera.sendToFrontends sessionId
                    )

                ( Nothing, _ ) ->
                    ( model
                    , Err InviteIsInvalid
                        |> Server_YouJoinedGuildByInvite
                        |> ServerChange
                        |> ChangeBroadcast
                        |> Lamdera.sendToFrontends sessionId
                    )

        Nothing ->
            ( model, Command.none )


twoFactorAuthenticationUpdateFromFrontend :
    ClientId
    -> Time.Posix
    -> TwoFactorAuthentication.ToBackend
    -> BackendModel
    -> UserSession
    -> BackendUser
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
twoFactorAuthenticationUpdateFromFrontend clientId time toBackend model session user =
    case toBackend of
        TwoFactorAuthentication.EnableTwoFactorAuthenticationRequest ->
            let
                ( model2, secret ) =
                    SecretId.getUniqueId time model
            in
            case TwoFactorAuthentication.getConfig (EmailAddress.toString user.email) secret of
                Ok key ->
                    ( { model2
                        | twoFactorAuthenticationSetup =
                            SeqDict.insert
                                session.userId
                                { startedAt = time, secret = secret }
                                model2.twoFactorAuthenticationSetup
                      }
                    , TwoFactorAuthentication.EnableTwoFactorAuthenticationResponse
                        { qrCodeUrl =
                            TOTP.Key.toString key
                                -- https://github.com/choonkeat/elm-totp/issues/3
                                |> String.replace "%3D" ""
                        }
                        |> TwoFactorAuthenticationToFrontend
                        |> Lamdera.sendToFrontend clientId
                    )

                Err _ ->
                    ( model2, Command.none )

        TwoFactorAuthentication.ConfirmTwoFactorAuthenticationRequest code ->
            case SeqDict.get session.userId model.twoFactorAuthenticationSetup of
                Just data ->
                    if Duration.from data.startedAt time |> Quantity.lessThan Duration.hour then
                        if TwoFactorAuthentication.isValidCode time code data.secret then
                            ( { model
                                | twoFactorAuthentication =
                                    SeqDict.insert
                                        session.userId
                                        { finishedAt = time, secret = data.secret }
                                        model.twoFactorAuthentication
                                , twoFactorAuthenticationSetup =
                                    SeqDict.remove session.userId model.twoFactorAuthenticationSetup
                              }
                            , TwoFactorAuthentication.ConfirmTwoFactorAuthenticationResponse code True
                                |> TwoFactorAuthenticationToFrontend
                                |> Lamdera.sendToFrontend clientId
                            )

                        else
                            ( model
                            , TwoFactorAuthentication.ConfirmTwoFactorAuthenticationResponse code False
                                |> TwoFactorAuthenticationToFrontend
                                |> Lamdera.sendToFrontend clientId
                            )

                    else
                        ( model, Command.none )

                Nothing ->
                    ( model, Command.none )


adminChangeUpdate :
    ClientId
    -> ChangeId
    -> Pages.Admin.AdminChange
    -> BackendModel
    -> Time.Posix
    -> Id UserId
    -> BackendUser
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
adminChangeUpdate clientId changeId adminChange model time userId user =
    let
        localMsg =
            Local_Admin adminChange
    in
    case adminChange of
        Pages.Admin.ChangeUsers changes ->
            case Pages.Admin.applyChangesToBackendUsers userId changes model.users of
                Ok newUsers ->
                    let
                        model2 : BackendModel
                        model2 =
                            Log.addLog time (Log.ChangedUsers userId) model
                    in
                    ( { model2
                        | users = newUsers
                        , sessions =
                            SeqDict.filter
                                (\_ session -> SeqSet.member session.userId changes.deletedUsers |> not)
                                model2.sessions
                      }
                    , Command.batch
                        [ Pages.Admin.ChangeUsers { changes | time = time }
                            |> Local_Admin
                            |> LocalChangeResponse changeId
                            |> Lamdera.sendToFrontend clientId
                        , Broadcast.toOtherAdmins clientId model2 (LocalChange userId localMsg)
                        ]
                    )

                Err _ ->
                    ( model, invalidChangeResponse changeId clientId )

        Pages.Admin.ExpandSection section ->
            ( { model
                | users =
                    NonemptyDict.insert
                        userId
                        { user | expandedSections = SeqSet.insert section user.expandedSections }
                        model.users
              }
            , LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
            )

        Pages.Admin.CollapseSection section ->
            ( { model
                | users =
                    NonemptyDict.insert
                        userId
                        { user | expandedSections = SeqSet.remove section user.expandedSections }
                        model.users
              }
            , LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
            )

        Pages.Admin.LogPageChanged logPageIndex ->
            ( { model
                | users = NonemptyDict.insert userId { user | lastLogPageViewed = logPageIndex } model.users
              }
            , LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
            )

        Pages.Admin.SetEmailNotificationsEnabled isEnabled ->
            let
                model2 =
                    { model | emailNotificationsEnabled = isEnabled }
            in
            ( model2
            , Command.batch
                [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                , Broadcast.toOtherAdmins clientId model2 (LocalChange userId localMsg)
                ]
            )

        Pages.Admin.SetPrivateVapidKey privateKey ->
            ( { model
                | privateVapidKey = privateKey
                , sessions = SeqDict.map (\_ session -> { session | pushSubscription = NotSubscribed }) model.sessions
              }
            , Command.batch
                [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                , Server_PushNotificationsReset model.publicVapidKey
                    |> ServerChange
                    |> ChangeBroadcast
                    |> Lamdera.broadcast
                ]
            )

        Pages.Admin.SetPublicVapidKey publicKey ->
            ( { model
                | publicVapidKey = publicKey
                , sessions = SeqDict.map (\_ session -> { session | pushSubscription = NotSubscribed }) model.sessions
              }
            , Command.batch
                [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                , Server_PushNotificationsReset model.publicVapidKey
                    |> ServerChange
                    |> ChangeBroadcast
                    |> Lamdera.broadcast
                ]
            )

        Pages.Admin.SetSlackClientSecret clientSecret ->
            ( { model | slackClientSecret = clientSecret }
            , LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
            )

        Pages.Admin.SetOpenRouterKey openRouterKey ->
            ( { model | openRouterKey = openRouterKey }
            , LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
            )


sendDirectMessage :
    BackendModel
    -> Time.Posix
    -> ClientId
    -> ChangeId
    -> Id UserId
    -> ThreadRouteWithMaybeMessage
    -> Nonempty (RichText (Id UserId))
    -> SeqDict (Id FileId) FileData
    -> UserSession
    -> BackendUser
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
sendDirectMessage model time clientId changeId otherUserId threadRouteWithReplyTo text attachedFiles session user =
    let
        dmChannelId : DmChannelId
        dmChannelId =
            DmChannel.channelIdFromUserIds session.userId otherUserId

        dmChannel : DmChannel
        dmChannel =
            SeqDict.get dmChannelId model.dmChannels
                |> Maybe.withDefault DmChannel.init
    in
    case threadRouteWithReplyTo of
        ViewThreadWithMaybeMessage threadMessageIndex _ ->
            let
                thread : Thread
                thread =
                    SeqDict.get threadMessageIndex dmChannel.threads |> Maybe.withDefault DmChannel.threadInit
            in
            ( { model
                | dmChannels = SeqDict.insert dmChannelId dmChannel model.dmChannels
                , users =
                    NonemptyDict.insert
                        session.userId
                        { user
                            | lastViewedThreads =
                                SeqDict.insert
                                    ( GuildOrDmId (GuildOrDmId_Dm otherUserId), threadMessageIndex )
                                    (DmChannel.latestThreadMessageId thread)
                                    user.lastViewedThreads
                        }
                        model.users
              }
            , if session.userId == otherUserId then
                Command.none

              else
                Broadcast.broadcastDm
                    changeId
                    time
                    clientId
                    session.userId
                    otherUserId
                    text
                    threadRouteWithReplyTo
                    attachedFiles
                    model
            )

        NoThreadWithMaybeMessage repliedTo ->
            let
                messageIndex : Id ChannelMessageId
                messageIndex =
                    DmChannel.latestMessageId dmChannel2

                dmChannel2 : DmChannel
                dmChannel2 =
                    LocalState.createChannelMessageBackend
                        (UserTextMessage
                            { createdAt = time
                            , createdBy = session.userId
                            , content = text
                            , reactions = SeqDict.empty
                            , editedAt = Nothing
                            , repliedTo = repliedTo
                            , attachedFiles = attachedFiles
                            }
                        )
                        dmChannel
            in
            ( { model
                | dmChannels = SeqDict.insert dmChannelId dmChannel2 model.dmChannels
                , users =
                    NonemptyDict.insert
                        session.userId
                        { user
                            | lastViewed =
                                SeqDict.insert
                                    (GuildOrDmId (GuildOrDmId_Dm otherUserId))
                                    messageIndex
                                    user.lastViewed
                        }
                        model.users
              }
            , Command.batch
                [ Broadcast.broadcastDm changeId time clientId session.userId otherUserId text threadRouteWithReplyTo attachedFiles model
                ]
            )


validateAttachedFiles : SeqDict FileHash BackendFileData -> SeqDict (Id FileId) FileData -> SeqDict (Id FileId) FileData
validateAttachedFiles uploadedFiles dict =
    SeqDict.filterMap
        (\id fileData ->
            if Id.toInt id < 1 then
                Nothing

            else
                case SeqDict.get fileData.fileHash uploadedFiles of
                    Just { fileSize } ->
                        Just { fileData | fileSize = fileSize }

                    Nothing ->
                        Nothing
        )
        dict


sendGuildMessage :
    BackendModel
    -> Time.Posix
    -> ClientId
    -> ChangeId
    -> Id GuildId
    -> Id ChannelId
    -> ThreadRouteWithMaybeMessage
    -> Nonempty (RichText (Id UserId))
    -> SeqDict (Id FileId) FileData
    -> UserSession
    -> BackendUser
    -> BackendGuild
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
sendGuildMessage model time clientId changeId guildId channelId threadRouteWithMaybeReplyTo text attachedFiles session user guild =
    case SeqDict.get channelId guild.channels of
        Just channel ->
            let
                channel2 : BackendChannel
                channel2 =
                    case threadRouteWithMaybeReplyTo of
                        ViewThreadWithMaybeMessage threadId maybeReplyTo ->
                            LocalState.createThreadMessageBackend
                                threadId
                                (UserTextMessage
                                    { createdAt = time
                                    , createdBy = session.userId
                                    , content = text
                                    , reactions = SeqDict.empty
                                    , editedAt = Nothing
                                    , repliedTo = maybeReplyTo
                                    , attachedFiles = attachedFiles
                                    }
                                )
                                channel

                        NoThreadWithMaybeMessage maybeReplyTo ->
                            LocalState.createChannelMessageBackend
                                (UserTextMessage
                                    { createdAt = time
                                    , createdBy = session.userId
                                    , content = text
                                    , reactions = SeqDict.empty
                                    , editedAt = Nothing
                                    , repliedTo = maybeReplyTo
                                    , attachedFiles = attachedFiles
                                    }
                                )
                                channel

                guildOrDmId : GuildOrDmId
                guildOrDmId =
                    GuildOrDmId_Guild guildId channelId

                threadRouteNoReply : ThreadRoute
                threadRouteNoReply =
                    case threadRouteWithMaybeReplyTo of
                        ViewThreadWithMaybeMessage threadId _ ->
                            ViewThread threadId

                        NoThreadWithMaybeMessage _ ->
                            NoThread

                usersMentioned : SeqSet (Id UserId)
                usersMentioned =
                    LocalState.usersMentionedOrRepliedToBackend
                        threadRouteWithMaybeReplyTo
                        text
                        (guild.owner :: SeqDict.keys guild.members)
                        channel2

                users2 : NonemptyDict (Id UserId) BackendUser
                users2 =
                    SeqSet.foldl
                        (\userId2 users ->
                            let
                                isViewing =
                                    List.any
                                        (\( _, userSession ) ->
                                            userSession.currentlyViewing == Just ( GuildOrDmId guildOrDmId, threadRouteNoReply )
                                        )
                                        (Broadcast.userGetAllSessions userId2 model)
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
            in
            ( { model
                | guilds =
                    SeqDict.insert
                        guildId
                        { guild | channels = SeqDict.insert channelId channel2 guild.channels }
                        model.guilds
                , users =
                    NonemptyDict.insert
                        session.userId
                        (case threadRouteWithMaybeReplyTo of
                            ViewThreadWithMaybeMessage threadMessageIndex _ ->
                                { user
                                    | lastViewedThreads =
                                        SeqDict.insert
                                            ( GuildOrDmId guildOrDmId, threadMessageIndex )
                                            (SeqDict.get threadMessageIndex channel2.threads
                                                |> Maybe.withDefault DmChannel.threadInit
                                                |> DmChannel.latestThreadMessageId
                                            )
                                            user.lastViewedThreads
                                }

                            NoThreadWithMaybeMessage _ ->
                                { user
                                    | lastViewed =
                                        SeqDict.insert
                                            (GuildOrDmId guildOrDmId)
                                            (DmChannel.latestMessageId channel2)
                                            user.lastViewed
                                }
                        )
                        users2
              }
            , Command.batch
                [ LocalChangeResponse
                    changeId
                    (Local_SendMessage time guildOrDmId text threadRouteWithMaybeReplyTo attachedFiles)
                    |> Lamdera.sendToFrontend clientId
                , Broadcast.toGuildExcludingOne
                    clientId
                    guildId
                    (Server_SendMessage session.userId time guildOrDmId text threadRouteWithMaybeReplyTo attachedFiles
                        |> ServerChange
                    )
                    model
                , Broadcast.messageNotification
                    usersMentioned
                    time
                    session.userId
                    guildId
                    channelId
                    threadRouteNoReply
                    text
                    (guild.owner :: SeqDict.keys guild.members)
                    model

                --, case ( Debug.todo "", threadRouteWithMaybeReplyTo ) of
                --    ( Just botToken, ViewThreadWithMaybeMessage threadMessageIndex maybeRepliedTo ) ->
                --        let
                --            thread : Thread
                --            thread =
                --                SeqDict.get threadMessageIndex channel2.threads
                --                    |> Maybe.withDefault DmChannel.threadInit
                --        in
                --        case
                --            ( OneToOne.first threadMessageIndex channel2.linkedThreadIds
                --            , OneToOne.first threadMessageIndex channel2.linkedMessageIds
                --            , Debug.todo ""
                --            )
                --        of
                --            ( Nothing, Just (DiscordMessageId discordMessageId), Just (DiscordChannelId discordChannelId) ) ->
                --                Discord.startThreadFromMessagePayload
                --                    (Debug.todo "")
                --                    { name = "New thread"
                --                    , channelId = discordChannelId
                --                    , messageId = discordMessageId
                --                    , autoArchiveDuration = Missing
                --                    , rateLimitPerUser = Missing
                --                    }
                --                    |> DiscordSync.http
                --                    |> Task.andThen
                --                        (\discordThread ->
                --                            Discord.createMessagePayload
                --                                (Debug.todo "")
                --                                { channelId = discordThread.id
                --                                , content = Debug.todo "" --toDiscordContent model attachedFiles text
                --                                , replyTo = Nothing
                --                                }
                --                                |> DiscordSync.http
                --                        )
                --                    |> Task.attempt
                --                        (SentGuildMessageToDiscord
                --                            guildId
                --                            channelId
                --                            (DmChannel.latestThreadMessageId thread
                --                                |> ViewThreadWithMessage threadMessageIndex
                --                            )
                --                        )
                --
                --            ( Just (DiscordChannelId discordThreadId), _, _ ) ->
                --                Discord.createMessagePayload
                --                    (Debug.todo "")
                --                    { channelId = discordThreadId
                --                    , content = Debug.todo "" --toDiscordContent model attachedFiles text
                --                    , replyTo =
                --                        case maybeRepliedTo of
                --                            Just index ->
                --                                case OneToOne.first index thread.linkedMessageIds of
                --                                    Just (DiscordMessageId replyTo) ->
                --                                        Just replyTo
                --
                --                                    _ ->
                --                                        Nothing
                --
                --                            Nothing ->
                --                                Nothing
                --                    }
                --                    |> DiscordSync.http
                --                    |> Task.attempt
                --                        (DmChannel.latestThreadMessageId thread
                --                            |> ViewThreadWithMessage threadMessageIndex
                --                            |> SentGuildMessageToDiscord guildId channelId
                --                        )
                --
                --            _ ->
                --                Command.none
                --
                --    ( Just botToken, NoThreadWithMaybeMessage maybeRepliedTo ) ->
                --        case Debug.todo "" of
                --            Just (DiscordChannelId discordChannelId) ->
                --                Discord.createMessagePayload
                --                    (Debug.todo "")
                --                    { channelId = discordChannelId
                --                    , content = Debug.todo "" --toDiscordContent model attachedFiles text
                --                    , replyTo =
                --                        case maybeRepliedTo of
                --                            Just index ->
                --                                case OneToOne.first index channel2.linkedMessageIds of
                --                                    Just (DiscordMessageId replyTo) ->
                --                                        Just replyTo
                --
                --                                    _ ->
                --                                        Nothing
                --
                --                            Nothing ->
                --                                Nothing
                --                    }
                --                    |> DiscordSync.http
                --                    |> Task.attempt
                --                        (SentGuildMessageToDiscord
                --                            guildId
                --                            channelId
                --                            (NoThreadWithMessage (DmChannel.latestMessageId channel2))
                --                        )
                --
                --            _ ->
                --                Command.none
                --
                --    _ ->
                --        Command.none
                ]
            )

        Nothing ->
            ( model
            , invalidChangeResponse changeId clientId
            )


sentDiscordGuildMessage :
    BackendModel
    -> Time.Posix
    -> ClientId
    -> ChangeId
    -> Discord.Id.Id Discord.Id.GuildId
    -> Discord.Id.Id Discord.Id.ChannelId
    -> ThreadRouteWithMaybeMessage
    -> Nonempty (RichText (Discord.Id.Id Discord.Id.UserId))
    -> SeqDict (Id FileId) FileData
    -> Discord.Id.Id Discord.Id.UserId
    -> Discord.Message
    -> UserSession
    -> DiscordFullUserData
    -> BackendUser
    -> DiscordBackendGuild
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
sentDiscordGuildMessage model time clientId changeId guildId channelId threadRouteWithMaybeReplyTo text attachedFiles discordUserId discordMessage session discordUser user guild =
    case SeqDict.get channelId guild.channels of
        Just channel ->
            let
                channel2 : DiscordBackendChannel
                channel2 =
                    case threadRouteWithMaybeReplyTo of
                        ViewThreadWithMaybeMessage threadId maybeReplyTo ->
                            Debug.todo ""

                        --LocalState.createThreadMessageBackend
                        --    threadId
                        --    (UserTextMessage
                        --        { createdAt = time
                        --        , createdBy = discordUserId
                        --        , content = text
                        --        , reactions = SeqDict.empty
                        --        , editedAt = Nothing
                        --        , repliedTo = maybeReplyTo
                        --        , attachedFiles = attachedFiles
                        --        }
                        --    )
                        --    channel
                        NoThreadWithMaybeMessage maybeReplyTo ->
                            LocalState.createDiscordChannelMessageBackend
                                discordMessage.id
                                (UserTextMessage
                                    { createdAt = time
                                    , createdBy = discordUserId
                                    , content = text
                                    , reactions = SeqDict.empty
                                    , editedAt = Nothing
                                    , repliedTo = maybeReplyTo
                                    , attachedFiles = attachedFiles
                                    }
                                )
                                channel

                guildOrDmId : DiscordGuildOrDmId
                guildOrDmId =
                    DiscordGuildOrDmId_Guild discordUserId guildId channelId

                threadRouteNoReply : ThreadRoute
                threadRouteNoReply =
                    case threadRouteWithMaybeReplyTo of
                        ViewThreadWithMaybeMessage threadId _ ->
                            ViewThread threadId

                        NoThreadWithMaybeMessage _ ->
                            NoThread

                usersMentioned : SeqSet (Discord.Id.Id Discord.Id.UserId)
                usersMentioned =
                    LocalState.usersMentionedOrRepliedToBackend
                        threadRouteWithMaybeReplyTo
                        text
                        (guild.owner :: SeqDict.keys guild.members)
                        channel2

                users2 : NonemptyDict (Id UserId) BackendUser
                users2 =
                    SeqSet.foldl
                        (\userId2 users ->
                            case SeqDict.get userId2 model.discordUsers of
                                Just (FullData data) ->
                                    let
                                        isViewing =
                                            List.any
                                                (\( _, userSession ) ->
                                                    userSession.currentlyViewing == Just ( DiscordGuildOrDmId guildOrDmId, threadRouteNoReply )
                                                )
                                                (Broadcast.userGetAllSessions data.linkedTo model)
                                    in
                                    if isViewing then
                                        users

                                    else
                                        NonemptyDict.updateIfExists
                                            data.linkedTo
                                            (User.addDiscordDirectMention guildId channelId threadRouteNoReply)
                                            users

                                _ ->
                                    users
                        )
                        model.users
                        usersMentioned
            in
            ( { model
                | discordGuilds =
                    SeqDict.insert
                        guildId
                        { guild | channels = SeqDict.insert channelId channel2 guild.channels }
                        model.discordGuilds
                , users =
                    NonemptyDict.insert
                        session.userId
                        (case threadRouteWithMaybeReplyTo of
                            ViewThreadWithMaybeMessage threadMessageIndex _ ->
                                { user
                                    | lastViewedThreads =
                                        SeqDict.insert
                                            ( DiscordGuildOrDmId guildOrDmId, threadMessageIndex )
                                            (SeqDict.get threadMessageIndex channel2.threads
                                                |> Maybe.withDefault DmChannel.discordThreadInit
                                                |> DmChannel.latestThreadMessageId
                                            )
                                            user.lastViewedThreads
                                }

                            NoThreadWithMaybeMessage _ ->
                                { user
                                    | lastViewed =
                                        SeqDict.insert
                                            (DiscordGuildOrDmId guildOrDmId)
                                            (DmChannel.latestMessageId channel2)
                                            user.lastViewed
                                }
                        )
                        users2
              }
            , Command.batch
                [ LocalChangeResponse
                    changeId
                    (Local_Discord_SendMessage time guildOrDmId text threadRouteWithMaybeReplyTo attachedFiles)
                    |> Lamdera.sendToFrontend clientId
                , Broadcast.toDiscordGuildExcludingOne
                    clientId
                    guildId
                    (Server_Discord_SendMessage session.userId time guildOrDmId text threadRouteWithMaybeReplyTo attachedFiles
                        |> ServerChange
                    )
                    model
                , Broadcast.discordMessageNotification
                    usersMentioned
                    time
                    discordUserId
                    guildId
                    channelId
                    threadRouteNoReply
                    text
                    (guild.owner :: SeqDict.keys guild.members)
                    model
                ]
            )

        Nothing ->
            ( model
            , invalidChangeResponse changeId clientId
            )


invalidChangeResponse : ChangeId -> ClientId -> Command BackendOnly ToFrontend backendMsg
invalidChangeResponse changeId clientId =
    LocalChangeResponse changeId Local_Invalid
        |> Lamdera.sendToFrontend clientId


shouldRateLimit : Time.Posix -> BackendUser -> Bool
shouldRateLimit time user =
    let
        loginsInLast5Minutes : Int
        loginsInLast5Minutes =
            List.Extra.count
                (\loginTime -> Duration.from loginTime time |> Quantity.lessThan (Duration.minutes 5))
                user.recentLoginEmails

        loginsInLast120Minutes : Int
        loginsInLast120Minutes =
            List.Extra.count
                (\loginTime -> Duration.from loginTime time |> Quantity.lessThan (Duration.minutes 120))
                user.recentLoginEmails
    in
    loginsInLast5Minutes > 5 || loginsInLast120Minutes > 10


updateFromFrontendAdmin :
    ClientId
    -> Pages.Admin.ToBackend
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
updateFromFrontendAdmin clientId toBackend model =
    case toBackend of
        Pages.Admin.LogPaginationToBackend a ->
            ( model
            , Pagination.updateFromFrontend clientId a model.logs
                |> Command.map
                    (\toMsg -> Pages.Admin.LogPaginationToFrontend toMsg |> AdminToFrontend)
                    identity
            )


asUser :
    BackendModel
    -> SessionId
    -> (UserSession -> BackendUser -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg ))
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
asUser model sessionId func =
    case SeqDict.get sessionId model.sessions of
        Just session ->
            case NonemptyDict.get session.userId model.users of
                Just user ->
                    func session user

                Nothing ->
                    ( model, Command.none )

        Nothing ->
            ( model, Command.none )


asGuildMember :
    BackendModel
    -> SessionId
    -> Id GuildId
    -> (UserSession -> BackendUser -> BackendGuild -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg ))
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
asGuildMember model sessionId guildId func =
    case SeqDict.get sessionId model.sessions of
        Just session ->
            case ( NonemptyDict.get session.userId model.users, SeqDict.get guildId model.guilds ) of
                ( Just user, Just guild ) ->
                    func session user guild

                _ ->
                    ( model, Command.none )

        Nothing ->
            ( model, Command.none )


asDiscordGuildMember :
    BackendModel
    -> SessionId
    -> Discord.Id.Id Discord.Id.GuildId
    -> Discord.Id.Id Discord.Id.UserId
    -> (UserSession -> DiscordFullUserData -> BackendUser -> DiscordBackendGuild -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg ))
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
asDiscordGuildMember model sessionId guildId discordUserId func =
    case SeqDict.get sessionId model.sessions of
        Just session ->
            case
                ( NonemptyDict.get session.userId model.users
                , SeqDict.get guildId model.discordGuilds
                , SeqDict.get discordUserId model.discordUsers
                )
            of
                ( Just user, Just guild, Just (FullData discordUser) ) ->
                    func session discordUser user guild

                _ ->
                    ( model, Command.none )

        Nothing ->
            ( model, Command.none )


asGuildOwner :
    BackendModel
    -> SessionId
    -> Id GuildId
    -> (Id UserId -> BackendUser -> BackendGuild -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg ))
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
asGuildOwner model sessionId guildId func =
    asGuildMember model
        sessionId
        guildId
        (\{ userId } user guild ->
            if userId == guild.owner then
                func userId user guild

            else
                ( model, Command.none )
        )


asAdmin :
    BackendModel
    -> SessionId
    -> (Id UserId -> BackendUser -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg ))
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
asAdmin model sessionId func =
    asUser
        model
        sessionId
        (\{ userId } user ->
            if user.isAdmin then
                func userId user

            else
                ( model, Command.none )
        )


getLoginCode : Time.Posix -> { a | secretCounter : Int } -> ( { a | secretCounter : Int }, Result () Int )
getLoginCode time model =
    let
        ( model2, id ) =
            SecretId.getUniqueId time model
    in
    ( model2
    , case String.left LoginForm.loginCodeLength (SecretId.toString id) |> Hex.fromString of
        Ok int ->
            case String.fromInt int |> String.left LoginForm.loginCodeLength |> String.toInt of
                Just int2 ->
                    Ok int2

                Nothing ->
                    Err ()

        Err _ ->
            Err ()
    )


sendLoginEmail :
    (Result Postmark.SendEmailError () -> backendMsg)
    -> EmailAddress
    -> Int
    -> Command BackendOnly toFrontend backendMsg
sendLoginEmail msg emailAddress loginCode =
    let
        _ =
            Debug.log "login" (String.padLeft LoginForm.loginCodeLength '0' (String.fromInt loginCode))
    in
    { from = { name = "", email = Env.noReplyEmailAddress }
    , to = List.Nonempty.fromElement { name = "", email = emailAddress }
    , subject = loginEmailSubject
    , body =
        Postmark.BodyBoth
            (loginEmailContent loginCode)
            ("Here is your code " ++ String.fromInt loginCode ++ "\n\nPlease type it in the login page you were previously on.\n\nIf you weren't expecting this email you can safely ignore it.")
    , messageStream = "outbound"
    }
        |> Postmark.sendEmail msg Env.postmarkServerToken


loginEmailContent : Int -> Email.Html.Html
loginEmailContent loginCode =
    Email.Html.div
        [ Email.Html.Attributes.padding "8px" ]
        [ Email.Html.div [] [ Email.Html.text "Here is your code." ]
        , Email.Html.div
            [ Email.Html.Attributes.fontSize "36px"
            , Email.Html.Attributes.fontFamily "monospace"
            ]
            (String.fromInt loginCode
                |> String.toList
                |> List.map
                    (\char ->
                        Email.Html.span
                            [ Email.Html.Attributes.padding "0px 3px 0px 4px" ]
                            [ Email.Html.text (String.fromChar char) ]
                    )
                |> (\a ->
                        List.take (LoginForm.loginCodeLength // 2) a
                            ++ [ Email.Html.span
                                    [ Email.Html.Attributes.backgroundColor "black"
                                    , Email.Html.Attributes.padding "0px 4px 0px 5px"
                                    , Email.Html.Attributes.style "vertical-align" "middle"
                                    , Email.Html.Attributes.fontSize "2px"
                                    ]
                                    []
                               ]
                            ++ List.drop (LoginForm.loginCodeLength // 2) a
                   )
            )
        , Email.Html.text "Please type it in the login page you were previously on."
        , Email.Html.br [] []
        , Email.Html.br [] []
        , Email.Html.text "If you weren't expecting this email you can safely ignore it."
        ]


loginEmailSubject : NonemptyString
loginEmailSubject =
    NonemptyString 'L' "ogin code"


isLoginTooOld : { a | loginAttempts : number, creationTime : Time.Posix } -> Time.Posix -> Bool
isLoginTooOld pendingLogin time =
    (pendingLogin.loginAttempts < LoginForm.maxLoginAttempts)
        && (Duration.from pendingLogin.creationTime time |> Quantity.lessThan Duration.hour)


loginWithToken :
    Time.Posix
    -> SessionId
    -> ClientId
    -> Int
    -> Maybe ( AnyGuildOrDmId, ThreadRoute )
    -> UserAgent
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
loginWithToken time sessionId clientId loginCode requestMessagesFor userAgent model =
    case SeqDict.get sessionId model.pendingLogins of
        Just (WaitingForLoginToken pendingLogin) ->
            if isLoginTooOld pendingLogin time then
                if loginCode == pendingLogin.loginCode then
                    case
                        ( NonemptyDict.get pendingLogin.userId model.users
                        , SeqDict.get pendingLogin.userId model.twoFactorAuthentication
                        )
                    of
                        ( Just _, Just _ ) ->
                            ( { model
                                | pendingLogins =
                                    SeqDict.insert
                                        sessionId
                                        (WaitingForTwoFactorToken
                                            { creationTime = pendingLogin.creationTime
                                            , userId = pendingLogin.userId
                                            , loginAttempts = 0
                                            }
                                        )
                                        model.pendingLogins
                              }
                            , NeedsTwoFactorToken
                                |> LoginWithTokenResponse
                                |> Lamdera.sendToFrontends sessionId
                            )

                        ( Just user, Nothing ) ->
                            let
                                session : UserSession
                                session =
                                    UserSession.init sessionId pendingLogin.userId requestMessagesFor userAgent
                            in
                            ( { model
                                | sessions = SeqDict.insert sessionId session model.sessions
                                , pendingLogins = SeqDict.remove sessionId model.pendingLogins
                              }
                            , Command.batch
                                [ getLoginData sessionId session user requestMessagesFor model
                                    |> LoginSuccess
                                    |> LoginWithTokenResponse
                                    |> Lamdera.sendToFrontends sessionId
                                , Broadcast.toUser
                                    (Just clientId)
                                    Nothing
                                    pendingLogin.userId
                                    (Server_NewSession
                                        session.sessionIdHash
                                        { notificationMode = session.notificationMode
                                        , currentlyViewing = session.currentlyViewing
                                        , userAgent = session.userAgent
                                        }
                                        |> ServerChange
                                    )
                                    model
                                ]
                            )

                        ( Nothing, _ ) ->
                            ( model
                            , LoginTokenInvalid loginCode
                                |> LoginWithTokenResponse
                                |> Lamdera.sendToFrontend clientId
                            )

                else
                    ( { model
                        | pendingLogins =
                            SeqDict.insert
                                sessionId
                                (WaitingForLoginToken { pendingLogin | loginAttempts = pendingLogin.loginAttempts + 1 })
                                model.pendingLogins
                      }
                    , LoginTokenInvalid loginCode |> LoginWithTokenResponse |> Lamdera.sendToFrontend clientId
                    )

            else
                ( model, LoginTokenInvalid loginCode |> LoginWithTokenResponse |> Lamdera.sendToFrontend clientId )

        Just (WaitingForLoginTokenForSignup pendingLogin) ->
            if isLoginTooOld pendingLogin time then
                if loginCode == pendingLogin.loginCode then
                    ( { model
                        | pendingLogins =
                            SeqDict.insert
                                sessionId
                                (WaitingForUserDataForSignup
                                    { creationTime = pendingLogin.creationTime
                                    , emailAddress = pendingLogin.emailAddress
                                    }
                                )
                                model.pendingLogins
                      }
                    , LoginWithTokenResponse NeedsAccountSetup |> Lamdera.sendToFrontends sessionId
                    )

                else
                    ( { model
                        | pendingLogins =
                            SeqDict.insert
                                sessionId
                                (WaitingForLoginTokenForSignup
                                    { pendingLogin | loginAttempts = pendingLogin.loginAttempts + 1 }
                                )
                                model.pendingLogins
                      }
                    , LoginTokenInvalid loginCode |> LoginWithTokenResponse |> Lamdera.sendToFrontend clientId
                    )

            else
                ( model, LoginTokenInvalid loginCode |> LoginWithTokenResponse |> Lamdera.sendToFrontend clientId )

        _ ->
            ( model, LoginTokenInvalid loginCode |> LoginWithTokenResponse |> Lamdera.sendToFrontend clientId )


addLogWithCmd :
    Time.Posix
    -> Log
    -> BackendModel
    -> Command BackendOnly ToFrontend BackendMsg
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
addLogWithCmd time log model cmd =
    let
        ( model2, logCmd ) =
            addLog time log model
    in
    ( model2, Command.batch [ logCmd, cmd ] )


addLog : Time.Posix -> Log -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
addLog time log model =
    let
        model2 : BackendModel
        model2 =
            { model | logs = Array.push { time = time, log = log } model.logs }
    in
    case
        ( Log.shouldNotifyAdmin log
        , Duration.from model2.lastErrorLogEmail time |> Quantity.lessThan (Duration.minutes 30)
        )
    of
        ( Just text, False ) ->
            ( { model2 | lastErrorLogEmail = time }
            , Postmark.sendEmailTask
                Env.postmarkServerToken
                { from = { name = "", email = Env.noReplyEmailAddress }
                , to = Nonempty { name = "", email = emailToNotifyWhenErrorsAreLogged } []
                , subject = NonemptyString 'A' "n error was logged that needs attention"
                , body = "The following error was logged: " ++ text ++ ". Note that any additional errors logged for the next 30 minutes will be ignored to avoid spamming emails." |> Postmark.BodyText
                , messageStream = "outbound"
                }
                |> Task.attempt (SentLogErrorEmail time emailToNotifyWhenErrorsAreLogged)
            )

        _ ->
            ( model2, Command.none )


emailToNotifyWhenErrorsAreLogged : EmailAddress
emailToNotifyWhenErrorsAreLogged =
    Unsafe.emailAddress "martinsstewart@gmail.com"
