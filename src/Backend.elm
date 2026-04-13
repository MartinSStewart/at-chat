module Backend exposing
    ( adminUser
    , app
    , app_
    )

import AiChat
import Array exposing (Array)
import Array.Extra
import BackendExtra
import Broadcast
import Bytes exposing (Bytes)
import Bytes.Decode
import Bytes.Encode
import ChannelDescription
import Discord exposing (OptionalData(..))
import Discord.Markdown
import DiscordAttachmentId exposing (DiscordAttachmentId)
import DiscordSync
import DiscordUserData exposing (DiscordBasicUserData, DiscordFullUserData, DiscordUserData(..), DiscordUserLoadingData(..), NeedsAuthAgainData)
import DmChannel exposing (DiscordDmChannel, DmChannelId)
import Duration
import Effect.Command as Command exposing (BackendOnly, Command)
import Effect.Http as Http
import Effect.Lamdera as Lamdera exposing (ClientId, SessionId)
import Effect.Subscription as Subscription exposing (Subscription)
import Effect.Task as Task exposing (Task)
import Effect.Time as Time
import Effect.Websocket as Websocket
import EmailAddress
import Emoji
import Env
import FileStatus exposing (FileData, FileId)
import GuildName
import Id exposing (AnyGuildOrDmId(..), ChannelId, ChannelMessageId, DiscordGuildOrDmId(..), DiscordGuildOrDmId_DmData, GuildId, GuildOrDmId(..), Id, InviteLinkId, ThreadRoute(..), ThreadRouteWithMaybeMessage(..), ThreadRouteWithMessage(..), UserId)
import ImageEditor
import Lamdera as LamderaCore
import List.Extra
import List.Nonempty exposing (Nonempty(..))
import Local exposing (ChangeId)
import LocalState exposing (BackendGuild, ChannelStatus(..), DiscordBackendChannel, DiscordBackendGuild, JoinGuildError(..), LastRequest(..), LoadingDiscordChannel(..), LoadingDiscordChannelStep(..), PrivateVapidKey(..))
import Log
import LoginForm
import MembersAndOwner exposing (IsMember(..))
import Message exposing (ChangeAttachments(..), Message(..))
import MyUi
import NonemptyDict
import OneToOne
import Pages.Admin exposing (ExportSubset(..))
import Pagination
import Quantity
import RateLimit
import RichText exposing (RichText)
import SecretId exposing (SecretId)
import SeqDict exposing (SeqDict)
import SeqSet
import Slack
import Sticker exposing (StickerUrl(..))
import TOTP.Key
import TextEditor
import Thread exposing (DiscordBackendThread)
import Toop exposing (T4(..))
import TwoFactorAuthentication
import Types exposing (BackendModel, BackendMsg(..), DiscordAttachmentData, ExportState, ExportStateProgress, InitialLoadRequest(..), LocalChange(..), LocalMsg(..), LoginResult(..), LoginTokenData(..), ServerChange(..), ToBackend(..), ToFrontend(..))
import Unsafe
import Untrusted
import User exposing (BackendUser, LastDmViewed(..))
import UserSession exposing (PushSubscription(..), SetViewing(..), ToBeFilledInByBackend(..), UserSession)
import VisibleMessages
import WireHelper


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
                        , description = ChannelDescription.fromStringLossy "The welcome channel!"
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
                        , description = ChannelDescription.empty
                        , messages = Array.empty
                        , status = ChannelActive
                        , lastTypedAt = SeqDict.empty
                        , threads = SeqDict.empty
                        }
                      )
                    ]
            , membersAndOwner = MembersAndOwner.init SeqDict.empty Broadcast.adminUserId

            --List.range 1 40
            --    |> List.map (\index -> ( Id.fromInt index, { joinedAt = Time.millisToPosix 0 } ))
            --    |> SeqDict.fromList
            , invites = SeqDict.empty
            }
    in
    ( { users =
            Nonempty
                ( Broadcast.adminUserId, adminUser )
                []
                --(List.range 1 40
                --    |> List.map
                --        (\index ->
                --            ( Id.fromInt index
                --            , User.init
                --                (Time.millisToPosix 0)
                --                (Unsafe.personName ("Steve" ++ String.fromInt index))
                --                (Unsafe.emailAddress ("steve" ++ String.fromInt index ++ "@email.com"))
                --                False
                --            )
                --        )
                --)
                |> NonemptyDict.fromNonemptyList
      , sessions = SeqDict.empty
      , connections = SeqDict.empty
      , secretCounter = 0
      , pendingLogins = SeqDict.empty
      , logs = Array.empty

      --List.range 0 100
      --    |> List.map
      --        (\index ->
      --            { time = Time.millisToPosix (index * 1000000)
      --            , log = Log.FailedToParseDiscordWebsocket Nothing (String.fromInt index)
      --            , isHidden = False
      --            }
      --        )
      --    |> Array.fromList
      , emailNotificationsEnabled = True
      , lastErrorLogEmail = Time.millisToPosix -10000000000
      , twoFactorAuthentication = SeqDict.empty
      , twoFactorAuthenticationSetup = SeqDict.empty
      , guilds = SeqDict.fromList [ ( Id.fromInt 0, guild ) ]
      , isInitialized = False
      , discordGuilds = SeqDict.empty
      , dmChannels = SeqDict.empty
      , discordDmChannels = SeqDict.empty
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
      , pendingDiscordCreateMessages = SeqDict.empty
      , pendingDiscordCreateDmMessages = SeqDict.empty
      , discordAttachments = SeqDict.empty
      , loadingDiscordChannels = SeqDict.empty
      , signupsEnabled = True
      , exportState = Nothing
      , scheduledExportState = Nothing
      , lastScheduledExportTime = Nothing
      , sendMessageRateLimits = SeqDict.empty
      , toBackendLogs = Array.empty
      , stickers = SeqDict.empty
      , discordStickers = OneToOne.empty
      }
    , Command.none
    )


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
                            (\connection onData onClose ->
                                Websocket.listen connection
                                    onData
                                    (\data3 ->
                                        let
                                            _ =
                                                Debug.log "Websocket unexpected close" ()
                                        in
                                        onClose data3.reason
                                    )
                            )
                            data2.connection
                            |> Maybe.map (Subscription.map (DiscordUserWebsocketMsg discordUserId))

                    BasicData _ ->
                        Nothing

                    NeedsAuthAgain _ ->
                        Nothing
            )
            (SeqDict.toList model.discordUsers)
            |> Subscription.batch
        , case model.exportState of
            Just _ ->
                Time.every (Duration.milliseconds 30) (\_ -> ExportBackendStep)

            Nothing ->
                Subscription.none
        , case model.scheduledExportState of
            Just _ ->
                Time.every (Duration.milliseconds 30) ScheduledExportBackendStep

            Nothing ->
                Subscription.none
        , Time.every Duration.hour HourlyUpdate
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
            disconnectClient sessionId clientId model

        BackendGotTime sessionId clientId toBackend time ->
            let
                oldModel : BackendModel
                oldModel =
                    model
            in
            updateFromFrontendWithTime
                time
                sessionId
                clientId
                toBackend
                { model
                    | connections =
                        SeqDict.updateIfExists
                            sessionId
                            (NonemptyDict.updateIfExists clientId (\_ -> LastRequest time))
                            model.connections
                }
                |> (\( model2, cmds ) ->
                        ( model2
                        , if Env.isProduction then
                            Command.batch
                                [ Task.perform
                                    (\endTime ->
                                        ToBackendCompleted
                                            (BackendExtra.toBackendLog toBackend)
                                            (SeqDict.get sessionId oldModel.sessions |> Maybe.map .userId)
                                            { startTime = time, endTime = endTime }
                                    )
                                    Time.now
                                , cmds
                                ]

                          else
                            cmds
                        )
                   )

        SentLoginEmail time emailAddress result ->
            BackendExtra.addLog time (Log.LoginEmail result emailAddress) model

        SentLogErrorEmail time email result ->
            case result of
                Ok () ->
                    ( model, Command.none )

                Err error ->
                    BackendExtra.addLog time (Log.SendLogErrorEmailFailed error email) model

        DiscordUserWebsocketMsg discordUserId discordMsg ->
            DiscordSync.discordUserWebsocketMsg discordUserId discordMsg model

        GotSlackChannels _ _ result ->
            case result of
                Ok _ ->
                    ( model
                    , Command.none
                    )

                Err _ ->
                    ( model, Command.none )

        SentDiscordGuildMessage time changeId _ clientId guildId channelId threadRoute discordUserId result ->
            case result of
                Ok _ ->
                    -- Wait until the Discord.UserOutMsg_UserCreatedMessage websocket event instead. This simplifies the code since we don't have two places that handle messages being created
                    ( model, Command.none )

                Err error ->
                    BackendExtra.addLogWithCmd
                        time
                        (Log.FailedToSendDiscordGuildMessage discordUserId guildId channelId threadRoute error)
                        model
                        (BackendExtra.invalidChangeResponse changeId clientId)

        SentDiscordDmMessage time changeId _ clientId channelId discordUserId result ->
            case result of
                Ok _ ->
                    -- Wait until the websocket event instead. This simplifies the code since we don't have two places that handle messages being created
                    ( model, Command.none )

                Err error ->
                    BackendExtra.addLogWithCmd
                        time
                        (Log.FailedToSendDiscordDmMessage discordUserId channelId error)
                        model
                        (BackendExtra.invalidChangeResponse changeId clientId)

        DeletedDiscordGuildMessage time guildId channelId threadRoute messageId result ->
            case result of
                Ok () ->
                    ( model, Command.none )

                Err error ->
                    BackendExtra.addLog time (Log.FailedToDeleteDiscordGuildMessage guildId channelId threadRoute messageId error) model

        DeletedDiscordDmMessage time channelId messageId discordMessageId result ->
            case result of
                Ok () ->
                    ( model, Command.none )

                Err error ->
                    BackendExtra.addLog time (Log.FailedToDeleteDiscordDmMessage channelId messageId discordMessageId error) model

        EditedDiscordGuildMessage time guildId channelId threadRoute messageId result ->
            case result of
                Ok () ->
                    ( model, Command.none )

                Err error ->
                    BackendExtra.addLog time (Log.FailedToEditDiscordGuildMessage guildId channelId threadRoute messageId error) model

        EditedDiscordDmMessage time channelId messageId discordMessageId result ->
            case result of
                Ok () ->
                    ( model, Command.none )

                Err error ->
                    BackendExtra.addLog time (Log.FailedToEditDiscordDmMessage channelId messageId discordMessageId error) model

        DiscordAddedReactionToGuildMessage time guildId channelId threadRoute discordMessageId emoji result ->
            case result of
                Ok () ->
                    ( model, Command.none )

                Err error ->
                    BackendExtra.addLog time (Log.FailedToAddReactionToDiscordGuildMessage guildId channelId threadRoute discordMessageId emoji error) model

        DiscordAddedReactionToDmMessage time channelId messageId discordMessageId emoji result ->
            case result of
                Ok () ->
                    ( model, Command.none )

                Err error ->
                    BackendExtra.addLog time (Log.FailedToAddReactionToDiscordDmMessage channelId messageId discordMessageId emoji error) model

        DiscordRemovedReactionToGuildMessage time guildId channelId threadRoute discordMessageId emoji result ->
            case result of
                Ok () ->
                    ( model, Command.none )

                Err error ->
                    BackendExtra.addLog time (Log.FailedToRemoveReactionToDiscordGuildMessage guildId channelId threadRoute discordMessageId emoji error) model

        DiscordRemovedReactionToDmMessage time channelId messageId discordMessageId emoji result ->
            case result of
                Ok () ->
                    ( model, Command.none )

                Err error ->
                    BackendExtra.addLog time (Log.FailedToRemoveReactionToDiscordDmMessage channelId messageId discordMessageId emoji error) model

        DiscordTypingIndicatorSent ->
            ( model, Command.none )

        AiChatBackendMsg aiChatMsg ->
            ( model, Command.map AiChatToFrontend AiChatBackendMsg (AiChat.backendUpdate aiChatMsg) )

        GotDiscordUserAvatars result time ->
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

                                                NeedsAuthAgain data ->
                                                    NeedsAuthAgain { data | icon = Maybe.map .fileHash maybeAvatar }
                                        )
                                        discordUsers
                                )
                                model.discordUsers
                                userAvatars
                      }
                    , Command.none
                    )

                Err error ->
                    BackendExtra.addLog time (Log.FailedToGetDiscordUserAvatars error) model

        SentNotification sessionId userId time result ->
            case result of
                Ok () ->
                    ( model, Command.none )

                Err error ->
                    BackendExtra.addLogWithCmd
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

        LinkDiscordUserStep1 linkedAt clientId userId auth result ->
            case result of
                Ok discordUser ->
                    let
                        backendUser : DiscordFullUserData
                        backendUser =
                            { auth = auth
                            , user = discordUser
                            , connection = Discord.init
                            , linkedTo = userId
                            , icon = Nothing
                            , linkedAt = linkedAt
                            , isLoadingData = DiscordUserLoadingData linkedAt
                            }
                    in
                    ( { model | discordUsers = SeqDict.insert discordUser.id (FullData backendUser) model.discordUsers }
                    , Command.batch
                        [ Lamdera.sendToFrontend clientId (LinkDiscordResponse (Ok ()))
                        , Broadcast.toUser
                            Nothing
                            Nothing
                            userId
                            (Server_LinkDiscordUser
                                discordUser.id
                                (User.discordFullDataUserToFrontendCurrentUser False backendUser backendUser.isLoadingData)
                                |> ServerChange
                            )
                            model
                        , DiscordSync.websocketCreateHandle
                            "LinkDiscordUserStep1"
                            (WebsocketCreatedHandleForUser discordUser.id)
                            Discord.websocketGatewayUrl
                        ]
                    )

                Err error ->
                    ( model
                    , Lamdera.sendToFrontend clientId (LinkDiscordResponse (Err error))
                    )

        ReloadDiscordUserStep1 time clientId userId discordUserId result ->
            case ( SeqDict.get discordUserId model.discordUsers, result ) of
                ( Just (FullData discordUser), Ok discordUserData ) ->
                    let
                        discordUser2 : DiscordFullUserData
                        discordUser2 =
                            { discordUser | user = discordUserData }
                    in
                    ( { model | discordUsers = SeqDict.insert discordUserId (FullData discordUser2) model.discordUsers }
                    , Command.batch
                        [ Lamdera.sendToFrontend clientId (LinkDiscordResponse (Ok ()))
                        , Broadcast.toUser
                            Nothing
                            Nothing
                            userId
                            (Server_LinkDiscordUser
                                discordUserId
                                (User.discordFullDataUserToFrontendCurrentUser False discordUser2 discordUser2.isLoadingData)
                                |> ServerChange
                            )
                            model
                        , DiscordSync.websocketCreateHandle
                            "ReloadDiscordUserStep1"
                            (WebsocketCreatedHandleForUser discordUserId)
                            Discord.websocketGatewayUrl
                        ]
                    )

                ( Just (FullData discordUser), Err _ ) ->
                    ( { model
                        | discordUsers =
                            SeqDict.insert
                                discordUserId
                                (FullData { discordUser | isLoadingData = DiscordUserLoadingFailed time })
                                model.discordUsers
                      }
                    , Broadcast.toUser
                        Nothing
                        Nothing
                        userId
                        (Server_DiscordUserLoadingDataIsDone discordUserId (Err time) |> ServerChange)
                        model
                    )

                _ ->
                    ( model, Command.none )

        HandleReadyDataStep2 time discordUserId result ->
            case SeqDict.get discordUserId model.discordUsers of
                Just (FullData discordUser) ->
                    case result of
                        Ok ( dmData, guildData ) ->
                            let
                                guildDataDict :
                                    SeqDict
                                        (Discord.Id Discord.GuildId)
                                        { guild : Discord.GatewayGuild
                                        , channels : List Discord.Channel
                                        , icon : Maybe FileStatus.UploadResponse
                                        }
                                guildDataDict =
                                    SeqDict.fromList guildData

                                model2 : BackendModel
                                model2 =
                                    { model
                                        | discordUsers =
                                            SeqDict.insert
                                                discordUserId
                                                (FullData { discordUser | isLoadingData = DiscordUserLoadedSuccessfully })
                                                model.discordUsers
                                        , discordGuilds =
                                            SeqDict.foldl
                                                (\guildId guildData2 discordGuilds ->
                                                    SeqDict.updateIfExists
                                                        guildId
                                                        (addDiscordGuildData discordUserId guildData2)
                                                        discordGuilds
                                                )
                                                model.discordGuilds
                                                guildDataDict
                                        , discordDmChannels =
                                            List.foldl
                                                (\data dmChannels2 ->
                                                    SeqDict.update
                                                        data.dmChannelId
                                                        (\maybe ->
                                                            case maybe of
                                                                Just _ ->
                                                                    maybe

                                                                Nothing ->
                                                                    { messages = Array.empty
                                                                    , lastTypedAt = SeqDict.empty
                                                                    , linkedMessageIds = OneToOne.empty
                                                                    , members =
                                                                        List.foldl
                                                                            (\member dict -> NonemptyDict.insert member { messagesSent = 0 } dict)
                                                                            (NonemptyDict.singleton discordUserId { messagesSent = 0 })
                                                                            data.members
                                                                    }
                                                                        |> Just
                                                        )
                                                        dmChannels2
                                                )
                                                model.discordDmChannels
                                                dmData
                                    }

                                ( otherDiscordUsers, linkedDiscordUsers ) =
                                    BackendExtra.getLinkedDiscordUsersAndOtherUsers discordUser.linkedTo model2
                            in
                            ( model2
                            , Broadcast.toUser
                                Nothing
                                Nothing
                                discordUser.linkedTo
                                (Server_DiscordUserLoadingDataIsDone
                                    discordUserId
                                    (Ok
                                        { discordGuilds =
                                            SeqDict.filterMap
                                                (\guildId _ ->
                                                    case SeqDict.get guildId model2.discordGuilds of
                                                        Just guild ->
                                                            BackendExtra.discordGuildToFrontendForUser Nothing guild linkedDiscordUsers

                                                        Nothing ->
                                                            Nothing
                                                )
                                                guildDataDict
                                        , discordDms =
                                            List.filterMap
                                                (\data ->
                                                    case SeqDict.get data.dmChannelId model2.discordDmChannels of
                                                        Just dmChannel ->
                                                            case BackendExtra.discordDmChannelToFrontend False dmChannel linkedDiscordUsers of
                                                                Just dmChannel2 ->
                                                                    Just ( data.dmChannelId, dmChannel2 )

                                                                Nothing ->
                                                                    Nothing

                                                        Nothing ->
                                                            Nothing
                                                )
                                                dmData
                                                |> SeqDict.fromList
                                        , discordUsers = otherDiscordUsers
                                        }
                                    )
                                    |> ServerChange
                                )
                                model2
                            )

                        Err error ->
                            BackendExtra.addLogWithCmd
                                time
                                (Log.FailedToLoadDiscordUserData discordUserId error)
                                { model
                                    | discordUsers =
                                        SeqDict.insert
                                            discordUserId
                                            (FullData { discordUser | isLoadingData = DiscordUserLoadingFailed time })
                                            model.discordUsers
                                }
                                (Broadcast.toUser
                                    Nothing
                                    Nothing
                                    discordUser.linkedTo
                                    (Server_DiscordUserLoadingDataIsDone discordUserId (Err time) |> ServerChange)
                                    model
                                )

                _ ->
                    BackendExtra.addLog
                        time
                        (Log.FailedToLoadDiscordUserData discordUserId (Discord.UnexpectedError "Couldn't find FullData Discord user"))
                        model

        WebsocketCreatedHandleForUser discordUserId connection ->
            case SeqDict.get discordUserId model.discordUsers of
                Just (FullData data) ->
                    ( { model
                        | discordUsers =
                            SeqDict.insert
                                discordUserId
                                (FullData { data | connection = Discord.createdHandle connection data.connection })
                                model.discordUsers
                      }
                    , case data.connection.websocketHandle of
                        Just connection2 ->
                            DiscordSync.websocketClose "WebsocketClosedByBackendForUser" connection2
                                |> Task.perform (\() -> WebsocketClosedByBackendForUser discordUserId False)

                        Nothing ->
                            Command.none
                    )

                _ ->
                    ( model, Command.none )

        WebsocketClosedByBackendForUser discordUserId reopen ->
            ( model
            , if reopen then
                DiscordSync.websocketCreateHandle
                    "WebsocketClosedByBackendForUser"
                    (WebsocketCreatedHandleForUser discordUserId)
                    Discord.websocketGatewayUrl

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

        DiscordMessageCreate_AttachmentsUploaded message results ->
            let
                ( attachments, discordAttachments ) =
                    attachmentsUploadedHelper model message (List.Nonempty.toList results)
            in
            DiscordSync.handleCreateMessage "" message attachments { model | discordAttachments = discordAttachments }

        DiscordMessageUpdate_AttachmentsUploaded message results ->
            let
                ( attachments, discordAttachments ) =
                    attachmentsUploadedHelper model message (List.Nonempty.toList results)
            in
            DiscordSync.handleEditMessage message attachments { model | discordAttachments = discordAttachments }

        ReloadedDiscordGuildChannel userIdToLoadWith guildId channelId attachments ->
            case ( LocalState.getDiscordGuildAndChannel guildId channelId model, SeqDict.get userIdToLoadWith model.loadingDiscordChannels ) of
                ( Just ( guild, channel ), Just (LoadingDiscordGuildChannel _ guildIdB channelIdB (LoadingDiscordChannelAttachments _ messages)) ) ->
                    if guildId == guildIdB && channelId == channelIdB then
                        let
                            attachments2 : SeqDict DiscordAttachmentId DiscordAttachmentData
                            attachments2 =
                                DiscordSync.addUploadResponsesToDiscordAttachments attachments model.discordAttachments

                            ( messages2, linkedMessageIds ) =
                                DiscordSync.messagesAndLinks (List.reverse messages) model.discordStickers attachments2

                            --( attachments3, channel2 ) =
                            --case result of
                            --    Ok { messages, attachments, threads } ->
                            --        let
                            --            attachments2 : SeqDict DiscordAttachmentId DiscordAttachmentData
                            --            attachments2 =
                            --                List.foldl
                            --                    (\thread dict ->
                            --                        DiscordSync.addUploadResponsesToDiscordAttachments thread.uploadResponses dict
                            --                    )
                            --                    (DiscordSync.addUploadResponsesToDiscordAttachments attachments model.discordAttachments)
                            --                    threads
                            --
                            --            ( messages2, linkedMessageIds ) =
                            --                DiscordSync.messagesAndLinks (List.reverse messages) attachments2
                            --        in
                            --        ( attachments2
                            --        , { channel
                            --            | messages = messages2
                            --            , linkedMessageIds = linkedMessageIds
                            --            , threads =
                            --                List.filterMap
                            --                    (\thread ->
                            --                        case
                            --                            OneToOne.second
                            --                                (Discord.toUInt64 thread.channel.id |> Discord.fromUInt64)
                            --                                linkedMessageIds
                            --                        of
                            --                            Just channelMessageIndex ->
                            --                                let
                            --                                    ( messages3, links ) =
                            --                                        DiscordSync.messagesAndLinks thread.messages attachments2
                            --                                in
                            --                                ( channelMessageIndex
                            --                                , { messages = messages3
                            --                                  , lastTypedAt = SeqDict.empty
                            --                                  , linkedMessageIds = links
                            --                                  }
                            --                                )
                            --                                    |> Just
                            --
                            --                            Nothing ->
                            --                                Nothing
                            --                    )
                            --                    threads
                            --                    |> SeqDict.fromList
                            --          }
                            --        )
                            model2 : BackendModel
                            model2 =
                                { model
                                    | discordGuilds =
                                        SeqDict.insert
                                            guildId
                                            { guild
                                                | channels =
                                                    SeqDict.insert
                                                        channelId
                                                        { channel | messages = messages2, linkedMessageIds = linkedMessageIds }
                                                        guild.channels
                                            }
                                            model.discordGuilds
                                    , discordAttachments = attachments2
                                    , loadingDiscordChannels = SeqDict.remove userIdToLoadWith model.loadingDiscordChannels
                                }
                        in
                        ( model2
                        , Server_LoadingDiscordChannelChanged userIdToLoadWith Nothing
                            |> ServerChange
                            |> Broadcast.toAdmins model2
                        )

                    else
                        ( model, Command.none )

                _ ->
                    ( model, Command.none )

        ReloadedDiscordDmChannel userIdToLoadWith channelId attachments ->
            case ( SeqDict.get channelId model.discordDmChannels, SeqDict.get userIdToLoadWith model.loadingDiscordChannels ) of
                ( Just channel, Just (LoadingDiscordDmChannel _ channelIdB (LoadingDiscordChannelAttachments _ messages)) ) ->
                    if channelId == channelIdB then
                        let
                            attachments2 : SeqDict DiscordAttachmentId DiscordAttachmentData
                            attachments2 =
                                DiscordSync.addUploadResponsesToDiscordAttachments
                                    attachments
                                    model.discordAttachments

                            ( messages2, linkedMessageIds ) =
                                DiscordSync.messagesAndLinks (List.reverse messages) model.discordStickers attachments2

                            model2 : BackendModel
                            model2 =
                                { model
                                    | discordDmChannels =
                                        SeqDict.insert
                                            channelId
                                            { channel
                                                | messages = messages2
                                                , linkedMessageIds = linkedMessageIds
                                                , members =
                                                    Array.foldl
                                                        (\message members ->
                                                            case message of
                                                                UserTextMessage message2 ->
                                                                    NonemptyDict.updateIfExists
                                                                        message2.createdBy
                                                                        (\a -> { a | messagesSent = a.messagesSent + 1 })
                                                                        members

                                                                UserJoinedMessage _ _ _ ->
                                                                    members

                                                                DeletedMessage _ ->
                                                                    members
                                                        )
                                                        channel.members
                                                        messages2
                                            }
                                            model.discordDmChannels
                                    , discordAttachments = attachments2
                                    , loadingDiscordChannels =
                                        SeqDict.remove
                                            userIdToLoadWith
                                            model.loadingDiscordChannels
                                }
                        in
                        ( model2
                        , Server_LoadingDiscordChannelChanged userIdToLoadWith Nothing
                            |> ServerChange
                            |> Broadcast.toAdmins model2
                        )

                    else
                        ( model, Command.none )

                _ ->
                    ( model, Command.none )

        GotDiscordGuildChannelMessages time userIdToLoadWith guildId channelId result ->
            case SeqDict.get userIdToLoadWith model.loadingDiscordChannels of
                Just (LoadingDiscordGuildChannel startTime loadingGuildId loadingChannelId LoadingDiscordChannelMessages) ->
                    if guildId == loadingGuildId && channelId == loadingChannelId then
                        let
                            loading : LoadingDiscordChannel (List Discord.Message)
                            loading =
                                (case result of
                                    Ok messages ->
                                        LoadingDiscordChannelAttachments time messages

                                    Err error ->
                                        LoadingDiscordChannelMessagesFailed error
                                )
                                    |> LoadingDiscordGuildChannel startTime loadingGuildId loadingChannelId
                        in
                        ( { model
                            | loadingDiscordChannels =
                                SeqDict.insert userIdToLoadWith loading model.loadingDiscordChannels
                          }
                        , Command.batch
                            [ case result of
                                Ok messages ->
                                    DiscordSync.uploadAttachmentsForMessages model messages
                                        |> Task.perform (ReloadedDiscordGuildChannel userIdToLoadWith guildId channelId)

                                Err _ ->
                                    Command.none
                            , LocalState.loadingDiscordChannelMap
                                (List.foldl (\message count -> count + List.length message.attachments) 0)
                                loading
                                |> Just
                                |> Server_LoadingDiscordChannelChanged userIdToLoadWith
                                |> ServerChange
                                |> Broadcast.toAdmins model
                            ]
                        )

                    else
                        ( model, Command.none )

                _ ->
                    ( model, Command.none )

        GotDiscordDmChannelMessages time userIdToLoadWith channelId result ->
            case SeqDict.get userIdToLoadWith model.loadingDiscordChannels of
                Just (LoadingDiscordDmChannel startTime loadingChannelId LoadingDiscordChannelMessages) ->
                    if channelId == loadingChannelId then
                        let
                            loading : LoadingDiscordChannel (List Discord.Message)
                            loading =
                                (case result of
                                    Ok messages ->
                                        LoadingDiscordChannelAttachments time messages

                                    Err error ->
                                        LoadingDiscordChannelMessagesFailed error
                                )
                                    |> LoadingDiscordDmChannel startTime loadingChannelId
                        in
                        ( { model
                            | loadingDiscordChannels =
                                SeqDict.insert userIdToLoadWith loading model.loadingDiscordChannels
                          }
                        , Command.batch
                            [ case result of
                                Ok messages ->
                                    DiscordSync.uploadAttachmentsForMessages model messages
                                        |> Task.perform (ReloadedDiscordDmChannel userIdToLoadWith channelId)

                                Err _ ->
                                    Command.none
                            , LocalState.loadingDiscordChannelMap
                                (List.foldl (\message count -> count + List.length message.attachments) 0)
                                loading
                                |> Just
                                |> Server_LoadingDiscordChannelChanged userIdToLoadWith
                                |> ServerChange
                                |> Broadcast.toAdmins model
                            ]
                        )

                    else
                        ( model, Command.none )

                _ ->
                    ( model, Command.none )

        GotTimeForFailedToParseDiscordWebsocket name jsonError time ->
            BackendExtra.addLog time (Log.FailedToParseDiscordWebsocket name jsonError) model

        GotGuildMessageEmbed guildId channelId threadRouteWithMessage result ->
            case SeqDict.get guildId model.guilds of
                Just guild ->
                    case SeqDict.get channelId guild.channels of
                        Just channel ->
                            ( { model
                                | guilds =
                                    SeqDict.insert
                                        guildId
                                        { guild
                                            | channels =
                                                SeqDict.insert
                                                    channelId
                                                    (case threadRouteWithMessage of
                                                        NoThreadWithMessage messageId ->
                                                            LocalState.addEmbedBackend messageId result channel

                                                        ViewThreadWithMessage threadId messageId ->
                                                            { channel
                                                                | threads =
                                                                    SeqDict.updateIfExists
                                                                        threadId
                                                                        (LocalState.addEmbedBackend messageId result)
                                                                        channel.threads
                                                            }
                                                    )
                                                    guild.channels
                                        }
                                        model.guilds
                              }
                            , Broadcast.toGuild
                                guildId
                                (Server_GotGuildMessageEmbed
                                    guildId
                                    channelId
                                    threadRouteWithMessage
                                    (Tuple.mapSecond (Result.mapError (\_ -> ())) result)
                                    |> ServerChange
                                )
                                model
                            )

                        Nothing ->
                            ( model, Command.none )

                Nothing ->
                    ( model, Command.none )

        GotDmMessageEmbed channelId threadRouteWithMessage result ->
            case SeqDict.get channelId model.dmChannels of
                Just channel ->
                    let
                        ( userIdA, userIdB ) =
                            DmChannel.userIdsFromChannelId channelId
                    in
                    ( { model
                        | dmChannels =
                            SeqDict.insert
                                channelId
                                (case threadRouteWithMessage of
                                    NoThreadWithMessage messageId ->
                                        LocalState.addEmbedBackend messageId result channel

                                    ViewThreadWithMessage threadId messageId ->
                                        { channel
                                            | threads =
                                                SeqDict.updateIfExists
                                                    threadId
                                                    (LocalState.addEmbedBackend messageId result)
                                                    channel.threads
                                        }
                                )
                                model.dmChannels
                      }
                    , Broadcast.toDmChannel
                        userIdA
                        userIdB
                        (\otherUserId ->
                            Server_GotDmMessageEmbed
                                otherUserId
                                threadRouteWithMessage
                                (Tuple.mapSecond (Result.mapError (\_ -> ())) result)
                        )
                        model
                    )

                Nothing ->
                    ( model, Command.none )

        DiscordGotGuildMessageEmbed guildId channelId threadRouteWithMessage result ->
            case SeqDict.get guildId model.discordGuilds of
                Just guild ->
                    case SeqDict.get channelId guild.channels of
                        Just channel ->
                            ( { model
                                | discordGuilds =
                                    SeqDict.insert
                                        guildId
                                        { guild
                                            | channels =
                                                SeqDict.insert
                                                    channelId
                                                    (case threadRouteWithMessage of
                                                        NoThreadWithMessage messageId ->
                                                            LocalState.addEmbedBackend messageId result channel

                                                        ViewThreadWithMessage threadId messageId ->
                                                            { channel
                                                                | threads =
                                                                    SeqDict.updateIfExists
                                                                        threadId
                                                                        (LocalState.addEmbedBackend messageId result)
                                                                        channel.threads
                                                            }
                                                    )
                                                    guild.channels
                                        }
                                        model.discordGuilds
                              }
                            , Broadcast.toDiscordGuild
                                guildId
                                (Server_GotDiscordGuildMessageEmbed
                                    guildId
                                    channelId
                                    threadRouteWithMessage
                                    (Tuple.mapSecond (Result.mapError (\_ -> ())) result)
                                    |> ServerChange
                                )
                                model
                            )

                        Nothing ->
                            ( model, Command.none )

                Nothing ->
                    ( model, Command.none )

        DiscordGotDmMessageEmbed channelId messageId result ->
            case SeqDict.get channelId model.discordDmChannels of
                Just channel ->
                    ( { model
                        | discordDmChannels =
                            SeqDict.insert
                                channelId
                                (LocalState.addEmbedBackend messageId result channel)
                                model.discordDmChannels
                      }
                    , Broadcast.toDiscordDmChannel
                        channelId
                        (Server_GotDiscordDmMessageEmbed
                            channelId
                            messageId
                            (Tuple.mapSecond (Result.mapError (\_ -> ())) result)
                            |> ServerChange
                        )
                        model
                    )

                Nothing ->
                    ( model, Command.none )

        ExportBackendStep ->
            case model.exportState of
                Just exportState ->
                    let
                        ( progress, progressState ) =
                            handleExportBackendStep exportState.progress
                    in
                    ( case progressState of
                        Just progressState2 ->
                            { model | exportState = Just { exportState | progress = progressState2 } }

                        Nothing ->
                            { model | exportState = Nothing }
                    , Pages.Admin.ExportBackendProgress exportState.exportSubset progress
                        |> AdminToFrontend
                        |> Lamdera.sendToFrontend exportState.clientId
                    )

                Nothing ->
                    ( model, Command.none )

        ScheduledExportBackendStep time ->
            case model.scheduledExportState of
                Just exportState ->
                    let
                        ( progress, progressState ) =
                            handleExportBackendStep exportState

                        timestamp : String
                        timestamp =
                            String.fromInt (Time.toYear Time.utc time)
                                ++ "-"
                                ++ String.padLeft 2 '0' (String.fromInt (MyUi.monthToInt (Time.toMonth Time.utc time)))
                                ++ "-"
                                ++ String.padLeft 2 '0' (String.fromInt (Time.toDay Time.utc time))
                                ++ "-"
                                ++ String.padLeft 2 '0' (String.fromInt (Time.toHour Time.utc time))
                                ++ ":"
                                ++ String.padLeft 2 '0' (String.fromInt (Time.toMinute Time.utc time))
                                ++ ":"
                                ++ String.padLeft 2 '0' (String.fromInt (Time.toSecond Time.utc time))
                    in
                    ( { model | scheduledExportState = progressState }
                    , case progress of
                        Pages.Admin.ExportingFinalStep bytes ->
                            FileStatus.uploadBackup ("backend-export-" ++ timestamp ++ ".bin") bytes
                                |> Task.attempt (ScheduledExportUploadResult time)

                        _ ->
                            Command.none
                    )

                Nothing ->
                    ( model, Command.none )

        DiscordGotDataForJoinedOrCreatedGuild discordUserId guildId time result ->
            case ( result, SeqDict.get guildId model.discordGuilds ) of
                ( Ok guildData, Just guild ) ->
                    let
                        guild2 : DiscordBackendGuild
                        guild2 =
                            addDiscordGuildData discordUserId guildData guild
                    in
                    ( { model | discordGuilds = SeqDict.insert guildId guild2 model.discordGuilds }
                    , case SeqDict.get discordUserId model.discordUsers of
                        Just (FullData discordUser) ->
                            Broadcast.toUser
                                Nothing
                                Nothing
                                discordUser.linkedTo
                                (Server_DiscordGuildJoinedOrCreated
                                    guildId
                                    (BackendExtra.discordGuildToFrontend Nothing guild2)
                                    |> ServerChange
                                )
                                model

                        _ ->
                            Command.none
                    )

                ( Err error, _ ) ->
                    BackendExtra.addLog time (Log.FailedToGetDataForJoinedOrCreatedDiscordGuild discordUserId guildId error) model

                ( _, Nothing ) ->
                    ( model, Command.none )

        JoinedDiscordThread guildId result time ->
            case result of
                Ok () ->
                    ( model, Command.none )

                Err error ->
                    BackendExtra.addLog time (Log.JoinedDiscordThreadFailed guildId error) model

        ToBackendCompleted toBackendLog maybeUserId { startTime, endTime } ->
            let
                count =
                    Array.length model.toBackendLogs
            in
            ( { model
                | toBackendLogs =
                    Array.push
                        { toBackendLog = toBackendLog
                        , userId = maybeUserId
                        , startTime = startTime
                        , endTime = endTime
                        }
                        (if count > 10000 then
                            Array.slice (count - 5000) count model.toBackendLogs

                         else
                            model.toBackendLogs
                        )
              }
            , Command.none
            )

        GotDiscordGuildStickers userId results time ->
            let
                ( errors, stickers, newStickers ) =
                    List.foldl
                        (\( stickerId, result ) ( errors2, stickers2, newStickers2 ) ->
                            case result of
                                Ok uploadResponse ->
                                    case SeqDict.get stickerId stickers2 of
                                        Just sticker ->
                                            case Sticker.addUrl uploadResponse sticker of
                                                Ok sticker2 ->
                                                    ( errors2
                                                    , SeqDict.insert stickerId sticker2 stickers2
                                                    , SeqDict.insert stickerId sticker2 newStickers2
                                                    )

                                                Err () ->
                                                    ( errors2, stickers2, newStickers2 )

                                        Nothing ->
                                            ( errors2, stickers2, newStickers2 )

                                Err error ->
                                    ( ( stickerId, error ) :: errors2, stickers2, newStickers2 )
                        )
                        ( [], model.stickers, SeqDict.empty )
                        results
            in
            case List.Nonempty.fromList errors of
                Just nonempty ->
                    BackendExtra.addLog
                        time
                        (Log.FailedToLoadDiscordGuildStickers nonempty (List.length results))
                        { model
                            | stickers = stickers
                            , users = NonemptyDict.updateIfExists userId (User.addNewStickers newStickers) model.users
                        }

                Nothing ->
                    ( { model
                        | stickers = stickers
                        , users = NonemptyDict.updateIfExists userId (User.addNewStickers newStickers) model.users
                      }
                    , Broadcast.toUser
                        Nothing
                        Nothing
                        userId
                        (Server_LinkedDiscordUserStickersLoaded newStickers |> ServerChange)
                        model
                    )

        HourlyUpdate time ->
            let
                shouldExport : Bool
                shouldExport =
                    case model.lastScheduledExportTime of
                        Nothing ->
                            False

                        Just lastScheduledExportTime ->
                            Duration.from lastScheduledExportTime time |> Quantity.greaterThanOrEqualTo (Duration.hours 4)
            in
            ( if shouldExport then
                let
                    baseModel : BackendModel
                    baseModel =
                        { model
                            | guilds = SeqDict.empty
                            , dmChannels = SeqDict.empty
                            , discordGuilds = SeqDict.empty
                            , discordDmChannels = SeqDict.empty
                            , exportState = Nothing
                            , scheduledExportState = Nothing
                        }
                in
                { model
                    | scheduledExportState =
                        { baseModel = Bytes.Encode.encode (WireHelper.encodeBackendModel baseModel)
                        , remainingGuilds = SeqDict.toList model.guilds
                        , encodedGuilds = []
                        , remainingDmChannels = SeqDict.toList model.dmChannels
                        , encodedDmChannels = []
                        , remainingDiscordGuilds = SeqDict.toList model.discordGuilds
                        , encodedDiscordGuilds = []
                        , remainingDiscordDmChannels = SeqDict.toList model.discordDmChannels
                        , encodedDiscordDmChannels = []
                        }
                            |> Just
                    , lastScheduledExportTime = Just time
                }

              else
                { model
                    | lastScheduledExportTime =
                        case model.lastScheduledExportTime of
                            Just _ ->
                                model.lastScheduledExportTime

                            Nothing ->
                                Just time
                }
            , Discord.getStickerPacksPayload |> DiscordSync.http |> Task.attempt (GotDiscordStandardStickerPacks time)
            )

        GotDiscordStandardStickerPacks time result ->
            case result of
                Ok stickerPacks ->
                    let
                        ( stickers, discordStickers ) =
                            List.foldl
                                (\stickerPack state ->
                                    List.foldl
                                        (\sticker ( stickers2, discordStickers2 ) ->
                                            case OneToOne.second sticker.id discordStickers2 of
                                                Just stickerId ->
                                                    ( SeqDict.insert
                                                        stickerId
                                                        { url = DiscordStandardSticker sticker.id
                                                        , name = sticker.name
                                                        , format = sticker.formatType
                                                        }
                                                        stickers2
                                                    , discordStickers2
                                                    )

                                                Nothing ->
                                                    let
                                                        stickerId =
                                                            Id.nextId stickers2
                                                    in
                                                    ( SeqDict.insert
                                                        stickerId
                                                        { url = DiscordStandardSticker sticker.id
                                                        , name = sticker.name
                                                        , format = sticker.formatType
                                                        }
                                                        stickers2
                                                    , OneToOne.insert sticker.id stickerId discordStickers2
                                                    )
                                        )
                                        state
                                        stickerPack.stickers
                                )
                                ( model.stickers, model.discordStickers )
                                stickerPacks
                    in
                    ( { model | stickers = stickers, discordStickers = discordStickers }
                    , Command.none
                    )

                Err error ->
                    BackendExtra.addLog time (Log.FailedToLoadDiscordStandardStickerPacks error) model

        ScheduledExportUploadResult time result ->
            case result of
                Ok () ->
                    ( model, Command.none )

                Err error ->
                    BackendExtra.addLog time (Log.FailedToGenerateScheduledBackup error) model


addDiscordGuildData :
    Discord.Id Discord.UserId
    -> { guild : Discord.GatewayGuild, channels : List Discord.Channel, icon : Maybe FileStatus.UploadResponse }
    -> DiscordBackendGuild
    -> DiscordBackendGuild
addDiscordGuildData discordUserId data guild =
    { name = GuildName.fromStringLossy data.guild.properties.name
    , icon = Maybe.map .fileHash data.icon
    , channels =
        List.foldl
            (\channel channels ->
                SeqDict.update
                    channel.id
                    (\maybe ->
                        case maybe of
                            Just _ ->
                                maybe

                            Nothing ->
                                DiscordSync.addDiscordChannel channel
                    )
                    channels
            )
            guild.channels
            data.channels
    , membersAndOwner =
        MembersAndOwner.addMember discordUserId { joinedAt = Nothing } guild.membersAndOwner
            |> Result.withDefault guild.membersAndOwner
    , stickers = guild.stickers
    }


attachmentsUploadedHelper :
    BackendModel
    -> { a | attachments : List Discord.Attachment }
    -> List (Result Http.Error ( Discord.Id Discord.AttachmentId, FileStatus.UploadResponse ))
    -> ( SeqDict (Id FileId) { fileData : FileData, isSpoilered : Bool }, SeqDict DiscordAttachmentId DiscordAttachmentData )
attachmentsUploadedHelper model message results =
    let
        uploadResponses : SeqDict (Discord.Id Discord.AttachmentId) FileStatus.UploadResponse
        uploadResponses =
            List.filterMap Result.toMaybe results |> SeqDict.fromList
    in
    List.foldl
        (\attachment ( fileDataDict, discordAttachments ) ->
            let
                attachmentId =
                    DiscordAttachmentId.fromUrl attachment.url

                fileId : Id FileId
                fileId =
                    SeqDict.size fileDataDict + 1 |> Id.fromInt
            in
            case SeqDict.get attachmentId model.discordAttachments of
                Just { fileHash, imageMetadata } ->
                    ( SeqDict.insert
                        fileId
                        { fileData = DiscordSync.attachmentsToFileData attachment fileHash imageMetadata
                        , isSpoilered =
                            case attachment.flags of
                                Included flags ->
                                    flags.isSpoiler

                                Missing ->
                                    False
                        }
                        fileDataDict
                    , discordAttachments
                    )

                Nothing ->
                    case SeqDict.get attachment.id uploadResponses of
                        Just uploadResponse ->
                            ( SeqDict.insert
                                fileId
                                { fileData =
                                    DiscordSync.attachmentsToFileData
                                        attachment
                                        uploadResponse.fileHash
                                        uploadResponse.imageSize
                                , isSpoilered =
                                    case attachment.flags of
                                        Included flags ->
                                            flags.isSpoiler

                                        Missing ->
                                            False
                                }
                                fileDataDict
                            , SeqDict.insert
                                attachmentId
                                { fileHash = uploadResponse.fileHash, imageMetadata = uploadResponse.imageSize }
                                discordAttachments
                            )

                        Nothing ->
                            ( fileDataDict, discordAttachments )
        )
        ( SeqDict.empty, model.discordAttachments )
        message.attachments


disconnectClient : SessionId -> ClientId -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend msg )
disconnectClient sessionId clientId model =
    let
        model2 : BackendModel
        model2 =
            Pages.Admin.disconnectClient sessionId clientId model
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



