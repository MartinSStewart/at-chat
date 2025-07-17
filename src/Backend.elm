module Backend exposing
    ( adminUser
    , app
    , app_
    , emailToNotifyWhenErrorsAreLogged
    , loginEmailContent
    , loginEmailSubject
    )

import Array
import ChannelName
import Discord exposing (OptionalData(..))
import Discord.Id
import Duration
import Effect.Command as Command exposing (BackendOnly, Command)
import Effect.Lamdera as Lamdera exposing (ClientId, SessionId)
import Effect.Process as Process
import Effect.Subscription as Subscription exposing (Subscription)
import Effect.Task as Task
import Effect.Time as Time
import Effect.Websocket as Websocket
import Email.Html
import Email.Html.Attributes
import EmailAddress exposing (EmailAddress)
import Env
import GuildName
import Hex
import Id exposing (ChannelId, GuildId, Id, InviteLinkId, UserId)
import Lamdera as LamderaCore
import List.Extra
import List.Nonempty exposing (Nonempty(..))
import Local exposing (ChangeId)
import LocalState exposing (BackendChannel, BackendGuild, ChannelStatus(..), JoinGuildError(..), Message(..))
import Log exposing (Log)
import LoginForm
import NonemptyDict
import OneToOne
import Pages.Admin exposing (InitAdminData)
import Pages.UserOverview
import Pagination
import PersonName
import Postmark
import Quantity
import RichText exposing (RichText)
import SecretId exposing (SecretId)
import SeqDict exposing (SeqDict)
import SeqSet
import String.Nonempty exposing (NonemptyString(..))
import TOTP.Key
import TwoFactorAuthentication
import Types
    exposing
        ( AdminStatusLoginData(..)
        , BackendModel
        , BackendMsg(..)
        , LastRequest(..)
        , LocalChange(..)
        , LocalMsg(..)
        , LoginData
        , LoginResult(..)
        , LoginTokenData(..)
        , ServerChange(..)
        , ToBackend(..)
        , ToBeFilledInByBackend(..)
        , ToFrontend(..)
        )
import Unsafe
import User exposing (BackendUser, EmailStatus(..))


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


adminUserId : Id UserId
adminUserId =
    Id.fromInt 0


adminUser : BackendUser
adminUser =
    LocalState.createNewUser
        (Time.millisToPosix 0)
        (Unsafe.personName "AT")
        (Unsafe.emailAddress Env.adminEmail |> RegisteredDirectly)
        True


init : ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
init =
    let
        guild : BackendGuild
        guild =
            { createdAt = Time.millisToPosix 0
            , createdBy = adminUserId
            , name = Unsafe.guildName "First guild"
            , icon = Nothing
            , channels =
                SeqDict.fromList
                    [ ( Id.fromInt 0
                      , { createdAt = Time.millisToPosix 0
                        , createdBy = adminUserId
                        , name = Unsafe.channelName "Welcome"
                        , messages = Array.empty
                        , status = ChannelActive
                        , lastTypedAt = SeqDict.empty
                        , linkedId = Nothing
                        , linkedMessageIds = OneToOne.empty
                        }
                      )
                    , ( Id.fromInt 1
                      , { createdAt = Time.millisToPosix 0
                        , createdBy = adminUserId
                        , name = Unsafe.channelName "General"
                        , messages = Array.empty
                        , status = ChannelActive
                        , lastTypedAt = SeqDict.empty
                        , linkedId = Nothing
                        , linkedMessageIds = OneToOne.empty
                        }
                      )
                    ]
            , members = SeqDict.fromList []
            , owner = adminUserId
            , invites = SeqDict.empty
            , announcementChannel = Id.fromInt 0
            }
    in
    ( { users =
            Nonempty ( adminUserId, adminUser ) []
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
      , guilds =
            SeqDict.fromList
                [ ( Id.fromInt 0
                  , guild
                  )
                , ( Id.fromInt 1
                  , { createdAt = Time.millisToPosix 0
                    , createdBy = adminUserId
                    , name = Unsafe.guildName "Second Guild"
                    , icon = Nothing
                    , channels =
                        SeqDict.fromList
                            [ ( Id.fromInt 0
                              , { createdAt = Time.millisToPosix 0
                                , createdBy = adminUserId
                                , name = Unsafe.channelName "First Channel"
                                , messages =
                                    Array.empty
                                , status = ChannelActive
                                , lastTypedAt = SeqDict.empty
                                , linkedId = Nothing
                                , linkedMessageIds = OneToOne.empty
                                }
                              )
                            ]
                    , members = SeqDict.fromList []
                    , owner = adminUserId
                    , invites = SeqDict.empty
                    , announcementChannel = Id.fromInt 0
                    }
                  )
                ]
      , discordModel = Discord.init
      , discordNotConnected = True
      , discordGuilds = OneToOne.empty
      , discordUsers = OneToOne.empty
      , discordBotId = Nothing
      }
    , Command.none
    )


