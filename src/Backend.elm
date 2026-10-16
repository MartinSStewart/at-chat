module Backend exposing
    ( adminEmail
    , adminUser
    , app
    , app_
    , handleExportBackendStep
    , startExport
    )

import AiChat
import Array exposing (Array)
import BackendExtra
import Broadcast
import Bytes exposing (Bytes)
import Bytes.Decode
import Bytes.Encode
import Call exposing (RemoteCallData)
import ChannelDescription
import ChannelExport
import ChannelImport
import ChannelName exposing (ChannelName)
import CustomEmoji exposing (CustomEmojiData)
import DeleteUserAndFiles
import Discord exposing (OptionalData(..))
import DiscordAttachmentId exposing (DiscordAttachmentId)
import DiscordSync
import DiscordUserData exposing (DiscordBasicUserData, DiscordFullUserData, DiscordUserData(..), DiscordUserLoadingData(..))
import DmChannel exposing (BackendDmChannel, DiscordDmChannel)
import DmChannelId exposing (DmChannelId, GuildOrFullDmId(..))
import Drawing
import Duration exposing (Duration)
import Effect.Command as Command exposing (BackendOnly, Command)
import Effect.Http as Http
import Effect.Lamdera as Lamdera exposing (ClientId, SessionId)
import Effect.Subscription as Subscription exposing (Subscription)
import Effect.Task as Task exposing (Task)
import Effect.Time as Time
import Effect.Websocket as Websocket
import EmailAddress exposing (EmailAddress)
import Emoji exposing (EmojiOrCustomEmoji(..))
import Env
import FileName
import FileStatus exposing (FileData, FileHash, FileId)
import Game
import Go
import GuildName
import Id exposing (AnyGuildOrDmId(..), ChannelId, ChannelMessageId, CustomEmojiId, DiscordGuildOrDmId(..), ExportChannelId(..), GamePublicId, GuildId, GuildOrDmId(..), Id, InviteLinkId, SlackGuildOrDmId(..), StickerId, ThreadMessageId, ThreadRoute(..), ThreadRouteWithMaybeMessage(..), ThreadRouteWithMessage(..), UserId, Viewing_ChannelId, Viewing_DmId)
import IdArray exposing (IdArray)
import ImageEditor
import Lamdera as LamderaCore
import LinkedAndOtherDiscordUsers
import List.Extra
import List.Nonempty exposing (Nonempty(..))
import Local exposing (ChangeId)
import LocalState exposing (BackendChannel, BackendGuild, CallStatus(..), ChannelStatus(..), ConnectionData, DiscordBackendChannel, DiscordBackendGuild, DiscordChannelReload, JoinGuildError(..), LastRequest(..), LoadingDiscordChannel(..), LoadingDiscordChannelStep(..), PrivateVapidKey(..), WebsocketClosedEvent(..))
import Log exposing (Log)
import LoginForm
import MembersAndOwner
import Message exposing (ChangeAttachments(..), GameType(..), Message(..), UserTextMessageData)
import MuteSettings
import MyUi
import NonemptyDict exposing (NonemptyDict)
import NonemptySet
import OneToOne exposing (OneToOne)
import Pages.Admin exposing (ExportSubset(..))
import Pagination
import PersonName exposing (PersonName)
import Ports exposing (RegisterPushSubscription(..))
import Postmark
import Quantity
import Random
import RateLimit
import RichText exposing (DiscordCustomEmojiIdAndName, RichText)
import Route exposing (ChannelsVisibleOnMobile(..), Route)
import SecretId exposing (SecretId, ServerSecret)
import SeqDict exposing (SeqDict)
import SeqDictHelper
import SeqSet exposing (SeqSet)
import Set exposing (Set)
import SetViewing exposing (SetViewing(..))
import Sha256
import SheepGame
import Slack exposing (SlackCookie, SlackToken)
import SlackEmoji
import SlackSync
import Sticker exposing (StickerData, StickerUrl(..))
import String.Nonempty exposing (NonemptyString)
import TOTP.Key
import TextEditor
import Thread exposing (DiscordBackendThread, SlackBackendThread)
import TwoFactorAuthentication
import Types exposing (BackendModel, BackendMsg(..), BackupTransfer(..), DiscordAttachmentData, ExportStateProgress, ExportStep(..), ImportChannelError(..), LinkDiscordFailure(..), LinkSlackResult(..), LinkSlackWorkspaceError(..), LoadedSlackWorkspace, LocalChange(..), LocalMsg(..), LoginResult(..), LoginTokenData(..), LoginType(..), MessageFromGuildOrDm(..), ServerChange(..), SlackBackendChannel, SlackFileData, SlackLinkedUser, SlackUserData(..), ToBackend(..), ToFrontend(..), UploadBackupState)
import Unsafe
import User exposing (BackendUser, BackendUserStatus(..))
import UserSession exposing (DiscordFrontendUser, PushSubscription(..), SlackFrontendUser, ToBeFilledInByBackend(..), UserSession, Viewing)
import VisibleMessages exposing (PageRequest(..))
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
    User.init (Time.millisToPosix 0) PersonName.widestName (UserHasEmail adminEmail) True


adminEmail : EmailAddress
adminEmail =
    Unsafe.emailAddress "a@a.aa"


{-| Sha256 hash of the password that logs you in as the admin user when the Postmark API key is
missing. This exists so that a backup can be uploaded again after the BackendModel has been reset
(at which point no one can receive a login email).
-}
recoveryPasswordHash : String
recoveryPasswordHash =
    "0e6a28a18a696783861f4eda27b09caa96718799deb31d701321cb3a9530d913"


{-| Once an admin sets a Postmark API key, login emails work again and the recovery password is no
longer accepted.
-}
loginType : BackendModel -> LoginType
loginType model =
    if model.postmarkApiKey == Postmark.apiKey "" then
        LoginWithRecoveryPassword

    else
        LoginWithEmail


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
            , bannedUsers = SeqSet.empty
            , invites = SeqDict.empty
            , lastTypedAt = SeqDict.empty
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
      , slackWorkspaces = SeqDict.empty
      , slackUsers = SeqDict.empty
      , slackFiles = SeqDict.empty
      , slackDmChannels = SeqDict.empty
      , files = SeqDict.empty
      , orphanedFilesLastHour = SeqSet.empty
      , orphanedDiscordGuildsLastHour = SeqSet.empty
      , orphanedSlackWorkspacesLastHour = SeqSet.empty
      , orphanedSlackDmChannelsLastHour = SeqSet.empty
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
      , openRouterKey = Nothing
      , textEditor = TextEditor.initLocalState
      , discordUsers = SeqDict.empty
      , pendingDiscordCreateMessages = SeqDict.empty
      , pendingDiscordCreateDmMessages = SeqDict.empty
      , discordAttachments = SeqDict.empty
      , loadingDiscordChannels = SeqDict.empty
      , signupsEnabled = True
      , discordLinkingEnabled = True
      , slackLinkingEnabled = True
      , exportState = Nothing
      , lastBackup = Nothing
      , discordLinkLimit = Nothing
      , slackLinkLimit = Nothing
      , downloadBackupState = Nothing
      , scheduledExportState = Nothing
      , lastScheduledExportTime = Nothing
      , sendMessageRateLimits = SeqDict.empty
      , sessionRateLimits = RateLimit.sessionRateLimitsInit
      , toBackendLogs = Array.empty
      , backendMsgLogs = Array.empty
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
      , pendingGatewayReconnects = SeqDict.empty
      , pendingSlackSends = SeqDict.empty
      , pendingSlackUserLookups = SeqSet.empty
      , refreshingSlackConversations = SeqSet.empty
      , pendingSlackReconnects = SeqDict.empty
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
        , List.filterMap
            (\( slackUserId, data ) ->
                case data of
                    SlackFullData linkedUser ->
                        case linkedUser.websocket of
                            Just connection ->
                                Websocket.listen connection Ok (\closed -> Err ( closed.code, closed.reason ))
                                    |> Subscription.map (SlackWebsocketMsg slackUserId)
                                    |> Just

                            Nothing ->
                                Nothing

                    SlackBasicData _ ->
                        Nothing
            )
            (SeqDict.toList model.slackUsers)
            |> Subscription.batch
        , case model.exportState of
            Just _ ->
                Time.every (Duration.milliseconds 30) ExportBackendStep

            Nothing ->
                Subscription.none
        , case model.downloadBackupState of
            Just (BackupDownload _) ->
                Time.every (Duration.milliseconds 30) (\_ -> DownloadBackupChunkStep)

            _ ->
                Subscription.none
        , case model.scheduledExportState of
            Just _ ->
                Time.every (Duration.milliseconds 30) ScheduledExportBackendStep

            Nothing ->
                Subscription.none
        , if SeqDict.isEmpty model.pendingGatewayReconnects then
            Subscription.none

          else
            Time.every DiscordSync.gatewayReconnectTickInterval (\_ -> GatewayReconnectTick)
        , if SeqDict.isEmpty model.pendingSlackReconnects then
            Subscription.none

          else
            Time.every DiscordSync.gatewayReconnectTickInterval (\_ -> SlackWebsocketReconnectTick)
        , Time.every Duration.hour HourlyUpdate
        ]


{-| Every BackendMsg is timed the same way a ToBackend is: the message is held onto while
Time.now runs, and once it's been handled a second Time.now says how long that took. The
two messages that do the timing are handled here and never passed to updateHelper, so they
can't be wrapped in a GotTimeForBackendMsg of their own and loop forever.

Only production pays for the round trip. Outside of it the logs are never shown and the
extra step would leave the end to end tests waiting a frame longer for every single thing
the backend does.

-}
update : BackendMsg -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
update msg model =
    case msg of
        GotTimeForBackendMsg startTime backendMsg ->
            let
                ( model2, cmd ) =
                    updateHelper backendMsg model
            in
            ( model2
            , Command.batch
                [ cmd
                , Task.perform
                    (\endTime ->
                        BackendMsgCompleted
                            (BackendExtra.backendMsgLog backendMsg)
                            { startTime = startTime, endTime = endTime }
                    )
                    Time.now
                ]
            )

        BackendMsgCompleted backendMsgLog { startTime, endTime } ->
            let
                count : Int
                count =
                    Array.length model.backendMsgLogs
            in
            ( { model
                | backendMsgLogs =
                    Array.push
                        { backendMsgLog = backendMsgLog, startTime = startTime, endTime = endTime }
                        (if count > 10000 then
                            Array.slice (count - 5000) count model.backendMsgLogs

                         else
                            model.backendMsgLogs
                        )
              }
            , Command.none
            )

        _ ->
            if Env.isProduction then
                ( model, Task.perform (\startTime -> GotTimeForBackendMsg startTime msg) Time.now )

            else
                updateHelper msg model