--(
--
--List.filterMap
--    (\result ->
--        case result of
--            Ok ( attachmentId, { imageSize, fileHash } ) ->
--                case SeqDict.get attachmentId attachmentsDict of
--                    Just attachment ->
--                        { fileName = FileName.fromString attachment.filename
--                        , fileSize = attachment.size
--                        , imageMetadata = imageSize
--                        , contentType =
--                            case attachment.contentType of
--                                Included contentType ->
--                                    FileStatus.contentType contentType
--
--                                Missing ->
--                                    case imageSize of
--                                        Just _ ->
--                                            FileStatus.webpContent
--
--                                        Nothing ->
--                                            FileStatus.unknownContentType
--                        , fileHash = fileHash
--                        }
--                            |> Just
--
--                    Nothing ->
--                        Nothing
--
--            Err _ ->
--                Nothing
--    )
--    results
--    |> List.indexedMap (\index fileData -> ( Id.fromInt (index + 1), fileData ))
--    |> SeqDict.fromList
--, List.foldl
--    (\result dict ->
--        case result of
--            Ok ( attachment, uploadResponse ) ->
--                SeqDict.insert attachment.url uploadResponse.fileHash dict
--
--            Err _ ->
--                dict
--    )
--    existingDiscordAttachments
--    results
--)


