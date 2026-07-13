module Backend exposing
    ( adminUser
    , app
    , app_
    , handleExportBackendStep
    , startExport
    )

import AiChat
import Array exposing (Array)
import Array.Extra
import BackendExtra
import Broadcast
import Bytes exposing (Bytes)
import Bytes.Decode
import Bytes.Encode
import Call exposing (RemoteCallData)
import ChannelDescription
import Cloudflare
import CustomEmoji exposing (CustomEmojiData)
import Date exposing (Date)
import Discord exposing (OptionalData(..))
import DiscordAttachmentId exposing (DiscordAttachmentId)
import DiscordSync
import DiscordUserData exposing (DiscordBasicUserData, DiscordFullUserData, DiscordUserData(..), DiscordUserLoadingData(..))
import DmChannel exposing (DiscordDmChannel, DmChannel)
import DmChannelId exposing (DmChannelId, GuildOrFullDmId(..))
import Drawing
import Duration
import Effect.Command as Command exposing (BackendOnly, Command)
import Effect.Http as Http
import Effect.Lamdera as Lamdera exposing (ClientId, SessionId)
import Effect.Subscription as Subscription exposing (Subscription)
import Effect.Task as Task exposing (Task)
import Effect.Time as Time
import Effect.Websocket as Websocket
import EmailAddress
import Emoji exposing (EmojiOrCustomEmoji(..))
import Env
import FileStatus exposing (FileData, FileId)
import Game
import Go
import GuildName
import Id exposing (AnyGuildOrDmId(..), ChannelId, ChannelMessageId, CustomEmojiId, DiscordGuildOrDmId(..), GamePublicId, GuildId, GuildOrDmId(..), Id, InviteLinkId, StickerId, ThreadRoute(..), ThreadRouteWithMaybeMessage(..), ThreadRouteWithMessage(..), UserId)
import IdArray exposing (IdArray)
import ImageEditor
import Lamdera as LamderaCore
import LinkedAndOtherDiscordUsers
import List.Extra
import List.Nonempty exposing (Nonempty(..))
import Local exposing (ChangeId)
import LocalState exposing (BackendChannel, BackendGuild, CallStatus(..), ChannelStatus(..), ConnectionData, DiscordBackendChannel, DiscordBackendGuild, JoinGuildError(..), LastRequest(..), LoadingDiscordChannel(..), LoadingDiscordChannelStep(..), PrivateVapidKey(..), WebsocketClosedEvent(..))
import Log
import LoginForm
import MembersAndOwner
import Message exposing (ChangeAttachments(..), GameType(..), Message(..))
import MyUi
import NonemptyDict
import NonemptySet
import OneToOne exposing (OneToOne)
import Pages.Admin exposing (ExportSubset(..))
import Pagination
import PersonName
import Ports exposing (RegisterPushSubscription(..))
import Postmark
import Quantity
import RateLimit
import RichText exposing (DiscordCustomEmojiIdAndName, RichText)
import SecretId exposing (SecretId)
import SeqDict exposing (SeqDict)
import SeqDictHelper
import SeqSet exposing (SeqSet)
import Slack
import Sticker exposing (StickerData, StickerUrl(..))
import String.Nonempty exposing (NonemptyString)
import TOTP.Key
import TextEditor
import Thread exposing (DiscordBackendThread)
import Toop exposing (T4(..))
import TwoFactorAuthentication
import Types exposing (BackendModel, BackendMsg(..), DiscordAttachmentData, ExportStateProgress, LocalChange(..), LocalMsg(..), LoginResult(..), LoginTokenData(..), MessageFromGuildOrDm(..), ServerChange(..), ToBackend(..), ToFrontend(..))
import Unsafe
import Untrusted
import User exposing (BackendUser, LastDmViewed(..))
import UserSession exposing (DiscordFrontendUser, PushSubscription(..), SetViewing(..), ToBeFilledInByBackend(..), UserSession)
import VisibleMessages
import WireHelper
import WordSpellingGame exposing (Language(..), WordList(..))


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
    User.init (Time.millisToPosix 0) (Unsafe.personName "AT") (Unsafe.emailAddress "a@a.se") True


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
                        , messages = IdArray.empty
                        , status = ChannelActive
                        , lastTypedAt = SeqDict.empty
                        , threads = SeqDict.empty
                        , dateDividerDrawings = SeqDict.empty
                        , games = SeqDict.empty
                        }
                      )
                    , ( Id.fromInt 1
                      , { createdAt = Time.millisToPosix 0
                        , createdBy = Broadcast.adminUserId
                        , name = Unsafe.channelName "General"
                        , description = ChannelDescription.empty
                        , messages = IdArray.empty
                        , status = ChannelActive
                        , lastTypedAt = SeqDict.empty
                        , threads = SeqDict.empty
                        , dateDividerDrawings = SeqDict.empty
                        , games = SeqDict.empty
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
      , nextGuildId = Id.fromInt 1
      , guilds = SeqDict.fromList [ ( Id.fromInt 0, guild ) ]
      , deletedGuilds = SeqDict.empty
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
      , cloudflareRealtimeApiToken = Nothing
      , cloudflareRealtimeAppId = Nothing
      , cloudflareAccountId = Nothing
      , cloudflareAnalyticsApiToken = Nothing
      , textEditor = TextEditor.initLocalState
      , discordUsers = SeqDict.empty
      , pendingDiscordCreateMessages = SeqDict.empty
      , pendingDiscordCreateDmMessages = SeqDict.empty
      , discordAttachments = SeqDict.empty
      , loadingDiscordChannels = SeqDict.empty
      , signupsEnabled = True
      , discordLinkingEnabled = True
      , exportState = Nothing
      , scheduledExportState = Nothing
      , lastScheduledExportTime = Nothing
      , sendMessageRateLimits = SeqDict.empty
      , toBackendLogs = Array.empty
      , stickers = SeqDict.empty
      , discordStickers = OneToOne.empty
      , customEmojis = SeqDict.empty
      , discordCustomEmojis = OneToOne.empty
      , postmarkApiKey = Postmark.apiKey ""
      , serverSecret = SecretId.fromString Env.secretKey
      , serverSecretRegeneratedAt = Nothing
      , websocketCloseEvents = Array.empty
      , goMatchPublicIds = OneToOne.empty
      , wordSpellingGameEnglish = WordList_NotLoaded
      , wordSpellingGameSwedish = WordList_NotLoaded
      }
    , Command.none
    )


{-| Alert when estimated Cloudflare costs exceed this many US dollars per month.
-}
cloudflareCostThresholdUsd : Float
cloudflareCostThresholdUsd =
    1


{-| Query Cloudflare for this month's Realtime egress so we can alert if it's costing us money.
Disabled (no-op) unless both the account id and analytics token have been configured by an admin.
-}
checkCloudflareCost : Time.Posix -> BackendModel -> Command BackendOnly ToFrontend BackendMsg
checkCloudflareCost time model =
    case ( model.cloudflareAccountId, model.cloudflareAnalyticsApiToken ) of
        ( Just accountId, Just analyticsToken ) ->
            let
                today : Date
                today =
                    Date.fromPosix Time.utc time
            in
            Cloudflare.monthlyEgressBytes
                { accountId = accountId
                , analyticsToken = analyticsToken
                , startDate = Date.floor Date.Month today |> Date.toIsoString
                , endDate = Date.toIsoString today
                }
                |> Task.attempt (GotCloudflareUsage time)

        _ ->
            Command.none