adminData : BackendModel -> Int -> InitAdminData
adminData model lastLogPageViewed =
    { lastLogPageViewed = lastLogPageViewed
    , users = model.users
    , emailNotificationsEnabled = model.emailNotificationsEnabled
    , twoFactorAuthentication = SeqDict.map (\_ a -> a.finishedAt) model.twoFactorAuthentication
    }


subscriptions : BackendModel -> Subscription BackendOnly BackendMsg
subscriptions model =
    Subscription.batch
        [ Lamdera.onConnect UserConnected
        , Lamdera.onDisconnect UserDisconnected
        , Discord.subscription
            (\connection onData onClose -> Websocket.listen connection onData (\_ -> onClose))
            model.discordModel
            |> Maybe.withDefault Subscription.none
            |> Subscription.map DiscordWebsocketMsg
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
            , Command.none
            )

        UserDisconnected sessionId clientId ->
            ( { model
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
            , Command.none
            )

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

        WebsocketCreatedHandle connection ->
            ( { model | discordModel = Discord.createdHandle connection model.discordModel }
            , Command.none
            )

        WebsocketSentData result ->
            case Debug.log "SentData" result of
                Ok () ->
                    ( model, Command.none )

                Err Websocket.ConnectionClosed ->
                    let
                        _ =
                            Debug.log "WebsocketSentData" "ConnectionClosed"
                    in
                    ( model, Command.none )

        WebsocketClosedByBackend ->
            ( model, Websocket.createHandle WebsocketCreatedHandle Discord.websocketGatewayUrl )

        DiscordWebsocketMsg discordMsg ->
            let
                ( discordModel2, outMsgs ) =
                    Discord.update Env.botToken discordMsg model.discordModel
            in
            List.foldl
                (\outMsg ( model2, cmds ) ->
                    case outMsg of
                        Discord.CloseAndReopenHandle connection ->
                            ( model2
                            , Task.perform (\() -> WebsocketClosedByBackend) (Websocket.close connection)
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

                        Discord.UserCreatedMessage discordGuildId message ->
                            let
                                ( model3, cmd2 ) =
                                    handleDiscordCreateMessage discordGuildId message model
                            in
                            ( model3, cmd2 :: cmds )

                        Discord.UserDeletedMessage guildId channelId id ->
                            ( model2, cmds )

                        Discord.UserEditedMessage guildId channelId id ->
                            ( model2, cmds )
                )
                ( { model | discordModel = discordModel2 }, [] )
                outMsgs
                |> Tuple.mapSecond Command.batch

        GotDiscordGuilds time result ->
            case result of
                Ok data ->
                    ( addDiscordUsers time data.users model
                        |> addDiscordGuilds time data.guilds
                    , Command.none
                    )

                Err error ->
                    let
                        _ =
                            Debug.log "error" error
                    in
                    ( model, Command.none )

        GotCurrentUserGuilds time result ->
            case result of
                Ok guilds ->
                    ( model
                    , List.map
                        (\guild ->
                            Task.map2
                                (\members channels ->
                                    ( members
                                    , ( guild.id, channels )
                                    )
                                )
                                (Discord.listGuildMembers
                                    Env.botToken
                                    { guildId = guild.id
                                    , limit = 100
                                    , after = Discord.Missing
                                    }
                                )
                                (Discord.getGuildChannels Env.botToken guild.id)
                        )
                        guilds
                        |> Task.sequence
                        |> Task.map
                            (\guilds2 ->
                                let
                                    users : SeqDict (Discord.Id.Id Discord.Id.UserId) Discord.GuildMember
                                    users =
                                        List.concatMap
                                            (\( members, _ ) ->
                                                List.map (\member -> ( member.user.id, member )) members
                                            )
                                            guilds2
                                            |> SeqDict.fromList
                                in
                                { users = users
                                , guilds = List.map Tuple.second guilds2 |> SeqDict.fromList
                                }
                            )
                        |> Task.attempt (GotDiscordGuilds time)
                    )

                Err _ ->
                    ( model, Command.none )

        SentMessageToDiscord messageId result ->
            case result of
                Ok message ->
                    ( { model
                        | guilds =
                            SeqDict.updateIfExists
                                messageId.guildId
                                (\guild ->
                                    let
                                        guild2 : BackendGuild
                                        guild2 =
                                            { guild
                                                | channels =
                                                    SeqDict.updateIfExists
                                                        messageId.channelId
                                                        (\channel ->
                                                            { channel
                                                                | linkedMessageIds =
                                                                    OneToOne.insert
                                                                        message.id
                                                                        messageId.messageIndex
                                                                        channel.linkedMessageIds
                                                            }
                                                        )
                                                        guild.channels
                                            }
                                    in
                                    guild2
                                )
                                model.guilds
                      }
                    , Command.none
                    )

                Err _ ->
                    ( model, Command.none )

        GotCurrentUser result ->
            case result of
                Ok user ->
                    ( { model | discordBotId = Just user.id }, Command.none )

                Err _ ->
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
                                (PersonName.fromStringLossy (Discord.usernameToString discordUser.user.username))
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


addDiscordGuilds :
    Time.Posix
    -> SeqDict (Discord.Id.Id Discord.Id.GuildId) (List Discord.Channel)
    -> BackendModel
    -> BackendModel
addDiscordGuilds time guilds model =
    SeqDict.foldl
        (\discordGuildId discordChannels model2 ->
            case OneToOne.second discordGuildId model2.discordGuilds of
                Just _ ->
                    model2

                Nothing ->
                    let
                        ownerId : Id UserId
                        ownerId =
                            adminUserId

                        channels : SeqDict (Id ChannelId) BackendChannel
                        channels =
                            List.indexedMap
                                (\index channel ->
                                    case channel.type_ of
                                        Discord.GuildText ->
                                            ( Id.fromInt index
                                            , { createdAt = time
                                              , createdBy = ownerId
                                              , name =
                                                    (case channel.name of
                                                        Included name ->
                                                            name

                                                        Missing ->
                                                            "Channel " ++ String.fromInt index
                                                    )
                                                        |> ChannelName.fromStringLossy
                                              , messages = Array.empty
                                              , status = ChannelActive
                                              , lastTypedAt = SeqDict.empty
                                              , linkedId = Just channel.id
                                              , linkedMessageIds = OneToOne.empty
                                              }
                                            )
                                                |> Just

                                        _ ->
                                            Nothing
                                )
                                discordChannels
                                |> List.filterMap identity
                                |> SeqDict.fromList

                        newGuild : BackendGuild
                        newGuild =
                            { createdAt = time
                            , createdBy = ownerId
                            , name = GuildName.fromStringLossy "Imported"
                            , icon = Nothing
                            , channels = channels
                            , members = SeqDict.empty
                            , owner = ownerId
                            , invites = SeqDict.empty
                            , announcementChannel = Id.fromInt 0
                            }

                        newGuild2 : BackendGuild
                        newGuild2 =
                            LocalState.addMember time adminUserId newGuild
                                |> Result.withDefault newGuild

                        guildId =
                            Id.nextId model.guilds
                    in
                    { model2
                        | discordGuilds =
                            OneToOne.insert discordGuildId guildId model2.discordGuilds
                        , guilds = SeqDict.insert guildId newGuild2 model2.guilds
                    }
        )
        model
        guilds


handleDiscordCreateMessage :
    Discord.Id.Id Discord.Id.GuildId
    -> Discord.Message
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend msg )
handleDiscordCreateMessage discordGuildId message model =
    if Just message.author.id == model.discordBotId && String.contains botMessageSeparator message.content then
        ( model, Command.none )

    else
        case String.Nonempty.fromString message.content |> Debug.log "message" of
            Just nonempty ->
                let
                    maybeData =
                        case OneToOne.second discordGuildId model.discordGuilds of
                            Just guildId ->
                                case SeqDict.get guildId model.guilds of
                                    Just guild ->
                                        List.Extra.findMap
                                            (\( channelId, channel ) ->
                                                if channel.linkedId == Just message.channelId then
                                                    Just
                                                        { guildId = guildId
                                                        , guild = guild
                                                        , channelId = channelId
                                                        , channel = channel
                                                        }

                                                else
                                                    Nothing
                                            )
                                            (SeqDict.toList guild.channels)

                                    Nothing ->
                                        Nothing

                            Nothing ->
                                Nothing
                in
                case ( OneToOne.second message.author.id model.discordUsers, maybeData |> Debug.log "data" ) of
                    ( Just userId, Just { guildId, guild, channelId, channel } ) ->
                        let
                            richText : Nonempty RichText
                            richText =
                                RichText.fromNonemptyString (NonemptyDict.toSeqDict model.users) nonempty
                        in
                        ( { model
                            | guilds =
                                SeqDict.insert
                                    guildId
                                    { guild
                                        | channels =
                                            SeqDict.insert
                                                channelId
                                                (LocalState.createMessage
                                                    (UserTextMessage
                                                        { createdAt = message.timestamp
                                                        , createdBy = userId
                                                        , content = richText
                                                        , reactions = SeqDict.empty
                                                        , editedAt = Nothing
                                                        , repliedTo = Nothing
                                                        }
                                                    )
                                                    channel
                                                )
                                                guild.channels
                                    }
                                    model.guilds
                          }
                        , broadcastToGuild
                            (Server_SendMessage
                                userId
                                message.timestamp
                                guildId
                                channelId
                                richText
                                Nothing
                                |> ServerChange
                            )
                            model
                        )

                    _ ->
                        ( model, Command.none )

            Nothing ->
                ( model, Command.none )


updateFromFrontend :
    SessionId
    -> ClientId
    -> ToBackend
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
updateFromFrontend sessionId clientId msg model =
    ( model, Task.perform (BackendGotTime sessionId clientId msg) Time.now )


getLoginData : Id UserId -> BackendUser -> BackendModel -> LoginData
getLoginData userId user model =
    { userId = userId
    , adminData =
        if user.isAdmin then
            IsAdminLoginData (adminData model user.lastLogPageViewed)

        else
            IsNotAdminLoginData
    , twoFactorAuthenticationEnabled =
        SeqDict.get userId model.twoFactorAuthentication |> Maybe.map .finishedAt
    , guilds = SeqDict.filterMap (\_ guild -> LocalState.guildToFrontendForUser userId guild) model.guilds
    , user = user
    , otherUsers =
        NonemptyDict.toList model.users
            |> List.filterMap
                (\( otherUserId, otherUser ) ->
                    if otherUserId == userId then
                        Nothing

                    else
                        Just ( otherUserId, User.backendToFrontendForUser otherUser )
                )
            |> SeqDict.fromList
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
        CheckLoginRequest ->
            let
                cmd : Command BackendOnly ToFrontend backendMsg
                cmd =
                    case getUserFromSessionId sessionId model2 of
                        Just ( userId, user ) ->
                            getLoginData userId user model2
                                |> Ok
                                |> CheckLoginResponse
                                |> Lamdera.sendToFrontend clientId

                        Nothing ->
                            CheckLoginResponse (Err ()) |> Lamdera.sendToFrontend clientId
            in
            if model2.discordNotConnected then
                ( { model2 | discordNotConnected = False }
                , Command.batch
                    [ Websocket.createHandle WebsocketCreatedHandle Discord.websocketGatewayUrl
                    , Discord.getCurrentUser Env.botToken |> Task.attempt GotCurrentUser
                    , Discord.getCurrentUserGuilds Env.botToken
                        |> Task.attempt (GotCurrentUserGuilds time)
                    , cmd
                    ]
                )

            else
                ( model2, cmd )

        LoginWithTokenRequest loginCode ->
            loginWithToken time sessionId clientId loginCode model2

        FinishUserCreationRequest personName ->
            case SeqDict.get sessionId model2.pendingLogins of
                Just (WaitingForUserDataForSignup pendingLogin) ->
                    if
                        NonemptyDict.values model2.users
                            |> List.Nonempty.any (\a -> a.email == RegisteredDirectly pendingLogin.emailAddress)
                    then
                        -- It's maybe possible to end up here if a user initiates two account creations for the same email address and then completes both. We'll just silently fail in that case, not worth the effort to give a good error message.
                        ( model2, Command.none )

                    else
                        let
                            userId : Id UserId
                            userId =
                                Id.nextId (NonemptyDict.toSeqDict model2.users)

                            newUser : BackendUser
                            newUser =
                                LocalState.createNewUser
                                    time
                                    personName
                                    (RegisteredDirectly pendingLogin.emailAddress)
                                    False

                            model3 : BackendModel
                            model3 =
                                { model2
                                    | sessions = SeqDict.insert sessionId userId model2.sessions
                                    , pendingLogins = SeqDict.remove sessionId model2.pendingLogins
                                    , users = NonemptyDict.insert userId newUser model2.users
                                }
                        in
                        ( model3
                        , getLoginData userId newUser model3
                            |> LoginSuccess
                            |> LoginWithTokenResponse
                            |> Lamdera.sendToFrontends sessionId
                        )

                _ ->
                    ( model2, Command.none )

        LoginWithTwoFactorRequest loginCode ->
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
                                    ( { model2
                                        | sessions = SeqDict.insert sessionId pendingLogin.userId model2.sessions
                                        , pendingLogins = SeqDict.remove sessionId model2.pendingLogins
                                      }
                                    , getLoginData pendingLogin.userId user model2
                                        |> LoginSuccess
                                        |> LoginWithTokenResponse
                                        |> Lamdera.sendToFrontends sessionId
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
                    |> List.Extra.find (\( _, user ) -> user.email == RegisteredDirectly email)
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
            ( { model2 | sessions = SeqDict.remove sessionId model2.sessions }
            , Lamdera.sendToFrontends sessionId LoggedOutSession
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

                Local_SendMessage _ guildId channelId text repliedTo ->
                    asGuildMember
                        model2
                        sessionId
                        guildId
                        (sendMessage model2 time clientId changeId guildId channelId text repliedTo)

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
                                , broadcastToGuildExcludingOne
                                    clientId
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
                                , broadcastToGuildExcludingOne
                                    clientId
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
                                , broadcastToGuildExcludingOne
                                    clientId
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
                        (\userId _ guild ->
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
                                , broadcastToGuildExcludingOne
                                    clientId
                                    (Server_NewInviteLink time userId guildId id |> ServerChange)
                                    model3
                                ]
                            )
                        )

                Local_NewGuild _ guildName _ ->
                    asUser
                        model2
                        sessionId
                        (\userId _ ->
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
                                , broadcastToUser
                                    clientId
                                    userId
                                    (Local_NewGuild time guildName (FilledInByBackend guildId))
                                    model2
                                ]
                            )
                        )

                Local_MemberTyping _ guildId channelId ->
                    asGuildMember
                        model2
                        sessionId
                        guildId
                        (\userId _ guild ->
                            ( { model2
                                | guilds =
                                    SeqDict.insert
                                        guildId
                                        (LocalState.memberIsTyping userId time channelId guild)
                                        model2.guilds
                              }
                            , Command.batch
                                [ Local_MemberTyping time guildId channelId
                                    |> LocalChangeResponse changeId
                                    |> Lamdera.sendToFrontend clientId
                                , broadcastToGuildExcludingOne
                                    clientId
                                    (Server_MemberTyping time userId guildId channelId |> ServerChange)
                                    model2
                                ]
                            )
                        )

                Local_AddReactionEmoji messageId emoji ->
                    asGuildMember
                        model2
                        sessionId
                        messageId.guildId
                        (\userId _ guild ->
                            ( { model2
                                | guilds =
                                    SeqDict.insert
                                        messageId.guildId
                                        (LocalState.addReactionEmoji
                                            emoji
                                            userId
                                            messageId.channelId
                                            messageId.messageIndex
                                            guild
                                        )
                                        model2.guilds
                              }
                            , Command.batch
                                [ Local_AddReactionEmoji messageId emoji
                                    |> LocalChangeResponse changeId
                                    |> Lamdera.sendToFrontend clientId
                                , broadcastToGuildExcludingOne
                                    clientId
                                    (Server_AddReactionEmoji userId messageId emoji |> ServerChange)
                                    model2
                                ]
                            )
                        )

                Local_RemoveReactionEmoji messageId emoji ->
                    asGuildMember
                        model2
                        sessionId
                        messageId.guildId
                        (\userId _ guild ->
                            ( { model2
                                | guilds =
                                    SeqDict.insert
                                        messageId.guildId
                                        (LocalState.removeReactionEmoji
                                            emoji
                                            userId
                                            messageId.channelId
                                            messageId.messageIndex
                                            guild
                                        )
                                        model2.guilds
                              }
                            , Command.batch
                                [ Local_RemoveReactionEmoji messageId emoji
                                    |> LocalChangeResponse changeId
                                    |> Lamdera.sendToFrontend clientId
                                , broadcastToGuildExcludingOne
                                    clientId
                                    (Server_RemoveReactionEmoji userId messageId emoji |> ServerChange)
                                    model2
                                ]
                            )
                        )

                Local_SendEditMessage _ messageId newContent ->
                    asGuildMember
                        model2
                        sessionId
                        messageId.guildId
                        (\userId _ guild ->
                            case
                                LocalState.editMessage
                                    userId
                                    time
                                    newContent
                                    messageId.channelId
                                    messageId.messageIndex
                                    guild
                            of
                                Ok guild2 ->
                                    ( { model2 | guilds = SeqDict.insert messageId.guildId guild2 model2.guilds }
                                    , Command.batch
                                        [ Local_SendEditMessage time messageId newContent
                                            |> LocalChangeResponse changeId
                                            |> Lamdera.sendToFrontend clientId
                                        , broadcastToGuildExcludingOne
                                            clientId
                                            (Server_SendEditMessage time userId messageId newContent
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

                Local_MemberEditTyping _ messageId ->
                    asGuildMember
                        model2
                        sessionId
                        messageId.guildId
                        (\userId _ guild ->
                            case
                                LocalState.memberIsEditTyping
                                    userId
                                    time
                                    messageId.channelId
                                    messageId.messageIndex
                                    guild
                            of
                                Ok guild2 ->
                                    ( { model2 | guilds = SeqDict.insert messageId.guildId guild2 model2.guilds }
                                    , Command.batch
                                        [ Local_MemberEditTyping time messageId
                                            |> LocalChangeResponse changeId
                                            |> Lamdera.sendToFrontend clientId
                                        , broadcastToGuildExcludingOne
                                            clientId
                                            (Server_MemberEditTyping time userId messageId
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

                Local_SetLastViewed guildId channelId messageIndex ->
                    asUser
                        model2
                        sessionId
                        (\userId user ->
                            ( { model2
                                | users =
                                    NonemptyDict.insert
                                        userId
                                        { user | lastViewed = SeqDict.insert ( guildId, channelId ) messageIndex user.lastViewed }
                                        model2.users
                              }
                            , Command.batch
                                [ LocalChangeResponse changeId localMsg
                                    |> Lamdera.sendToFrontend clientId
                                , broadcastToUser clientId userId localMsg model2
                                ]
                            )
                        )

                Local_DeleteMessage messageId ->
                    asGuildMember
                        model2
                        sessionId
                        messageId.guildId
                        (\userId _ guild ->
                            case
                                LocalState.deleteMessage
                                    userId
                                    messageId.channelId
                                    messageId.messageIndex
                                    guild
                            of
                                Ok guild2 ->
                                    ( { model2
                                        | guilds = SeqDict.insert messageId.guildId guild2 model2.guilds
                                      }
                                    , Command.batch
                                        [ Lamdera.sendToFrontend
                                            clientId
                                            (LocalChangeResponse changeId localMsg)
                                        , broadcastToGuildExcludingOne
                                            clientId
                                            (Server_DeleteMessage userId messageId |> ServerChange)
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

        UserOverviewToBackend toBackend2 ->
            asUser
                model2
                sessionId
                (\userId user ->
                    userOverviewUpdateFromFrontend clientId time userId user toBackend2 model2
                )

        JoinGuildByInviteRequest guildId inviteLinkId ->
            asUser
                model2
                sessionId
                (joinGuildByInvite inviteLinkId time sessionId clientId guildId model2)


joinGuildByInvite :
    SecretId InviteLinkId
    -> Time.Posix
    -> SessionId
    -> ClientId
    -> Id GuildId
    -> BackendModel
    -> Id UserId
    -> BackendUser
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
joinGuildByInvite inviteLinkId time sessionId clientId guildId model userId user =
    case SeqDict.get guildId model.guilds of
        Just guild ->
            case ( SeqDict.get inviteLinkId guild.invites, LocalState.addMember time userId guild ) of
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
                                        userId
                                        (LocalState.markAllChannelsAsViewed guildId guild2 user)
                                        model.users
                            }
                    in
                    ( model2
                    , Command.batch
                        [ broadcastToGuildExcludingOne
                            clientId
                            (Server_MemberJoined
                                time
                                userId
                                guildId
                                (User.backendToFrontendForUser user)
                                |> ServerChange
                            )
                            modelWithoutUser
                        , case
                            ( NonemptyDict.get guild2.owner model2.users
                            , LocalState.guildToFrontendForUser userId guild2
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


userOverviewUpdateFromFrontend :
    ClientId
    -> Time.Posix
    -> Id UserId
    -> BackendUser
    -> Pages.UserOverview.ToBackend
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
userOverviewUpdateFromFrontend clientId time userId user toBackend model =
    case toBackend of
        Pages.UserOverview.EnableTwoFactorAuthenticationRequest ->
            let
                ( model2, secret ) =
                    SecretId.getUniqueId time model
            in
            case user.email of
                RegisteredDirectly email ->
                    case TwoFactorAuthentication.getConfig (EmailAddress.toString email) secret of
                        Ok key ->
                            ( { model2
                                | twoFactorAuthenticationSetup =
                                    SeqDict.insert
                                        userId
                                        { startedAt = time, secret = secret }
                                        model2.twoFactorAuthenticationSetup
                              }
                            , Pages.UserOverview.EnableTwoFactorAuthenticationResponse
                                { qrCodeUrl =
                                    TOTP.Key.toString key
                                        -- https://github.com/choonkeat/elm-totp/issues/3
                                        |> String.replace "%3D" ""
                                }
                                |> UserOverviewToFrontend
                                |> Lamdera.sendToFrontend clientId
                            )

                        Err _ ->
                            ( model2, Command.none )

                RegisteredFromDiscord ->
                    ( model2, Command.none )

        Pages.UserOverview.ConfirmTwoFactorAuthenticationRequest code ->
            case SeqDict.get userId model.twoFactorAuthenticationSetup of
                Just data ->
                    if Duration.from data.startedAt time |> Quantity.lessThan Duration.hour then
                        if TwoFactorAuthentication.isValidCode time code data.secret then
                            ( { model
                                | twoFactorAuthentication =
                                    SeqDict.insert
                                        userId
                                        { finishedAt = time, secret = data.secret }
                                        model.twoFactorAuthentication
                                , twoFactorAuthenticationSetup =
                                    SeqDict.remove userId model.twoFactorAuthenticationSetup
                              }
                            , Pages.UserOverview.ConfirmTwoFactorAuthenticationResponse code True
                                |> UserOverviewToFrontend
                                |> Lamdera.sendToFrontend clientId
                            )

                        else
                            ( model
                            , Pages.UserOverview.ConfirmTwoFactorAuthenticationResponse code False
                                |> UserOverviewToFrontend
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
                                (\_ sessionUserId -> SeqSet.member sessionUserId changes.deletedUsers |> not)
                                model2.sessions
                      }
                    , Command.batch
                        [ Pages.Admin.ChangeUsers { changes | time = time }
                            |> Local_Admin
                            |> LocalChangeResponse changeId
                            |> Lamdera.sendToFrontend clientId
                        , broadcastToOtherAdmins clientId model2 (LocalChange userId localMsg)
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
                , broadcastToOtherAdmins clientId model2 (LocalChange userId localMsg)
                ]
            )


botMessageSeparator : String
botMessageSeparator =
    "꞉"


sendMessage :
    BackendModel
    -> Time.Posix
    -> ClientId
    -> ChangeId
    -> Id GuildId
    -> Id ChannelId
    -> Nonempty RichText
    -> Maybe Int
    -> Id UserId
    -> BackendUser
    -> BackendGuild
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
sendMessage model time clientId changeId guildId channelId text repliedTo userId user guild =
    case SeqDict.get channelId guild.channels of
        Just channel ->
            let
                channel2 : BackendChannel
                channel2 =
                    LocalState.createMessage
                        (UserTextMessage
                            { createdAt = time
                            , createdBy = userId
                            , content = text
                            , reactions = SeqDict.empty
                            , editedAt = Nothing
                            , repliedTo = repliedTo
                            }
                        )
                        channel

                messageIndex : Int
                messageIndex =
                    Array.length channel2.messages - 1
            in
            ( { model
                | guilds =
                    SeqDict.insert
                        guildId
                        { guild | channels = SeqDict.insert channelId channel2 guild.channels }
                        model.guilds
                , users =
                    NonemptyDict.insert
                        userId
                        { user
                            | lastViewed = SeqDict.insert ( guildId, channelId ) messageIndex user.lastViewed
                        }
                        model.users
              }
            , Command.batch
                [ LocalChangeResponse changeId (Local_SendMessage time guildId channelId text repliedTo)
                    |> Lamdera.sendToFrontend clientId
                , broadcastToGuildExcludingOne
                    clientId
                    (Server_SendMessage userId time guildId channelId text repliedTo |> ServerChange)
                    model
                , case channel.linkedId of
                    Just discordChannelId ->
                        Discord.createMessage
                            Env.botToken
                            { channelId = discordChannelId
                            , content =
                                PersonName.toString user.name
                                    ++ botMessageSeparator
                                    ++ " "
                                    ++ RichText.toString (NonemptyDict.toSeqDict model.users) text
                            , replyTo = Nothing
                            }
                            |> Task.attempt
                                (SentMessageToDiscord
                                    { guildId = guildId
                                    , channelId = channelId
                                    , messageIndex = messageIndex
                                    }
                                )

                    Nothing ->
                        Command.none
                ]
            )

        Nothing ->
            ( model
            , invalidChangeResponse changeId clientId
            )


broadcastToGuildExcludingOne : ClientId -> LocalMsg -> BackendModel -> Command BackendOnly ToFrontend msg
broadcastToGuildExcludingOne clientToSkip msg model =
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


broadcastToGuild : LocalMsg -> BackendModel -> Command BackendOnly ToFrontend msg
broadcastToGuild msg model =
    List.concatMap
        (\( _, otherClientIds ) ->
            NonemptyDict.keys otherClientIds
                |> List.Nonempty.toList
                |> List.filterMap
                    (\otherClientId ->
                        ChangeBroadcast msg
                            |> Lamdera.sendToFrontend otherClientId
                            |> Just
                    )
        )
        (SeqDict.toList model.connections)
        |> Command.batch


broadcastToUser : ClientId -> Id UserId -> LocalChange -> BackendModel -> Command BackendOnly ToFrontend msg
broadcastToUser clientToSkip userId msg model =
    SeqDict.filterMap
        (\sessionId otherUserId ->
            if userId == otherUserId then
                case SeqDict.get sessionId model.connections of
                    Just clientIds ->
                        List.filterMap
                            (\( otherClientId, _ ) ->
                                if clientToSkip == otherClientId then
                                    Nothing

                                else
                                    ChangeBroadcast (LocalChange userId msg)
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



--    |> SeqDict.keys
--    |>
--List.concatMap
--    (\( _, otherClientIds ) ->
--        NonemptyDict.keys otherClientIds
--            |> List.Nonempty.toList
--            |> List.filterMap
--                (\otherClientId ->
--                    if clientToSkip == otherClientId then
--                        Nothing
--
--                    else
--                        ChangeBroadcast msg
--                            |> Lamdera.sendToFrontend otherClientId
--                            |> Just
--                )
--    )
--    (SeqDict.toList model.connections)
--    |> Command.batch


broadcastToOtherAdmins : ClientId -> BackendModel -> LocalMsg -> Command BackendOnly ToFrontend msg
broadcastToOtherAdmins currentClientId model broadcastMsg =
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
    -> (Id UserId -> BackendUser -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg ))
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
asUser model sessionId func =
    case SeqDict.get sessionId model.sessions of
        Just userId ->
            case NonemptyDict.get userId model.users of
                Just user ->
                    func userId user

                Nothing ->
                    ( model, Command.none )

        Nothing ->
            ( model, Command.none )


asGuildMember :
    BackendModel
    -> SessionId
    -> Id GuildId
    -> (Id UserId -> BackendUser -> BackendGuild -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg ))
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
asGuildMember model sessionId guildId func =
    case SeqDict.get sessionId model.sessions of
        Just userId ->
            case ( NonemptyDict.get userId model.users, SeqDict.get guildId model.guilds ) of
                ( Just user, Just guild ) ->
                    func userId user guild

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
        (\userId user guild ->
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
        (\userId user ->
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
            Debug.log "a login" (String.padLeft LoginForm.loginCodeLength '0' (String.fromInt loginCode))
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
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
loginWithToken time sessionId clientId loginCode model =
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
                            ( { model
                                | sessions = SeqDict.insert sessionId pendingLogin.userId model.sessions
                                , pendingLogins = SeqDict.remove sessionId model.pendingLogins
                              }
                            , getLoginData pendingLogin.userId user model
                                |> LoginSuccess
                                |> LoginWithTokenResponse
                                |> Lamdera.sendToFrontends sessionId
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


getUserFromSessionId : SessionId -> BackendModel -> Maybe ( Id UserId, BackendUser )
getUserFromSessionId sessionId model =
    SeqDict.get sessionId model.sessions
        |> Maybe.andThen (\userId -> NonemptyDict.get userId model.users |> Maybe.map (Tuple.pair userId))


emailToNotifyWhenErrorsAreLogged : EmailAddress
emailToNotifyWhenErrorsAreLogged =
    Unsafe.emailAddress "martinsstewart@gmail.com"


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