updateFromFrontend :
    SessionId
    -> ClientId
    -> ToBackend
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
updateFromFrontend sessionId clientId msg model =
    ( model, Task.perform (BackendGotTime sessionId clientId msg) Time.now )


discordStartThread :
    DiscordFullUserData
    -> DiscordBackendChannel
    -> Discord.Id Discord.ChannelId
    -> Id ChannelMessageId
    -> Discord.Id Discord.MessageId
    -> { d | discordUsers : SeqDict (Discord.Id Discord.UserId) DiscordUserData }
    -> Task BackendOnly Discord.HttpError Discord.Channel
discordStartThread discordUser channel channelId threadId messageId model =
    Discord.startThreadFromMessagePayload
        (Discord.userToken discordUser.auth)
        { channelId = channelId
        , messageId = messageId
        , name =
            case DmChannel.getArray threadId channel.messages of
                Just message ->
                    case message of
                        UserTextMessage a ->
                            RichText.toStringWithGetter DiscordUserData.username model.discordUsers a.content

                        UserJoinedMessage _ userId _ ->
                            case SeqDict.get userId model.discordUsers of
                                Just (FullData user2) ->
                                    user2.user.username ++ " joined!"

                                Just (BasicData user2) ->
                                    user2.user.username ++ " joined!"

                                Just (NeedsAuthAgain user2) ->
                                    user2.user.username ++ " joined!"

                                Nothing ->
                                    "Thread"

                        DeletedMessage _ ->
                            "Message deleted"

                Nothing ->
                    "Thread"
        , autoArchiveDuration = Missing
        , rateLimitPerUser = Missing
        }
        |> DiscordSync.http