updateHelper : BackendMsg -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
updateHelper msg model =
    case msg of
        -- update handles these two and never passes them along, so reaching them here would
        -- mean a message got wrapped twice. Dropping it ends the loop instead of feeding it.
        GotTimeForBackendMsg _ _ ->
            ( model, Command.none )

        BackendMsgCompleted _ _ ->
            ( model, Command.none )

        UserConnected sessionId clientId ->
            let
                connections : SeqDict SessionId (NonemptyDict ClientId ConnectionData)
                connections =
                    SeqDictHelper.addToDict
                        sessionId
                        clientId
                        { lastRequest = NoRequestsMade
                        , call = NotInCall
                        , remoteCallData = Call.defaultRemoteCallData
                        , currentlyViewing = UserSession.Viewing_None
                        }
                        model.connections
            in
            ( { model | connections = connections }
            , Command.batch
                (Lamdera.sendToFrontend clientId (YouConnected clientId)
                    :: List.map
                        (\staleClientId -> Task.perform (UserDisconnectedWithTime sessionId staleClientId) Time.now)
                        (staleConnections sessionId connections)
                )
            )

        UserDisconnected sessionId clientId ->
            ( model, Task.perform (UserDisconnectedWithTime sessionId clientId) Time.now )

        UserDisconnectedWithTime sessionId clientId time ->
            disconnectClient time sessionId clientId model

        BackendGotTime sessionId clientId toBackend time ->
            case RateLimit.checkAndUpdateSessionRateLimit time sessionId model.sessionRateLimits of
                Err () ->
                    ( model, Command.none )

                Ok sessionRateLimits ->
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
                            , sessionRateLimits = sessionRateLimits
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
            case result of
                Ok _ ->
                    ( model, Command.none )

                Err error ->
                    BackendExtra.addLog time (Log.FailedToSendNotificationEmail error email) model

        DiscordUserWebsocketMsg discordUserId result ->
            let
                ( model2, cmd ) =
                    DiscordSync.discordUserWebsocketMsg
                        discordUserId
                        (case result of
                            Ok text ->
                                Discord.GotWebsocketData text

                            Err ( code, reason ) ->
                                Discord.WebsocketClosed
                                    { code = DiscordSync.closeEventCodeToInt code, reason = reason }
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

        SentSlackMessage time changeId clientId timezone guildOrDmId threadRoute text richText attachedFiles result ->
            let
                model1 : BackendModel
                model1 =
                    { model
                        | pendingSlackSends =
                            SeqDict.update
                                (slackPendingSendKey guildOrDmId)
                                (\maybeCount ->
                                    case maybeCount of
                                        Just count ->
                                            if count > 1 then
                                                Just (count - 1)

                                            else
                                                Nothing

                                        Nothing ->
                                            Nothing
                                )
                                model.pendingSlackSends
                    }
            in
            case result of
                Ok ( slackMessageId, slackFiles ) ->
                    let
                        author : Slack.Id Slack.UserId
                        author =
                            slackAuthor guildOrDmId

                        ( data, embedCmds ) =
                            Message.userTextMessageNoEmbeds time author richText SeqDict.empty Message.NoReply attachedFiles
                                |> Message.loadEmbeds model1.serverSecret

                        ( threadData, _ ) =
                            Message.userTextMessageNoEmbeds time author richText SeqDict.empty Message.NoReply attachedFiles
                                |> Message.loadEmbeds model1.serverSecret

                        {- So the files are recognized when the message comes back from Slack, in an
                           edit or when catching up.
                        -}
                        model1b : BackendModel
                        model1b =
                            { model1
                                | slackFiles =
                                    List.foldl
                                        (\( slackFileId, fileData ) dict ->
                                            SeqDict.insert slackFileId { fileHash = fileData.fileHash, metadata = fileData.metadata } dict
                                        )
                                        model1.slackFiles
                                        slackFiles
                            }
                    in
                    case
                        updateSlackConversation
                            guildOrDmId
                            (addToSlackConversation threadRoute slackMessageId (UserTextMessage data) (UserTextMessage threadData))
                            model1b
                    of
                        Just ( model2, threadRouteWithMessage ) ->
                            let
                                ( model3, notificationCmds ) =
                                    slackMessageAdded time guildOrDmId threadRouteWithMessage data model2
                            in
                            ( model3
                            , Command.batch
                                [ Command.batch notificationCmds
                                , Command.map identity (SlackGotMessageEmbed guildOrDmId threadRouteWithMessage) embedCmds
                                , Local_Slack_SendMessage time timezone guildOrDmId threadRoute text attachedFiles
                                    |> LocalChangeResponse changeId
                                    |> Lamdera.sendToFrontend clientId
                                , Broadcast.toSlackExcludingOne
                                    clientId
                                    guildOrDmId
                                    (Server_Slack_SendMessage time guildOrDmId threadRoute richText attachedFiles (slackThreadStarter guildOrDmId threadRoute model3) |> ServerChange)
                                    model3
                                ]
                            )

                        Nothing ->
                            ( model1b, BackendExtra.invalidChangeResponse changeId clientId )

                Err error ->
                    BackendExtra.addLogWithCmd
                        time
                        (Log.FailedToSendSlackMessage guildOrDmId error)
                        model1
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
                    let
                        ( discordUsers, cmds ) =
                            List.foldl
                                (\( discordUserId, maybeAvatar ) ( discordUsers2, cmds2 ) ->
                                    case SeqDict.get discordUserId discordUsers2 of
                                        Just user ->
                                            let
                                                fileHash =
                                                    Maybe.map .fileHash maybeAvatar

                                                user2 : DiscordUserData
                                                user2 =
                                                    case user of
                                                        FullData data ->
                                                            FullData { data | icon = fileHash }

                                                        BasicData data ->
                                                            BasicData { data | icon = fileHash }

                                                        NeedsAuthAgain data ->
                                                            NeedsAuthAgain { data | icon = fileHash }
                                            in
                                            ( SeqDict.insert discordUserId user2 discordUsers2
                                            , Broadcast.toEveryoneWhoCanSeeDiscordUser
                                                discordUserId
                                                (Server_DiscordAvatarsLoaded
                                                    discordUserId
                                                    { name = DiscordUserData.username user2 |> PersonName.fromStringLossy
                                                    , icon = fileHash
                                                    , color =
                                                        case user2 of
                                                            FullData data ->
                                                                case NonemptyDict.get data.linkedTo model.users of
                                                                    Just linkedUser ->
                                                                        linkedUser.color

                                                                    Nothing ->
                                                                        RichText.defaultColor

                                                            BasicData _ ->
                                                                RichText.defaultColor

                                                            NeedsAuthAgain data ->
                                                                case NonemptyDict.get data.linkedTo model.users of
                                                                    Just linkedUser ->
                                                                        linkedUser.color

                                                                    Nothing ->
                                                                        RichText.defaultColor
                                                    }
                                                )
                                                model
                                                :: cmds2
                                            )

                                        Nothing ->
                                            ( discordUsers2, cmds2 )
                                )
                                ( model.discordUsers, [] )
                                userAvatars
                    in
                    ( { model | discordUsers = discordUsers }
                    , Command.batch cmds
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
                        (Broadcast.toSession
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

        LinkDiscordUserStep1 linkedAt clientId userId auth result ->
            case result of
                Ok discordUser ->
                    if BackendExtra.discordLinkLimitReached discordUser.id model then
                        ( model, Lamdera.sendToFrontend clientId (LinkDiscordResponse (Err LinkDiscordLimitReached)) )

                    else
                        linkDiscordUser linkedAt clientId userId auth discordUser model

                Err error ->
                    ( model
                    , Lamdera.sendToFrontend clientId (LinkDiscordResponse (Err (LinkDiscordHttpError error)))
                    )

        LinkSlackUserStep1 linkedAt clientId userId cookie results ->
            let
                linkWorkspace :
                    ( SlackToken, Result Slack.HttpError Slack.UserBoot )
                    -> BackendModel
                    -> ( BackendModel, ( SlackToken, Result LinkSlackWorkspaceError Slack.UserBoot ) )
                linkWorkspace ( token, result ) current =
                    case result of
                        Ok userBoot ->
                            if BackendExtra.slackLinkLimitReached userBoot.self.id current then
                                ( current, ( token, Err SlackLinkLimitReached ) )

                            else
                                ( addLinkedSlackUser linkedAt userId cookie token userBoot current, ( token, Ok userBoot ) )

                        Err error ->
                            ( current, ( token, Err (SlackWorkspaceHttpError error) ) )

                (Nonempty firstResult restOfResults) =
                    results

                ( model2, firstResult2 ) =
                    linkWorkspace firstResult model

                ( model3, restOfResults2 ) =
                    List.foldl
                        (\result ( current, list ) ->
                            let
                                ( next, result2 ) =
                                    linkWorkspace result current
                            in
                            ( next, result2 :: list )
                        )
                        ( model2, [] )
                        restOfResults

                results2 : Nonempty ( SlackToken, Result LinkSlackWorkspaceError Slack.UserBoot )
                results2 =
                    Nonempty firstResult2 (List.reverse restOfResults2)
            in
            ( model3
            , Command.batch
                [ List.Nonempty.map (\( _, result ) -> Result.map (\{ team } -> team.name) result) results2
                    |> LoadedSlackWorkspaces
                    |> LinkSlackResponse
                    |> Lamdera.sendToFrontend clientId
                , List.Nonempty.toList results2
                    |> List.filterMap
                        (\( token, result ) ->
                            case result of
                                Ok { self, team } ->
                                    loadSlackWorkspaceData model3 cookie token self team
                                        |> Task.attempt (LinkSlackUserStep2 linkedAt team.id self.id)
                                        |> Just

                                Err _ ->
                                    Nothing
                        )
                    |> Command.batch
                ]
            )

        SlackChangedReaction time guildOrDmId result ->
            case result of
                Ok () ->
                    ( model, Command.none )

                Err (Slack.SlackError "already_reacted") ->
                    ( model, Command.none )

                Err (Slack.SlackError "no_reaction") ->
                    ( model, Command.none )

                Err error ->
                    BackendExtra.addLog time (Log.FailedToChangeSlackReaction guildOrDmId error) model

        SlackDeletedMessage time guildOrDmId result ->
            case result of
                Ok () ->
                    ( model, Command.none )

                Err (Slack.SlackError "message_not_found") ->
                    ( model, Command.none )

                Err error ->
                    BackendExtra.addLog time (Log.FailedToDeleteSlackMessage guildOrDmId error) model

        SlackEditedMessage time guildOrDmId result ->
            case result of
                Ok () ->
                    ( model, Command.none )

                Err (Slack.SlackError "message_not_found") ->
                    ( model, Command.none )

                Err error ->
                    BackendExtra.addLog time (Log.FailedToEditSlackMessage guildOrDmId error) model

        GotChangedSlackUser user icon ->
            slackUserChanged user icon model

        GotSlackUser slackUserId result ->
            let
                model2 : BackendModel
                model2 =
                    { model | pendingSlackUserLookups = SeqSet.remove slackUserId model.pendingSlackUserLookups }
            in
            case ( result, SeqDict.get slackUserId model2.slackUsers ) of
                ( Ok ( user, icon ), Nothing ) ->
                    let
                        model3 : BackendModel
                        model3 =
                            { model2 | slackUsers = SeqDict.insert slackUserId (SlackBasicData { user = user, icon = icon }) model2.slackUsers }
                    in
                    ( model3
                    , Broadcast.toSlackTeam
                        user.teamId
                        (Server_Slack_UserLoaded slackUserId (SlackSync.basicUserToFrontend user icon) |> ServerChange)
                        model3
                    )

                ( Ok _, Just _ ) ->
                    ( model2, Command.none )

                ( Err _, Just _ ) ->
                    ( model2, Command.none )

                ( Err _, Nothing ) ->
                    ( model2, Command.none )

        LinkSlackUserStep2 time teamId slackUserId result ->
            case result of
                Ok data ->
                    addLoadedSlackWorkspace teamId slackUserId data model
                        |> markNewSlackConversationsAsViewed
                            slackUserId
                            teamId
                            (List.map (\( channel, _ ) -> channel.id) data.channels)
                            (List.map (\( dmChannel, _ ) -> dmChannel.id) data.dmChannels)
                        |> (\model2 ->
                                ( model2
                                , Command.batch
                                    [ Websocket.createHandle (SlackWebsocketCreatedHandle slackUserId) Slack.websocketRelayUrl
                                    , slackLinkedUserLoaded slackUserId teamId model2
                                    ]
                                )
                           )

                Err error ->
                    BackendExtra.addLog time (Log.FailedToLoadSlackConversations teamId error) model

        RefreshedSlackConversations slackUserId result ->
            let
                model2 : BackendModel
                model2 =
                    { model | refreshingSlackConversations = SeqSet.remove slackUserId model.refreshingSlackConversations }
            in
            case result of
                Ok ( teamId, data ) ->
                    let
                        joinedChannels : SeqDict (Slack.Id Slack.ChannelId) SlackBackendChannel
                        joinedChannels =
                            case SeqDict.get teamId model2.slackWorkspaces of
                                Just workspace ->
                                    SeqDict.filter (\_ channel -> SeqSet.member slackUserId channel.linkedMembers) workspace.channels

                                Nothing ->
                                    SeqDict.empty

                        model3 : BackendModel
                        model3 =
                            addLoadedSlackWorkspace teamId slackUserId data model2
                                |> markNewSlackConversationsAsViewed
                                    slackUserId
                                    teamId
                                    (List.filterMap
                                        (\( channel, _ ) ->
                                            if SeqDict.member channel.id joinedChannels then
                                                Nothing

                                            else
                                                Just channel.id
                                        )
                                        data.channels
                                    )
                                    []
                    in
                    ( model3, slackLinkedUserLoaded slackUserId teamId model3 )

                Err ( time, error ) ->
                    case SeqDict.get slackUserId model2.slackUsers of
                        Just (SlackFullData linkedUser) ->
                            BackendExtra.addLog time (Log.FailedToLoadSlackConversations linkedUser.user.teamId error) model2

                        Just (SlackBasicData _) ->
                            ( model2, Command.none )

                        Nothing ->
                            ( model2, Command.none )

        SlackWebsocketCreatedHandle slackUserId connection ->
            case SeqDict.get slackUserId model.slackUsers of
                Just (SlackFullData linkedUser) ->
                    ( { model
                        | slackUsers =
                            SeqDict.insert
                                slackUserId
                                (SlackFullData { linkedUser | websocket = Just connection })
                                model.slackUsers
                      }
                    , case linkedUser.websocket of
                        Just oldConnection ->
                            Websocket.close oldConnection |> Task.perform (\() -> SlackWebsocketClosedByBackend)

                        Nothing ->
                            Command.none
                    )

                _ ->
                    ( model, Websocket.close connection |> Task.perform (\() -> SlackWebsocketClosedByBackend) )

        SlackWebsocketClosedByBackend ->
            ( model, Command.none )

        SlackMessageFilesUploaded slackUserId event files ->
            let
                model2 : BackendModel
                model2 =
                    { model | slackFiles = SeqDict.union files model.slackFiles }
            in
            case SeqDict.get slackUserId model2.slackUsers of
                Just (SlackFullData linkedUser) ->
                    handleSlackWebsocketEvent linkedUser event model2

                Just (SlackBasicData _) ->
                    ( model2, Command.none )

                Nothing ->
                    ( model2, Command.none )

        SlackWebsocketMsg slackUserId result ->
            case SeqDict.get slackUserId model.slackUsers of
                Just (SlackFullData linkedUser) ->
                    case result of
                        Ok text ->
                            receivedSlackWebsocketEvent linkedUser (Slack.parseWebsocketEvent text) model

                        Err ( code, reason ) ->
                            let
                                _ =
                                    Debug.log "Slack websocket closed" ( slackUserId, DiscordSync.closeEventCodeToInt code, reason )

                                ( delay, reconnect ) =
                                    nextSlackReconnectDelay linkedUser.reconnect
                            in
                            if linkedUser.needsAuthAgain then
                                ( { model
                                    | slackUsers =
                                        SeqDict.insert slackUserId (SlackFullData { linkedUser | websocket = Nothing }) model.slackUsers
                                  }
                                , Command.none
                                )

                            else
                                ( { model
                                    | slackUsers =
                                        SeqDict.insert
                                            slackUserId
                                            (SlackFullData { linkedUser | websocket = Nothing, reconnect = reconnect })
                                            model.slackUsers
                                    , pendingSlackReconnects = SeqDict.insert slackUserId delay model.pendingSlackReconnects
                                  }
                                , -- Failing twice in a row could mean the login expired, which reconnecting won't fix.
                                  if linkedUser.reconnect.failedAttempts > 0 then
                                    Slack.userBoot model.serverSecret linkedUser.cookie linkedUser.token
                                        |> Task.attempt (CheckedSlackAuth slackUserId)

                                  else
                                    Command.none
                                )

                _ ->
                    ( model, Command.none )

        CaughtUpSlackMessages slackUserId events ->
            case SeqDict.get slackUserId model.slackUsers of
                Just (SlackFullData linkedUser) ->
                    List.foldl
                        (\event ( model2, cmds ) ->
                            let
                                ( model3, cmd ) =
                                    receivedSlackWebsocketEvent linkedUser event model2
                            in
                            ( model3, cmd :: cmds )
                        )
                        ( model, [] )
                        events
                        |> Tuple.mapSecond Command.batch

                Just (SlackBasicData _) ->
                    ( model, Command.none )

                Nothing ->
                    ( model, Command.none )

        CheckedSlackAuth slackUserId result ->
            case ( SeqDict.get slackUserId model.slackUsers, result ) of
                ( Just (SlackFullData linkedUser), Err (Slack.SlackError error) ) ->
                    if List.member error [ "invalid_auth", "not_authed", "token_revoked", "token_expired", "account_inactive" ] then
                        let
                            model2 : BackendModel
                            model2 =
                                { model
                                    | slackUsers =
                                        SeqDict.insert
                                            slackUserId
                                            (SlackFullData { linkedUser | websocket = Nothing, needsAuthAgain = True })
                                            model.slackUsers
                                    , pendingSlackReconnects = SeqDict.remove slackUserId model.pendingSlackReconnects
                                }
                        in
                        ( model2
                        , Command.batch
                            [ Broadcast.toUser
                                Nothing
                                Nothing
                                linkedUser.linkedTo
                                (Server_Slack_NeedsAuthAgain slackUserId |> ServerChange)
                                model2
                            , case linkedUser.websocket of
                                Just connection ->
                                    Websocket.close connection |> Task.perform (\() -> SlackWebsocketClosedByBackend)

                                Nothing ->
                                    Command.none
                            ]
                        )

                    else
                        ( model, Command.none )

                _ ->
                    ( model, Command.none )

        SlackWebsocketSentData slackUserId result ->
            case result of
                Ok () ->
                    ( model, Command.none )

                Err Websocket.ConnectionClosed ->
                    let
                        _ =
                            Debug.log "SlackWebsocketSentData" ( slackUserId, "ConnectionClosed" )
                    in
                    ( model, Command.none )

        SlackWebsocketReconnectTick ->
            let
                ( stillWaiting, reopenNow ) =
                    SeqDict.foldl
                        (\slackUserId delay ( waiting, reopen ) ->
                            let
                                remaining : Duration
                                remaining =
                                    Quantity.minus DiscordSync.gatewayReconnectTickInterval delay
                            in
                            if Quantity.greaterThanZero remaining then
                                ( SeqDict.insert slackUserId remaining waiting, reopen )

                            else
                                case SeqDict.get slackUserId model.slackUsers of
                                    Just (SlackFullData linkedUser) ->
                                        case linkedUser.websocket of
                                            Just _ ->
                                                ( waiting, reopen )

                                            Nothing ->
                                                ( waiting, slackUserId :: reopen )

                                    Just (SlackBasicData _) ->
                                        ( waiting, reopen )

                                    Nothing ->
                                        ( waiting, reopen )
                        )
                        ( SeqDict.empty, [] )
                        model.pendingSlackReconnects
            in
            ( { model | pendingSlackReconnects = stillWaiting }
            , List.map
                (\slackUserId -> Websocket.createHandle (SlackWebsocketCreatedHandle slackUserId) Slack.websocketRelayUrl)
                reopenNow
                |> Command.batch
            )

        ReloadDiscordUserStep1 time clientId userId discordUserId result ->
            case ( SeqDict.get discordUserId model.discordUsers, result ) of
                ( Just (FullData discordUser), Ok discordUserData ) ->
                    let
                        discordUser2 : DiscordFullUserData
                        discordUser2 =
                            { discordUser
                                | user = discordUserData
                                , {- This is to prevent the normal reconnect flow.
                                     We want to trigger a new Ready gateway event so we can load all the data in it.
                                  -}
                                  connection = Discord.init (Time.posixToMillis time)
                            }
                    in
                    ( { model
                        | discordUsers = SeqDict.insert discordUserId (FullData discordUser2) model.discordUsers
                        , pendingGatewayReconnects =
                            SeqDict.remove discordUserId model.pendingGatewayReconnects
                      }
                    , Command.batch
                        [ Lamdera.sendToFrontend clientId (LinkDiscordResponse (Ok ()))
                        , Broadcast.toUser
                            Nothing
                            Nothing
                            userId
                            (Server_LinkDiscordUser
                                discordUserId
                                (User.discordFullDataUserToFrontendCurrentUser model.users False discordUser2 discordUser2.isLoadingData)
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
                        Ok { dmChannels, guilds, channelMessages, attachments } ->
                            let
                                guildDataDict :
                                    SeqDict
                                        (Discord.Id Discord.GuildId)
                                        { guild : Discord.GatewayGuild
                                        , channels : List Discord.Channel
                                        , icon : Maybe FileStatus.UploadResponse
                                        }
                                guildDataDict =
                                    SeqDict.fromList guilds

                                attachments2 : SeqDict DiscordAttachmentId DiscordAttachmentData
                                attachments2 =
                                    DiscordSync.addUploadResponsesToDiscordAttachments attachments model.discordAttachments

                                messageAuthors : List Discord.User
                                messageAuthors =
                                    List.concatMap .messages dmChannels
                                        ++ List.concat (SeqDict.values channelMessages)
                                        |> List.map .author
                                        |> List.Extra.uniqueBy (\author -> Discord.idToString author.id)

                                model2 : BackendModel
                                model2 =
                                    { model
                                        | discordUsers =
                                            List.foldl
                                                (\author discordUsers -> DiscordSync.addDiscordUserData (Discord.userToPartialUser author) discordUsers)
                                                (SeqDict.insert
                                                    discordUserId
                                                    (FullData
                                                        { discordUser
                                                            | isLoadingData = DiscordUserLoadedSuccessfully
                                                            , markEverythingAsViewedOnceLoaded = False
                                                        }
                                                    )
                                                    model.discordUsers
                                                )
                                                messageAuthors
                                        , discordGuilds =
                                            SeqDict.foldl
                                                (\guildId guildData2 discordGuilds ->
                                                    SeqDict.updateIfExists
                                                        guildId
                                                        (\guild ->
                                                            addDiscordGuildData discordUserId guildData2 guild
                                                                |> addNewChannelMessages model attachments2 channelMessages guild.channels
                                                        )
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
                                                                    let
                                                                        ( messages, linkedMessageIds ) =
                                                                            DiscordSync.messagesAndLinks
                                                                                { messages = IdArray.empty, linkedMessageIds = OneToOne.empty }
                                                                                (List.reverse data.messages)
                                                                                model.discordCustomEmojis
                                                                                SeqDict.empty
                                                                                model.discordStickers
                                                                                attachments2
                                                                    in
                                                                    { messages = messages
                                                                    , lastTypedAt = SeqDict.empty
                                                                    , linkedMessageIds = linkedMessageIds
                                                                    , members =
                                                                        List.foldl
                                                                            (\member dict -> NonemptyDict.insert member { messagesSent = 0 } dict)
                                                                            (NonemptyDict.singleton discordUserId { messagesSent = 0 })
                                                                            data.members
                                                                            |> addMessagesSent messages
                                                                    , dateDividerDrawings = SeqDict.empty
                                                                    }
                                                                        |> Just
                                                        )
                                                        dmChannels2
                                                )
                                                model.discordDmChannels
                                                dmChannels
                                        , discordAttachments = attachments2
                                    }

                                model3 : BackendModel
                                model3 =
                                    if discordUser.markEverythingAsViewedOnceLoaded then
                                        markDiscordDataAsViewed discordUserId discordUser.linkedTo model2

                                    else
                                        model2
                            in
                            ( model3
                            , Command.batch
                                [ DiscordSync.getUserAvatars model3.serverSecret model3.discordUsers messageAuthors
                                , Broadcast.toUserAlt
                                    discordUser.linkedTo
                                    (\session connection ->
                                        let
                                            linkedAndOtherDiscordUsers =
                                                BackendExtra.getLinkedDiscordUsersAndOtherUsers
                                                    session.userId
                                                    connection.currentlyViewing
                                                    model3
                                        in
                                        Server_DiscordUserLoadingDataIsDone
                                            discordUserId
                                            (Ok
                                                { discordGuilds =
                                                    SeqDict.filterMap
                                                        (\guildId _ ->
                                                            case SeqDict.get guildId model3.discordGuilds of
                                                                Just guild ->
                                                                    BackendExtra.discordGuildToFrontendForUser
                                                                        Nothing
                                                                        guildId
                                                                        guild
                                                                        (LinkedAndOtherDiscordUsers.linkedUsers linkedAndOtherDiscordUsers)

                                                                Nothing ->
                                                                    Nothing
                                                        )
                                                        guildDataDict
                                                , discordDms =
                                                    List.filterMap
                                                        (\data ->
                                                            case SeqDict.get data.dmChannelId model3.discordDmChannels of
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
                                                        dmChannels
                                                        |> SeqDict.fromList
                                                , discordUsers = LinkedAndOtherDiscordUsers.otherUsers linkedAndOtherDiscordUsers
                                                , markEverythingAsViewed = discordUser.markEverythingAsViewedOnceLoaded
                                                }
                                            )
                                            |> ServerChange
                                    )
                                    model3
                                ]
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
                                |> Task.perform (WebsocketClosedByBackendForUser discordUserId Nothing)

                        Nothing ->
                            Command.none
                    )

                _ ->
                    ( model, Command.none )

        WebsocketClosedByBackendForUser discordUserId reopen websocketEvent ->
            let
                model2 : BackendModel
                model2 =
                    recordWebsocketCloseEvent websocketEvent model
            in
            ( case reopen of
                Just reconnect ->
                    { model2
                        | pendingGatewayReconnects =
                            SeqDict.insert discordUserId reconnect model2.pendingGatewayReconnects
                    }

                Nothing ->
                    model2
            , Command.none
            )

        GatewayReconnectTick ->
            let
                ( stillWaiting, reopenNow ) =
                    SeqDict.foldl
                        (\discordUserId reconnect ( waiting, reopen ) ->
                            let
                                remaining : Duration
                                remaining =
                                    Quantity.minus DiscordSync.gatewayReconnectTickInterval reconnect.delay
                            in
                            if Quantity.greaterThanZero remaining then
                                ( SeqDict.insert discordUserId { reconnect | delay = remaining } waiting, reopen )

                            else
                                case SeqDict.get discordUserId model.discordUsers of
                                    Just (FullData _) ->
                                        ( waiting, ( discordUserId, reconnect.gatewayUrl ) :: reopen )

                                    _ ->
                                        -- The account was unlinked or needs authorizing again while
                                        -- we were waiting, so there's nothing left to reconnect to.
                                        ( waiting, reopen )
                        )
                        ( SeqDict.empty, [] )
                        model.pendingGatewayReconnects
            in
            ( { model | pendingGatewayReconnects = stillWaiting }
            , List.map
                (\( discordUserId, gatewayUrl ) ->
                    DiscordSync.websocketCreateHandle
                        "GatewayReconnectTick"
                        (WebsocketCreatedHandleForUser discordUserId)
                        gatewayUrl
                )
                reopenNow
                |> Command.batch
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
                ( Just ( guild, channel ), Just (LoadingDiscordGuildChannel _ guildIdB channelIdB (LoadingDiscordChannelAttachments _ reload)) ) ->
                    if guildId == guildIdB && channelId == channelIdB then
                        let
                            attachments2 : SeqDict DiscordAttachmentId DiscordAttachmentData
                            attachments2 =
                                DiscordSync.addUploadResponsesToDiscordAttachments attachments model.discordAttachments

                            linkedMessageIds : OneToOne (Discord.Id Discord.MessageId) (Id ChannelMessageId)
                            linkedMessageIds =
                                DiscordSync.messageLinks (List.reverse reload.messages)

                            -- Mentions of this channel's own threads have to be looked up in the
                            -- messages being loaded rather than the ones they replace
                            channels : SeqDict (Discord.Id Discord.ChannelId) DiscordBackendChannel
                            channels =
                                SeqDict.insert channelId { channel | linkedMessageIds = linkedMessageIds } guild.channels

                            ( messages2, _ ) =
                                DiscordSync.messagesAndLinks
                                    channel
                                    (List.reverse reload.messages)
                                    model.discordCustomEmojis
                                    channels
                                    model.discordStickers
                                    attachments2

                            threads : SeqDict (Id ChannelMessageId) DiscordBackendThread
                            threads =
                                List.filterMap
                                    (\thread ->
                                        let
                                            threadMessageId : Discord.Id Discord.MessageId
                                            threadMessageId =
                                                Discord.idToUInt64 thread.threadId |> Discord.idFromUInt64
                                        in
                                        case OneToOne.second threadMessageId linkedMessageIds of
                                            Just channelMessageIndex ->
                                                let
                                                    -- Keep whatever the thread already had that isn't
                                                    -- loaded from Discord, such as drawings
                                                    existingThread : DiscordBackendThread
                                                    existingThread =
                                                        case OneToOne.second threadMessageId channel.linkedMessageIds of
                                                            Just oldMessageIndex ->
                                                                SeqDict.get oldMessageIndex channel.threads
                                                                    |> Maybe.withDefault Thread.discordBackendInit

                                                            Nothing ->
                                                                Thread.discordBackendInit

                                                    ( threadMessages, threadLinkedMessageIds ) =
                                                        DiscordSync.messagesAndLinks
                                                            existingThread
                                                            (List.reverse thread.messages)
                                                            model.discordCustomEmojis
                                                            channels
                                                            model.discordStickers
                                                            attachments2
                                                in
                                                if IdArray.isEmpty threadMessages then
                                                    -- A thread nobody has written anything in yet is
                                                    -- the same as the message not having a thread
                                                    Nothing

                                                else
                                                    ( channelMessageIndex
                                                    , { existingThread
                                                        | messages = threadMessages
                                                        , linkedMessageIds = threadLinkedMessageIds
                                                      }
                                                    )
                                                        |> Just

                                            Nothing ->
                                                -- The message the thread hangs off of is older than the
                                                -- messages we loaded, so there's nothing to attach it to
                                                Nothing
                                    )
                                    reload.threads
                                    |> SeqDict.fromList

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
                                                        { channel
                                                            | messages = messages2
                                                            , linkedMessageIds = linkedMessageIds
                                                            , threads = threads
                                                        }
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
                ( Just channel, Just (LoadingDiscordDmChannel _ channelIdB (LoadingDiscordChannelAttachments _ reload)) ) ->
                    if channelId == channelIdB then
                        let
                            attachments2 : SeqDict DiscordAttachmentId DiscordAttachmentData
                            attachments2 =
                                DiscordSync.addUploadResponsesToDiscordAttachments
                                    attachments
                                    model.discordAttachments

                            ( messages2, linkedMessageIds ) =
                                DiscordSync.messagesAndLinks
                                    channel
                                    (List.reverse reload.messages)
                                    model.discordCustomEmojis
                                    SeqDict.empty
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
                                                , members = addMessagesSent messages2 channel.members
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
                            loading : LoadingDiscordChannel DiscordChannelReload
                            loading =
                                (case result of
                                    Ok reload ->
                                        LoadingDiscordChannelAttachments time reload

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
                                Ok reload ->
                                    DiscordSync.uploadAttachmentsForMessages
                                        model
                                        (LocalState.discordChannelReloadMessages reload)
                                        |> Task.perform (ReloadedDiscordGuildChannel userIdToLoadWith guildId channelId)

                                Err _ ->
                                    Command.none
                            , LocalState.loadingDiscordChannelMap
                                LocalState.discordChannelReloadAttachmentCount
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
                            loading : LoadingDiscordChannel DiscordChannelReload
                            loading =
                                (case result of
                                    Ok messages ->
                                        -- DM channels don't have threads
                                        LoadingDiscordChannelAttachments time { messages = messages, threads = [] }

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
                                LocalState.discordChannelReloadAttachmentCount
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

        GotTimeForDiscordForumPostRenamed thread time ->
            DiscordSync.handleForumPostRenamed thread time model

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
                        { otherUserId = userIdB }
                        (\id ->
                            Server_GotDmMessageEmbed
                                id.otherUserId
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
                            , Broadcast.toDiscordGuildChannel
                                guildId
                                channelId
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

        SlackGotMessageEmbed guildOrDmId threadRouteWithMessage result ->
            case
                updateSlackConversation
                    guildOrDmId
                    (\conversation ->
                        ( case threadRouteWithMessage of
                            NoThreadWithMessage messageId ->
                                LocalState.addEmbedBackend messageId result conversation

                            ViewThreadWithMessage threadId messageId ->
                                { conversation
                                    | threads =
                                        SeqDict.updateIfExists threadId (LocalState.addEmbedBackend messageId result) conversation.threads
                                }
                        , ()
                        )
                            |> Just
                    )
                    model
            of
                Just ( model2, () ) ->
                    ( model2
                    , Broadcast.toSlack
                        guildOrDmId
                        (Server_Slack_GotMessageEmbed
                            guildOrDmId
                            threadRouteWithMessage
                            (Tuple.mapSecond (Result.mapError (\_ -> ())) result)
                            |> ServerChange
                        )
                        model2
                    )

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

        ExportBackendStep time ->
            case model.exportState of
                Just exportState ->
                    case handleExportBackendStep exportState.progress of
                        ExportInProgress progress progressState ->
                            ( { model | exportState = Just { exportState | progress = progressState } }
                            , Pages.Admin.ExportBackendProgress exportState.exportSubset progress
                                |> AdminToFrontend
                                |> Lamdera.sendToFrontend exportState.clientId
                            )

                        ExportFinished bytes ->
                            let
                                backup : LocalState.LastBackup
                                backup =
                                    { createdAt = time
                                    , contents =
                                        case exportState.exportSubset of
                                            Pages.Admin.ExportAll ->
                                                LocalState.FullBackup

                                            Pages.Admin.ExportSubset _ ->
                                                LocalState.SubsetBackup
                                    }

                                model2 : BackendModel
                                model2 =
                                    { model
                                        | exportState = Nothing
                                        , lastBackup = Just { backup = backup, bytes = bytes }
                                    }
                            in
                            ( model2
                            , Command.batch
                                [ Pages.Admin.ExportBackendFinished
                                    |> AdminToFrontend
                                    |> Lamdera.sendToFrontend exportState.clientId
                                , Broadcast.toAdmins model2 (Server_BackupGenerated backup |> ServerChange)
                                ]
                            )

                Nothing ->
                    ( model, Command.none )

        DownloadBackupChunkStep ->
            case model.downloadBackupState of
                Just (BackupDownload downloadState) ->
                    let
                        ( chunk, remainingBytes ) =
                            Pages.Admin.splitOffChunk downloadBackupChunkSize downloadState.remainingBytes
                    in
                    ( { model
                        | downloadBackupState =
                            if Bytes.width remainingBytes > 0 then
                                Just (BackupDownload { downloadState | remainingBytes = remainingBytes })

                            else
                                Nothing
                      }
                    , Pages.Admin.DownloadLastBackupChunk downloadState.contents downloadState.totalBytes chunk
                        |> AdminToFrontend
                        |> Lamdera.sendToFrontend downloadState.clientId
                    )

                _ ->
                    ( model, Command.none )

        ScheduledExportBackendStep time ->
            case model.scheduledExportState of
                Just exportState ->
                    case handleExportBackendStep exportState of
                        ExportInProgress _ progressState ->
                            ( { model | scheduledExportState = Just progressState }, Command.none )

                        ExportFinished bytes ->
                            let
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
                            ( { model
                                | scheduledExportState = Nothing
                                , lastBackup =
                                    Just
                                        { backup =
                                            { createdAt = time
                                            , contents = LocalState.FullBackup
                                            }
                                        , bytes = bytes
                                        }
                              }
                            , FileStatus.uploadBackup model.serverSecret ("backend-export-" ++ timestamp ++ ".bin") bytes
                                |> Task.attempt (ScheduledExportUploadResult time (Bytes.width bytes))
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

                        maybeLinkedTo : Maybe (Id UserId)
                        maybeLinkedTo =
                            case SeqDict.get discordUserId model.discordUsers of
                                Just (FullData discordUser) ->
                                    Just discordUser.linkedTo

                                _ ->
                                    Nothing

                        model2 : BackendModel
                        model2 =
                            { model
                                | discordGuilds = SeqDict.insert guildId guild2 model.discordGuilds
                                , users =
                                    case maybeLinkedTo of
                                        Just linkedTo ->
                                            NonemptyDict.updateIfExists
                                                linkedTo
                                                (LocalState.markAllDiscordChannelsAndThreadsAsViewedBackend
                                                    discordUserId
                                                    guildId
                                                    guild2
                                                )
                                                model.users

                                        Nothing ->
                                            model.users
                            }
                    in
                    ( model2
                    , case maybeLinkedTo of
                        Just linkedTo ->
                            Broadcast.toUser
                                Nothing
                                Nothing
                                linkedTo
                                (Server_DiscordGuildJoinedOrCreated
                                    discordUserId
                                    guildId
                                    (BackendExtra.discordGuildToFrontend
                                        Nothing
                                        -- We don't need to provide all the linked users because the current one must have access to the channels we just loaded
                                        (SeqDict.singleton discordUserId ())
                                        guildId
                                        guild2
                                    )
                                    |> ServerChange
                                )
                                model2

                        Nothing ->
                            Command.none
                    )

                ( Err error, _ ) ->
                    BackendExtra.addLog time (Log.FailedToGetDataForJoinedOrCreatedDiscordGuild discordUserId guildId error) model

                ( _, Nothing ) ->
                    ( model, Command.none )

        DiscordGotGuildIcon guildId uploadResponse ->
            let
                icon : Maybe FileHash
                icon =
                    Maybe.map .fileHash uploadResponse
            in
            case SeqDict.get guildId model.discordGuilds of
                Just guild ->
                    if guild.icon == icon then
                        ( model, Command.none )

                    else
                        let
                            model2 : BackendModel
                            model2 =
                                { model
                                    | discordGuilds =
                                        SeqDict.insert guildId { guild | icon = icon } model.discordGuilds
                                }
                        in
                        ( model2
                        , Broadcast.toDiscordGuild
                            guildId
                            (Server_DiscordUpdateGuild guildId guild.name icon guild.roles |> ServerChange)
                            model2
                        )

                Nothing ->
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
                orphanedFiles : SeqSet FileHash
                orphanedFiles =
                    SeqDict.keys (DeleteUserAndFiles.orphanedFiles model) |> SeqSet.fromList

                filesToDelete : SeqSet FileHash
                filesToDelete =
                    SeqSet.intersect model.orphanedFilesLastHour orphanedFiles

                orphanedDiscordGuilds : SeqSet (Discord.Id Discord.GuildId)
                orphanedDiscordGuilds =
                    DeleteUserAndFiles.orphanedDiscordGuilds model

                discordGuildsToDelete : SeqSet (Discord.Id Discord.GuildId)
                discordGuildsToDelete =
                    SeqSet.intersect model.orphanedDiscordGuildsLastHour orphanedDiscordGuilds

                orphanedSlackWorkspaces : SeqSet (Slack.Id Slack.TeamId)
                orphanedSlackWorkspaces =
                    DeleteUserAndFiles.orphanedSlackWorkspaces model

                slackWorkspacesToDelete : SeqSet (Slack.Id Slack.TeamId)
                slackWorkspacesToDelete =
                    SeqSet.intersect model.orphanedSlackWorkspacesLastHour orphanedSlackWorkspaces

                orphanedSlackDmChannels : SeqSet (Slack.Id Slack.DmChannelId)
                orphanedSlackDmChannels =
                    DeleteUserAndFiles.orphanedSlackDmChannels model

                slackDmChannelsToDelete : SeqSet (Slack.Id Slack.DmChannelId)
                slackDmChannelsToDelete =
                    SeqSet.intersect model.orphanedSlackDmChannelsLastHour orphanedSlackDmChannels

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
                                lastActiveAt : Time.Posix
                                lastActiveAt =
                                    BackendExtra.sessionLastActiveAt session (SeqDict.get sessionId model.connections)
                            in
                            if Duration.from lastActiveAt time |> Quantity.lessThan (Duration.days 30) then
                                Nothing

                            else
                                Just sessionId
                        )
                        (SeqDict.toList model.sessions)

                ( model2, deleteAccountsCmd ) =
                    DeleteUserAndFiles.deleteAccounts
                        time
                        { model
                            | orphanedFilesLastHour = SeqSet.diff orphanedFiles filesToDelete
                            , orphanedDiscordGuildsLastHour = SeqSet.diff orphanedDiscordGuilds discordGuildsToDelete
                            , discordGuilds = SeqSet.foldl SeqDict.remove model.discordGuilds discordGuildsToDelete
                            , orphanedSlackWorkspacesLastHour = SeqSet.diff orphanedSlackWorkspaces slackWorkspacesToDelete
                            , slackWorkspaces = SeqSet.foldl SeqDict.remove model.slackWorkspaces slackWorkspacesToDelete
                            , orphanedSlackDmChannelsLastHour = SeqSet.diff orphanedSlackDmChannels slackDmChannelsToDelete
                            , slackDmChannels = SeqSet.foldl SeqDict.remove model.slackDmChannels slackDmChannelsToDelete
                            , logs = deleteOldLogs time model.logs
                        }
            in
            ( if shouldExport then
                startExport time model2

              else
                { model2
                    | lastScheduledExportTime =
                        case model2.lastScheduledExportTime of
                            Just _ ->
                                model2.lastScheduledExportTime

                            Nothing ->
                                Just time
                    , deletedGuilds =
                        SeqDict.filter
                            (\_ deletedGuild ->
                                Duration.from deletedGuild.deletedAt time |> Quantity.lessThan (Duration.days 30)
                            )
                            model2.deletedGuilds
                    , connections = List.foldl SeqDict.remove model2.connections expiredSessions
                    , sessions = List.foldl SeqDict.remove model2.sessions expiredSessions
                }
            , Command.batch
                [ Discord.getStickerPacksPayload
                    |> DiscordSync.http model2.serverSecret
                    |> Task.attempt (GotDiscordStandardStickerPacks time)
                , if SeqSet.isEmpty filesToDelete then
                    Command.none

                  else
                    DeleteUserAndFiles.deleteFiles model2.serverSecret (SeqSet.toList filesToDelete)
                        |> Task.attempt (HourlyDeletedOrphanedFiles time (SeqSet.toList filesToDelete))
                , deleteAccountsCmd
                ]
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

        ScheduledExportUploadResult time backupSize result ->
            case result of
                Ok () ->
                    ( model, Command.none )

                Err error ->
                    BackendExtra.addLog time (Log.FailedToGenerateScheduledBackup error backupSize) model

        DeletedOrphanedFiles time changeId clientId deleted result ->
            let
                responseCmd : Command BackendOnly ToFrontend BackendMsg
                responseCmd =
                    FilledInByBackend (Result.map (\() -> deleted) result)
                        |> Pages.Admin.DeleteOrphanedFiles
                        |> Local_Admin
                        |> LocalChangeResponse changeId
                        |> Lamdera.sendToFrontend clientId
            in
            case result of
                Ok () ->
                    ( DeleteUserAndFiles.removeDeletedFiles deleted model, responseCmd )

                Err error ->
                    BackendExtra.addLogWithCmd time (Log.FailedToDeleteOrphanedFiles error) model responseCmd

        HourlyDeletedOrphanedFiles time deleted result ->
            case result of
                Ok () ->
                    ( DeleteUserAndFiles.removeDeletedFiles deleted model, Command.none )

                Err error ->
                    BackendExtra.addLog time (Log.FailedToDeleteOrphanedFiles error) model

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

        ReloadedDiscordGuildForAdmin time changeId clientId userIdToLoadWith guildId result ->
            let
                responseCmd : Command BackendOnly ToFrontend BackendMsg
                responseCmd =
                    FilledInByBackend (Result.map (\( guild, _ ) -> guild.roles) result)
                        |> Pages.Admin.ReloadDiscordGuild userIdToLoadWith guildId
                        |> Local_Admin
                        |> LocalChangeResponse changeId
                        |> Lamdera.sendToFrontend clientId
            in
            case result of
                Ok ( guild, channels ) ->
                    ( { model
                        | discordGuilds =
                            SeqDict.updateIfExists
                                guildId
                                (\discordGuild ->
                                    { discordGuild
                                        | roles = Pages.Admin.rolesToDict guild.roles
                                        , channels = reloadChannelPermissionOverwrites channels discordGuild.channels
                                    }
                                )
                                model.discordGuilds
                      }
                    , responseCmd
                    )

                Err error ->
                    BackendExtra.addLogWithCmd time (Log.FailedToReloadDiscordGuild guildId error) model responseCmd

        Rpc_GotFileUpload fileHash fileSize2 maybeImageSize ->
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

        Rpc_UserJoinedCall time sessionId clientId userId callId ->
            case callId of
                Call.DmRoomId id ->
                    joinDmVoiceChat sessionId clientId time id model userId

                Call.GuildRoomId id ->
                    joinGuildVoiceChat sessionId clientId time id model userId


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


{-| Refresh the permission overwrites of the channels we already track for a guild, using freshly
fetched channels. Channels we don't track are ignored and every other field of the channels we do
track is left untouched, so this only updates permission overwrites without affecting anything else.
-}
reloadChannelPermissionOverwrites :
    List Discord.Channel2
    -> SeqDict (Discord.Id Discord.ChannelId) DiscordBackendChannel
    -> SeqDict (Discord.Id Discord.ChannelId) DiscordBackendChannel
reloadChannelPermissionOverwrites discordChannels channels =
    List.foldl
        (\discordChannel acc ->
            SeqDict.updateIfExists
                discordChannel.id
                (\channel -> { channel | permissionOverwrites = discordChannel.permissionOverwrites })
                acc
        )
        channels
        discordChannels


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
        MembersAndOwner.addMember discordUserId { joinedAt = Nothing, roles = SeqSet.empty } guild.membersAndOwner
            |> Result.withDefault guild.membersAndOwner
    , stickers = guild.stickers
    , customEmojis = guild.customEmojis
    , roles = Pages.Admin.rolesToDict data.guild.roles
    , lastTypedAt = guild.lastTypedAt
    }


{-| Loads every channel and DM the linked Slack user can see, along with the newest messages of
the channels and DMs we didn't have before, and the users in those we haven't seen yet.
-}
loadSlackWorkspaceData :
    BackendModel
    -> SlackCookie
    -> SlackToken
    -> Slack.User
    -> Slack.Team
    -> Task BackendOnly Slack.HttpError LoadedSlackWorkspace
loadSlackWorkspaceData model cookie token self team =
    let
        teamId : Slack.Id Slack.TeamId
        teamId =
            team.id

        existingChannels : SeqDict (Slack.Id Slack.ChannelId) SlackBackendChannel
        existingChannels =
            case SeqDict.get teamId model.slackWorkspaces of
                Just workspace ->
                    workspace.channels

                Nothing ->
                    SeqDict.empty

        history : Slack.Id channelId -> Task BackendOnly Slack.HttpError Slack.History
        history channelId =
            Slack.history model.serverSecret cookie token SlackSync.newChannelMaxMessages channelId

        noHistory : Slack.History
        noHistory =
            { messages = [], replies = SeqDict.empty }
    in
    Slack.userConversations model.serverSecret cookie token self.id
        |> Task.andThen
            (\{ channels, dmChannels } ->
                Task.map2
                    (\channels2 dmChannels2 -> { channels = channels2, dmChannels = dmChannels2 })
                    (List.map
                        (\channel ->
                            if SeqDict.member channel.id existingChannels then
                                Task.succeed ( channel, noHistory )

                            else
                                history channel.id |> Task.map (Tuple.pair channel)
                        )
                        channels
                        |> Task.sequence
                    )
                    (List.map
                        (\dmChannel ->
                            if SeqDict.member dmChannel.id model.slackDmChannels then
                                Task.succeed ( dmChannel, noHistory )

                            else
                                history dmChannel.id |> Task.map (Tuple.pair dmChannel)
                        )
                        dmChannels
                        |> Task.sequence
                    )
            )
        |> Task.andThen
            (\{ channels, dmChannels } ->
                let
                    historyUserIds : Slack.History -> List (Slack.Id Slack.UserId)
                    historyUserIds history2 =
                        List.concatMap Slack.messageUserIds history2.messages
                            ++ List.concatMap (List.concatMap Slack.messageUserIds) (SeqDict.values history2.replies)

                    unknownUserIds : List (Slack.Id Slack.UserId)
                    unknownUserIds =
                        List.concatMap (\( _, channelHistory ) -> historyUserIds channelHistory) channels
                            ++ List.concatMap
                                (\( dmChannel, dmHistory ) -> NonemptySet.toList dmChannel.members ++ historyUserIds dmHistory)
                                dmChannels
                            |> SeqSet.fromList
                            |> SeqSet.filter (\userId -> not (SeqDict.member userId model.slackUsers))
                            |> SeqSet.toList

                    usersWithoutIcon : List (Slack.Id Slack.UserId)
                    usersWithoutIcon =
                        SeqDict.toList model.slackUsers
                            |> List.filterMap
                                (\( userId, userData ) ->
                                    case userData of
                                        SlackBasicData { user, icon } ->
                                            if user.teamId == teamId && icon == Nothing then
                                                Just userId

                                            else
                                                Nothing

                                        SlackFullData _ ->
                                            Nothing
                                )
                in
                Slack.usersById model.serverSecret cookie token teamId (unknownUserIds ++ usersWithoutIcon)
                    |> Task.map (\users -> { channels = channels, dmChannels = dmChannels, users = users })
            )
        |> Task.andThen
            (\{ channels, dmChannels, users } ->
                let
                    historyFiles : Slack.History -> List Slack.File
                    historyFiles history2 =
                        List.concatMap Slack.messageFiles history2.messages
                            ++ List.concatMap (List.concatMap Slack.messageFiles) (SeqDict.values history2.replies)
                in
                Task.map4
                    (\users2 selfIcon workspaceIcon files ->
                        { channels = channels
                        , dmChannels = dmChannels
                        , users = users2
                        , selfIcon = selfIcon
                        , workspaceIcon = workspaceIcon
                        , files = files
                        }
                    )
                    (List.map
                        (\user -> uploadSlackImage model.serverSecret user.image |> Task.map (Tuple.pair user))
                        users
                        |> Task.sequence
                    )
                    (uploadSlackImage model.serverSecret self.image)
                    (case team.icon of
                        Just icon ->
                            uploadSlackImage model.serverSecret icon

                        Nothing ->
                            Task.succeed Nothing
                    )
                    (List.concatMap (\( _, channelHistory ) -> historyFiles channelHistory) channels
                        ++ List.concatMap (\( _, dmHistory ) -> historyFiles dmHistory) dmChannels
                        |> List.filter (\file -> not (SeqDict.member file.id model.slackFiles))
                        |> uploadSlackFiles model.serverSecret cookie token
                    )
            )


{-| Fills in the messages loaded for a Discord guild's channels, leaving alone the channels it
already had.
-}
addNewChannelMessages :
    BackendModel
    -> SeqDict DiscordAttachmentId DiscordAttachmentData
    -> SeqDict (Discord.Id Discord.ChannelId) (List Discord.Message)
    -> SeqDict (Discord.Id Discord.ChannelId) DiscordBackendChannel
    -> DiscordBackendGuild
    -> DiscordBackendGuild
addNewChannelMessages model attachments channelMessages existingChannels guild =
    { guild
        | channels =
            SeqDict.map
                (\channelId channel ->
                    case ( SeqDict.member channelId existingChannels, SeqDict.get channelId channelMessages ) of
                        ( False, Just messages ) ->
                            let
                                ( messages2, linkedMessageIds ) =
                                    DiscordSync.messagesAndLinks
                                        channel
                                        (List.reverse messages)
                                        model.discordCustomEmojis
                                        guild.channels
                                        model.discordStickers
                                        attachments
                            in
                            { channel | messages = messages2, linkedMessageIds = linkedMessageIds }

                        _ ->
                            channel
                )
                guild.channels
    }


addMessagesSent :
    IdArray messageId (Message messageId (Discord.Id Discord.UserId) channelId)
    -> NonemptyDict (Discord.Id Discord.UserId) { a | messagesSent : Int }
    -> NonemptyDict (Discord.Id Discord.UserId) { a | messagesSent : Int }
addMessagesSent messages members =
    IdArray.foldl
        (\message members2 ->
            case message of
                UserTextMessage message2 ->
                    NonemptyDict.updateIfExists
                        message2.createdBy
                        (\a -> { a | messagesSent = a.messagesSent + 1 })
                        members2

                EncryptedUserTextMessage message2 ->
                    NonemptyDict.updateIfExists
                        message2.createdBy
                        (\a -> { a | messagesSent = a.messagesSent + 1 })
                        members2

                UserJoinedMessage _ _ _ _ ->
                    members2

                DeletedMessage _ ->
                    members2

                CallStarted _ ->
                    members2

                GameStarted _ ->
                    members2
        )
        members
        messages


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
                Just { fileHash, metadata } ->
                    ( SeqDict.insert
                        fileId
                        { fileData = DiscordSync.attachmentsToFileData attachment fileHash metadata
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
                                        (FileStatus.uploadResponseMetadata uploadResponse)
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
                                { fileHash = uploadResponse.fileHash
                                , metadata = FileStatus.uploadResponseMetadata uploadResponse
                                }
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


maxConnectionsPerSession : Int
maxConnectionsPerSession =
    5


{-| Lamdera.onDisconnect doesn't always fire, which leaves connections behind that will never go
away on their own. Until that's fixed, a session that has more than maxConnectionsPerSession
connections gets its oldest ones disconnected.
-}
staleConnections : SessionId -> SeqDict SessionId (NonemptyDict ClientId ConnectionData) -> List ClientId
staleConnections sessionId connections =
    case SeqDict.get sessionId connections of
        Just clients ->
            -- NonemptyDict.toList is ordered oldest first
            NonemptyDict.toList clients
                |> List.map Tuple.first
                |> List.take (NonemptyDict.size clients - maxConnectionsPerSession)

        Nothing ->
            []


disconnectClient : Time.Posix -> SessionId -> ClientId -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend msg )
disconnectClient time sessionId clientId model =
    case ( Pages.Admin.disconnectClient sessionId clientId model.connections, SeqDict.get sessionId model.sessions ) of
        ( Ok ( removedConnection, connections ), Just session ) ->
            let
                model2 =
                    case removedConnection.call of
                        ConnectedToCall (Call.DmRoomId id) ->
                            let
                                dmChannelId =
                                    DmChannelId.fromUserIds session.userId id.otherUserId
                            in
                            { model
                                | connections = connections
                                , dmChannels =
                                    if dmVoiceChatRoomHasOtherMembers dmChannelId clientId model then
                                        model.dmChannels

                                    else
                                        SeqDict.updateIfExists dmChannelId (LocalState.markCallMessageAsEndedBackend time) model.dmChannels
                            }

                        ConnectedToCall (Call.GuildRoomId id) ->
                            { model
                                | connections = connections
                                , guilds =
                                    if guildVoiceChatRoomHasOtherMembers id clientId model then
                                        model.guilds

                                    else
                                        SeqDict.updateIfExists
                                            id.guildId
                                            (\guild ->
                                                { guild
                                                    | channels =
                                                        SeqDict.updateIfExists
                                                            id.channelId
                                                            (LocalState.markCallMessageAsEndedBackend time)
                                                            guild.channels
                                                }
                                            )
                                            model.guilds
                            }

                        NotInCall ->
                            { model | connections = connections }

                model3 : BackendModel
                model3 =
                    -- Dropping the connection is the last we hear from this device, so that's
                    -- when it was last active.
                    { model2
                        | sessions =
                            SeqDict.updateIfExists
                                sessionId
                                (\session2 -> { session2 | lastClientDisconnect = Just time })
                                model2.sessions
                    }
            in
            ( model3
            , Command.batch
                [ Broadcast.toUser
                    Nothing
                    Nothing
                    session.userId
                    (Server_ClientDisconnected session.sessionIdHash clientId time |> ServerChange)
                    model3
                , case removedConnection.call of
                    ConnectedToCall (Call.DmRoomId id) ->
                        Broadcast.toDmChannel
                            session.userId
                            id
                            (\otherUserId2 ->
                                Call.Server_Left
                                    time
                                    { roomId = Call.DmRoomId otherUserId2
                                    , otherClientId = ( session.userId, clientId )
                                    }
                                    |> Server_VoiceChatChange
                            )
                            model3

                    ConnectedToCall (Call.GuildRoomId id) ->
                        Broadcast.toGuild
                            id.guildId
                            (Call.Server_Left
                                time
                                { roomId = Call.GuildRoomId id
                                , otherClientId = ( session.userId, clientId )
                                }
                                |> Server_VoiceChatChange
                                |> ServerChange
                            )
                            model3

                    NotInCall ->
                        Command.none
                ]
            )

        ( Ok ( _, connections ), Nothing ) ->
            ( { model | connections = connections }, Command.none )

        _ ->
            ( model, Command.none )


deleteOldLogs :
    Time.Posix
    -> Array { time : Time.Posix, log : Log }
    -> Array { time : Time.Posix, log : Log }
deleteOldLogs time logs =
    Array.map
        (\log ->
            if Duration.from log.time time |> Quantity.greaterThan (Duration.days 30) then
                { log | log = Log.DeletedLog }

            else
                log
        )
        logs


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
                , lastBackup = Nothing
                , downloadBackupState = Nothing
                , scheduledExportState = Nothing
            }
    in
    { model
        | scheduledExportState =
            { baseModel = Bytes.Encode.encode (WireHelper.encodeBackendModel baseModel)
            , remainingGuilds = SeqDict.toList model.guilds
            , remainingGuildChannels = []
            , encodedGuildCount = 0
            , encodedGuilds = []
            , remainingDmChannels = SeqDict.toList model.dmChannels
            , encodedDmChannels = []
            , remainingDiscordGuilds = SeqDict.toList model.discordGuilds
            , remainingDiscordGuildChannels = []
            , encodedDiscordGuildCount = 0
            , encodedDiscordGuilds = []
            , remainingDiscordDmChannels = SeqDict.toList model.discordDmChannels
            , encodedDiscordDmChannels = []
            }
                |> Just
        , lastScheduledExportTime = Just time
    }


linkDiscordUser :
    Time.Posix
    -> ClientId
    -> Id UserId
    -> Discord.UserAuth
    -> Discord.User
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
linkDiscordUser linkedAt clientId userId auth discordUser model =
    let
        backendUser : DiscordFullUserData
        backendUser =
            { auth = auth
            , user = discordUser
            , connection = Discord.init (Time.posixToMillis linkedAt)
            , linkedTo = userId
            , icon = Nothing
            , linkedAt = linkedAt
            , isLoadingData = DiscordUserLoadingData linkedAt
            , markEverythingAsViewedOnceLoaded = True
            }
    in
    ( { model
        | discordUsers = SeqDict.insert discordUser.id (FullData backendUser) model.discordUsers
        , pendingGatewayReconnects =
            SeqDict.remove discordUser.id model.pendingGatewayReconnects
      }
    , Command.batch
        [ Lamdera.sendToFrontend clientId (LinkDiscordResponse (Ok ()))
        , Broadcast.toUser
            Nothing
            Nothing
            userId
            (Server_LinkDiscordUser
                discordUser.id
                (User.discordFullDataUserToFrontendCurrentUser model.users False backendUser backendUser.isLoadingData)
                |> ServerChange
            )
            model
        , DiscordSync.websocketCreateHandle
            "LinkDiscordUserStep1"
            (WebsocketCreatedHandleForUser discordUser.id)
            Discord.websocketGatewayUrl
        ]
    )


updateFromFrontend :
    SessionId
    -> ClientId
    -> ToBackend
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
updateFromFrontend sessionId clientId msg model =
    ( model, Task.perform (BackendGotTime sessionId clientId msg) Time.now )


discordStartThread :
    Time.Zone
    -> DiscordFullUserData
    -> DiscordBackendChannel
    -> Discord.Id Discord.ChannelId
    -> Id ChannelMessageId
    -> Discord.Id Discord.MessageId
    -> BackendModel
    -> Task BackendOnly Discord.HttpError Discord.Channel
discordStartThread timezone discordUser channel channelId threadId messageId model =
    Discord.startThreadFromMessagePayload
        (Discord.userToken discordUser.auth)
        { channelId = channelId
        , messageId = messageId
        , name =
            (case IdArray.get threadId channel.messages of
                Just message ->
                    case message of
                        UserTextMessage a ->
                            RichText.toStringWithGetter
                                timezone
                                DiscordUserData.username
                                True
                                model.discordUsers
                                SeqDict.empty
                                a.content.content

                        EncryptedUserTextMessage _ ->
                            ""

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
            )
                |> DiscordSync.threadName
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

                                session2 : UserSession
                                session2 =
                                    UserSession.setLastViewedGuild currentlyViewing session
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
                                , sessions = SeqDict.insert sessionId session2 model.sessions
                              }
                            , (case user.email of
                                UserHasEmail email ->
                                    BackendExtra.getLoginData sessionId clientId currentlyViewing session2 email user requestMessagesFor model
                                        |> Ok

                                DeletedUser ->
                                    Err ()
                              )
                                |> CheckLoginResponse (loginType model)
                                |> Lamdera.sendToFrontend clientId
                            )

                        Nothing ->
                            ( model
                            , CheckLoginResponse (loginType model) (Err ()) |> Lamdera.sendToFrontend clientId
                            )
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

        LoginWithRecoveryPasswordRequest requestMessagesFor password userAgent ->
            case ( loginType model, NonemptyDict.get Broadcast.adminUserId model.users ) of
                ( LoginWithRecoveryPassword, Just user ) ->
                    if Sha256.sha256 password == recoveryPasswordHash then
                        case user.email of
                            UserHasEmail email ->
                                let
                                    currentlyViewing : Viewing
                                    currentlyViewing =
                                        BackendExtra.requestedForToGuildOrDmId Broadcast.adminUserId requestMessagesFor

                                    session : UserSession
                                    session =
                                        UserSession.init time sessionId Broadcast.adminUserId userAgent
                                            |> UserSession.setLastViewedGuild currentlyViewing
                                in
                                ( { model
                                    | sessions = SeqDict.insert sessionId session model.sessions
                                    , pendingLogins = SeqDict.remove sessionId model.pendingLogins
                                  }
                                , Command.batch
                                    [ BackendExtra.getLoginData
                                        sessionId
                                        clientId
                                        currentlyViewing
                                        session
                                        email
                                        user
                                        requestMessagesFor
                                        model
                                        |> LoginSuccess
                                        |> LoginWithTokenResponse
                                        |> Lamdera.sendToFrontends sessionId
                                    , Broadcast.toUser
                                        (Just clientId)
                                        Nothing
                                        Broadcast.adminUserId
                                        (Server_NewSession
                                            session.sessionIdHash
                                            { notificationMode = session.notificationMode
                                            , currentlyViewing = SeqDict.singleton clientId currentlyViewing
                                            , userAgent = session.userAgent
                                            , lastActiveAt = time
                                            }
                                            |> ServerChange
                                        )
                                        model
                                    ]
                                )

                            DeletedUser ->
                                ( model, UserIsDeleted |> LoginWithTokenResponse |> Lamdera.sendToFrontend clientId )

                    else
                        ( model
                        , RecoveryPasswordInvalid |> LoginWithTokenResponse |> Lamdera.sendToFrontend clientId
                        )

                _ ->
                    ( model
                    , RecoveryPasswordInvalid |> LoginWithTokenResponse |> Lamdera.sendToFrontend clientId
                    )

        FinishUserCreationRequest requestMessagesFor personName userAgent ->
            case SeqDict.get sessionId model.pendingLogins of
                Just (WaitingForUserDataForSignup pendingLogin) ->
                    if
                        NonemptyDict.values model.users
                            |> List.Nonempty.any (\a -> a.email == UserHasEmail pendingLogin.emailAddress)
                    then
                        -- It's maybe possible to end up here if a user initiates two account creations for the same email address and then completes both. We'll just silently fail in that case, not worth the effort to give a good error message.
                        ( model, Command.none )

                    else
                        let
                            userId : Id UserId
                            userId =
                                Id.nextId (NonemptyDict.toSeqDict model.users)

                            currentlyViewing : Viewing
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
                                User.init time personName (UserHasEmail pendingLogin.emailAddress) False

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
                            pendingLogin.emailAddress
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
                                    case user.email of
                                        UserHasEmail email ->
                                            let
                                                currentlyViewing : Viewing
                                                currentlyViewing =
                                                    BackendExtra.requestedForToGuildOrDmId pendingLogin.userId requestMessagesFor

                                                session : UserSession
                                                session =
                                                    UserSession.init time sessionId pendingLogin.userId userAgent
                                                        |> UserSession.setLastViewedGuild currentlyViewing
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
                                                    email
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
                                                        , lastActiveAt = time
                                                        }
                                                        |> ServerChange
                                                    )
                                                    model
                                                ]
                                            )

                                        DeletedUser ->
                                            ( model, UserIsDeleted |> LoginWithTokenResponse |> Lamdera.sendToFrontend clientId )

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
            let
                ( model3, result ) =
                    BackendExtra.getLoginCode time model
            in
            case
                ( NonemptyDict.toList model3.users
                    |> List.Extra.find (\( _, user ) -> user.email == UserHasEmail email)
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
                        , BackendExtra.sendLoginEmail (SentLoginEmail time email) email loginCode model3.postmarkApiKey
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
                                        , emailAddress = email
                                        , loginCode = loginCode
                                        }
                                    )
                                    model3.pendingLogins
                          }
                        , BackendExtra.sendLoginEmail (SentLoginEmail time email) email loginCode model3.postmarkApiKey
                        )

                    else
                        ( model3, Lamdera.sendToFrontend clientId SignupsDisabledResponse )

                ( _, Err () ) ->
                    ( model3, Command.none )

        AdminToBackend adminToBackend ->
            BackendExtra.asAdmin
                model
                sessionId
                (\_ _ -> updateFromFrontendAdmin time clientId adminToBackend model)

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

                Local_SendMessage _ timezone guildOrDmId text threadRoute attachedFiles emojis ->
                    if String.Nonempty.length text > RichText.maxLength then
                        ( model, BackendExtra.invalidChangeResponse changeId clientId )

                    else
                        case guildOrDmId of
                            GuildOrDmId_Guild id ->
                                BackendExtra.asGuildMember
                                    model
                                    sessionId
                                    id.guildId
                                    (BackendExtra.sendGuildMessage
                                        model
                                        time
                                        timezone
                                        clientId
                                        changeId
                                        id
                                        threadRoute
                                        text
                                        (BackendExtra.validateAttachedFiles model.files attachedFiles)
                                        emojis
                                    )

                            GuildOrDmId_Dm id ->
                                BackendExtra.asDmUser
                                    model
                                    sessionId
                                    id
                                    (BackendExtra.sendDm
                                        model
                                        time
                                        timezone
                                        clientId
                                        changeId
                                        id.otherUserId
                                        threadRoute
                                        text
                                        (BackendExtra.validateAttachedFiles model.files attachedFiles)
                                        emojis
                                    )

                Local_Discord_SendMessage _ timezone guildOrDmId text threadRouteWithMaybeReplyTo attachedFiles ->
                    case guildOrDmId of
                        DiscordGuildOrDmId_Guild id ->
                            BackendExtra.asDiscordGuildChannelMember
                                model
                                sessionId
                                id
                                (\_ discordUser _ guild channel ->
                                    case RateLimit.checkAndUpdateRateLimit time discordUser.linkedTo model.sendMessageRateLimits of
                                        Ok sendMessageRateLimits ->
                                            let
                                                attachedFiles2 : SeqDict (Id FileId) FileData
                                                attachedFiles2 =
                                                    BackendExtra.validateAttachedFiles model.files attachedFiles

                                                guildMembers : SeqDict (Discord.Id Discord.UserId) { name : PersonName }
                                                guildMembers =
                                                    DiscordUserData.names (MembersAndOwner.membersAndOwner guild.membersAndOwner) model.discordUsers

                                                richText : Nonempty (RichText (Discord.Id Discord.UserId) (Discord.Id Discord.ChannelId))
                                                richText =
                                                    RichText.fromNonemptyString timezone guildMembers (LocalState.guildChannelNames timezone guildMembers guild.channels) text
                                            in
                                            case
                                                ( RichText.toDiscord model.discordCustomEmojis guild.channels richText
                                                , threadRouteWithMaybeReplyTo
                                                )
                                            of
                                                ( Ok discordText, NoThreadWithMaybeMessage maybeReplyTo ) ->
                                                    ( { model
                                                        | pendingDiscordCreateMessages =
                                                            SeqDict.insert
                                                                ( id.currentUserId, id.channelId )
                                                                ( clientId, changeId, timezone )
                                                                model.pendingDiscordCreateMessages
                                                        , sendMessageRateLimits = sendMessageRateLimits
                                                      }
                                                    , DiscordSync.sendMessage
                                                        model.serverSecret
                                                        discordUser
                                                        id.channelId
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
                                                                id.guildId
                                                                id.channelId
                                                                threadRouteWithMaybeReplyTo
                                                                id.currentUserId
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
                                                                        ( id.currentUserId, discordThreadId )
                                                                        ( clientId, changeId, timezone )
                                                                        model.pendingDiscordCreateMessages
                                                                , sendMessageRateLimits = sendMessageRateLimits
                                                              }
                                                            , (case SeqDict.get threadId channel.threads of
                                                                Just _ ->
                                                                    Task.succeed ()

                                                                Nothing ->
                                                                    discordStartThread
                                                                        timezone
                                                                        discordUser
                                                                        channel
                                                                        id.channelId
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
                                                                        id.guildId
                                                                        id.channelId
                                                                        threadRouteWithMaybeReplyTo
                                                                        id.currentUserId
                                                                    )
                                                            )

                                                        _ ->
                                                            ( model, BackendExtra.invalidChangeResponse changeId clientId )

                                                ( Err _, _ ) ->
                                                    ( model, BackendExtra.invalidChangeResponse changeId clientId )

                                        Err _ ->
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
                                                richText : Nonempty (RichText (Discord.Id Discord.UserId) (Discord.Id Discord.ChannelId))
                                                richText =
                                                    RichText.fromNonemptyString
                                                        timezone
                                                        (DiscordUserData.names (NonemptyDict.keys dmChannel.members |> List.Nonempty.toList) model.discordUsers)
                                                        SeqDict.empty
                                                        text
                                            in
                                            case
                                                ( RichText.toDiscord model.discordCustomEmojis SeqDict.empty richText
                                                  -- Sending messages in a DM channel the linked account has barely
                                                  -- used is likely to trigger Discord's spam bot heuristics
                                                , LocalState.sentEnoughDiscordDmMessages data.currentUserId dmChannel
                                                )
                                            of
                                                ( Ok discordText, True ) ->
                                                    ( { model
                                                        | pendingDiscordCreateDmMessages =
                                                            SeqDict.insert
                                                                data
                                                                ( clientId, changeId, timezone )
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

                                                _ ->
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

                Local_EditGuildName guildId guildName ->
                    BackendExtra.asGuildOwner
                        model
                        sessionId
                        guildId
                        (\_ _ guild ->
                            ( { model
                                | guilds =
                                    SeqDict.insert
                                        guildId
                                        (LocalState.editGuildName guildName guild)
                                        model.guilds
                              }
                            , Command.batch
                                [ LocalChangeResponse changeId localMsg
                                    |> Lamdera.sendToFrontend clientId
                                , Broadcast.toGuildExcludingOne
                                    clientId
                                    guildId
                                    (Server_EditGuildName guildId guildName |> ServerChange)
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

                Local_LeaveGuild guildId ->
                    BackendExtra.asGuildMember
                        model
                        sessionId
                        guildId
                        (\session _ guild ->
                            if MembersAndOwner.owner guild.membersAndOwner == session.userId then
                                ( model, BackendExtra.invalidChangeResponse changeId clientId )

                            else
                                ( { model
                                    | guilds =
                                        SeqDict.insert
                                            guildId
                                            { guild
                                                | membersAndOwner =
                                                    MembersAndOwner.removeMember
                                                        session.userId
                                                        guild.membersAndOwner
                                            }
                                            model.guilds
                                  }
                                , Command.batch
                                    [ LocalChangeResponse changeId localMsg
                                        |> Lamdera.sendToFrontend clientId
                                    , Broadcast.toGuildExcludingOne
                                        clientId
                                        guildId
                                        (Server_MemberLeft session.userId guildId |> ServerChange)
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

                Local_BanMember guildId userId ->
                    BackendExtra.asGuildOwner
                        model
                        sessionId
                        guildId
                        (\_ _ guild ->
                            case MembersAndOwner.isMember userId guild.membersAndOwner of
                                MembersAndOwner.IsMember ->
                                    ( { model
                                        | guilds =
                                            SeqDict.insert guildId (LocalState.banMember userId guild) model.guilds
                                      }
                                    , Command.batch
                                        [ LocalChangeResponse changeId localMsg
                                            |> Lamdera.sendToFrontend clientId
                                        , Broadcast.toGuildExcludingOne
                                            clientId
                                            guildId
                                            (Server_MemberLeft userId guildId |> ServerChange)
                                            model
                                        ]
                                    )

                                MembersAndOwner.IsOwner ->
                                    ( model, BackendExtra.invalidChangeResponse changeId clientId )

                                MembersAndOwner.IsNotMember ->
                                    ( model, BackendExtra.invalidChangeResponse changeId clientId )
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
                        GuildOrDmId (GuildOrDmId_Guild id) ->
                            BackendExtra.asGuildMember
                                model
                                sessionId
                                id.guildId
                                (\{ userId } _ guild ->
                                    ( { model
                                        | guilds =
                                            SeqDict.insert
                                                id.guildId
                                                (LocalState.memberIsTyping userId time id.channelId threadRoute guild)
                                                model.guilds
                                      }
                                    , Command.batch
                                        [ Local_MemberTyping time ( guildOrDmId, threadRoute )
                                            |> LocalChangeResponse changeId
                                            |> Lamdera.sendToFrontend clientId
                                        , Broadcast.toGuildExcludingOne
                                            clientId
                                            id.guildId
                                            (Server_MemberTyping time userId (GuildOrDmId_Guild id) threadRoute
                                                |> ServerChange
                                            )
                                            model
                                        ]
                                    )
                                )

                        GuildOrDmId (GuildOrDmId_Dm id) ->
                            BackendExtra.asDmUser
                                model
                                sessionId
                                id
                                (\session _ _ dmChannelId _ ->
                                    ( { model
                                        | dmChannels =
                                            SeqDict.updateIfExists
                                                dmChannelId
                                                (LocalState.dmMemberIsTyping session.userId time threadRoute)
                                                model.dmChannels
                                      }
                                    , Command.batch
                                        [ Local_MemberTyping time ( guildOrDmId, threadRoute )
                                            |> LocalChangeResponse changeId
                                            |> Lamdera.sendToFrontend clientId
                                        , Broadcast.toUser
                                            (Just clientId)
                                            Nothing
                                            id.otherUserId
                                            (Server_MemberTyping
                                                time
                                                session.userId
                                                (GuildOrDmId_Dm { otherUserId = session.userId })
                                                threadRoute
                                                |> ServerChange
                                            )
                                            model
                                        ]
                                    )
                                )

                        DiscordGuildOrDmId (DiscordGuildOrDmId_Guild id) ->
                            BackendExtra.asDiscordGuildChannelMember
                                model
                                sessionId
                                id
                                (\_ userData _ guild channel ->
                                    let
                                        discordChannelId : Maybe (Discord.Id Discord.ChannelId)
                                        discordChannelId =
                                            case threadRoute of
                                                NoThread ->
                                                    Just id.channelId

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
                                                id.guildId
                                                (LocalState.memberIsTyping id.currentUserId time id.channelId threadRoute guild)
                                                model.discordGuilds
                                      }
                                    , Command.batch
                                        [ Local_MemberTyping time ( guildOrDmId, threadRoute )
                                            |> LocalChangeResponse changeId
                                            |> Lamdera.sendToFrontend clientId
                                        , Broadcast.toDiscordGuildChannelExcludingOne
                                            clientId
                                            id.guildId
                                            id.channelId
                                            (Server_DiscordGuildMemberTyping
                                                time
                                                id.currentUserId
                                                id.guildId
                                                id.channelId
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
                                )

                        DiscordGuildOrDmId (DiscordGuildOrDmId_Dm id) ->
                            BackendExtra.asDiscordDmUser
                                model
                                sessionId
                                id
                                (\_ userData _ dmChannel ->
                                    ( { model
                                        | discordDmChannels =
                                            SeqDict.insert
                                                id.channelId
                                                (LocalState.discordDmMemberIsTyping id.currentUserId time dmChannel)
                                                model.discordDmChannels
                                      }
                                    , Command.batch
                                        [ Local_MemberTyping time ( guildOrDmId, threadRoute )
                                            |> LocalChangeResponse changeId
                                            |> Lamdera.sendToFrontend clientId
                                        , Broadcast.toDiscordDmChannelExcludingOne
                                            clientId
                                            id.channelId
                                            (Server_DiscordDmMemberTyping time id.currentUserId id.channelId
                                                |> ServerChange
                                            )
                                            model
                                        , Discord.triggerTypingIndicatorPayload
                                            (Discord.userToken userData.auth)
                                            (Discord.idToUInt64 id.channelId |> Discord.idFromUInt64)
                                            |> DiscordSync.http model.serverSecret
                                            |> Task.attempt (\_ -> DiscordTypingIndicatorSent)
                                        ]
                                    )
                                )

                        SlackGuildOrDmId _ ->
                            ( model, BackendExtra.invalidChangeResponse changeId clientId )

                Local_AddReactionEmoji guildOrDmId threadRoute emoji ->
                    case guildOrDmId of
                        GuildOrDmId (GuildOrDmId_Guild id) ->
                            BackendExtra.asGuildMember
                                model
                                sessionId
                                id.guildId
                                (\{ userId } user guild ->
                                    ( { model
                                        | guilds =
                                            SeqDict.insert
                                                id.guildId
                                                (LocalState.updateChannel (LocalState.addReactionEmoji emoji userId threadRoute) id.channelId guild)
                                                model.guilds
                                        , users = NonemptyDict.insert userId (User.addRecentlyUsedEmoji emoji user) model.users
                                      }
                                    , Command.batch
                                        [ Lamdera.sendToFrontend clientId (LocalChangeResponse changeId localMsg)
                                        , Broadcast.toGuild
                                            id.guildId
                                            (Server_AddReactionEmoji userId (GuildOrDmId_Guild id) threadRoute emoji |> ServerChange)
                                            model
                                        ]
                                    )
                                )

                        GuildOrDmId (GuildOrDmId_Dm id) ->
                            BackendExtra.asDmUser
                                model
                                sessionId
                                id
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
                                            id
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

                        DiscordGuildOrDmId (DiscordGuildOrDmId_Guild id) ->
                            BackendExtra.asDiscordGuildChannelMember
                                model
                                sessionId
                                id
                                (\session userData user guild channel ->
                                    case emojiOrCustomEmojiToDiscord model.discordCustomEmojis emoji of
                                        Ok discordEmoji ->
                                            ( { model
                                                | discordGuilds =
                                                    SeqDict.insert
                                                        id.guildId
                                                        (LocalState.updateChannel
                                                            (LocalState.addReactionEmoji emoji id.currentUserId threadRoute)
                                                            id.channelId
                                                            guild
                                                        )
                                                        model.discordGuilds
                                                , users = NonemptyDict.insert session.userId (User.addRecentlyUsedEmoji emoji user) model.users
                                              }
                                            , Command.batch
                                                [ Lamdera.sendToFrontend clientId (LocalChangeResponse changeId localMsg)
                                                , Broadcast.toDiscordGuildChannelExcludingOne
                                                    clientId
                                                    id.guildId
                                                    id.channelId
                                                    (Server_DiscordAddReactionGuildEmoji id.currentUserId id.guildId id.channelId threadRoute emoji
                                                        |> ServerChange
                                                    )
                                                    model
                                                , case threadRouteToDiscordMessageId id.channelId channel threadRoute of
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
                                                                    id.guildId
                                                                    id.channelId
                                                                    threadRoute
                                                                    discordMessageId
                                                                    emoji
                                                                )

                                                    Nothing ->
                                                        Command.none
                                                ]
                                            )

                                        Err _ ->
                                            ( model, BackendExtra.invalidChangeResponse changeId clientId )
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

                        SlackGuildOrDmId slackGuildOrDmId ->
                            asSlackConversationUser
                                model
                                sessionId
                                slackGuildOrDmId
                                (\session slackUser slackChannelId ->
                                    case
                                        ( slackReactionName emoji
                                        , updateSlackConversation
                                            slackGuildOrDmId
                                            (\conversation ->
                                                slackMessageTs threadRoute conversation
                                                    |> Maybe.map (\ts -> ( LocalState.addReactionEmoji emoji slackUser.user.id threadRoute conversation, ts ))
                                            )
                                            model
                                        )
                                    of
                                        ( Just name, Just ( model2, ts ) ) ->
                                            let
                                                model3 : BackendModel
                                                model3 =
                                                    { model2 | users = NonemptyDict.updateIfExists session.userId (User.addRecentlyUsedEmoji emoji) model2.users }
                                            in
                                            ( model3
                                            , Command.batch
                                                [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                                                , Broadcast.toSlackExcludingOne
                                                    clientId
                                                    slackGuildOrDmId
                                                    (Server_Slack_AddReactionEmoji slackUser.user.id slackGuildOrDmId threadRoute emoji |> ServerChange)
                                                    model3
                                                , Slack.addReaction model3.serverSecret slackUser.cookie slackUser.token slackChannelId ts name
                                                    |> Task.attempt (SlackChangedReaction time slackGuildOrDmId)
                                                ]
                                            )

                                        ( Just _, Nothing ) ->
                                            ( model, BackendExtra.invalidChangeResponse changeId clientId )

                                        ( Nothing, Just _ ) ->
                                            ( model, BackendExtra.invalidChangeResponse changeId clientId )

                                        ( Nothing, Nothing ) ->
                                            ( model, BackendExtra.invalidChangeResponse changeId clientId )
                                )

                Local_RemoveReactionEmoji guildOrDmId threadRoute emoji ->
                    case guildOrDmId of
                        GuildOrDmId (GuildOrDmId_Guild id) ->
                            BackendExtra.asGuildMember
                                model
                                sessionId
                                id.guildId
                                (\{ userId } _ guild ->
                                    ( { model
                                        | guilds =
                                            SeqDict.insert
                                                id.guildId
                                                (LocalState.updateChannel
                                                    (LocalState.removeReactionEmoji emoji userId threadRoute)
                                                    id.channelId
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
                                            id.guildId
                                            (Server_RemoveReactionEmoji
                                                userId
                                                (GuildOrDmId_Guild id)
                                                threadRoute
                                                emoji
                                                |> ServerChange
                                            )
                                            model
                                        ]
                                    )
                                )

                        GuildOrDmId (GuildOrDmId_Dm id) ->
                            BackendExtra.asDmUser
                                model
                                sessionId
                                id
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
                                            id
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

                        DiscordGuildOrDmId (DiscordGuildOrDmId_Guild id) ->
                            BackendExtra.asDiscordGuildChannelMember
                                model
                                sessionId
                                id
                                (\_ userData _ guild channel ->
                                    case emojiOrCustomEmojiToDiscord model.discordCustomEmojis emoji of
                                        Ok discordEmoji ->
                                            ( { model
                                                | discordGuilds =
                                                    SeqDict.insert
                                                        id.guildId
                                                        (LocalState.updateChannel
                                                            (LocalState.removeReactionEmoji emoji id.currentUserId threadRoute)
                                                            id.channelId
                                                            guild
                                                        )
                                                        model.discordGuilds
                                              }
                                            , Command.batch
                                                [ Lamdera.sendToFrontend clientId (LocalChangeResponse changeId localMsg)
                                                , Broadcast.toDiscordGuildChannelExcludingOne
                                                    clientId
                                                    id.guildId
                                                    id.channelId
                                                    (Server_DiscordRemoveReactionGuildEmoji
                                                        id.currentUserId
                                                        id.guildId
                                                        id.channelId
                                                        threadRoute
                                                        emoji
                                                        |> ServerChange
                                                    )
                                                    model
                                                , case threadRouteToDiscordMessageId id.channelId channel threadRoute of
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
                                                                    id.guildId
                                                                    id.channelId
                                                                    threadRoute
                                                                    discordMessageId
                                                                    emoji
                                                                )

                                                    Nothing ->
                                                        Command.none
                                                ]
                                            )

                                        Err _ ->
                                            ( model, BackendExtra.invalidChangeResponse changeId clientId )
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

                        SlackGuildOrDmId slackGuildOrDmId ->
                            asSlackConversationUser
                                model
                                sessionId
                                slackGuildOrDmId
                                (\_ slackUser slackChannelId ->
                                    case
                                        ( slackReactionName emoji
                                        , updateSlackConversation
                                            slackGuildOrDmId
                                            (\conversation ->
                                                slackMessageTs threadRoute conversation
                                                    |> Maybe.map (\ts -> ( LocalState.removeReactionEmoji emoji slackUser.user.id threadRoute conversation, ts ))
                                            )
                                            model
                                        )
                                    of
                                        ( Just name, Just ( model2, ts ) ) ->
                                            ( model2
                                            , Command.batch
                                                [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                                                , Broadcast.toSlackExcludingOne
                                                    clientId
                                                    slackGuildOrDmId
                                                    (Server_Slack_RemoveReactionEmoji slackUser.user.id slackGuildOrDmId threadRoute emoji |> ServerChange)
                                                    model2
                                                , Slack.removeReaction model2.serverSecret slackUser.cookie slackUser.token slackChannelId ts name
                                                    |> Task.attempt (SlackChangedReaction time slackGuildOrDmId)
                                                ]
                                            )

                                        ( Just _, Nothing ) ->
                                            ( model, BackendExtra.invalidChangeResponse changeId clientId )

                                        ( Nothing, Just _ ) ->
                                            ( model, BackendExtra.invalidChangeResponse changeId clientId )

                                        ( Nothing, Nothing ) ->
                                            ( model, BackendExtra.invalidChangeResponse changeId clientId )
                                )

                Local_SendEditMessage _ timezone guildOrDmId threadRoute newContent attachedFiles ->
                    if String.Nonempty.length newContent > RichText.maxLength then
                        ( model, BackendExtra.invalidChangeResponse changeId clientId )

                    else
                        let
                            attachedFiles2 : SeqDict (Id FileId) FileData
                            attachedFiles2 =
                                BackendExtra.validateAttachedFiles model.files attachedFiles
                        in
                        case guildOrDmId of
                            GuildOrDmId_Guild id ->
                                BackendExtra.asGuildMember
                                    model
                                    sessionId
                                    id.guildId
                                    (\{ userId } _ guild ->
                                        sendEditMessage
                                            clientId
                                            changeId
                                            time
                                            timezone
                                            newContent
                                            attachedFiles2
                                            id
                                            threadRoute
                                            model
                                            userId
                                            guild
                                    )

                            GuildOrDmId_Dm id ->
                                BackendExtra.asDmUser
                                    model
                                    sessionId
                                    id
                                    (\session user otherUser dmChannelId dmChannel ->
                                        let
                                            richText : Nonempty (RichText (Id UserId) (Id ChannelId))
                                            richText =
                                                RichText.fromNonemptyString
                                                    timezone
                                                    (SeqDict.fromList
                                                        [ ( session.userId, user )
                                                        , ( id.otherUserId, otherUser )
                                                        ]
                                                    )
                                                    SeqDict.empty
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
                                                    | dmChannels =
                                                        SeqDict.insert
                                                            dmChannelId
                                                            { dmChannel2
                                                                | lastTypedAt =
                                                                    LocalState.dmForgetEditTyping session.userId threadRoute dmChannel2.lastTypedAt
                                                            }
                                                            model.dmChannels
                                                  }
                                                , Command.batch
                                                    [ Local_SendEditMessage
                                                        time
                                                        timezone
                                                        guildOrDmId
                                                        threadRoute
                                                        newContent
                                                        attachedFiles2
                                                        |> LocalChangeResponse changeId
                                                        |> Lamdera.sendToFrontend clientId
                                                    , Broadcast.toDmChannelExcludingOne
                                                        clientId
                                                        session.userId
                                                        id
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

                Local_Discord_SendEditGuildMessage _ timezone currentUserId guildId channelId threadRoute newContent ->
                    BackendExtra.asDiscordGuildChannelMember
                        model
                        sessionId
                        { guildId = guildId, channelId = channelId, currentUserId = currentUserId }
                        (\_ userData _ guild channel ->
                            let
                                guildMembers : SeqDict (Discord.Id Discord.UserId) { name : PersonName }
                                guildMembers =
                                    DiscordUserData.names (MembersAndOwner.membersAndOwner guild.membersAndOwner) model.discordUsers

                                richText : Nonempty (RichText (Discord.Id Discord.UserId) (Discord.Id Discord.ChannelId))
                                richText =
                                    RichText.fromNonemptyString timezone guildMembers (LocalState.guildChannelNames timezone guildMembers guild.channels) newContent
                            in
                            case
                                ( RichText.toDiscord model.discordCustomEmojis guild.channels richText
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
                                            SeqDict.insert
                                                guildId
                                                { guild
                                                    | channels = SeqDict.insert channelId channel2 guild.channels
                                                    , lastTypedAt =
                                                        LocalState.forgetEditTyping currentUserId channelId threadRoute guild.lastTypedAt
                                                }
                                                model.discordGuilds
                                      }
                                    , Command.batch
                                        [ Local_Discord_SendEditGuildMessage
                                            time
                                            timezone
                                            currentUserId
                                            guildId
                                            channelId
                                            threadRoute
                                            newContent
                                            |> LocalChangeResponse changeId
                                            |> Lamdera.sendToFrontend clientId
                                        , Broadcast.toDiscordGuildChannelExcludingOne
                                            clientId
                                            guildId
                                            channelId
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
                                    ( model, BackendExtra.invalidChangeResponse changeId clientId )
                        )

                Local_Discord_SendEditDmMessage _ timezone dmData messageId newContent ->
                    BackendExtra.asDiscordDmUser
                        model
                        sessionId
                        dmData
                        (\_ userData _ channel ->
                            let
                                richText : Nonempty (RichText (Discord.Id Discord.UserId) (Discord.Id Discord.ChannelId))
                                richText =
                                    RichText.fromNonemptyString
                                        timezone
                                        (DiscordUserData.names (NonemptyDict.keys channel.members |> List.Nonempty.toList) model.discordUsers)
                                        SeqDict.empty
                                        newContent
                            in
                            case
                                ( RichText.toDiscord model.discordCustomEmojis SeqDict.empty richText
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
                                            SeqDict.insert
                                                dmData.channelId
                                                { channel2
                                                    | lastTypedAt =
                                                        LocalState.discordDmForgetEditTyping dmData.currentUserId messageId channel2.lastTypedAt
                                                }
                                                model.discordDmChannels
                                      }
                                    , Command.batch
                                        [ Local_Discord_SendEditDmMessage time timezone dmData messageId newContent
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
                        GuildOrDmId (GuildOrDmId_Guild { guildId, channelId }) ->
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

                        GuildOrDmId (GuildOrDmId_Dm id) ->
                            BackendExtra.asDmUser
                                model
                                sessionId
                                id
                                (\{ userId } _ _ dmChannelId dmChannel ->
                                    case LocalState.dmMemberIsEditTypingBackend time userId threadRoute dmChannel of
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
                                                    id.otherUserId
                                                    (Server_MemberEditTyping
                                                        time
                                                        userId
                                                        (GuildOrDmId (GuildOrDmId_Dm { otherUserId = userId }))
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

                        DiscordGuildOrDmId (DiscordGuildOrDmId_Guild id) ->
                            BackendExtra.asDiscordGuildChannelMember
                                model
                                sessionId
                                id
                                (\session _ _ guild _ ->
                                    case LocalState.memberIsEditTypingBackend id.currentUserId time id.channelId threadRoute guild of
                                        Ok guild2 ->
                                            ( { model | discordGuilds = SeqDict.insert id.guildId guild2 model.discordGuilds }
                                            , Command.batch
                                                [ Local_MemberEditTyping time guildOrDmId threadRoute
                                                    |> LocalChangeResponse changeId
                                                    |> Lamdera.sendToFrontend clientId
                                                , Broadcast.toDiscordGuildChannelExcludingOne
                                                    clientId
                                                    id.guildId
                                                    id.channelId
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
                                                LocalState.discordDmMemberIsEditTypingBackend
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

                        SlackGuildOrDmId _ ->
                            ( model, BackendExtra.invalidChangeResponse changeId clientId )

                Local_SetLastViewed guildOrDmId threadRoute ->
                    let
                        helper : UserSession -> BackendUser -> ( BackendModel, Command BackendOnly ToFrontend msg )
                        helper session user =
                            ( { model
                                | users =
                                    NonemptyDict.insert
                                        session.userId
                                        (User.setLastViewedMessage guildOrDmId threadRoute user)
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
                        GuildOrDmId (GuildOrDmId_Guild { guildId }) ->
                            BackendExtra.asGuildMember model sessionId guildId (\session user _ -> helper session user)

                        GuildOrDmId (GuildOrDmId_Dm id) ->
                            BackendExtra.asDmUser
                                model
                                sessionId
                                id
                                (\session user _ _ _ -> helper session user)

                        DiscordGuildOrDmId (DiscordGuildOrDmId_Guild id) ->
                            BackendExtra.asDiscordGuildChannelMember_AllowUserThatNeedsAuthAgain
                                model
                                sessionId
                                clientId
                                id
                                (\session _ _ user _ _ -> helper session user)

                        DiscordGuildOrDmId (DiscordGuildOrDmId_Dm data) ->
                            BackendExtra.asDiscordDmUser_AllowUserThatNeedsAuthAgain
                                model
                                sessionId
                                data
                                (\session _ user _ -> helper session user)

                        SlackGuildOrDmId (SlackGuildOrDmId_Workspace id) ->
                            BackendExtra.asSlackChannelMember
                                model
                                sessionId
                                id
                                (\session _ _ _ ->
                                    case NonemptyDict.get session.userId model.users of
                                        Just user ->
                                            helper session user

                                        Nothing ->
                                            ( model, BackendExtra.invalidChangeResponse changeId clientId )
                                )

                        SlackGuildOrDmId (SlackGuildOrDmId_Dm id) ->
                            BackendExtra.asSlackDmUser
                                model
                                sessionId
                                id
                                (\session _ _ ->
                                    case NonemptyDict.get session.userId model.users of
                                        Just user ->
                                            helper session user

                                        Nothing ->
                                            ( model, BackendExtra.invalidChangeResponse changeId clientId )
                                )

                Local_DeleteMessage guildOrDmId threadRoute ->
                    case guildOrDmId of
                        GuildOrDmId (GuildOrDmId_Guild id) ->
                            BackendExtra.asGuildMember
                                model
                                sessionId
                                id.guildId
                                (\{ userId } _ guild ->
                                    case LocalState.deleteMessageBackend userId id.channelId threadRoute guild of
                                        Ok ( guild2, _ ) ->
                                            ( { model | guilds = SeqDict.insert id.guildId guild2 model.guilds }
                                            , Command.batch
                                                [ Lamdera.sendToFrontend
                                                    clientId
                                                    (LocalChangeResponse changeId localMsg)
                                                , Broadcast.toGuildExcludingOne
                                                    clientId
                                                    id.guildId
                                                    (Server_DeleteMessage guildOrDmId threadRoute |> ServerChange)
                                                    model
                                                ]
                                            )

                                        Err _ ->
                                            ( model
                                            , BackendExtra.invalidChangeResponse changeId clientId
                                            )
                                )

                        GuildOrDmId (GuildOrDmId_Dm id) ->
                            BackendExtra.asDmUser
                                model
                                sessionId
                                id
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
                                                    id
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

                        DiscordGuildOrDmId (DiscordGuildOrDmId_Guild id) ->
                            BackendExtra.asDiscordGuildChannelMember
                                model
                                sessionId
                                id
                                (\_ userData _ guild _ ->
                                    case LocalState.deleteMessageBackend id.currentUserId id.channelId threadRoute guild of
                                        Ok ( guild2, channel ) ->
                                            ( { model | discordGuilds = SeqDict.insert id.guildId guild2 model.discordGuilds }
                                            , Command.batch
                                                [ Lamdera.sendToFrontend
                                                    clientId
                                                    (LocalChangeResponse changeId localMsg)
                                                , Broadcast.toDiscordGuildChannelExcludingOne
                                                    clientId
                                                    id.guildId
                                                    id.channelId
                                                    (Server_DeleteMessage guildOrDmId threadRoute |> ServerChange)
                                                    model
                                                , case threadRouteToDiscordMessageId id.channelId channel threadRoute of
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
                                                                    id.guildId
                                                                    id.channelId
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

                        SlackGuildOrDmId slackGuildOrDmId ->
                            asSlackConversationUser
                                model
                                sessionId
                                slackGuildOrDmId
                                (\_ slackUser slackChannelId ->
                                    case
                                        updateSlackConversation
                                            slackGuildOrDmId
                                            (\conversation ->
                                                case slackMessageTs threadRoute conversation of
                                                    Just ts ->
                                                        case deleteSlackMessage slackUser.user.id ts conversation of
                                                            ( _, [] ) ->
                                                                Nothing

                                                            ( conversation2, deleted ) ->
                                                                Just ( conversation2, ( ts, deleted ) )

                                                    Nothing ->
                                                        Nothing
                                            )
                                            model
                                    of
                                        Just ( model2, ( ts, deleted ) ) ->
                                            ( model2
                                            , Command.batch
                                                [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                                                , List.map
                                                    (\threadRoute2 ->
                                                        Broadcast.toSlack
                                                            slackGuildOrDmId
                                                            (Server_Slack_DeleteMessage slackGuildOrDmId threadRoute2 |> ServerChange)
                                                            model2
                                                    )
                                                    deleted
                                                    |> Command.batch
                                                , Slack.deleteMessage model2.serverSecret slackUser.cookie slackUser.token slackChannelId ts
                                                    |> Task.attempt (SlackDeletedMessage time slackGuildOrDmId)
                                                ]
                                            )

                                        Nothing ->
                                            ( model, BackendExtra.invalidChangeResponse changeId clientId )
                                )

                Local_CurrentlyViewing { markMessagesAsViewed } viewing ->
                    let
                        currentlyViewing : Viewing
                        currentlyViewing =
                            SetViewing.setViewingToCurrentlyViewing viewing

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
                                UserSession.Viewing_DiscordChannel data ->
                                    if guildId == data.id.guildId then
                                        SeqDict.empty

                                    else
                                        getNewUsersHelper guild

                                UserSession.Viewing_DiscordChannelThread data ->
                                    if guildId == data.id.guildId then
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
                                                (User.discordUserDataToFrontendUser model.users member)
                                                dict

                                        Nothing ->
                                            dict
                                )
                                SeqDict.empty
                                (MembersAndOwner.membersAndOwner guild.membersAndOwner)

                        connections : SeqDict SessionId (NonemptyDict ClientId ConnectionData)
                        connections =
                            SeqDict.updateIfExists
                                sessionId
                                (NonemptyDict.updateIfExists
                                    clientId
                                    (\connection2 -> { connection2 | currentlyViewing = currentlyViewing })
                                )
                                model.connections

                        sessions : SeqDict SessionId UserSession
                        sessions =
                            SeqDict.updateIfExists sessionId (UserSession.setLastViewedGuild currentlyViewing) model.sessions
                    in
                    case viewing of
                        ViewDm data _ ->
                            BackendExtra.asDmUser
                                model
                                sessionId
                                { otherUserId = data.id.otherUserId }
                                (\session user _ dmChannelId dmChannel ->
                                    ( { model
                                        | users =
                                            NonemptyDict.insert
                                                session.userId
                                                (User.setLastDmViewed
                                                    data.id
                                                    (NoThreadWithMaybeMessage
                                                        (if markMessagesAsViewed then
                                                            DmChannel.latestMessageId dmChannel |> Just

                                                         else
                                                            Nothing
                                                        )
                                                    )
                                                    user
                                                )
                                                model.users
                                        , connections = connections
                                      }
                                    , Command.batch
                                        [ ViewDm
                                            data
                                            (loadMessagesHelper dmChannel
                                                |> DmChannel.loadedMessages
                                                    (GuildOrFullDmId_Dm dmChannelId)
                                                    model.goMatchPublicIds
                                                    dmChannel
                                                |> FilledInByBackend
                                            )
                                            |> Local_CurrentlyViewing { markMessagesAsViewed = markMessagesAsViewed }
                                            |> LocalChangeResponse changeId
                                            |> Lamdera.sendToFrontend clientId
                                        , broadcastCmd session
                                        ]
                                    )
                                )

                        ViewDmThread data _ ->
                            BackendExtra.asDmUser
                                model
                                sessionId
                                { otherUserId = data.id.otherUserId }
                                (\session user _ _ dmChannel ->
                                    ( { model
                                        | users =
                                            NonemptyDict.insert
                                                session.userId
                                                (User.setLastDmViewed
                                                    { otherUserId = data.id.otherUserId }
                                                    (ViewThreadWithMaybeMessage
                                                        data.id.threadId
                                                        (if markMessagesAsViewed then
                                                            SeqDict.get data.id.threadId dmChannel.threads
                                                                |> Maybe.withDefault Thread.backendInit
                                                                |> DmChannel.latestThreadMessageId
                                                                |> Just

                                                         else
                                                            Nothing
                                                        )
                                                    )
                                                    user
                                                )
                                                model.users
                                        , connections = connections
                                      }
                                    , Command.batch
                                        [ ViewDmThread
                                            data
                                            (SeqDict.get data.id.threadId dmChannel.threads
                                                |> Maybe.withDefault Thread.backendInit
                                                |> loadMessagesHelper
                                                |> FilledInByBackend
                                            )
                                            |> Local_CurrentlyViewing { markMessagesAsViewed = markMessagesAsViewed }
                                            |> LocalChangeResponse changeId
                                            |> Lamdera.sendToFrontend clientId
                                        , broadcastCmd session
                                        ]
                                    )
                                )

                        ViewSlackChannel data _ ->
                            BackendExtra.asSlackChannelMember
                                model
                                sessionId
                                data.id
                                (\session _ _ channel ->
                                    ( { model
                                        | users =
                                            NonemptyDict.updateIfExists
                                                session.userId
                                                (User.setLastSlackChannelViewed
                                                    data.id
                                                    (NoThreadWithMaybeMessage
                                                        (if markMessagesAsViewed then
                                                            DmChannel.latestMessageId channel |> Just

                                                         else
                                                            Nothing
                                                        )
                                                    )
                                                )
                                                model.users
                                        , connections = connections
                                      }
                                    , Command.batch
                                        [ ViewSlackChannel data (loadMessagesHelper channel |> FilledInByBackend)
                                            |> Local_CurrentlyViewing { markMessagesAsViewed = markMessagesAsViewed }
                                            |> LocalChangeResponse changeId
                                            |> Lamdera.sendToFrontend clientId
                                        , broadcastCmd session
                                        ]
                                    )
                                )

                        ViewSlackDm data _ ->
                            BackendExtra.asSlackDmUser
                                model
                                sessionId
                                data.id
                                (\session _ dmChannel ->
                                    ( { model
                                        | users =
                                            if markMessagesAsViewed then
                                                NonemptyDict.updateIfExists
                                                    session.userId
                                                    (User.setLastViewedMessage
                                                        (SlackGuildOrDmId (SlackGuildOrDmId_Dm data.id))
                                                        (NoThreadWithMessage (DmChannel.latestMessageId dmChannel))
                                                    )
                                                    model.users

                                            else
                                                model.users
                                        , connections = connections
                                      }
                                    , Command.batch
                                        [ ViewSlackDm data (loadMessagesHelper dmChannel |> FilledInByBackend)
                                            |> Local_CurrentlyViewing { markMessagesAsViewed = markMessagesAsViewed }
                                            |> LocalChangeResponse changeId
                                            |> Lamdera.sendToFrontend clientId
                                        , broadcastCmd session
                                        ]
                                    )
                                )

                        ViewSlackChannelThread data _ ->
                            BackendExtra.asSlackChannelMember
                                model
                                sessionId
                                data.id
                                (\session _ _ channel ->
                                    let
                                        thread : SlackBackendThread
                                        thread =
                                            SeqDict.get data.threadId channel.threads |> Maybe.withDefault Thread.slackBackendInit
                                    in
                                    ( { model
                                        | users =
                                            NonemptyDict.updateIfExists
                                                session.userId
                                                (User.setLastSlackChannelViewed
                                                    data.id
                                                    (ViewThreadWithMaybeMessage
                                                        data.threadId
                                                        (if markMessagesAsViewed && IdArray.length thread.messages > 0 then
                                                            DmChannel.latestThreadMessageId thread |> Just

                                                         else
                                                            Nothing
                                                        )
                                                    )
                                                )
                                                model.users
                                        , connections = connections
                                      }
                                    , Command.batch
                                        [ ViewSlackChannelThread data (loadMessagesHelper thread |> FilledInByBackend)
                                            |> Local_CurrentlyViewing { markMessagesAsViewed = markMessagesAsViewed }
                                            |> LocalChangeResponse changeId
                                            |> Lamdera.sendToFrontend clientId
                                        , broadcastCmd session
                                        ]
                                    )
                                )

                        ViewSlackDmThread data _ ->
                            BackendExtra.asSlackDmUser
                                model
                                sessionId
                                data.id
                                (\session _ dmChannel ->
                                    let
                                        thread : SlackBackendThread
                                        thread =
                                            SeqDict.get data.threadId dmChannel.threads |> Maybe.withDefault Thread.slackBackendInit
                                    in
                                    ( { model
                                        | users =
                                            if markMessagesAsViewed && IdArray.length thread.messages > 0 then
                                                NonemptyDict.updateIfExists
                                                    session.userId
                                                    (User.setLastViewedMessage
                                                        (SlackGuildOrDmId (SlackGuildOrDmId_Dm data.id))
                                                        (ViewThreadWithMessage data.threadId (DmChannel.latestThreadMessageId thread))
                                                    )
                                                    model.users

                                            else
                                                model.users
                                        , connections = connections
                                      }
                                    , Command.batch
                                        [ ViewSlackDmThread data (loadMessagesHelper thread |> FilledInByBackend)
                                            |> Local_CurrentlyViewing { markMessagesAsViewed = markMessagesAsViewed }
                                            |> LocalChangeResponse changeId
                                            |> Lamdera.sendToFrontend clientId
                                        , broadcastCmd session
                                        ]
                                    )
                                )

                        ViewDiscordDm data _ ->
                            BackendExtra.asDiscordDmUser_AllowUserThatNeedsAuthAgain
                                model
                                sessionId
                                { currentUserId = data.id.currentUserId, channelId = data.id.channelId }
                                (\session _ user dmChannel ->
                                    ( { model
                                        | users =
                                            NonemptyDict.insert
                                                session.userId
                                                (User.setLastDiscordDmViewed
                                                    data.id.currentUserId
                                                    data.id.channelId
                                                    (if markMessagesAsViewed then
                                                        DmChannel.latestMessageId dmChannel |> Just

                                                     else
                                                        Nothing
                                                    )
                                                    user
                                                )
                                                model.users
                                        , connections = connections
                                      }
                                    , Command.batch
                                        [ ViewDiscordDm
                                            data
                                            (loadMessagesHelper dmChannel |> FilledInByBackend)
                                            |> Local_CurrentlyViewing { markMessagesAsViewed = markMessagesAsViewed }
                                            |> LocalChangeResponse changeId
                                            |> Lamdera.sendToFrontend clientId
                                        , broadcastCmd session
                                        ]
                                    )
                                )

                        ViewChannel data _ ->
                            BackendExtra.asGuildMember
                                model
                                sessionId
                                data.id.guildId
                                (\session user guild ->
                                    case SeqDict.get data.id.channelId guild.channels of
                                        Just channel ->
                                            ( { model
                                                | users =
                                                    NonemptyDict.insert
                                                        session.userId
                                                        (User.setLastChannelViewed
                                                            data.id
                                                            (NoThreadWithMaybeMessage
                                                                (if markMessagesAsViewed then
                                                                    DmChannel.latestMessageId channel |> Just

                                                                 else
                                                                    Nothing
                                                                )
                                                            )
                                                            user
                                                        )
                                                        model.users
                                                , connections = connections
                                                , sessions = sessions
                                              }
                                            , Command.batch
                                                [ ViewChannel
                                                    data
                                                    (loadMessagesHelper channel
                                                        |> DmChannel.loadedMessages
                                                            (GuildOrFullDmId_Guild data.id.guildId data.id.channelId)
                                                            model.goMatchPublicIds
                                                            channel
                                                        |> FilledInByBackend
                                                    )
                                                    |> Local_CurrentlyViewing { markMessagesAsViewed = markMessagesAsViewed }
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

                        ViewChannelThread data _ ->
                            BackendExtra.asGuildMember
                                model
                                sessionId
                                data.id.guildId
                                (\session user guild ->
                                    case SeqDict.get data.id.channelId guild.channels of
                                        Just channel ->
                                            ( { model
                                                | users =
                                                    NonemptyDict.insert
                                                        session.userId
                                                        (User.setLastChannelViewed
                                                            { guildId = data.id.guildId, channelId = data.id.channelId }
                                                            (ViewThreadWithMaybeMessage
                                                                data.id.threadId
                                                                (if markMessagesAsViewed then
                                                                    SeqDict.get data.id.threadId channel.threads
                                                                        |> Maybe.withDefault Thread.backendInit
                                                                        |> DmChannel.latestThreadMessageId
                                                                        |> Just

                                                                 else
                                                                    Nothing
                                                                )
                                                            )
                                                            user
                                                        )
                                                        model.users
                                                , connections = connections
                                                , sessions = sessions
                                              }
                                            , Command.batch
                                                [ ViewChannelThread
                                                    data
                                                    (SeqDict.get data.id.threadId channel.threads
                                                        |> Maybe.withDefault Thread.backendInit
                                                        |> loadMessagesHelper
                                                        |> FilledInByBackend
                                                    )
                                                    |> Local_CurrentlyViewing { markMessagesAsViewed = markMessagesAsViewed }
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
                                    ( { model | connections = connections }
                                    , Command.batch
                                        [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                                        , broadcastCmd session
                                        ]
                                    )
                                )

                        ViewDiscordChannel data _ ->
                            BackendExtra.asDiscordGuildChannelMember_AllowUserThatNeedsAuthAgain
                                model
                                sessionId
                                clientId
                                { guildId = data.id.guildId, channelId = data.id.channelId, currentUserId = data.id.currentUserId }
                                (\session connectionData _ user guild channel ->
                                    ( { model
                                        | users =
                                            NonemptyDict.insert
                                                session.userId
                                                (User.setLastDiscordChannelViewed
                                                    data.id
                                                    (NoThreadWithMaybeMessage
                                                        (if markMessagesAsViewed then
                                                            DmChannel.latestMessageId channel |> Just

                                                         else
                                                            Nothing
                                                        )
                                                    )
                                                    user
                                                )
                                                model.users
                                        , connections = connections
                                        , sessions = sessions
                                      }
                                    , Command.batch
                                        [ ViewDiscordChannel
                                            data
                                            (FilledInByBackend
                                                { messages = loadMessagesHelper channel
                                                , newUsers = getNewUsers connectionData data.id.guildId guild
                                                }
                                            )
                                            |> Local_CurrentlyViewing { markMessagesAsViewed = markMessagesAsViewed }
                                            |> LocalChangeResponse changeId
                                            |> Lamdera.sendToFrontend clientId
                                        , broadcastCmd session
                                        ]
                                    )
                                )

                        ViewDiscordChannelThread data _ ->
                            BackendExtra.asDiscordGuildChannelMember_AllowUserThatNeedsAuthAgain
                                model
                                sessionId
                                clientId
                                { guildId = data.id.guildId, channelId = data.id.channelId, currentUserId = data.id.currentUserId }
                                (\session connectionData _ user guild channel ->
                                    ( { model
                                        | users =
                                            NonemptyDict.insert
                                                session.userId
                                                (User.setLastDiscordChannelViewed
                                                    { guildId = data.id.guildId, channelId = data.id.channelId, currentUserId = data.id.currentUserId }
                                                    (ViewThreadWithMaybeMessage
                                                        data.id.threadId
                                                        (if markMessagesAsViewed then
                                                            SeqDict.get data.id.threadId channel.threads
                                                                |> Maybe.withDefault Thread.discordBackendInit
                                                                |> DmChannel.latestThreadMessageId
                                                                |> Just

                                                         else
                                                            Nothing
                                                        )
                                                    )
                                                    user
                                                )
                                                model.users
                                        , connections = connections
                                        , sessions = sessions
                                      }
                                    , Command.batch
                                        [ ViewDiscordChannelThread
                                            data
                                            (FilledInByBackend
                                                { messages =
                                                    SeqDict.get data.id.threadId channel.threads
                                                        |> Maybe.withDefault Thread.discordBackendInit
                                                        |> loadMessagesHelper
                                                , newUsers = getNewUsers connectionData data.id.guildId guild
                                                }
                                            )
                                            |> Local_CurrentlyViewing { markMessagesAsViewed = markMessagesAsViewed }
                                            |> LocalChangeResponse changeId
                                            |> Lamdera.sendToFrontend clientId
                                        , broadcastCmd session
                                        ]
                                    )
                                )

                        ViewOverview _ ->
                            BackendExtra.asUser
                                model
                                sessionId
                                (\session user ->
                                    ( { model | connections = connections }
                                    , Command.batch
                                        [ ViewOverview
                                            (BackendExtra.unreadOverviewData session.userId user model
                                                |> FilledInByBackend
                                            )
                                            |> Local_CurrentlyViewing { markMessagesAsViewed = markMessagesAsViewed }
                                            |> LocalChangeResponse changeId
                                            |> Lamdera.sendToFrontend clientId
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

                Local_LoadChannelMessages guildOrDmId pageRequest _ ->
                    case guildOrDmId of
                        GuildOrDmId_Guild { guildId, channelId } ->
                            BackendExtra.asGuildMember
                                model
                                sessionId
                                guildId
                                (\_ _ guild ->
                                    ( model
                                    , case SeqDict.get channelId guild.channels of
                                        Just channel ->
                                            handleMessagesRequest pageRequest channel
                                                |> DmChannel.loadedMessages
                                                    (GuildOrFullDmId_Guild guildId channelId)
                                                    model.goMatchPublicIds
                                                    channel
                                                |> FilledInByBackend
                                                |> Local_LoadChannelMessages guildOrDmId pageRequest
                                                |> LocalChangeResponse changeId
                                                |> Lamdera.sendToFrontend clientId

                                        Nothing ->
                                            BackendExtra.invalidChangeResponse changeId clientId
                                    )
                                )

                        GuildOrDmId_Dm id ->
                            BackendExtra.asDmUser
                                model
                                sessionId
                                id
                                (\_ _ _ dmChannelId dmChannel ->
                                    ( model
                                    , handleMessagesRequest pageRequest dmChannel
                                        |> DmChannel.loadedMessages
                                            (GuildOrFullDmId_Dm dmChannelId)
                                            model.goMatchPublicIds
                                            dmChannel
                                        |> FilledInByBackend
                                        |> Local_LoadChannelMessages guildOrDmId pageRequest
                                        |> LocalChangeResponse changeId
                                        |> Lamdera.sendToFrontend clientId
                                    )
                                )

                Local_LoadThreadMessages guildOrDmId threadId pageRequest _ ->
                    case guildOrDmId of
                        GuildOrDmId_Guild { guildId, channelId } ->
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
                                                |> handleMessagesRequest pageRequest
                                                |> FilledInByBackend
                                                |> Local_LoadThreadMessages guildOrDmId threadId pageRequest
                                                |> LocalChangeResponse changeId
                                                |> Lamdera.sendToFrontend clientId

                                        Nothing ->
                                            BackendExtra.invalidChangeResponse changeId clientId
                                    )
                                )

                        GuildOrDmId_Dm id ->
                            BackendExtra.asDmUser
                                model
                                sessionId
                                id
                                (\_ _ _ _ dmChannel ->
                                    ( model
                                    , SeqDict.get threadId dmChannel.threads
                                        |> Maybe.withDefault Thread.backendInit
                                        |> handleMessagesRequest pageRequest
                                        |> FilledInByBackend
                                        |> Local_LoadThreadMessages guildOrDmId threadId pageRequest
                                        |> LocalChangeResponse changeId
                                        |> Lamdera.sendToFrontend clientId
                                    )
                                )

                Local_Slack_LoadChannelMessages guildOrDmId pageRequest _ ->
                    case guildOrDmId of
                        SlackGuildOrDmId_Workspace id ->
                            BackendExtra.asSlackChannelMember
                                model
                                sessionId
                                id
                                (\_ _ _ channel ->
                                    ( model
                                    , handleMessagesRequest pageRequest channel
                                        |> FilledInByBackend
                                        |> Local_Slack_LoadChannelMessages guildOrDmId pageRequest
                                        |> LocalChangeResponse changeId
                                        |> Lamdera.sendToFrontend clientId
                                    )
                                )

                        SlackGuildOrDmId_Dm data ->
                            BackendExtra.asSlackDmUser
                                model
                                sessionId
                                data
                                (\_ _ channel ->
                                    ( model
                                    , handleMessagesRequest pageRequest channel
                                        |> FilledInByBackend
                                        |> Local_Slack_LoadChannelMessages guildOrDmId pageRequest
                                        |> LocalChangeResponse changeId
                                        |> Lamdera.sendToFrontend clientId
                                    )
                                )

                Local_Slack_LoadThreadMessages guildOrDmId threadId pageRequest _ ->
                    let
                        respond :
                            { a | threads : SeqDict (Id ChannelMessageId) SlackBackendThread }
                            -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
                        respond channel =
                            ( model
                            , SeqDict.get threadId channel.threads
                                |> Maybe.withDefault Thread.slackBackendInit
                                |> handleMessagesRequest pageRequest
                                |> FilledInByBackend
                                |> Local_Slack_LoadThreadMessages guildOrDmId threadId pageRequest
                                |> LocalChangeResponse changeId
                                |> Lamdera.sendToFrontend clientId
                            )
                    in
                    case guildOrDmId of
                        SlackGuildOrDmId_Workspace id ->
                            BackendExtra.asSlackChannelMember model sessionId id (\_ _ _ channel -> respond channel)

                        SlackGuildOrDmId_Dm data ->
                            BackendExtra.asSlackDmUser model sessionId data (\_ _ channel -> respond channel)

                Local_Slack_ReloadUser slackUserId ->
                    BackendExtra.asUser
                        model
                        sessionId
                        (\session _ ->
                            case SeqDict.get slackUserId model.slackUsers of
                                Just (SlackFullData linkedUser) ->
                                    if linkedUser.linkedTo == session.userId && not linkedUser.needsAuthAgain then
                                        let
                                            ( model2, refreshCmd ) =
                                                refreshSlackConversations linkedUser model
                                        in
                                        ( model2
                                        , Command.batch
                                            [ Lamdera.sendToFrontend clientId (LocalChangeResponse changeId localMsg)
                                            , refreshCmd
                                            , catchUpSlackConversations linkedUser model2
                                            , case ( linkedUser.websocket, SeqDict.member slackUserId model2.pendingSlackReconnects ) of
                                                ( Nothing, False ) ->
                                                    Websocket.createHandle (SlackWebsocketCreatedHandle slackUserId) Slack.websocketRelayUrl

                                                _ ->
                                                    Command.none
                                            ]
                                        )

                                    else
                                        ( model, BackendExtra.invalidChangeResponse changeId clientId )

                                Just (SlackBasicData _) ->
                                    ( model, BackendExtra.invalidChangeResponse changeId clientId )

                                Nothing ->
                                    ( model, BackendExtra.invalidChangeResponse changeId clientId )
                        )

                Local_Slack_UnlinkUser slackUserId ->
                    BackendExtra.asUser
                        model
                        sessionId
                        (\session _ ->
                            case SeqDict.get slackUserId model.slackUsers of
                                Just (SlackFullData linkedUser) ->
                                    if linkedUser.linkedTo == session.userId then
                                        let
                                            model2 : BackendModel
                                            model2 =
                                                SlackSync.unlinkUser slackUserId linkedUser model
                                        in
                                        ( model2
                                        , Command.batch
                                            [ Lamdera.sendToFrontend clientId (LocalChangeResponse changeId localMsg)
                                            , Broadcast.toUser
                                                (Just clientId)
                                                Nothing
                                                session.userId
                                                (Server_Slack_UnlinkUser slackUserId |> ServerChange)
                                                model2
                                            , case linkedUser.websocket of
                                                Just connection ->
                                                    Websocket.close connection |> Task.perform (\() -> SlackWebsocketClosedByBackend)

                                                Nothing ->
                                                    Command.none
                                            ]
                                        )

                                    else
                                        ( model, BackendExtra.invalidChangeResponse changeId clientId )

                                Just (SlackBasicData _) ->
                                    ( model, BackendExtra.invalidChangeResponse changeId clientId )

                                Nothing ->
                                    ( model, BackendExtra.invalidChangeResponse changeId clientId )
                        )

                Local_Slack_SendMessage _ timezone guildOrDmId threadRoute text attachedFiles ->
                    let
                        send :
                            SlackLinkedUser
                            -> SeqDict ( Slack.Id Slack.ChannelId, Maybe (Id ChannelMessageId) ) { name : String }
                            -> Slack.Id channelId
                            -> OneToOne (Slack.Id Slack.MessageId) (Id ChannelMessageId)
                            -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
                        send slackUser channelMentions slackChannelId linkedMessageIds =
                            case
                                ( RateLimit.checkAndUpdateRateLimit time slackUser.linkedTo model.sendMessageRateLimits
                                , case threadRoute of
                                    ViewThread threadId ->
                                        OneToOne.first threadId linkedMessageIds |> Maybe.map Just

                                    NoThread ->
                                        Just Nothing
                                )
                            of
                                ( Ok sendMessageRateLimits, Just maybeSlackThreadId ) ->
                                    let
                                        workspaceUsers : SeqDict (Slack.Id Slack.UserId) SlackFrontendUser
                                        workspaceUsers =
                                            SlackSync.usersToFrontend
                                                model.users
                                                (SeqDict.singleton slackUser.user.id slackUser.user.teamId)
                                                model.slackUsers

                                        richText : Nonempty (RichText (Slack.Id Slack.UserId) (Slack.Id Slack.ChannelId))
                                        richText =
                                            RichText.fromNonemptyString timezone workspaceUsers channelMentions text

                                        attachedFiles2 : SeqDict (Id FileId) FileData
                                        attachedFiles2 =
                                            BackendExtra.validateAttachedFiles model.files attachedFiles
                                    in
                                    ( { model
                                        | sendMessageRateLimits = sendMessageRateLimits
                                        , pendingSlackSends =
                                            SeqDict.update
                                                (slackPendingSendKey guildOrDmId)
                                                (\maybeCount -> Maybe.withDefault 0 maybeCount + 1 |> Just)
                                                model.pendingSlackSends
                                      }
                                    , sendSlackMessage
                                        model.serverSecret
                                        slackUser
                                        slackChannelId
                                        maybeSlackThreadId
                                        (RichText.toString timezone False workspaceUsers channelMentions richText)
                                        (RichText.toSlack richText)
                                        attachedFiles2
                                        |> Task.attempt (SentSlackMessage time changeId clientId timezone guildOrDmId threadRoute text richText attachedFiles2)
                                    )

                                _ ->
                                    ( model, BackendExtra.invalidChangeResponse changeId clientId )
                    in
                    case guildOrDmId of
                        SlackGuildOrDmId_Workspace id ->
                            BackendExtra.asSlackChannelMember
                                model
                                sessionId
                                id
                                (\_ slackUser workspace channel ->
                                    send
                                        slackUser
                                        (SeqDict.foldl
                                            (\channelId channel2 dict ->
                                                SeqDict.insert ( channelId, Nothing ) { name = ChannelName.toString channel2.name } dict
                                            )
                                            SeqDict.empty
                                            workspace.channels
                                        )
                                        id.channelId
                                        channel.linkedMessageIds
                                )

                        SlackGuildOrDmId_Dm data ->
                            BackendExtra.asSlackDmUser
                                model
                                sessionId
                                data
                                (\_ slackUser dmChannel -> send slackUser SeqDict.empty data.channelId dmChannel.linkedMessageIds)

                Local_Slack_SendEditMessage _ timezone guildOrDmId threadRoute text ->
                    let
                        edit :
                            SlackLinkedUser
                            -> SeqDict ( Slack.Id Slack.ChannelId, Maybe (Id ChannelMessageId) ) { name : String }
                            -> Slack.Id channelId
                            -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
                        edit slackUser channelMentions slackChannelId =
                            let
                                workspaceUsers : SeqDict (Slack.Id Slack.UserId) SlackFrontendUser
                                workspaceUsers =
                                    SlackSync.usersToFrontend
                                        model.users
                                        (SeqDict.singleton slackUser.user.id slackUser.user.teamId)
                                        model.slackUsers

                                richText : Nonempty (RichText (Slack.Id Slack.UserId) (Slack.Id Slack.ChannelId))
                                richText =
                                    RichText.fromNonemptyString timezone workspaceUsers channelMentions text
                            in
                            case
                                updateSlackConversation
                                    guildOrDmId
                                    (\conversation ->
                                        case slackMessageTs threadRoute conversation of
                                            Just ts ->
                                                case editSlackMessage time slackUser.user.id richText ts conversation of
                                                    ( _, [] ) ->
                                                        Nothing

                                                    ( conversation2, edited ) ->
                                                        Just ( conversation2, ( ts, edited ) )

                                            Nothing ->
                                                Nothing
                                    )
                                    model
                            of
                                Just ( model2, ( ts, edited ) ) ->
                                    ( model2
                                    , Command.batch
                                        [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                                        , List.map
                                            (\threadRoute2 ->
                                                Broadcast.toSlackExcludingOne
                                                    clientId
                                                    guildOrDmId
                                                    (Server_Slack_EditMessage time slackUser.user.id guildOrDmId threadRoute2 richText |> ServerChange)
                                                    model2
                                            )
                                            edited
                                            |> Command.batch
                                        , Slack.updateMessage
                                            model2.serverSecret
                                            slackUser.cookie
                                            slackUser.token
                                            slackChannelId
                                            ts
                                            (RichText.toString timezone False workspaceUsers channelMentions richText)
                                            (RichText.toSlack richText)
                                            |> Task.attempt (SlackEditedMessage time guildOrDmId)
                                        ]
                                    )

                                Nothing ->
                                    ( model, BackendExtra.invalidChangeResponse changeId clientId )
                    in
                    case guildOrDmId of
                        SlackGuildOrDmId_Workspace id ->
                            BackendExtra.asSlackChannelMember
                                model
                                sessionId
                                id
                                (\_ slackUser workspace _ ->
                                    edit
                                        slackUser
                                        (SeqDict.foldl
                                            (\channelId channel dict ->
                                                SeqDict.insert ( channelId, Nothing ) { name = ChannelName.toString channel.name } dict
                                            )
                                            SeqDict.empty
                                            workspace.channels
                                        )
                                        id.channelId
                                )

                        SlackGuildOrDmId_Dm data ->
                            BackendExtra.asSlackDmUser
                                model
                                sessionId
                                data
                                (\_ slackUser _ -> edit slackUser SeqDict.empty data.channelId)

                Local_Discord_LoadChannelMessages guildOrDmId pageRequest _ ->
                    case guildOrDmId of
                        DiscordGuildOrDmId_Guild id ->
                            BackendExtra.asDiscordGuildChannelMember_AllowUserThatNeedsAuthAgain
                                model
                                sessionId
                                clientId
                                id
                                (\_ _ _ _ _ channel ->
                                    ( model
                                    , handleMessagesRequest pageRequest channel
                                        |> FilledInByBackend
                                        |> Local_Discord_LoadChannelMessages guildOrDmId pageRequest
                                        |> LocalChangeResponse changeId
                                        |> Lamdera.sendToFrontend clientId
                                    )
                                )

                        DiscordGuildOrDmId_Dm data ->
                            BackendExtra.asDiscordDmUser_AllowUserThatNeedsAuthAgain
                                model
                                sessionId
                                data
                                (\_ _ _ channel ->
                                    ( model
                                    , handleMessagesRequest pageRequest channel
                                        |> FilledInByBackend
                                        |> Local_Discord_LoadChannelMessages guildOrDmId pageRequest
                                        |> LocalChangeResponse changeId
                                        |> Lamdera.sendToFrontend clientId
                                    )
                                )

                Local_Discord_LoadThreadMessages guildOrDmId threadId pageRequest _ ->
                    case guildOrDmId of
                        DiscordGuildOrDmId_Guild id ->
                            BackendExtra.asDiscordGuildChannelMember
                                model
                                sessionId
                                id
                                (\_ _ _ _ channel ->
                                    ( model
                                    , SeqDict.get threadId channel.threads
                                        |> Maybe.withDefault Thread.discordBackendInit
                                        |> handleMessagesRequest pageRequest
                                        |> FilledInByBackend
                                        |> Local_Discord_LoadThreadMessages guildOrDmId threadId pageRequest
                                        |> LocalChangeResponse changeId
                                        |> Lamdera.sendToFrontend clientId
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

                Local_ExpandUserOptionSection section collapseOthers ->
                    BackendExtra.asUser
                        model
                        sessionId
                        (\session _ ->
                            ( { model
                                | sessions =
                                    SeqDict.insert
                                        sessionId
                                        (UserSession.expandUserOptionSection section collapseOthers session)
                                        model.sessions
                              }
                            , LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                            )
                        )

                Local_CollapseUserOptionSection section ->
                    BackendExtra.asUser
                        model
                        sessionId
                        (\session _ ->
                            ( { model
                                | sessions =
                                    SeqDict.insert
                                        sessionId
                                        (UserSession.collapseUserOptionSection section session)
                                        model.sessions
                              }
                            , LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                            )
                        )

                Local_SetSheepGameQuestions questions ->
                    BackendExtra.asUser
                        model
                        sessionId
                        (\session _ ->
                            ( { model
                                | sessions =
                                    SeqDict.insert
                                        sessionId
                                        (UserSession.setSheepGameQuestions
                                            (SheepGame.clampSavedQuestions questions)
                                            session
                                        )
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

                Local_SetEmbedVisibility embedVisibility ->
                    BackendExtra.asUser
                        model
                        sessionId
                        (\session user ->
                            ( { model
                                | users =
                                    NonemptyDict.insert
                                        session.userId
                                        (User.setEmbedVisibility embedVisibility user)
                                        model.users
                              }
                            , Lamdera.sendToFrontend clientId (LocalChangeResponse changeId localMsg)
                            )
                        )

                Local_ScheduleAccountDeletion _ ->
                    BackendExtra.asUser
                        model
                        sessionId
                        (\session user ->
                            case ( user.isAdmin, user.email ) of
                                ( False, UserHasEmail email ) ->
                                    let
                                        deleteAt : Time.Posix
                                        deleteAt =
                                            Duration.addTo time (Duration.weeks User.accountDeletionDelayInWeeks)
                                    in
                                    ( { model
                                        | users =
                                            NonemptyDict.insert
                                                session.userId
                                                { user | deleteAccountAt = Just deleteAt }
                                                model.users
                                      }
                                    , Command.batch
                                        [ LocalChangeResponse changeId (Local_ScheduleAccountDeletion deleteAt)
                                            |> Lamdera.sendToFrontend clientId
                                        , Broadcast.toUser
                                            (Just clientId)
                                            Nothing
                                            session.userId
                                            (LocalChange session.userId (Local_ScheduleAccountDeletion deleteAt))
                                            model
                                        , BackendExtra.sendAccountDeletionEmail
                                            (SentNotificationEmail time email)
                                            email
                                            deleteAt
                                            model.postmarkApiKey
                                        ]
                                    )

                                _ ->
                                    ( model, BackendExtra.invalidChangeResponse changeId clientId )
                        )

                Local_CancelAccountDeletion ->
                    BackendExtra.asUser
                        model
                        sessionId
                        (\session user ->
                            ( { model
                                | users =
                                    NonemptyDict.insert
                                        session.userId
                                        { user | deleteAccountAt = Nothing }
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
                                            (Broadcast.UnencryptedBody "Push notifications enabled")
                                            "https://at-chat.app/cacheable/at-logo-no-background.png"
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
                                                        (WebsocketClosedByBackendForUser discordUserId Nothing)
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

                Local_LinkSlackAcknowledgementIsChecked isChecked ->
                    BackendExtra.asUser
                        model
                        sessionId
                        (\session user ->
                            ( { model
                                | users =
                                    NonemptyDict.insert
                                        session.userId
                                        { user | linkSlackAcknowledgementIsChecked = isChecked }
                                        model.users
                              }
                            , Lamdera.sendToFrontend clientId (LocalChangeResponse changeId localMsg)
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

                Local_SetUserColor color ->
                    BackendExtra.asUser
                        model
                        sessionId
                        (\session user ->
                            ( { model | users = NonemptyDict.insert session.userId { user | color = color } model.users }
                            , Command.batch
                                [ Lamdera.sendToFrontend clientId (LocalChangeResponse changeId localMsg)
                                , Broadcast.toEveryoneWhoCanSeeUser
                                    clientId
                                    session.userId
                                    (ServerChange (Server_SetUserColor session.userId color))
                                    model
                                ]
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
                        GuildOrDmId_Dm id ->
                            BackendExtra.asDmUser
                                model
                                sessionId
                                id
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
                                                        id
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
                                                                id
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
                                                                    id
                                                                    (\otherUserId2 ->
                                                                        Server_Game session.userId (GuildOrDmId_Dm otherUserId2) localMsg2
                                                                    )
                                                                    model2
                                                                ]
                                                            )

                                                Nothing ->
                                                    ( model, BackendExtra.invalidChangeResponse changeId clientId )

                                        Game.LoadMatch matchId _ ->
                                            ( model
                                            , loadMatchResponse
                                                clientId
                                                changeId
                                                guildOrDmId
                                                (GuildOrFullDmId_Dm dmChannelId)
                                                matchId
                                                dmChannel
                                                model
                                            )

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
                                                                id
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
                                                                id
                                                                GameType_WordSpellingGame
                                                                model2
                                                    in
                                                    ( { model2 | sessions = sessions }
                                                    , Command.batch [ cmd, notificationCmd ]
                                                    )

                                                _ ->
                                                    ( model2, cmd )

                                        Game.LocalChange_SheepGame matchId sheepChange ->
                                            let
                                                ( model2, cmd ) =
                                                    handleSheepGame
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
                                                                id
                                                                (\otherUserId2 ->
                                                                    Server_Game session.userId (GuildOrDmId_Dm otherUserId2) localMsg2
                                                                )
                                                                model3
                                                        )
                                                        matchId
                                                        sheepChange
                                                        model
                                            in
                                            case sheepChange of
                                                SheepGame.StartMatch _ _ ->
                                                    let
                                                        ( sessions, notificationCmd ) =
                                                            Broadcast.gameStartedDmNotification
                                                                time
                                                                session.userId
                                                                id
                                                                GameType_SheepGame
                                                                model2
                                                    in
                                                    ( { model2 | sessions = sessions }
                                                    , Command.batch [ cmd, notificationCmd ]
                                                    )

                                                _ ->
                                                    ( model2, cmd )
                                )

                        GuildOrDmId_Guild id ->
                            BackendExtra.asGuildMember
                                model
                                sessionId
                                id.guildId
                                (\session _ guild ->
                                    case SeqDict.get id.channelId guild.channels of
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
                                                                                id.guildId
                                                                                { guild | channels = SeqDict.insert id.channelId channel2 guild.channels }
                                                                                model3.guilds
                                                                    }
                                                                )
                                                                (\localMsg2 model3 ->
                                                                    Broadcast.toGuildExcludingOne
                                                                        clientId
                                                                        id.guildId
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
                                                                id
                                                                GameType_WordSpellingGame
                                                                guild
                                                                model2
                                                                cmd

                                                        _ ->
                                                            ( model2, cmd )

                                                Game.LocalChange_SheepGame matchId sheepChange ->
                                                    let
                                                        ( model2, cmd ) =
                                                            handleSheepGame
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
                                                                                id.guildId
                                                                                { guild | channels = SeqDict.insert id.channelId channel2 guild.channels }
                                                                                model3.guilds
                                                                    }
                                                                )
                                                                (\localMsg2 model3 ->
                                                                    Broadcast.toGuildExcludingOne
                                                                        clientId
                                                                        id.guildId
                                                                        (Server_Game session.userId guildOrDmId localMsg2 |> ServerChange)
                                                                        model3
                                                                )
                                                                matchId
                                                                sheepChange
                                                                model
                                                    in
                                                    case sheepChange of
                                                        SheepGame.StartMatch _ _ ->
                                                            notifyGameStartedInGuild
                                                                time
                                                                session.userId
                                                                id
                                                                GameType_SheepGame
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
                                                                id
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
                                                                id
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
                                                                            id.guildId
                                                                            (Server_Game
                                                                                session.userId
                                                                                (GuildOrDmId_Guild id)
                                                                                localMsg2
                                                                                |> ServerChange
                                                                            )
                                                                            model2
                                                                        ]
                                                                    )

                                                        Nothing ->
                                                            ( model, BackendExtra.invalidChangeResponse changeId clientId )

                                                Game.LoadMatch matchId _ ->
                                                    ( model
                                                    , loadMatchResponse
                                                        clientId
                                                        changeId
                                                        guildOrDmId
                                                        (GuildOrFullDmId_Guild id.guildId id.channelId)
                                                        matchId
                                                        channel
                                                        model
                                                    )

                                        Nothing ->
                                            ( model, BackendExtra.invalidChangeResponse changeId clientId )
                                )

                Local_Drawing guildOrDmId anchor drawingChange ->
                    BackendExtra.handleDrawingChange sessionId clientId changeId guildOrDmId anchor drawingChange model

                Local_SetMuteChannel guildId channelId isMuted ->
                    BackendExtra.asGuildMember
                        model
                        sessionId
                        guildId
                        (\session user _ ->
                            ( { model
                                | users =
                                    NonemptyDict.insert
                                        session.userId
                                        { user
                                            | muteSettings =
                                                MuteSettings.setMuteChannel guildId channelId isMuted user.muteSettings
                                        }
                                        model.users
                              }
                            , Command.batch
                                [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                                , Broadcast.toUser
                                    (Just clientId)
                                    Nothing
                                    session.userId
                                    (Server_SetMuteChannel guildId channelId isMuted |> ServerChange)
                                    model
                                ]
                            )
                        )

                Local_SetMuteThread guildId channelId threadId isMuted ->
                    BackendExtra.asGuildMember
                        model
                        sessionId
                        guildId
                        (\session user _ ->
                            ( { model
                                | users =
                                    NonemptyDict.insert
                                        session.userId
                                        { user
                                            | muteSettings =
                                                MuteSettings.setMuteThread guildId channelId threadId isMuted user.muteSettings
                                        }
                                        model.users
                              }
                            , Command.batch
                                [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                                , Broadcast.toUser
                                    (Just clientId)
                                    Nothing
                                    session.userId
                                    (Server_SetMuteThread guildId channelId threadId isMuted |> ServerChange)
                                    model
                                ]
                            )
                        )

                Local_SetMuteDiscordChannel discordUserId guildId channelId isMuted ->
                    BackendExtra.asDiscordGuildChannelMember
                        model
                        sessionId
                        { guildId = guildId, channelId = channelId, currentUserId = discordUserId }
                        (\session _ user _ _ ->
                            ( { model
                                | users =
                                    NonemptyDict.insert
                                        session.userId
                                        { user
                                            | muteSettings =
                                                MuteSettings.setMuteDiscordChannel guildId channelId isMuted user.muteSettings
                                        }
                                        model.users
                              }
                            , Command.batch
                                [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                                , Broadcast.toUser
                                    (Just clientId)
                                    Nothing
                                    session.userId
                                    (Server_SetMuteDiscordChannel guildId channelId isMuted |> ServerChange)
                                    model
                                ]
                            )
                        )

                Local_SetMuteDiscordThread discordUserId guildId channelId threadId isMuted ->
                    BackendExtra.asDiscordGuildChannelMember
                        model
                        sessionId
                        { guildId = guildId, channelId = channelId, currentUserId = discordUserId }
                        (\session _ user _ _ ->
                            ( { model
                                | users =
                                    NonemptyDict.insert
                                        session.userId
                                        { user
                                            | muteSettings =
                                                MuteSettings.setMuteDiscordThread guildId channelId threadId isMuted user.muteSettings
                                        }
                                        model.users
                              }
                            , Command.batch
                                [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                                , Broadcast.toUser
                                    (Just clientId)
                                    Nothing
                                    session.userId
                                    (Server_SetMuteDiscordThread guildId channelId threadId isMuted |> ServerChange)
                                    model
                                ]
                            )
                        )

                Local_SetMuteGuild guildId isMuted ->
                    BackendExtra.asGuildMember
                        model
                        sessionId
                        guildId
                        (\session user _ ->
                            ( { model
                                | users =
                                    NonemptyDict.insert
                                        session.userId
                                        { user
                                            | muteSettings =
                                                MuteSettings.setMuteGuild guildId isMuted user.muteSettings
                                        }
                                        model.users
                              }
                            , Command.batch
                                [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                                , Broadcast.toUser
                                    (Just clientId)
                                    Nothing
                                    session.userId
                                    (Server_SetMuteGuild guildId isMuted |> ServerChange)
                                    model
                                ]
                            )
                        )

                Local_SetMuteDiscordGuild discordUserId guildId isMuted ->
                    BackendExtra.asDiscordGuildMember
                        model
                        sessionId
                        guildId
                        discordUserId
                        (\session _ user _ ->
                            ( { model
                                | users =
                                    NonemptyDict.insert
                                        session.userId
                                        { user
                                            | muteSettings =
                                                MuteSettings.setMuteDiscordGuild guildId isMuted user.muteSettings
                                        }
                                        model.users
                              }
                            , Command.batch
                                [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                                , Broadcast.toUser
                                    (Just clientId)
                                    Nothing
                                    session.userId
                                    (Server_SetMuteDiscordGuild guildId isMuted |> ServerChange)
                                    model
                                ]
                            )
                        )

                Local_SetSlackWorkspaceNotificationLevel slackUserId teamId notificationLevel ->
                    BackendExtra.asSlackWorkspaceMember
                        model
                        sessionId
                        teamId
                        slackUserId
                        (\session _ user _ ->
                            ( { model
                                | users =
                                    NonemptyDict.insert
                                        session.userId
                                        (User.setSlackWorkspaceNotificationLevel teamId notificationLevel user)
                                        model.users
                              }
                            , Command.batch
                                [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                                , Broadcast.toUser
                                    (Just clientId)
                                    Nothing
                                    session.userId
                                    (Server_SetSlackWorkspaceNotificationLevel teamId notificationLevel |> ServerChange)
                                    model
                                ]
                            )
                        )

                Local_SetMuteSlackWorkspace slackUserId teamId isMuted ->
                    BackendExtra.asSlackWorkspaceMember
                        model
                        sessionId
                        teamId
                        slackUserId
                        (\session _ user _ ->
                            ( { model
                                | users =
                                    NonemptyDict.insert
                                        session.userId
                                        { user | muteSettings = MuteSettings.setMuteSlackWorkspace teamId isMuted user.muteSettings }
                                        model.users
                              }
                            , Command.batch
                                [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                                , Broadcast.toUser
                                    (Just clientId)
                                    Nothing
                                    session.userId
                                    (Server_SetMuteSlackWorkspace teamId isMuted |> ServerChange)
                                    model
                                ]
                            )
                        )

                Local_SetMuteSlackChannel slackUserId teamId channelId isMuted ->
                    BackendExtra.asSlackChannelMember
                        model
                        sessionId
                        { teamId = teamId, channelId = channelId, currentUserId = slackUserId }
                        (\session _ _ _ ->
                            case NonemptyDict.get session.userId model.users of
                                Just user ->
                                    ( { model
                                        | users =
                                            NonemptyDict.insert
                                                session.userId
                                                { user | muteSettings = MuteSettings.setMuteSlackChannel teamId channelId isMuted user.muteSettings }
                                                model.users
                                      }
                                    , Command.batch
                                        [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                                        , Broadcast.toUser
                                            (Just clientId)
                                            Nothing
                                            session.userId
                                            (Server_SetMuteSlackChannel teamId channelId isMuted |> ServerChange)
                                            model
                                        ]
                                    )

                                Nothing ->
                                    ( model, BackendExtra.invalidChangeResponse changeId clientId )
                        )

                Local_SetMuteSlackThread slackUserId teamId channelId threadId isMuted ->
                    BackendExtra.asSlackChannelMember
                        model
                        sessionId
                        { teamId = teamId, channelId = channelId, currentUserId = slackUserId }
                        (\session _ _ _ ->
                            case NonemptyDict.get session.userId model.users of
                                Just user ->
                                    ( { model
                                        | users =
                                            NonemptyDict.insert
                                                session.userId
                                                { user | muteSettings = MuteSettings.setMuteSlackThread teamId channelId threadId isMuted user.muteSettings }
                                                model.users
                                      }
                                    , Command.batch
                                        [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                                        , Broadcast.toUser
                                            (Just clientId)
                                            Nothing
                                            session.userId
                                            (Server_SetMuteSlackThread teamId channelId threadId isMuted |> ServerChange)
                                            model
                                        ]
                                    )

                                Nothing ->
                                    ( model, BackendExtra.invalidChangeResponse changeId clientId )
                        )

                Local_RequestE2ee id ->
                    BackendExtra.asDmUser
                        model
                        sessionId
                        id
                        (\session _ _ dmChannelId dmChannel ->
                            let
                                canRequest : Bool
                                canRequest =
                                    case dmChannel.e2ee of
                                        DmChannel.E2eeDisabled _ ->
                                            True

                                        DmChannel.E2eeDeclinedBy declinedBy ->
                                            declinedBy == session.userId

                                        DmChannel.E2eeRequestedBy _ ->
                                            False

                                        DmChannel.E2eeEnabled _ ->
                                            False
                            in
                            if canRequest then
                                let
                                    model2 : BackendModel
                                    model2 =
                                        { model
                                            | dmChannels =
                                                SeqDict.insert
                                                    dmChannelId
                                                    { dmChannel
                                                        | e2ee =
                                                            DmChannel.E2eeRequestedBy ( session.userId, session.sessionIdHash )
                                                    }
                                                    model.dmChannels
                                        }

                                    ( sessions, notificationCmd ) =
                                        Broadcast.e2eeRequestNotification time session.userId id model2
                                in
                                ( { model2 | sessions = sessions }
                                , Command.batch
                                    [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                                    , Broadcast.toDmChannelExcludingOne
                                        clientId
                                        session.userId
                                        id
                                        (\id2 -> Server_E2eeRequested id2 ( session.userId, session.sessionIdHash ))
                                        model2
                                    , notificationCmd
                                    ]
                                )

                            else
                                ( model, BackendExtra.invalidChangeResponse changeId clientId )
                        )

                Local_EncryptOldMessages id messages ->
                    BackendExtra.asDmUser
                        model
                        sessionId
                        id
                        (\_ _ _ dmChannelId dmChannel ->
                            BackendExtra.encryptOldMessages clientId changeId localMsg model messages dmChannelId dmChannel
                        )

                Local_DisableE2ee id _ ->
                    BackendExtra.asDmUser
                        model
                        sessionId
                        id
                        (\session _ _ _ dmChannel ->
                            case dmChannel.e2ee of
                                DmChannel.E2eeEnabled _ ->
                                    ( model
                                    , Command.batch
                                        [ BackendExtra.channelDataToDecrypt dmChannel
                                            |> FilledInByBackend
                                            |> Local_DisableE2ee id
                                            |> LocalChangeResponse changeId
                                            |> Lamdera.sendToFrontend clientId
                                        , Broadcast.toDmChannelExcludingOne
                                            clientId
                                            session.userId
                                            id
                                            (Server_DisableE2ee time session.userId)
                                            model
                                        ]
                                    )

                                DmChannel.E2eeDisabled _ ->
                                    ( model, BackendExtra.invalidChangeResponse changeId clientId )

                                DmChannel.E2eeRequestedBy _ ->
                                    ( model, BackendExtra.invalidChangeResponse changeId clientId )

                                DmChannel.E2eeDeclinedBy _ ->
                                    ( model, BackendExtra.invalidChangeResponse changeId clientId )
                        )

                Local_DecryptOldMessages id _ messages ->
                    BackendExtra.asDmUser
                        model
                        sessionId
                        id
                        (\session _ _ dmChannelId dmChannel ->
                            BackendExtra.decryptOldMessages
                                time
                                clientId
                                changeId
                                localMsg
                                model
                                messages
                                session
                                dmChannelId
                                dmChannel
                        )

                Local_SetE2eeRisksAccepted isAccepted ->
                    BackendExtra.asUser
                        model
                        sessionId
                        (\session user ->
                            ( { model
                                | users =
                                    NonemptyDict.insert
                                        session.userId
                                        { user | e2eeRisksAccepted = isAccepted }
                                        model.users
                              }
                            , Lamdera.sendToFrontend clientId (LocalChangeResponse changeId localMsg)
                            )
                        )

                Local_SetPublicKey publicKey _ ->
                    BackendExtra.asUser
                        model
                        sessionId
                        (\session user ->
                            case user.publicKey of
                                Nothing ->
                                    ( { model
                                        | users =
                                            NonemptyDict.insert
                                                session.userId
                                                { user | publicKey = Just publicKey }
                                                model.users
                                      }
                                    , Command.batch
                                        [ BackendExtra.dmChannelsThatNeedEncrypting session model.dmChannels
                                            |> FilledInByBackend
                                            |> Local_SetPublicKey publicKey
                                            |> LocalChangeResponse changeId
                                            |> Lamdera.sendToFrontend clientId
                                        , Broadcast.toEveryoneWhoCanSeeUser
                                            clientId
                                            session.userId
                                            (Server_SetPublicKey session.userId publicKey |> ServerChange)
                                            model
                                        ]
                                    )

                                Just existingPublicKey ->
                                    if publicKey == existingPublicKey then
                                        ( model
                                        , BackendExtra.dmChannelsThatNeedEncrypting session model.dmChannels
                                            |> FilledInByBackend
                                            |> Local_SetPublicKey publicKey
                                            |> LocalChangeResponse changeId
                                            |> Lamdera.sendToFrontend clientId
                                        )

                                    else
                                        ( model, BackendExtra.invalidChangeResponse changeId clientId )
                        )

                Local_SendEncryptedMessage _ id fileHashes content notification threadRoute ->
                    BackendExtra.asDmUser
                        model
                        sessionId
                        id
                        (\session user _ dmChannelId dmChannel ->
                            case dmChannel.e2ee of
                                DmChannel.E2eeEnabled _ ->
                                    BackendExtra.sendEncryptedDm
                                        time
                                        clientId
                                        changeId
                                        id
                                        fileHashes
                                        content
                                        notification
                                        threadRoute
                                        session
                                        user
                                        dmChannelId
                                        dmChannel
                                        model

                                _ ->
                                    ( model, BackendExtra.invalidChangeResponse changeId clientId )
                        )

                Local_SendEncryptedEditMessage _ id threadRoute fileHashes content ->
                    BackendExtra.asDmUser
                        model
                        sessionId
                        id
                        (\session _ _ dmChannelId dmChannel ->
                            case
                                ( dmChannel.e2ee
                                , LocalState.editEncryptedMessageHelper
                                    time
                                    session.userId
                                    fileHashes
                                    content
                                    threadRoute
                                    dmChannel
                                )
                            of
                                ( DmChannel.E2eeEnabled _, Ok dmChannel2 ) ->
                                    ( { model
                                        | dmChannels =
                                            SeqDict.insert
                                                dmChannelId
                                                { dmChannel2
                                                    | lastTypedAt =
                                                        LocalState.dmForgetEditTyping session.userId threadRoute dmChannel2.lastTypedAt
                                                }
                                                model.dmChannels
                                      }
                                    , Command.batch
                                        [ Local_SendEncryptedEditMessage time id threadRoute fileHashes content
                                            |> LocalChangeResponse changeId
                                            |> Lamdera.sendToFrontend clientId
                                        , Broadcast.toDmChannelExcludingOne
                                            clientId
                                            session.userId
                                            id
                                            (\id2 ->
                                                Server_SendEncryptedEditMessage
                                                    time
                                                    session.userId
                                                    id2
                                                    threadRoute
                                                    fileHashes
                                                    content
                                            )
                                            model
                                        ]
                                    )

                                _ ->
                                    -- Either nothing agreed to encrypt this conversation, or
                                    -- the message being edited isn't one this user wrote.
                                    ( model, BackendExtra.invalidChangeResponse changeId clientId )
                        )

                Local_AcceptE2ee id _ _ ->
                    BackendExtra.asDmUser
                        model
                        sessionId
                        id
                        (\session _ _ dmChannelId dmChannel ->
                            case dmChannel.e2ee of
                                DmChannel.E2eeRequestedBy requestedBy ->
                                    if Tuple.first requestedBy == session.userId && (session.userId /= id.otherUserId) then
                                        ( model, BackendExtra.invalidChangeResponse changeId clientId )

                                    else
                                        let
                                            dmChannels =
                                                SeqDict.insert
                                                    dmChannelId
                                                    { dmChannel
                                                        | e2ee =
                                                            DmChannel.E2eeEnabled
                                                                { enabledAt = time, requestedBy = requestedBy }
                                                    }
                                                    model.dmChannels

                                            model2 : BackendModel
                                            model2 =
                                                { model | dmChannels = dmChannels }
                                        in
                                        ( model2
                                        , Command.batch
                                            [ BackendExtra.dmChannelsThatNeedEncrypting session dmChannels
                                                |> FilledInByBackend
                                                |> Local_AcceptE2ee id time
                                                |> LocalChangeResponse changeId
                                                |> Lamdera.sendToFrontend clientId
                                            , Broadcast.toDmChannelExcludingOne
                                                clientId
                                                session.userId
                                                id
                                                (\id2 -> Server_E2eeAccepted id2 time)
                                                model2
                                            ]
                                        )

                                _ ->
                                    ( model, BackendExtra.invalidChangeResponse changeId clientId )
                        )

                Local_DeclineE2eeRequestAsInitiator id ->
                    BackendExtra.asDmUser
                        model
                        sessionId
                        id
                        (\session _ _ dmChannelId dmChannel ->
                            case dmChannel.e2ee of
                                DmChannel.E2eeDisabled _ ->
                                    ( model, BackendExtra.invalidChangeResponse changeId clientId )

                                DmChannel.E2eeDeclinedBy _ ->
                                    ( model, BackendExtra.invalidChangeResponse changeId clientId )

                                DmChannel.E2eeEnabled _ ->
                                    ( model, BackendExtra.invalidChangeResponse changeId clientId )

                                DmChannel.E2eeRequestedBy ( requestedBy, _ ) ->
                                    if requestedBy == session.userId then
                                        let
                                            model2 : BackendModel
                                            model2 =
                                                { model
                                                    | dmChannels =
                                                        SeqDict.insert
                                                            dmChannelId
                                                            { dmChannel | e2ee = DmChannel.E2eeDisabled Nothing }
                                                            model.dmChannels
                                                }
                                        in
                                        ( model2
                                        , Command.batch
                                            [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                                            , Broadcast.toDmChannelExcludingOne
                                                clientId
                                                session.userId
                                                id
                                                Server_E2eeRequestCancelled
                                                model2
                                            ]
                                        )

                                    else
                                        ( model, BackendExtra.invalidChangeResponse changeId clientId )
                        )

                Local_DeclineE2eeRequest id ->
                    BackendExtra.asDmUser
                        model
                        sessionId
                        id
                        (\session _ _ dmChannelId dmChannel ->
                            case dmChannel.e2ee of
                                DmChannel.E2eeRequestedBy ( requestedBy, _ ) ->
                                    if requestedBy == session.userId && (session.userId /= id.otherUserId) then
                                        ( model, BackendExtra.invalidChangeResponse changeId clientId )

                                    else
                                        let
                                            model2 : BackendModel
                                            model2 =
                                                { model
                                                    | dmChannels =
                                                        SeqDict.insert
                                                            dmChannelId
                                                            { dmChannel | e2ee = DmChannel.E2eeDeclinedBy session.userId }
                                                            model.dmChannels
                                                }
                                        in
                                        ( model2
                                        , Command.batch
                                            [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                                            , Broadcast.toDmChannelExcludingOne
                                                clientId
                                                session.userId
                                                id
                                                (\id2 -> Server_E2eeRequestDeclined id2 session.userId)
                                                model2
                                            ]
                                        )

                                DmChannel.E2eeDeclinedBy _ ->
                                    ( model, BackendExtra.invalidChangeResponse changeId clientId )

                                DmChannel.E2eeDisabled _ ->
                                    ( model, BackendExtra.invalidChangeResponse changeId clientId )

                                DmChannel.E2eeEnabled _ ->
                                    ( model, BackendExtra.invalidChangeResponse changeId clientId )
                        )

        TwoFactorToBackend toBackend2 ->
            BackendExtra.asUser
                model
                sessionId
                (twoFactorAuthenticationUpdateFromFrontend clientId time toBackend2 model)

        AiChatToBackend aiChatToBackend ->
            BackendExtra.asAdmin
                model
                sessionId
                (\_ _ ->
                    ( model
                    , Command.map
                        AiChatToFrontend
                        AiChatBackendMsg
                        (AiChat.updateFromFrontend clientId aiChatToBackend model.openRouterKey)
                    )
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
                    , (case user.email of
                        UserHasEmail email ->
                            BackendExtra.getLoginData sessionId clientId currentlyViewing session email user requestMessagesFor model
                                |> Ok

                        DeletedUser ->
                            Err ()
                      )
                        |> ReloadDataResponse
                        |> Lamdera.sendToFrontend clientId
                    )
                )

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
                            (LinkDiscordResponse (Err (LinkDiscordHttpError (Discord.UnexpectedError "Discord account linking is disabled"))))
                        )
                )

        LinkSlackRequest data ->
            BackendExtra.asUser
                model
                sessionId
                (\session _ ->
                    if model.slackLinkingEnabled then
                        ( model
                        , let
                            loadWorkspace : SlackToken -> Task BackendOnly Never ( SlackToken, Result Slack.HttpError Slack.UserBoot )
                            loadWorkspace token =
                                Slack.userBoot model.serverSecret data.cookie token
                                    |> Task.map Ok
                                    |> Task.onError (\error -> Task.succeed (Err error))
                                    |> Task.map (Tuple.pair token)

                            (Nonempty firstToken restOfTokens) =
                                data.tokens
                          in
                          Task.map2
                            Nonempty
                            (loadWorkspace firstToken)
                            (List.map loadWorkspace restOfTokens |> Task.sequence)
                            |> Task.perform (LinkSlackUserStep1 time clientId session.userId data.cookie)
                        )

                    else
                        ( model
                        , Lamdera.sendToFrontend clientId (LinkSlackResponse SlackLinkingDisabled)
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
                            SeqDict.insert guildId { guild | icon = fileHash } model.guilds
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
                                    handleGoMatchRequest messageId dmChannel model

                                Nothing ->
                                    Err ()

                        GuildOrFullDmId_Guild guildId channelId ->
                            case SeqDict.get guildId model.guilds of
                                Just guild ->
                                    case SeqDict.get channelId guild.channels of
                                        Just channel ->
                                            handleGoMatchRequest messageId channel model

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

        ImportChannelRequest guildId file ->
            BackendExtra.asGuildOwner
                model
                sessionId
                guildId
                (\userId _ guild ->
                    case ChannelImport.decode file.json model of
                        Ok imported ->
                            let
                                channelId : Id ChannelId
                                channelId =
                                    Id.nextId guild.channels

                                channel : BackendChannel
                                channel =
                                    { createdAt = Maybe.withDefault time imported.createdAt
                                    , createdBy = Maybe.withDefault userId imported.createdBy
                                    , name =
                                        case imported.name of
                                            Just name ->
                                                name

                                            Nothing ->
                                                importedChannelName file.fileName
                                    , description =
                                        Maybe.withDefault ChannelDescription.empty imported.description
                                    , messages = imported.messages
                                    , status = LocalState.ChannelActive
                                    , threads = imported.threads
                                    , dateDividerDrawings = imported.dateDividerDrawings
                                    , games = imported.games
                                    }

                                model2 : BackendModel
                                model2 =
                                    { model
                                        | guilds =
                                            SeqDict.insert
                                                guildId
                                                { guild | channels = SeqDict.insert channelId channel guild.channels }
                                                model.guilds
                                    }
                            in
                            ( model2
                            , Command.batch
                                [ case
                                    LocalState.channelToFrontend guildId channelId Nothing model2.goMatchPublicIds channel
                                  of
                                    Just frontendChannel ->
                                        Broadcast.toGuild
                                            guildId
                                            (Server_ImportedChannel guildId channelId frontendChannel |> ServerChange)
                                            model2

                                    Nothing ->
                                        Command.none
                                , ImportChannelResponse guildId (Ok { encryptedMessages = imported.encryptedMessages })
                                    |> Lamdera.sendToFrontend clientId
                                ]
                            )

                        Err (ChannelImport.NotAChannelExport _) ->
                            ( model
                            , ImportChannelResponse guildId (Err NotAChannelExport)
                                |> Lamdera.sendToFrontend clientId
                            )
                )

        ExportChannelRequest exportChannelId ->
            case exportChannelId of
                ExportChannel_Guild guildId channelId ->
                    BackendExtra.asGuildMember
                        model
                        sessionId
                        guildId
                        (\_ _ guild ->
                            ( model
                            , case SeqDict.get channelId guild.channels of
                                Just channel ->
                                    ExportChannelResponse
                                        { fileName = ChannelExport.fileName channel.name
                                        , json = ChannelExport.guildChannel channel
                                        }
                                        |> Lamdera.sendToFrontend clientId

                                Nothing ->
                                    Command.none
                            )
                        )

                ExportChannel_Discord currentDiscordUserId guildId channelId ->
                    BackendExtra.asDiscordGuildChannelMember
                        model
                        sessionId
                        { guildId = guildId, channelId = channelId, currentUserId = currentDiscordUserId }
                        (\_ _ _ _ channel ->
                            ( model
                            , ExportChannelResponse
                                { fileName = ChannelExport.fileName channel.name
                                , json = ChannelExport.discordGuildChannel channel
                                }
                                |> Lamdera.sendToFrontend clientId
                            )
                        )

                ExportChannel_Dm otherUserId ->
                    BackendExtra.asDmUser
                        model
                        sessionId
                        { otherUserId = otherUserId }
                        (\_ _ otherUser _ dmChannel ->
                            ( model
                            , ExportChannelResponse
                                { fileName = ChannelExport.dmFileName (PersonName.toString otherUser.name)
                                , json = ChannelExport.dmChannel dmChannel
                                }
                                |> Lamdera.sendToFrontend clientId
                            )
                        )

                ExportChannel_DiscordDm currentDiscordUserId channelId ->
                    BackendExtra.asDiscordDmUser
                        model
                        sessionId
                        { currentUserId = currentDiscordUserId, channelId = channelId }
                        (\_ _ _ dmChannel ->
                            ( model
                            , ExportChannelResponse
                                { fileName =
                                    ChannelExport.discordDmName model.discordUsers currentDiscordUserId dmChannel
                                        |> ChannelExport.dmFileName
                                , json = ChannelExport.discordDmChannel dmChannel
                                }
                                |> Lamdera.sendToFrontend clientId
                            )
                        )


{-| A DM export carries no channel name of its own, so the name of the file it arrived in
stands in for one.
-}
importedChannelName : String -> ChannelName
importedChannelName fileName =
    (if String.endsWith ".json" fileName then
        String.dropRight 5 fileName

     else
        fileName
    )
        |> ChannelName.fromStringLossy


handleGoMatchRequest :
    Id ChannelMessageId
    -> { a | games : SeqDict (Id ChannelMessageId) Game.BackendGameData }
    -> BackendModel
    -> Result () Go.PublicGoMatchResponse
handleGoMatchRequest messageId channel model =
    case SeqDict.get messageId channel.games of
        Just (Game.GameData_Go setup actions) ->
            let
                lookupUser : Id UserId -> User.FrontendUser
                lookupUser userId =
                    case NonemptyDict.get userId model.users of
                        Just user ->
                            User.backendToFrontendForUser user

                        Nothing ->
                            { name = PersonName.fromStringLossy User.missingName
                            , color = RichText.defaultColor
                            , icon = Nothing
                            , publicKey = Nothing
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


{-| Hand one match over to the client that asked for it. Nothing about the match changes,
so this goes to that client alone rather than being broadcast.
-}
loadMatchResponse :
    ClientId
    -> ChangeId
    -> GuildOrDmId
    -> GuildOrFullDmId
    -> Id ChannelMessageId
    -> { a | games : SeqDict (Id ChannelMessageId) Game.BackendGameData }
    -> BackendModel
    -> Command BackendOnly ToFrontend BackendMsg
loadMatchResponse clientId changeId guildOrDmId guildOrFullDmId matchId channel model =
    case SeqDict.get matchId channel.games of
        Just gameData ->
            Game.LoadMatch
                matchId
                (FilledInByBackend
                    { gameData = gameData
                    , publicLink = OneToOne.first ( guildOrFullDmId, matchId ) model.goMatchPublicIds
                    }
                )
                |> Local_Game guildOrDmId
                |> LocalChangeResponse changeId
                |> Lamdera.sendToFrontend clientId

        Nothing ->
            BackendExtra.invalidChangeResponse changeId clientId


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
                GuildOrDmId_Guild { guildId, channelId } ->
                    GuildOrFullDmId_Guild guildId channelId

                GuildOrDmId_Dm id ->
                    GuildOrFullDmId_Dm (DmChannelId.fromUserIds session.userId id.otherUserId)
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
    -> Viewing_ChannelId
    -> GameType
    -> BackendGuild
    -> BackendModel
    -> Command BackendOnly ToFrontend BackendMsg
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
notifyGameStartedInGuild time sender id gameType guild model cmd =
    let
        ( sessions, notificationCmd ) =
            Broadcast.gameStartedGuildNotification
                time
                sender
                id
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
    -> Viewing_ChannelId
    -> Id ChannelMessageId
    -> Go.LocalChange
    -> BackendGuild
    -> BackendChannel
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleGuildGoGame time session clientId changeId id matchId goChange guild channel model =
    let
        guildOrDmId =
            GuildOrDmId_Guild id
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
                        id.guildId
                        { guild
                            | channels =
                                SeqDict.insert
                                    id.channelId
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
                , users =
                    BackendExtra.ownMessageIsReadBackend
                        session.userId
                        (GuildOrDmId guildOrDmId)
                        messageId
                        model.users
              }
            , Command.batch
                [ Local_Game guildOrDmId localMsg2
                    |> LocalChangeResponse changeId
                    |> Lamdera.sendToFrontend clientId
                , Broadcast.toGuildExcludingOne
                    clientId
                    id.guildId
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
                                    id.guildId
                                    { guild
                                        | channels =
                                            SeqDict.insert
                                                id.channelId
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
                                id.guildId
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
    -> Viewing_DmId
    -> Id ChannelMessageId
    -> Go.LocalChange
    -> DmChannelId
    -> BackendDmChannel
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleDmGoGame time session clientId changeId id matchId goChange dmChannelId dmChannel model =
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
                , users =
                    BackendExtra.ownMessageIsReadBackend
                        session.userId
                        (GuildOrDmId (GuildOrDmId_Dm id))
                        messageId
                        model.users
              }
            , Command.batch
                [ Local_Game (GuildOrDmId_Dm id) localMsg2
                    |> LocalChangeResponse changeId
                    |> Lamdera.sendToFrontend clientId
                , Broadcast.toDmChannelExcludingOne
                    clientId
                    session.userId
                    id
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
                            [ Local_Game (GuildOrDmId_Dm id) localMsg2
                                |> LocalChangeResponse changeId
                                |> Lamdera.sendToFrontend clientId
                            , Broadcast.toDmChannelExcludingOne
                                clientId
                                session.userId
                                id
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


handleSheepGame :
    Time.Posix
    -> UserSession
    -> ClientId
    -> ChangeId
    -> GuildOrDmId
    ->
        { c
            | messages : IdArray ChannelMessageId (Message ChannelMessageId (Id UserId) (Id ChannelId))
            , games : SeqDict (Id ChannelMessageId) Game.BackendGameData
        }
    ->
        ({ c
            | messages : IdArray ChannelMessageId (Message ChannelMessageId (Id UserId) (Id ChannelId))
            , games : SeqDict (Id ChannelMessageId) Game.BackendGameData
         }
         -> BackendModel
         -> BackendModel
        )
    -> (Game.LocalChange -> BackendModel -> Command BackendOnly ToFrontend BackendMsg)
    -> Id ChannelMessageId
    -> SheepGame.LocalChange
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleSheepGame time session clientId changeId guildOrDmId channel setChannel broadcast matchId sheepChange model =
    case sheepChange of
        SheepGame.StartMatch _ setup ->
            let
                setup2 : SheepGame.ValidatedSetup
                setup2 =
                    -- A client could name files it never uploaded, the same way it could when
                    -- sending a message, so only the ones we actually hold are kept.
                    { setup
                        | questions =
                            List.Nonempty.map
                                (\question ->
                                    { question
                                        | attachedFiles =
                                            BackendExtra.validateAttachedFiles model.files question.attachedFiles
                                    }
                                )
                                setup.questions
                    }

                ( messageId, channel2 ) =
                    LocalState.createChannelMessageBackend
                        (GameStarted
                            { startedAt = time
                            , startedBy = session.userId
                            , reactions = SeqDict.empty
                            , gameType = GameType_SheepGame
                            , timestampDrawings = Drawing.emptyDrawing
                            , cardDrawings = Drawing.emptyDrawing
                            }
                        )
                        channel

                localMsg2 : Game.LocalChange
                localMsg2 =
                    Game.LocalChange_SheepGame messageId (SheepGame.StartMatch time setup2)
            in
            ( setChannel
                { channel2
                    | games =
                        SeqDict.insert
                            messageId
                            (Game.GameData_SheepGame setup2 Array.empty SheepGame.initShared)
                            channel2.games
                }
                model
            , Command.batch
                [ Local_Game guildOrDmId localMsg2
                    |> LocalChangeResponse changeId
                    |> Lamdera.sendToFrontend clientId
                , broadcast localMsg2 model
                ]
            )

        SheepGame.Action action ->
            -- Actions only carry weight when they come from the person they claim to. Whether
            -- that person is allowed to make this particular move is decided by
            -- `SheepGame.updateAction`, which the frontend runs over the same actions.
            case ( action.userId == session.userId, SeqDict.get matchId channel.games ) of
                ( True, Just (Game.GameData_SheepGame setup actions shared) ) ->
                    let
                        action2 : SheepGame.ActionWithTime
                        action2 =
                            case action.change of
                                -- An answer names the files attached to it the way a message
                                -- does, so it gets the same check that we're actually holding
                                -- the ones it names.
                                SheepGame.SubmittedAnswer questionId (Just answer) ->
                                    { action
                                        | change =
                                            SheepGame.SubmittedAnswer
                                                questionId
                                                (Just
                                                    { answer
                                                        | attachedFiles =
                                                            BackendExtra.validateAttachedFiles
                                                                model.files
                                                                answer.attachedFiles
                                                    }
                                                )
                                    }

                                -- And so does a note the host wrote about a question.
                                SheepGame.ChangedNotes questionId (Just notes) ->
                                    { action
                                        | change =
                                            SheepGame.ChangedNotes
                                                questionId
                                                (Just
                                                    { notes
                                                        | attachedFiles =
                                                            BackendExtra.validateAttachedFiles
                                                                model.files
                                                                notes.attachedFiles
                                                    }
                                                )
                                    }

                                _ ->
                                    action

                        localMsg2 : Game.LocalChange
                        localMsg2 =
                            Game.LocalChange_SheepGame matchId (SheepGame.Action action2)
                    in
                    ( setChannel
                        { channel
                            | games =
                                SeqDict.insert
                                    matchId
                                    (Game.GameData_SheepGame
                                        setup
                                        (Array.push action2 actions)
                                        (SheepGame.updateAction setup action2 shared)
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


handleWordSpellingGame :
    Time.Posix
    -> UserSession
    -> ClientId
    -> ChangeId
    -> GuildOrDmId
    ->
        { c
            | messages : IdArray ChannelMessageId (Message ChannelMessageId (Id UserId) (Id ChannelId))
            , games : SeqDict (Id ChannelMessageId) Game.BackendGameData
        }
    ->
        ({ c
            | messages : IdArray ChannelMessageId (Message ChannelMessageId (Id UserId) (Id ChannelId))
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
                    , users =
                        BackendExtra.ownMessageIsReadBackend
                            session.userId
                            (GuildOrDmId guildOrDmId)
                            messageId
                            model.users
                }
            , Command.batch
                [ Local_Game guildOrDmId localMsg2
                    |> LocalChangeResponse changeId
                    |> Lamdera.sendToFrontend clientId
                , broadcast localMsg2 model
                , if loadEnglishWordList then
                    Http.get
                        { url = Env.domain ++ "/cacheable/NWL2023.txt"
                        , expect = Http.expectString GotEnglishWordList
                        }

                  else
                    Command.none
                , if loadSwedishWordList then
                    Http.get
                        { url = Env.domain ++ "/cacheable/swedish-word-list.txt"
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
                        placeWordHelper : WordSpellingGame.PlacedWord -> Result () ( WordSpellingGame.PlacementResult, Set String )
                        placeWordHelper placed =
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

                        action2 : WordSpellingGame.ActionWithTime
                        action2 =
                            { action
                                | time = time
                                , change =
                                    case action.change of
                                        WordSpellingGame.PlaceWord placed _ ->
                                            WordSpellingGame.PlaceWord
                                                placed
                                                (case placeWordHelper placed of
                                                    Ok ( _, wildcardMatches ) ->
                                                        FilledInByBackend (WordSpellingGame.IsValid wildcardMatches)

                                                    Err () ->
                                                        FilledInByBackend WordSpellingGame.IsNotValid
                                                )

                                        WordSpellingGame.ReplaceTrayOrPass ->
                                            action.change

                                        WordSpellingGame.JoinGame ->
                                            action.change

                                        WordSpellingGame.Premove placed _ ->
                                            WordSpellingGame.Premove
                                                placed
                                                (case placeWordHelper placed of
                                                    Ok ( _, wildcardMatches ) ->
                                                        FilledInByBackend (WordSpellingGame.IsValid wildcardMatches)

                                                    Err () ->
                                                        FilledInByBackend WordSpellingGame.IsNotValid
                                                )

                                        WordSpellingGame.CancelPremove ->
                                            action.change

                                        WordSpellingGame.AddedReaction _ _ ->
                                            action.change

                                        WordSpellingGame.RemovedReaction _ _ ->
                                            action.change
                            }

                        localMsg2 : Game.LocalChange
                        localMsg2 =
                            Game.LocalChange_WordSpellingGame
                                matchId
                                (WordSpellingGame.Action action2)

                        ( sharedNext, descriptions ) =
                            WordSpellingGame.updateAction setup action2 shared

                        notificationRoute : Route
                        notificationRoute =
                            case guildOrDmId of
                                GuildOrDmId_Guild { guildId, channelId } ->
                                    Route.GuildRoute
                                        guildId
                                        (Route.ChannelRoute
                                            channelId
                                            (Route.NoThreadWithFriends Nothing Route.HideChannelSettings)
                                            (Just (UserSession.ChannelHeaderTab_Games (Just matchId) Nothing))
                                        )
                                        ChannelsHiddenOnMobile
                                        Nothing

                                GuildOrDmId_Dm id ->
                                    Route.DmRoute
                                        { channelId = DmChannelId.fromUserIds session.userId id.otherUserId
                                        , threadRoute = Route.NoThreadWithFriends Nothing Route.HideChannelSettings
                                        , tab = Just (UserSession.ChannelHeaderTab_Games (Just matchId) Nothing)
                                        , channelsVisible = ChannelsHiddenOnMobile
                                        , overlay = Nothing
                                        }

                        userToString : Id UserId -> String
                        userToString userId =
                            case NonemptyDict.get userId model.users of
                                Just user ->
                                    PersonName.toString user.name

                                Nothing ->
                                    "<unknown>"

                        ( userSessions2, notificationCmds ) =
                            List.foldl
                                (\{ userId, title, pushNotificationText, emailText, emailHtml } ( userSessions, cmds ) ->
                                    let
                                        -- A DM channel is identified by the *other* user, so
                                        -- when checking what the notified user is viewing we
                                        -- need the DM as seen from their side.
                                        guildOrDmIdForRecipient : GuildOrDmId
                                        guildOrDmIdForRecipient =
                                            case guildOrDmId of
                                                GuildOrDmId_Guild _ ->
                                                    guildOrDmId

                                                GuildOrDmId_Dm id ->
                                                    if userId == id.otherUserId then
                                                        GuildOrDmId_Dm { otherUserId = session.userId }

                                                    else
                                                        guildOrDmId

                                        alreadyViewing : Bool
                                        alreadyViewing =
                                            List.any
                                                (\connection ->
                                                    UserSession.isViewingGame guildOrDmIdForRecipient matchId connection.currentlyViewing
                                                )
                                                (Broadcast.userGetAllConnections userId model)
                                    in
                                    if alreadyViewing then
                                        ( userSessions, cmds )

                                    else
                                        Broadcast.notificationAlt
                                            time
                                            userId
                                            title
                                            (Env.domain ++ "/cacheable/word-spelling-game-preview.webp")
                                            (Broadcast.UnencryptedBody pushNotificationText)
                                            emailText
                                            emailHtml
                                            (Just notificationRoute)
                                            userSessions
                                            model
                                            |> Tuple.mapSecond (\a -> a ++ cmds)
                                )
                                ( model.sessions, [] )
                                (WordSpellingGame.nextTurnNotifications userToString notificationRoute shared descriptions sharedNext)
                    in
                    ( setChannel
                        { channel
                            | games =
                                SeqDict.insert
                                    matchId
                                    (Game.GameData_WordSpellingGame setup (Array.push action2 actions) sharedNext)
                                    channel.games
                        }
                        { model | sessions = userSessions2 }
                    , Command.batch
                        [ Local_Game guildOrDmId localMsg2
                            |> LocalChangeResponse changeId
                            |> Lamdera.sendToFrontend clientId
                        , broadcast localMsg2 model
                        , Command.batch notificationCmds
                        ]
                    )

                _ ->
                    ( model, BackendExtra.invalidChangeResponse changeId clientId )


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
        Call.Local_Leave _ ->
            BackendExtra.asUser
                model
                sessionId
                (\session _ -> leaveVoice sessionId clientId time changeId model session.userId)

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

                        ConnectedToCall roomId ->
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
                    Just (Call.DmRoomId id) ->
                        Broadcast.toDmChannelExcludingOne
                            clientId
                            session.userId
                            id
                            (\otherUserId2 ->
                                Call.Server_SetRemoteCallData
                                    { roomId = Call.DmRoomId otherUserId2
                                    , otherClientId = ( session.userId, clientId )
                                    }
                                    remoteCallData
                                    |> Server_VoiceChatChange
                            )
                            model

                    Just (Call.GuildRoomId id) ->
                        Broadcast.toGuildExcludingOne
                            clientId
                            id.guildId
                            (Call.Server_SetRemoteCallData
                                { roomId = Call.GuildRoomId id
                                , otherClientId = ( session.userId, clientId )
                                }
                                remoteCallData
                                |> Server_VoiceChatChange
                                |> ServerChange
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
    -> Id UserId
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
leaveVoice sessionId clientId time changeId model userId =
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

                                ConnectedToCall roomId ->
                                    Just roomId

                        Nothing ->
                            Nothing

                Nothing ->
                    Nothing
    in
    case maybeRoomId of
        Just roomId ->
            leaveVoiceHelper sessionId clientId time (Just changeId) model userId roomId

        Nothing ->
            ( model, BackendExtra.invalidChangeResponse changeId clientId )


leaveVoiceHelper :
    SessionId
    -> ClientId
    -> Time.Posix
    -> Maybe ChangeId
    -> BackendModel
    -> Id UserId
    -> Call.CallId
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
leaveVoiceHelper sessionId clientId time maybeChangeId model userId roomId =
    let
        connections =
            SeqDict.updateIfExists
                sessionId
                (NonemptyDict.updateIfExists clientId (\connection -> { connection | call = NotInCall }))
                model.connections
    in
    ( case roomId of
        Call.DmRoomId id ->
            let
                dmChannelId =
                    DmChannelId.fromUserIds userId id.otherUserId
            in
            { model
                | connections = connections
                , dmChannels =
                    if dmVoiceChatRoomHasOtherMembers dmChannelId clientId model then
                        model.dmChannels

                    else
                        SeqDict.updateIfExists dmChannelId (LocalState.markCallMessageAsEndedBackend time) model.dmChannels
            }

        Call.GuildRoomId id ->
            { model
                | connections = connections
                , guilds =
                    if guildVoiceChatRoomHasOtherMembers id clientId model then
                        model.guilds

                    else
                        SeqDict.updateIfExists
                            id.guildId
                            (\guild ->
                                { guild
                                    | channels =
                                        SeqDict.updateIfExists
                                            id.channelId
                                            (LocalState.markCallMessageAsEndedBackend time)
                                            guild.channels
                                }
                            )
                            model.guilds
            }
    , Command.batch
        [ case maybeChangeId of
            Just changeId ->
                LocalChangeResponse changeId (Local_VoiceChatChange (Call.Local_Leave time))
                    |> Lamdera.sendToFrontend clientId

            Nothing ->
                Command.none
        , case roomId of
            Call.DmRoomId id ->
                Broadcast.toDmChannelExcludingOne
                    clientId
                    userId
                    id
                    (\otherUserId2 ->
                        Call.Server_Left
                            time
                            { roomId = Call.DmRoomId otherUserId2
                            , otherClientId = ( userId, clientId )
                            }
                            |> Server_VoiceChatChange
                    )
                    model

            Call.GuildRoomId id ->
                Broadcast.toGuildExcludingOne
                    clientId
                    id.guildId
                    (Call.Server_Left
                        time
                        { roomId = Call.GuildRoomId id
                        , otherClientId = ( userId, clientId )
                        }
                        |> Server_VoiceChatChange
                        |> ServerChange
                    )
                    model
        ]
    )


joinDmVoiceChat :
    SessionId
    -> ClientId
    -> Time.Posix
    -> Viewing_DmId
    -> BackendModel
    -> Id UserId
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
joinDmVoiceChat sessionId clientId time id model userId =
    let
        dmChannelId : DmChannelId
        dmChannelId =
            DmChannelId.fromUserIds userId id.otherUserId

        dmChannel : BackendDmChannel
        dmChannel =
            SeqDict.get dmChannelId model.dmChannels |> Maybe.withDefault DmChannel.backendInit
    in
    case SeqDict.get sessionId model.connections of
        Just connections ->
            case NonemptyDict.get clientId connections of
                Just connection ->
                    let
                        ( model2, leaveCmd ) =
                            case connection.call of
                                NotInCall ->
                                    ( model, Command.none )

                                ConnectedToCall oldVoiceChatId ->
                                    leaveVoiceHelper sessionId clientId time Nothing model userId oldVoiceChatId

                        voiceChatId : Call.CallId
                        voiceChatId =
                            Call.DmRoomId id

                        startsTheCall : Bool
                        startsTheCall =
                            dmVoiceChatRoomHasOtherMembers dmChannelId clientId model2 |> not

                        ( messageId, dmChannel2 ) =
                            LocalState.createChannelMessageBackend
                                (CallStarted
                                    { startedAt = time
                                    , endedAt = Nothing
                                    , startedBy = userId
                                    , reactions = SeqDict.empty
                                    , timestampDrawings = Drawing.emptyDrawing
                                    , cardDrawings = Drawing.emptyDrawing
                                    }
                                )
                                dmChannel

                        model3 : BackendModel
                        model3 =
                            { model2
                                | connections =
                                    SeqDict.update
                                        sessionId
                                        (Maybe.map
                                            (NonemptyDict.insert
                                                clientId
                                                { connection | call = ConnectedToCall voiceChatId }
                                            )
                                        )
                                        model2.connections
                                , dmChannels =
                                    if startsTheCall then
                                        SeqDict.insert dmChannelId dmChannel2 model2.dmChannels

                                    else
                                        model2.dmChannels
                                , users =
                                    if startsTheCall then
                                        BackendExtra.ownMessageIsReadBackend
                                            userId
                                            (GuildOrDmId (GuildOrDmId_Dm id))
                                            messageId
                                            model2.users

                                    else
                                        model2.users
                            }
                    in
                    ( model3
                    , Command.batch
                        [ Lamdera.sendToFrontend
                            clientId
                            (Call.Server_YouJoined time (Call.DmRoomId id)
                                |> Server_VoiceChatChange
                                |> ServerChange
                                |> ChangeBroadcast
                            )
                        , Broadcast.toDmChannelExcludingOne
                            clientId
                            userId
                            id
                            (\otherUserId2 ->
                                Call.Server_OtherJoined
                                    time
                                    { roomId = Call.DmRoomId otherUserId2
                                    , otherClientId = ( otherUserId2.otherUserId, clientId )
                                    }
                                    |> Server_VoiceChatChange
                            )
                            model3
                        , leaveCmd
                        ]
                    )

                Nothing ->
                    ( model, Command.none )

        _ ->
            ( model, Command.none )


joinGuildVoiceChat :
    SessionId
    -> ClientId
    -> Time.Posix
    -> Viewing_ChannelId
    -> BackendModel
    -> Id UserId
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
joinGuildVoiceChat sessionId clientId time id model userId =
    case ( SeqDict.get sessionId model.connections, SeqDict.get id.guildId model.guilds ) of
        ( Just connections, Just guild ) ->
            case ( NonemptyDict.get clientId connections, SeqDict.get id.channelId guild.channels ) of
                ( Just connection, Just channel ) ->
                    let
                        ( model2, leaveCmd ) =
                            case connection.call of
                                NotInCall ->
                                    ( model, Command.none )

                                ConnectedToCall oldVoiceChatId ->
                                    leaveVoiceHelper sessionId clientId time Nothing model userId oldVoiceChatId

                        voiceChatId : Call.CallId
                        voiceChatId =
                            Call.GuildRoomId id

                        startsTheCall : Bool
                        startsTheCall =
                            guildVoiceChatRoomHasOtherMembers id clientId model2 |> not

                        ( messageId, channel2 ) =
                            LocalState.createChannelMessageBackend
                                (CallStarted
                                    { startedAt = time
                                    , endedAt = Nothing
                                    , startedBy = userId
                                    , reactions = SeqDict.empty
                                    , timestampDrawings = Drawing.emptyDrawing
                                    , cardDrawings = Drawing.emptyDrawing
                                    }
                                )
                                channel

                        model3 : BackendModel
                        model3 =
                            { model2
                                | connections =
                                    SeqDict.update
                                        sessionId
                                        (Maybe.map
                                            (NonemptyDict.insert
                                                clientId
                                                { connection | call = ConnectedToCall voiceChatId }
                                            )
                                        )
                                        model2.connections
                                , guilds =
                                    if startsTheCall then
                                        SeqDict.insert
                                            id.guildId
                                            { guild | channels = SeqDict.insert id.channelId channel2 guild.channels }
                                            model2.guilds

                                    else
                                        model2.guilds
                                , users =
                                    if startsTheCall then
                                        BackendExtra.ownMessageIsReadBackend
                                            userId
                                            (GuildOrDmId (GuildOrDmId_Guild id))
                                            messageId
                                            model2.users

                                    else
                                        model2.users
                            }
                    in
                    ( model3
                    , Command.batch
                        [ Lamdera.sendToFrontend
                            clientId
                            (Call.Server_YouJoined time (Call.GuildRoomId id)
                                |> Server_VoiceChatChange
                                |> ServerChange
                                |> ChangeBroadcast
                            )
                        , Broadcast.toGuildExcludingOne
                            clientId
                            id.guildId
                            (Call.Server_OtherJoined
                                time
                                { roomId = Call.GuildRoomId id
                                , otherClientId = ( userId, clientId )
                                }
                                |> Server_VoiceChatChange
                                |> ServerChange
                            )
                            model3
                        , leaveCmd
                        ]
                    )

                _ ->
                    ( model, Command.none )

        _ ->
            ( model, Command.none )


dmVoiceChatRoomHasOtherMembers : DmChannelId -> ClientId -> BackendModel -> Bool
dmVoiceChatRoomHasOtherMembers dmChannelId clientId model =
    SeqDict.filter
        (\sessionId2 connections ->
            case SeqDict.get sessionId2 model.sessions of
                Just otherSession ->
                    NonemptyDict.any
                        (\otherClientId connection ->
                            case connection.call of
                                ConnectedToCall (Call.DmRoomId otherUserId2) ->
                                    (DmChannelId.fromUserIds otherUserId2.otherUserId otherSession.userId == dmChannelId)
                                        && (clientId /= otherClientId)

                                _ ->
                                    False
                        )
                        connections

                Nothing ->
                    False
        )
        model.connections
        |> SeqDict.isEmpty
        |> not


guildVoiceChatRoomHasOtherMembers : Viewing_ChannelId -> ClientId -> BackendModel -> Bool
guildVoiceChatRoomHasOtherMembers id clientId model =
    SeqDict.filter
        (\_ connections ->
            NonemptyDict.any
                (\otherClientId connection ->
                    case connection.call of
                        ConnectedToCall (Call.GuildRoomId otherId) ->
                            id == otherId && clientId /= otherClientId

                        _ ->
                            False
                )
                connections
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
    { a | messages : IdArray messageId (Message messageId userId channelId) }
    -> SeqDict (Id messageId) (Message messageId userId channelId)
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
        |> Thread.withRepliedToMessages channel.messages


handleMessagesRequest :
    PageRequest messageId
    -> { b | messages : IdArray messageId (Message messageId userId channelId) }
    -> SeqDict (Id messageId) (Message messageId userId channelId)
handleMessagesRequest pageRequest channel =
    let
        ( start, end ) =
            case pageRequest of
                PageBefore oldestVisibleMessage ->
                    ( max (Id.toInt oldestVisibleMessage - VisibleMessages.pageSize) 0
                    , Id.toInt oldestVisibleMessage
                    )

                PageFrom firstNewMessage ->
                    ( max (Id.toInt firstNewMessage) 0
                    , Id.toInt firstNewMessage + VisibleMessages.pageSize
                    )
    in
    -- A negative end would make Array.slice count back from the end of the whole channel
    IdArray.slice (Id.fromInt start) (Id.fromInt (max start end)) channel.messages
        |> IdArray.toList
        |> List.indexedMap (\index message -> ( Id.fromInt (index + start), message ))
        |> SeqDict.fromList
        |> Thread.withRepliedToMessages channel.messages


sendEditMessage :
    ClientId
    -> ChangeId
    -> Time.Posix
    -> Time.Zone
    -> NonemptyString
    -> SeqDict (Id FileId) FileData
    -> Viewing_ChannelId
    -> ThreadRouteWithMessage
    -> BackendModel
    -> Id UserId
    -> BackendGuild
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
sendEditMessage clientId changeId time timezone newContent attachedFiles2 id threadRoute model2 userId guild =
    case SeqDict.get id.channelId guild.channels of
        Just channel ->
            let
                guildMembers : SeqDict (Id UserId) BackendUser
                guildMembers =
                    List.foldl
                        (\memberId dict ->
                            case NonemptyDict.get memberId model2.users of
                                Just member ->
                                    SeqDict.insert memberId member dict

                                Nothing ->
                                    dict
                        )
                        SeqDict.empty
                        (MembersAndOwner.membersAndOwner guild.membersAndOwner)

                richText : Nonempty (RichText (Id UserId) (Id ChannelId))
                richText =
                    RichText.fromNonemptyString timezone guildMembers (LocalState.guildChannelNames timezone guildMembers guild.channels) newContent
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
                            SeqDict.insert
                                id.guildId
                                { guild
                                    | channels = SeqDict.insert id.channelId channel2 guild.channels
                                    , lastTypedAt = LocalState.forgetEditTyping userId id.channelId threadRoute guild.lastTypedAt
                                }
                                model2.guilds
                      }
                    , Command.batch
                        [ Local_SendEditMessage
                            time
                            timezone
                            (GuildOrDmId_Guild id)
                            threadRoute
                            newContent
                            attachedFiles2
                            |> LocalChangeResponse changeId
                            |> Lamdera.sendToFrontend clientId
                        , Broadcast.toGuildExcludingOne
                            clientId
                            id.guildId
                            (Server_SendEditMessage
                                time
                                userId
                                (GuildOrDmId_Guild id)
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


{-| Everything a newly linked Discord account brings with it starts out read. The
messages were written before the user could see them here, so treating them as unread
would bury the app in notifications the moment an account is linked.
-}
markDiscordDataAsViewed : Discord.Id Discord.UserId -> Id UserId -> BackendModel -> BackendModel
markDiscordDataAsViewed discordUserId userId model =
    { model
        | users =
            NonemptyDict.updateIfExists
                userId
                (\user ->
                    let
                        guildsViewed : BackendUser
                        guildsViewed =
                            SeqDict.foldl
                                (\guildId guild state ->
                                    case MembersAndOwner.isMember discordUserId guild.membersAndOwner of
                                        MembersAndOwner.IsNotMember ->
                                            state

                                        _ ->
                                            LocalState.markAllDiscordChannelsAndThreadsAsViewedBackend
                                                discordUserId
                                                guildId
                                                guild
                                                state
                                )
                                user
                                model.discordGuilds
                    in
                    SeqDict.foldl
                        (\channelId dmChannel state ->
                            if NonemptyDict.member discordUserId dmChannel.members then
                                LocalState.markDiscordDmAsViewedBackend discordUserId channelId dmChannel state

                            else
                                state
                        )
                        guildsViewed
                        model.discordDmChannels
                )
                model.users
    }


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
            if SeqSet.member session.userId guild.bannedUsers then
                ( model
                , Err YouAreBanned
                    |> Server_YouJoinedGuildByInvite
                    |> ServerChange
                    |> ChangeBroadcast
                    |> Lamdera.sendToFrontends sessionId
                )

            else
                joinGuildByInviteHelper inviteLinkId time sessionId clientId guildId model session user guild

        Nothing ->
            ( model, Command.none )


joinGuildByInviteHelper :
    SecretId InviteLinkId
    -> Time.Posix
    -> SessionId
    -> ClientId
    -> Id GuildId
    -> BackendModel
    -> UserSession
    -> BackendUser
    -> BackendGuild
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
joinGuildByInviteHelper inviteLinkId time sessionId clientId guildId model session user guild =
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
                                (LocalState.markAllChannelsAndThreadsAsViewedBackend guildId guild2 user)
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
                        guildId
                        (Just ( LocalState.announcementChannel guild2, ( NoThread, Nothing ) ))
                        session.userId
                        model2.goMatchPublicIds
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
            case user.email of
                UserHasEmail email ->
                    case TwoFactorAuthentication.getConfig (EmailAddress.toString email) secret of
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

                DeletedUser ->
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


{-| Admin data the frontend asked for on its way back to the client that asked. Only that
client gets it, since another admin's page won't have the section open.
-}
adminDataResponse : ChangeId -> ClientId -> Pages.Admin.AdminChange -> Command BackendOnly ToFrontend BackendMsg
adminDataResponse changeId clientId adminChange =
    Local_Admin adminChange
        |> LocalChangeResponse changeId
        |> Lamdera.sendToFrontend clientId


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

        Pages.Admin.LoadUsers _ ->
            ( model, adminDataResponse changeId clientId (Pages.Admin.LoadUsers (FilledInByBackend model.users)) )

        Pages.Admin.LoadGuilds _ ->
            ( model, adminDataResponse changeId clientId (Pages.Admin.LoadGuilds (FilledInByBackend (BackendExtra.adminGuilds model))) )

        Pages.Admin.LoadDeletedGuilds _ ->
            ( model
            , adminDataResponse
                changeId
                clientId
                (Pages.Admin.LoadDeletedGuilds (FilledInByBackend (BackendExtra.adminDeletedGuilds model)))
            )

        Pages.Admin.LoadDmChannels _ ->
            ( model
            , adminDataResponse
                changeId
                clientId
                (Pages.Admin.LoadDmChannels (FilledInByBackend (BackendExtra.adminDmChannels model)))
            )

        Pages.Admin.LoadDiscordGuilds _ ->
            ( model
            , adminDataResponse
                changeId
                clientId
                (Pages.Admin.LoadDiscordGuilds (FilledInByBackend (BackendExtra.adminDiscordGuilds model)))
            )

        Pages.Admin.LoadSlackWorkspaces _ ->
            ( model
            , adminDataResponse
                changeId
                clientId
                (Pages.Admin.LoadSlackWorkspaces (FilledInByBackend (BackendExtra.adminSlackWorkspaces model)))
            )

        Pages.Admin.LoadSlackDmChannels _ ->
            ( model
            , adminDataResponse
                changeId
                clientId
                (Pages.Admin.LoadSlackDmChannels (FilledInByBackend (BackendExtra.adminSlackDmChannels model)))
            )

        Pages.Admin.LoadDiscordDmChannels _ ->
            ( model
            , adminDataResponse
                changeId
                clientId
                (Pages.Admin.LoadDiscordDmChannels (FilledInByBackend (BackendExtra.adminDiscordDmChannels model)))
            )

        Pages.Admin.LoadDiscordUsers _ ->
            ( model
            , adminDataResponse
                changeId
                clientId
                (Pages.Admin.LoadDiscordUsers (FilledInByBackend (BackendExtra.adminDiscordUsers model)))
            )

        Pages.Admin.LoadSessions _ ->
            ( model
            , adminDataResponse
                changeId
                clientId
                (Pages.Admin.LoadSessions (FilledInByBackend (BackendExtra.adminSessions model)))
            )

        Pages.Admin.LoadWebsocketCloseEvents _ ->
            ( model
            , adminDataResponse
                changeId
                clientId
                (Pages.Admin.LoadWebsocketCloseEvents (FilledInByBackend model.websocketCloseEvents))
            )

        Pages.Admin.LoadOrphanedFiles _ ->
            ( model
            , adminDataResponse
                changeId
                clientId
                (Pages.Admin.LoadOrphanedFiles (FilledInByBackend (DeleteUserAndFiles.orphanedFiles model)))
            )

        Pages.Admin.LoadToBackendLogs _ ->
            ( model
            , adminDataResponse
                changeId
                clientId
                (Pages.Admin.LoadToBackendLogs (FilledInByBackend model.toBackendLogs))
            )

        Pages.Admin.LoadBackendMsgLogs _ ->
            ( model
            , adminDataResponse
                changeId
                clientId
                (Pages.Admin.LoadBackendMsgLogs (FilledInByBackend model.backendMsgLogs))
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

        Pages.Admin.SetDiscordLinkLimit limit ->
            let
                model2 =
                    { model | discordLinkLimit = limit }
            in
            ( model2
            , Command.batch
                [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                , Broadcast.toOtherAdmins clientId model2 (LocalChange userId localMsg)
                ]
            )

        Pages.Admin.SetSlackLinkingEnabled isEnabled ->
            let
                model2 =
                    { model | slackLinkingEnabled = isEnabled }
            in
            ( model2
            , Command.batch
                [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                , Broadcast.toOtherAdmins clientId model2 (LocalChange userId localMsg)
                ]
            )

        Pages.Admin.SetSlackLinkLimit limit ->
            let
                model2 =
                    { model | slackLinkLimit = limit }
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

        Pages.Admin.SetOpenRouterKey openRouterKey ->
            ( { model | openRouterKey = openRouterKey }
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

        Pages.Admin.DeleteSlackWorkspace teamId ->
            let
                model2 : BackendModel
                model2 =
                    { model | slackWorkspaces = SeqDict.remove teamId model.slackWorkspaces }
            in
            ( model2
            , Command.batch
                [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                , Broadcast.toOtherAdmins clientId model2 (LocalChange userId localMsg)
                ]
            )

        Pages.Admin.DeleteSlackDmChannel channelId ->
            let
                model2 : BackendModel
                model2 =
                    { model | slackDmChannels = SeqDict.remove channelId model.slackDmChannels }
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
                , ( LocalState.userIsLoadingDiscordChannel userIdToLoadWith model.loadingDiscordChannels
                  , LocalState.getDiscordGuildAndChannel guildId channelId model
                  )
                )
            of
                ( Just (FullData discordUser), Nothing, ( False, Just ( _, channel ) ) ) ->
                    let
                        auth =
                            Discord.userToken discordUser.auth

                        reload : Task BackendOnly Discord.HttpError DiscordChannelReload
                        reload =
                            if channel.isForum then
                                DiscordSync.getForumChannelReload model.serverSecret auth channelId

                            else
                                DiscordSync.getManyMessages
                                    model.serverSecret
                                    auth
                                    { channelId = channelId, limit = DiscordSync.reloadChannelMaxMessages }
                                    |> Task.andThen
                                        (\messages ->
                                            DiscordSync.getThreadsForMessages model.serverSecret auth messages
                                                |> Task.map (\threads -> { messages = messages, threads = threads })
                                        )
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
                        , Task.attempt (GotDiscordGuildChannelMessages time userIdToLoadWith guildId channelId) reload
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

        Pages.Admin.ReloadDiscordGuild userIdToLoadWith guildId _ ->
            case SeqDict.get userIdToLoadWith model.discordUsers of
                Just (FullData discordUser) ->
                    let
                        token : Discord.Authentication
                        token =
                            Discord.userToken discordUser.auth
                    in
                    ( model
                    , Task.map2
                        Tuple.pair
                        (Discord.getGuildPayload token guildId |> DiscordSync.http model.serverSecret)
                        (Discord.getGuildChannelsPayload token guildId |> DiscordSync.http model.serverSecret)
                        |> Task.attempt (ReloadedDiscordGuildForAdmin time changeId clientId userIdToLoadWith guildId)
                    )

                _ ->
                    ( model, BackendExtra.invalidChangeResponse changeId clientId )

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

        Pages.Admin.DeleteOrphanedFiles _ ->
            let
                orphanedFiles : List FileHash
                orphanedFiles =
                    SeqDict.keys (DeleteUserAndFiles.orphanedFiles model)
            in
            ( model
            , DeleteUserAndFiles.deleteFiles model.serverSecret orphanedFiles
                |> Task.attempt (DeletedOrphanedFiles time changeId clientId orphanedFiles)
            )

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


updateFromFrontendAdmin :
    Time.Posix
    -> ClientId
    -> Pages.Admin.ToBackend
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
updateFromFrontendAdmin time clientId toBackend model =
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
                        , lastBackup = Nothing
                        , downloadBackupState = Nothing
                        , scheduledExportState = Nothing
                    }

                remainingGuilds : List ( Id GuildId, BackendGuild )
                remainingGuilds =
                    case isPartial of
                        ExportSubset selection ->
                            SeqDict.toList model.guilds
                                |> List.filter (\( guildId, _ ) -> SeqSet.member guildId selection.guilds)

                        ExportAll ->
                            SeqDict.toList model.guilds

                remainingDiscordGuilds : List ( Discord.Id Discord.GuildId, DiscordBackendGuild )
                remainingDiscordGuilds =
                    case isPartial of
                        ExportSubset selection ->
                            SeqDict.toList model.discordGuilds
                                |> List.filter (\( guildId, _ ) -> SeqSet.member guildId selection.discordGuilds)

                        ExportAll ->
                            SeqDict.toList model.discordGuilds

                remainingDmChannels : List ( DmChannelId, BackendDmChannel )
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
                        , remainingGuilds = remainingGuilds
                        , remainingGuildChannels = []
                        , encodedGuildCount = 0
                        , encodedGuilds = []
                        , remainingDmChannels = remainingDmChannels
                        , encodedDmChannels = []
                        , remainingDiscordGuilds = remainingDiscordGuilds
                        , remainingDiscordGuildChannels = []
                        , encodedDiscordGuildCount = 0
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

        Pages.Admin.DownloadLastBackupRequest ->
            ( case model.lastBackup of
                Just lastBackup ->
                    { model
                        | downloadBackupState =
                            BackupDownload
                                { contents = lastBackup.backup.contents
                                , remainingBytes = lastBackup.bytes
                                , totalBytes = Bytes.width lastBackup.bytes
                                , clientId = clientId
                                }
                                |> Just
                    }

                Nothing ->
                    model
            , Command.none
            )

        Pages.Admin.ImportBackendChunkRequest { totalBytes, offset } chunk ->
            let
                upload : Maybe UploadBackupState
                upload =
                    if offset == 0 then
                        Just { totalBytes = totalBytes, receivedBytes = Bytes.width chunk, chunks = [ chunk ], clientId = clientId }

                    else
                        case model.downloadBackupState of
                            Just (BackupUpload upload2) ->
                                if upload2.receivedBytes == offset && upload2.totalBytes == totalBytes && upload2.clientId == clientId then
                                    Just
                                        { upload2
                                            | receivedBytes = upload2.receivedBytes + Bytes.width chunk
                                            , chunks = chunk :: upload2.chunks
                                        }

                                else
                                    Nothing

                            _ ->
                                Nothing
            in
            case upload of
                Just upload2 ->
                    if upload2.receivedBytes < upload2.totalBytes then
                        ( { model | downloadBackupState = Just (BackupUpload upload2) }
                        , Lamdera.sendToFrontend clientId (Pages.Admin.ImportBackendChunkReceived upload2.receivedBytes |> AdminToFrontend)
                        )

                    else
                        case
                            List.reverse upload2.chunks
                                |> List.map Bytes.Encode.bytes
                                |> Bytes.Encode.sequence
                                |> Bytes.Encode.encode
                                |> Bytes.Decode.decode WireHelper.decodeStreamedBackendModel
                        of
                            Just model2 ->
                                ( model2
                                , Lamdera.sendToFrontend clientId (Pages.Admin.ImportBackendResponse (Ok ()) |> AdminToFrontend)
                                )

                            Nothing ->
                                ( { model | downloadBackupState = Nothing }
                                , Lamdera.sendToFrontend clientId (Pages.Admin.ImportBackendResponse (Err ()) |> AdminToFrontend)
                                )

                Nothing ->
                    ( { model | downloadBackupState = Nothing }
                    , Lamdera.sendToFrontend clientId (Pages.Admin.ImportBackendResponse (Err ()) |> AdminToFrontend)
                    )

        Pages.Admin.TypeThatIsAlwaysInvalidRequest _ ->
            BackendExtra.addLog time Log.ReceivedTypeThatIsAlwaysInvalid model


{-| How much of a backup gets sent in each ToFrontend message. Sending the whole backup
at once blocks the websocket for long enough that the connection times out.
-}
downloadBackupChunkSize : Int
downloadBackupChunkSize =
    5 * 1024 * 1024


handleExportBackendStep : ExportStateProgress -> ExportStep
handleExportBackendStep exportState =
    case ( exportState.remainingGuildChannels, exportState.remainingGuilds ) of
        ( entry :: rest, _ ) ->
            ExportInProgress
                (Pages.Admin.ExportingGuilds
                    { channelsRemaining = List.length rest
                    , encoded = exportState.encodedGuildCount
                    , total = exportState.encodedGuildCount + List.length exportState.remainingGuilds
                    }
                )
                { exportState
                    | remainingGuildChannels = rest
                    , encodedGuilds =
                        Bytes.Encode.encode (WireHelper.encodeGuildChannel entry) :: exportState.encodedGuilds
                }

        ( [], ( guildId, guild ) :: rest ) ->
            ExportInProgress
                (Pages.Admin.ExportingGuilds
                    { channelsRemaining = 0
                    , encoded = exportState.encodedGuildCount + 1
                    , total = exportState.encodedGuildCount + 1 + List.length rest
                    }
                )
                { exportState
                    | remainingGuilds = rest
                    , remainingGuildChannels = SeqDict.toList guild.channels
                    , encodedGuildCount = exportState.encodedGuildCount + 1
                    , encodedGuilds =
                        Bytes.Encode.encode (WireHelper.encodeGuildHeader ( guildId, guild ))
                            :: exportState.encodedGuilds
                }

        ( [], [] ) ->
            case exportState.remainingDmChannels of
                entry :: rest ->
                    let
                        encodedCount : Int
                        encodedCount =
                            List.length exportState.encodedDmChannels
                    in
                    ExportInProgress
                        (Pages.Admin.ExportingDmChannels
                            { encoded = encodedCount + 1
                            , total = encodedCount + List.length exportState.remainingDmChannels
                            }
                        )
                        { exportState
                            | remainingDmChannels = rest
                            , encodedDmChannels = Bytes.Encode.encode (WireHelper.encodeDmChannel entry) :: exportState.encodedDmChannels
                        }

                [] ->
                    case ( exportState.remainingDiscordGuildChannels, exportState.remainingDiscordGuilds ) of
                        ( entry :: rest, _ ) ->
                            ExportInProgress
                                (Pages.Admin.ExportingDiscordGuilds
                                    { channelsRemaining = List.length rest
                                    , encoded = exportState.encodedDiscordGuildCount
                                    , total = exportState.encodedDiscordGuildCount + List.length exportState.remainingDiscordGuilds
                                    }
                                )
                                { exportState
                                    | remainingDiscordGuildChannels = rest
                                    , encodedDiscordGuilds =
                                        Bytes.Encode.encode (WireHelper.encodeDiscordGuildChannel entry)
                                            :: exportState.encodedDiscordGuilds
                                }

                        ( [], ( guildId, guild ) :: rest ) ->
                            ExportInProgress
                                (Pages.Admin.ExportingDiscordGuilds
                                    { channelsRemaining = 0
                                    , encoded = exportState.encodedDiscordGuildCount + 1
                                    , total = exportState.encodedDiscordGuildCount + 1 + List.length rest
                                    }
                                )
                                { exportState
                                    | remainingDiscordGuilds = rest
                                    , remainingDiscordGuildChannels = SeqDict.toList guild.channels
                                    , encodedDiscordGuildCount = exportState.encodedDiscordGuildCount + 1
                                    , encodedDiscordGuilds =
                                        Bytes.Encode.encode (WireHelper.encodeDiscordGuildHeader ( guildId, guild ))
                                            :: exportState.encodedDiscordGuilds
                                }

                        ( [], [] ) ->
                            case exportState.remainingDiscordDmChannels of
                                entry :: rest ->
                                    let
                                        encodedCount : Int
                                        encodedCount =
                                            List.length exportState.encodedDiscordDmChannels
                                    in
                                    ExportInProgress
                                        (Pages.Admin.ExportingDiscordDmChannels
                                            { encoded = encodedCount + 1
                                            , total = encodedCount + List.length exportState.remainingDiscordDmChannels
                                            }
                                        )
                                        { exportState
                                            | remainingDiscordDmChannels = rest
                                            , encodedDiscordDmChannels =
                                                Bytes.Encode.encode (WireHelper.encodeDiscordDmChannel entry)
                                                    :: exportState.encodedDiscordDmChannels
                                        }

                                [] ->
                                    let
                                        encodeItemList : Int -> List Bytes -> Bytes.Encode.Encoder
                                        encodeItemList count items =
                                            Bytes.Encode.sequence
                                                (Bytes.Encode.unsignedInt32 Bytes.BE count
                                                    :: List.map Bytes.Encode.bytes (List.reverse items)
                                                )

                                        exportedBytes : Bytes
                                        exportedBytes =
                                            Bytes.Encode.encode
                                                (Bytes.Encode.sequence
                                                    [ Bytes.Encode.bytes exportState.baseModel
                                                    , encodeItemList exportState.encodedGuildCount exportState.encodedGuilds
                                                    , encodeItemList (List.length exportState.encodedDmChannels) exportState.encodedDmChannels
                                                    , encodeItemList exportState.encodedDiscordGuildCount exportState.encodedDiscordGuilds
                                                    , encodeItemList (List.length exportState.encodedDiscordDmChannels) exportState.encodedDiscordDmChannels
                                                    ]
                                                )
                                    in
                                    ExportFinished exportedBytes


slackPendingSendKey : SlackGuildOrDmId -> ( Slack.Id Slack.UserId, String )
slackPendingSendKey guildOrDmId =
    case guildOrDmId of
        SlackGuildOrDmId_Workspace { currentUserId, channelId } ->
            ( currentUserId, Slack.idToString channelId )

        SlackGuildOrDmId_Dm { currentUserId, channelId } ->
            ( currentUserId, Slack.idToString channelId )


{-| The same jittered exponential backoff as Discord's gateway: 0s, 1s, 3s, 7s… up to a minute,
each shortened by up to half. Slack's hello event resets it.
-}
nextSlackReconnectDelay : { failedAttempts : Int, seed : Int } -> ( Duration, { failedAttempts : Int, seed : Int } )
nextSlackReconnectDelay reconnect =
    let
        ( ( jitter, nextSeed ), _ ) =
            Random.step
                (Random.map2 Tuple.pair (Random.float 0.5 1) (Random.int Random.minInt Random.maxInt))
                (Random.initialSeed reconnect.seed)
    in
    ( Duration.seconds (2 ^ toFloat reconnect.failedAttempts - 1)
        |> Quantity.min (Duration.seconds 60)
        |> Quantity.multiplyBy jitter
    , { failedAttempts = reconnect.failedAttempts + 1, seed = nextSeed }
    )


{-| Slack doesn't say which channels are DMs in its websocket events, so the channel ID is
looked up in the linked user's workspace first and then among the DMs.
-}
slackChannelFromWebsocket : SlackLinkedUser -> Slack.Id Slack.UserId -> String -> BackendModel -> Maybe SlackGuildOrDmId
slackChannelFromWebsocket linkedUser author channelString model =
    let
        channelId : Slack.Id Slack.ChannelId
        channelId =
            Slack.Id channelString

        dmChannelId : Slack.Id Slack.DmChannelId
        dmChannelId =
            Slack.Id channelString
    in
    case LocalState.getSlackWorkspaceAndChannel linkedUser.user.teamId channelId model of
        Just _ ->
            SlackGuildOrDmId_Workspace { currentUserId = author, teamId = linkedUser.user.teamId, channelId = channelId }
                |> Just

        Nothing ->
            if SeqDict.member dmChannelId model.slackDmChannels then
                SlackGuildOrDmId_Dm { currentUserId = author, channelId = dmChannelId } |> Just

            else
                Nothing


websocketEventUserIds : Slack.WebsocketEvent -> List (Slack.Id Slack.UserId)
websocketEventUserIds event =
    case event of
        Slack.WebsocketMessageCreated _ message ->
            Slack.messageUserIds message

        Slack.WebsocketMessageChanged _ message _ ->
            Slack.messageUserIds message

        Slack.WebsocketMessageDeleted _ _ _ ->
            []

        Slack.WebsocketReactionAdded { user } ->
            [ user ]

        Slack.WebsocketReactionRemoved { user } ->
            [ user ]

        Slack.WebsocketRelayReady ->
            []

        Slack.WebsocketHello ->
            []

        Slack.WebsocketUserChanged _ ->
            []

        Slack.WebsocketTeamRenamed _ ->
            []

        Slack.WebsocketTeamDomainChanged _ ->
            []

        Slack.WebsocketConversationsChanged ->
            []

        Slack.WebsocketChannelRenamed _ _ ->
            []

        Slack.WebsocketOtherEvent ->
            []


{-| Linking only loads the users in the messages it loaded, so anyone else is looked up the first
time they show up.
-}
lookUpUnknownSlackUsers :
    SlackLinkedUser
    -> List (Slack.Id Slack.UserId)
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
lookUpUnknownSlackUsers linkedUser userIds model =
    let
        unknown : List (Slack.Id Slack.UserId)
        unknown =
            SeqSet.fromList userIds
                |> SeqSet.filter
                    (\userId ->
                        not (SeqDict.member userId model.slackUsers || SeqSet.member userId model.pendingSlackUserLookups)
                    )
                |> SeqSet.toList
    in
    ( { model | pendingSlackUserLookups = List.foldl SeqSet.insert model.pendingSlackUserLookups unknown }
    , List.map
        (\userId ->
            Slack.userInfo model.serverSecret linkedUser.cookie linkedUser.token linkedUser.user.teamId userId
                |> Task.andThen (\user -> uploadSlackImage model.serverSecret user.image |> Task.map (Tuple.pair user))
                |> Task.attempt (GotSlackUser userId)
        )
        unknown
        |> Command.batch
    )


websocketEventFiles : Slack.WebsocketEvent -> List Slack.File
websocketEventFiles event =
    case event of
        Slack.WebsocketMessageCreated _ message ->
            Slack.messageFiles message

        Slack.WebsocketMessageChanged _ message _ ->
            Slack.messageFiles message

        Slack.WebsocketMessageDeleted _ _ _ ->
            []

        Slack.WebsocketReactionAdded _ ->
            []

        Slack.WebsocketReactionRemoved _ ->
            []

        Slack.WebsocketRelayReady ->
            []

        Slack.WebsocketHello ->
            []

        Slack.WebsocketUserChanged _ ->
            []

        Slack.WebsocketTeamRenamed _ ->
            []

        Slack.WebsocketTeamDomainChanged _ ->
            []

        Slack.WebsocketConversationsChanged ->
            []

        Slack.WebsocketChannelRenamed _ _ ->
            []

        Slack.WebsocketOtherEvent ->
            []


{-| Copies the files to at-chat. A file that fails to copy is left out, so its message shows
without it.
-}
uploadSlackFiles :
    SecretId ServerSecret
    -> SlackCookie
    -> SlackToken
    -> List Slack.File
    -> Task BackendOnly x (SeqDict (Slack.Id Slack.FileId) SlackFileData)
uploadSlackFiles secretKey cookie token files =
    List.map
        (\file ->
            FileStatus.uploadUrl secretKey file.url (Slack.fileHeaders cookie token)
                |> Task.map
                    (\uploadResponse ->
                        Just
                            ( file.id
                            , { fileHash = uploadResponse.fileHash, metadata = FileStatus.uploadResponseMetadata uploadResponse }
                            )
                    )
                |> Task.onError (\_ -> Task.succeed Nothing)
        )
        (List.filter
            (\file -> Slack.isHostedBySlack file && file.size <= FileStatus.maxUploadSize)
            (List.Extra.uniqueBy (\file -> Slack.idToString file.id) files)
        )
        |> Task.sequence
        |> Task.map (\results -> List.filterMap identity results |> SeqDict.fromList)


{-| Profile pictures and workspace icons don't need credentials to download.
-}
uploadSlackImage : SecretId ServerSecret -> String -> Task BackendOnly x (Maybe FileHash)
uploadSlackImage secretKey url =
    if url == "" then
        Task.succeed Nothing

    else
        FileStatus.uploadUrl secretKey url []
            |> Task.map (\uploadResponse -> Just uploadResponse.fileHash)
            |> Task.onError (\_ -> Task.succeed Nothing)


handleSlackWebsocketEvent :
    SlackLinkedUser
    -> Slack.WebsocketEvent
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleSlackWebsocketEvent linkedUser event model =
    case event of
        Slack.WebsocketRelayReady ->
            case linkedUser.websocket of
                Just connection ->
                    ( model
                    , Websocket.sendString
                        connection
                        (Slack.websocketRelayRequest model.serverSecret linkedUser.cookie linkedUser.token)
                        |> Task.attempt (SlackWebsocketSentData linkedUser.user.id)
                    )

                Nothing ->
                    ( model, Command.none )

        Slack.WebsocketMessageCreated channelString message ->
            case
                ( slackChannelFromWebsocket linkedUser message.user channelString model
                , ( SlackSync.toMessage model.slackFiles message, SlackSync.toMessage model.slackFiles message )
                )
            of
                ( Just guildOrDmId, ( Just (UserTextMessage data), Just (UserTextMessage threadData) ) ) ->
                    if SeqDict.member (slackPendingSendKey guildOrDmId) model.pendingSlackSends then
                        -- Probably the message at-chat is sending right now. SentSlackMessage adds it instead.
                        ( model, Command.none )

                    else
                        let
                            ( data2, embedCmds ) =
                                Message.loadEmbeds model.serverSecret data

                            ( threadData2, _ ) =
                                Message.loadEmbeds model.serverSecret threadData

                            parentId : Slack.Id Slack.MessageId -> List ThreadRoute
                            parentId slackParentId =
                                case
                                    getSlackConversation guildOrDmId model
                                        |> Maybe.andThen (\conversation -> OneToOne.second slackParentId conversation.linkedMessageIds)
                                of
                                    Just threadId ->
                                        [ ViewThread threadId ]

                                    Nothing ->
                                        []

                            threadRoutes : List ThreadRoute
                            threadRoutes =
                                case message.inThread of
                                    Slack.NotAReply ->
                                        [ NoThread ]

                                    Slack.ReplyTo slackParentId ->
                                        parentId slackParentId

                                    Slack.BroadcastReplyTo slackParentId ->
                                        NoThread :: parentId slackParentId
                        in
                        List.foldl
                            (\threadRoute ( model2, cmds ) ->
                                case
                                    updateSlackConversation
                                        guildOrDmId
                                        (addToSlackConversation threadRoute message.id (UserTextMessage data2) (UserTextMessage threadData2))
                                        model2
                                of
                                    Just ( model3, threadRouteWithMessage ) ->
                                        let
                                            ( model4, notificationCmds ) =
                                                slackMessageAdded message.createdAt guildOrDmId threadRouteWithMessage data2 model3
                                        in
                                        ( model4
                                        , Broadcast.toSlack
                                            guildOrDmId
                                            (Server_Slack_SendMessage message.createdAt guildOrDmId threadRoute data2.content.content data2.content.attachedFiles (slackThreadStarter guildOrDmId threadRoute model4) |> ServerChange)
                                            model4
                                            :: Command.map identity (SlackGotMessageEmbed guildOrDmId threadRouteWithMessage) embedCmds
                                            :: notificationCmds
                                            ++ cmds
                                        )

                                    Nothing ->
                                        ( model2, cmds )
                            )
                            ( model, [] )
                            threadRoutes
                            |> Tuple.mapSecond Command.batch

                ( Nothing, _ ) ->
                    refreshSlackConversations linkedUser model

                _ ->
                    ( model, Command.none )

        Slack.WebsocketMessageChanged channelString message editedAt ->
            case
                ( slackChannelFromWebsocket linkedUser message.user channelString model
                , SlackSync.toMessage model.slackFiles message
                )
            of
                ( Just guildOrDmId, Just (UserTextMessage data) ) ->
                    let
                        content : Nonempty (RichText (Slack.Id Slack.UserId) (Slack.Id Slack.ChannelId))
                        content =
                            data.content.content
                    in
                    case
                        updateSlackConversation
                            guildOrDmId
                            (\conversation -> editSlackMessage editedAt message.user content message.id conversation |> Just)
                            model
                    of
                        Just ( model2, edited ) ->
                            ( model2
                            , List.map
                                (\threadRoute ->
                                    Broadcast.toSlack
                                        guildOrDmId
                                        (Server_Slack_EditMessage editedAt message.user guildOrDmId threadRoute content |> ServerChange)
                                        model2
                                )
                                edited
                                |> Command.batch
                            )

                        Nothing ->
                            ( model, Command.none )

                _ ->
                    ( model, Command.none )

        Slack.WebsocketMessageDeleted channelString author slackMessageId ->
            case slackChannelFromWebsocket linkedUser author channelString model of
                Just guildOrDmId ->
                    case
                        updateSlackConversation
                            guildOrDmId
                            (\conversation -> deleteSlackMessage author slackMessageId conversation |> Just)
                            model
                    of
                        Just ( model2, deleted ) ->
                            ( model2
                            , List.map
                                (\threadRoute ->
                                    Broadcast.toSlack
                                        guildOrDmId
                                        (Server_Slack_DeleteMessage guildOrDmId threadRoute |> ServerChange)
                                        model2
                                )
                                deleted
                                |> Command.batch
                            )

                        Nothing ->
                            ( model, Command.none )

                Nothing ->
                    ( model, Command.none )

        Slack.WebsocketReactionAdded { user, reaction, channel, messageId } ->
            case ( slackChannelFromWebsocket linkedUser user channel model, SlackEmoji.fromSlackName reaction ) of
                ( Just guildOrDmId, Just unicodeEmoji ) ->
                    let
                        emoji : EmojiOrCustomEmoji
                        emoji =
                            EmojiOrCustomEmoji_Emoji unicodeEmoji
                    in
                    case
                        updateSlackConversation
                            guildOrDmId
                            (\conversation ->
                                let
                                    locations : List ThreadRouteWithMessage
                                    locations =
                                        slackMessageLocations messageId conversation
                                in
                                ( List.foldl (LocalState.addReactionEmoji emoji user) conversation locations, locations ) |> Just
                            )
                            model
                    of
                        Just ( model2, locations ) ->
                            ( model2
                            , List.map
                                (\threadRoute ->
                                    Broadcast.toSlack
                                        guildOrDmId
                                        (Server_Slack_AddReactionEmoji user guildOrDmId threadRoute emoji |> ServerChange)
                                        model2
                                )
                                locations
                                |> Command.batch
                            )

                        Nothing ->
                            ( model, Command.none )

                ( Just _, Nothing ) ->
                    ( model, Command.none )

                ( Nothing, Just _ ) ->
                    ( model, Command.none )

                ( Nothing, Nothing ) ->
                    ( model, Command.none )

        Slack.WebsocketReactionRemoved { user, reaction, channel, messageId } ->
            case ( slackChannelFromWebsocket linkedUser user channel model, SlackEmoji.fromSlackName reaction ) of
                ( Just guildOrDmId, Just unicodeEmoji ) ->
                    let
                        emoji : EmojiOrCustomEmoji
                        emoji =
                            EmojiOrCustomEmoji_Emoji unicodeEmoji
                    in
                    case
                        updateSlackConversation
                            guildOrDmId
                            (\conversation ->
                                let
                                    locations : List ThreadRouteWithMessage
                                    locations =
                                        slackMessageLocations messageId conversation
                                in
                                ( List.foldl (LocalState.removeReactionEmoji emoji user) conversation locations, locations ) |> Just
                            )
                            model
                    of
                        Just ( model2, locations ) ->
                            ( model2
                            , List.map
                                (\threadRoute ->
                                    Broadcast.toSlack
                                        guildOrDmId
                                        (Server_Slack_RemoveReactionEmoji user guildOrDmId threadRoute emoji |> ServerChange)
                                        model2
                                )
                                locations
                                |> Command.batch
                            )

                        Nothing ->
                            ( model, Command.none )

                ( Just _, Nothing ) ->
                    ( model, Command.none )

                ( Nothing, Just _ ) ->
                    ( model, Command.none )

                ( Nothing, Nothing ) ->
                    ( model, Command.none )

        Slack.WebsocketHello ->
            ( { model
                | slackUsers =
                    SeqDict.insert
                        linkedUser.user.id
                        (SlackFullData { linkedUser | reconnect = { failedAttempts = 0, seed = linkedUser.reconnect.seed } })
                        model.slackUsers
              }
            , if linkedUser.reconnect.failedAttempts > 0 then
                catchUpSlackConversations linkedUser model

              else
                Command.none
            )

        Slack.WebsocketUserChanged user ->
            case SeqDict.get user.id model.slackUsers of
                Just (SlackBasicData existing) ->
                    if user.teamId /= linkedUser.user.teamId || existing.user == user then
                        ( model, Command.none )

                    else if existing.user.image == user.image then
                        slackUserChanged user existing.icon model

                    else
                        ( model, uploadSlackImage model.serverSecret user.image |> Task.perform (GotChangedSlackUser user) )

                Just (SlackFullData existing) ->
                    if user.teamId /= linkedUser.user.teamId || existing.user == user then
                        ( model, Command.none )

                    else if existing.user.image == user.image then
                        slackUserChanged user existing.icon model

                    else
                        ( model, uploadSlackImage model.serverSecret user.image |> Task.perform (GotChangedSlackUser user) )

                Nothing ->
                    ( model, Command.none )

        Slack.WebsocketTeamRenamed name ->
            let
                teamId : Slack.Id Slack.TeamId
                teamId =
                    linkedUser.user.teamId

                model2 : BackendModel
                model2 =
                    { model
                        | slackWorkspaces =
                            SeqDict.updateIfExists teamId (\workspace -> { workspace | name = name }) model.slackWorkspaces
                    }
            in
            ( model2
            , Broadcast.toSlackTeam teamId (Server_Slack_WorkspaceRenamed teamId name |> ServerChange) model2
            )

        Slack.WebsocketConversationsChanged ->
            refreshSlackConversations linkedUser model

        Slack.WebsocketChannelRenamed channelId name ->
            let
                teamId : Slack.Id Slack.TeamId
                teamId =
                    linkedUser.user.teamId

                channelName : ChannelName
                channelName =
                    ChannelName.fromStringLossy name

                model2 : BackendModel
                model2 =
                    { model
                        | slackWorkspaces =
                            SeqDict.updateIfExists
                                teamId
                                (\workspace ->
                                    { workspace
                                        | channels =
                                            SeqDict.updateIfExists
                                                channelId
                                                (\channel -> { channel | name = channelName })
                                                workspace.channels
                                    }
                                )
                                model.slackWorkspaces
                    }
            in
            ( model2
            , Broadcast.toSlackTeam teamId (Server_Slack_ChannelRenamed teamId channelId channelName |> ServerChange) model2
            )

        Slack.WebsocketTeamDomainChanged domain ->
            ( { model
                | slackWorkspaces =
                    SeqDict.updateIfExists
                        linkedUser.user.teamId
                        (\workspace -> { workspace | domain = domain })
                        model.slackWorkspaces
              }
            , Command.none
            )

        Slack.WebsocketOtherEvent ->
            ( model, Command.none )


receivedSlackWebsocketEvent :
    SlackLinkedUser
    -> Slack.WebsocketEvent
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
receivedSlackWebsocketEvent linkedUser event model =
    let
        ( model2, lookUpCmd ) =
            lookUpUnknownSlackUsers linkedUser (websocketEventUserIds event) model
    in
    case List.filter (\file -> not (SeqDict.member file.id model2.slackFiles)) (websocketEventFiles event) of
        [] ->
            let
                ( model3, cmd ) =
                    handleSlackWebsocketEvent linkedUser event model2
            in
            ( model3, Command.batch [ cmd, lookUpCmd ] )

        newFiles ->
            ( model2
            , Command.batch
                [ uploadSlackFiles model2.serverSecret linkedUser.cookie linkedUser.token newFiles
                    |> Task.perform (SlackMessageFilesUploaded linkedUser.user.id event)
                , lookUpCmd
                ]
            )


{-| Loads the messages posted while the websocket was down, and handles them as if they had come
through it. Replies in threads that were already there before are missed.
-}
catchUpSlackConversations : SlackLinkedUser -> BackendModel -> Command BackendOnly ToFrontend BackendMsg
catchUpSlackConversations linkedUser model =
    let
        newestMessage : OneToOne (Slack.Id Slack.MessageId) (Id ChannelMessageId) -> Maybe (Slack.Id Slack.MessageId)
        newestMessage linkedMessageIds =
            OneToOne.toList linkedMessageIds
                |> List.map (\( slackMessageId, _ ) -> Slack.idToString slackMessageId)
                |> List.maximum
                |> Maybe.map Slack.Id

        catchUp : Slack.Id channelId -> Slack.Id Slack.MessageId -> Task BackendOnly Never (List Slack.WebsocketEvent)
        catchUp channelId oldest =
            Slack.messagesSince model.serverSecret linkedUser.cookie linkedUser.token channelId oldest
                |> Task.map (List.map (Slack.WebsocketMessageCreated (Slack.idToString channelId)))

        channels : List (Task BackendOnly Never (List Slack.WebsocketEvent))
        channels =
            case SeqDict.get linkedUser.user.teamId model.slackWorkspaces of
                Just workspace ->
                    SeqDict.toList workspace.channels
                        |> List.filterMap
                            (\( channelId, channel ) ->
                                if SeqSet.member linkedUser.user.id channel.linkedMembers then
                                    newestMessage channel.linkedMessageIds |> Maybe.map (catchUp channelId)

                                else
                                    Nothing
                            )

                Nothing ->
                    []

        dmChannels : List (Task BackendOnly Never (List Slack.WebsocketEvent))
        dmChannels =
            SeqDict.toList model.slackDmChannels
                |> List.filterMap
                    (\( dmChannelId, dmChannel ) ->
                        if NonemptySet.member linkedUser.user.id dmChannel.members then
                            newestMessage dmChannel.linkedMessageIds |> Maybe.map (catchUp dmChannelId)

                        else
                            Nothing
                    )
    in
    Task.sequence (channels ++ dmChannels)
        |> Task.map List.concat
        |> Task.perform (CaughtUpSlackMessages linkedUser.user.id)


{-| Returns the new message's ts, and the Slack ID of each file. Files that can't be read from
at-chat's storage are left out.
-}
sendSlackMessage :
    SecretId ServerSecret
    -> SlackLinkedUser
    -> Slack.Id channelId
    -> Maybe (Slack.Id Slack.MessageId)
    -> String
    -> List Slack.RichTextElement
    -> SeqDict (Id FileId) FileData
    -> Task BackendOnly Slack.HttpError ( Slack.Id Slack.MessageId, List ( Slack.Id Slack.FileId, FileData ) )
sendSlackMessage secretKey slackUser channelId maybeThreadId text blocks attachedFiles =
    if SeqDict.isEmpty attachedFiles then
        Slack.postMessage secretKey slackUser.cookie slackUser.token channelId maybeThreadId text blocks
            |> Task.map (\messageId -> ( messageId, [] ))

    else
        SeqDict.values attachedFiles
            |> List.map
                (\fileData ->
                    Http.task
                        { method = "GET"
                        , headers = []
                        , url = FileStatus.fileUrl fileData.contentType fileData.fileHash
                        , body = Http.emptyBody
                        , resolver =
                            Http.bytesResolver
                                (\response ->
                                    case response of
                                        Http.GoodStatus_ _ body ->
                                            Ok
                                                ( fileData
                                                , { fileName = FileName.toString fileData.fileName
                                                  , contentType = FileStatus.contentTypeHeader fileData.contentType
                                                  , bytes = body
                                                  }
                                                )

                                        _ ->
                                            Err ()
                                )
                        , timeout = Duration.seconds 30 |> Just
                        }
                        |> Task.map Just
                        |> Task.onError (\() -> Task.succeed Nothing)
                )
            |> Task.sequence
            |> Task.andThen
                (\files ->
                    case List.filterMap identity files of
                        (( _, first ) :: rest) as files2 ->
                            Slack.postMessageWithFiles
                                secretKey
                                slackUser.cookie
                                slackUser.token
                                channelId
                                maybeThreadId
                                blocks
                                (Nonempty first (List.map Tuple.second rest))
                                |> Task.map
                                    (\( messageId, fileIds ) ->
                                        ( messageId, List.map2 Tuple.pair (List.Nonempty.toList fileIds) (List.map Tuple.first files2) )
                                    )

                        [] ->
                            Slack.postMessage secretKey slackUser.cookie slackUser.token channelId maybeThreadId text blocks
                                |> Task.map (\messageId -> ( messageId, [] ))
                )


{-| Adds what loadSlackWorkspaceData loaded, keeping the messages of conversations we already had.
-}
addLoadedSlackWorkspace : Slack.Id Slack.TeamId -> Slack.Id Slack.UserId -> LoadedSlackWorkspace -> BackendModel -> BackendModel
addLoadedSlackWorkspace teamId slackUserId { channels, dmChannels, users, selfIcon, workspaceIcon, files } model =
    let
        slackFiles : SeqDict (Slack.Id Slack.FileId) SlackFileData
        slackFiles =
            SeqDict.union files model.slackFiles
    in
    { model
        | slackFiles = slackFiles
        , slackWorkspaces =
            SeqDict.updateIfExists
                teamId
                (\workspace ->
                    { workspace
                        | icon = workspaceIcon
                        , channels =
                            List.foldl
                                (\( channel, channelHistory ) dict ->
                                    SeqDict.insert
                                        channel.id
                                        (case SeqDict.get channel.id dict of
                                            Just existing ->
                                                { existing
                                                    | name = ChannelName.fromStringLossy channel.name
                                                    , isPrivate = channel.isPrivate
                                                    , linkedMembers = SeqSet.insert slackUserId existing.linkedMembers
                                                }

                                            Nothing ->
                                                let
                                                    conversation =
                                                        SlackSync.conversationFromHistory slackFiles channelHistory
                                                in
                                                { name = ChannelName.fromStringLossy channel.name
                                                , isPrivate = channel.isPrivate
                                                , linkedMembers = SeqSet.singleton slackUserId
                                                , messages = conversation.messages
                                                , linkedMessageIds = conversation.linkedMessageIds
                                                , threads = conversation.threads
                                                }
                                        )
                                        dict
                                )
                                (SeqDict.map
                                    (\_ channel -> { channel | linkedMembers = SeqSet.remove slackUserId channel.linkedMembers })
                                    workspace.channels
                                )
                                channels
                    }
                )
                model.slackWorkspaces
        , slackDmChannels =
            List.foldl
                (\( dmChannel, dmHistory ) dict ->
                    SeqDict.insert
                        dmChannel.id
                        (case SeqDict.get dmChannel.id dict of
                            Just existing ->
                                { existing | members = dmChannel.members }

                            Nothing ->
                                let
                                    conversation =
                                        SlackSync.conversationFromHistory slackFiles dmHistory
                                in
                                { teamId = teamId
                                , members = dmChannel.members
                                , messages = conversation.messages
                                , linkedMessageIds = conversation.linkedMessageIds
                                , threads = conversation.threads
                                }
                        )
                        dict
                )
                model.slackDmChannels
                dmChannels
        , slackUsers =
            List.foldl
                (\( user, icon ) dict ->
                    SeqDict.insert
                        user.id
                        (case SeqDict.get user.id dict of
                            Just (SlackFullData linkedUser) ->
                                SlackFullData { linkedUser | user = user, icon = icon }

                            Just (SlackBasicData _) ->
                                SlackBasicData { user = user, icon = icon }

                            Nothing ->
                                SlackBasicData { user = user, icon = icon }
                        )
                        dict
                )
                (SeqDict.updateIfExists
                    slackUserId
                    (\userData ->
                        case userData of
                            SlackFullData linkedUser ->
                                SlackFullData { linkedUser | icon = selfIcon }

                            SlackBasicData basicData ->
                                SlackBasicData { basicData | icon = selfIcon }
                    )
                    model.slackUsers
                )
                users
    }


{-| Reloads the linked Slack user's list of channels and DMs, for when they've joined or left one
or a message arrives in one we don't have. New channels start out read like they do when linking,
while new DMs keep their messages unread since they are usually what caused the refresh.
-}
refreshSlackConversations : SlackLinkedUser -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
refreshSlackConversations linkedUser model =
    if SeqSet.member linkedUser.user.id model.refreshingSlackConversations then
        ( model, Command.none )

    else
        ( { model | refreshingSlackConversations = SeqSet.insert linkedUser.user.id model.refreshingSlackConversations }
        , Slack.userBoot model.serverSecret linkedUser.cookie linkedUser.token
            |> Task.andThen
                (\{ self, team } ->
                    loadSlackWorkspaceData model linkedUser.cookie linkedUser.token self team
                        |> Task.map (Tuple.pair team.id)
                )
            |> Task.onError (\error -> Time.now |> Task.andThen (\time -> Task.fail ( time, error )))
            |> Task.attempt (RefreshedSlackConversations linkedUser.user.id)
        )


{-| Every linked Slack account in the workspace gets the same profile change, so this runs once
per account but only the first one changes anything.
-}
slackUserChanged : Slack.User -> Maybe FileHash -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
slackUserChanged user icon model =
    case SeqDict.get user.id model.slackUsers of
        Just userData ->
            let
                userData2 : SlackUserData
                userData2 =
                    case userData of
                        SlackBasicData _ ->
                            SlackBasicData { user = user, icon = icon }

                        SlackFullData linkedUser ->
                            SlackFullData { linkedUser | user = user, icon = icon }

                model2 : BackendModel
                model2 =
                    { model | slackUsers = SeqDict.insert user.id userData2 model.slackUsers }
            in
            ( model2
            , Broadcast.toSlackTeam
                user.teamId
                (Server_Slack_UserLoaded user.id (SlackSync.userToFrontend model2.users userData2) |> ServerChange)
                model2
            )

        Nothing ->
            ( model, Command.none )


{-| Keeps up the last viewed message of everyone reading the conversation, marks the message
read for whoever wrote it, gives a red dot to the linked accounts it mentions and notifies them.
-}
slackMessageAdded :
    Time.Posix
    -> SlackGuildOrDmId
    -> ThreadRouteWithMessage
    -> UserTextMessageData messageId (Slack.Id Slack.UserId) (Slack.Id Slack.ChannelId)
    -> BackendModel
    -> ( BackendModel, List (Command BackendOnly ToFrontend BackendMsg) )
slackMessageAdded time guildOrDmId threadRouteWithMessage data model =
    let
        threadRoute : ThreadRoute
        threadRoute =
            Id.threadRouteWithoutMessage threadRouteWithMessage

        ( sessions, notificationCmds ) =
            Broadcast.slackMessageNotification time guildOrDmId threadRoute data model

        viewers : List ( Id UserId, AnyGuildOrDmId )
        viewers =
            Broadcast.usersViewingSlackConversation guildOrDmId threadRoute model

        authorLinkedTo : Maybe (Id UserId)
        authorLinkedTo =
            case SeqDict.get (slackAuthor guildOrDmId) model.slackUsers of
                Just (SlackFullData linkedUser) ->
                    Just linkedUser.linkedTo

                Just (SlackBasicData _) ->
                    Nothing

                Nothing ->
                    Nothing

        users2 : NonemptyDict (Id UserId) BackendUser
        users2 =
            List.foldl
                (\( userId, viewerGuildOrDmId ) usersAcc ->
                    NonemptyDict.updateIfExists
                        userId
                        (LocalState.incrementLastViewedMessageBackend viewerGuildOrDmId threadRouteWithMessage)
                        usersAcc
                )
                model.users
                viewers

        users3 : NonemptyDict (Id UserId) BackendUser
        users3 =
            case authorLinkedTo of
                Just userId ->
                    NonemptyDict.updateIfExists
                        userId
                        (User.setLastViewedMessage (SlackGuildOrDmId guildOrDmId) threadRouteWithMessage)
                        users2

                Nothing ->
                    users2

        users4 : NonemptyDict (Id UserId) BackendUser
        users4 =
            case guildOrDmId of
                SlackGuildOrDmId_Workspace { teamId, channelId } ->
                    SeqSet.foldl
                        (\mentioned usersAcc ->
                            case SeqDict.get mentioned model.slackUsers of
                                Just (SlackFullData linkedUser) ->
                                    if
                                        (Just linkedUser.linkedTo == authorLinkedTo)
                                            || List.any (\( viewer, _ ) -> viewer == linkedUser.linkedTo) viewers
                                    then
                                        usersAcc

                                    else
                                        NonemptyDict.updateIfExists
                                            linkedUser.linkedTo
                                            (User.addSlackDirectMention teamId channelId threadRoute)
                                            usersAcc

                                Just (SlackBasicData _) ->
                                    usersAcc

                                Nothing ->
                                    usersAcc
                        )
                        users3
                        (Broadcast.slackMentionedMembers teamId channelId data.content.content model)

                SlackGuildOrDmId_Dm _ ->
                    users3
    in
    ( { model | users = users4, sessions = sessions }, notificationCmds )


type alias SlackConversation =
    { messages : IdArray ChannelMessageId (Message ChannelMessageId (Slack.Id Slack.UserId) (Slack.Id Slack.ChannelId))
    , linkedMessageIds : OneToOne (Slack.Id Slack.MessageId) (Id ChannelMessageId)
    , threads : SeqDict (Id ChannelMessageId) SlackBackendThread
    }


{-| Sent along with a thread reply, since the message the thread started from may be too old for the
frontend to have loaded, and the thread is named after it.
-}
slackThreadStarter : SlackGuildOrDmId -> ThreadRoute -> BackendModel -> Maybe (Message ChannelMessageId (Slack.Id Slack.UserId) (Slack.Id Slack.ChannelId))
slackThreadStarter guildOrDmId threadRoute model =
    case threadRoute of
        ViewThread threadId ->
            getSlackConversation guildOrDmId model |> Maybe.andThen (\conversation -> IdArray.get threadId conversation.messages)

        NoThread ->
            Nothing


getSlackConversation : SlackGuildOrDmId -> BackendModel -> Maybe SlackConversation
getSlackConversation guildOrDmId model =
    case guildOrDmId of
        SlackGuildOrDmId_Workspace { teamId, channelId } ->
            LocalState.getSlackWorkspaceAndChannel teamId channelId model
                |> Maybe.map
                    (\( _, channel ) ->
                        { messages = channel.messages, linkedMessageIds = channel.linkedMessageIds, threads = channel.threads }
                    )

        SlackGuildOrDmId_Dm { channelId } ->
            SeqDict.get channelId model.slackDmChannels
                |> Maybe.map
                    (\channel ->
                        { messages = channel.messages, linkedMessageIds = channel.linkedMessageIds, threads = channel.threads }
                    )


updateSlackConversation :
    SlackGuildOrDmId
    -> (SlackConversation -> Maybe ( SlackConversation, a ))
    -> BackendModel
    -> Maybe ( BackendModel, a )
updateSlackConversation guildOrDmId updateFunc model =
    case guildOrDmId of
        SlackGuildOrDmId_Workspace { teamId, channelId } ->
            LocalState.getSlackWorkspaceAndChannel teamId channelId model
                |> Maybe.andThen
                    (\( workspace, channel ) ->
                        updateFunc { messages = channel.messages, linkedMessageIds = channel.linkedMessageIds, threads = channel.threads }
                            |> Maybe.map
                                (\( conversation, a ) ->
                                    ( { model
                                        | slackWorkspaces =
                                            SeqDict.insert
                                                teamId
                                                { workspace
                                                    | channels =
                                                        SeqDict.insert
                                                            channelId
                                                            { channel
                                                                | messages = conversation.messages
                                                                , linkedMessageIds = conversation.linkedMessageIds
                                                                , threads = conversation.threads
                                                            }
                                                            workspace.channels
                                                }
                                                model.slackWorkspaces
                                      }
                                    , a
                                    )
                                )
                    )

        SlackGuildOrDmId_Dm { channelId } ->
            SeqDict.get channelId model.slackDmChannels
                |> Maybe.andThen
                    (\channel ->
                        updateFunc { messages = channel.messages, linkedMessageIds = channel.linkedMessageIds, threads = channel.threads }
                            |> Maybe.map
                                (\( conversation, a ) ->
                                    ( { model
                                        | slackDmChannels =
                                            SeqDict.insert
                                                channelId
                                                { channel
                                                    | messages = conversation.messages
                                                    , linkedMessageIds = conversation.linkedMessageIds
                                                    , threads = conversation.threads
                                                }
                                                model.slackDmChannels
                                      }
                                    , a
                                    )
                                )
                    )


{-| Nothing if the message is already there, or it replies to a message at-chat doesn't have.
The same message is passed twice since a channel message and a thread message have different id
types.
-}
addToSlackConversation :
    ThreadRoute
    -> Slack.Id Slack.MessageId
    -> Message ChannelMessageId (Slack.Id Slack.UserId) (Slack.Id Slack.ChannelId)
    -> Message ThreadMessageId (Slack.Id Slack.UserId) (Slack.Id Slack.ChannelId)
    -> SlackConversation
    -> Maybe ( SlackConversation, ThreadRouteWithMessage )
addToSlackConversation threadRoute slackMessageId channelMessage threadMessage conversation =
    case threadRoute of
        NoThread ->
            if OneToOne.memberFirst slackMessageId conversation.linkedMessageIds then
                Nothing

            else
                let
                    messageId : Id ChannelMessageId
                    messageId =
                        IdArray.nextId conversation.messages
                in
                ( { conversation
                    | messages = IdArray.push channelMessage conversation.messages
                    , linkedMessageIds = OneToOne.insert slackMessageId messageId conversation.linkedMessageIds
                  }
                , NoThreadWithMessage messageId
                )
                    |> Just

        ViewThread threadId ->
            let
                thread : SlackBackendThread
                thread =
                    SeqDict.get threadId conversation.threads |> Maybe.withDefault Thread.slackBackendInit

                messageId : Id ThreadMessageId
                messageId =
                    IdArray.nextId thread.messages
            in
            if IdArray.get threadId conversation.messages == Nothing || OneToOne.memberFirst slackMessageId thread.linkedMessageIds then
                Nothing

            else
                ( { conversation
                    | threads =
                        SeqDict.insert
                            threadId
                            { messages = IdArray.push threadMessage thread.messages
                            , linkedMessageIds = OneToOne.insert slackMessageId messageId thread.linkedMessageIds
                            }
                            conversation.threads
                  }
                , ViewThreadWithMessage threadId messageId
                )
                    |> Just


{-| Slack has no way to tell which of its custom emojis an at-chat custom emoji is.
-}
slackReactionName : EmojiOrCustomEmoji -> Maybe String
slackReactionName emoji =
    case emoji of
        EmojiOrCustomEmoji_Emoji unicodeEmoji ->
            SlackEmoji.toSlackName unicodeEmoji

        EmojiOrCustomEmoji_CustomEmoji _ ->
            Nothing


slackMessageTs : ThreadRouteWithMessage -> SlackConversation -> Maybe (Slack.Id Slack.MessageId)
slackMessageTs threadRoute conversation =
    case threadRoute of
        NoThreadWithMessage messageId ->
            OneToOne.first messageId conversation.linkedMessageIds

        ViewThreadWithMessage threadId messageId ->
            SeqDict.get threadId conversation.threads |> Maybe.andThen (\thread -> OneToOne.first messageId thread.linkedMessageIds)


asSlackConversationUser :
    BackendModel
    -> SessionId
    -> SlackGuildOrDmId
    -> (UserSession -> SlackLinkedUser -> Slack.Id Slack.ChannelId -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg ))
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
asSlackConversationUser model sessionId guildOrDmId func =
    case guildOrDmId of
        SlackGuildOrDmId_Workspace id ->
            BackendExtra.asSlackChannelMember model sessionId id (\session slackUser _ _ -> func session slackUser id.channelId)

        SlackGuildOrDmId_Dm data ->
            -- Slack's API takes a DM's id wherever it takes a channel's
            BackendExtra.asSlackDmUser model sessionId data (\session slackUser _ -> func session slackUser (Slack.Id (Slack.idToString data.channelId)))


{-| Edits the message in every place it is in, as long as it's by the given author, and returns
where it was edited.
-}
editSlackMessage :
    Time.Posix
    -> Slack.Id Slack.UserId
    -> Nonempty (RichText (Slack.Id Slack.UserId) (Slack.Id Slack.ChannelId))
    -> Slack.Id Slack.MessageId
    -> SlackConversation
    -> ( SlackConversation, List ThreadRouteWithMessage )
editSlackMessage editedAt author content slackMessageId conversation =
    List.foldl
        (\threadRoute ( conversation2, edited ) ->
            case LocalState.editMessageHelper editedAt author content DoNotChangeAttachments threadRoute conversation2 of
                Ok conversation3 ->
                    ( conversation3, threadRoute :: edited )

                Err () ->
                    ( conversation2, edited )
        )
        ( conversation, [] )
        (slackMessageLocations slackMessageId conversation)


{-| Deletes the message from every place it is in, as long as it's by the given author, and returns
where it was deleted from.
-}
deleteSlackMessage : Slack.Id Slack.UserId -> Slack.Id Slack.MessageId -> SlackConversation -> ( SlackConversation, List ThreadRouteWithMessage )
deleteSlackMessage author slackMessageId conversation =
    List.foldl
        (\threadRoute ( conversation2, deleted ) ->
            case LocalState.deleteMessageBackendHelper author threadRoute conversation2 of
                Ok conversation3 ->
                    ( conversation3, threadRoute :: deleted )

                Err () ->
                    ( conversation2, deleted )
        )
        ( conversation, [] )
        (slackMessageLocations slackMessageId conversation)


{-| A reply that was also sent to the channel is in two places.
-}
slackMessageLocations : Slack.Id Slack.MessageId -> SlackConversation -> List ThreadRouteWithMessage
slackMessageLocations slackMessageId conversation =
    (case OneToOne.second slackMessageId conversation.linkedMessageIds of
        Just messageId ->
            [ NoThreadWithMessage messageId ]

        Nothing ->
            []
    )
        ++ SeqDict.foldr
            (\threadId thread list ->
                case OneToOne.second slackMessageId thread.linkedMessageIds of
                    Just messageId ->
                        ViewThreadWithMessage threadId messageId :: list

                    Nothing ->
                        list
            )
            []
            conversation.threads


addLinkedSlackUser : Time.Posix -> Id UserId -> SlackCookie -> SlackToken -> Slack.UserBoot -> BackendModel -> BackendModel
addLinkedSlackUser linkedAt userId cookie token { self, team } model =
    { model
        | slackWorkspaces =
            SeqDict.update
                team.id
                (\maybeWorkspace ->
                    { name = team.name
                    , domain = team.domain
                    , icon =
                        case maybeWorkspace of
                            Just workspace ->
                                workspace.icon

                            Nothing ->
                                Nothing
                    , channels =
                        case maybeWorkspace of
                            Just workspace ->
                                workspace.channels

                            Nothing ->
                                SeqDict.empty
                    }
                        |> Just
                )
                model.slackWorkspaces
        , slackUsers =
            SeqDict.insert
                self.id
                (SlackFullData
                    { user = self
                    , icon =
                        case SeqDict.get self.id model.slackUsers of
                            Just (SlackFullData existing) ->
                                existing.icon

                            Just (SlackBasicData existing) ->
                                existing.icon

                            Nothing ->
                                Nothing
                    , linkedTo = userId
                    , linkedAt = linkedAt
                    , token = token
                    , cookie = cookie
                    , websocket =
                        case SeqDict.get self.id model.slackUsers of
                            Just (SlackFullData existing) ->
                                existing.websocket

                            Just (SlackBasicData _) ->
                                Nothing

                            Nothing ->
                                Nothing
                    , reconnect =
                        case SeqDict.get self.id model.slackUsers of
                            Just (SlackFullData existing) ->
                                existing.reconnect

                            Just (SlackBasicData _) ->
                                { failedAttempts = 0, seed = Time.posixToMillis linkedAt }

                            Nothing ->
                                { failedAttempts = 0, seed = Time.posixToMillis linkedAt }
                    , needsAuthAgain = False
                    }
                )
                model.slackUsers
    }


{-| Hands the at-chat user everything linking loaded, so their open tabs show it without a reload.
-}
slackLinkedUserLoaded : Slack.Id Slack.UserId -> Slack.Id Slack.TeamId -> BackendModel -> Command BackendOnly ToFrontend BackendMsg
slackLinkedUserLoaded slackUserId teamId model =
    case SeqDict.get slackUserId model.slackUsers of
        Just (SlackFullData linkedUser) ->
            case NonemptyDict.get linkedUser.linkedTo model.users of
                Just user ->
                    let
                        linked : SeqDict (Slack.Id Slack.UserId) (Slack.Id Slack.TeamId)
                        linked =
                            SlackSync.linkedUsers linkedUser.linkedTo model.slackUsers

                        isSlack : AnyGuildOrDmId -> Bool
                        isSlack guildOrDmId =
                            case guildOrDmId of
                                SlackGuildOrDmId _ ->
                                    True

                                GuildOrDmId _ ->
                                    False

                                DiscordGuildOrDmId _ ->
                                    False
                    in
                    Broadcast.toUser
                        Nothing
                        Nothing
                        linkedUser.linkedTo
                        (Server_Slack_LinkedUserLoaded
                            slackUserId
                            teamId
                            { workspaces = SlackSync.workspacesToFrontend linked model.slackWorkspaces
                            , dmChannels = SlackSync.dmChannelsToFrontend linked model.slackDmChannels
                            , users = SlackSync.usersToFrontend model.users linked model.slackUsers
                            , lastViewedMessage = SeqDict.filter (\guildOrDmId _ -> isSlack guildOrDmId) user.lastViewedMessage
                            , lastViewedThreadMessage = SeqDict.filter (\( guildOrDmId, _ ) _ -> isSlack guildOrDmId) user.lastViewedThreadMessage
                            }
                            |> ServerChange
                        )
                        model

                Nothing ->
                    Command.none

        Just (SlackBasicData _) ->
            Command.none

        Nothing ->
            Command.none


{-| Linking Slack loads the newest messages of every conversation, and none of them are new to
the person linking it, so conversations they've never had a last viewed message in start out read.
-}
markNewSlackConversationsAsViewed :
    Slack.Id Slack.UserId
    -> Slack.Id Slack.TeamId
    -> List (Slack.Id Slack.ChannelId)
    -> List (Slack.Id Slack.DmChannelId)
    -> BackendModel
    -> BackendModel
markNewSlackConversationsAsViewed slackUserId teamId channelIds dmChannelIds model =
    case SeqDict.get slackUserId model.slackUsers of
        Just (SlackFullData linkedUser) ->
            let
                markAsViewed : SlackGuildOrDmId -> BackendUser -> BackendUser
                markAsViewed guildOrDmId user =
                    case getSlackConversation guildOrDmId model of
                        Just conversation ->
                            if IdArray.length conversation.messages > 0 && not (SeqDict.member (SlackGuildOrDmId guildOrDmId) user.lastViewedMessage) then
                                SeqDict.foldl
                                    (\threadId thread user2 ->
                                        User.setLastViewedMessage
                                            (SlackGuildOrDmId guildOrDmId)
                                            (ViewThreadWithMessage threadId (DmChannel.latestThreadMessageId thread))
                                            user2
                                    )
                                    (User.setLastViewedMessage
                                        (SlackGuildOrDmId guildOrDmId)
                                        (NoThreadWithMessage (DmChannel.latestMessageId conversation))
                                        user
                                    )
                                    conversation.threads

                            else
                                user

                        Nothing ->
                            user

                markChannels : BackendUser -> BackendUser
                markChannels user =
                    List.foldl
                        (\channelId user2 ->
                            let
                                guildOrDmId : SlackGuildOrDmId
                                guildOrDmId =
                                    SlackGuildOrDmId_Workspace { currentUserId = slackUserId, teamId = teamId, channelId = channelId }
                            in
                            markAsViewed guildOrDmId user2
                        )
                        user
                        channelIds

                markDmChannels : BackendUser -> BackendUser
                markDmChannels user =
                    List.foldl
                        (\channelId user2 ->
                            let
                                guildOrDmId : SlackGuildOrDmId
                                guildOrDmId =
                                    SlackGuildOrDmId_Dm { currentUserId = slackUserId, channelId = channelId }
                            in
                            markAsViewed guildOrDmId user2
                        )
                        user
                        dmChannelIds
            in
            { model | users = NonemptyDict.updateIfExists linkedUser.linkedTo (\user -> markChannels user |> markDmChannels) model.users }

        Just (SlackBasicData _) ->
            model

        Nothing ->
            model


slackAuthor : SlackGuildOrDmId -> Slack.Id Slack.UserId
slackAuthor guildOrDmId =
    case guildOrDmId of
        SlackGuildOrDmId_Workspace data ->
            data.currentUserId

        SlackGuildOrDmId_Dm data ->
            data.currentUserId