{-| To avoid re-logging (and re-emailing about) the same overage every hour, only alert once per
calendar month. We derive this from the existing log history rather than tracking extra state.
-}
cloudflareCostAlreadyLoggedThisMonth : Time.Posix -> BackendModel -> Bool
cloudflareCostAlreadyLoggedThisMonth time model =
    Array.slice (Array.length model.logs - 1000) (Array.length model.logs) model.logs
        |> Array.Extra.any
            (\entry ->
                case entry.log of
                    Log.CloudflareCostExceeded _ _ ->
                        (Time.toYear Time.utc entry.time == Time.toYear Time.utc time)
                            && (Time.toMonth Time.utc entry.time == Time.toMonth Time.utc time)

                    _ ->
                        False
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
                        case data2.connection.websocketHandle of
                            Just connection ->
                                Websocket.listen
                                    connection
                                    Ok
                                    (\data3 ->
                                        let
                                            _ =
                                                Debug.log "Websocket unexpected close" ()
                                        in
                                        Err ( data3.code, data3.reason )
                                    )
                                    |> Subscription.map (DiscordUserWebsocketMsg discordUserId)
                                    |> Just

                            Nothing ->
                                Nothing

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
                    SeqDictHelper.addToDict
                        sessionId
                        clientId
                        { lastRequest = NoRequestsMade
                        , call = NotInCall
                        , remoteCallData = Call.defaultRemoteCallData
                        , currentlyViewing = Nothing
                        }
                        model.connections
              }
            , Lamdera.sendToFrontend clientId (YouConnected clientId)
            )

        UserDisconnected sessionId clientId ->
            ( model, Task.perform (UserDisconnectedWithTime sessionId clientId) Time.now )

        UserDisconnectedWithTime sessionId clientId time ->
            disconnectClient time sessionId clientId model

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
                            (NonemptyDict.updateIfExists
                                clientId
                                (\data ->
                                    { lastRequest = LastRequest time
                                    , call = data.call
                                    , remoteCallData = data.remoteCallData
                                    , currentlyViewing = data.currentlyViewing
                                    }
                                )
                            )
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

        SentNotificationEmail time email result ->
            BackendExtra.addLog time (Log.NotificationEmail result email) model

        DiscordUserWebsocketMsg discordUserId result ->
            let
                ( model2, cmd ) =
                    DiscordSync.discordUserWebsocketMsg
                        discordUserId
                        (case result of
                            Ok text ->
                                Discord.GotWebsocketData text

                            Err ( _, reason ) ->
                                Discord.WebsocketClosed reason
                        )
                        model
            in
            ( model2
            , Command.batch
                [ cmd
                , case result of
                    Ok _ ->
                        Command.none

                    Err ( code, text ) ->
                        Task.perform (GotTimeForWebsocketListenClose discordUserId code text) Time.now
                ]
            )

        GotTimeForWebsocketListenClose userId code text time ->
            ( recordWebsocketCloseEvent (WebsocketClosed_ListenCloseEvent userId code text time) model, Command.none )

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

        SentNotification sessionId userId time subscribeData result ->
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
                                    (\session -> { session | pushSubscription = SubscriptionError subscribeData error })
                                    model.sessions
                        }
                        (if Env.isProduction && userId /= Broadcast.adminUserId then
                            Broadcast.toSession
                                sessionId
                                (Server_PushNotificationFailed
                                    subscribeData
                                    (Http.BadBody "Something went wrong when sending notifications")
                                )
                                model

                         else
                            Broadcast.toSession
                                sessionId
                                (Server_PushNotificationFailed subscribeData error)
                                model
                        )

        GotVapidKeys result ->
            ( case result of
                Ok keys ->
                    case String.split "," keys of
                        [ publicKey, privateKey ] ->
                            { model
                                | publicVapidKey = String.filter (\char -> char /= '"') publicKey
                                , privateVapidKey = String.filter (\char -> char /= '"') privateKey |> PrivateVapidKey
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

        GotCloudflareSessionCreated sessionId clientId changeId time roomId offerSdp transceiverMids result ->
            let
                cmd : Command BackendOnly ToFrontend BackendMsg
                cmd =
                    Call.Local_Leave time
                        |> Local_VoiceChatChange
                        |> LocalChangeResponse changeId
                        |> Lamdera.sendToFrontend clientId
            in
            case result of
                Err error ->
                    BackendExtra.addLogWithCmd time (Log.FailedCloudflareSessionCreate error) model cmd

                Ok realtimeSessionId ->
                    case ( model.cloudflareRealtimeApiToken, model.cloudflareRealtimeAppId ) of
                        ( Just apiToken, Just cloudflareAppId ) ->
                            ( model
                            , Cloudflare.pushLocalTracks cloudflareAppId
                                apiToken
                                realtimeSessionId
                                { offerSdp = offerSdp, transceiverMids = transceiverMids }
                                |> Task.attempt (GotCloudflareSession sessionId clientId changeId time roomId realtimeSessionId)
                            )

                        _ ->
                            ( model, cmd )

        GotCloudflareSession sessionId clientId changeId time roomId realtimeSessionId result ->
            handleGotCloudflareSession sessionId clientId changeId time roomId realtimeSessionId result model

        GotCloudflarePullOffer time clientId changeId connectionId remoteSessionId trackNames result ->
            let
                cmd =
                    FilledInByBackend (Result.mapError (\_ -> ()) result)
                        |> Call.Local_PullTracks connectionId remoteSessionId trackNames
                        |> Local_VoiceChatChange
                        |> LocalChangeResponse changeId
                        |> Lamdera.sendToFrontend clientId
            in
            case result of
                Ok _ ->
                    ( model, cmd )

                Err error ->
                    BackendExtra.addLogWithCmd time (Log.FailedCloudflarePullOffer error) model cmd

        GotCloudflareRenegotiateAck clientId changeId sdp result ->
            ( model
            , Call.Local_RenegotiateAnswer sdp (FilledInByBackend (Result.mapError (\_ -> ()) result))
                |> Local_VoiceChatChange
                |> LocalChangeResponse changeId
                |> Lamdera.sendToFrontend clientId
            )

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
                                                                    { messages = IdArray.empty
                                                                    , lastTypedAt = SeqDict.empty
                                                                    , linkedMessageIds = OneToOne.empty
                                                                    , members =
                                                                        List.foldl
                                                                            (\member dict -> NonemptyDict.insert member { messagesSent = 0 } dict)
                                                                            (NonemptyDict.singleton discordUserId { messagesSent = 0 })
                                                                            data.members
                                                                    , dateDividerDrawings = SeqDict.empty
                                                                    }
                                                                        |> Just
                                                        )
                                                        dmChannels2
                                                )
                                                model.discordDmChannels
                                                dmData
                                    }
                            in
                            ( model2
                            , Broadcast.toUserAlt
                                discordUser.linkedTo
                                (\session connection ->
                                    let
                                        linkedAndOtherDiscordUsers =
                                            BackendExtra.getLinkedDiscordUsersAndOtherUsers
                                                session.userId
                                                connection.currentlyViewing
                                                model2
                                    in
                                    Server_DiscordUserLoadingDataIsDone
                                        discordUserId
                                        (Ok
                                            { discordGuilds =
                                                SeqDict.filterMap
                                                    (\guildId _ ->
                                                        case SeqDict.get guildId model2.discordGuilds of
                                                            Just guild ->
                                                                BackendExtra.discordGuildToFrontendForUser
                                                                    Nothing
                                                                    guild
                                                                    (LinkedAndOtherDiscordUsers.linkedUsers linkedAndOtherDiscordUsers)

                                                            Nothing ->
                                                                Nothing
                                                    )
                                                    guildDataDict
                                            , discordDms =
                                                List.filterMap
                                                    (\data ->
                                                        case SeqDict.get data.dmChannelId model2.discordDmChannels of
                                                            Just dmChannel ->
                                                                case
                                                                    BackendExtra.discordDmChannelToFrontend
                                                                        False
                                                                        dmChannel
                                                                        (LinkedAndOtherDiscordUsers.linkedUsers linkedAndOtherDiscordUsers)
                                                                of
                                                                    Just dmChannel2 ->
                                                                        Just ( data.dmChannelId, dmChannel2 )

                                                                    Nothing ->
                                                                        Nothing

                                                            Nothing ->
                                                                Nothing
                                                    )
                                                    dmData
                                                    |> SeqDict.fromList
                                            , discordUsers = LinkedAndOtherDiscordUsers.otherUsers linkedAndOtherDiscordUsers
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
                            DiscordSync.websocketClose (WebsocketClosed_ClosedByBackendForUser discordUserId) connection2
                                |> Task.perform (WebsocketClosedByBackendForUser discordUserId False)

                        Nothing ->
                            Command.none
                    )

                _ ->
                    ( model, Command.none )

        WebsocketClosedByBackendForUser discordUserId reopen websocketEvent ->
            ( recordWebsocketCloseEvent websocketEvent model
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
                                DiscordSync.messagesAndLinks
                                    (List.reverse messages)
                                    model.discordCustomEmojis
                                    model.discordStickers
                                    attachments2

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
                                DiscordSync.messagesAndLinks
                                    (List.reverse messages)
                                    model.discordCustomEmojis
                                    model.discordStickers
                                    attachments2

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
                                                    IdArray.foldl
                                                        (\message members ->
                                                            case message of
                                                                UserTextMessage message2 ->
                                                                    NonemptyDict.updateIfExists
                                                                        message2.createdBy
                                                                        (\a -> { a | messagesSent = a.messagesSent + 1 })
                                                                        members

                                                                UserJoinedMessage _ _ _ _ ->
                                                                    members

                                                                DeletedMessage _ ->
                                                                    members

                                                                CallStarted _ ->
                                                                    members

                                                                GameStarted _ ->
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
                            DmChannelId.toUserIds channelId
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
                            FileStatus.uploadBackup model.serverSecret ("backend-export-" ++ timestamp ++ ".bin") bytes
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

        GotDiscordReadyDataStickers userId results time ->
            let
                ( errors, stickers, newStickers ) =
                    gotDiscordStickers results model
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

        GotDiscordMessageStickers guildOrDmId results time ->
            let
                ( errors, stickers, newStickers ) =
                    gotDiscordStickers results model
            in
            case List.Nonempty.fromList errors of
                Just nonempty ->
                    BackendExtra.addLog
                        time
                        (Log.FailedToLoadDiscordGuildStickers nonempty (List.length results))
                        { model | stickers = stickers }

                Nothing ->
                    ( { model | stickers = stickers }
                    , case guildOrDmId of
                        MessageFromGuildOrDm_Guild guildId ->
                            Broadcast.toDiscordGuild
                                guildId
                                (Server_LinkedDiscordUserStickersLoaded newStickers |> ServerChange)
                                model

                        MessageFromGuildOrDm_Dm channelId ->
                            Broadcast.toDiscordDmChannel
                                channelId
                                (Server_LinkedDiscordUserStickersLoaded newStickers |> ServerChange)
                                model
                    )

        GotDiscordReadyDataCustomEmojis userId results time ->
            let
                ( errors, customEmojis, newCustomEmojis ) =
                    gotDiscordCustomEmojis results model
            in
            case List.Nonempty.fromList errors of
                Just nonempty ->
                    BackendExtra.addLog
                        time
                        (Log.FailedToLoadDiscordGuildCustomEmojis nonempty (List.length results))
                        { model
                            | customEmojis = customEmojis
                            , users = NonemptyDict.updateIfExists userId (User.addNewCustomEmojis newCustomEmojis) model.users
                        }

                Nothing ->
                    ( { model
                        | customEmojis = customEmojis
                        , users = NonemptyDict.updateIfExists userId (User.addNewCustomEmojis newCustomEmojis) model.users
                      }
                    , Broadcast.toUser
                        Nothing
                        Nothing
                        userId
                        (Server_LinkedDiscordUserCustomEmojisLoaded newCustomEmojis |> ServerChange)
                        model
                    )

        GotDiscordMessageCustomEmojis guildOrDmId results time ->
            let
                ( errors, customEmojis, newCustomEmojis ) =
                    gotDiscordCustomEmojis results model
            in
            case List.Nonempty.fromList errors of
                Just nonempty ->
                    BackendExtra.addLog
                        time
                        (Log.FailedToLoadDiscordGuildCustomEmojis nonempty (List.length results))
                        { model | customEmojis = customEmojis }

                Nothing ->
                    ( { model | customEmojis = customEmojis }
                    , case guildOrDmId of
                        MessageFromGuildOrDm_Guild guildId ->
                            Broadcast.toDiscordGuild
                                guildId
                                (Server_LinkedDiscordUserCustomEmojisLoaded newCustomEmojis |> ServerChange)
                                model

                        MessageFromGuildOrDm_Dm channelId ->
                            Broadcast.toDiscordDmChannel
                                channelId
                                (Server_LinkedDiscordUserCustomEmojisLoaded newCustomEmojis |> ServerChange)
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

                expiredSessions : List SessionId
                expiredSessions =
                    List.filterMap
                        (\( sessionId, session ) ->
                            let
                                latestRequest : Time.Posix
                                latestRequest =
                                    case SeqDict.get sessionId model.connections of
                                        Just connections ->
                                            NonemptyDict.foldl
                                                (\_ data latestRequest2 ->
                                                    case data.lastRequest of
                                                        NoRequestsMade ->
                                                            latestRequest2

                                                        LastRequest time2 ->
                                                            max (Time.posixToMillis time2) (Time.posixToMillis latestRequest2)
                                                                |> Time.millisToPosix
                                                )
                                                session.signedInAt
                                                connections

                                        Nothing ->
                                            session.signedInAt
                            in
                            if Duration.from latestRequest time |> Quantity.lessThan (Duration.days 30) then
                                Nothing

                            else
                                Just sessionId
                        )
                        (SeqDict.toList model.sessions)
            in
            ( if shouldExport then
                startExport time model

              else
                { model
                    | lastScheduledExportTime =
                        case model.lastScheduledExportTime of
                            Just _ ->
                                model.lastScheduledExportTime

                            Nothing ->
                                Just time
                    , deletedGuilds =
                        SeqDict.filter
                            (\_ deletedGuild ->
                                Duration.from deletedGuild.deletedAt time |> Quantity.lessThan (Duration.days 30)
                            )
                            model.deletedGuilds
                    , connections = List.foldl SeqDict.remove model.connections expiredSessions
                    , sessions = List.foldl SeqDict.remove model.sessions expiredSessions
                }
            , Command.batch
                [ Discord.getStickerPacksPayload
                    |> DiscordSync.http model.serverSecret
                    |> Task.attempt (GotDiscordStandardStickerPacks time)
                , checkCloudflareCost time model
                ]
            )

        GotCloudflareUsage time result ->
            case result of
                Ok egressBytes ->
                    let
                        cost : Float
                        cost =
                            Cloudflare.estimatedMonthlyCostUsd egressBytes
                    in
                    if cost > cloudflareCostThresholdUsd && not (cloudflareCostAlreadyLoggedThisMonth time model) then
                        BackendExtra.addLog time (Log.CloudflareCostExceeded cost egressBytes) model

                    else
                        ( model, Command.none )

                Err _ ->
                    ( model, Command.none )

        GotCloudflareEgressForAdmin clientId result ->
            ( model
            , Pages.Admin.CloudflareEgressResponse result
                |> AdminToFrontend
                |> Lamdera.sendToFrontend clientId
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

        RegeneratedServerSecret time changeId clientId result ->
            let
                responseCmd : Command BackendOnly ToFrontend BackendMsg
                responseCmd =
                    FilledInByBackend (Result.map (\_ -> time) result)
                        |> Pages.Admin.RegenerateServerSecret
                        |> Local_Admin
                        |> LocalChangeResponse changeId
                        |> Lamdera.sendToFrontend clientId
            in
            case result of
                Ok serverSecret ->
                    ( { model | serverSecret = serverSecret, serverSecretRegeneratedAt = Just time }
                    , responseCmd
                    )

                Err error ->
                    BackendExtra.addLogWithCmd time (Log.FailedToRegenerateServerSecret error) model responseCmd

        GotRustServerFileUpload fileHash fileSize2 maybeImageSize ->
            ( { model
                | files =
                    SeqDict.insert
                        fileHash
                        { fileSize = fileSize2, imageSize = maybeImageSize }
                        model.files
              }
            , Command.none
            )

        GotEnglishWordList result ->
            ( { model
                | wordSpellingGameEnglish =
                    case model.wordSpellingGameEnglish of
                        WordList_Loading ->
                            WordSpellingGame.parseWordList result

                        _ ->
                            model.wordSpellingGameEnglish
              }
            , Command.none
            )

        GotSwedishWordList result ->
            ( { model
                | wordSpellingGameSwedish =
                    case model.wordSpellingGameSwedish of
                        WordList_Loading ->
                            WordSpellingGame.parseWordList result

                        _ ->
                            model.wordSpellingGameSwedish
              }
            , Command.none
            )


gotDiscordStickers :
    List ( Id StickerId, Result Http.Error FileStatus.UploadResponse )
    -> BackendModel
    -> ( List ( Id StickerId, Http.Error ), SeqDict (Id StickerId) StickerData, SeqDict (Id StickerId) StickerData )
gotDiscordStickers results model =
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


gotDiscordCustomEmojis :
    List ( Id CustomEmojiId, Result Http.Error FileStatus.UploadResponse )
    -> BackendModel
    -> ( List ( Id CustomEmojiId, Http.Error ), SeqDict (Id CustomEmojiId) CustomEmojiData, SeqDict (Id CustomEmojiId) CustomEmojiData )
gotDiscordCustomEmojis results model =
    List.foldl
        (\( customEmojiId, result ) ( errors2, customEmojis2, newCustomEmojis2 ) ->
            case result of
                Ok uploadResponse ->
                    case SeqDict.get customEmojiId customEmojis2 of
                        Just customEmoji ->
                            case CustomEmoji.addUrl uploadResponse customEmoji of
                                Ok customEmoji2 ->
                                    ( errors2
                                    , SeqDict.insert customEmojiId customEmoji2 customEmojis2
                                    , SeqDict.insert customEmojiId customEmoji2 newCustomEmojis2
                                    )

                                Err () ->
                                    ( errors2, customEmojis2, newCustomEmojis2 )

                        Nothing ->
                            ( errors2, customEmojis2, newCustomEmojis2 )

                Err error ->
                    ( ( customEmojiId, error ) :: errors2, customEmojis2, newCustomEmojis2 )
        )
        ( [], model.customEmojis, SeqDict.empty )
        results


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
    , customEmojis = guild.customEmojis
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


recordWebsocketCloseEvent : WebsocketClosedEvent -> BackendModel -> BackendModel
recordWebsocketCloseEvent event model =
    let
        appended : Array WebsocketClosedEvent
        appended =
            Array.push event model.websocketCloseEvents

        excess : Int
        excess =
            Array.length appended - maxWebsocketCloseEvents
    in
    { model
        | websocketCloseEvents =
            if excess > 0 then
                Array.slice excess (Array.length appended) appended

            else
                appended
    }


maxWebsocketCloseEvents : Int
maxWebsocketCloseEvents =
    10000


disconnectClient : Time.Posix -> SessionId -> ClientId -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend msg )
disconnectClient time sessionId clientId model =
    case ( Pages.Admin.disconnectClient sessionId clientId model.connections, SeqDict.get sessionId model.sessions ) of
        ( Ok ( removedConnection, connections ), Just session ) ->
            let
                helper otherUserId =
                    let
                        dmChannelId =
                            DmChannelId.fromUserIds session.userId otherUserId
                    in
                    if voiceChatRoomHasOtherMembers dmChannelId clientId model then
                        model.dmChannels

                    else
                        SeqDict.updateIfExists dmChannelId (LocalState.markCallMessageAsEndedBackend time) model.dmChannels

                model2 =
                    { model
                        | connections = connections
                        , dmChannels =
                            case removedConnection.call of
                                ConnectingToCall (Call.DmRoomId otherUserId) ->
                                    helper otherUserId

                                ConnectedToCall (Call.DmRoomId otherUserId) _ ->
                                    helper otherUserId

                                NotInCall ->
                                    model.dmChannels
                    }
            in
            ( model2
            , Command.batch
                [ Broadcast.toUser
                    Nothing
                    Nothing
                    session.userId
                    (Server_ClientDisconnected session.sessionIdHash clientId |> ServerChange)
                    model2
                , case removedConnection.call of
                    ConnectingToCall (Call.DmRoomId otherUserId) ->
                        Broadcast.toDmChannel
                            session.userId
                            otherUserId
                            (\otherUserId2 ->
                                Call.Server_Left
                                    time
                                    { roomId = Call.DmRoomId otherUserId2
                                    , otherClientId = ( session.userId, clientId )
                                    }
                                    |> Server_VoiceChatChange
                            )
                            model2

                    ConnectedToCall (Call.DmRoomId otherUserId) _ ->
                        Broadcast.toDmChannel
                            session.userId
                            otherUserId
                            (\otherUserId2 ->
                                Call.Server_Left
                                    time
                                    { roomId = Call.DmRoomId otherUserId2
                                    , otherClientId = ( session.userId, clientId )
                                    }
                                    |> Server_VoiceChatChange
                            )
                            model2

                    NotInCall ->
                        Command.none
                ]
            )

        ( Ok ( _, connections ), Nothing ) ->
            ( { model | connections = connections }, Command.none )

        _ ->
            ( model, Command.none )


startExport : Time.Posix -> BackendModel -> BackendModel
startExport time model =
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
    -> BackendModel
    -> Task BackendOnly Discord.HttpError Discord.Channel
discordStartThread discordUser channel channelId threadId messageId model =
    Discord.startThreadFromMessagePayload
        (Discord.userToken discordUser.auth)
        { channelId = channelId
        , messageId = messageId
        , name =
            case IdArray.get threadId channel.messages of
                Just message ->
                    case message of
                        UserTextMessage a ->
                            RichText.toStringWithGetter DiscordUserData.username True model.discordUsers a.content

                        UserJoinedMessage _ userId _ _ ->
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

                        CallStarted callStarted ->
                            LocalState.callStartedText callStarted.endedAt

                        GameStarted gameStarted ->
                            LocalState.gameStartedText gameStarted.gameType

                Nothing ->
                    "Thread"
        , autoArchiveDuration = Missing
        , rateLimitPerUser = Missing
        }
        |> DiscordSync.http model.serverSecret


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
                ( model2, cmd ) =
                    case Broadcast.getUserFromSessionId sessionId model of
                        Just ( session, user ) ->
                            let
                                currentlyViewing =
                                    BackendExtra.requestedForToGuildOrDmId session.userId requestMessagesFor
                            in
                            ( { model
                                | connections =
                                    SeqDict.updateIfExists
                                        sessionId
                                        (NonemptyDict.updateIfExists
                                            clientId
                                            (\connection -> { connection | currentlyViewing = currentlyViewing })
                                        )
                                        model.connections
                              }
                            , BackendExtra.getLoginData sessionId clientId currentlyViewing session user requestMessagesFor model
                                |> Ok
                                |> CheckLoginResponse
                                |> Lamdera.sendToFrontend clientId
                            )

                        Nothing ->
                            ( model, CheckLoginResponse (Err ()) |> Lamdera.sendToFrontend clientId )
            in
            if model2.isInitialized then
                ( model2, cmd )

            else
                ( { model2 | isInitialized = True }
                , Command.batch
                    [ Http.request
                        { method = "GET"
                        , headers = [ FileStatus.secretKeyHeader model2.serverSecret ]
                        , url = FileStatus.domain ++ "/file/internal/vapid"
                        , body = Http.emptyBody
                        , expect = Http.expectString GotVapidKeys
                        , timeout = Just Duration.minute
                        , tracker = Nothing
                        }
                    , Discord.getStickerPacksPayload
                        |> DiscordSync.http model2.serverSecret
                        |> Task.attempt (GotDiscordStandardStickerPacks time)
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

                            currentlyViewing : Maybe ( AnyGuildOrDmId, ThreadRoute )
                            currentlyViewing =
                                BackendExtra.requestedForToGuildOrDmId session.userId requestMessagesFor

                            session : UserSession
                            session =
                                UserSession.init
                                    time
                                    sessionId
                                    userId
                                    userAgent

                            newUser : BackendUser
                            newUser =
                                User.init time personName pendingLogin.emailAddress False

                            model2 : BackendModel
                            model2 =
                                { model
                                    | sessions = SeqDict.insert sessionId session model.sessions
                                    , pendingLogins = SeqDict.remove sessionId model.pendingLogins
                                    , users = NonemptyDict.insert userId newUser model.users
                                    , connections =
                                        SeqDict.updateIfExists
                                            sessionId
                                            (NonemptyDict.updateIfExists
                                                clientId
                                                (\connection -> { connection | currentlyViewing = currentlyViewing })
                                            )
                                            model.connections
                                }
                        in
                        ( model2
                        , BackendExtra.getLoginData
                            sessionId
                            clientId
                            currentlyViewing
                            session
                            newUser
                            requestMessagesFor
                            model2
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
                                        currentlyViewing : Maybe ( AnyGuildOrDmId, ThreadRoute )
                                        currentlyViewing =
                                            BackendExtra.requestedForToGuildOrDmId pendingLogin.userId requestMessagesFor

                                        session : UserSession
                                        session =
                                            UserSession.init time sessionId pendingLogin.userId userAgent
                                    in
                                    ( { model
                                        | sessions = SeqDict.insert sessionId session model.sessions
                                        , connections =
                                            SeqDict.updateIfExists
                                                sessionId
                                                (NonemptyDict.updateIfExists
                                                    clientId
                                                    (\connection -> { connection | currentlyViewing = currentlyViewing })
                                                )
                                                model.connections
                                        , pendingLogins = SeqDict.remove sessionId model.pendingLogins
                                      }
                                    , Command.batch
                                        [ BackendExtra.getLoginData
                                            sessionId
                                            clientId
                                            currentlyViewing
                                            session
                                            user
                                            requestMessagesFor
                                            model
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
                                                , currentlyViewing = SeqDict.singleton clientId currentlyViewing
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
                                , BackendExtra.sendLoginEmail (SentLoginEmail time email2) email2 loginCode model3.postmarkApiKey
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
                                , BackendExtra.sendLoginEmail (SentLoginEmail time email2) email2 loginCode model3.postmarkApiKey
                                )

                            else
                                ( model3, Lamdera.sendToFrontend clientId SignupsDisabledResponse )

                        ( _, Err () ) ->
                            ( model3, Command.none )

                Nothing ->
                    ( model, Command.none )

        AdminToBackend adminToBackend ->
            BackendExtra.asAdmin
                model
                sessionId
                (\_ _ -> updateFromFrontendAdmin clientId adminToBackend model)

        LogOutRequest sessionIdHashToLogOut ->
            BackendExtra.asUser
                model
                sessionId
                (\session _ ->
                    case
                        List.Extra.find
                            (\( _, sessionToLogOut ) -> sessionToLogOut.sessionIdHash == sessionIdHashToLogOut)
                            (SeqDict.toList model.sessions)
                    of
                        Just ( sessionIdToLogOut, sessionToLogOut ) ->
                            if session.userId == sessionToLogOut.userId then
                                ( { model | sessions = SeqDict.remove sessionIdToLogOut model.sessions }
                                , Command.batch
                                    [ Lamdera.sendToFrontends sessionIdToLogOut LoggedOutSession
                                    , Broadcast.toUser
                                        Nothing
                                        (Just sessionIdToLogOut)
                                        session.userId
                                        (Server_LoggedOut sessionToLogOut.sessionIdHash |> ServerChange)
                                        model
                                    ]
                                )

                            else
                                ( model, Command.none )

                        Nothing ->
                            ( model, Command.none )
                )

        LocalModelChangeRequest changeId localMsg ->
            case localMsg of
                Local_Invalid ->
                    ( model, BackendExtra.invalidChangeResponse changeId clientId )

                Local_Admin adminChange ->
                    BackendExtra.asAdmin
                        model
                        sessionId
                        (adminChangeUpdate clientId changeId adminChange model time)

                Local_SendMessage _ guildOrDmId text threadRoute attachedFiles ->
                    if String.Nonempty.length text > RichText.maxLength then
                        ( model, BackendExtra.invalidChangeResponse changeId clientId )

                    else
                        case guildOrDmId of
                            GuildOrDmId_Guild guildId channelId ->
                                BackendExtra.asGuildMember
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
                                BackendExtra.asDmUser
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
                            BackendExtra.asDiscordGuildMember
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

                                                richText : Nonempty (RichText (Discord.Id Discord.UserId))
                                                richText =
                                                    textToDiscordRichText text (MembersAndOwner.membersAndOwner guild.membersAndOwner) model
                                            in
                                            case ( RichText.toDiscord model.discordCustomEmojis richText, threadRouteWithMaybeReplyTo ) of
                                                ( Ok discordText, NoThreadWithMaybeMessage maybeReplyTo ) ->
                                                    ( { model
                                                        | pendingDiscordCreateMessages =
                                                            SeqDict.insert
                                                                ( currentDiscordUserId, channelId )
                                                                ( clientId, changeId )
                                                                model.pendingDiscordCreateMessages
                                                        , sendMessageRateLimits = sendMessageRateLimits
                                                      }
                                                    , DiscordSync.sendMessage
                                                        model.serverSecret
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
                                                        discordText
                                                        richText
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

                                                ( Ok discordText, ViewThreadWithMaybeMessage threadId maybeReplyTo ) ->
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
                                                                            model.serverSecret
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
                                                                            discordText
                                                                            richText
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

                                                ( Err _, _ ) ->
                                                    ( model, BackendExtra.invalidChangeResponse changeId clientId )

                                        _ ->
                                            ( model, BackendExtra.invalidChangeResponse changeId clientId )
                                )

                        DiscordGuildOrDmId_Dm data ->
                            BackendExtra.asDiscordDmUser
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
                                            let
                                                richText : Nonempty (RichText (Discord.Id Discord.UserId))
                                                richText =
                                                    textToDiscordRichText
                                                        text
                                                        (NonemptyDict.keys dmChannel.members |> List.Nonempty.toList)
                                                        model
                                            in
                                            case RichText.toDiscord model.discordCustomEmojis richText of
                                                Ok discordText ->
                                                    ( { model
                                                        | pendingDiscordCreateDmMessages =
                                                            SeqDict.insert
                                                                data
                                                                ( clientId, changeId )
                                                                model.pendingDiscordCreateDmMessages
                                                        , sendMessageRateLimits = sendMessageRateLimits
                                                      }
                                                    , DiscordSync.sendMessage
                                                        model.serverSecret
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
                                                        discordText
                                                        richText
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

                                                Err _ ->
                                                    ( model, BackendExtra.invalidChangeResponse changeId clientId )

                                        _ ->
                                            ( model, BackendExtra.invalidChangeResponse changeId clientId )
                                )

                Local_NewChannel _ guildId channelName channelDescription ->
                    BackendExtra.asGuildOwner
                        model
                        sessionId
                        guildId
                        (\userId _ guild ->
                            ( { model
                                | guilds =
                                    SeqDict.insert
                                        guildId
                                        (LocalState.createChannel time userId channelName channelDescription guild)
                                        model.guilds
                              }
                            , Command.batch
                                [ Local_NewChannel time guildId channelName channelDescription
                                    |> LocalChangeResponse changeId
                                    |> Lamdera.sendToFrontend clientId
                                , Broadcast.toGuildExcludingOne
                                    clientId
                                    guildId
                                    (Server_NewChannel time guildId channelName channelDescription |> ServerChange)
                                    model
                                ]
                            )
                        )

                Local_EditChannel guildId channelId channelName channelDescription ->
                    BackendExtra.asGuildOwner
                        model
                        sessionId
                        guildId
                        (\_ _ guild ->
                            ( { model
                                | guilds =
                                    SeqDict.insert
                                        guildId
                                        (LocalState.editChannel channelName channelDescription channelId guild)
                                        model.guilds
                              }
                            , Command.batch
                                [ LocalChangeResponse changeId localMsg
                                    |> Lamdera.sendToFrontend clientId
                                , Broadcast.toGuildExcludingOne
                                    clientId
                                    guildId
                                    (Server_EditChannel guildId channelId channelName channelDescription |> ServerChange)
                                    model
                                ]
                            )
                        )

                Local_DeleteChannel guildId channelId ->
                    BackendExtra.asGuildOwner
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

                Local_DeleteGuild guildId ->
                    BackendExtra.asGuildOwner
                        model
                        sessionId
                        guildId
                        (\_ _ guild ->
                            ( { model
                                | guilds = SeqDict.remove guildId model.guilds
                                , deletedGuilds =
                                    SeqDict.insert
                                        guildId
                                        { guild = guild, deletedAt = time }
                                        model.deletedGuilds
                              }
                            , Command.batch
                                [ LocalChangeResponse changeId localMsg
                                    |> Lamdera.sendToFrontend clientId
                                , Broadcast.toGuildExcludingOne
                                    clientId
                                    guildId
                                    (Server_DeleteGuild guildId |> ServerChange)
                                    model
                                ]
                            )
                        )

                Local_NewInviteLink _ guildId _ ->
                    BackendExtra.asGuildMember
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

                Local_DeleteInviteLink guildId inviteLinkId ->
                    BackendExtra.asGuildOwner
                        model
                        sessionId
                        guildId
                        (\_ _ guild ->
                            ( { model
                                | guilds =
                                    SeqDict.insert
                                        guildId
                                        (LocalState.removeInvite inviteLinkId guild)
                                        model.guilds
                              }
                            , Command.batch
                                [ LocalChangeResponse changeId localMsg
                                    |> Lamdera.sendToFrontend clientId
                                , Broadcast.toGuildExcludingOne
                                    clientId
                                    guildId
                                    (Server_DeleteInviteLink guildId inviteLinkId |> ServerChange)
                                    model
                                ]
                            )
                        )

                Local_NewGuild _ guildName _ ->
                    BackendExtra.asUser
                        model
                        sessionId
                        (\{ userId } _ ->
                            ( { model
                                | nextGuildId = Id.increment model.nextGuildId
                                , guilds =
                                    SeqDict.insert
                                        model.nextGuildId
                                        (LocalState.createGuild time userId guildName)
                                        model.guilds
                              }
                            , Command.batch
                                [ Local_NewGuild time guildName (FilledInByBackend model.nextGuildId)
                                    |> LocalChangeResponse changeId
                                    |> Lamdera.sendToFrontend clientId
                                , Broadcast.toUser
                                    (Just clientId)
                                    Nothing
                                    userId
                                    (Local_NewGuild time guildName (FilledInByBackend model.nextGuildId) |> LocalChange userId)
                                    model
                                ]
                            )
                        )

                Local_MemberTyping _ ( guildOrDmId, threadRoute ) ->
                    case guildOrDmId of
                        GuildOrDmId (GuildOrDmId_Guild guildId channelId) ->
                            BackendExtra.asGuildMember
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
                            BackendExtra.asDmUser
                                model
                                sessionId
                                { otherUserId = otherUserId }
                                (\{ userId } _ _ dmChannelId _ ->
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
                            BackendExtra.asDiscordGuildMember
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
                                                            |> DiscordSync.http model.serverSecret
                                                            |> Task.attempt (\_ -> DiscordTypingIndicatorSent)

                                                    Nothing ->
                                                        Command.none
                                                ]
                                            )

                                        Nothing ->
                                            ( model, BackendExtra.invalidChangeResponse changeId clientId )
                                )

                        DiscordGuildOrDmId (DiscordGuildOrDmId_Dm data) ->
                            BackendExtra.asDiscordDmUser
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
                                            |> DiscordSync.http model.serverSecret
                                            |> Task.attempt (\_ -> DiscordTypingIndicatorSent)
                                        ]
                                    )
                                )

                Local_AddReactionEmoji guildOrDmId threadRoute emoji ->
                    case guildOrDmId of
                        GuildOrDmId (GuildOrDmId_Guild guildId channelId) ->
                            BackendExtra.asGuildMember
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
                            BackendExtra.asDmUser
                                model
                                sessionId
                                { otherUserId = otherUserId }
                                (\{ userId } user _ dmChannelId _ ->
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
                            BackendExtra.asDiscordGuildMember
                                model
                                sessionId
                                guildId
                                currentUserId
                                (\session userData user guild ->
                                    case
                                        ( SeqDict.get channelId guild.channels
                                        , emojiOrCustomEmojiToDiscord model.discordCustomEmojis emoji
                                        )
                                    of
                                        ( Just channel, Ok discordEmoji ) ->
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
                                                            , emoji = discordEmoji
                                                            }
                                                            |> DiscordSync.http model.serverSecret
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

                                        _ ->
                                            ( model
                                            , BackendExtra.invalidChangeResponse changeId clientId
                                            )
                                )

                        DiscordGuildOrDmId (DiscordGuildOrDmId_Dm data) ->
                            BackendExtra.asDiscordDmUser
                                model
                                sessionId
                                data
                                (\session userData user channel ->
                                    case ( threadRoute, emojiOrCustomEmojiToDiscord model.discordCustomEmojis emoji ) of
                                        ( NoThreadWithMessage messageId, Ok discordEmoji ) ->
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
                                                            , emoji = discordEmoji
                                                            }
                                                            |> DiscordSync.http model.serverSecret
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

                                        _ ->
                                            ( model, Command.none )
                                )

                Local_RemoveReactionEmoji guildOrDmId threadRoute emoji ->
                    case guildOrDmId of
                        GuildOrDmId (GuildOrDmId_Guild guildId channelId) ->
                            BackendExtra.asGuildMember
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
                            BackendExtra.asDmUser
                                model
                                sessionId
                                { otherUserId = otherUserId }
                                (\{ userId } _ _ dmChannelId _ ->
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
                            BackendExtra.asDiscordGuildMember
                                model
                                sessionId
                                guildId
                                currentUserId
                                (\_ userData _ guild ->
                                    case
                                        ( SeqDict.get channelId guild.channels
                                        , emojiOrCustomEmojiToDiscord model.discordCustomEmojis emoji
                                        )
                                    of
                                        ( Just channel, Ok discordEmoji ) ->
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
                                                            , emoji = discordEmoji
                                                            }
                                                            |> DiscordSync.http model.serverSecret
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

                                        _ ->
                                            ( model
                                            , BackendExtra.invalidChangeResponse changeId clientId
                                            )
                                )

                        DiscordGuildOrDmId (DiscordGuildOrDmId_Dm data) ->
                            BackendExtra.asDiscordDmUser
                                model
                                sessionId
                                data
                                (\_ userData _ channel ->
                                    case ( threadRoute, emojiOrCustomEmojiToDiscord model.discordCustomEmojis emoji ) of
                                        ( NoThreadWithMessage messageId, Ok discordEmoji ) ->
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
                                                            , emoji = discordEmoji
                                                            }
                                                            |> DiscordSync.http model.serverSecret
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

                                        _ ->
                                            ( model, Command.none )
                                )

                Local_SendEditMessage _ guildOrDmId threadRoute newContent attachedFiles ->
                    if String.Nonempty.length newContent > RichText.maxLength then
                        ( model, BackendExtra.invalidChangeResponse changeId clientId )

                    else
                        let
                            attachedFiles2 : SeqDict (Id FileId) FileData
                            attachedFiles2 =
                                BackendExtra.validateAttachedFiles model.files attachedFiles
                        in
                        case guildOrDmId of
                            GuildOrDmId_Guild guildId channelId ->
                                BackendExtra.asGuildMember
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
                                BackendExtra.asDmUser
                                    model
                                    sessionId
                                    { otherUserId = otherUserId }
                                    (\session user otherUser dmChannelId dmChannel ->
                                        let
                                            richText : Nonempty (RichText (Id UserId))
                                            richText =
                                                RichText.fromNonemptyString
                                                    (SeqDict.fromList
                                                        [ ( session.userId, user )
                                                        , ( otherUserId, otherUser )
                                                        ]
                                                    )
                                                    newContent
                                        in
                                        case
                                            LocalState.editMessageHelper
                                                time
                                                session.userId
                                                richText
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
                                                        session.userId
                                                        otherUserId
                                                        (\otherUserId2 ->
                                                            Server_SendEditMessage
                                                                time
                                                                session.userId
                                                                (GuildOrDmId_Dm otherUserId2)
                                                                threadRoute
                                                                richText
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
                    BackendExtra.asDiscordGuildMember
                        model
                        sessionId
                        guildId
                        currentUserId
                        (\_ userData _ guild ->
                            case SeqDict.get channelId guild.channels of
                                Just channel ->
                                    let
                                        richText : Nonempty (RichText (Discord.Id Discord.UserId))
                                        richText =
                                            textToDiscordRichText
                                                newContent
                                                (MembersAndOwner.membersAndOwner guild.membersAndOwner)
                                                model
                                    in
                                    case
                                        ( RichText.toDiscord model.discordCustomEmojis richText
                                        , LocalState.editMessageHelper
                                            time
                                            currentUserId
                                            richText
                                            DoNotChangeAttachments
                                            threadRoute
                                            channel
                                        )
                                    of
                                        ( Ok discordText, Ok channel2 ) ->
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
                                                        richText
                                                        |> ServerChange
                                                    )
                                                    model
                                                , case threadRouteToDiscordMessageId channelId channel2 threadRoute of
                                                    Just ( discordChannelId, discordMessageId ) ->
                                                        Discord.editMessagePayload
                                                            (Discord.userToken userData.auth)
                                                            { channelId = discordChannelId
                                                            , messageId = discordMessageId
                                                            , content = discordText
                                                            }
                                                            |> DiscordSync.http model.serverSecret
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

                                        _ ->
                                            ( model
                                            , BackendExtra.invalidChangeResponse changeId clientId
                                            )

                                Nothing ->
                                    ( model
                                    , BackendExtra.invalidChangeResponse changeId clientId
                                    )
                        )

                Local_Discord_SendEditDmMessage _ dmData messageId newContent ->
                    BackendExtra.asDiscordDmUser
                        model
                        sessionId
                        dmData
                        (\_ userData _ channel ->
                            let
                                richText : Nonempty (RichText (Discord.Id Discord.UserId))
                                richText =
                                    textToDiscordRichText
                                        newContent
                                        (NonemptyDict.keys channel.members |> List.Nonempty.toList)
                                        model
                            in
                            case
                                ( RichText.toDiscord model.discordCustomEmojis richText
                                , LocalState.editMessageHelperNoThread
                                    time
                                    dmData.currentUserId
                                    richText
                                    DoNotChangeAttachments
                                    messageId
                                    channel
                                )
                            of
                                ( Ok discordText, Ok channel2 ) ->
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
                                                richText
                                                |> ServerChange
                                            )
                                            model
                                        , case OneToOne.first messageId channel2.linkedMessageIds of
                                            Just discordMessageId ->
                                                Discord.editMessagePayload
                                                    (Discord.userToken userData.auth)
                                                    { channelId = Discord.idToUInt64 dmData.channelId |> Discord.idFromUInt64
                                                    , messageId = discordMessageId
                                                    , content = discordText
                                                    }
                                                    |> DiscordSync.http model.serverSecret
                                                    |> Task.attempt
                                                        (EditedDiscordDmMessage time dmData.channelId messageId discordMessageId)

                                            Nothing ->
                                                Command.none
                                        ]
                                    )

                                _ ->
                                    ( model, BackendExtra.invalidChangeResponse changeId clientId )
                        )

                Local_MemberEditTyping _ guildOrDmId threadRoute ->
                    case guildOrDmId of
                        GuildOrDmId (GuildOrDmId_Guild guildId channelId) ->
                            BackendExtra.asGuildMember
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
                            BackendExtra.asDmUser
                                model
                                sessionId
                                { otherUserId = otherUserId }
                                (\{ userId } _ _ dmChannelId dmChannel ->
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
                            BackendExtra.asDiscordGuildMember
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
                            BackendExtra.asDiscordDmUser
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
                            BackendExtra.asGuildMember model sessionId guildId (\session user _ -> helper session user)

                        GuildOrDmId (GuildOrDmId_Dm otherUserId) ->
                            BackendExtra.asDmUser
                                model
                                sessionId
                                { otherUserId = otherUserId }
                                (\session user _ _ _ -> helper session user)

                        DiscordGuildOrDmId (DiscordGuildOrDmId_Guild userId guildId _) ->
                            BackendExtra.asDiscordGuildMember_AllowUserThatNeedsAuthAgain
                                model
                                sessionId
                                clientId
                                guildId
                                userId
                                (\session _ _ user _ -> helper session user)

                        DiscordGuildOrDmId (DiscordGuildOrDmId_Dm data) ->
                            BackendExtra.asDiscordDmUser_AllowUserThatNeedsAuthAgain
                                model
                                sessionId
                                data
                                (\session _ user _ -> helper session user)

                Local_DeleteMessage guildOrDmId threadRoute ->
                    case guildOrDmId of
                        GuildOrDmId (GuildOrDmId_Guild guildId channelId) ->
                            BackendExtra.asGuildMember
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
                            BackendExtra.asDmUser
                                model
                                sessionId
                                { otherUserId = otherUserId }
                                (\{ userId } _ _ dmChannelId dmChannel ->
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
                            BackendExtra.asDiscordGuildMember
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
                                                            |> DiscordSync.http model.serverSecret
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
                            BackendExtra.asDiscordDmUser
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
                                                                    |> DiscordSync.http model.serverSecret
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
                        currentlyViewing : Maybe ( AnyGuildOrDmId, ThreadRoute )
                        currentlyViewing =
                            UserSession.setViewingToCurrentlyViewing viewing

                        broadcastCmd : UserSession -> Command BackendOnly ToFrontend msg
                        broadcastCmd session =
                            Broadcast.toUser
                                (Just clientId)
                                Nothing
                                session.userId
                                (Server_CurrentlyViewing session.sessionIdHash clientId currentlyViewing |> ServerChange)
                                model

                        getNewUsers :
                            ConnectionData
                            -> Discord.Id Discord.GuildId
                            -> DiscordBackendGuild
                            -> SeqDict (Discord.Id Discord.UserId) DiscordFrontendUser
                        getNewUsers connection guildId guild =
                            case connection.currentlyViewing of
                                Just ( DiscordGuildOrDmId (DiscordGuildOrDmId_Guild _ previousGuildId _), _ ) ->
                                    if guildId == previousGuildId then
                                        SeqDict.empty

                                    else
                                        getNewUsersHelper guild

                                _ ->
                                    getNewUsersHelper guild

                        getNewUsersHelper : DiscordBackendGuild -> SeqDict (Discord.Id Discord.UserId) DiscordFrontendUser
                        getNewUsersHelper guild =
                            List.foldl
                                (\memberId dict ->
                                    case SeqDict.get memberId model.discordUsers of
                                        Just member ->
                                            SeqDict.insert
                                                memberId
                                                (User.discordUserDataToFrontendUser member)
                                                dict

                                        Nothing ->
                                            dict
                                )
                                SeqDict.empty
                                (MembersAndOwner.membersAndOwner guild.membersAndOwner)
                    in
                    case viewing of
                        ViewDm otherUserId _ ->
                            BackendExtra.asDmUser
                                model
                                sessionId
                                { otherUserId = otherUserId }
                                (\session user _ _ dmChannel ->
                                    ( { model
                                        | users =
                                            NonemptyDict.insert
                                                session.userId
                                                (User.setLastDmViewed (DmChannelLastViewed otherUserId NoThread) user)
                                                model.users
                                        , connections =
                                            SeqDict.updateIfExists
                                                sessionId
                                                (NonemptyDict.updateIfExists
                                                    clientId
                                                    (\connection -> { connection | currentlyViewing = currentlyViewing })
                                                )
                                                model.connections
                                      }
                                    , Command.batch
                                        [ ViewDm otherUserId (loadMessagesHelper dmChannel |> FilledInByBackend)
                                            |> Local_CurrentlyViewing
                                            |> LocalChangeResponse changeId
                                            |> Lamdera.sendToFrontend clientId
                                        , broadcastCmd session
                                        ]
                                    )
                                )

                        ViewDmThread otherUserId threadId _ ->
                            BackendExtra.asDmUser
                                model
                                sessionId
                                { otherUserId = otherUserId }
                                (\session user _ _ dmChannel ->
                                    ( { model
                                        | users =
                                            NonemptyDict.insert
                                                session.userId
                                                (User.setLastDmViewed (DmChannelLastViewed otherUserId (ViewThread threadId)) user)
                                                model.users
                                        , connections =
                                            SeqDict.updateIfExists
                                                sessionId
                                                (NonemptyDict.updateIfExists
                                                    clientId
                                                    (\connection -> { connection | currentlyViewing = currentlyViewing })
                                                )
                                                model.connections
                                      }
                                    , Command.batch
                                        [ ViewDmThread
                                            otherUserId
                                            threadId
                                            (SeqDict.get threadId dmChannel.threads
                                                |> Maybe.withDefault Thread.backendInit
                                                |> loadMessagesHelper
                                                |> FilledInByBackend
                                            )
                                            |> Local_CurrentlyViewing
                                            |> LocalChangeResponse changeId
                                            |> Lamdera.sendToFrontend clientId
                                        , broadcastCmd session
                                        ]
                                    )
                                )

                        ViewDiscordDm currentUserId dmChannelId _ ->
                            BackendExtra.asDiscordDmUser_AllowUserThatNeedsAuthAgain
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
                                        , connections =
                                            SeqDict.updateIfExists
                                                sessionId
                                                (NonemptyDict.updateIfExists
                                                    clientId
                                                    (\connection -> { connection | currentlyViewing = currentlyViewing })
                                                )
                                                model.connections
                                      }
                                    , Command.batch
                                        [ ViewDiscordDm
                                            currentUserId
                                            dmChannelId
                                            (loadMessagesHelper dmChannel |> FilledInByBackend)
                                            |> Local_CurrentlyViewing
                                            |> LocalChangeResponse changeId
                                            |> Lamdera.sendToFrontend clientId
                                        , broadcastCmd session
                                        ]
                                    )
                                )

                        ViewChannel guildId channelId _ ->
                            BackendExtra.asGuildMember
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
                                                , connections =
                                                    SeqDict.updateIfExists
                                                        sessionId
                                                        (NonemptyDict.updateIfExists
                                                            clientId
                                                            (\connection -> { connection | currentlyViewing = currentlyViewing })
                                                        )
                                                        model.connections
                                              }
                                            , Command.batch
                                                [ ViewChannel
                                                    guildId
                                                    channelId
                                                    (loadMessagesHelper channel |> FilledInByBackend)
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
                            BackendExtra.asGuildMember
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
                                                , connections =
                                                    SeqDict.updateIfExists
                                                        sessionId
                                                        (NonemptyDict.updateIfExists
                                                            clientId
                                                            (\connection -> { connection | currentlyViewing = currentlyViewing })
                                                        )
                                                        model.connections
                                              }
                                            , Command.batch
                                                [ ViewChannelThread
                                                    guildId
                                                    channelId
                                                    threadId
                                                    (SeqDict.get threadId channel.threads
                                                        |> Maybe.withDefault Thread.backendInit
                                                        |> loadMessagesHelper
                                                        |> FilledInByBackend
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
                            BackendExtra.asUser
                                model
                                sessionId
                                (\session _ ->
                                    ( { model
                                        | connections =
                                            SeqDict.updateIfExists
                                                sessionId
                                                (NonemptyDict.updateIfExists
                                                    clientId
                                                    (\connection -> { connection | currentlyViewing = currentlyViewing })
                                                )
                                                model.connections
                                      }
                                    , Command.batch
                                        [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                                        , broadcastCmd session
                                        ]
                                    )
                                )

                        ViewDiscordChannel guildId channelId currentDiscordUserId _ ->
                            BackendExtra.asDiscordGuildMember_AllowUserThatNeedsAuthAgain
                                model
                                sessionId
                                clientId
                                guildId
                                currentDiscordUserId
                                (\session connectionData _ user guild ->
                                    case SeqDict.get channelId guild.channels of
                                        Just channel ->
                                            ( { model
                                                | users =
                                                    NonemptyDict.insert
                                                        session.userId
                                                        (User.setLastDiscordChannelViewed guildId channelId NoThread user)
                                                        model.users
                                                , connections =
                                                    SeqDict.updateIfExists
                                                        sessionId
                                                        (NonemptyDict.updateIfExists
                                                            clientId
                                                            (\connection -> { connection | currentlyViewing = currentlyViewing })
                                                        )
                                                        model.connections
                                              }
                                            , Command.batch
                                                [ ViewDiscordChannel
                                                    guildId
                                                    channelId
                                                    currentDiscordUserId
                                                    ({ messages = loadMessagesHelper channel
                                                     , newUsers = getNewUsers connectionData guildId guild
                                                     }
                                                        |> FilledInByBackend
                                                    )
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
                            BackendExtra.asDiscordGuildMember_AllowUserThatNeedsAuthAgain
                                model
                                sessionId
                                clientId
                                guildId
                                currentDiscordUserId
                                (\session connectionData _ user guild ->
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
                                                , connections =
                                                    SeqDict.updateIfExists
                                                        sessionId
                                                        (NonemptyDict.updateIfExists
                                                            clientId
                                                            (\connection -> { connection | currentlyViewing = currentlyViewing })
                                                        )
                                                        model.connections
                                              }
                                            , Command.batch
                                                [ ViewDiscordChannelThread
                                                    guildId
                                                    channelId
                                                    currentDiscordUserId
                                                    threadId
                                                    ({ messages =
                                                        SeqDict.get threadId channel.threads
                                                            |> Maybe.withDefault Thread.discordBackendInit
                                                            |> loadMessagesHelper
                                                     , newUsers = getNewUsers connectionData guildId guild
                                                     }
                                                        |> FilledInByBackend
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
                    BackendExtra.asUser
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
                            BackendExtra.asGuildMember
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
                            BackendExtra.asDmUser
                                model
                                sessionId
                                { otherUserId = otherUserId }
                                (\_ _ _ _ dmChannel ->
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
                            BackendExtra.asGuildMember
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
                            BackendExtra.asDmUser
                                model
                                sessionId
                                { otherUserId = otherUserId }
                                (\_ _ _ _ dmChannel ->
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
                            BackendExtra.asDiscordGuildMember_AllowUserThatNeedsAuthAgain
                                model
                                sessionId
                                clientId
                                guildId
                                currentUserId
                                (\_ _ _ _ guild ->
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
                            BackendExtra.asDiscordDmUser_AllowUserThatNeedsAuthAgain
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
                            BackendExtra.asDiscordGuildMember
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
                    BackendExtra.asGuildMember
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
                    BackendExtra.asDiscordGuildMember
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
                    BackendExtra.asUser
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

                Local_SetEmailNotifications emailNotifications ->
                    BackendExtra.asUser
                        model
                        sessionId
                        (\session user ->
                            ( { model
                                | users =
                                    NonemptyDict.insert
                                        session.userId
                                        (User.setEmailNotifications emailNotifications user)
                                        model.users
                              }
                            , Lamdera.sendToFrontend clientId (LocalChangeResponse changeId localMsg)
                            )
                        )

                Local_RegisterPushSubscription _ pushSubscription ->
                    BackendExtra.asUser
                        model
                        sessionId
                        (\session _ ->
                            case pushSubscription of
                                GotSubscribeData subscribeData ->
                                    ( { model
                                        | sessions =
                                            SeqDict.insert
                                                sessionId
                                                { session | pushSubscription = Subscribed subscribeData time }
                                                model.sessions
                                      }
                                    , Command.batch
                                        [ LocalChangeResponse changeId (Local_RegisterPushSubscription time pushSubscription)
                                            |> Lamdera.sendToFrontend clientId
                                        , Broadcast.pushNotification
                                            sessionId
                                            session.userId
                                            time
                                            "Success!"
                                            "Push notifications enabled"
                                            "https://at-chat.app/at-logo-no-background.png"
                                            Nothing
                                            subscribeData
                                            model
                                        ]
                                    )

                                SubscribeJsException jsError ->
                                    ( { model
                                        | sessions =
                                            SeqDict.insert
                                                sessionId
                                                { session | pushSubscription = SubscriptionJsException jsError time }
                                                model.sessions
                                      }
                                    , LocalChangeResponse changeId (Local_RegisterPushSubscription time pushSubscription)
                                        |> Lamdera.sendToFrontend clientId
                                    )
                        )

                Local_TextEditor localChange ->
                    BackendExtra.asUser
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
                    BackendExtra.asUser
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
                                                        (WebsocketClosedByBackendForUser discordUserId False)
                                                        (DiscordSync.websocketClose
                                                            (WebsocketClosed_UnlinkDiscordUser discordUserId)
                                                            connection
                                                        )

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
                    BackendExtra.asDiscordUser
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
                                        |> DiscordSync.http model.serverSecret
                                        |> Task.attempt (ReloadDiscordUserStep1 time clientId session.userId discordUserId)
                                    ]
                                )
                        )

                Local_LinkDiscordAcknowledgementIsChecked isChecked ->
                    BackendExtra.asUser
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
                    BackendExtra.asUser
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
                    BackendExtra.asUser
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
                    BackendExtra.asUser
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

                Local_AddCustomEmojisToUser customEmojiIds ->
                    BackendExtra.asUser
                        model
                        sessionId
                        (\session user ->
                            let
                                validIds : SeqSet (Id CustomEmojiId)
                                validIds =
                                    SeqSet.filter
                                        (\id -> SeqDict.member id model.customEmojis)
                                        (NonemptySet.toSeqSet customEmojiIds)
                            in
                            ( { model
                                | users =
                                    NonemptyDict.insert
                                        session.userId
                                        { user | availableCustomEmojis = SeqSet.union validIds user.availableCustomEmojis }
                                        model.users
                              }
                            , Lamdera.sendToFrontend clientId (LocalChangeResponse changeId localMsg)
                            )
                        )

                Local_VoiceChatChange voiceChatLocalChange ->
                    handleVoiceChatChange time changeId clientId sessionId voiceChatLocalChange model

                Local_Game guildOrDmId gameChange ->
                    case guildOrDmId of
                        GuildOrDmId_Dm otherUserId ->
                            BackendExtra.asDmUser
                                model
                                sessionId
                                { otherUserId = otherUserId }
                                (\session _ _ dmChannelId dmChannel ->
                                    case gameChange of
                                        Game.LocalChange_Go matchId goChange ->
                                            let
                                                ( model2, cmd ) =
                                                    handleDmGoGame
                                                        time
                                                        session
                                                        clientId
                                                        changeId
                                                        otherUserId
                                                        matchId
                                                        goChange
                                                        dmChannelId
                                                        dmChannel
                                                        model
                                            in
                                            case goChange of
                                                Go.StartMatch _ _ ->
                                                    let
                                                        ( sessions, notificationCmd ) =
                                                            Broadcast.gameStartedDmNotification
                                                                time
                                                                session.userId
                                                                otherUserId
                                                                GameType_Go
                                                                model2
                                                    in
                                                    ( { model2 | sessions = sessions }
                                                    , Command.batch [ cmd, notificationCmd ]
                                                    )

                                                _ ->
                                                    ( model2, cmd )

                                        Game.CreatePublicLink matchId _ ->
                                            case SeqDict.get matchId dmChannel.games of
                                                Just _ ->
                                                    case createGamePublicLinkHelper time clientId changeId session guildOrDmId matchId model of
                                                        GameLinkAlreadyExists cmd ->
                                                            ( model, cmd )

                                                        CreatedGameLink publicId model2 ->
                                                            let
                                                                localMsg2 : Game.LocalChange
                                                                localMsg2 =
                                                                    Game.CreatePublicLink matchId (FilledInByBackend publicId)
                                                            in
                                                            ( model2
                                                            , Command.batch
                                                                [ Local_Game guildOrDmId localMsg2
                                                                    |> LocalChangeResponse changeId
                                                                    |> Lamdera.sendToFrontend clientId
                                                                , Broadcast.toDmChannelExcludingOne
                                                                    clientId
                                                                    session.userId
                                                                    otherUserId
                                                                    (\otherUserId2 ->
                                                                        Server_Game session.userId (GuildOrDmId_Dm otherUserId2) localMsg2
                                                                    )
                                                                    model2
                                                                ]
                                                            )

                                                Nothing ->
                                                    ( model, BackendExtra.invalidChangeResponse changeId clientId )

                                        Game.LocalChange_WordSpellingGame matchId wsChange ->
                                            let
                                                ( model2, cmd ) =
                                                    handleWordSpellingGame
                                                        time
                                                        session
                                                        clientId
                                                        changeId
                                                        guildOrDmId
                                                        dmChannel
                                                        (\dmChannel2 model3 ->
                                                            { model3 | dmChannels = SeqDict.insert dmChannelId dmChannel2 model3.dmChannels }
                                                        )
                                                        (\localMsg2 model3 ->
                                                            Broadcast.toDmChannelExcludingOne
                                                                clientId
                                                                session.userId
                                                                otherUserId
                                                                (\otherUserId2 ->
                                                                    Server_Game session.userId (GuildOrDmId_Dm otherUserId2) localMsg2
                                                                )
                                                                model3
                                                        )
                                                        matchId
                                                        wsChange
                                                        model
                                            in
                                            case wsChange of
                                                WordSpellingGame.StartMatch _ _ ->
                                                    let
                                                        ( sessions, notificationCmd ) =
                                                            Broadcast.gameStartedDmNotification
                                                                time
                                                                session.userId
                                                                otherUserId
                                                                GameType_WordSpellingGame
                                                                model2
                                                    in
                                                    ( { model2 | sessions = sessions }
                                                    , Command.batch [ cmd, notificationCmd ]
                                                    )

                                                _ ->
                                                    ( model2, cmd )
                                )

                        GuildOrDmId_Guild guildId channelId ->
                            BackendExtra.asGuildMember
                                model
                                sessionId
                                guildId
                                (\session _ guild ->
                                    case SeqDict.get channelId guild.channels of
                                        Just channel ->
                                            case gameChange of
                                                Game.LocalChange_WordSpellingGame matchId wsChange ->
                                                    let
                                                        ( model2, cmd ) =
                                                            handleWordSpellingGame
                                                                time
                                                                session
                                                                clientId
                                                                changeId
                                                                guildOrDmId
                                                                channel
                                                                (\channel2 model3 ->
                                                                    { model3
                                                                        | guilds =
                                                                            SeqDict.insert
                                                                                guildId
                                                                                { guild | channels = SeqDict.insert channelId channel2 guild.channels }
                                                                                model3.guilds
                                                                    }
                                                                )
                                                                (\localMsg2 model3 ->
                                                                    Broadcast.toGuildExcludingOne
                                                                        clientId
                                                                        guildId
                                                                        (Server_Game session.userId guildOrDmId localMsg2 |> ServerChange)
                                                                        model3
                                                                )
                                                                matchId
                                                                wsChange
                                                                model
                                                    in
                                                    case wsChange of
                                                        WordSpellingGame.StartMatch _ _ ->
                                                            notifyGameStartedInGuild
                                                                time
                                                                session.userId
                                                                guildId
                                                                channelId
                                                                GameType_WordSpellingGame
                                                                guild
                                                                model2
                                                                cmd

                                                        _ ->
                                                            ( model2, cmd )

                                                Game.LocalChange_Go matchId goChange ->
                                                    let
                                                        ( model2, cmd ) =
                                                            handleGuildGoGame
                                                                time
                                                                session
                                                                clientId
                                                                changeId
                                                                guildId
                                                                channelId
                                                                matchId
                                                                goChange
                                                                guild
                                                                channel
                                                                model
                                                    in
                                                    case goChange of
                                                        Go.StartMatch _ _ ->
                                                            notifyGameStartedInGuild
                                                                time
                                                                session.userId
                                                                guildId
                                                                channelId
                                                                GameType_Go
                                                                guild
                                                                model2
                                                                cmd

                                                        _ ->
                                                            ( model2, cmd )

                                                Game.CreatePublicLink matchId _ ->
                                                    case SeqDict.get matchId channel.games of
                                                        Just _ ->
                                                            case createGamePublicLinkHelper time clientId changeId session guildOrDmId matchId model of
                                                                GameLinkAlreadyExists cmd ->
                                                                    ( model, cmd )

                                                                CreatedGameLink publicId model2 ->
                                                                    let
                                                                        localMsg2 : Game.LocalChange
                                                                        localMsg2 =
                                                                            Game.CreatePublicLink matchId (FilledInByBackend publicId)
                                                                    in
                                                                    ( model2
                                                                    , Command.batch
                                                                        [ Local_Game guildOrDmId localMsg2
                                                                            |> LocalChangeResponse changeId
                                                                            |> Lamdera.sendToFrontend clientId
                                                                        , Broadcast.toGuildExcludingOne
                                                                            clientId
                                                                            guildId
                                                                            (Server_Game
                                                                                session.userId
                                                                                (GuildOrDmId_Guild guildId channelId)
                                                                                localMsg2
                                                                                |> ServerChange
                                                                            )
                                                                            model2
                                                                        ]
                                                                    )

                                                        Nothing ->
                                                            ( model, BackendExtra.invalidChangeResponse changeId clientId )

                                        Nothing ->
                                            ( model, BackendExtra.invalidChangeResponse changeId clientId )
                                )

                Local_Drawing guildOrDmId anchor drawingChange ->
                    BackendExtra.handleDrawingChange sessionId clientId changeId guildOrDmId anchor drawingChange model

        TwoFactorToBackend toBackend2 ->
            BackendExtra.asUser
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
            BackendExtra.asUser
                model
                sessionId
                (joinGuildByInvite inviteLinkId time sessionId clientId guildId model)

        ReloadDataRequest requestMessagesFor ->
            BackendExtra.asUser
                model
                sessionId
                (\session user ->
                    let
                        currentlyViewing =
                            BackendExtra.requestedForToGuildOrDmId session.userId requestMessagesFor
                    in
                    ( { model
                        | connections =
                            SeqDict.updateIfExists
                                sessionId
                                (NonemptyDict.updateIfExists
                                    clientId
                                    (\connection -> { connection | currentlyViewing = currentlyViewing })
                                )
                                model.connections
                      }
                    , BackendExtra.getLoginData sessionId clientId currentlyViewing session user requestMessagesFor model
                        |> Ok
                        |> ReloadDataResponse
                        |> Lamdera.sendToFrontend clientId
                    )
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
            BackendExtra.asUser
                model
                sessionId
                (\session _ ->
                    if model.discordLinkingEnabled then
                        ( model
                        , Discord.getCurrentUserPayload (Discord.userToken data)
                            |> DiscordSync.http model.serverSecret
                            |> Task.attempt (LinkDiscordUserStep1 time clientId session.userId data)
                        )

                    else
                        ( model
                        , Lamdera.sendToFrontend
                            clientId
                            (LinkDiscordResponse (Err (Discord.UnexpectedError "Discord account linking is disabled")))
                        )
                )

        ProfilePictureEditorToBackend (ImageEditor.ChangeUserAvatarRequest fileHash) ->
            BackendExtra.asUser
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

        ProfilePictureEditorToBackend (ImageEditor.ChangeGuildIconRequest guildId fileHash) ->
            BackendExtra.asGuildOwner
                model
                sessionId
                guildId
                (\_ _ guild ->
                    ( { model
                        | guilds =
                            SeqDict.insert guildId { guild | icon = Just fileHash } model.guilds
                      }
                    , Command.batch
                        [ Lamdera.sendToFrontend
                            clientId
                            (ProfilePictureEditorToFrontend (ImageEditor.ChangeGuildIconResponse guildId))
                        , Broadcast.toGuild
                            guildId
                            (Server_SetGuildIcon guildId fileHash |> ServerChange)
                            model
                        ]
                    )
                )

        AdminDataRequest logPage ->
            BackendExtra.asAdmin
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

        GetPublicGoMatchRequest publicGoMatchId ->
            case OneToOne.second publicGoMatchId model.goMatchPublicIds of
                Just ( guildOrDmId, messageId ) ->
                    ( model
                    , (case guildOrDmId of
                        GuildOrFullDmId_Dm channelId ->
                            case SeqDict.get channelId model.dmChannels of
                                Just dmChannel ->
                                    handleGoMatchRequest time messageId dmChannel model

                                Nothing ->
                                    Err ()

                        GuildOrFullDmId_Guild guildId channelId ->
                            case SeqDict.get guildId model.guilds of
                                Just guild ->
                                    case SeqDict.get channelId guild.channels of
                                        Just channel ->
                                            handleGoMatchRequest time messageId channel model

                                        Nothing ->
                                            Err ()

                                Nothing ->
                                    Err ()
                      )
                        |> GetPublicGoMatchResponse
                        |> Lamdera.sendToFrontend clientId
                    )

                Nothing ->
                    ( model, GetPublicGoMatchResponse (Err ()) |> Lamdera.sendToFrontend clientId )


handleGoMatchRequest :
    Time.Posix
    -> Id ChannelMessageId
    -> { a | games : SeqDict (Id ChannelMessageId) Game.BackendGameData }
    -> BackendModel
    -> Result () Go.PublicGoMatchResponse
handleGoMatchRequest time messageId channel model =
    case SeqDict.get messageId channel.games of
        Just (Game.GameData_Go setup actions) ->
            let
                lookupUser : Id UserId -> User.FrontendUser
                lookupUser userId =
                    case NonemptyDict.get userId model.users of
                        Just user ->
                            User.backendToFrontendForUser user

                        Nothing ->
                            { name = PersonName.fromStringLossy "<missing>"
                            , isAdmin = False
                            , createdAt = time
                            , icon = Nothing
                            }
            in
            { setup = setup
            , actions = actions
            , creatorUser = lookupUser setup.createdBy
            , joinedUser =
                case Go.joinedUser actions of
                    Just userId ->
                        lookupUser userId |> Just

                    Nothing ->
                        Nothing
            }
                |> Ok

        _ ->
            Err ()


createGamePublicLinkHelper :
    Time.Posix
    -> ClientId
    -> ChangeId
    -> UserSession
    -> GuildOrDmId
    -> Id ChannelMessageId
    -> BackendModel
    -> CreatedGameLink
createGamePublicLinkHelper time clientId changeId session guildOrDmId matchId model =
    let
        guildOrFullDmId : GuildOrFullDmId
        guildOrFullDmId =
            case guildOrDmId of
                GuildOrDmId_Guild guildId channelId ->
                    GuildOrFullDmId_Guild guildId channelId

                GuildOrDmId_Dm otherUserId ->
                    GuildOrFullDmId_Dm (DmChannelId.fromUserIds session.userId otherUserId)
    in
    case OneToOne.first ( guildOrFullDmId, matchId ) model.goMatchPublicIds of
        Just publicId ->
            Game.CreatePublicLink matchId (FilledInByBackend publicId)
                |> Local_Game guildOrDmId
                |> LocalChangeResponse changeId
                |> Lamdera.sendToFrontend clientId
                |> GameLinkAlreadyExists

        Nothing ->
            let
                ( model3, publicId ) =
                    SecretId.getShortUniqueId time model
            in
            CreatedGameLink
                publicId
                { model3
                    | goMatchPublicIds =
                        OneToOne.insert publicId ( guildOrFullDmId, matchId ) model3.goMatchPublicIds
                }


type CreatedGameLink
    = CreatedGameLink (SecretId GamePublicId) BackendModel
    | GameLinkAlreadyExists (Command BackendOnly ToFrontend BackendMsg)


{-| Whether a Go action sent by a user is one they are allowed to make. Joining is valid for
anyone as long as the open seat hasn't been taken; everything else requires it to be the
sender's turn.
-}
isValidGoAction : Id UserId -> Go.ValidatedSetup -> Array Go.ActionWithTime -> Go.ActionWithTime -> Bool
isValidGoAction userId goSetup actions actionWithTime =
    case actionWithTime.change of
        Go.Joined joinedUserId ->
            (joinedUserId == userId) && (Go.joinedUser actions == Nothing)

        _ ->
            let
                players : { black : Maybe (Id UserId), white : Maybe (Id UserId) }
                players =
                    case goSetup.gameCreatorPlayingAs of
                        Go.White ->
                            { white = Just goSetup.createdBy, black = Go.joinedUser actions }

                        Go.Black ->
                            { black = Just goSetup.createdBy, white = Go.joinedUser actions }
            in
            case Go.currentPlayersTurn actions of
                Go.Black ->
                    players.black == Just userId

                Go.White ->
                    players.white == Just userId


{-| After a game is started in a guild channel, push a notification to the channel's members who
aren't currently viewing it. `cmd` is the command the game-start handler already produced; the
notification command is batched onto it and the notified users' sessions are folded back into the
model.
-}
notifyGameStartedInGuild :
    Time.Posix
    -> Id UserId
    -> Id GuildId
    -> Id ChannelId
    -> GameType
    -> BackendGuild
    -> BackendModel
    -> Command BackendOnly ToFrontend BackendMsg
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
notifyGameStartedInGuild time sender guildId channelId gameType guild model cmd =
    let
        ( sessions, notificationCmd ) =
            Broadcast.gameStartedGuildNotification
                time
                sender
                guildId
                channelId
                gameType
                (MembersAndOwner.membersAndOwner guild.membersAndOwner)
                model
    in
    ( { model | sessions = sessions }
    , Command.batch [ cmd, notificationCmd ]
    )


handleGuildGoGame :
    Time.Posix
    -> UserSession
    -> ClientId
    -> ChangeId
    -> Id GuildId
    -> Id ChannelId
    -> Id ChannelMessageId
    -> Go.LocalChange
    -> BackendGuild
    -> BackendChannel
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleGuildGoGame time session clientId changeId guildId channelId matchId goChange guild channel model =
    let
        guildOrDmId =
            GuildOrDmId_Guild guildId channelId
    in
    case goChange of
        Go.StartMatch createdAt setup ->
            let
                ( messageId, channel2 ) =
                    LocalState.createChannelMessageBackend
                        (GameStarted
                            { startedAt = createdAt
                            , startedBy = session.userId
                            , reactions = SeqDict.empty
                            , gameType = GameType_Go
                            , timestampDrawings = Drawing.emptyDrawing
                            , cardDrawings = Drawing.emptyDrawing
                            }
                        )
                        channel

                localMsg2 : Game.LocalChange
                localMsg2 =
                    Game.LocalChange_Go messageId (Go.StartMatch time setup)
            in
            ( { model
                | guilds =
                    SeqDict.insert
                        guildId
                        { guild
                            | channels =
                                SeqDict.insert
                                    channelId
                                    { channel2
                                        | games =
                                            SeqDict.insert
                                                messageId
                                                (Game.GameData_Go setup Array.empty)
                                                channel2.games
                                    }
                                    guild.channels
                        }
                        model.guilds
              }
            , Command.batch
                [ Local_Game guildOrDmId localMsg2
                    |> LocalChangeResponse changeId
                    |> Lamdera.sendToFrontend clientId
                , Broadcast.toGuildExcludingOne
                    clientId
                    guildId
                    (Server_Game session.userId guildOrDmId localMsg2 |> ServerChange)
                    model
                ]
            )

        Go.Action actionWithTime ->
            case SeqDict.get matchId channel.games of
                Just (Game.GameData_Go goSetup actions) ->
                    let
                        localMsg2 : Game.LocalChange
                        localMsg2 =
                            Game.LocalChange_Go matchId (Go.Action { actionWithTime | time = time })
                    in
                    if isValidGoAction session.userId goSetup actions actionWithTime then
                        ( { model
                            | guilds =
                                SeqDict.insert
                                    guildId
                                    { guild
                                        | channels =
                                            SeqDict.insert
                                                channelId
                                                { channel
                                                    | games =
                                                        SeqDict.insert
                                                            matchId
                                                            (Game.GameData_Go goSetup (Array.push actionWithTime actions))
                                                            channel.games
                                                }
                                                guild.channels
                                    }
                                    model.guilds
                          }
                        , Command.batch
                            [ Local_Game guildOrDmId localMsg2
                                |> LocalChangeResponse changeId
                                |> Lamdera.sendToFrontend clientId
                            , Broadcast.toGuildExcludingOne
                                clientId
                                guildId
                                (Server_Game session.userId guildOrDmId localMsg2 |> ServerChange)
                                model
                            ]
                        )

                    else
                        ( model, BackendExtra.invalidChangeResponse changeId clientId )

                _ ->
                    ( model, BackendExtra.invalidChangeResponse changeId clientId )


handleDmGoGame :
    Time.Posix
    -> UserSession
    -> ClientId
    -> ChangeId
    -> Id UserId
    -> Id ChannelMessageId
    -> Go.LocalChange
    -> DmChannelId
    -> DmChannel
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleDmGoGame time session clientId changeId otherUserId matchId goChange dmChannelId dmChannel model =
    case goChange of
        Go.StartMatch createdAt setup ->
            let
                ( messageId, dmChannel2 ) =
                    LocalState.createChannelMessageBackend
                        (GameStarted
                            { startedAt = createdAt
                            , startedBy = session.userId
                            , reactions = SeqDict.empty
                            , gameType = GameType_Go
                            , timestampDrawings = Drawing.emptyDrawing
                            , cardDrawings = Drawing.emptyDrawing
                            }
                        )
                        dmChannel

                localMsg2 : Game.LocalChange
                localMsg2 =
                    Game.LocalChange_Go messageId (Go.StartMatch time setup)
            in
            ( { model
                | dmChannels =
                    SeqDict.insert
                        dmChannelId
                        { dmChannel2
                            | games =
                                SeqDict.insert
                                    messageId
                                    (Game.GameData_Go setup Array.empty)
                                    dmChannel2.games
                        }
                        model.dmChannels
              }
            , Command.batch
                [ Local_Game (GuildOrDmId_Dm otherUserId) localMsg2
                    |> LocalChangeResponse changeId
                    |> Lamdera.sendToFrontend clientId
                , Broadcast.toDmChannelExcludingOne
                    clientId
                    session.userId
                    otherUserId
                    (\otherUserId2 ->
                        Server_Game session.userId (GuildOrDmId_Dm otherUserId2) localMsg2
                    )
                    model
                ]
            )

        Go.Action actionWithTime ->
            case SeqDict.get matchId dmChannel.games of
                Just (Game.GameData_Go goSetup actions) ->
                    let
                        localMsg2 : Game.LocalChange
                        localMsg2 =
                            Game.LocalChange_Go matchId (Go.Action { actionWithTime | time = time })
                    in
                    if isValidGoAction session.userId goSetup actions actionWithTime then
                        ( { model
                            | dmChannels =
                                SeqDict.insert
                                    dmChannelId
                                    { dmChannel
                                        | games =
                                            SeqDict.insert
                                                matchId
                                                (Game.GameData_Go goSetup (Array.push actionWithTime actions))
                                                dmChannel.games
                                    }
                                    model.dmChannels
                          }
                        , Command.batch
                            [ Local_Game (GuildOrDmId_Dm otherUserId) localMsg2
                                |> LocalChangeResponse changeId
                                |> Lamdera.sendToFrontend clientId
                            , Broadcast.toDmChannelExcludingOne
                                clientId
                                session.userId
                                otherUserId
                                (\otherUserId2 ->
                                    Server_Game session.userId (GuildOrDmId_Dm otherUserId2) localMsg2
                                )
                                model
                            ]
                        )

                    else
                        ( model, BackendExtra.invalidChangeResponse changeId clientId )

                _ ->
                    ( model, BackendExtra.invalidChangeResponse changeId clientId )


handleWordSpellingGame :
    Time.Posix
    -> UserSession
    -> ClientId
    -> ChangeId
    -> GuildOrDmId
    ->
        { c
            | messages : IdArray ChannelMessageId (Message ChannelMessageId (Id UserId))
            , lastTypedAt : SeqDict (Id UserId) (Thread.LastTypedAt ChannelMessageId)
            , games : SeqDict (Id ChannelMessageId) Game.BackendGameData
        }
    ->
        ({ c
            | messages : IdArray ChannelMessageId (Message ChannelMessageId (Id UserId))
            , lastTypedAt : SeqDict (Id UserId) (Thread.LastTypedAt ChannelMessageId)
            , games : SeqDict (Id ChannelMessageId) Game.BackendGameData
         }
         -> BackendModel
         -> BackendModel
        )
    -> (Game.LocalChange -> BackendModel -> Command BackendOnly ToFrontend BackendMsg)
    -> Id ChannelMessageId
    -> WordSpellingGame.LocalChange
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleWordSpellingGame time session clientId changeId guildOrDmId channel setChannel broadcast matchId wsChange model =
    case wsChange of
        WordSpellingGame.StartMatch _ setup ->
            let
                loadEnglishWordList : Bool
                loadEnglishWordList =
                    case model.wordSpellingGameEnglish of
                        WordList_NotLoaded ->
                            setup.language == English

                        WordList_Error _ ->
                            setup.language == English

                        WordList_Loading ->
                            False

                        WordList_Loaded _ ->
                            False

                loadSwedishWordList : Bool
                loadSwedishWordList =
                    case model.wordSpellingGameSwedish of
                        WordList_NotLoaded ->
                            setup.language == Swedish

                        WordList_Error _ ->
                            setup.language == Swedish

                        WordList_Loading ->
                            False

                        WordList_Loaded _ ->
                            False

                ( messageId, channel2 ) =
                    LocalState.createChannelMessageBackend
                        (GameStarted
                            { startedAt = time
                            , startedBy = session.userId
                            , reactions = SeqDict.empty
                            , gameType = GameType_WordSpellingGame
                            , timestampDrawings = Drawing.emptyDrawing
                            , cardDrawings = Drawing.emptyDrawing
                            }
                        )
                        channel

                localMsg2 : Game.LocalChange
                localMsg2 =
                    Game.LocalChange_WordSpellingGame messageId (WordSpellingGame.StartMatch time setup)
            in
            ( setChannel
                { channel2
                    | games =
                        SeqDict.insert
                            messageId
                            (Game.GameData_WordSpellingGame
                                setup
                                Array.empty
                                (WordSpellingGame.initShared setup)
                            )
                            channel2.games
                }
                { model
                    | wordSpellingGameEnglish =
                        if loadEnglishWordList then
                            WordList_Loading

                        else
                            model.wordSpellingGameEnglish
                    , wordSpellingGameSwedish =
                        if loadSwedishWordList then
                            WordList_Loading

                        else
                            model.wordSpellingGameSwedish
                }
            , Command.batch
                [ Local_Game guildOrDmId localMsg2
                    |> LocalChangeResponse changeId
                    |> Lamdera.sendToFrontend clientId
                , broadcast localMsg2 model
                , if loadEnglishWordList then
                    Http.get
                        { url = "/NWL2023.txt"
                        , expect = Http.expectString GotEnglishWordList
                        }

                  else
                    Command.none
                , if loadSwedishWordList then
                    Http.get
                        { url = "/swedish-word-list.txt"
                        , expect = Http.expectString GotSwedishWordList
                        }

                  else
                    Command.none
                ]
            )

        WordSpellingGame.Action action ->
            case ( action.userId == session.userId, SeqDict.get matchId channel.games ) of
                ( True, Just (Game.GameData_WordSpellingGame setup actions shared) ) ->
                    let
                        action2 =
                            { action
                                | time = time
                                , change =
                                    case action.change of
                                        WordSpellingGame.PlaceWord placed _ ->
                                            let
                                                result =
                                                    case setup.language of
                                                        English ->
                                                            case model.wordSpellingGameEnglish of
                                                                WordList_Loaded words ->
                                                                    WordSpellingGame.validatePlacement
                                                                        words
                                                                        setup
                                                                        shared.board
                                                                        placed

                                                                _ ->
                                                                    Err ()

                                                        Swedish ->
                                                            case model.wordSpellingGameSwedish of
                                                                WordList_Loaded words ->
                                                                    WordSpellingGame.validatePlacement
                                                                        words
                                                                        setup
                                                                        shared.board
                                                                        placed

                                                                _ ->
                                                                    Err ()
                                            in
                                            WordSpellingGame.PlaceWord
                                                placed
                                                (case result of
                                                    Ok _ ->
                                                        FilledInByBackend WordSpellingGame.IsValid

                                                    Err () ->
                                                        FilledInByBackend WordSpellingGame.IsNotValid
                                                )

                                        WordSpellingGame.ReplaceTrayOrPass ->
                                            action.change

                                        WordSpellingGame.JoinGame ->
                                            action.change
                            }

                        localMsg2 : Game.LocalChange
                        localMsg2 =
                            Game.LocalChange_WordSpellingGame
                                matchId
                                (WordSpellingGame.Action action2)
                    in
                    ( setChannel
                        { channel
                            | games =
                                SeqDict.insert
                                    matchId
                                    (Game.GameData_WordSpellingGame
                                        setup
                                        (Array.push action2 actions)
                                        (WordSpellingGame.updateAction setup action2 shared)
                                    )
                                    channel.games
                        }
                        model
                    , Command.batch
                        [ Local_Game guildOrDmId localMsg2
                            |> LocalChangeResponse changeId
                            |> Lamdera.sendToFrontend clientId
                        , broadcast localMsg2 model
                        ]
                    )

                _ ->
                    ( model, BackendExtra.invalidChangeResponse changeId clientId )


textToDiscordRichText :
    NonemptyString
    -> List (Discord.Id Discord.UserId)
    -> BackendModel
    -> Nonempty (RichText (Discord.Id Discord.UserId))
textToDiscordRichText text memberIds model =
    RichText.fromNonemptyString
        (List.foldl
            (\memberId dict ->
                case SeqDict.get memberId model.discordUsers of
                    Just member ->
                        SeqDict.insert
                            memberId
                            { name =
                                DiscordUserData.username member
                                    |> PersonName.fromStringLossy
                            }
                            dict

                    Nothing ->
                        dict
            )
            SeqDict.empty
            memberIds
        )
        text


emojiOrCustomEmojiToDiscord : OneToOne DiscordCustomEmojiIdAndName (Id CustomEmojiId) -> EmojiOrCustomEmoji -> Result () Discord.Emoji
emojiOrCustomEmojiToDiscord customEmojis emoji =
    case emoji of
        EmojiOrCustomEmoji_Emoji emoji2 ->
            Emoji.toString emoji2 |> Discord.UnicodeEmoji |> Ok

        EmojiOrCustomEmoji_CustomEmoji id ->
            case OneToOne.first id customEmojis of
                Just discordEmoji ->
                    Discord.CustomEmoji
                        { id = discordEmoji.id, name = CustomEmoji.emojiNameToString discordEmoji.name }
                        |> Ok

                Nothing ->
                    Err ()


handleVoiceChatChange :
    Time.Posix
    -> ChangeId
    -> ClientId
    -> SessionId
    -> Call.LocalChange
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleVoiceChatChange time changeId clientId sessionId voiceMsg model =
    case voiceMsg of
        Call.Local_Join _ voiceChatId _ ->
            case voiceChatId of
                Call.DmRoomId otherUserId ->
                    BackendExtra.asDmUser
                        model
                        sessionId
                        { otherUserId = otherUserId }
                        (joinDmVoiceChat sessionId clientId time changeId otherUserId model)

        Call.Local_Leave _ ->
            BackendExtra.asUser model sessionId (leaveVoice sessionId clientId time changeId model)

        Call.Local_PublishTracks offerSdp mids _ ->
            BackendExtra.asUser model sessionId (handlePublishTracks sessionId clientId changeId time offerSdp mids model)

        Call.Local_PublishConnected ->
            BackendExtra.asUser model sessionId (handlePublishConnected time sessionId clientId changeId model)

        Call.Local_PullTracks connectionId remoteSessionId trackNames _ ->
            BackendExtra.asUser model sessionId (handlePullTracks time sessionId clientId changeId connectionId remoteSessionId trackNames model)

        Call.Local_RenegotiateAnswer answerSdp _ ->
            BackendExtra.asUser model sessionId (handleRenegotiateAnswer sessionId clientId changeId answerSdp model)

        Call.Local_SetRemoteCallData remoteCallData ->
            BackendExtra.asUser model sessionId (handleSetInputEnabled sessionId clientId changeId remoteCallData model)


{-| Apply a "set audio/video input enabled" change: update the stored state for
this connection, echo the change back to the requester, and broadcast the new
state to the other members of the call so their UI can reflect it.
-}
handleSetInputEnabled :
    SessionId
    -> ClientId
    -> ChangeId
    -> RemoteCallData
    -> BackendModel
    -> UserSession
    -> BackendUser
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleSetInputEnabled sessionId clientId changeId remoteCallData model session _ =
    case SeqDict.get sessionId model.connections |> Maybe.andThen (NonemptyDict.get clientId) of
        Just connection ->
            let
                maybeRoomId : Maybe Call.CallId
                maybeRoomId =
                    case connection.call of
                        NotInCall ->
                            Nothing

                        ConnectingToCall roomId ->
                            Just roomId

                        ConnectedToCall roomId _ ->
                            Just roomId
            in
            ( { model
                | connections =
                    SeqDict.updateIfExists
                        sessionId
                        (NonemptyDict.updateIfExists
                            clientId
                            (\connection2 -> { connection2 | remoteCallData = remoteCallData })
                        )
                        model.connections
              }
            , Command.batch
                [ LocalChangeResponse changeId (Local_VoiceChatChange (Call.Local_SetRemoteCallData remoteCallData))
                    |> Lamdera.sendToFrontend clientId
                , case maybeRoomId of
                    Just (Call.DmRoomId otherUserId) ->
                        Broadcast.toDmChannelExcludingOne
                            clientId
                            session.userId
                            otherUserId
                            (\otherUserId2 ->
                                Call.Server_SetRemoteCallData
                                    { roomId = Call.DmRoomId otherUserId2
                                    , otherClientId = ( session.userId, clientId )
                                    }
                                    remoteCallData
                                    |> Server_VoiceChatChange
                            )
                            model

                    Nothing ->
                        Command.none
                ]
            )

        Nothing ->
            ( model, BackendExtra.invalidChangeResponse changeId clientId )


leaveVoice :
    SessionId
    -> ClientId
    -> Time.Posix
    -> ChangeId
    -> BackendModel
    -> UserSession
    -> BackendUser
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
leaveVoice sessionId clientId time changeId model session _ =
    let
        maybeRoomId : Maybe Call.CallId
        maybeRoomId =
            case SeqDict.get sessionId model.connections of
                Just connections ->
                    case NonemptyDict.get clientId connections of
                        Just connection ->
                            case connection.call of
                                NotInCall ->
                                    Nothing

                                ConnectingToCall roomId ->
                                    Just roomId

                                ConnectedToCall roomId _ ->
                                    Just roomId

                        Nothing ->
                            Nothing

                Nothing ->
                    Nothing
    in
    case maybeRoomId of
        Just roomId ->
            leaveVoiceHelper sessionId clientId time (Just changeId) model session roomId

        Nothing ->
            ( model, BackendExtra.invalidChangeResponse changeId clientId )


leaveVoiceHelper :
    SessionId
    -> ClientId
    -> Time.Posix
    -> Maybe ChangeId
    -> BackendModel
    -> UserSession
    -> Call.CallId
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
leaveVoiceHelper sessionId clientId time maybeChangeId model session roomId =
    ( { model
        | connections =
            SeqDict.updateIfExists
                sessionId
                (NonemptyDict.updateIfExists clientId (\connection -> { connection | call = NotInCall }))
                model.connections
        , dmChannels =
            case roomId of
                Call.DmRoomId otherUserId ->
                    let
                        dmChannelId =
                            DmChannelId.fromUserIds session.userId otherUserId
                    in
                    if voiceChatRoomHasOtherMembers dmChannelId clientId model then
                        model.dmChannels

                    else
                        SeqDict.updateIfExists dmChannelId (LocalState.markCallMessageAsEndedBackend time) model.dmChannels
      }
    , Command.batch
        [ case maybeChangeId of
            Just changeId ->
                LocalChangeResponse changeId (Local_VoiceChatChange (Call.Local_Leave time))
                    |> Lamdera.sendToFrontend clientId

            Nothing ->
                Command.none
        , case roomId of
            Call.DmRoomId otherUserId ->
                Broadcast.toDmChannelExcludingOne
                    clientId
                    session.userId
                    otherUserId
                    (\otherUserId2 ->
                        Call.Server_Left
                            time
                            { roomId = Call.DmRoomId otherUserId2
                            , otherClientId = ( session.userId, clientId )
                            }
                            |> Server_VoiceChatChange
                    )
                    model
        ]
    )


joinDmVoiceChat :
    SessionId
    -> ClientId
    -> Time.Posix
    -> ChangeId
    -> Id UserId
    -> BackendModel
    -> UserSession
    -> BackendUser
    -> BackendUser
    -> DmChannelId
    -> DmChannel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
joinDmVoiceChat sessionId clientId time changeId otherUserId model session _ _ dmChannelId dmChannel =
    case SeqDict.get sessionId model.connections of
        Just connections ->
            case NonemptyDict.get clientId connections of
                Just connection ->
                    let
                        ( model2, leaveCmd ) =
                            case connection.call of
                                NotInCall ->
                                    ( model, Command.none )

                                ConnectingToCall oldVoiceChatId ->
                                    leaveVoiceHelper sessionId clientId time Nothing model session oldVoiceChatId

                                ConnectedToCall oldVoiceChatId _ ->
                                    leaveVoiceHelper sessionId clientId time Nothing model session oldVoiceChatId

                        voiceChatId : Call.CallId
                        voiceChatId =
                            Call.DmRoomId otherUserId
                    in
                    case ( model2.cloudflareRealtimeApiToken, model2.cloudflareRealtimeAppId ) of
                        ( Just _, Just _ ) ->
                            let
                                existingPeers : List Call.ExistingPeer
                                existingPeers =
                                    collectExistingPeers voiceChatId session.userId clientId model2

                                model3 : BackendModel
                                model3 =
                                    { model2
                                        | connections =
                                            SeqDict.update
                                                sessionId
                                                (Maybe.map
                                                    (NonemptyDict.insert
                                                        clientId
                                                        { connection | call = ConnectingToCall voiceChatId }
                                                    )
                                                )
                                                model2.connections
                                        , dmChannels =
                                            -- Only the person who starts the call adds a "started a call"
                                            -- message. Anyone joining an already ongoing call doesn't.
                                            if isAnyoneElseInCall voiceChatId session.userId clientId model2 then
                                                model2.dmChannels

                                            else
                                                SeqDict.insert
                                                    dmChannelId
                                                    (LocalState.createChannelMessageBackend
                                                        (CallStarted
                                                            { startedAt = time
                                                            , endedAt = Nothing
                                                            , startedBy = session.userId
                                                            , reactions = SeqDict.empty
                                                            , timestampDrawings = Drawing.emptyDrawing
                                                            , cardDrawings = Drawing.emptyDrawing
                                                            }
                                                        )
                                                        dmChannel
                                                        |> Tuple.second
                                                    )
                                                    model2.dmChannels
                                    }
                            in
                            ( model3
                            , Command.batch
                                [ FilledInByBackend (Ok existingPeers)
                                    |> Call.Local_Join time voiceChatId
                                    |> Local_VoiceChatChange
                                    |> LocalChangeResponse changeId
                                    |> Lamdera.sendToFrontend clientId
                                , Broadcast.toDmChannelExcludingOne
                                    clientId
                                    session.userId
                                    otherUserId
                                    (\otherUserId2 ->
                                        Call.Server_Joining
                                            time
                                            { roomId = Call.DmRoomId otherUserId2
                                            , otherClientId = ( otherUserId2, clientId )
                                            }
                                            |> Server_VoiceChatChange
                                    )
                                    model3
                                , leaveCmd
                                ]
                            )

                        _ ->
                            ( model2
                            , Command.batch
                                [ FilledInByBackend (Err ())
                                    |> Call.Local_Join time voiceChatId
                                    |> Local_VoiceChatChange
                                    |> LocalChangeResponse changeId
                                    |> Lamdera.sendToFrontend clientId
                                , leaveCmd
                                ]
                            )

                Nothing ->
                    ( model, BackendExtra.invalidChangeResponse changeId clientId )

        Nothing ->
            ( model, BackendExtra.invalidChangeResponse changeId clientId )


collectExistingPeers : Call.CallId -> Id UserId -> ClientId -> BackendModel -> List Call.ExistingPeer
collectExistingPeers roomId currentUserId currentClientId model =
    SeqDict.foldl
        (\sessionId2 connections acc ->
            case SeqDict.get sessionId2 model.sessions of
                Just session ->
                    NonemptyDict.toList connections
                        |> List.filterMap
                            (\( clientId2, connection ) ->
                                case connection.call of
                                    -- Only list peers whose RTCPeerConnection has
                                    -- connected to Cloudflare; their tracks aren't
                                    -- pullable before that.
                                    ConnectedToCall otherRoomId sfu ->
                                        if
                                            isPeerInSameCall roomId currentUserId session.userId otherRoomId
                                                && (clientId2 /= currentClientId)
                                                && sfu.pullTracksReady
                                        then
                                            Just
                                                { connectionId =
                                                    { roomId = roomId
                                                    , otherClientId = ( session.userId, clientId2 )
                                                    }
                                                , sessionId = sfu.sessionId
                                                , trackNames = sfu.trackNames
                                                }

                                        else
                                            Nothing

                                    ConnectingToCall _ ->
                                        Nothing

                                    NotInCall ->
                                        Nothing
                            )
                        |> (\l -> l ++ acc)

                Nothing ->
                    acc
        )
        []
        model.connections


{-| Is anyone other than the joining client already in (or connecting to) this
call? Used to decide whether a join is starting a brand new call (and so should
add a "started a call" message) or just joining an ongoing one.
-}
isAnyoneElseInCall : Call.CallId -> Id UserId -> ClientId -> BackendModel -> Bool
isAnyoneElseInCall roomId currentUserId currentClientId model =
    SeqDict.toList model.connections
        |> List.any
            (\( sessionId2, connections ) ->
                case SeqDict.get sessionId2 model.sessions of
                    Just session ->
                        NonemptyDict.toList connections
                            |> List.any
                                (\( clientId2, connection ) ->
                                    (clientId2 /= currentClientId)
                                        && (case connection.call of
                                                ConnectedToCall otherRoomId _ ->
                                                    isPeerInSameCall roomId currentUserId session.userId otherRoomId

                                                ConnectingToCall otherRoomId ->
                                                    isPeerInSameCall roomId currentUserId session.userId otherRoomId

                                                NotInCall ->
                                                    False
                                           )
                                )

                    Nothing ->
                        False
            )


{-| Given the joining user's room and the peer's call state, decide whether
the two are in the same logical call. For DMs, each side encodes the OTHER
user in `DmRoomId`, so equality won't work directly — we compare DM channel
ids instead.
-}
isPeerInSameCall : Call.CallId -> Id UserId -> Id UserId -> Call.CallId -> Bool
isPeerInSameCall myRoomId myUserId peerUserId peerCall =
    let
        (Call.DmRoomId myOther) =
            myRoomId

        (Call.DmRoomId peerOther) =
            peerCall
    in
    DmChannelId.fromUserIds myUserId myOther == DmChannelId.fromUserIds peerUserId peerOther


handlePublishTracks :
    SessionId
    -> ClientId
    -> ChangeId
    -> Time.Posix
    -> Cloudflare.Sdp
    -> List String
    -> BackendModel
    -> UserSession
    -> BackendUser
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handlePublishTracks sessionId clientId changeId time offerSdp transceiverMids model _ _ =
    case ( model.cloudflareRealtimeApiToken, model.cloudflareRealtimeAppId ) of
        ( Just apiToken, Just cloudflareAppId ) ->
            case clientIdCurrentCallId sessionId clientId model of
                ConnectingToCall roomId ->
                    ( model
                    , Cloudflare.createSession cloudflareAppId apiToken
                        |> Task.attempt (GotCloudflareSessionCreated sessionId clientId changeId time roomId offerSdp transceiverMids)
                    )

                ConnectedToCall _ _ ->
                    ( model, BackendExtra.invalidChangeResponse changeId clientId )

                NotInCall ->
                    ( model, BackendExtra.invalidChangeResponse changeId clientId )

        _ ->
            ( model, BackendExtra.invalidChangeResponse changeId clientId )


clientIdCurrentCallId : SessionId -> ClientId -> BackendModel -> CallStatus
clientIdCurrentCallId sessionId clientId model =
    case SeqDict.get sessionId model.connections of
        Just connections2 ->
            case NonemptyDict.get clientId connections2 of
                Just connection ->
                    connection.call

                Nothing ->
                    NotInCall

        Nothing ->
            NotInCall


handleGotCloudflareSession :
    SessionId
    -> ClientId
    -> ChangeId
    -> Time.Posix
    -> Call.CallId
    -> Cloudflare.RealtimeSessionId
    -> Result Http.Error Cloudflare.PushTracksResult
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleGotCloudflareSession sessionId clientId changeId time _ cfSessionId result model =
    case result of
        Err error ->
            BackendExtra.addLogWithCmd
                time
                (Log.FailedCloudflarePushLocalTracks error)
                model
                (Call.Local_Leave time
                    |> Local_VoiceChatChange
                    |> LocalChangeResponse changeId
                    |> Lamdera.sendToFrontend clientId
                )

        Ok push ->
            case clientIdCurrentCallId sessionId clientId model of
                ConnectedToCall _ _ ->
                    ( model, Command.none )

                ConnectingToCall callId ->
                    let
                        model2 : BackendModel
                        model2 =
                            { model
                                | connections =
                                    SeqDict.update
                                        sessionId
                                        (Maybe.map
                                            (NonemptyDict.updateIfExists
                                                clientId
                                                (\connection ->
                                                    { connection
                                                        | call =
                                                            ConnectedToCall
                                                                callId
                                                                { sessionId = cfSessionId
                                                                , trackNames = push.trackNames

                                                                -- Not connected to Cloudflare yet. We must NOT
                                                                -- advertise these tracks for pulling until the
                                                                -- publisher's RTCPeerConnection actually connects
                                                                -- and starts sending packets, otherwise pulls fail
                                                                -- with not_found_track_error. The publisher signals
                                                                -- readiness via Local_PublishConnected.
                                                                , pullTracksReady = False
                                                                }
                                                    }
                                                )
                                            )
                                        )
                                        model.connections
                            }
                    in
                    ( model2
                    , Call.Local_PublishTracks push.answerSdp
                        []
                        (FilledInByBackend
                            { answerSdp = push.answerSdp
                            , sessionId = cfSessionId
                            , trackNames = push.trackNames
                            }
                        )
                        |> Local_VoiceChatChange
                        |> LocalChangeResponse changeId
                        |> Lamdera.sendToFrontend clientId
                    )

                NotInCall ->
                    ( model, Command.none )


{-| The publisher's RTCPeerConnection has connected to Cloudflare and is now
sending media. Only now is it safe for other participants to pull this peer's
tracks (and for this peer to pull others). We mark the connection ready and
exchange Server\_Joined messages in both directions with every other already-
connected peer in the same call.
-}
handlePublishConnected :
    Time.Posix
    -> SessionId
    -> ClientId
    -> ChangeId
    -> BackendModel
    -> UserSession
    -> BackendUser
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handlePublishConnected time sessionId clientId changeId model session _ =
    case clientIdCurrentCallId sessionId clientId model of
        ConnectedToCall roomId sfu ->
            let
                userId : Id UserId
                userId =
                    session.userId

                model2 : BackendModel
                model2 =
                    { model
                        | connections =
                            SeqDict.updateIfExists
                                sessionId
                                (NonemptyDict.updateIfExists
                                    clientId
                                    (\connection ->
                                        { connection | call = ConnectedToCall roomId { sfu | pullTracksReady = True } }
                                    )
                                )
                                model.connections
                    }

                -- Every other connected peer already in this call.
                peers :
                    List
                        { peerUserId : Id UserId
                        , peerClientId : ClientId
                        , realtimeSessionId : Cloudflare.RealtimeSessionId
                        , trackNames : List Cloudflare.TrackName
                        }
                peers =
                    List.concatMap
                        (\( sid, conns ) ->
                            case SeqDict.get sid model2.sessions of
                                Just s ->
                                    List.filterMap
                                        (\( cId, c ) ->
                                            case c.call of
                                                ConnectedToCall callId peerSfu ->
                                                    if
                                                        (cId /= clientId)
                                                            && isPeerInSameCall roomId userId s.userId callId
                                                            && peerSfu.pullTracksReady
                                                    then
                                                        Just
                                                            { peerUserId = s.userId
                                                            , peerClientId = cId
                                                            , realtimeSessionId = peerSfu.sessionId
                                                            , trackNames = peerSfu.trackNames
                                                            }

                                                    else
                                                        Nothing

                                                ConnectingToCall _ ->
                                                    Nothing

                                                NotInCall ->
                                                    Nothing
                                        )
                                        (NonemptyDict.toList conns)

                                Nothing ->
                                    []
                        )
                        (SeqDict.toList model2.connections)

                cmds : List (Command BackendOnly ToFrontend BackendMsg)
                cmds =
                    List.concatMap
                        (\peer ->
                            [ -- Tell the peer to pull this newly-connected publisher.
                              Call.Server_Joined
                                time
                                { roomId = peerRoomId roomId peer.peerUserId userId
                                , otherClientId = ( userId, clientId )
                                }
                                sfu.sessionId
                                sfu.trackNames
                                |> Server_VoiceChatChange
                                |> ServerChange
                                |> ChangeBroadcast
                                |> Lamdera.sendToFrontend peer.peerClientId
                            , -- Tell this publisher to pull the (already connected) peer.
                              Call.Server_Joined
                                time
                                { roomId = roomId
                                , otherClientId = ( peer.peerUserId, peer.peerClientId )
                                }
                                peer.realtimeSessionId
                                peer.trackNames
                                |> Server_VoiceChatChange
                                |> ServerChange
                                |> ChangeBroadcast
                                |> Lamdera.sendToFrontend clientId
                            ]
                        )
                        peers
            in
            ( model2
            , Lamdera.sendToFrontend clientId (LocalChangeResponse changeId (Local_VoiceChatChange Call.Local_PublishConnected))
                :: cmds
                |> Command.batch
            )

        _ ->
            ( model, BackendExtra.invalidChangeResponse changeId clientId )


peerRoomId : Call.CallId -> Id UserId -> Id UserId -> Call.CallId
peerRoomId roomId peerUserId joiningUserId =
    case roomId of
        Call.DmRoomId joinerOther ->
            if peerUserId == joiningUserId then
                -- Peer is another tab of the joiner: same DM other as joiner.
                Call.DmRoomId joinerOther

            else
                -- Peer is the other DM party: from their view, the joiner is the other.
                Call.DmRoomId joiningUserId


handlePullTracks :
    Time.Posix
    -> SessionId
    -> ClientId
    -> ChangeId
    -> Call.ConnectionId
    -> Cloudflare.RealtimeSessionId
    -> List Cloudflare.TrackName
    -> BackendModel
    -> UserSession
    -> BackendUser
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handlePullTracks time sessionId clientId changeId connectionId remoteSessionId trackNames model session _ =
    case
        ( model.cloudflareRealtimeApiToken
        , model.cloudflareRealtimeAppId
        , SeqDict.get sessionId model.connections |> Maybe.andThen (NonemptyDict.get clientId)
        )
    of
        ( Just apiToken, Just appId, Just connection ) ->
            case connection.call of
                ConnectedToCall roomId sfu ->
                    if
                        collectExistingPeers roomId session.userId clientId model
                            |> List.any (\peer -> peer.sessionId == remoteSessionId)
                    then
                        ( model
                        , Cloudflare.pullRemoteTracks
                            appId
                            apiToken
                            sfu.sessionId
                            { remoteSessionId = remoteSessionId, trackNames = trackNames }
                            |> Task.attempt (GotCloudflarePullOffer time clientId changeId connectionId remoteSessionId trackNames)
                        )

                    else
                        ( model, BackendExtra.invalidChangeResponse changeId clientId )

                ConnectingToCall _ ->
                    ( model, BackendExtra.invalidChangeResponse changeId clientId )

                NotInCall ->
                    ( model, BackendExtra.invalidChangeResponse changeId clientId )

        _ ->
            ( model, BackendExtra.invalidChangeResponse changeId clientId )


handleRenegotiateAnswer :
    SessionId
    -> ClientId
    -> ChangeId
    -> Cloudflare.Sdp
    -> BackendModel
    -> UserSession
    -> BackendUser
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleRenegotiateAnswer sessionId clientId changeId answerSdp model _ _ =
    case
        ( model.cloudflareRealtimeApiToken
        , model.cloudflareRealtimeAppId
        , SeqDict.get sessionId model.connections |> Maybe.andThen (NonemptyDict.get clientId)
        )
    of
        ( Just apiToken, Just appId, Just connection ) ->
            case connection.call of
                ConnectedToCall _ sfu ->
                    ( model
                    , Cloudflare.renegotiate appId apiToken sfu.sessionId { answerSdp = answerSdp }
                        |> Task.attempt (GotCloudflareRenegotiateAck clientId changeId answerSdp)
                    )

                ConnectingToCall _ ->
                    ( model, BackendExtra.invalidChangeResponse changeId clientId )

                NotInCall ->
                    ( model, BackendExtra.invalidChangeResponse changeId clientId )

        _ ->
            ( model, BackendExtra.invalidChangeResponse changeId clientId )


voiceChatRoomHasOtherMembers : DmChannelId -> ClientId -> BackendModel -> Bool
voiceChatRoomHasOtherMembers dmChannelId clientId model =
    SeqDict.filter
        (\sessionId2 connections ->
            case SeqDict.get sessionId2 model.sessions of
                Just otherSession ->
                    NonemptyDict.any
                        (\otherClientId connection ->
                            case connection.call of
                                ConnectedToCall (Call.DmRoomId otherUserId2) _ ->
                                    (DmChannelId.fromUserIds otherUserId2 otherSession.userId == dmChannelId)
                                        && (clientId /= otherClientId)

                                ConnectingToCall (Call.DmRoomId otherUserId2) ->
                                    (DmChannelId.fromUserIds otherUserId2 otherSession.userId == dmChannelId)
                                        && (clientId /= otherClientId)

                                NotInCall ->
                                    False
                        )
                        connections

                Nothing ->
                    False
        )
        model.connections
        |> SeqDict.isEmpty
        |> not


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
    { a | messages : IdArray messageId (Message messageId userId) }
    -> SeqDict (Id messageId) (Message messageId userId)
loadMessagesHelper channel =
    let
        messageCount : Int
        messageCount =
            IdArray.length channel.messages

        indexStart : Int
        indexStart =
            max (messageCount - VisibleMessages.pageSize) 0
    in
    IdArray.slice (Id.fromInt indexStart) (Id.fromInt messageCount) channel.messages
        |> IdArray.toList
        |> List.indexedMap
            (\index message ->
                ( index + indexStart |> Id.fromInt, message )
            )
        |> SeqDict.fromList


handleMessagesRequest :
    Id messageId
    -> { b | messages : IdArray messageId (Message messageId userId) }
    -> ToBeFilledInByBackend (SeqDict (Id messageId) (Message messageId userId))
handleMessagesRequest oldestVisibleMessage channel =
    let
        oldestVisibleMessage2 =
            oldestVisibleMessage

        nextOldestVisible =
            max (Id.toInt oldestVisibleMessage2 - VisibleMessages.pageSize) 0
    in
    IdArray.slice (Id.fromInt nextOldestVisible) oldestVisibleMessage2 channel.messages
        |> IdArray.toList
        |> List.indexedMap (\index message -> ( Id.fromInt (index + nextOldestVisible), message ))
        |> SeqDict.fromList
        |> FilledInByBackend


sendEditMessage :
    ClientId
    -> ChangeId
    -> Time.Posix
    -> NonemptyString
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
            let
                richText : Nonempty (RichText (Id UserId))
                richText =
                    RichText.fromNonemptyString
                        (List.foldl
                            (\memberId dict ->
                                case NonemptyDict.get memberId model2.users of
                                    Just member ->
                                        SeqDict.insert memberId member dict

                                    Nothing ->
                                        dict
                            )
                            SeqDict.empty
                            (MembersAndOwner.membersAndOwner guild.membersAndOwner)
                        )
                        newContent
            in
            case
                LocalState.editMessageHelper
                    time
                    userId
                    richText
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
                                richText
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

        TwoFactorAuthentication.DisableTwoFactorAuthenticationRequest code ->
            case SeqDict.get session.userId model.twoFactorAuthentication of
                Just data ->
                    if TwoFactorAuthentication.isValidCode time code data.secret then
                        ( { model
                            | twoFactorAuthentication =
                                SeqDict.remove session.userId model.twoFactorAuthentication
                          }
                        , TwoFactorAuthentication.DisableTwoFactorAuthenticationResponse code True
                            |> TwoFactorAuthenticationToFrontend
                            |> Lamdera.sendToFrontend clientId
                        )

                    else
                        ( model
                        , TwoFactorAuthentication.DisableTwoFactorAuthenticationResponse code False
                            |> TwoFactorAuthenticationToFrontend
                            |> Lamdera.sendToFrontend clientId
                        )

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

        Pages.Admin.SetDiscordLinkingEnabled isEnabled ->
            let
                model2 =
                    { model | discordLinkingEnabled = isEnabled }
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

        Pages.Admin.SetCloudflareRealtimeApiToken cloudflareRealtimeApiToken ->
            ( { model | cloudflareRealtimeApiToken = cloudflareRealtimeApiToken }
            , LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
            )

        Pages.Admin.SetCloudflareRealtimeAppId maybeAppId ->
            ( { model | cloudflareRealtimeAppId = maybeAppId }
            , LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
            )

        Pages.Admin.SetCloudflareAccountId maybeAccountId ->
            ( { model | cloudflareAccountId = maybeAccountId }
            , LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
            )

        Pages.Admin.SetCloudflareAnalyticsApiToken maybeToken ->
            ( { model | cloudflareAnalyticsApiToken = maybeToken }
            , LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
            )

        Pages.Admin.SetPostmarkKey postmarkKey ->
            ( { model | postmarkApiKey = postmarkKey }
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

        Pages.Admin.RestoreGuild guildId ->
            case ( SeqDict.get guildId model.deletedGuilds, SeqDict.get guildId model.guilds ) of
                ( Just deletedGuild, Nothing ) ->
                    let
                        model2 : BackendModel
                        model2 =
                            { model
                                | guilds = SeqDict.insert guildId deletedGuild.guild model.guilds
                                , deletedGuilds = SeqDict.remove guildId model.deletedGuilds
                            }
                    in
                    ( model2
                    , Command.batch
                        [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                        , Broadcast.toOtherAdmins clientId model2 (LocalChange userId localMsg)
                        ]
                    )

                _ ->
                    ( model, BackendExtra.invalidChangeResponse changeId clientId )

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
                        , DiscordSync.getManyMessages
                            model.serverSecret
                            auth
                            { channelId = channelId, limit = DiscordSync.reloadChannelMaxMessages }
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
                            model.serverSecret
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
                            disconnectClient time sessionId disconnectClientId model
                    in
                    ( model2
                    , Command.batch [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId, cmds ]
                    )

                Nothing ->
                    ( model, BackendExtra.invalidChangeResponse changeId clientId )

        Pages.Admin.DeleteSession sessionIdHash ->
            case Broadcast.getSessionFromSessionIdHash sessionIdHash model of
                Just ( sessionId, _ ) ->
                    ( { model | sessions = SeqDict.remove sessionId model.sessions }
                    , LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                    )

                Nothing ->
                    ( model, BackendExtra.invalidChangeResponse changeId clientId )

        Pages.Admin.RegenerateServerSecret _ ->
            ( model
            , Http.task
                { method = "POST"
                , url = FileStatus.domain ++ "/file/internal/regenerate-server-secret"
                , body = Http.emptyBody
                , headers = [ FileStatus.secretKeyHeader model.serverSecret ]
                , resolver =
                    Http.stringResolver
                        (\result ->
                            case result of
                                Http.BadStatus_ metadata body ->
                                    Http.BadBody
                                        ("Status code: " ++ String.fromInt metadata.statusCode ++ ", body: " ++ body)
                                        |> Err

                                Http.GoodStatus_ _ text ->
                                    Ok (SecretId.fromString text)

                                Http.BadUrl_ string ->
                                    Err (Http.BadUrl string)

                                Http.Timeout_ ->
                                    Err Http.Timeout

                                Http.NetworkError_ ->
                                    Err Http.NetworkError
                        )
                , timeout = Just Duration.minute
                }
                |> Task.attempt (RegeneratedServerSecret time changeId clientId)
            )

        Pages.Admin.EndAllCalls ->
            ( Pages.Admin.endAllCalls model
            , LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
            )


updateFromFrontendAdmin :
    ClientId
    -> Pages.Admin.ToBackend
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
updateFromFrontendAdmin clientId toBackend model =
    case toBackend of
        Pages.Admin.LoadCloudflareEgressRequest ->
            case ( model.cloudflareAccountId, model.cloudflareAnalyticsApiToken ) of
                ( Just accountId, Just analyticsToken ) ->
                    ( model
                    , Time.now
                        |> Task.andThen
                            (\time ->
                                let
                                    today : Date
                                    today =
                                        Date.fromPosix Time.utc time
                                in
                                Cloudflare.monthlyEgressBytes
                                    { accountId = accountId
                                    , analyticsToken = analyticsToken
                                    , startDate = Date.floor Date.Month today |> Date.toIsoString
                                    , endDate = Date.toIsoString today
                                    }
                            )
                        |> Task.attempt (GotCloudflareEgressForAdmin clientId)
                    )

                _ ->
                    ( model
                    , Http.BadBody "Cloudflare account id and analytics token must be configured first"
                        |> Err
                        |> Pages.Admin.CloudflareEgressResponse
                        |> AdminToFrontend
                        |> Lamdera.sendToFrontend clientId
                    )

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
                        ExportSubset _ ->
                            []

                        ExportAll ->
                            list

                remainingDmChannels : List ( DmChannelId, DmChannel )
                remainingDmChannels =
                    case isPartial of
                        ExportSubset selection ->
                            SeqDict.toList model.dmChannels
                                |> List.filter (\( channelId, _ ) -> SeqSet.member channelId selection.dmChannels)

                        ExportAll ->
                            SeqDict.toList model.dmChannels

                remainingDiscordDmChannels : List ( Discord.Id Discord.PrivateChannelId, DiscordDmChannel )
                remainingDiscordDmChannels =
                    case isPartial of
                        ExportSubset selection ->
                            SeqDict.toList model.discordDmChannels
                                |> List.filter (\( channelId, _ ) -> SeqSet.member channelId selection.discordDmChannels)

                        ExportAll ->
                            SeqDict.toList model.discordDmChannels
            in
            ( { model
                | exportState =
                    { progress =
                        { baseModel = Bytes.Encode.encode (WireHelper.encodeBackendModel baseModel)
                        , remainingGuilds = SeqDict.toList model.guilds |> partialList
                        , encodedGuilds = []
                        , remainingDmChannels = remainingDmChannels
                        , encodedDmChannels = []
                        , remainingDiscordGuilds = SeqDict.toList model.discordGuilds |> partialList
                        , encodedDiscordGuilds = []
                        , remainingDiscordDmChannels = remainingDiscordDmChannels
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