updateFromFrontendWithTime :
    Time.Posix
    -> SessionId
    -> ClientId
    -> ToBackend
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
updateFromFrontendWithTime time sessionId clientId msg model =
    case msg of
        CheckLoginRequest requestMessagesFor ->
            let
                cmd : Command BackendOnly ToFrontend backendMsg
                cmd =
                    case Broadcast.getUserFromSessionId sessionId model of
                        Just ( session, user ) ->
                            BackendExtra.getLoginData sessionId session user requestMessagesFor model
                                |> Ok
                                |> CheckLoginResponse
                                |> Lamdera.sendToFrontend clientId

                        Nothing ->
                            CheckLoginResponse (Err ()) |> Lamdera.sendToFrontend clientId
            in
            if model.isInitialized then
                ( model, cmd )

            else
                ( { model | isInitialized = True }
                , Command.batch
                    [ Http.request
                        { method = "GET"
                        , headers = [ Env.secretKeyHeader ]
                        , url = FileStatus.domain ++ "/file/internal/vapid"
                        , body = Http.emptyBody
                        , expect = Http.expectString GotVapidKeys
                        , timeout = Nothing
                        , tracker = Nothing
                        }
                    , Discord.getStickerPacksPayload |> DiscordSync.http |> Task.attempt (GotDiscordStandardStickerPacks time)
                    , cmd
                    ]
                )

        LoginWithTokenRequest requestMessagesFor loginCode userAgent ->
            BackendExtra.loginWithToken time sessionId clientId loginCode requestMessagesFor userAgent model

        FinishUserCreationRequest requestMessagesFor personName userAgent ->
            case SeqDict.get sessionId model.pendingLogins of
                Just (WaitingForUserDataForSignup pendingLogin) ->
                    if
                        NonemptyDict.values model.users
                            |> List.Nonempty.any (\a -> a.email == pendingLogin.emailAddress)
                    then
                        -- It's maybe possible to end up here if a user initiates two account creations for the same email address and then completes both. We'll just silently fail in that case, not worth the effort to give a good error message.
                        ( model, Command.none )

                    else
                        let
                            userId : Id UserId
                            userId =
                                Id.nextId (NonemptyDict.toSeqDict model.users)

                            session : UserSession
                            session =
                                UserSession.init
                                    sessionId
                                    userId
                                    (case requestMessagesFor of
                                        InitialLoadRequested_None ->
                                            Nothing

                                        InitialLoadRequested_Channel anyGuildOrDmId threadRoute ->
                                            Just ( anyGuildOrDmId, threadRoute )

                                        InitialLoadRequested_Admin _ ->
                                            Nothing
                                    )
                                    userAgent

                            newUser : BackendUser
                            newUser =
                                User.init time personName pendingLogin.emailAddress False

                            model3 : BackendModel
                            model3 =
                                { model
                                    | sessions = SeqDict.insert sessionId session model.sessions
                                    , pendingLogins = SeqDict.remove sessionId model.pendingLogins
                                    , users = NonemptyDict.insert userId newUser model.users
                                }
                        in
                        ( model3
                        , BackendExtra.getLoginData sessionId session newUser requestMessagesFor model3
                            |> LoginSuccess
                            |> LoginWithTokenResponse
                            |> Lamdera.sendToFrontends sessionId
                        )

                _ ->
                    ( model, Command.none )

        LoginWithTwoFactorRequest requestMessagesFor loginCode userAgent ->
            case SeqDict.get sessionId model.pendingLogins of
                Just (WaitingForTwoFactorToken pendingLogin) ->
                    if
                        (pendingLogin.loginAttempts < LoginForm.maxLoginAttempts)
                            && (Duration.from pendingLogin.creationTime time |> Quantity.lessThan Duration.hour)
                    then
                        case
                            ( NonemptyDict.get pendingLogin.userId model.users
                            , SeqDict.get pendingLogin.userId model.twoFactorAuthentication
                            )
                        of
                            ( Just user, Just { secret } ) ->
                                if TwoFactorAuthentication.isValidCode time loginCode secret then
                                    let
                                        session : UserSession
                                        session =
                                            UserSession.init
                                                sessionId
                                                pendingLogin.userId
                                                (case requestMessagesFor of
                                                    InitialLoadRequested_None ->
                                                        Nothing

                                                    InitialLoadRequested_Channel anyGuildOrDmId threadRoute ->
                                                        Just ( anyGuildOrDmId, threadRoute )

                                                    InitialLoadRequested_Admin _ ->
                                                        Nothing
                                                )
                                                userAgent
                                    in
                                    ( { model
                                        | sessions = SeqDict.insert sessionId session model.sessions
                                        , pendingLogins = SeqDict.remove sessionId model.pendingLogins
                                      }
                                    , Command.batch
                                        [ BackendExtra.getLoginData sessionId session user requestMessagesFor model
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

                                else
                                    ( { model
                                        | pendingLogins =
                                            SeqDict.insert
                                                sessionId
                                                (WaitingForTwoFactorToken
                                                    { pendingLogin | loginAttempts = pendingLogin.loginAttempts + 1 }
                                                )
                                                model.pendingLogins
                                      }
                                    , LoginTokenInvalid loginCode
                                        |> LoginWithTokenResponse
                                        |> Lamdera.sendToFrontend clientId
                                    )

                            _ ->
                                ( model
                                , LoginTokenInvalid loginCode
                                    |> LoginWithTokenResponse
                                    |> Lamdera.sendToFrontend clientId
                                )

                    else
                        ( model
                        , LoginTokenInvalid loginCode
                            |> LoginWithTokenResponse
                            |> Lamdera.sendToFrontend clientId
                        )

                _ ->
                    ( model
                    , LoginTokenInvalid loginCode |> LoginWithTokenResponse |> Lamdera.sendToFrontend clientId
                    )

        GetLoginTokenRequest email ->
            case Untrusted.emailAddress email of
                Just email2 ->
                    let
                        ( model3, result ) =
                            BackendExtra.getLoginCode time model
                    in
                    case
                        ( NonemptyDict.toList model3.users
                            |> List.Extra.find (\( _, user ) -> user.email == email2)
                        , result
                        )
                    of
                        ( Just ( userId, user ), Ok loginCode ) ->
                            if BackendExtra.shouldRateLimit time user then
                                let
                                    ( model4, cmd ) =
                                        BackendExtra.addLog time (Log.LoginsRateLimited userId) model3
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
                                , BackendExtra.sendLoginEmail (SentLoginEmail time email2) email2 loginCode
                                )

                        ( Nothing, Ok loginCode ) ->
                            if model3.signupsEnabled then
                                ( { model3
                                    | pendingLogins =
                                        SeqDict.insert
                                            sessionId
                                            (WaitingForLoginTokenForSignup
                                                { creationTime = time
                                                , loginAttempts = 0
                                                , emailAddress = email2
                                                , loginCode = loginCode
                                                }
                                            )
                                            model3.pendingLogins
                                  }
                                , BackendExtra.sendLoginEmail (SentLoginEmail time email2) email2 loginCode
                                )

                            else
                                ( model3, Lamdera.sendToFrontend clientId SignupsDisabledResponse )

                        ( _, Err () ) ->
                            ( model3, Command.none )

                Nothing ->
                    ( model, Command.none )

        AdminToBackend adminToBackend ->
            asAdmin
                model
                sessionId
                (\_ _ -> updateFromFrontendAdmin clientId adminToBackend model)

        LogOutRequest ->
            asUser
                model
                sessionId
                (\session _ ->
                    ( { model | sessions = SeqDict.remove sessionId model.sessions }
                    , Command.batch
                        [ Lamdera.sendToFrontends sessionId LoggedOutSession
                        , Broadcast.toUser
                            Nothing
                            (Just sessionId)
                            session.userId
                            (Server_LoggedOut session.sessionIdHash |> ServerChange)
                            model
                        ]
                    )
                )

        LocalModelChangeRequest changeId localMsg ->
            case localMsg of
                Local_Invalid ->
                    ( model, BackendExtra.invalidChangeResponse changeId clientId )

                Local_Admin adminChange ->
                    asAdmin
                        model
                        sessionId
                        (adminChangeUpdate clientId changeId adminChange model time)

                Local_SendMessage _ guildOrDmId text threadRoute attachedFiles ->
                    case guildOrDmId of
                        GuildOrDmId_Guild guildId channelId ->
                            asGuildMember
                                model
                                sessionId
                                guildId
                                (BackendExtra.sendGuildMessage
                                    model
                                    time
                                    clientId
                                    changeId
                                    guildId
                                    channelId
                                    threadRoute
                                    text
                                    (BackendExtra.validateAttachedFiles model.files attachedFiles)
                                )

                        GuildOrDmId_Dm otherUserId ->
                            asDmUser
                                model
                                sessionId
                                { otherUserId = otherUserId }
                                (BackendExtra.sendDm
                                    model
                                    time
                                    clientId
                                    changeId
                                    otherUserId
                                    threadRoute
                                    text
                                    (BackendExtra.validateAttachedFiles model.files attachedFiles)
                                )

                Local_Discord_SendMessage _ guildOrDmId text threadRouteWithMaybeReplyTo attachedFiles ->
                    case guildOrDmId of
                        DiscordGuildOrDmId_Guild currentDiscordUserId guildId channelId ->
                            asDiscordGuildMember
                                model
                                sessionId
                                guildId
                                currentDiscordUserId
                                (\_ discordUser _ guild ->
                                    case
                                        ( SeqDict.get channelId guild.channels
                                        , RateLimit.checkAndUpdateRateLimit time discordUser.linkedTo model.sendMessageRateLimits
                                        )
                                    of
                                        ( Just channel, Ok sendMessageRateLimits ) ->
                                            let
                                                attachedFiles2 : SeqDict (Id FileId) FileData
                                                attachedFiles2 =
                                                    BackendExtra.validateAttachedFiles model.files attachedFiles
                                            in
                                            case threadRouteWithMaybeReplyTo of
                                                NoThreadWithMaybeMessage maybeReplyTo ->
                                                    ( { model
                                                        | pendingDiscordCreateMessages =
                                                            SeqDict.insert
                                                                ( currentDiscordUserId, channelId )
                                                                ( clientId, changeId )
                                                                model.pendingDiscordCreateMessages
                                                        , sendMessageRateLimits = sendMessageRateLimits
                                                      }
                                                    , DiscordSync.sendMessage
                                                        discordUser
                                                        channelId
                                                        (case maybeReplyTo of
                                                            Just replyTo ->
                                                                OneToOne.first replyTo channel.linkedMessageIds

                                                            Nothing ->
                                                                Nothing
                                                        )
                                                        attachedFiles2
                                                        model.discordStickers
                                                        text
                                                        |> Task.attempt
                                                            (SentDiscordGuildMessage
                                                                time
                                                                changeId
                                                                sessionId
                                                                clientId
                                                                guildId
                                                                channelId
                                                                threadRouteWithMaybeReplyTo
                                                                currentDiscordUserId
                                                            )
                                                    )

                                                ViewThreadWithMaybeMessage threadId maybeReplyTo ->
                                                    case OneToOne.first threadId channel.linkedMessageIds of
                                                        Just messageId ->
                                                            let
                                                                thread : DiscordBackendThread
                                                                thread =
                                                                    SeqDict.get threadId channel.threads
                                                                        |> Maybe.withDefault Thread.discordBackendInit

                                                                discordThreadId : Discord.Id Discord.ChannelId
                                                                discordThreadId =
                                                                    Discord.idToUInt64 messageId |> Discord.idFromUInt64
                                                            in
                                                            ( { model
                                                                | pendingDiscordCreateMessages =
                                                                    SeqDict.insert
                                                                        ( currentDiscordUserId, discordThreadId )
                                                                        ( clientId, changeId )
                                                                        model.pendingDiscordCreateMessages
                                                                , sendMessageRateLimits = sendMessageRateLimits
                                                              }
                                                            , (case SeqDict.get threadId channel.threads of
                                                                Just _ ->
                                                                    Task.succeed ()

                                                                Nothing ->
                                                                    discordStartThread
                                                                        discordUser
                                                                        channel
                                                                        channelId
                                                                        threadId
                                                                        messageId
                                                                        model
                                                                        |> Task.map (\_ -> ())
                                                              )
                                                                |> Task.andThen
                                                                    (\() ->
                                                                        DiscordSync.sendMessage
                                                                            discordUser
                                                                            (Discord.idToUInt64 messageId |> Discord.idFromUInt64)
                                                                            (case maybeReplyTo of
                                                                                Just replyTo ->
                                                                                    OneToOne.first replyTo thread.linkedMessageIds

                                                                                Nothing ->
                                                                                    Nothing
                                                                            )
                                                                            attachedFiles2
                                                                            model.discordStickers
                                                                            text
                                                                    )
                                                                |> Task.attempt
                                                                    (SentDiscordGuildMessage
                                                                        time
                                                                        changeId
                                                                        sessionId
                                                                        clientId
                                                                        guildId
                                                                        channelId
                                                                        threadRouteWithMaybeReplyTo
                                                                        currentDiscordUserId
                                                                    )
                                                            )

                                                        _ ->
                                                            ( model, BackendExtra.invalidChangeResponse changeId clientId )

                                        _ ->
                                            ( model, BackendExtra.invalidChangeResponse changeId clientId )
                                )

                        DiscordGuildOrDmId_Dm data ->
                            asDiscordDmUser
                                model
                                sessionId
                                data
                                (\_ discordUser _ dmChannel ->
                                    let
                                        attachedFiles2 : SeqDict (Id FileId) FileData
                                        attachedFiles2 =
                                            BackendExtra.validateAttachedFiles model.files attachedFiles
                                    in
                                    case
                                        ( threadRouteWithMaybeReplyTo
                                        , RateLimit.checkAndUpdateRateLimit time discordUser.linkedTo model.sendMessageRateLimits
                                        )
                                    of
                                        ( NoThreadWithMaybeMessage maybeReplyTo, Ok sendMessageRateLimits ) ->
                                            ( { model
                                                | pendingDiscordCreateDmMessages =
                                                    SeqDict.insert
                                                        data
                                                        ( clientId, changeId )
                                                        model.pendingDiscordCreateDmMessages
                                                , sendMessageRateLimits = sendMessageRateLimits
                                              }
                                            , DiscordSync.sendMessage
                                                discordUser
                                                (Discord.idToUInt64 data.channelId |> Discord.idFromUInt64)
                                                (case maybeReplyTo of
                                                    Just replyTo ->
                                                        OneToOne.first replyTo dmChannel.linkedMessageIds

                                                    Nothing ->
                                                        Nothing
                                                )
                                                attachedFiles2
                                                model.discordStickers
                                                text
                                                |> Task.attempt
                                                    (SentDiscordDmMessage
                                                        time
                                                        changeId
                                                        sessionId
                                                        clientId
                                                        data.channelId
                                                        data.currentUserId
                                                    )
                                            )

                                        _ ->
                                            ( model, BackendExtra.invalidChangeResponse changeId clientId )
                                )

                Local_NewChannel _ guildId channelName ->
                    asGuildOwner
                        model
                        sessionId
                        guildId
                        (\userId _ guild ->
                            ( { model
                                | guilds =
                                    SeqDict.insert
                                        guildId
                                        (LocalState.createChannel time userId channelName guild)
                                        model.guilds
                              }
                            , Command.batch
                                [ Local_NewChannel time guildId channelName
                                    |> LocalChangeResponse changeId
                                    |> Lamdera.sendToFrontend clientId
                                , Broadcast.toGuildExcludingOne
                                    clientId
                                    guildId
                                    (Server_NewChannel time guildId channelName |> ServerChange)
                                    model
                                ]
                            )
                        )

                Local_EditChannel guildId channelId channelName ->
                    asGuildOwner
                        model
                        sessionId
                        guildId
                        (\_ _ guild ->
                            ( { model
                                | guilds =
                                    SeqDict.insert
                                        guildId
                                        (LocalState.editChannel channelName channelId guild)
                                        model.guilds
                              }
                            , Command.batch
                                [ LocalChangeResponse changeId localMsg
                                    |> Lamdera.sendToFrontend clientId
                                , Broadcast.toGuildExcludingOne
                                    clientId
                                    guildId
                                    (Server_EditChannel guildId channelId channelName |> ServerChange)
                                    model
                                ]
                            )
                        )

                Local_DeleteChannel guildId channelId ->
                    asGuildOwner
                        model
                        sessionId
                        guildId
                        (\userId _ guild ->
                            ( { model
                                | guilds =
                                    SeqDict.insert
                                        guildId
                                        (LocalState.deleteChannel time userId channelId guild)
                                        model.guilds
                              }
                            , Command.batch
                                [ LocalChangeResponse changeId localMsg
                                    |> Lamdera.sendToFrontend clientId
                                , Broadcast.toGuildExcludingOne
                                    clientId
                                    guildId
                                    (Server_DeleteChannel guildId channelId |> ServerChange)
                                    model
                                ]
                            )
                        )

                Local_NewInviteLink _ guildId _ ->
                    asGuildMember
                        model
                        sessionId
                        guildId
                        (\{ userId } _ guild ->
                            let
                                ( model3, id ) =
                                    SecretId.getShortUniqueId time model
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
                        model
                        sessionId
                        (\{ userId } _ ->
                            let
                                guildId : Id GuildId
                                guildId =
                                    Id.nextId model.guilds

                                newGuild : BackendGuild
                                newGuild =
                                    LocalState.createGuild time userId guildName
                            in
                            ( { model
                                | guilds = SeqDict.insert guildId newGuild model.guilds
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
                                    model
                                ]
                            )
                        )

                Local_MemberTyping _ ( guildOrDmId, threadRoute ) ->
                    case guildOrDmId of
                        GuildOrDmId (GuildOrDmId_Guild guildId channelId) ->
                            asGuildMember
                                model
                                sessionId
                                guildId
                                (\{ userId } _ guild ->
                                    ( { model
                                        | guilds =
                                            SeqDict.insert
                                                guildId
                                                (LocalState.updateChannel
                                                    (LocalState.memberIsTyping userId time threadRoute)
                                                    channelId
                                                    guild
                                                )
                                                model.guilds
                                      }
                                    , Command.batch
                                        [ Local_MemberTyping time ( guildOrDmId, threadRoute )
                                            |> LocalChangeResponse changeId
                                            |> Lamdera.sendToFrontend clientId
                                        , Broadcast.toGuildExcludingOne
                                            clientId
                                            guildId
                                            (Server_MemberTyping
                                                time
                                                userId
                                                (GuildOrDmId_Guild guildId channelId)
                                                threadRoute
                                                |> ServerChange
                                            )
                                            model
                                        ]
                                    )
                                )

                        GuildOrDmId (GuildOrDmId_Dm otherUserId) ->
                            asDmUser
                                model
                                sessionId
                                { otherUserId = otherUserId }
                                (\{ userId } _ dmChannelId _ ->
                                    ( { model
                                        | dmChannels =
                                            SeqDict.updateIfExists
                                                dmChannelId
                                                (LocalState.memberIsTyping userId time threadRoute)
                                                model.dmChannels
                                      }
                                    , Command.batch
                                        [ Local_MemberTyping time ( guildOrDmId, threadRoute )
                                            |> LocalChangeResponse changeId
                                            |> Lamdera.sendToFrontend clientId
                                        , Broadcast.toUser
                                            (Just clientId)
                                            Nothing
                                            otherUserId
                                            (Server_MemberTyping time userId (GuildOrDmId_Dm userId) threadRoute
                                                |> ServerChange
                                            )
                                            model
                                        ]
                                    )
                                )

                        DiscordGuildOrDmId (DiscordGuildOrDmId_Guild currentDiscordUserId guildId channelId) ->
                            asDiscordGuildMember
                                model
                                sessionId
                                guildId
                                currentDiscordUserId
                                (\_ userData _ guild ->
                                    case SeqDict.get channelId guild.channels of
                                        Just channel ->
                                            let
                                                discordChannelId : Maybe (Discord.Id Discord.ChannelId)
                                                discordChannelId =
                                                    case threadRoute of
                                                        NoThread ->
                                                            Just channelId

                                                        ViewThread threadId ->
                                                            case OneToOne.first threadId channel.linkedMessageIds of
                                                                Just messageId ->
                                                                    Discord.idToUInt64 messageId
                                                                        |> Discord.idFromUInt64
                                                                        |> Just

                                                                Nothing ->
                                                                    Nothing
                                            in
                                            ( { model
                                                | discordGuilds =
                                                    SeqDict.insert
                                                        guildId
                                                        { guild
                                                            | channels =
                                                                SeqDict.insert
                                                                    channelId
                                                                    (LocalState.memberIsTyping
                                                                        currentDiscordUserId
                                                                        time
                                                                        threadRoute
                                                                        channel
                                                                    )
                                                                    guild.channels
                                                        }
                                                        model.discordGuilds
                                              }
                                            , Command.batch
                                                [ Local_MemberTyping time ( guildOrDmId, threadRoute )
                                                    |> LocalChangeResponse changeId
                                                    |> Lamdera.sendToFrontend clientId
                                                , Broadcast.toDiscordGuildExcludingOne
                                                    clientId
                                                    guildId
                                                    (Server_DiscordGuildMemberTyping
                                                        time
                                                        currentDiscordUserId
                                                        guildId
                                                        channelId
                                                        threadRoute
                                                        |> ServerChange
                                                    )
                                                    model
                                                , case discordChannelId of
                                                    Just discordChannelId2 ->
                                                        Discord.triggerTypingIndicatorPayload
                                                            (Discord.userToken userData.auth)
                                                            discordChannelId2
                                                            |> DiscordSync.http
                                                            |> Task.attempt (\_ -> DiscordTypingIndicatorSent)

                                                    Nothing ->
                                                        Command.none
                                                ]
                                            )

                                        Nothing ->
                                            ( model, BackendExtra.invalidChangeResponse changeId clientId )
                                )

                        DiscordGuildOrDmId (DiscordGuildOrDmId_Dm data) ->
                            asDiscordDmUser
                                model
                                sessionId
                                data
                                (\_ userData _ dmChannel ->
                                    ( { model
                                        | discordDmChannels =
                                            SeqDict.insert
                                                data.channelId
                                                (LocalState.memberIsTypingHelper data.currentUserId time dmChannel)
                                                model.discordDmChannels
                                      }
                                    , Command.batch
                                        [ Local_MemberTyping time ( guildOrDmId, threadRoute )
                                            |> LocalChangeResponse changeId
                                            |> Lamdera.sendToFrontend clientId
                                        , Broadcast.toDiscordDmChannelExcludingOne
                                            clientId
                                            data.channelId
                                            (Server_DiscordDmMemberTyping time data.currentUserId data.channelId
                                                |> ServerChange
                                            )
                                            model
                                        , Discord.triggerTypingIndicatorPayload
                                            (Discord.userToken userData.auth)
                                            (Discord.idToUInt64 data.channelId |> Discord.idFromUInt64)
                                            |> DiscordSync.http
                                            |> Task.attempt (\_ -> DiscordTypingIndicatorSent)
                                        ]
                                    )
                                )

                Local_AddReactionEmoji guildOrDmId threadRoute emoji ->
                    case guildOrDmId of
                        GuildOrDmId (GuildOrDmId_Guild guildId channelId) ->
                            asGuildMember
                                model
                                sessionId
                                guildId
                                (\{ userId } user guild ->
                                    ( { model
                                        | guilds =
                                            SeqDict.insert
                                                guildId
                                                (LocalState.updateChannel (LocalState.addReactionEmoji emoji userId threadRoute) channelId guild)
                                                model.guilds
                                        , users = NonemptyDict.insert userId (User.addRecentlyUsedEmoji emoji user) model.users
                                      }
                                    , Command.batch
                                        [ Lamdera.sendToFrontend clientId (LocalChangeResponse changeId localMsg)
                                        , Broadcast.toGuild
                                            guildId
                                            (Server_AddReactionEmoji userId (GuildOrDmId_Guild guildId channelId) threadRoute emoji |> ServerChange)
                                            model
                                        ]
                                    )
                                )

                        GuildOrDmId (GuildOrDmId_Dm otherUserId) ->
                            asDmUser
                                model
                                sessionId
                                { otherUserId = otherUserId }
                                (\{ userId } user dmChannelId _ ->
                                    ( { model
                                        | dmChannels =
                                            SeqDict.updateIfExists
                                                dmChannelId
                                                (LocalState.addReactionEmoji emoji userId threadRoute)
                                                model.dmChannels
                                        , users = NonemptyDict.insert userId (User.addRecentlyUsedEmoji emoji user) model.users
                                      }
                                    , Command.batch
                                        [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                                        , Broadcast.toDmChannelExcludingOne
                                            clientId
                                            userId
                                            otherUserId
                                            (\otherUserId2 ->
                                                Server_AddReactionEmoji
                                                    userId
                                                    (GuildOrDmId_Dm otherUserId2)
                                                    threadRoute
                                                    emoji
                                            )
                                            model
                                        ]
                                    )
                                )

                        DiscordGuildOrDmId (DiscordGuildOrDmId_Guild currentUserId guildId channelId) ->
                            asDiscordGuildMember
                                model
                                sessionId
                                guildId
                                currentUserId
                                (\session userData user guild ->
                                    case SeqDict.get channelId guild.channels of
                                        Just channel ->
                                            ( { model
                                                | discordGuilds =
                                                    SeqDict.insert
                                                        guildId
                                                        (LocalState.updateChannel
                                                            (LocalState.addReactionEmoji emoji currentUserId threadRoute)
                                                            channelId
                                                            guild
                                                        )
                                                        model.discordGuilds
                                                , users = NonemptyDict.insert session.userId (User.addRecentlyUsedEmoji emoji user) model.users
                                              }
                                            , Command.batch
                                                [ Lamdera.sendToFrontend clientId (LocalChangeResponse changeId localMsg)
                                                , Broadcast.toDiscordGuildExcludingOne
                                                    clientId
                                                    guildId
                                                    (Server_DiscordAddReactionGuildEmoji currentUserId guildId channelId threadRoute emoji
                                                        |> ServerChange
                                                    )
                                                    model
                                                , case threadRouteToDiscordMessageId channelId channel threadRoute of
                                                    Just ( discordChannelId, discordMessageId ) ->
                                                        Discord.createReactionPayload
                                                            (Discord.userToken userData.auth)
                                                            { channelId = discordChannelId
                                                            , messageId = discordMessageId
                                                            , emoji = Emoji.toString emoji |> Discord.UnicodeEmoji
                                                            }
                                                            |> DiscordSync.http
                                                            |> Task.attempt
                                                                (DiscordAddedReactionToGuildMessage
                                                                    time
                                                                    guildId
                                                                    channelId
                                                                    threadRoute
                                                                    discordMessageId
                                                                    emoji
                                                                )

                                                    Nothing ->
                                                        Command.none
                                                ]
                                            )

                                        Nothing ->
                                            ( model
                                            , BackendExtra.invalidChangeResponse changeId clientId
                                            )
                                )

                        DiscordGuildOrDmId (DiscordGuildOrDmId_Dm data) ->
                            asDiscordDmUser
                                model
                                sessionId
                                data
                                (\session userData user channel ->
                                    case threadRoute of
                                        NoThreadWithMessage messageId ->
                                            ( { model
                                                | discordDmChannels =
                                                    SeqDict.updateIfExists
                                                        data.channelId
                                                        (LocalState.addReactionEmojiHelper emoji data.currentUserId messageId)
                                                        model.discordDmChannels
                                                , users = NonemptyDict.insert session.userId (User.addRecentlyUsedEmoji emoji user) model.users
                                              }
                                            , Command.batch
                                                [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                                                , Broadcast.toDiscordDmChannelExcludingOne
                                                    clientId
                                                    data.channelId
                                                    (Server_DiscordAddReactionDmEmoji
                                                        data.currentUserId
                                                        data.channelId
                                                        messageId
                                                        emoji
                                                        |> ServerChange
                                                    )
                                                    model
                                                , case OneToOne.first messageId channel.linkedMessageIds of
                                                    Just discordMessageId ->
                                                        Discord.createReactionPayload
                                                            (Discord.userToken userData.auth)
                                                            { channelId = Discord.idToUInt64 data.channelId |> Discord.idFromUInt64
                                                            , messageId = discordMessageId
                                                            , emoji = Emoji.toString emoji |> Discord.UnicodeEmoji
                                                            }
                                                            |> DiscordSync.http
                                                            |> Task.attempt
                                                                (DiscordAddedReactionToDmMessage
                                                                    time
                                                                    data.channelId
                                                                    messageId
                                                                    discordMessageId
                                                                    emoji
                                                                )

                                                    Nothing ->
                                                        Command.none
                                                ]
                                            )

                                        ViewThreadWithMessage _ _ ->
                                            ( model, Command.none )
                                )

                Local_RemoveReactionEmoji guildOrDmId threadRoute emoji ->
                    case guildOrDmId of
                        GuildOrDmId (GuildOrDmId_Guild guildId channelId) ->
                            asGuildMember
                                model
                                sessionId
                                guildId
                                (\{ userId } _ guild ->
                                    ( { model
                                        | guilds =
                                            SeqDict.insert
                                                guildId
                                                (LocalState.updateChannel
                                                    (LocalState.removeReactionEmoji emoji userId threadRoute)
                                                    channelId
                                                    guild
                                                )
                                                model.guilds
                                      }
                                    , Command.batch
                                        [ Local_RemoveReactionEmoji guildOrDmId threadRoute emoji
                                            |> LocalChangeResponse changeId
                                            |> Lamdera.sendToFrontend clientId
                                        , Broadcast.toGuildExcludingOne
                                            clientId
                                            guildId
                                            (Server_RemoveReactionEmoji
                                                userId
                                                (GuildOrDmId_Guild guildId channelId)
                                                threadRoute
                                                emoji
                                                |> ServerChange
                                            )
                                            model
                                        ]
                                    )
                                )

                        GuildOrDmId (GuildOrDmId_Dm otherUserId) ->
                            asDmUser
                                model
                                sessionId
                                { otherUserId = otherUserId }
                                (\{ userId } _ dmChannelId _ ->
                                    ( { model
                                        | dmChannels =
                                            SeqDict.updateIfExists
                                                dmChannelId
                                                (LocalState.removeReactionEmoji emoji userId threadRoute)
                                                model.dmChannels
                                      }
                                    , Command.batch
                                        [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                                        , Broadcast.toDmChannelExcludingOne
                                            clientId
                                            userId
                                            otherUserId
                                            (\otherUserId2 ->
                                                Server_RemoveReactionEmoji
                                                    userId
                                                    (GuildOrDmId_Dm otherUserId2)
                                                    threadRoute
                                                    emoji
                                            )
                                            model
                                        ]
                                    )
                                )

                        DiscordGuildOrDmId (DiscordGuildOrDmId_Guild currentUserId guildId channelId) ->
                            asDiscordGuildMember
                                model
                                sessionId
                                guildId
                                currentUserId
                                (\_ userData _ guild ->
                                    case SeqDict.get channelId guild.channels of
                                        Just channel ->
                                            ( { model
                                                | discordGuilds =
                                                    SeqDict.insert
                                                        guildId
                                                        (LocalState.updateChannel
                                                            (LocalState.removeReactionEmoji emoji currentUserId threadRoute)
                                                            channelId
                                                            guild
                                                        )
                                                        model.discordGuilds
                                              }
                                            , Command.batch
                                                [ Lamdera.sendToFrontend clientId (LocalChangeResponse changeId localMsg)
                                                , Broadcast.toDiscordGuildExcludingOne
                                                    clientId
                                                    guildId
                                                    (Server_DiscordRemoveReactionGuildEmoji
                                                        currentUserId
                                                        guildId
                                                        channelId
                                                        threadRoute
                                                        emoji
                                                        |> ServerChange
                                                    )
                                                    model
                                                , case threadRouteToDiscordMessageId channelId channel threadRoute of
                                                    Just ( discordChannelId, discordMessageId ) ->
                                                        Discord.deleteOwnReactionPayload
                                                            (Discord.userToken userData.auth)
                                                            { channelId = discordChannelId
                                                            , messageId = discordMessageId
                                                            , emoji = Emoji.toString emoji |> Discord.UnicodeEmoji
                                                            }
                                                            |> DiscordSync.http
                                                            |> Task.attempt
                                                                (DiscordRemovedReactionToGuildMessage
                                                                    time
                                                                    guildId
                                                                    channelId
                                                                    threadRoute
                                                                    discordMessageId
                                                                    emoji
                                                                )

                                                    Nothing ->
                                                        Command.none
                                                ]
                                            )

                                        Nothing ->
                                            ( model
                                            , BackendExtra.invalidChangeResponse changeId clientId
                                            )
                                )

                        DiscordGuildOrDmId (DiscordGuildOrDmId_Dm data) ->
                            asDiscordDmUser
                                model
                                sessionId
                                data
                                (\_ userData _ channel ->
                                    case threadRoute of
                                        NoThreadWithMessage messageId ->
                                            ( { model
                                                | discordDmChannels =
                                                    SeqDict.updateIfExists
                                                        data.channelId
                                                        (LocalState.removeReactionEmojiHelper emoji data.currentUserId messageId)
                                                        model.discordDmChannels
                                              }
                                            , Command.batch
                                                [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                                                , Broadcast.toDiscordDmChannelExcludingOne
                                                    clientId
                                                    data.channelId
                                                    (Server_DiscordRemoveReactionDmEmoji
                                                        data.currentUserId
                                                        data.channelId
                                                        messageId
                                                        emoji
                                                        |> ServerChange
                                                    )
                                                    model
                                                , case OneToOne.first messageId channel.linkedMessageIds of
                                                    Just discordMessageId ->
                                                        Discord.deleteOwnReactionPayload
                                                            (Discord.userToken userData.auth)
                                                            { channelId = Discord.idToUInt64 data.channelId |> Discord.idFromUInt64
                                                            , messageId = discordMessageId
                                                            , emoji = Emoji.toString emoji |> Discord.UnicodeEmoji
                                                            }
                                                            |> DiscordSync.http
                                                            |> Task.attempt
                                                                (DiscordRemovedReactionToDmMessage
                                                                    time
                                                                    data.channelId
                                                                    messageId
                                                                    discordMessageId
                                                                    emoji
                                                                )

                                                    Nothing ->
                                                        Command.none
                                                ]
                                            )

                                        ViewThreadWithMessage _ _ ->
                                            ( model, Command.none )
                                )

                Local_SendEditMessage _ guildOrDmId threadRoute newContent attachedFiles ->
                    let
                        attachedFiles2 : SeqDict (Id FileId) FileData
                        attachedFiles2 =
                            BackendExtra.validateAttachedFiles model.files attachedFiles
                    in
                    case guildOrDmId of
                        GuildOrDmId_Guild guildId channelId ->
                            asGuildMember
                                model
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
                                        model
                                        userId
                                        guild
                                )

                        GuildOrDmId_Dm otherUserId ->
                            asDmUser
                                model
                                sessionId
                                { otherUserId = otherUserId }
                                (\{ userId } _ dmChannelId dmChannel ->
                                    case
                                        LocalState.editMessageHelper
                                            time
                                            userId
                                            newContent
                                            (ChangeAttachments attachedFiles2)
                                            threadRoute
                                            dmChannel
                                    of
                                        Ok dmChannel2 ->
                                            ( { model
                                                | dmChannels = SeqDict.insert dmChannelId dmChannel2 model.dmChannels
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
                                                , Broadcast.toDmChannelExcludingOne
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
                                                    model
                                                ]
                                            )

                                        Err () ->
                                            ( model
                                            , BackendExtra.invalidChangeResponse changeId clientId
                                            )
                                )

                Local_Discord_SendEditGuildMessage _ currentUserId guildId channelId threadRoute newContent ->
                    asDiscordGuildMember
                        model
                        sessionId
                        guildId
                        currentUserId
                        (\_ userData _ guild ->
                            case SeqDict.get channelId guild.channels of
                                Just channel ->
                                    case
                                        LocalState.editMessageHelper
                                            time
                                            currentUserId
                                            newContent
                                            DoNotChangeAttachments
                                            threadRoute
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
                                            , Command.batch
                                                [ Local_Discord_SendEditGuildMessage
                                                    time
                                                    currentUserId
                                                    guildId
                                                    channelId
                                                    threadRoute
                                                    newContent
                                                    |> LocalChangeResponse changeId
                                                    |> Lamdera.sendToFrontend clientId
                                                , Broadcast.toDiscordGuildExcludingOne
                                                    clientId
                                                    guildId
                                                    (Server_DiscordSendEditGuildMessage
                                                        time
                                                        currentUserId
                                                        guildId
                                                        channelId
                                                        threadRoute
                                                        newContent
                                                        |> ServerChange
                                                    )
                                                    model
                                                , case threadRouteToDiscordMessageId channelId channel2 threadRoute of
                                                    Just ( discordChannelId, discordMessageId ) ->
                                                        Discord.editMessagePayload
                                                            (Discord.userToken userData.auth)
                                                            { channelId = discordChannelId
                                                            , messageId = discordMessageId
                                                            , content =
                                                                case RichText.removeAttachedFile (\_ -> True) newContent of
                                                                    Just text2 ->
                                                                        RichText.toDiscord text2 |> Discord.Markdown.toString

                                                                    Nothing ->
                                                                        ""
                                                            }
                                                            |> DiscordSync.http
                                                            |> Task.attempt
                                                                (EditedDiscordGuildMessage
                                                                    time
                                                                    guildId
                                                                    channelId
                                                                    threadRoute
                                                                    discordMessageId
                                                                )

                                                    Nothing ->
                                                        Command.none
                                                ]
                                            )

                                        Err () ->
                                            ( model
                                            , BackendExtra.invalidChangeResponse changeId clientId
                                            )

                                Nothing ->
                                    ( model
                                    , BackendExtra.invalidChangeResponse changeId clientId
                                    )
                        )

                Local_Discord_SendEditDmMessage _ dmData messageId newContent ->
                    asDiscordDmUser
                        model
                        sessionId
                        dmData
                        (\_ userData _ channel ->
                            case
                                LocalState.editMessageHelperNoThread
                                    time
                                    dmData.currentUserId
                                    newContent
                                    DoNotChangeAttachments
                                    messageId
                                    channel
                            of
                                Ok channel2 ->
                                    ( { model
                                        | discordDmChannels =
                                            SeqDict.insert dmData.channelId channel2 model.discordDmChannels
                                      }
                                    , Command.batch
                                        [ Local_Discord_SendEditDmMessage time dmData messageId newContent
                                            |> LocalChangeResponse changeId
                                            |> Lamdera.sendToFrontend clientId
                                        , Broadcast.toDiscordDmChannelExcludingOne
                                            clientId
                                            dmData.channelId
                                            (Server_DiscordSendEditDmMessage
                                                time
                                                dmData
                                                messageId
                                                newContent
                                                |> ServerChange
                                            )
                                            model
                                        , case OneToOne.first messageId channel2.linkedMessageIds of
                                            Just discordMessageId ->
                                                Discord.editMessagePayload
                                                    (Discord.userToken userData.auth)
                                                    { channelId = Discord.idToUInt64 dmData.channelId |> Discord.idFromUInt64
                                                    , messageId = discordMessageId
                                                    , content =
                                                        RichText.toDiscord newContent
                                                            |> Discord.Markdown.toString
                                                    }
                                                    |> DiscordSync.http
                                                    |> Task.attempt
                                                        (EditedDiscordDmMessage time dmData.channelId messageId discordMessageId)

                                            Nothing ->
                                                Command.none
                                        ]
                                    )

                                Err () ->
                                    ( model
                                    , BackendExtra.invalidChangeResponse changeId clientId
                                    )
                        )

                Local_MemberEditTyping _ guildOrDmId threadRoute ->
                    case guildOrDmId of
                        GuildOrDmId (GuildOrDmId_Guild guildId channelId) ->
                            asGuildMember
                                model
                                sessionId
                                guildId
                                (\{ userId } _ guild ->
                                    case LocalState.memberIsEditTypingBackend userId time channelId threadRoute guild of
                                        Ok guild2 ->
                                            ( { model | guilds = SeqDict.insert guildId guild2 model.guilds }
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
                                                    model
                                                ]
                                            )

                                        Err () ->
                                            ( model
                                            , BackendExtra.invalidChangeResponse changeId clientId
                                            )
                                )

                        GuildOrDmId (GuildOrDmId_Dm otherUserId) ->
                            asDmUser
                                model
                                sessionId
                                { otherUserId = otherUserId }
                                (\{ userId } _ dmChannelId dmChannel ->
                                    case LocalState.memberIsEditTypingBackendHelper time userId threadRoute dmChannel of
                                        Ok dmChannel2 ->
                                            ( { model
                                                | dmChannels =
                                                    SeqDict.insert dmChannelId dmChannel2 model.dmChannels
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
                                                        (GuildOrDmId (GuildOrDmId_Dm userId))
                                                        threadRoute
                                                        |> ServerChange
                                                    )
                                                    model
                                                ]
                                            )

                                        Err _ ->
                                            ( model
                                            , BackendExtra.invalidChangeResponse changeId clientId
                                            )
                                )

                        DiscordGuildOrDmId (DiscordGuildOrDmId_Guild currentUserId guildId channelId) ->
                            asDiscordGuildMember
                                model
                                sessionId
                                guildId
                                currentUserId
                                (\session _ _ guild ->
                                    case LocalState.memberIsEditTypingBackend currentUserId time channelId threadRoute guild of
                                        Ok guild2 ->
                                            ( { model | discordGuilds = SeqDict.insert guildId guild2 model.discordGuilds }
                                            , Command.batch
                                                [ Local_MemberEditTyping time guildOrDmId threadRoute
                                                    |> LocalChangeResponse changeId
                                                    |> Lamdera.sendToFrontend clientId
                                                , Broadcast.toDiscordGuildExcludingOne
                                                    clientId
                                                    guildId
                                                    (Server_MemberEditTyping time session.userId guildOrDmId threadRoute
                                                        |> ServerChange
                                                    )
                                                    model
                                                ]
                                            )

                                        Err () ->
                                            ( model
                                            , BackendExtra.invalidChangeResponse changeId clientId
                                            )
                                )

                        DiscordGuildOrDmId (DiscordGuildOrDmId_Dm data) ->
                            asDiscordDmUser
                                model
                                sessionId
                                data
                                (\session _ _ channel ->
                                    case threadRoute of
                                        ViewThreadWithMessage _ _ ->
                                            ( model
                                            , BackendExtra.invalidChangeResponse changeId clientId
                                            )

                                        NoThreadWithMessage messageId ->
                                            case
                                                LocalState.memberIsEditTypingBackendHelperNoThread
                                                    time
                                                    data.currentUserId
                                                    messageId
                                                    channel
                                            of
                                                Ok channel2 ->
                                                    ( { model
                                                        | discordDmChannels =
                                                            SeqDict.insert data.channelId channel2 model.discordDmChannels
                                                      }
                                                    , Command.batch
                                                        [ Local_MemberEditTyping time guildOrDmId threadRoute
                                                            |> LocalChangeResponse changeId
                                                            |> Lamdera.sendToFrontend clientId
                                                        , Broadcast.toDiscordDmChannelExcludingOne
                                                            clientId
                                                            data.channelId
                                                            (Server_MemberEditTyping
                                                                time
                                                                session.userId
                                                                guildOrDmId
                                                                threadRoute
                                                                |> ServerChange
                                                            )
                                                            model
                                                        ]
                                                    )

                                                Err () ->
                                                    ( model
                                                    , BackendExtra.invalidChangeResponse changeId clientId
                                                    )
                                )

                Local_SetLastViewed guildOrDmId threadRoute ->
                    let
                        helper session user =
                            ( { model
                                | users =
                                    NonemptyDict.insert
                                        session.userId
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
                                        model.users
                              }
                            , Command.batch
                                [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                                , Broadcast.toUser
                                    (Just clientId)
                                    Nothing
                                    session.userId
                                    (LocalChange session.userId localMsg)
                                    model
                                ]
                            )
                    in
                    case guildOrDmId of
                        GuildOrDmId (GuildOrDmId_Guild guildId _) ->
                            asGuildMember model sessionId guildId (\session user _ -> helper session user)

                        GuildOrDmId (GuildOrDmId_Dm otherUserId) ->
                            asDmUser
                                model
                                sessionId
                                { otherUserId = otherUserId }
                                (\session user _ _ -> helper session user)

                        DiscordGuildOrDmId (DiscordGuildOrDmId_Guild userId guildId _) ->
                            asDiscordGuildMember_AllowUserThatNeedsAuthAgain
                                model
                                sessionId
                                guildId
                                userId
                                (\session _ user _ -> helper session user)

                        DiscordGuildOrDmId (DiscordGuildOrDmId_Dm data) ->
                            asDiscordDmUser_AllowUserThatNeedsAuthAgain
                                model
                                sessionId
                                data
                                (\session _ user _ -> helper session user)

                Local_DeleteMessage guildOrDmId threadRoute ->
                    case guildOrDmId of
                        GuildOrDmId (GuildOrDmId_Guild guildId channelId) ->
                            asGuildMember
                                model
                                sessionId
                                guildId
                                (\{ userId } _ guild ->
                                    case LocalState.deleteMessageBackend userId channelId threadRoute guild of
                                        Ok ( guild2, _ ) ->
                                            ( { model | guilds = SeqDict.insert guildId guild2 model.guilds }
                                            , Command.batch
                                                [ Lamdera.sendToFrontend
                                                    clientId
                                                    (LocalChangeResponse changeId localMsg)
                                                , Broadcast.toGuildExcludingOne
                                                    clientId
                                                    guildId
                                                    (Server_DeleteMessage guildOrDmId threadRoute |> ServerChange)
                                                    model
                                                ]
                                            )

                                        Err _ ->
                                            ( model
                                            , BackendExtra.invalidChangeResponse changeId clientId
                                            )
                                )

                        GuildOrDmId (GuildOrDmId_Dm otherUserId) ->
                            asDmUser
                                model
                                sessionId
                                { otherUserId = otherUserId }
                                (\{ userId } _ dmChannelId dmChannel ->
                                    case LocalState.deleteMessageBackendHelper userId threadRoute dmChannel of
                                        Ok dmChannel2 ->
                                            ( { model | dmChannels = SeqDict.insert dmChannelId dmChannel2 model.dmChannels }
                                            , Command.batch
                                                [ Lamdera.sendToFrontend
                                                    clientId
                                                    (LocalChangeResponse changeId localMsg)
                                                , Broadcast.toDmChannelExcludingOne
                                                    clientId
                                                    userId
                                                    otherUserId
                                                    (\otherUserId2 ->
                                                        Server_DeleteMessage
                                                            (GuildOrDmId (GuildOrDmId_Dm otherUserId2))
                                                            threadRoute
                                                    )
                                                    model
                                                ]
                                            )

                                        Err _ ->
                                            ( model
                                            , BackendExtra.invalidChangeResponse changeId clientId
                                            )
                                )

                        DiscordGuildOrDmId (DiscordGuildOrDmId_Guild currentUserId guildId channelId) ->
                            asDiscordGuildMember
                                model
                                sessionId
                                guildId
                                currentUserId
                                (\_ userData _ guild ->
                                    case LocalState.deleteMessageBackend currentUserId channelId threadRoute guild of
                                        Ok ( guild2, channel ) ->
                                            ( { model | discordGuilds = SeqDict.insert guildId guild2 model.discordGuilds }
                                            , Command.batch
                                                [ Lamdera.sendToFrontend
                                                    clientId
                                                    (LocalChangeResponse changeId localMsg)
                                                , Broadcast.toDiscordGuildExcludingOne
                                                    clientId
                                                    guildId
                                                    (Server_DeleteMessage guildOrDmId threadRoute |> ServerChange)
                                                    model
                                                , case threadRouteToDiscordMessageId channelId channel threadRoute of
                                                    Just ( discordChannelId, discordMessageId ) ->
                                                        Discord.deleteMessagePayload
                                                            (Discord.userToken userData.auth)
                                                            { channelId = discordChannelId
                                                            , messageId = discordMessageId
                                                            }
                                                            |> DiscordSync.http
                                                            |> Task.attempt
                                                                (DeletedDiscordGuildMessage
                                                                    time
                                                                    guildId
                                                                    channelId
                                                                    threadRoute
                                                                    discordMessageId
                                                                )

                                                    Nothing ->
                                                        Command.none
                                                ]
                                            )

                                        Err _ ->
                                            ( model
                                            , BackendExtra.invalidChangeResponse changeId clientId
                                            )
                                )

                        DiscordGuildOrDmId (DiscordGuildOrDmId_Dm data) ->
                            asDiscordDmUser
                                model
                                sessionId
                                data
                                (\_ userData _ channel ->
                                    case threadRoute of
                                        NoThreadWithMessage messageId ->
                                            let
                                                oldChannel =
                                                    channel
                                            in
                                            case LocalState.deleteMessageBackendHelperNoThread data.currentUserId messageId channel of
                                                Ok channel2 ->
                                                    ( { model
                                                        | discordDmChannels =
                                                            SeqDict.insert data.channelId channel2 model.discordDmChannels
                                                      }
                                                    , Command.batch
                                                        [ Lamdera.sendToFrontend
                                                            clientId
                                                            (LocalChangeResponse changeId localMsg)
                                                        , Broadcast.toDiscordDmChannelExcludingOne
                                                            clientId
                                                            data.channelId
                                                            (Server_DeleteMessage guildOrDmId threadRoute |> ServerChange)
                                                            model
                                                        , case OneToOne.first messageId oldChannel.linkedMessageIds of
                                                            Just discordMessageId ->
                                                                Discord.deleteMessagePayload
                                                                    (Discord.userToken userData.auth)
                                                                    { channelId =
                                                                        Discord.idToUInt64 data.channelId
                                                                            |> Discord.idFromUInt64
                                                                    , messageId = discordMessageId
                                                                    }
                                                                    |> DiscordSync.http
                                                                    |> Task.attempt
                                                                        (DeletedDiscordDmMessage
                                                                            time
                                                                            data.channelId
                                                                            messageId
                                                                            discordMessageId
                                                                        )

                                                            Nothing ->
                                                                Command.none
                                                        ]
                                                    )

                                                Err _ ->
                                                    ( model
                                                    , BackendExtra.invalidChangeResponse changeId clientId
                                                    )

                                        ViewThreadWithMessage _ _ ->
                                            ( model, Command.none )
                                )

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
                                model
                    in
                    case viewing of
                        ViewDm otherUserId _ ->
                            asDmUser
                                model
                                sessionId
                                { otherUserId = otherUserId }
                                (\session user _ dmChannel ->
                                    ( { model
                                        | users =
                                            NonemptyDict.insert
                                                session.userId
                                                (User.setLastDmViewed (DmChannelLastViewed otherUserId NoThread) user)
                                                model.users
                                        , sessions =
                                            SeqDict.insert sessionId (updateSession session) model.sessions
                                      }
                                    , Command.batch
                                        [ ViewDm otherUserId (loadMessagesHelper dmChannel)
                                            |> Local_CurrentlyViewing
                                            |> LocalChangeResponse changeId
                                            |> Lamdera.sendToFrontend clientId
                                        , broadcastCmd session
                                        ]
                                    )
                                )

                        ViewDmThread otherUserId threadId _ ->
                            asDmUser
                                model
                                sessionId
                                { otherUserId = otherUserId }
                                (\session user _ dmChannel ->
                                    ( { model
                                        | users =
                                            NonemptyDict.insert
                                                session.userId
                                                (User.setLastDmViewed (DmChannelLastViewed otherUserId (ViewThread threadId)) user)
                                                model.users
                                        , sessions =
                                            SeqDict.insert sessionId (updateSession session) model.sessions
                                      }
                                    , Command.batch
                                        [ ViewDmThread
                                            otherUserId
                                            threadId
                                            (SeqDict.get threadId dmChannel.threads
                                                |> Maybe.withDefault Thread.backendInit
                                                |> loadMessagesHelper
                                            )
                                            |> Local_CurrentlyViewing
                                            |> LocalChangeResponse changeId
                                            |> Lamdera.sendToFrontend clientId
                                        , broadcastCmd session
                                        ]
                                    )
                                )

                        ViewDiscordDm currentUserId dmChannelId _ ->
                            asDiscordDmUser_AllowUserThatNeedsAuthAgain
                                model
                                sessionId
                                { currentUserId = currentUserId, channelId = dmChannelId }
                                (\session _ user dmChannel ->
                                    ( { model
                                        | users =
                                            NonemptyDict.insert
                                                session.userId
                                                (User.setLastDmViewed (DiscordDmChannelLastViewed dmChannelId) user)
                                                model.users
                                        , sessions =
                                            SeqDict.insert sessionId (updateSession session) model.sessions
                                      }
                                    , Command.batch
                                        [ ViewDiscordDm currentUserId dmChannelId (loadMessagesHelper dmChannel)
                                            |> Local_CurrentlyViewing
                                            |> LocalChangeResponse changeId
                                            |> Lamdera.sendToFrontend clientId
                                        , broadcastCmd session
                                        ]
                                    )
                                )

                        ViewChannel guildId channelId _ ->
                            asGuildMember
                                model
                                sessionId
                                guildId
                                (\session user guild ->
                                    case SeqDict.get channelId guild.channels of
                                        Just channel ->
                                            ( { model
                                                | users =
                                                    NonemptyDict.insert
                                                        session.userId
                                                        (User.setLastChannelViewed guildId channelId NoThread user)
                                                        model.users
                                                , sessions =
                                                    SeqDict.insert sessionId (updateSession session) model.sessions
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
                                            ( model
                                            , BackendExtra.invalidChangeResponse changeId clientId
                                            )
                                )

                        ViewChannelThread guildId channelId threadId _ ->
                            asGuildMember
                                model
                                sessionId
                                guildId
                                (\session user guild ->
                                    case SeqDict.get channelId guild.channels of
                                        Just channel ->
                                            ( { model
                                                | users =
                                                    NonemptyDict.insert
                                                        session.userId
                                                        (User.setLastChannelViewed
                                                            guildId
                                                            channelId
                                                            (ViewThread threadId)
                                                            user
                                                        )
                                                        model.users
                                                , sessions =
                                                    SeqDict.insert sessionId (updateSession session) model.sessions
                                              }
                                            , Command.batch
                                                [ ViewChannelThread
                                                    guildId
                                                    channelId
                                                    threadId
                                                    (SeqDict.get threadId channel.threads
                                                        |> Maybe.withDefault Thread.backendInit
                                                        |> loadMessagesHelper
                                                    )
                                                    |> Local_CurrentlyViewing
                                                    |> LocalChangeResponse changeId
                                                    |> Lamdera.sendToFrontend clientId
                                                , broadcastCmd session
                                                ]
                                            )

                                        Nothing ->
                                            ( model
                                            , Command.batch
                                                [ BackendExtra.invalidChangeResponse changeId clientId
                                                , broadcastCmd session
                                                ]
                                            )
                                )

                        StopViewingChannel ->
                            asUser
                                model
                                sessionId
                                (\session _ ->
                                    ( { model
                                        | sessions = SeqDict.insert sessionId (updateSession session) model.sessions
                                      }
                                    , LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                                    )
                                )

                        ViewDiscordChannel guildId channelId currentDiscordUserId _ ->
                            asDiscordGuildMember_AllowUserThatNeedsAuthAgain
                                model
                                sessionId
                                guildId
                                currentDiscordUserId
                                (\session _ user guild ->
                                    case SeqDict.get channelId guild.channels of
                                        Just channel ->
                                            ( { model
                                                | users =
                                                    NonemptyDict.insert
                                                        session.userId
                                                        (User.setLastDiscordChannelViewed guildId channelId NoThread user)
                                                        model.users
                                                , sessions =
                                                    SeqDict.insert sessionId (updateSession session) model.sessions
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
                                            ( model
                                            , BackendExtra.invalidChangeResponse changeId clientId
                                            )
                                )

                        ViewDiscordChannelThread guildId channelId currentDiscordUserId threadId _ ->
                            asDiscordGuildMember_AllowUserThatNeedsAuthAgain
                                model
                                sessionId
                                guildId
                                currentDiscordUserId
                                (\session _ user guild ->
                                    case SeqDict.get channelId guild.channels of
                                        Just channel ->
                                            ( { model
                                                | users =
                                                    NonemptyDict.insert
                                                        session.userId
                                                        (User.setLastDiscordChannelViewed
                                                            guildId
                                                            channelId
                                                            (ViewThread threadId)
                                                            user
                                                        )
                                                        model.users
                                                , sessions =
                                                    SeqDict.insert sessionId (updateSession session) model.sessions
                                              }
                                            , Command.batch
                                                [ ViewDiscordChannelThread
                                                    guildId
                                                    channelId
                                                    currentDiscordUserId
                                                    threadId
                                                    (SeqDict.get threadId channel.threads
                                                        |> Maybe.withDefault Thread.discordBackendInit
                                                        |> loadMessagesHelper
                                                    )
                                                    |> Local_CurrentlyViewing
                                                    |> LocalChangeResponse changeId
                                                    |> Lamdera.sendToFrontend clientId
                                                , broadcastCmd session
                                                ]
                                            )

                                        Nothing ->
                                            ( model
                                            , Command.batch
                                                [ BackendExtra.invalidChangeResponse changeId clientId
                                                , broadcastCmd session
                                                ]
                                            )
                                )

                Local_SetName name ->
                    asUser
                        model
                        sessionId
                        (\{ userId } user ->
                            ( { model
                                | users = NonemptyDict.insert userId { user | name = name } model.users
                              }
                            , Command.batch
                                [ Lamdera.sendToFrontend clientId (LocalChangeResponse changeId localMsg)
                                , Broadcast.toEveryoneWhoCanSeeUser
                                    clientId
                                    userId
                                    (ServerChange (Server_SetName userId name))
                                    model
                                ]
                            )
                        )

                Local_LoadChannelMessages guildOrDmId oldestVisibleMessage _ ->
                    case guildOrDmId of
                        GuildOrDmId_Guild guildId channelId ->
                            asGuildMember
                                model
                                sessionId
                                guildId
                                (\_ _ guild ->
                                    ( model
                                    , case SeqDict.get channelId guild.channels of
                                        Just channel ->
                                            handleMessagesRequest oldestVisibleMessage channel
                                                |> Local_LoadChannelMessages guildOrDmId oldestVisibleMessage
                                                |> LocalChangeResponse changeId
                                                |> Lamdera.sendToFrontend clientId

                                        Nothing ->
                                            BackendExtra.invalidChangeResponse changeId clientId
                                    )
                                )

                        GuildOrDmId_Dm otherUserId ->
                            asDmUser
                                model
                                sessionId
                                { otherUserId = otherUserId }
                                (\_ _ _ dmChannel ->
                                    ( model
                                    , handleMessagesRequest oldestVisibleMessage dmChannel
                                        |> Local_LoadChannelMessages guildOrDmId oldestVisibleMessage
                                        |> LocalChangeResponse changeId
                                        |> Lamdera.sendToFrontend clientId
                                    )
                                )

                Local_LoadThreadMessages guildOrDmId threadId oldestVisibleMessage _ ->
                    case guildOrDmId of
                        GuildOrDmId_Guild guildId channelId ->
                            asGuildMember
                                model
                                sessionId
                                guildId
                                (\_ _ guild ->
                                    ( model
                                    , case SeqDict.get channelId guild.channels of
                                        Just channel ->
                                            SeqDict.get threadId channel.threads
                                                |> Maybe.withDefault Thread.backendInit
                                                |> handleMessagesRequest oldestVisibleMessage
                                                |> Local_LoadThreadMessages guildOrDmId threadId oldestVisibleMessage
                                                |> LocalChangeResponse changeId
                                                |> Lamdera.sendToFrontend clientId

                                        Nothing ->
                                            BackendExtra.invalidChangeResponse changeId clientId
                                    )
                                )

                        GuildOrDmId_Dm otherUserId ->
                            asDmUser
                                model
                                sessionId
                                { otherUserId = otherUserId }
                                (\_ _ _ dmChannel ->
                                    ( model
                                    , SeqDict.get threadId dmChannel.threads
                                        |> Maybe.withDefault Thread.backendInit
                                        |> handleMessagesRequest oldestVisibleMessage
                                        |> Local_LoadThreadMessages guildOrDmId threadId oldestVisibleMessage
                                        |> LocalChangeResponse changeId
                                        |> Lamdera.sendToFrontend clientId
                                    )
                                )

                Local_Discord_LoadChannelMessages guildOrDmId oldestVisibleMessage _ ->
                    case guildOrDmId of
                        DiscordGuildOrDmId_Guild currentUserId guildId channelId ->
                            asDiscordGuildMember_AllowUserThatNeedsAuthAgain
                                model
                                sessionId
                                guildId
                                currentUserId
                                (\_ _ _ guild ->
                                    ( model
                                    , case SeqDict.get channelId guild.channels of
                                        Just channel ->
                                            handleMessagesRequest oldestVisibleMessage channel
                                                |> Local_Discord_LoadChannelMessages guildOrDmId oldestVisibleMessage
                                                |> LocalChangeResponse changeId
                                                |> Lamdera.sendToFrontend clientId

                                        Nothing ->
                                            BackendExtra.invalidChangeResponse changeId clientId
                                    )
                                )

                        DiscordGuildOrDmId_Dm data ->
                            asDiscordDmUser_AllowUserThatNeedsAuthAgain
                                model
                                sessionId
                                data
                                (\_ _ _ channel ->
                                    ( model
                                    , handleMessagesRequest oldestVisibleMessage channel
                                        |> Local_Discord_LoadChannelMessages guildOrDmId oldestVisibleMessage
                                        |> LocalChangeResponse changeId
                                        |> Lamdera.sendToFrontend clientId
                                    )
                                )

                Local_Discord_LoadThreadMessages guildOrDmId threadId oldestVisibleMessage _ ->
                    case guildOrDmId of
                        DiscordGuildOrDmId_Guild currentDiscordUserId guildId channelId ->
                            asDiscordGuildMember
                                model
                                sessionId
                                guildId
                                currentDiscordUserId
                                (\_ _ _ guild ->
                                    ( model
                                    , case SeqDict.get channelId guild.channels of
                                        Just channel ->
                                            SeqDict.get threadId channel.threads
                                                |> Maybe.withDefault Thread.discordBackendInit
                                                |> handleMessagesRequest oldestVisibleMessage
                                                |> Local_Discord_LoadThreadMessages guildOrDmId threadId oldestVisibleMessage
                                                |> LocalChangeResponse changeId
                                                |> Lamdera.sendToFrontend clientId

                                        Nothing ->
                                            BackendExtra.invalidChangeResponse changeId clientId
                                    )
                                )

                        DiscordGuildOrDmId_Dm _ ->
                            ( model, BackendExtra.invalidChangeResponse changeId clientId )

                Local_SetGuildNotificationLevel guildId notificationLevel ->
                    asGuildMember
                        model
                        sessionId
                        guildId
                        (\{ userId } user _ ->
                            ( { model
                                | users =
                                    NonemptyDict.insert
                                        userId
                                        (User.setGuildNotificationLevel guildId notificationLevel user)
                                        model.users
                              }
                            , Command.batch
                                [ LocalChangeResponse changeId localMsg
                                    |> Lamdera.sendToFrontend clientId
                                , Broadcast.toUser
                                    (Just clientId)
                                    Nothing
                                    userId
                                    (Server_SetGuildNotificationLevel guildId notificationLevel |> ServerChange)
                                    model
                                ]
                            )
                        )

                Local_SetDiscordGuildNotificationLevel userId guildId notificationLevel ->
                    asDiscordGuildMember
                        model
                        sessionId
                        guildId
                        userId
                        (\session _ user _ ->
                            ( { model
                                | users =
                                    NonemptyDict.insert
                                        session.userId
                                        (User.setDiscordGuildNotificationLevel guildId notificationLevel user)
                                        model.users
                              }
                            , Command.batch
                                [ LocalChangeResponse changeId localMsg
                                    |> Lamdera.sendToFrontend clientId
                                , Broadcast.toUser
                                    (Just clientId)
                                    Nothing
                                    session.userId
                                    (Server_SetDiscordGuildNotificationLevel guildId notificationLevel |> ServerChange)
                                    model
                                ]
                            )
                        )

                Local_SetNotificationMode notificationMode ->
                    asUser
                        model
                        sessionId
                        (\session _ ->
                            ( { model
                                | sessions =
                                    SeqDict.insert
                                        sessionId
                                        { session | notificationMode = notificationMode }
                                        model.sessions
                              }
                            , LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                            )
                        )

                Local_RegisterPushSubscription pushSubscription ->
                    asUser
                        model
                        sessionId
                        (\session _ ->
                            ( { model
                                | sessions =
                                    SeqDict.insert
                                        sessionId
                                        { session | pushSubscription = Subscribed pushSubscription }
                                        model.sessions
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
                                    model
                                ]
                            )
                        )

                Local_TextEditor localChange ->
                    asUser
                        model
                        sessionId
                        (\session _ ->
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

                Local_UnlinkDiscordUser discordUserId ->
                    asUser
                        model
                        sessionId
                        (\session _ ->
                            let
                                helper :
                                    Id UserId
                                    -> DiscordBasicUserData
                                    -> Maybe Websocket.Connection
                                    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
                                helper linkedTo basicData maybeConnection =
                                    if linkedTo == session.userId then
                                        ( { model
                                            | discordUsers =
                                                SeqDict.insert discordUserId (BasicData basicData) model.discordUsers
                                          }
                                        , Command.batch
                                            [ Lamdera.sendToFrontend clientId (LocalChangeResponse changeId localMsg)
                                            , Broadcast.toUser
                                                (Just clientId)
                                                Nothing
                                                session.userId
                                                (Server_UnlinkDiscordUser discordUserId |> ServerChange)
                                                model
                                            , case maybeConnection of
                                                Just connection ->
                                                    Task.perform
                                                        (\() -> WebsocketClosedByBackendForUser discordUserId False)
                                                        (DiscordSync.websocketClose "Local_UnlinkDiscordUser" connection)

                                                Nothing ->
                                                    Command.none
                                            ]
                                        )

                                    else
                                        ( model, BackendExtra.invalidChangeResponse changeId clientId )
                            in
                            case SeqDict.get discordUserId model.discordUsers of
                                Just (FullData discordUser) ->
                                    helper
                                        discordUser.linkedTo
                                        { user = Discord.userToPartialUser discordUser.user
                                        , icon = discordUser.icon
                                        }
                                        discordUser.connection.websocketHandle

                                Just (NeedsAuthAgain discordUser) ->
                                    helper
                                        discordUser.linkedTo
                                        { user = Discord.userToPartialUser discordUser.user
                                        , icon = discordUser.icon
                                        }
                                        Nothing

                                Just (BasicData _) ->
                                    ( model, BackendExtra.invalidChangeResponse changeId clientId )

                                Nothing ->
                                    ( model, BackendExtra.invalidChangeResponse changeId clientId )
                        )

                Local_StartReloadingDiscordUser _ discordUserId ->
                    asDiscordUser
                        model
                        sessionId
                        discordUserId
                        (\session discordUser _ ->
                            let
                                isAlreadyLoading : Bool
                                isAlreadyLoading =
                                    case SeqDict.get discordUserId model.discordUsers of
                                        Just (FullData discordUser2) ->
                                            case discordUser2.isLoadingData of
                                                DiscordUserLoadedSuccessfully ->
                                                    False

                                                DiscordUserLoadingData _ ->
                                                    True

                                                DiscordUserLoadingFailed _ ->
                                                    False

                                        _ ->
                                            False
                            in
                            if isAlreadyLoading then
                                ( model, BackendExtra.invalidChangeResponse changeId clientId )

                            else
                                let
                                    backendUser : DiscordFullUserData
                                    backendUser =
                                        { discordUser | isLoadingData = DiscordUserLoadingData time }
                                in
                                ( { model | discordUsers = SeqDict.insert discordUserId (FullData backendUser) model.discordUsers }
                                , Command.batch
                                    [ LocalChangeResponse changeId (Local_StartReloadingDiscordUser time discordUserId)
                                        |> Lamdera.sendToFrontend clientId
                                    , Broadcast.toUser
                                        (Just clientId)
                                        Nothing
                                        session.userId
                                        (Server_StartReloadingDiscordUser time discordUserId |> ServerChange)
                                        model
                                    , Discord.getCurrentUserPayload (Discord.userToken discordUser.auth)
                                        |> DiscordSync.http
                                        |> Task.attempt (ReloadDiscordUserStep1 time clientId session.userId discordUserId)
                                    ]
                                )
                        )

                Local_LinkDiscordAcknowledgementIsChecked isChecked ->
                    asUser
                        model
                        sessionId
                        (\session user ->
                            ( { model
                                | users =
                                    NonemptyDict.insert
                                        session.userId
                                        { user | linkDiscordAcknowledgementIsChecked = isChecked }
                                        model.users
                              }
                            , Lamdera.sendToFrontend clientId (LocalChangeResponse changeId localMsg)
                            )
                        )

                Local_SetDomainWhitelist enable domain ->
                    asUser
                        model
                        sessionId
                        (\session user ->
                            ( { model
                                | users =
                                    NonemptyDict.insert
                                        session.userId
                                        (User.setDomainWhitelist enable domain user)
                                        model.users
                              }
                            , Lamdera.sendToFrontend clientId (LocalChangeResponse changeId localMsg)
                            )
                        )

                Local_SetEmojiCategory category ->
                    asUser
                        model
                        sessionId
                        (\session user ->
                            ( { model
                                | users =
                                    NonemptyDict.insert
                                        session.userId
                                        (User.setEmojiCategory category user)
                                        model.users
                              }
                            , Lamdera.sendToFrontend clientId (LocalChangeResponse changeId localMsg)
                            )
                        )

                Local_SetEmojiSkinTone maybeSkinTone ->
                    asUser
                        model
                        sessionId
                        (\session user ->
                            ( { model
                                | users =
                                    NonemptyDict.insert
                                        session.userId
                                        (User.setEmojiSkinTone maybeSkinTone user)
                                        model.users
                              }
                            , Lamdera.sendToFrontend clientId (LocalChangeResponse changeId localMsg)
                            )
                        )

        TwoFactorToBackend toBackend2 ->
            asUser
                model
                sessionId
                (twoFactorAuthenticationUpdateFromFrontend clientId time toBackend2 model)

        AiChatToBackend aiChatToBackend ->
            ( model
            , Command.map
                AiChatToFrontend
                AiChatBackendMsg
                (AiChat.updateFromFrontend clientId aiChatToBackend model.openRouterKey)
            )

        JoinGuildByInviteRequest guildId inviteLinkId ->
            asUser
                model
                sessionId
                (joinGuildByInvite inviteLinkId time sessionId clientId guildId model)

        ReloadDataRequest requestMessagesFor ->
            ( model
            , case Broadcast.getUserFromSessionId sessionId model of
                Just ( userId, user ) ->
                    BackendExtra.getLoginData sessionId userId user requestMessagesFor model
                        |> Ok
                        |> ReloadDataResponse
                        |> Lamdera.sendToFrontend clientId

                Nothing ->
                    Lamdera.sendToFrontend clientId (ReloadDataResponse (Err ()))
            )

        LinkSlackOAuthCode oAuthCode sessionId2 ->
            case Broadcast.getSessionFromSessionIdHash sessionId2 model of
                Just ( _, session ) ->
                    ( model
                    , case model.slackClientSecret of
                        Just clientSecret ->
                            Slack.exchangeCodeForToken clientSecret Env.slackClientId oAuthCode
                                |> Task.attempt (GotSlackOAuth time session.userId)

                        Nothing ->
                            Command.none
                    )

                Nothing ->
                    ( model, Command.none )

        LinkDiscordRequest data ->
            asUser
                model
                sessionId
                (\session _ ->
                    ( model
                    , Discord.getCurrentUserPayload (Discord.userToken data)
                        |> DiscordSync.http
                        |> Task.attempt (LinkDiscordUserStep1 time clientId session.userId data)
                    )
                )

        ProfilePictureEditorToBackend (ImageEditor.ChangeUserAvatarRequest fileHash) ->
            asUser
                model
                sessionId
                (\session user ->
                    let
                        user2 : BackendUser
                        user2 =
                            User.setIcon fileHash user
                    in
                    ( { model | users = NonemptyDict.insert session.userId user2 model.users }
                    , Command.batch
                        [ Broadcast.toEveryoneWhoCanSeeUserIncludingUser
                            session.userId
                            (Server_SetUserIcon session.userId fileHash |> ServerChange)
                            model
                        , Lamdera.sendToFrontend
                            clientId
                            (ProfilePictureEditorToFrontend ImageEditor.ChangeUserAvatarResponse)
                        ]
                    )
                )

        AdminDataRequest logPage ->
            asAdmin
                model
                sessionId
                (\_ user ->
                    ( model
                    , BackendExtra.adminData model (Maybe.withDefault user.lastLogPageViewed logPage)
                        |> Server_LoadAdminData
                        |> ServerChange
                        |> ChangeBroadcast
                        |> Lamdera.sendToFrontend clientId
                    )
                )


threadRouteToDiscordMessageId :
    Discord.Id Discord.ChannelId
    -> DiscordBackendChannel
    -> ThreadRouteWithMessage
    -> Maybe ( Discord.Id Discord.ChannelId, Discord.Id Discord.MessageId )
threadRouteToDiscordMessageId channelId channel threadRoute =
    case threadRoute of
        NoThreadWithMessage messageId ->
            case OneToOne.first messageId channel.linkedMessageIds of
                Just discordMessageId ->
                    Just ( channelId, discordMessageId )

                Nothing ->
                    Nothing

        ViewThreadWithMessage threadId messageId ->
            case ( SeqDict.get threadId channel.threads, OneToOne.first threadId channel.linkedMessageIds ) of
                ( Just thread, Just discordThreadId ) ->
                    case OneToOne.first messageId thread.linkedMessageIds of
                        Just discordMessageId ->
                            Just ( Discord.idToUInt64 discordThreadId |> Discord.idFromUInt64, discordMessageId )

                        Nothing ->
                            Nothing

                _ ->
                    Nothing


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
                    (ChangeAttachments attachedFiles2)
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
                    , BackendExtra.invalidChangeResponse changeId clientId
                    )

        Nothing ->
            ( model2
            , BackendExtra.invalidChangeResponse changeId clientId
            )


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
            case ( SeqDict.get inviteLinkId guild.invites, LocalState.addMemberBackend time session.userId guild ) of
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
                            ( NonemptyDict.get (MembersAndOwner.owner guild2.membersAndOwner) model2.users
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
                                        (MembersAndOwner.members guild2.membersAndOwner)
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
                        ( model2, cmd ) =
                            BackendExtra.addLog time (Log.ChangedUsers userId) model
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
                        , cmd
                        ]
                    )

                Err _ ->
                    ( model, BackendExtra.invalidChangeResponse changeId clientId )

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

        Pages.Admin.LogPageChanged pageId _ ->
            let
                pageIndex =
                    Id.toInt pageId
            in
            ( { model
                | users = NonemptyDict.insert userId { user | lastLogPageViewed = pageId } model.users
              }
            , Pages.Admin.LogPageChanged
                pageId
                (FilledInByBackend
                    (Array.slice (pageIndex * Pagination.pageSize) ((pageIndex + 1) * Pagination.pageSize) model.logs)
                )
                |> Local_Admin
                |> LocalChangeResponse changeId
                |> Lamdera.sendToFrontend clientId
            )

        Pages.Admin.HideLog logIndex ->
            ( { model | logs = Array.Extra.update (Id.toInt logIndex) (\log -> { log | isHidden = True }) model.logs }
            , LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
            )

        Pages.Admin.UnhideLog logIndex ->
            ( { model | logs = Array.Extra.update (Id.toInt logIndex) (\log -> { log | isHidden = False }) model.logs }
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

        Pages.Admin.SetSignupsEnabled isEnabled ->
            let
                model2 =
                    { model | signupsEnabled = isEnabled }
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

        Pages.Admin.DeleteDiscordDmChannel channelId ->
            let
                model2 : BackendModel
                model2 =
                    { model | discordDmChannels = SeqDict.remove channelId model.discordDmChannels }
            in
            ( model2
            , Command.batch
                [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                , Broadcast.toOtherAdmins clientId model2 (LocalChange userId localMsg)
                ]
            )

        Pages.Admin.DeleteDiscordGuild guildId ->
            let
                model2 : BackendModel
                model2 =
                    { model | discordGuilds = SeqDict.remove guildId model.discordGuilds }
            in
            ( model2
            , Command.batch
                [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                , Broadcast.toOtherAdmins clientId model2 (LocalChange userId localMsg)
                ]
            )

        Pages.Admin.DeleteGuild guildId ->
            let
                model2 : BackendModel
                model2 =
                    { model | guilds = SeqDict.remove guildId model.guilds }
            in
            ( model2
            , Command.batch
                [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                , Broadcast.toOtherAdmins clientId model2 (LocalChange userId localMsg)
                ]
            )

        Pages.Admin.StartReloadingDiscordGuildChannel _ userIdToLoadWith guildId channelId ->
            case
                ( SeqDict.get userIdToLoadWith model.discordUsers
                , LocalState.isDiscordGuildChannelReloading channelId model.loadingDiscordChannels
                , LocalState.userIsLoadingDiscordChannel userIdToLoadWith model.loadingDiscordChannels
                )
            of
                ( Just (FullData discordUser), Nothing, False ) ->
                    let
                        auth =
                            Discord.userToken discordUser.auth
                    in
                    ( { model
                        | loadingDiscordChannels =
                            SeqDict.insert
                                userIdToLoadWith
                                (LoadingDiscordGuildChannel time guildId channelId LoadingDiscordChannelMessages)
                                model.loadingDiscordChannels
                      }
                    , Command.batch
                        [ Pages.Admin.StartReloadingDiscordGuildChannel time userIdToLoadWith guildId channelId
                            |> Local_Admin
                            |> LocalChangeResponse changeId
                            |> Lamdera.sendToFrontend clientId
                        , Broadcast.toOtherAdmins clientId model (LocalChange userId localMsg)
                        , DiscordSync.getManyMessages auth { channelId = channelId, limit = DiscordSync.reloadChannelMaxMessages }
                            |> Task.attempt (GotDiscordGuildChannelMessages time userIdToLoadWith guildId channelId)

                        --(DiscordSync.getChannelThreads auth guildId channelId model)
                        --|> Task.andThen
                        --    (\( messages, threads ) ->
                        --        Task.map
                        --            (\attachments ->
                        --                { messages = messages, attachments = attachments, threads = threads }
                        --            )
                        --            (DiscordSync.uploadAttachmentsForMessages model messages)
                        --    )
                        --|> Task.attempt (ReloadedDiscordChannel time userIdToLoadWith guildId channelId)
                        ]
                    )

                _ ->
                    ( model, BackendExtra.invalidChangeResponse changeId clientId )

        Pages.Admin.StartReloadingDiscordDmChannel _ userIdToLoadWith channelId ->
            case
                ( SeqDict.get userIdToLoadWith model.discordUsers
                , LocalState.isDiscordDmChannelReloading channelId model.loadingDiscordChannels
                , LocalState.userIsLoadingDiscordChannel userIdToLoadWith model.loadingDiscordChannels
                )
            of
                ( Just (FullData discordUser), Nothing, False ) ->
                    ( { model
                        | loadingDiscordChannels =
                            SeqDict.insert
                                userIdToLoadWith
                                (LoadingDiscordDmChannel time channelId LoadingDiscordChannelMessages)
                                model.loadingDiscordChannels
                      }
                    , Command.batch
                        [ Pages.Admin.StartReloadingDiscordDmChannel time userIdToLoadWith channelId
                            |> Local_Admin
                            |> LocalChangeResponse changeId
                            |> Lamdera.sendToFrontend clientId
                        , Broadcast.toOtherAdmins clientId model (LocalChange userId localMsg)
                        , DiscordSync.getManyMessages
                            (Discord.userToken discordUser.auth)
                            { channelId = Discord.idToUInt64 channelId |> Discord.idFromUInt64
                            , limit = DiscordSync.reloadChannelMaxMessages
                            }
                            |> Task.attempt (GotDiscordDmChannelMessages time userIdToLoadWith channelId)

                        --, DiscordSync.getManyMessages
                        --    (Discord.userToken discordUser.auth)
                        --    { channelId = Discord.toUInt64 channelId |> Discord.fromUInt64, limit = reloadChannelMaxMessages }
                        --    |> Task.andThen
                        --        (\messages ->
                        --            DiscordSync.uploadAttachmentsForMessages model messages
                        --                |> Task.map
                        --                    (\attachments ->
                        --                        { messages = messages
                        --                        , attachments = attachments
                        --                        }
                        --                    )
                        --        )
                        --    |> Task.attempt (ReloadedDiscordDmChannel time userIdToLoadWith channelId)
                        ]
                    )

                _ ->
                    ( model, BackendExtra.invalidChangeResponse changeId clientId )

        Pages.Admin.ExpandGuild guildId ->
            ( { model
                | users =
                    NonemptyDict.insert
                        userId
                        { user | expandedGuilds = SeqSet.insert guildId user.expandedGuilds }
                        model.users
              }
            , LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
            )

        Pages.Admin.CollapseGuild guildId ->
            ( { model
                | users =
                    NonemptyDict.insert
                        userId
                        { user | expandedGuilds = SeqSet.remove guildId user.expandedGuilds }
                        model.users
              }
            , LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
            )

        Pages.Admin.ExpandDiscordGuild guildId ->
            ( { model
                | users =
                    NonemptyDict.insert
                        userId
                        { user | expandedDiscordGuilds = SeqSet.insert guildId user.expandedDiscordGuilds }
                        model.users
              }
            , LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
            )

        Pages.Admin.CollapseDiscordGuild guildId ->
            ( { model
                | users =
                    NonemptyDict.insert
                        userId
                        { user | expandedDiscordGuilds = SeqSet.remove guildId user.expandedDiscordGuilds }
                        model.users
              }
            , LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
            )

        Pages.Admin.DisconnectClient sessionIdHash disconnectClientId ->
            case Broadcast.getSessionFromSessionIdHash sessionIdHash model of
                Just ( sessionId, _ ) ->
                    let
                        ( model2, cmds ) =
                            disconnectClient sessionId disconnectClientId model
                    in
                    ( model2
                    , Command.batch [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId, cmds ]
                    )

                Nothing ->
                    ( model, BackendExtra.invalidChangeResponse changeId clientId )


updateFromFrontendAdmin :
    ClientId
    -> Pages.Admin.ToBackend
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
updateFromFrontendAdmin clientId toBackend model =
    case toBackend of
        Pages.Admin.ExportBackendRequest isPartial ->
            let
                baseModel : BackendModel
                baseModel =
                    { model
                        | guilds = SeqDict.empty
                        , dmChannels = SeqDict.empty
                        , discordGuilds = SeqDict.empty
                        , discordDmChannels = SeqDict.empty
                        , exportState = Nothing
                        , scheduledExportState = Nothing
                    }

                partialList : List a -> List a
                partialList list =
                    case isPartial of
                        ExportSubset ->
                            List.take 2 list

                        ExportAll ->
                            list
            in
            ( { model
                | exportState =
                    { progress =
                        { baseModel = Bytes.Encode.encode (WireHelper.encodeBackendModel baseModel)
                        , remainingGuilds = SeqDict.toList model.guilds |> partialList
                        , encodedGuilds = []
                        , remainingDmChannels = SeqDict.toList model.dmChannels |> partialList
                        , encodedDmChannels = []
                        , remainingDiscordGuilds = SeqDict.toList model.discordGuilds |> partialList
                        , encodedDiscordGuilds = []
                        , remainingDiscordDmChannels = SeqDict.toList model.discordDmChannels |> partialList
                        , encodedDiscordDmChannels = []
                        }
                    , exportSubset = isPartial
                    , clientId = clientId
                    }
                        |> Just
              }
            , Pages.Admin.ExportBackendProgress isPartial Pages.Admin.ExportStarting
                |> AdminToFrontend
                |> Lamdera.sendToFrontend clientId
            )

        Pages.Admin.ImportBackendRequest bytes ->
            case Bytes.Decode.decode WireHelper.decodeStreamedBackendModel bytes of
                Just model2 ->
                    ( model2
                    , Lamdera.sendToFrontend clientId (Pages.Admin.ImportBackendResponse (Ok ()) |> AdminToFrontend)
                    )

                Nothing ->
                    ( model
                    , Lamdera.sendToFrontend clientId (Pages.Admin.ImportBackendResponse (Err ()) |> AdminToFrontend)
                    )


handleExportBackendStep : ExportStateProgress -> ( Pages.Admin.ExportProgress, Maybe ExportStateProgress )
handleExportBackendStep exportState =
    case exportState.remainingGuilds of
        entry :: rest ->
            let
                encodedCount : Int
                encodedCount =
                    List.length exportState.encodedGuilds
            in
            ( Pages.Admin.ExportingGuilds
                { encoded = encodedCount + 1
                , total = encodedCount + List.length exportState.remainingGuilds
                }
            , { exportState
                | remainingGuilds = rest
                , encodedGuilds = Bytes.Encode.encode (WireHelper.encodeGuild entry) :: exportState.encodedGuilds
              }
                |> Just
            )

        [] ->
            case exportState.remainingDmChannels of
                entry :: rest ->
                    let
                        encodedCount : Int
                        encodedCount =
                            List.length exportState.encodedDmChannels
                    in
                    ( Pages.Admin.ExportingDmChannels
                        { encoded = encodedCount + 1
                        , total = encodedCount + List.length exportState.remainingDmChannels
                        }
                    , { exportState
                        | remainingDmChannels = rest
                        , encodedDmChannels = Bytes.Encode.encode (WireHelper.encodeDmChannel entry) :: exportState.encodedDmChannels
                      }
                        |> Just
                    )

                [] ->
                    case exportState.remainingDiscordGuilds of
                        entry :: rest ->
                            let
                                encodedCount : Int
                                encodedCount =
                                    List.length exportState.encodedDiscordGuilds
                            in
                            ( Pages.Admin.ExportingDiscordGuilds
                                { encoded = encodedCount + 1
                                , total = encodedCount + List.length exportState.remainingDiscordGuilds
                                }
                            , { exportState
                                | remainingDiscordGuilds = rest
                                , encodedDiscordGuilds =
                                    Bytes.Encode.encode (WireHelper.encodeDiscordGuild entry)
                                        :: exportState.encodedDiscordGuilds
                              }
                                |> Just
                            )

                        [] ->
                            case exportState.remainingDiscordDmChannels of
                                entry :: rest ->
                                    let
                                        encodedCount : Int
                                        encodedCount =
                                            List.length exportState.encodedDiscordDmChannels
                                    in
                                    ( Pages.Admin.ExportingDiscordDmChannels
                                        { encoded = encodedCount + 1
                                        , total = encodedCount + List.length exportState.remainingDiscordDmChannels
                                        }
                                    , { exportState
                                        | remainingDiscordDmChannels = rest
                                        , encodedDiscordDmChannels =
                                            Bytes.Encode.encode (WireHelper.encodeDiscordDmChannel entry)
                                                :: exportState.encodedDiscordDmChannels
                                      }
                                        |> Just
                                    )

                                [] ->
                                    let
                                        encodeItemList : List Bytes -> Bytes.Encode.Encoder
                                        encodeItemList items =
                                            Bytes.Encode.sequence
                                                (Bytes.Encode.unsignedInt32 Bytes.BE (List.length items)
                                                    :: List.map Bytes.Encode.bytes (List.reverse items)
                                                )

                                        exportedBytes : Bytes
                                        exportedBytes =
                                            Bytes.Encode.encode
                                                (Bytes.Encode.sequence
                                                    [ Bytes.Encode.bytes exportState.baseModel
                                                    , encodeItemList exportState.encodedGuilds
                                                    , encodeItemList exportState.encodedDmChannels
                                                    , encodeItemList exportState.encodedDiscordGuilds
                                                    , encodeItemList exportState.encodedDiscordDmChannels
                                                    ]
                                                )
                                    in
                                    ( Pages.Admin.ExportingFinalStep exportedBytes
                                    , Nothing
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


asDmUser :
    BackendModel
    -> SessionId
    -> { otherUserId : Id UserId }
    -> (UserSession -> BackendUser -> DmChannelId -> DmChannel.DmChannel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg ))
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
asDmUser model sessionId { otherUserId } func =
    case SeqDict.get sessionId model.sessions of
        Just session ->
            let
                dmChannelId =
                    DmChannel.channelIdFromUserIds session.userId otherUserId
            in
            case ( NonemptyDict.get session.userId model.users, SeqDict.get dmChannelId model.dmChannels ) of
                ( Just user, Just dmChannel ) ->
                    func session user dmChannelId dmChannel

                ( Just user, Nothing ) ->
                    if usersHaveSharedGuilds session.userId otherUserId model then
                        func session user dmChannelId DmChannel.backendInit

                    else
                        ( model, Command.none )

                ( Nothing, _ ) ->
                    ( model, Command.none )

        Nothing ->
            ( model, Command.none )


usersHaveSharedGuilds : Id UserId -> Id UserId -> BackendModel -> Bool
usersHaveSharedGuilds userIdA userIdB model =
    SeqDict.foldl
        (\_ guild haveShared ->
            haveShared
                || (MembersAndOwner.isMember userIdA guild.membersAndOwner /= IsNotMember)
                && (MembersAndOwner.isMember userIdB guild.membersAndOwner /= IsNotMember)
        )
        False
        model.guilds


asDiscordUser :
    BackendModel
    -> SessionId
    -> Discord.Id Discord.UserId
    ->
        (UserSession
         -> DiscordFullUserData
         -> BackendUser
         -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
        )
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
asDiscordUser model sessionId discordUserId func =
    case SeqDict.get sessionId model.sessions of
        Just session ->
            case ( NonemptyDict.get session.userId model.users, SeqDict.get discordUserId model.discordUsers ) of
                ( Just user, Just (FullData discordUser) ) ->
                    if discordUser.linkedTo == session.userId then
                        func session discordUser user

                    else
                        ( model, Command.none )

                _ ->
                    ( model, Command.none )

        Nothing ->
            ( model, Command.none )


asDiscordDmUser :
    BackendModel
    -> SessionId
    -> DiscordGuildOrDmId_DmData
    ->
        (UserSession
         -> DiscordFullUserData
         -> BackendUser
         -> DiscordDmChannel
         -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
        )
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
asDiscordDmUser model sessionId { currentUserId, channelId } func =
    case SeqDict.get sessionId model.sessions of
        Just session ->
            case
                ( NonemptyDict.get session.userId model.users
                , SeqDict.get currentUserId model.discordUsers
                , SeqDict.get channelId model.discordDmChannels
                )
            of
                ( Just user, Just (FullData discordUser), Just dmChannel ) ->
                    if discordUser.linkedTo == session.userId && NonemptyDict.member currentUserId dmChannel.members then
                        func session discordUser user dmChannel

                    else
                        ( model, Command.none )

                _ ->
                    ( model, Command.none )

        Nothing ->
            ( model, Command.none )


asDiscordDmUser_AllowUserThatNeedsAuthAgain :
    BackendModel
    -> SessionId
    -> DiscordGuildOrDmId_DmData
    ->
        (UserSession
         -> NeedsAuthAgainData
         -> BackendUser
         -> DiscordDmChannel
         -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
        )
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
asDiscordDmUser_AllowUserThatNeedsAuthAgain model sessionId { currentUserId, channelId } func =
    case SeqDict.get sessionId model.sessions of
        Just session ->
            case
                ( NonemptyDict.get session.userId model.users
                , SeqDict.get currentUserId model.discordUsers
                , SeqDict.get channelId model.discordDmChannels
                )
            of
                ( Just user, Just (FullData discordUser), Just dmChannel ) ->
                    if discordUser.linkedTo == session.userId && NonemptyDict.member currentUserId dmChannel.members then
                        func
                            session
                            { user = discordUser.user
                            , linkedTo = discordUser.linkedTo
                            , icon = discordUser.icon
                            , linkedAt = discordUser.linkedAt
                            }
                            user
                            dmChannel

                    else
                        ( model, Command.none )

                ( Just user, Just (NeedsAuthAgain discordUser), Just dmChannel ) ->
                    if discordUser.linkedTo == session.userId && NonemptyDict.member currentUserId dmChannel.members then
                        func session discordUser user dmChannel

                    else
                        ( model, Command.none )

                _ ->
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
                    case MembersAndOwner.isMember session.userId guild.membersAndOwner of
                        IsNotMember ->
                            ( model, Command.none )

                        IsMember ->
                            func session user guild

                        IsOwner ->
                            func session user guild

                _ ->
                    ( model, Command.none )

        Nothing ->
            ( model, Command.none )


asDiscordGuildMember :
    BackendModel
    -> SessionId
    -> Discord.Id Discord.GuildId
    -> Discord.Id Discord.UserId
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
                    if discordUser.linkedTo == session.userId then
                        case MembersAndOwner.isMember discordUserId guild.membersAndOwner of
                            IsNotMember ->
                                ( model, Command.none )

                            IsMember ->
                                func session discordUser user guild

                            IsOwner ->
                                func session discordUser user guild

                    else
                        ( model, Command.none )

                _ ->
                    ( model, Command.none )

        Nothing ->
            ( model, Command.none )


asDiscordGuildMember_AllowUserThatNeedsAuthAgain :
    BackendModel
    -> SessionId
    -> Discord.Id Discord.GuildId
    -> Discord.Id Discord.UserId
    -> (UserSession -> NeedsAuthAgainData -> BackendUser -> DiscordBackendGuild -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg ))
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
asDiscordGuildMember_AllowUserThatNeedsAuthAgain model sessionId guildId discordUserId func =
    case SeqDict.get sessionId model.sessions of
        Just session ->
            case
                ( NonemptyDict.get session.userId model.users
                , SeqDict.get guildId model.discordGuilds
                , SeqDict.get discordUserId model.discordUsers
                )
            of
                ( Just user, Just guild, Just (FullData discordUser) ) ->
                    if discordUser.linkedTo == session.userId then
                        case MembersAndOwner.isMember discordUserId guild.membersAndOwner of
                            IsNotMember ->
                                ( model, Command.none )

                            IsMember ->
                                func
                                    session
                                    { user = discordUser.user
                                    , linkedTo = discordUser.linkedTo
                                    , icon = discordUser.icon
                                    , linkedAt = discordUser.linkedAt
                                    }
                                    user
                                    guild

                            IsOwner ->
                                func
                                    session
                                    { user = discordUser.user
                                    , linkedTo = discordUser.linkedTo
                                    , icon = discordUser.icon
                                    , linkedAt = discordUser.linkedAt
                                    }
                                    user
                                    guild

                    else
                        ( model, Command.none )

                ( Just user, Just guild, Just (NeedsAuthAgain discordUser) ) ->
                    if discordUser.linkedTo == session.userId then
                        case MembersAndOwner.isMember discordUserId guild.membersAndOwner of
                            IsNotMember ->
                                ( model, Command.none )

                            IsMember ->
                                func session discordUser user guild

                            IsOwner ->
                                func session discordUser user guild

                    else
                        ( model, Command.none )

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
        (\session user guild ->
            case MembersAndOwner.isMember session.userId guild.membersAndOwner of
                IsOwner ->
                    func session.userId user guild

                IsMember ->
                    ( model, Command.none )

                IsNotMember ->
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
