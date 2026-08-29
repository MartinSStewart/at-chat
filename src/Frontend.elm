module Frontend exposing
    ( app
    , app_
    , discordLinkExpiredText
    , goMatchNotFoundText
    )

import AiChat
import Array exposing (Array)
import Audio exposing (AudioCmd, AudioData)
import Browser exposing (UrlRequest(..))
import Browser.Navigation
import Call exposing (MediaDevicesStatus(..))
import ChannelDescription
import ChannelName
import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import CustomEmoji
import Discord
import DmChannel exposing (FrontendDmChannel)
import DmChannelId
import Drawing
import Duration exposing (Duration, Seconds)
import Editable
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Browser.Events
import Effect.Browser.Navigation as BrowserNavigation exposing (Key)
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.File.Download
import Effect.File.Select
import Effect.Http as Http
import Effect.Lamdera as Lamdera exposing (ClientId)
import Effect.Process as Process
import Effect.Subscription as Subscription exposing (Subscription)
import Effect.Task as Task
import Effect.Time as Time
import Emoji exposing (CachedEmojiData, EmojiOrCustomEmoji(..), EmojiOrSticker(..))
import Encryption
import FileStatus exposing (FileData, FileId, FileStatus(..))
import FrontendExtra
import Game
import Go
import GuildColumn
import GuildName
import Html exposing (Html)
import Html.Attributes
import Id exposing (AnyGuildOrDmId(..), ChannelId, DiscordGuildOrDmId(..), GuildOrDmId(..), Id, ThreadRoute(..), ThreadRouteWithMaybeMessage(..), ThreadRouteWithMessage(..), UserId, Viewing_DmId)
import ImageEditor
import ImageViewer
import Json.Decode
import Lamdera as LamderaCore
import LinkedAndOtherDiscordUsers
import List.Extra
import List.Nonempty exposing (Nonempty(..))
import Local exposing (Local)
import LocalState exposing (AdminStatus(..), LocalState)
import LoginForm
import Message exposing (ContentAndEmbeds)
import MessageDropdown
import MessageInput exposing (NameSoFar(..), TextInputFocus)
import MessageMenu
import MessageView
import MyUi exposing (Copied(..))
import NonemptyDict exposing (NonemptyDict)
import NonemptySet
import OneOrGreater
import Pages.Admin
import Pages.Guild exposing (DmChannelSelection(..))
import Pages.Home
import Pagination
import Point2d exposing (Point2d)
import Ports exposing (PwaStatus(..))
import Quantity exposing (Quantity, Rate, Unitless)
import Range exposing (Range, SelectionDirection)
import RecoveryLogin
import RichText exposing (RichText)
import Route exposing (ChannelRoute(..), ChannelSidebarMode(..), ChannelsVisibleOnMobile(..), DiscordChannelRoute(..), LinkDiscordError(..), Route(..), ShowChannelSettings(..), ThreadRouteWithFriends(..))
import Scroll exposing (ScrollPosition(..))
import SeqDict exposing (SeqDict)
import SeqDictHelper
import SeqSet exposing (SeqSet)
import SheepGame
import Sticker
import String.Extra
import String.Nonempty
import TextEditor
import Thread
import Toop exposing (T4(..))
import Touch exposing (Drag(..), DragTarget(..), ScreenCoordinate, Touch)
import TwoFactorAuthentication exposing (TwoFactorState(..))
import Types exposing (AdminStatusLoginData(..), EmojiSelector(..), FileDrag(..), FrontendModel, FrontendModel_(..), FrontendMsg, FrontendMsg_(..), InitialLoadRequest(..), LoadStatus(..), LoadedFrontend, LoadingFrontend, LocalChange(..), LocalMsg(..), LoggedIn2, LoginData, LoginResult(..), LoginStatus(..), LoginType(..), MessageHover(..), MessageHoverMobileMode(..), PublicGoMatch(..), ServerChange(..), ToBackend(..), ToFrontend(..), UserOptionsModel)
import Ui exposing (Element)
import Ui.Anim
import Ui.Font
import Ui.Lazy
import Untrusted
import Url exposing (Url)
import User exposing (FrontendUser)
import UserAgent
import UserColor
import UserOptions
import UserSession exposing (ChannelHeaderTab(..), NotificationMode(..), SetViewing(..), ToBeFilledInByBackend(..))
import Vector2d
import WordSpellingGame
import X25519


discordLinkExpiredText : String
discordLinkExpiredText =
    "This Discord link has expired"


goMatchNotFoundText : String
goMatchNotFoundText =
    "Go match not found"


app :
    { init : Url -> Browser.Navigation.Key -> ( FrontendModel, Cmd FrontendMsg )
    , view : FrontendModel -> Browser.Document FrontendMsg
    , update : FrontendMsg -> FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
    , updateFromBackend : ToFrontend -> FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
    , subscriptions : FrontendModel -> Sub FrontendMsg
    , onUrlRequest : UrlRequest -> FrontendMsg
    , onUrlChange : Url -> FrontendMsg
    }
app =
    Lamdera.frontend LamderaCore.sendToBackend app_


app_ :
    { init : Url -> Key -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
    , onUrlRequest : UrlRequest -> FrontendMsg
    , onUrlChange : Url -> FrontendMsg
    , update : FrontendMsg -> FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
    , updateFromBackend : ToFrontend -> FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
    , subscriptions : FrontendModel -> Subscription FrontendOnly FrontendMsg
    , view : FrontendModel -> Browser.Document FrontendMsg
    }
app_ =
    Audio.lamderaFrontendWithAudio
        { init = init
        , onUrlRequest = onUrlRequest
        , onUrlChange = onUrlChange
        , update = update
        , updateFromBackend = updateFromBackend
        , subscriptions = subscriptions
        , view = view
        , audio = FrontendExtra.audio
        , audioPort = { toJS = Ports.audioPortToJS, fromJS = Ports.audioPortFromJS }
        }


{-| LocalUser keeps a copy of the device pixel ratio so that ascii art can pick a font size
that lands on whole device pixels without messageView needing another parameter. That copy
has to be kept in step with the real value, which changes when the page is zoomed or moved
to a screen with a different pixel density.
-}
setDevicePixelRatio : Float -> LoadedFrontend -> LoadedFrontend
setDevicePixelRatio devicePixelRatio model =
    let
        startupData : Ports.StartupData
        startupData =
            model.startupData
    in
    { model
        | startupData = { startupData | devicePixelRatio = devicePixelRatio }
        , loginStatus =
            case model.loginStatus of
                LoggedIn loggedIn ->
                    LoggedIn
                        { loggedIn
                            | localState =
                                Local.mapModel
                                    (\local ->
                                        let
                                            localUser : User.LocalUser
                                            localUser =
                                                local.localUser
                                        in
                                        { local
                                            | localUser = { localUser | devicePixelRatio = devicePixelRatio }
                                        }
                                    )
                                    loggedIn.localState
                        }

                NotLoggedIn _ ->
                    model.loginStatus
    }


{-| LocalUser keeps a copy of the emoji data so that a reaction can name the emoji it
shows without messageView needing another parameter. It arrives once, after the rest of
the page has loaded, so both copies are filled in when it does.
-}
setEmojiData : CachedEmojiData -> LoadedFrontend -> LoadedFrontend
setEmojiData emojiData model =
    { model
        | emojiData = Just emojiData
        , loginStatus =
            case model.loginStatus of
                LoggedIn loggedIn ->
                    LoggedIn
                        { loggedIn
                            | localState =
                                Local.mapModel
                                    (\local ->
                                        let
                                            localUser : User.LocalUser
                                            localUser =
                                                local.localUser
                                        in
                                        { local
                                            | localUser = { localUser | emojiData = Just emojiData }
                                        }
                                    )
                                    loggedIn.localState
                        }

                NotLoggedIn _ ->
                    model.loginStatus
    }


checkAppVersion : Bool -> Command FrontendOnly toMsg FrontendMsg_
checkAppVersion reloadOnNewVersion =
    Http.get
        { url = "/_i"
        , expect =
            Http.expectJson
                (\result ->
                    -- The error isn't interesting and in lamdera live it's going to load the entire bundle and try printing that as an error in the console
                    Result.mapError (\_ -> ()) result |> GotVersionNumber reloadOnNewVersion
                )
                (Json.Decode.field "v" Json.Decode.int)
        }


subscriptions : AudioData -> FrontendModel_ -> Subscription FrontendOnly FrontendMsg_
subscriptions _ model =
    Subscription.batch
        [ Effect.Browser.Events.onResize GotWindowSize
        , Time.every Duration.second GotTime
        , Effect.Browser.Events.onKeyDown
            (Json.Decode.map4
                (\ctrlKey metaKey shiftKey key ->
                    KeyDown { ctrlKey = ctrlKey, metaKey = metaKey, shiftKey = shiftKey, key = key }
                )
                (Json.Decode.field "ctrlKey" Json.Decode.bool)
                (Json.Decode.field "metaKey" Json.Decode.bool)
                (Json.Decode.field "shiftKey" Json.Decode.bool)
                (Json.Decode.field "key" Json.Decode.string)
            )
        , Ports.checkNotificationPermissionResponse CheckedNotificationPermission
        , AiChat.subscriptions |> Subscription.map AiChatMsg
        , Ports.startupDataSub GotStartupData
        , Ports.gotDevicePixelRatio GotDevicePixelRatio
        , Ports.pageHasFocus PageHasFocusChanged
        , Ports.serviceWorkerMessage GotServiceWorkerMessage
        , Ports.serviceWorkerData GotServiceWorkerData
        , Ports.visualViewportResized VisualViewportResized
        , Ports.selectionChanged TextSelectionChanged
        , Ports.focusChanged DomFocusChanged
        , Call.fromJs GotVoiceChatSignalFromJs
        , Encryption.fromJs Message.contentAndEmbedsCodec EncryptionFromJs
        , case model of
            Loading _ ->
                Subscription.none

            Loaded loaded ->
                Subscription.batch
                    [ Effect.Browser.Events.onVisibilityChange VisibilityChanged
                    , case loaded.imageViewer of
                        Just imageViewer ->
                            ImageViewer.subscriptions loaded.windowSize imageViewer |> Subscription.map ImageViewerMsg

                        Nothing ->
                            Subscription.none
                    , case loaded.loginStatus of
                        LoggedIn loggedIn ->
                            Subscription.batch
                                [ SeqDict.foldl
                                    (\guildOrDmId filesToUpload list ->
                                        NonemptyDict.foldl
                                            (\fileId fileStatus list2 ->
                                                case fileStatus of
                                                    FileUploading _ _ _ _ ->
                                                        Http.track
                                                            (FileStatus.uploadTrackerId guildOrDmId fileId)
                                                            (FileUploadProgress guildOrDmId fileId)
                                                            :: list2

                                                    FileUploaded _ ->
                                                        list2

                                                    FileError _ _ _ _ _ ->
                                                        list2
                                            )
                                            list
                                            filesToUpload
                                    )
                                    []
                                    loggedIn.filesToUpload
                                    |> Subscription.batch
                                , if FrontendExtra.fileDragOverlayOpacity loggedIn loaded <= 0 then
                                    Subscription.none

                                  else
                                    Effect.Browser.Events.onAnimationFrame GotTime
                                , case FrontendExtra.currentGame (Local.model loggedIn.localState) loaded of
                                    Just { guildOrDmId, matchId, match } ->
                                        if
                                            Game.isAnimating
                                                loaded.time
                                                loaded.windowSize
                                                matchId
                                                match
                                                (SeqDict.get guildOrDmId loggedIn.games |> Maybe.withDefault Game.initModel)
                                        then
                                            Effect.Browser.Events.onAnimationFrame GotTime

                                        else
                                            Subscription.none

                                    Nothing ->
                                        Subscription.none
                                , case loggedIn.sidebarMode of
                                    ChannelSidebarDragging _ ->
                                        Subscription.none

                                    ChannelSidebarNotDragging { offset } ->
                                        if offset == channelSidebarTarget loaded.route then
                                            Subscription.none

                                        else
                                            Effect.Browser.Events.onAnimationFrameDelta ChannelSidebarAnimated
                                , case loggedIn.messageHover of
                                    NoMessageHover ->
                                        Subscription.none

                                    MessageHover _ _ ->
                                        Subscription.none

                                    MessageMenu messageMenuExtraOptions ->
                                        case messageMenuExtraOptions.mobileMode of
                                            MessageMenuClosing _ _ ->
                                                Effect.Browser.Events.onAnimationFrameDelta MessageMenuAnimated

                                            MessageMenuOpening _ ->
                                                Effect.Browser.Events.onAnimationFrameDelta MessageMenuAnimated

                                            MessageMenuDragging _ ->
                                                Subscription.none

                                            MessageMenuFixed _ ->
                                                Subscription.none
                                , ImageEditor.subscriptions |> Subscription.map ProfilePictureEditorMsg
                                , case loggedIn.guildIconEditor of
                                    Just ( guildId, _ ) ->
                                        ImageEditor.subscriptions |> Subscription.map (GuildIconEditorMsg guildId)

                                    Nothing ->
                                        Subscription.none
                                ]

                        NotLoggedIn _ ->
                            Subscription.none
                    ]
        , Ports.registerPushSubscription GotRegisterPushSubscription
        ]


onUrlRequest : UrlRequest -> FrontendMsg_
onUrlRequest =
    UrlClicked


onUrlChange : Url -> FrontendMsg_
onUrlChange =
    UrlChanged


init : Url -> Key -> ( FrontendModel_, Command FrontendOnly ToBackend FrontendMsg_, AudioCmd FrontendMsg_ )
init url key =
    let
        route : Route
        route =
            Route.decode url
    in
    ( Loading
        { navigationKey = key
        , clientId = Nothing
        , route = route
        , windowSize = Coord.xy 1920 1080
        , time = Nothing
        , loginStatus = LoadingData
        , loginType = LoginWithEmail
        , startupData = Nothing
        , publicGoMatch =
            case route of
                PublicGoMatchRoute _ ->
                    PublicGoMatch_Loading

                _ ->
                    PublicGoMatch_NotLoaded
        , popSound = Err Audio.UnknownError
        }
    , Command.batch
        [ BrowserNavigation.replaceUrl key (Route.encode route)
        , Task.perform (\{ viewport } -> GotWindowSize (round viewport.width) (round viewport.height)) Dom.getViewport
        , Lamdera.sendToBackend
            (CheckLoginRequest (routeToInitialDataRequest route))
        , case route of
            PublicGoMatchRoute goMatchPublicId ->
                Lamdera.sendToBackend (GetPublicGoMatchRequest goMatchPublicId)

            _ ->
                Command.none
        , Ports.loadStartupData
        ]
    , Audio.loadAudio LoadedPopSound "/pop.mp3"
    )


initLoadedFrontend :
    LoadingFrontend
    -> ClientId
    -> Time.Posix
    -> Ports.StartupData
    -> Result () LoginData
    -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg_, AudioCmd FrontendMsg_ )
initLoadedFrontend loading clientId time startupData loginResult =
    let
        ( loginStatus, cmdB ) =
            case loginResult of
                Ok loginData ->
                    -- The emoji data is requested as part of this same load, so it's
                    -- always still on its way at this point.
                    loadedInitHelper startupData Nothing loginData loading |> Tuple.mapFirst LoggedIn

                Err () ->
                    ( NotLoggedIn
                        { loginForm = Nothing
                        , recoveryLogin = RecoveryLogin.init
                        , useInviteAfterLoggedIn = Nothing
                        , textInputFocus = Nothing
                        }
                    , Command.none
                    )

        ( aiChatModel, aiChatCmd ) =
            AiChat.init

        model : LoadedFrontend
        model =
            { navigationKey = loading.navigationKey
            , clientId = clientId
            , route = loading.route
            , time = time
            , timezone = startupData.timezone
            , windowSize = loading.windowSize
            , virtualKeyboardOpen = False
            , loginStatus = loginStatus
            , loginType = loading.loginType
            , elmUiState = Ui.Anim.init
            , lastCopied = Nothing
            , drag = NoDrag
            , dragPrevious = NoDrag
            , aiChatModel = aiChatModel
            , pageHasFocus = True
            , versionNumber = Nothing
            , emojiData = Nothing
            , publicGoMatch = loading.publicGoMatch
            , imageViewer = Nothing
            , toFrontendLogs = Nothing
            , popSound = loading.popSound
            , startupData = startupData
            , appBadgeCount = Nothing
            }

        ( model2, cmdA ) =
            FrontendExtra.routeRequest Nothing model.route model

        ( model3, badgeCmd ) =
            checkAppBadgeChange model2
    in
    ( model3
    , Command.batch
        [ cmdB
        , cmdA
        , badgeCmd
        , Command.map AiChatToBackend AiChatMsg aiChatCmd
        , checkAppVersion True
        , case loginResult of
            Ok _ ->
                Ports.registerServiceWorker

            Err _ ->
                Command.none
        , Emoji.requestEmojiData GotEmojiData
        ]
    , Audio.cmdNone
    )


loadedInitHelper :
    Ports.StartupData
    -> Maybe CachedEmojiData
    -> LoginData
    -> { a | windowSize : Coord CssPixels, navigationKey : Key, route : Route }
    -> ( LoggedIn2, Command FrontendOnly ToBackend FrontendMsg_ )
loadedInitHelper startupData emojiData loginData loading =
    let
        local : LocalState
        local =
            loginDataToLocalState startupData emojiData loginData

        loggedIn : LoggedIn2
        loggedIn =
            { localState = Local.init local
            , admin =
                case loginData.adminData of
                    IsAdminLoginData _ ->
                        Pages.Admin.initForAdmin
                            (case loading.route of
                                AdminRoute params ->
                                    params

                                _ ->
                                    { highlightLog = Nothing }
                            )

                    IsAdminButNoData ->
                        Pages.Admin.initForAdmin
                            (case loading.route of
                                AdminRoute params ->
                                    params

                                _ ->
                                    { highlightLog = Nothing }
                            )

                    IsNotAdminLoginData ->
                        Pages.Admin.initForUser
            , drafts = SeqDict.empty
            , newChannelForm = SeqDict.empty
            , editChannelForm = SeqDict.empty
            , editGuildForm = SeqDict.empty
            , newGuildForm = Nothing
            , typingDebouncer = True
            , textInputFocus = Nothing
            , previousTextInputFocus = Nothing
            , messageHover = NoMessageHover
            , showEmojiSelector = EmojiSelectorHidden
            , editMessage = SeqDict.empty
            , replyTo = SeqDict.empty
            , revealedSpoilers = SeqDict.empty
            , sidebarMode = ChannelSidebarNotDragging { offset = channelSidebarTarget loading.route }
            , userOptions = Nothing
            , twoFactor =
                case loginData.twoFactorAuthenticationEnabled of
                    Just enabledAt ->
                        TwoFactorAlreadyComplete enabledAt

                    Nothing ->
                        TwoFactorNotStarted
            , filesToUpload = SeqDict.empty
            , showFileToUploadInfo = Nothing
            , isReloading = False
            , channelScrollPosition = ScrolledToBottom
            , textEditor = TextEditor.init
            , profilePictureEditor = ImageEditor.init
            , guildIconEditor = Nothing
            , externalLinkWarning = Nothing
            , emojiSelector = Emoji.selectorInit
            , voiceChat = Call.initModel
            , games = SeqDict.empty
            , fileDragOverCount = NoFileDrag Nothing
            , drawingMode = Drawing.init
            , newMessagesWhileNotScrolledToBottom = 0
            , showInviteLinkQrCode = Nothing
            , friendsSearch = ""
            , channelSearch = ""
            , showNewPrivateKey = Nothing
            , e2eeError = Nothing
            , e2eePrivateKeyText = ""
            , e2eeKeysOnThisDevice = SeqSet.fromList startupData.e2eeKeys
            , pendingEncryptedMessages = SeqDict.empty
            , nextEncryptionRequestId = Id.fromInt 0
            , pendingDecryptedMessages = SeqDict.empty
            , nextDecryptionRequestId = Id.fromInt 0
            , e2eeSectionsExpanded = SeqDict.empty
            , typedTextCounter = 0
            , decryptedMessages = SeqDict.empty
            }
    in
    ( loggedIn
    , Command.batch
        [ case loading.route of
            AdminRoute params ->
                case params.highlightLog of
                    Just _ ->
                        Dom.getElement Pages.Admin.logSectionId
                            |> Task.andThen (\{ element } -> Dom.setViewport 0 (element.y + 40))
                            |> Task.attempt (\_ -> ScrolledToLogSection)

                    Nothing ->
                        Command.none

            _ ->
                Command.none
        , -- We need to check if a video preview is visible immediately since we might be on the call route
          Call.displayModeChangeCmd
            Call.NoVideo
            (Call.displayMode (MyUi.isMobile loading) local.localUser.session.userId loading.route local.calls)
            loggedIn.voiceChat
        ]
    )


loginDataToLocalState : Ports.StartupData -> Maybe CachedEmojiData -> LoginData -> LocalState
loginDataToLocalState startupData emojiData loginData =
    { adminData =
        case loginData.adminData of
            IsAdminLoginData adminData ->
                IsAdmin (FrontendExtra.initAdminData adminData)

            IsNotAdminLoginData ->
                IsNotAdmin

            IsAdminButNoData ->
                IsAdminButDataNotLoaded
    , guilds = loginData.guilds
    , discordGuilds = loginData.discordGuilds
    , dmChannels = loginData.dmChannels
    , discordDmChannels = loginData.discordDmChannels
    , joinGuildError = Nothing
    , localUser =
        { session = loginData.session
        , currentlyViewing = loginData.currentlyViewing
        , user = loginData.user
        , otherUsers = loginData.otherUsers
        , discordUsers = loginData.discordUsers
        , timezone = startupData.timezone
        , userAgent = startupData.userAgent
        , devicePixelRatio = startupData.devicePixelRatio
        , stickers = loginData.stickers
        , customEmojis = loginData.customEmojis
        , emojiData = emojiData
        }
    , otherSessions = loginData.otherSessions
    , publicVapidKey = loginData.publicVapidKey
    , textEditor = loginData.textEditor
    , calls = Call.init loginData.voiceChatPeers
    }


tryInitLoadedFrontend : LoadingFrontend -> ( FrontendModel_, Command FrontendOnly ToBackend FrontendMsg_, AudioCmd FrontendMsg_ )
tryInitLoadedFrontend loading =
    let
        maybeLoginStatus =
            case loading.loginStatus of
                LoadingData ->
                    Nothing

                LoadSuccess loginData ->
                    Just (Ok loginData)

                LoadError ->
                    Just (Err ())
    in
    case T4 loading.clientId loading.time maybeLoginStatus loading.startupData of
        T4 (Just clientId) (Just time) (Just loginStatus) (Just startupData) ->
            let
                ( loaded, audioCmd, cmd ) =
                    initLoadedFrontend loading clientId time startupData loginStatus
            in
            ( Loaded loaded, audioCmd, cmd )

        _ ->
            ( Loading loading, Command.none, Audio.cmdNone )


update : AudioData -> FrontendMsg_ -> FrontendModel_ -> ( FrontendModel_, Command FrontendOnly ToBackend FrontendMsg_, AudioCmd FrontendMsg_ )
update _ msg model =
    case model of
        Loading loading ->
            case msg of
                GotWindowSize width height ->
                    ( Loading { loading | windowSize = Coord.xy width height }, Command.none, Audio.cmdNone )

                GotStartupData (Ok startupData) ->
                    tryInitLoadedFrontend
                        { loading | startupData = Just startupData, time = Just startupData.loadStartupDataTime }

                GotStartupData (Err error) ->
                    let
                        _ =
                            Debug.log "GotStartupData failed!" error
                    in
                    ( model, Command.none, Audio.cmdNone )

                LoadedPopSound result ->
                    ( Loading { loading | popSound = result }, Command.none, Audio.cmdNone )

                _ ->
                    ( model, Command.none, Audio.cmdNone )

        Loaded loaded ->
            -- We only care about the user accidentally triggering button presses while dragging on mobile.
            -- On desktop it's less of an issue and it's kind of annoying when clicking a button and nothing happens because you slightly moved the cursor and it counted as a drag
            case ( MyUi.isMobile loaded && FrontendExtra.isPressMsg msg, loaded.dragPrevious ) of
                ( True, Dragging _ ) ->
                    ( model, Command.none, Audio.cmdNone )

                ( True, _ ) ->
                    let
                        ( loadedNew, cmd ) =
                            updateLoaded msg loaded

                        ( loadedNew2, badgeCmd ) =
                            checkAppBadgeChange loadedNew
                    in
                    ( case loadedNew2.loginStatus of
                        LoggedIn loggedIn ->
                            { loadedNew2
                                | loginStatus = LoggedIn { loggedIn | previousTextInputFocus = Nothing }
                            }
                                |> Loaded

                        NotLoggedIn _ ->
                            Loaded loadedNew2
                    , Command.batch [ cmd, checkCallDisplayModeChange loaded loadedNew2, badgeCmd ]
                    , Audio.cmdNone
                    )

                _ ->
                    let
                        ( loadedNew, cmd ) =
                            updateLoaded msg loaded

                        ( loadedNew2, badgeCmd ) =
                            checkAppBadgeChange loadedNew
                    in
                    ( Loaded loadedNew2
                    , Command.batch [ cmd, checkCallDisplayModeChange loaded loadedNew2, badgeCmd ]
                    , Audio.cmdNone
                    )


parseDomainWhitelistInput : String -> SeqSet RichText.Domain
parseDomainWhitelistInput text =
    String.split "," text
        |> List.filterMap
            (\text2 ->
                case Url.fromString ("https://" ++ String.trim text2) of
                    Just url ->
                        RichText.urlToDomain url |> Just

                    Nothing ->
                        Nothing
            )
        |> SeqSet.fromList


updateLoaded : FrontendMsg_ -> LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg_ )
updateLoaded msg model =
    case msg of
        UrlClicked urlRequest ->
            case urlRequest of
                Internal url ->
                    let
                        route : Route
                        route =
                            Route.decode url

                        isSameRoute : Bool
                        isSameRoute =
                            model.route == route
                    in
                    ( model
                    , Command.batch
                        [ if isSameRoute then
                            BrowserNavigation.replaceUrl model.navigationKey (Route.encode route)

                          else
                            BrowserNavigation.pushUrl model.navigationKey (Route.encode route)
                        ]
                    )

                External url ->
                    ( model, BrowserNavigation.load url )

        UrlChanged url ->
            FrontendExtra.routeRequest (Just model.route) (Route.decode url) model

        GotTime time ->
            ( { model | time = time }
            , -- A big gap between once-per-second ticks means the page was suspended (OS
              -- sleep or browser tab freezing). A new version might have been deployed in
              -- the meantime and no focus/visibility event fires in the OS sleep case.
              if model.pageHasFocus && (Duration.from model.time time |> Quantity.greaterThan (Duration.seconds 10)) then
                checkAppVersion True

              else
                Command.none
            )

        GotWindowSize width height ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn | drawingMode = Drawing.resetAnchor loggedIn.drawingMode }
                    , -- Zooming the page changes the device pixel ratio and resizes the window at
                      -- the same time, so this is where a new ratio turns up. Ask for it so ascii
                      -- art can pick a font size that lands on whole device pixels. Moving the
                      -- window to a screen with a different pixel density doesn't always resize it,
                      -- but the startup data gets re-sent whenever the window regains focus, and
                      -- that carries the ratio too.
                      Ports.requestDevicePixelRatio
                    )
                )
                { model | windowSize = Coord.xy width height }

        PressedShowLogin ->
            case model.loginStatus of
                LoggedIn _ ->
                    ( model, Command.none )

                NotLoggedIn notLoggedIn ->
                    ( { model
                        | loginStatus =
                            NotLoggedIn
                                { notLoggedIn
                                    | loginForm =
                                        case notLoggedIn.loginForm of
                                            Just _ ->
                                                notLoggedIn.loginForm

                                            Nothing ->
                                                Just LoginForm.init
                                }
                      }
                    , Command.none
                    )

        AdminPageMsg adminPageMsg ->
            case model.loginStatus of
                LoggedIn loggedIn ->
                    case (Local.model loggedIn.localState).adminData of
                        IsAdmin adminData ->
                            let
                                ( newAdmin, cmd, outMsg ) =
                                    Pages.Admin.update
                                        model.navigationKey
                                        model.time
                                        adminData
                                        (Local.model loggedIn.localState)
                                        adminPageMsg
                                        loggedIn.admin

                                loggedIn2 : LoggedIn2
                                loggedIn2 =
                                    { loggedIn | admin = newAdmin }
                            in
                            case outMsg of
                                Pages.Admin.AdminChange adminChange ->
                                    let
                                        ( loggedIn3, cmd2 ) =
                                            FrontendExtra.handleLocalChange
                                                model.time
                                                (Local_Admin adminChange |> Just)
                                                loggedIn2
                                                (Command.map AdminToBackend AdminPageMsg cmd)
                                    in
                                    ( { model | loginStatus = LoggedIn loggedIn3 }, cmd2 )

                                Pages.Admin.NoOutMsg ->
                                    ( { model | loginStatus = LoggedIn loggedIn2 }
                                    , Command.map AdminToBackend AdminPageMsg cmd
                                    )

                                Pages.Admin.GoToHomepage ->
                                    FrontendExtra.routePush { model | loginStatus = LoggedIn loggedIn2 } HomePageRoute

                                Pages.Admin.CopyToClipboard text ->
                                    ( { model | lastCopied = Just { copiedAt = model.time, copied = CopiedText text } }
                                    , Ports.copyToClipboard text
                                    )

                        _ ->
                            ( model, Command.none )

                NotLoggedIn _ ->
                    ( model, Command.none )

        LoginFormMsg loginFormMsg ->
            case model.loginStatus of
                LoggedIn _ ->
                    ( model, Command.none )

                NotLoggedIn notLoggedIn ->
                    let
                        requestMessagesFor : InitialLoadRequest
                        requestMessagesFor =
                            routeToInitialDataRequest model.route
                    in
                    case
                        LoginForm.update
                            (\email -> GetLoginTokenRequest (Untrusted.untrust email) |> Lamdera.sendToBackend)
                            (\loginToken ->
                                LoginWithTokenRequest requestMessagesFor loginToken model.startupData.userAgent
                                    |> Lamdera.sendToBackend
                            )
                            (\loginToken ->
                                LoginWithTwoFactorRequest requestMessagesFor loginToken model.startupData.userAgent
                                    |> Lamdera.sendToBackend
                            )
                            (\name ->
                                FinishUserCreationRequest requestMessagesFor name model.startupData.userAgent
                                    |> Lamdera.sendToBackend
                            )
                            loginFormMsg
                            (Maybe.withDefault LoginForm.init notLoggedIn.loginForm)
                    of
                        Just ( newLoginForm, cmd ) ->
                            ( { model
                                | loginStatus = NotLoggedIn { notLoggedIn | loginForm = Just newLoginForm }
                              }
                            , Command.map identity LoginFormMsg cmd
                            )

                        Nothing ->
                            let
                                model2 : LoadedFrontend
                                model2 =
                                    { model | loginStatus = NotLoggedIn { notLoggedIn | loginForm = Nothing } }
                            in
                            if Route.requiresLogin model2.route then
                                FrontendExtra.routePush model2 HomePageRoute

                            else
                                ( model2, Command.none )

        RecoveryLoginMsg recoveryLoginMsg ->
            case model.loginStatus of
                LoggedIn _ ->
                    ( model, Command.none )

                NotLoggedIn notLoggedIn ->
                    let
                        ( recoveryLogin, cmd ) =
                            RecoveryLogin.update
                                (\password ->
                                    LoginWithRecoveryPasswordRequest
                                        (routeToInitialDataRequest model.route)
                                        password
                                        model.startupData.userAgent
                                        |> Lamdera.sendToBackend
                                )
                                recoveryLoginMsg
                                notLoggedIn.recoveryLogin
                    in
                    ( { model | loginStatus = NotLoggedIn { notLoggedIn | recoveryLogin = recoveryLogin } }
                    , Command.map identity RecoveryLoginMsg cmd
                    )

        PressedLogOut sessionId ->
            ( model, Lamdera.sendToBackend (LogOutRequest sessionId) )

        ScrolledToLogSection ->
            ( model, Command.none )

        ElmUiMsg elmUiMsg ->
            ( { model | elmUiState = Ui.Anim.update ElmUiMsg elmUiMsg model.elmUiState }, Command.none )

        PressedLink route ->
            FrontendExtra.routePush model route

        DebouncedTyping ->
            FrontendExtra.updateLoggedIn
                (\loggedIn -> ( { loggedIn | typingDebouncer = True }, Command.none ))
                model

        SelectedFilesToAttach ( guildOrDmId, threadRoute ) file files ->
            FrontendExtra.gotFiles guildOrDmId threadRoute (Nonempty file files) model

        NewChannelFormChanged guildId newChannelForm ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn
                        | newChannelForm =
                            SeqDict.insert guildId newChannelForm loggedIn.newChannelForm
                      }
                    , Command.none
                    )
                )
                model

        PressedSubmitNewChannel guildId newChannelForm ->
            case model.loginStatus of
                LoggedIn loggedIn ->
                    case Result.map2 Tuple.pair (ChannelName.fromString newChannelForm.name) (ChannelDescription.fromString newChannelForm.description) of
                        Ok ( channelName, channelDescription ) ->
                            let
                                oldLoggedIn : LoggedIn2
                                oldLoggedIn =
                                    loggedIn

                                ( loggedIn2, cmd ) =
                                    FrontendExtra.handleLocalChange
                                        model.time
                                        (Local_NewChannel model.time guildId channelName channelDescription |> Just)
                                        { loggedIn
                                            | newChannelForm =
                                                SeqDict.remove guildId loggedIn.newChannelForm
                                        }
                                        Command.none

                                nextChannelId : Id ChannelId
                                nextChannelId =
                                    case SeqDict.get guildId (Local.model oldLoggedIn.localState).guilds of
                                        Just guild ->
                                            Id.nextId guild.channels

                                        Nothing ->
                                            Id.fromInt 0

                                ( model2, routeCmd ) =
                                    FrontendExtra.routePush
                                        { model | loginStatus = LoggedIn loggedIn2 }
                                        (GuildRoute
                                            guildId
                                            (ChannelRoute nextChannelId (NoThreadWithFriends Nothing HideChannelSettings) Nothing)
                                            ChannelsHiddenOnMobile
                                        )
                            in
                            ( model2, Command.batch [ routeCmd, cmd ] )

                        Err _ ->
                            ( { model
                                | loginStatus =
                                    LoggedIn
                                        { loggedIn
                                            | newChannelForm =
                                                SeqDict.insert
                                                    guildId
                                                    { newChannelForm | pressedSubmit = True }
                                                    loggedIn.newChannelForm
                                        }
                              }
                            , Command.none
                            )

                NotLoggedIn _ ->
                    ( model, Command.none )

        EditChannelFormChanged guildId channelId form ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn
                        | editChannelForm =
                            SeqDict.insert
                                ( guildId, channelId )
                                form
                                loggedIn.editChannelForm
                      }
                    , Command.none
                    )
                )
                model

        PressedResetEditChannelChanges guildId channelId ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn
                        | editChannelForm =
                            SeqDict.remove ( guildId, channelId ) loggedIn.editChannelForm
                      }
                    , Command.none
                    )
                )
                model

        PressedSubmitEditChannelChanges guildId channelId form ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    case ( ChannelName.fromString form.name, ChannelDescription.fromString form.description ) of
                        ( Ok channelName, Ok channelDescription ) ->
                            FrontendExtra.handleLocalChange
                                model.time
                                (Local_EditChannel guildId channelId channelName channelDescription |> Just)
                                { loggedIn
                                    | editChannelForm =
                                        SeqDict.remove ( guildId, channelId ) loggedIn.editChannelForm
                                }
                                Command.none

                        _ ->
                            ( { loggedIn
                                | editChannelForm =
                                    SeqDict.insert
                                        ( guildId, channelId )
                                        { form | pressedSubmit = True }
                                        loggedIn.editChannelForm
                              }
                            , Command.none
                            )
                )
                model

        PressedDeleteChannel guildId channelId ->
            case model.loginStatus of
                LoggedIn loggedIn ->
                    let
                        local : LocalState
                        local =
                            Local.model loggedIn.localState

                        ( model2, cmd ) =
                            case SeqDict.get guildId local.guilds of
                                Just guild ->
                                    FrontendExtra.routePush
                                        model
                                        (GuildRoute
                                            guildId
                                            (ChannelRoute
                                                (LocalState.announcementChannel guild)
                                                (NoThreadWithFriends Nothing HideChannelSettings)
                                                Nothing
                                            )
                                            ChannelsVisibleOnMobile
                                        )

                                Nothing ->
                                    ( model, Command.none )

                        ( loggedIn2, cmd2 ) =
                            FrontendExtra.handleLocalChange
                                model2.time
                                (Local_DeleteChannel guildId channelId |> Just)
                                { loggedIn
                                    | drafts =
                                        SeqDict.remove
                                            ( GuildOrDmId (GuildOrDmId_Guild { guildId = guildId, channelId = channelId }), NoThread )
                                            loggedIn.drafts
                                    , editChannelForm =
                                        SeqDict.remove ( guildId, channelId ) loggedIn.editChannelForm
                                }
                                cmd
                    in
                    ( { model | loginStatus = LoggedIn loggedIn2 }, cmd2 )

                NotLoggedIn _ ->
                    ( model, Command.none )

        EditGuildFormChanged guildId form ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn
                        | editGuildForm = SeqDict.insert guildId form loggedIn.editGuildForm
                      }
                    , Command.none
                    )
                )
                model

        PressedResetEditGuildChanges guildId ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn
                        | editGuildForm = SeqDict.remove guildId loggedIn.editGuildForm
                      }
                    , Command.none
                    )
                )
                model

        PressedSubmitEditGuildChanges guildId form ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    case GuildName.fromString form.name of
                        Ok guildName ->
                            FrontendExtra.handleLocalChange
                                model.time
                                (Local_EditGuildName guildId guildName |> Just)
                                { loggedIn
                                    | editGuildForm = SeqDict.remove guildId loggedIn.editGuildForm
                                }
                                Command.none

                        Err _ ->
                            ( { loggedIn
                                | editGuildForm =
                                    SeqDict.insert guildId { form | pressedSubmit = True } loggedIn.editGuildForm
                              }
                            , Command.none
                            )
                )
                model

        PressedDeleteGuild guildId ->
            case model.loginStatus of
                LoggedIn loggedIn ->
                    let
                        ( model2, cmd ) =
                            FrontendExtra.routePush model HomePageRoute

                        ( loggedIn2, cmd2 ) =
                            FrontendExtra.handleLocalChange
                                model2.time
                                (Local_DeleteGuild guildId |> Just)
                                { loggedIn
                                    | editGuildForm = SeqDict.remove guildId loggedIn.editGuildForm
                                }
                                cmd
                    in
                    ( { model | loginStatus = LoggedIn loggedIn2 }, cmd2 )

                NotLoggedIn _ ->
                    ( model, Command.none )

        PressedLeaveGuild guildId ->
            case model.loginStatus of
                LoggedIn loggedIn ->
                    let
                        ( model2, cmd ) =
                            FrontendExtra.routePush model HomePageRoute

                        ( loggedIn2, cmd2 ) =
                            FrontendExtra.handleLocalChange
                                model2.time
                                (Local_LeaveGuild guildId |> Just)
                                { loggedIn
                                    | editGuildForm = SeqDict.remove guildId loggedIn.editGuildForm
                                }
                                cmd
                    in
                    ( { model | loginStatus = LoggedIn loggedIn2 }, cmd2 )

                NotLoggedIn _ ->
                    ( model, Command.none )

        PressedCreateInviteLink guildId ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    FrontendExtra.handleLocalChange
                        model.time
                        (Local_NewInviteLink model.time guildId EmptyPlaceholder |> Just)
                        loggedIn
                        Command.none
                )
                model

        PressedDeleteInviteLink guildId inviteLinkId ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    FrontendExtra.handleLocalChange
                        model.time
                        (Local_DeleteInviteLink guildId inviteLinkId |> Just)
                        loggedIn
                        Command.none
                )
                model

        PressedToggleInviteLinkQrCode inviteLinkId ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn
                        | showInviteLinkQrCode =
                            if Just inviteLinkId == loggedIn.showInviteLinkQrCode then
                                Nothing

                            else
                                Just inviteLinkId
                      }
                    , Command.none
                    )
                )
                model

        FrontendNoOp ->
            ( model, Command.none )

        PressedCopyText text ->
            copyText text model

        PressedCopyImage imageUrl ->
            ( { model | lastCopied = Just { copiedAt = model.time, copied = CopiedImage imageUrl } }
            , Ports.copyImageToClipboard imageUrl
            )

        NewGuildFormChanged newGuildForm ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn | newGuildForm = Just newGuildForm }
                    , Command.none
                    )
                )
                model

        PressedSubmitNewGuild newGuildForm ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    case GuildName.fromString newGuildForm.name of
                        Ok guildName ->
                            FrontendExtra.handleLocalChange
                                model.time
                                (Local_NewGuild model.time guildName EmptyPlaceholder |> Just)
                                -- The form is left as is until the backend replies with the new
                                -- guild and we navigate to it
                                loggedIn
                                Command.none

                        Err _ ->
                            ( { loggedIn | newGuildForm = Just { newGuildForm | pressedSubmit = True } }
                            , Command.none
                            )
                )
                model

        GotPingUserPosition htmlId result ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    ( case result of
                        Ok ok ->
                            case loggedIn.textInputFocus of
                                Just textInputFocus ->
                                    if textInputFocus.htmlId == htmlId then
                                        { loggedIn
                                            | textInputFocus = Just { textInputFocus | dropdown = Just ok }
                                            , previousTextInputFocus = loggedIn.textInputFocus
                                        }

                                    else
                                        loggedIn

                                Nothing ->
                                    loggedIn

                        Err _ ->
                            loggedIn
                    , Command.none
                    )
                )
                model

        SetFocus ->
            ( model, Command.none )

        RemoveFocus ->
            ( model, Command.none )

        KeyDown { ctrlKey, metaKey, shiftKey, key } ->
            let
                ctrlOrMeta =
                    ctrlKey || metaKey
            in
            case ( ctrlOrMeta, shiftKey, key ) of
                ( _, _, "Escape" ) ->
                    FrontendExtra.handleEscapeKey model

                ( True, False, "z" ) ->
                    FrontendExtra.handleUndo model

                ( True, True, "z" ) ->
                    FrontendExtra.handleRedo model

                ( True, _, "y" ) ->
                    FrontendExtra.handleRedo model

                _ ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            case loggedIn.textInputFocus of
                                Just _ ->
                                    ( loggedIn, Command.none )

                                Nothing ->
                                    case FrontendExtra.currentGame (Local.model loggedIn.localState) model of
                                        Just { guildOrDmId, matchId, match } ->
                                            ( { loggedIn
                                                | games =
                                                    SeqDict.update
                                                        guildOrDmId
                                                        (Game.pressedKey matchId key match)
                                                        loggedIn.games
                                              }
                                            , Command.none
                                            )

                                        Nothing ->
                                            ( loggedIn, Command.none )
                        )
                        model

        MessageMenu_PressedShowReactionEmojiSelector guildOrDmId threadRoute _ ->
            showReactionEmojiSelector guildOrDmId threadRoute model

        MessageMenu_PressedReactionEmoji emoji ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    case loggedIn.messageHover of
                        NoMessageHover ->
                            ( loggedIn, Command.none )

                        MessageMenu data ->
                            MessageMenu.close model loggedIn
                                |> toggleReactionEmoji emoji data.guildOrDmId data.threadRoute model

                        MessageHover guildOrDmId threadRoute ->
                            MessageMenu.close model loggedIn
                                |> toggleReactionEmoji emoji guildOrDmId threadRoute model
                )
                model

        MessageMenu_PressedEditMessage guildOrDmId threadRoute ->
            pressedEditMessage guildOrDmId threadRoute model

        EmojiSelectorMsg emojiMsg ->
            case emojiMsg of
                Emoji.PressedSelectEmoji emojiOrSticker ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            case loggedIn.showEmojiSelector of
                                EmojiSelectorHidden ->
                                    ( loggedIn, Command.none )

                                EmojiSelectorForReaction guildOrDmId threadRoute ->
                                    case emojiOrSticker of
                                        EmojiOrSticker_UnicodeEmoji emoji ->
                                            FrontendExtra.handleLocalChange
                                                model.time
                                                (Local_AddReactionEmoji guildOrDmId threadRoute (EmojiOrCustomEmoji_Emoji emoji) |> Just)
                                                { loggedIn | showEmojiSelector = EmojiSelectorHidden }
                                                (Scroll.toBottomOfChannelIfAtBottom Pages.Guild.conversationContainerId SetScrollToBottom loggedIn.channelScrollPosition)

                                        EmojiOrSticker_Sticker _ ->
                                            ( loggedIn, Command.none )

                                        EmojiOrSticker_CustomEmoji customEmojiId ->
                                            FrontendExtra.handleLocalChange
                                                model.time
                                                (Local_AddReactionEmoji guildOrDmId threadRoute (EmojiOrCustomEmoji_CustomEmoji customEmojiId) |> Just)
                                                { loggedIn | showEmojiSelector = EmojiSelectorHidden }
                                                (Scroll.toBottomOfChannelIfAtBottom Pages.Guild.conversationContainerId SetScrollToBottom loggedIn.channelScrollPosition)

                                EmojiSelectorForMessage maybeSelection ->
                                    insertEmojiOrSticker Pages.Guild.channelTextInputId maybeSelection emojiOrSticker model loggedIn

                                EmojiSelectorForEditMessage _ maybeSelection ->
                                    insertEmojiOrSticker MessageMenu.editMessageTextInputId maybeSelection emojiOrSticker model loggedIn

                                EmojiSelectorForSheepGameInput input _ maybeSelection ->
                                    insertEmojiOrSticker
                                        (SheepGame.inputId input)
                                        maybeSelection
                                        emojiOrSticker
                                        model
                                        loggedIn

                                EmojiSelectorForSheepGameReaction guildOrDmId matchId target ->
                                    case emojiOrSticker of
                                        EmojiOrSticker_UnicodeEmoji emoji ->
                                            addSheepGameReaction
                                                guildOrDmId
                                                matchId
                                                target
                                                (EmojiOrCustomEmoji_Emoji emoji)
                                                model
                                                loggedIn

                                        EmojiOrSticker_CustomEmoji customEmojiId ->
                                            addSheepGameReaction
                                                guildOrDmId
                                                matchId
                                                target
                                                (EmojiOrCustomEmoji_CustomEmoji customEmojiId)
                                                model
                                                loggedIn

                                        EmojiOrSticker_Sticker _ ->
                                            ( loggedIn, Command.none )
                        )
                        model

                Emoji.PressedContainer ->
                    ( model, Command.none )

                Emoji.PressedCategory category offset ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            let
                                emojiSelector =
                                    loggedIn.emojiSelector
                            in
                            ( { loggedIn | emojiSelector = { emojiSelector | category = category } }
                            , Dom.setViewportOf Emoji.scrollContainerId 0 (toFloat offset)
                                |> Task.attempt (\_ -> FrontendNoOp)
                            )
                        )
                        model

                Emoji.ScrolledToCategory category ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            let
                                emojiSelector =
                                    loggedIn.emojiSelector
                            in
                            ( { loggedIn | emojiSelector = { emojiSelector | category = category } }
                            , Command.none
                            )
                        )
                        model

                Emoji.PressedSkinTone skinTone ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            FrontendExtra.handleLocalChange
                                model.time
                                (Local_SetEmojiSkinTone skinTone |> Just)
                                loggedIn
                                Command.none
                        )
                        model

                Emoji.MouseEnteredEmoji index emoji ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            let
                                emojiSelector =
                                    loggedIn.emojiSelector
                            in
                            ( { loggedIn
                                | emojiSelector =
                                    { emojiSelector | emojiHovered = Just { index = index, emoji = emoji } }
                              }
                            , Command.none
                            )
                        )
                        model

                Emoji.KeyboardMovedHover index emoji ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            let
                                emojiSelector =
                                    loggedIn.emojiSelector
                            in
                            ( { loggedIn
                                | emojiSelector =
                                    { emojiSelector | emojiHovered = Just { index = index, emoji = emoji } }
                              }
                            , scrollEmojiIntoView index
                            )
                        )
                        model

                Emoji.ClearEmojiHover ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            let
                                emojiSelector =
                                    loggedIn.emojiSelector
                            in
                            ( { loggedIn | emojiSelector = { emojiSelector | emojiHovered = Nothing } }
                            , Command.none
                            )
                        )
                        model

                Emoji.TypedSearchText text ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            ( { loggedIn | emojiSelector = Emoji.setSearch text loggedIn.emojiSelector }, Command.none )
                        )
                        model

                Emoji.PressedClearSearch ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            ( { loggedIn | emojiSelector = Emoji.setSearch "" loggedIn.emojiSelector }, Command.none )
                        )
                        model

                Emoji.NoOp ->
                    ( model, Command.none )

        MessageMenu_PressedReply threadRoute ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    case Route.toGuildOrDmId (Local.model loggedIn.localState).localUser.session.userId model.route of
                        Just ( guildOrDmId, _ ) ->
                            pressedReply guildOrDmId threadRoute loggedIn model

                        Nothing ->
                            ( loggedIn, Command.none )
                )
                model

        MessageMenu_PressedOpenThread messageIndex ->
            case ( model.route, model.loginStatus ) of
                ( GuildRoute guildId (ChannelRoute channelId (NoThreadWithFriends _ _) _) _, LoggedIn loggedIn ) ->
                    FrontendExtra.routePush
                        { model | loginStatus = MessageMenu.close model loggedIn |> LoggedIn }
                        (GuildRoute
                            guildId
                            (ChannelRoute channelId (ViewThreadWithFriends messageIndex Nothing HideChannelSettings) Nothing)
                            ChannelsHiddenOnMobile
                        )

                ( DmRoute dmRoute, LoggedIn loggedIn ) ->
                    case dmRoute.threadRoute of
                        NoThreadWithFriends _ _ ->
                            FrontendExtra.routePush
                                { model | loginStatus = MessageMenu.close model loggedIn |> LoggedIn }
                                (DmRoute { dmRoute | threadRoute = ViewThreadWithFriends messageIndex Nothing HideChannelSettings })

                        ViewThreadWithFriends _ _ _ ->
                            ( model, Command.none )

                ( DiscordGuildRoute guildRoute, LoggedIn loggedIn ) ->
                    case guildRoute.channelRoute of
                        DiscordChannel_ChannelRoute channelId (NoThreadWithFriends _ _) _ ->
                            FrontendExtra.routePush
                                { model | loginStatus = MessageMenu.close model loggedIn |> LoggedIn }
                                (DiscordGuildRoute
                                    { guildRoute
                                        | channelRoute =
                                            DiscordChannel_ChannelRoute
                                                channelId
                                                (ViewThreadWithFriends messageIndex Nothing HideChannelSettings)
                                                Nothing
                                    }
                                )

                        _ ->
                            ( model, Command.none )

                ( DiscordDmRoute _, LoggedIn _ ) ->
                    ( model, Command.none )

                _ ->
                    ( model, Command.none )

        PressedCloseReplyTo guildOrDmId ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn | replyTo = SeqDict.remove guildOrDmId loggedIn.replyTo }
                    , FrontendExtra.setFocus model Pages.Guild.channelTextInputId
                    )
                )
                model

        VisibilityChanged visibility ->
            case visibility of
                Effect.Browser.Events.Visible ->
                    ( model
                    , Command.batch
                        [ FrontendExtra.setFocus model Pages.Guild.channelTextInputId
                        , Ports.setFavicon "/favicon.ico"
                        , Ports.closeNotifications
                        , Ports.registerServiceWorker
                        , checkAppVersion True
                        ]
                    )

                Effect.Browser.Events.Hidden ->
                    ( model, Command.none )

        CheckedNotificationPermission notificationPermission ->
            let
                startupData =
                    model.startupData
            in
            ( { model | startupData = { startupData | notificationPermission = notificationPermission } }, Command.none )

        TouchStart timeStamp touches ->
            touchStart Nothing Nothing Nothing (Duration.addTo model.startupData.timeOrigin timeStamp) touches model

        TouchMoved timeStamp newTouches ->
            let
                time : Time.Posix
                time =
                    Duration.addTo model.startupData.timeOrigin timeStamp
            in
            case model.drag of
                Dragging dragging ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            let
                                averageMove : { x : Float, y : Float }
                                averageMove =
                                    Touch.averageTouchMove dragging.touches newTouches |> Vector2d.unwrap
                            in
                            ( case dragging.target of
                                Drag_CallThumbnail ->
                                    { loggedIn
                                        | voiceChat =
                                            Call.dragThumbnail
                                                (MyUi.isMobile model)
                                                averageMove
                                                model.windowSize
                                                loggedIn.voiceChat
                                    }

                                Drag_Game ->
                                    loggedIn

                                Drag_Channel ->
                                    case ( loggedIn.showFileToUploadInfo, loggedIn.messageHover ) of
                                        ( Just _, _ ) ->
                                            loggedIn

                                        ( Nothing, MessageMenu messageMenu ) ->
                                            if dragging.horizontalStart then
                                                loggedIn

                                            else
                                                let
                                                    previousOffset =
                                                        Types.messageMenuMobileOffset messageMenu.mobileMode

                                                    offset =
                                                        Quantity.min
                                                            (MessageMenu.mobileMenuMaxHeight
                                                                messageMenu
                                                                (Local.model loggedIn.localState)
                                                                model
                                                            )
                                                            (Quantity.plus
                                                                (CssPixels.cssPixels -averageMove.y)
                                                                previousOffset
                                                            )
                                                in
                                                { loggedIn
                                                    | messageHover =
                                                        MessageMenu
                                                            { messageMenu
                                                                | mobileMode =
                                                                    { offset = offset
                                                                    , previousOffset = previousOffset
                                                                    , time = time
                                                                    }
                                                                        |> MessageMenuDragging
                                                            }
                                                }

                                        _ ->
                                            if dragging.horizontalStart then
                                                let
                                                    tHorizontal : Float
                                                    tHorizontal =
                                                        averageMove.x / toFloat (Coord.xRaw model.windowSize)
                                                in
                                                { loggedIn
                                                    | sidebarMode =
                                                        case ( loggedIn.textInputFocus, isTouchingTextInput dragging.touches ) of
                                                            ( Just _, True ) ->
                                                                loggedIn.sidebarMode

                                                            _ ->
                                                                dragChannelSidebar
                                                                    (channelSidebarDragRange model.route)
                                                                    time
                                                                    tHorizontal
                                                                    loggedIn.sidebarMode
                                                }

                                            else
                                                loggedIn
                            , Command.none
                            )
                        )
                        { model | drag = Dragging { dragging | touches = newTouches }, dragPrevious = model.drag }

                NoDrag ->
                    ( model, Command.none )

                DragStart _ startTouches ->
                    let
                        averageMove : { x : Float, y : Float }
                        averageMove =
                            Touch.averageTouchMove startTouches newTouches |> Vector2d.unwrap

                        horizontalStart : Bool
                        horizontalStart =
                            abs averageMove.x > abs averageMove.y
                    in
                    case dragTarget startTouches model of
                        Just target ->
                            FrontendExtra.updateLoggedIn
                                (\loggedIn ->
                                    ( case target of
                                        Drag_CallThumbnail ->
                                            { loggedIn
                                                | voiceChat =
                                                    Call.dragThumbnail
                                                        (MyUi.isMobile model)
                                                        averageMove
                                                        model.windowSize
                                                        loggedIn.voiceChat
                                            }

                                        Drag_Channel ->
                                            if horizontalStart then
                                                let
                                                    tHorizontal : Float
                                                    tHorizontal =
                                                        averageMove.x / toFloat (Coord.xRaw model.windowSize)
                                                in
                                                { loggedIn
                                                    | sidebarMode =
                                                        case ( loggedIn.textInputFocus, isTouchingTextInput startTouches ) of
                                                            ( Just _, True ) ->
                                                                loggedIn.sidebarMode

                                                            _ ->
                                                                dragChannelSidebar (channelSidebarDragRange model.route) time tHorizontal loggedIn.sidebarMode
                                                }

                                            else
                                                loggedIn

                                        Drag_Game ->
                                            case FrontendExtra.currentGame (Local.model loggedIn.localState) model of
                                                Just { guildOrDmId, matchId, match } ->
                                                    { loggedIn
                                                        | games =
                                                            SeqDict.updateIfExists
                                                                guildOrDmId
                                                                (Game.dragStart
                                                                    time
                                                                    model.windowSize
                                                                    (Local.model loggedIn.localState).localUser.session.userId
                                                                    (Touch.removeSafeAreaTopInset
                                                                        model.startupData.safeAreaInsetTop
                                                                        startTouches
                                                                    )
                                                                    matchId
                                                                    match
                                                                )
                                                                loggedIn.games
                                                    }

                                                Nothing ->
                                                    loggedIn
                                    , Command.none
                                    )
                                )
                                { model
                                    | drag =
                                        Dragging
                                            { horizontalStart = horizontalStart
                                            , touches = startTouches
                                            , target = target
                                            }
                                    , dragPrevious = model.drag
                                }

                        Nothing ->
                            ( model, Command.none )

        TouchEnd timeStamp ->
            handleTouchEnd (Duration.addTo model.startupData.timeOrigin timeStamp) model

        TouchCancel timeStamp ->
            handleTouchEnd (Duration.addTo model.startupData.timeOrigin timeStamp) model

        ChannelSidebarAnimated elapsedTime ->
            case model.loginStatus of
                LoggedIn loggedIn ->
                    case loggedIn.sidebarMode of
                        ChannelSidebarDragging _ ->
                            ( model, Command.none )

                        ChannelSidebarNotDragging { offset } ->
                            let
                                target : Float
                                target =
                                    channelSidebarTarget model.route

                                step : Float
                                step =
                                    Quantity.unwrap (Quantity.for elapsedTime sidebarSpeed)

                                offset2 : Float
                                offset2 =
                                    if offset < target then
                                        min target (offset + step)

                                    else
                                        max target (offset - step)
                            in
                            ( { model
                                | loginStatus =
                                    { loggedIn | sidebarMode = ChannelSidebarNotDragging { offset = offset2 } }
                                        |> LoggedIn
                              }
                            , if target > 1 then
                                -- The conversation view's text input is going off screen,
                                -- so let go of the keyboard it's holding open
                                Dom.blur Pages.Guild.channelTextInputId |> Task.attempt (\_ -> RemoveFocus)

                              else
                                Command.none
                            )

                NotLoggedIn _ ->
                    ( model, Command.none )

        SetScrollToBottom ->
            ( model, Command.none )

        PressedChannelHeaderBackButton ->
            startClosingChannelSidebar model

        PressedShowMembers ->
            setShowMembers ShowChannelSettings model

        PressedHideMembers ->
            setShowMembers HideChannelSettings model

        UserScrolled guildOrDmId threadRoute scrollPosition ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    case scrollPosition of
                        ScrolledToTop ->
                            let
                                local : LocalState
                                local =
                                    Local.model loggedIn.localState
                            in
                            FrontendExtra.handleLocalChange
                                model.time
                                (loadOlderMessages guildOrDmId threadRoute local)
                                { loggedIn | channelScrollPosition = scrollPosition }
                                Command.none

                        ScrolledToBottom ->
                            -- Scrolling to the bottom yourself means you've seen the messages
                            -- that arrived while the conversation stayed where it was
                            ( { loggedIn | channelScrollPosition = scrollPosition, newMessagesWhileNotScrolledToBottom = 0 }
                            , Command.none
                            )

                        ScrolledToMiddle ->
                            ( { loggedIn | channelScrollPosition = scrollPosition }, Command.none )
                )
                model

        PressedBody ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    ( MessageMenu.close
                        model
                        { loggedIn | showEmojiSelector = EmojiSelectorHidden }
                    , Command.none
                    )
                )
                model

        MessageMenu_PressedDeleteMessage guildOrDmId messageIndex ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    FrontendExtra.handleLocalChange
                        model.time
                        (Just (Local_DeleteMessage guildOrDmId messageIndex))
                        (MessageMenu.close model loggedIn)
                        Command.none
                )
                model

        MessageMenu_PressedMarkAsUnread guildOrDmId threadRoute ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    FrontendExtra.handleLocalChange
                        model.time
                        (Local_SetLastViewed
                            guildOrDmId
                            (case threadRoute of
                                ViewThreadWithMessage threadMessageId messageId ->
                                    ViewThreadWithMessage threadMessageId (messageBefore messageId)

                                NoThreadWithMessage messageId ->
                                    NoThreadWithMessage (messageBefore messageId)
                            )
                            |> Just
                        )
                        (MessageMenu.close model loggedIn)
                        Command.none
                )
                model

        MessageMenu_PressedAddCustomEmojisToUser customEmojiIds ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    FrontendExtra.handleLocalChange
                        model.time
                        (Just (Local_AddCustomEmojisToUser customEmojiIds))
                        (MessageMenu.close model loggedIn)
                        Command.none
                )
                model

        MessageMenu_PressedOpenDm otherUserId ->
            case model.loginStatus of
                LoggedIn loggedIn ->
                    FrontendExtra.routePush
                        model
                        (Route.DmRoute
                            { channelId =
                                DmChannelId.fromUserIds
                                    otherUserId
                                    (Local.model loggedIn.localState).localUser.session.userId
                            , threadRoute = NoThreadWithFriends Nothing HideChannelSettings
                            , tab = Nothing
                            , channelsVisible = ChannelsHiddenOnMobile
                            }
                        )

                NotLoggedIn _ ->
                    ( model, Command.none )

        MessageMenu_PressedOpenDiscordDm currentUserId channelId ->
            case model.loginStatus of
                LoggedIn _ ->
                    FrontendExtra.routePush
                        model
                        (Route.DiscordDmRoute
                            { currentDiscordUserId = currentUserId
                            , channelId = channelId
                            , viewingMessage = Nothing
                            , showMembersTab = HideChannelSettings
                            , tab = Nothing
                            , channelsVisible = ChannelsHiddenOnMobile
                            }
                        )

                NotLoggedIn _ ->
                    ( model, Command.none )

        ScrolledToMessage ->
            ( model, Command.none )

        MessageMenu_PressedClose ->
            FrontendExtra.updateLoggedIn (\loggedIn -> ( MessageMenu.close model loggedIn, Command.none )) model

        MessageMenu_PressedContainer ->
            ( model, Command.none )

        PressedCancelMessageEdit guildOrDmId ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn | editMessage = SeqDict.remove guildOrDmId loggedIn.editMessage }
                    , Command.none
                    )
                )
                model

        CheckMessageAltPress startTime guildOrDmId threadRoute isThreadStarter maybeImageUrl maybeLinkUrl ->
            case model.drag of
                DragStart dragStart _ ->
                    if startTime == dragStart then
                        FrontendExtra.updateLoggedIn
                            (\loggedIn ->
                                ( handleAltPressedMessage
                                    guildOrDmId
                                    threadRoute
                                    isThreadStarter
                                    maybeImageUrl
                                    maybeLinkUrl
                                    Coord.origin
                                    loggedIn
                                    (Local.model loggedIn.localState)
                                    model
                                , Ports.hapticFeedback
                                )
                            )
                            model

                    else
                        ( model, Command.none )

                NoDrag ->
                    ( model, Command.none )

                Dragging _ ->
                    ( model, Command.none )

        MessageMenuAnimated elapsedTime ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn
                        | messageHover =
                            case loggedIn.messageHover of
                                NoMessageHover ->
                                    loggedIn.messageHover

                                MessageHover _ _ ->
                                    loggedIn.messageHover

                                MessageMenu messageMenu ->
                                    case messageMenu.mobileMode of
                                        MessageMenuOpening { offset, targetOffset } ->
                                            let
                                                delta : Quantity Float CssPixels
                                                delta =
                                                    Quantity.for elapsedTime MessageMenu.messageMenuSpeed

                                                offsetNext : Quantity Float CssPixels
                                                offsetNext =
                                                    if offset |> Quantity.lessThan targetOffset then
                                                        offset |> Quantity.plus delta

                                                    else
                                                        offset |> Quantity.minus delta
                                            in
                                            { messageMenu
                                                | mobileMode =
                                                    if
                                                        (offsetNext |> Quantity.lessThan targetOffset)
                                                            == (offset |> Quantity.lessThan targetOffset)
                                                    then
                                                        MessageMenuOpening { offset = offsetNext, targetOffset = targetOffset }

                                                    else
                                                        MessageMenuFixed targetOffset
                                            }
                                                |> MessageMenu

                                        MessageMenuClosing offset maybeEdit ->
                                            let
                                                offsetNext : Quantity Float CssPixels
                                                offsetNext =
                                                    offset
                                                        |> Quantity.minus (Quantity.for elapsedTime MessageMenu.messageMenuSpeed)
                                            in
                                            if offsetNext |> Quantity.lessThanOrEqualToZero then
                                                NoMessageHover

                                            else
                                                { messageMenu | mobileMode = MessageMenuClosing offsetNext maybeEdit }
                                                    |> MessageMenu

                                        MessageMenuDragging _ ->
                                            MessageMenu messageMenu

                                        MessageMenuFixed _ ->
                                            MessageMenu messageMenu
                      }
                    , Command.none
                    )
                )
                model

        PressedShowUserOption ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn
                        | userOptions =
                            Just
                                (UserOptions.init
                                    (Local.model loggedIn.localState).localUser.user.domainWhitelist
                                )
                      }
                    , Command.none
                    )
                )
                model

        PressedCloseUserOptions ->
            FrontendExtra.updateLoggedIn
                (\loggedIn -> ( { loggedIn | userOptions = Nothing }, Command.none ))
                model

        PressedExpandContainer section ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    FrontendExtra.handleLocalChange
                        model.time
                        (if
                            SeqSet.member
                                section
                                (Local.model loggedIn.localState).localUser.session.expandedUserOptions
                         then
                            Local_CollapseUserOptionSection section |> Just

                         else
                            Local_ExpandUserOptionSection section |> Just
                        )
                        loggedIn
                        Command.none
                )
                model

        TwoFactorMsg twoFactorMsg ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    let
                        ( twoFactor2, cmd ) =
                            TwoFactorAuthentication.update twoFactorMsg loggedIn.twoFactor
                    in
                    ( { loggedIn | twoFactor = twoFactor2 }, Command.map TwoFactorToBackend TwoFactorMsg cmd )
                )
                model

        AiChatMsg aiChatMsg ->
            let
                ( aiChatModel2, aiChatCmd ) =
                    AiChat.update aiChatMsg model.aiChatModel
            in
            ( { model | aiChatModel = aiChatModel2 }
            , Command.map AiChatToBackend AiChatMsg aiChatCmd
            )

        GameMsg gameMsg ->
            case model.loginStatus of
                LoggedIn loggedIn ->
                    let
                        local =
                            Local.model loggedIn.localState
                    in
                    case FrontendExtra.currentGamesTab local model.route of
                        Just gamesTab ->
                            let
                                ( gameModel2, outMsgs ) =
                                    Game.update
                                        model.time
                                        model.windowSize
                                        local.localUser
                                        gamesTab.guildOrDmId
                                        gameMsg
                                        gamesTab.newMatchId
                                        (case gamesTab.maybeMatchId of
                                            Just matchId ->
                                                case SeqDict.get matchId gamesTab.channelGames of
                                                    Just matchData ->
                                                        Just ( matchId, matchData )

                                                    Nothing ->
                                                        Nothing

                                            Nothing ->
                                                Nothing
                                        )
                                        (SeqDict.get gamesTab.guildOrDmId loggedIn.games |> Maybe.withDefault Game.initModel)

                                ( loggedIn2, localChangeCmd ) =
                                    List.foldl
                                        (\outMsg ( accLoggedIn, accCmd ) ->
                                            case outMsg of
                                                Game.OutLocalChange change ->
                                                    FrontendExtra.handleLocalChange
                                                        model.time
                                                        (Just (Local_Game gamesTab.guildOrDmId change))
                                                        accLoggedIn
                                                        accCmd

                                                Game.SaveSheepGameQuestions questions ->
                                                    FrontendExtra.handleLocalChange
                                                        model.time
                                                        (Just (Local_SetSheepGameQuestions questions))
                                                        accLoggedIn
                                                        accCmd

                                                _ ->
                                                    ( accLoggedIn, accCmd )
                                        )
                                        ( { loggedIn
                                            | games =
                                                SeqDict.update gamesTab.guildOrDmId (\_ -> Just gameModel2) loggedIn.games
                                          }
                                        , Command.none
                                        )
                                        outMsgs

                                ( model2, effectCmd ) =
                                    handleGameOutMsgs outMsgs { model | loginStatus = LoggedIn loggedIn2 }
                            in
                            ( model2, Command.batch [ localChangeCmd, Command.batch (List.reverse effectCmd) ] )

                        Nothing ->
                            ( model, Command.none )

                NotLoggedIn _ ->
                    ( model, Command.none )

        UserNameEditableMsg editableMsg ->
            handleEditable
                editableMsg
                (\userOptions value -> { userOptions | name = value })
                (\value loggedIn -> FrontendExtra.handleLocalChange model.time (Just (Local_SetName value)) loggedIn Command.none)
                model

        OneFrameAfterDragEnd ->
            ( { model | dragPrevious = model.drag }, Command.none )

        GotFileHashName guildOrDmId fileStatusId result ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn
                        | filesToUpload =
                            SeqDict.updateIfExists
                                guildOrDmId
                                (NonemptyDict.updateIfExists fileStatusId (FileStatus.addFileHash result))
                                loggedIn.filesToUpload
                      }
                    , Command.none
                    )
                )
                model

        PressedDeleteAttachedFile guildOrDmId fileId ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    let
                        local =
                            Local.model loggedIn.localState

                        allUsers =
                            User.allUsers local.localUser
                    in
                    ( { loggedIn
                        | filesToUpload =
                            SeqDict.update
                                guildOrDmId
                                (\maybe ->
                                    case maybe of
                                        Just dict ->
                                            NonemptyDict.toSeqDict dict
                                                |> SeqDict.remove fileId
                                                |> NonemptyDict.fromSeqDict

                                        Nothing ->
                                            Nothing
                                )
                                loggedIn.filesToUpload
                        , drafts =
                            SeqDict.update
                                guildOrDmId
                                (\maybe ->
                                    case maybe of
                                        Just draft ->
                                            case
                                                RichText.fromNonemptyString local.localUser.timezone allUsers draft
                                                    |> RichText.removeAttachedFile (\a -> a == fileId)
                                            of
                                                Just richText ->
                                                    RichText.toString local.localUser.timezone False allUsers richText
                                                        |> String.Nonempty.fromString

                                                Nothing ->
                                                    Nothing

                                        Nothing ->
                                            Nothing
                                )
                                loggedIn.drafts
                      }
                    , Http.cancel (FileStatus.uploadTrackerId guildOrDmId fileId)
                    )
                )
                model

        EditMessage_PressedDeleteAttachedFile guildOrDmId fileId ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    let
                        local =
                            Local.model loggedIn.localState

                        allUsers =
                            User.allUsers local.localUser
                    in
                    ( case SeqDict.get guildOrDmId loggedIn.editMessage of
                        Just edit ->
                            { loggedIn
                                | editMessage =
                                    SeqDict.insert
                                        guildOrDmId
                                        { edit
                                            | text =
                                                case String.Nonempty.fromString edit.text of
                                                    Just nonempty ->
                                                        case
                                                            RichText.fromNonemptyString local.localUser.timezone allUsers nonempty
                                                                |> RichText.removeAttachedFile (\a -> a == fileId)
                                                        of
                                                            Just richText ->
                                                                RichText.toString local.localUser.timezone False allUsers richText

                                                            Nothing ->
                                                                edit.text

                                                    Nothing ->
                                                        edit.text
                                            , attachedFiles = SeqDict.remove fileId edit.attachedFiles
                                        }
                                        loggedIn.editMessage
                            }

                        Nothing ->
                            loggedIn
                    , Http.cancel (FileStatus.uploadTrackerId guildOrDmId fileId)
                    )
                )
                model

        EditMessage_SelectedFilesToAttach guildOrDmId file files ->
            FrontendExtra.editMessage_gotFiles guildOrDmId (Nonempty file files) model

        EditMessage_GotFileHashName guildOrDmId messageIndex fileId result ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn
                        | editMessage =
                            SeqDict.updateIfExists
                                guildOrDmId
                                (\edit ->
                                    if edit.messageIndex == messageIndex then
                                        { edit
                                            | attachedFiles =
                                                SeqDict.updateIfExists
                                                    fileId
                                                    (FileStatus.addFileHash result)
                                                    edit.attachedFiles
                                        }

                                    else
                                        edit
                                )
                                loggedIn.editMessage
                      }
                    , Command.none
                    )
                )
                model

        FileUploadProgress guildOrDmId fileId progress ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn
                        | filesToUpload =
                            SeqDict.updateIfExists
                                guildOrDmId
                                (NonemptyDict.updateIfExists
                                    fileId
                                    (\fileStatus ->
                                        case fileStatus of
                                            FileUploading fileName fileSize contentType isEncrypted ->
                                                FileUploading
                                                    fileName
                                                    (case progress of
                                                        Http.Sending progress2 ->
                                                            progress2

                                                        Http.Receiving { received } ->
                                                            { sent = received, size = fileSize.size }
                                                    )
                                                    contentType
                                                    isEncrypted

                                            FileUploaded _ ->
                                                fileStatus

                                            FileError _ _ _ _ _ ->
                                                fileStatus
                                    )
                                )
                                loggedIn.filesToUpload
                      }
                    , Command.none
                    )
                )
                model

        ImageViewerMsg imageViewerMsg ->
            ( { model | imageViewer = Maybe.andThen (ImageViewer.update model.windowSize imageViewerMsg) model.imageViewer }
            , Command.none
            )

        MessageViewMsg guildOrDmId threadRoute messageViewMsg ->
            case messageViewMsg of
                MessageView.MessageView_PressedSpoiler spoilerIndex ->
                    handleRevealSpoilers guildOrDmId threadRoute spoilerIndex model

                MessageView.MessageView_MouseEnteredMessage ->
                    handleMouseEnteredMessage guildOrDmId threadRoute model

                MessageView.MessageView_MouseExitedMessage ->
                    handleMouseExitedMessage guildOrDmId threadRoute model

                MessageView.MessageView_TouchStart timeStamp isThreadStarter maybeImageUrl maybeLinkUrl touches ->
                    touchStart
                        (Just ( guildOrDmId, threadRoute, isThreadStarter ))
                        maybeImageUrl
                        maybeLinkUrl
                        (Duration.addTo model.startupData.timeOrigin timeStamp)
                        touches
                        model

                MessageView.MessageView_AltPressedMessage isThreadStarter maybeImageUrl maybeLinkUrl clickedAt ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            ( handleAltPressedMessage
                                guildOrDmId
                                threadRoute
                                isThreadStarter
                                maybeImageUrl
                                maybeLinkUrl
                                clickedAt
                                loggedIn
                                (Local.model loggedIn.localState)
                                model
                            , Command.none
                            )
                        )
                        model

                MessageView.MessageView_PressedReactionEmoji_Remove emoji ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            FrontendExtra.handleLocalChange
                                model.time
                                (Local_RemoveReactionEmoji guildOrDmId threadRoute emoji |> Just)
                                loggedIn
                                Command.none
                        )
                        model

                MessageView.MessageView_PressedReactionEmoji_Add emoji ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            FrontendExtra.handleLocalChange
                                model.time
                                (Local_AddReactionEmoji guildOrDmId threadRoute emoji |> Just)
                                loggedIn
                                (Scroll.toBottomOfChannelIfAtBottom Pages.Guild.conversationContainerId SetScrollToBottom loggedIn.channelScrollPosition)
                        )
                        model

                MessageView.MessageView_PressedReplyLink ->
                    case model.loginStatus of
                        LoggedIn loggedIn ->
                            case guildOrDmId of
                                GuildOrDmId guildOrDmId2 ->
                                    case LocalState.guildOrDmIdToMessage guildOrDmId2 threadRoute (Local.model loggedIn.localState) of
                                        Just ( _, maybeRepliedTo ) ->
                                            case ( guildOrDmId2, maybeRepliedTo ) of
                                                ( GuildOrDmId_Guild { guildId, channelId }, ViewThreadWithMaybeMessage threadId (Just repliedTo) ) ->
                                                    FrontendExtra.routePush
                                                        model
                                                        (GuildRoute
                                                            guildId
                                                            (ChannelRoute
                                                                channelId
                                                                (ViewThreadWithFriends threadId (Just repliedTo) HideChannelSettings)
                                                                Nothing
                                                            )
                                                            ChannelsHiddenOnMobile
                                                        )

                                                ( GuildOrDmId_Guild { guildId, channelId }, NoThreadWithMaybeMessage (Just repliedTo) ) ->
                                                    FrontendExtra.routePush
                                                        model
                                                        (GuildRoute
                                                            guildId
                                                            (ChannelRoute
                                                                channelId
                                                                (NoThreadWithFriends (Just repliedTo) HideChannelSettings)
                                                                Nothing
                                                            )
                                                            ChannelsHiddenOnMobile
                                                        )

                                                ( GuildOrDmId_Dm { otherUserId }, ViewThreadWithMaybeMessage threadId (Just repliedTo) ) ->
                                                    FrontendExtra.routePush
                                                        model
                                                        (DmRoute
                                                            { channelId =
                                                                DmChannelId.fromUserIds
                                                                    (Local.model loggedIn.localState |> .localUser |> .session |> .userId)
                                                                    otherUserId
                                                            , threadRoute =
                                                                ViewThreadWithFriends threadId (Just repliedTo) HideChannelSettings
                                                            , tab = Nothing
                                                            , channelsVisible = ChannelsHiddenOnMobile
                                                            }
                                                        )

                                                ( GuildOrDmId_Dm { otherUserId }, NoThreadWithMaybeMessage (Just repliedTo) ) ->
                                                    FrontendExtra.routePush
                                                        model
                                                        (DmRoute
                                                            { channelId =
                                                                DmChannelId.fromUserIds
                                                                    (Local.model loggedIn.localState |> .localUser |> .session |> .userId)
                                                                    otherUserId
                                                            , threadRoute =
                                                                NoThreadWithFriends (Just repliedTo) HideChannelSettings
                                                            , tab = Nothing
                                                            , channelsVisible = ChannelsHiddenOnMobile
                                                            }
                                                        )

                                                _ ->
                                                    ( model, Command.none )

                                        _ ->
                                            ( model, Command.none )

                                DiscordGuildOrDmId guildOrDmId2 ->
                                    case LocalState.discordGuildOrDmIdToMessage guildOrDmId2 threadRoute (Local.model loggedIn.localState) of
                                        Just ( _, maybeRepliedTo ) ->
                                            case ( guildOrDmId2, maybeRepliedTo ) of
                                                ( DiscordGuildOrDmId_Guild { currentUserId, guildId, channelId }, ViewThreadWithMaybeMessage threadId (Just repliedTo) ) ->
                                                    FrontendExtra.routePush
                                                        model
                                                        ({ currentDiscordUserId = currentUserId
                                                         , guildId = guildId
                                                         , channelRoute =
                                                            DiscordChannel_ChannelRoute
                                                                channelId
                                                                (ViewThreadWithFriends threadId (Just repliedTo) HideChannelSettings)
                                                                Nothing
                                                         , channelsVisible = ChannelsHiddenOnMobile
                                                         }
                                                            |> DiscordGuildRoute
                                                        )

                                                ( DiscordGuildOrDmId_Guild { currentUserId, guildId, channelId }, NoThreadWithMaybeMessage (Just repliedTo) ) ->
                                                    FrontendExtra.routePush
                                                        model
                                                        ({ currentDiscordUserId = currentUserId
                                                         , guildId = guildId
                                                         , channelRoute =
                                                            DiscordChannel_ChannelRoute
                                                                channelId
                                                                (NoThreadWithFriends (Just repliedTo) HideChannelSettings)
                                                                Nothing
                                                         , channelsVisible = ChannelsHiddenOnMobile
                                                         }
                                                            |> DiscordGuildRoute
                                                        )

                                                ( DiscordGuildOrDmId_Dm { currentUserId, channelId }, NoThreadWithMaybeMessage (Just repliedTo) ) ->
                                                    FrontendExtra.routePush
                                                        model
                                                        (DiscordDmRoute
                                                            { currentDiscordUserId = currentUserId
                                                            , channelId = channelId
                                                            , viewingMessage = Just repliedTo
                                                            , showMembersTab = HideChannelSettings
                                                            , tab = Nothing
                                                            , channelsVisible = ChannelsHiddenOnMobile
                                                            }
                                                        )

                                                _ ->
                                                    ( model, Command.none )

                                        _ ->
                                            ( model, Command.none )

                        NotLoggedIn _ ->
                            ( model, Command.none )

                MessageView.MessageViewMsg_PressedShowReactionEmojiSelector ->
                    showReactionEmojiSelector guildOrDmId threadRoute model

                MessageView.MessageViewMsg_PressedEditMessage ->
                    pressedEditMessage guildOrDmId threadRoute model

                MessageView.MessageViewMsg_PressedReply ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn -> pressedReply guildOrDmId threadRoute loggedIn model)
                        model

                MessageView.MessageViewMsg_PressedShowFullMenu isThreadStarter clickedAt ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            let
                                local : LocalState
                                local =
                                    Local.model loggedIn.localState
                            in
                            ( { loggedIn
                                | messageHover =
                                    MessageMenu
                                        { position = clickedAt
                                        , guildOrDmId = guildOrDmId
                                        , threadRoute = threadRoute
                                        , isThreadStarter = isThreadStarter
                                        , imageUrl = Nothing
                                        , linkUrl = Nothing
                                        , mobileMode =
                                            MessageMenuOpening
                                                { offset = Quantity.zero
                                                , targetOffset =
                                                    MessageMenu.mobileMenuOpeningOffset
                                                        guildOrDmId
                                                        threadRoute
                                                        local
                                                        model
                                                }
                                        }
                              }
                            , Command.none
                            )
                        )
                        model

                MessageView.MessageView_PressedViewThreadLink ->
                    case ( guildOrDmId, threadRoute ) of
                        ( GuildOrDmId (GuildOrDmId_Guild { guildId, channelId }), NoThreadWithMessage messageId ) ->
                            FrontendExtra.routePush
                                model
                                (GuildRoute
                                    guildId
                                    (ChannelRoute channelId (ViewThreadWithFriends messageId Nothing HideChannelSettings) Nothing)
                                    ChannelsHiddenOnMobile
                                )

                        ( GuildOrDmId (GuildOrDmId_Dm { otherUserId }), NoThreadWithMessage messageId ) ->
                            case model.loginStatus of
                                LoggedIn loggedIn ->
                                    { channelId =
                                        DmChannelId.fromUserIds
                                            (Local.model loggedIn.localState |> .localUser |> .session |> .userId)
                                            otherUserId
                                    , threadRoute = ViewThreadWithFriends messageId Nothing HideChannelSettings
                                    , tab = Nothing
                                    , channelsVisible = ChannelsHiddenOnMobile
                                    }
                                        |> DmRoute
                                        |> FrontendExtra.routePush model

                                NotLoggedIn _ ->
                                    ( model, Command.none )

                        ( DiscordGuildOrDmId (DiscordGuildOrDmId_Guild { currentUserId, guildId, channelId }), NoThreadWithMessage messageId ) ->
                            FrontendExtra.routePush
                                model
                                ({ currentDiscordUserId = currentUserId
                                 , guildId = guildId
                                 , channelRoute =
                                    DiscordChannel_ChannelRoute
                                        channelId
                                        (ViewThreadWithFriends messageId Nothing HideChannelSettings)
                                        Nothing
                                 , channelsVisible = ChannelsHiddenOnMobile
                                 }
                                    |> DiscordGuildRoute
                                )

                        ( DiscordGuildOrDmId (DiscordGuildOrDmId_Dm { currentUserId, channelId }), NoThreadWithMessage _ ) ->
                            FrontendExtra.routePush
                                model
                                (DiscordDmRoute
                                    { currentDiscordUserId = currentUserId
                                    , channelId = channelId
                                    , viewingMessage = Nothing
                                    , showMembersTab = HideChannelSettings
                                    , tab = Nothing
                                    , channelsVisible = ChannelsHiddenOnMobile
                                    }
                                )

                        _ ->
                            ( model, Command.none )

                MessageView.MessageView_PressedNonWhitelistLink url ->
                    handlePressedNonWhitelistLink url model

                MessageView.MessageView_PressedImage { imageId, fileUrl, imageSize, position, displayWidth } ->
                    case Route.toChannelHeaderTab model.route of
                        Just ChannelHeaderTab_Draw ->
                            let
                                displayHeight : Float
                                displayHeight =
                                    if Coord.xRaw imageSize > 0 then
                                        displayWidth * toFloat (Coord.yRaw imageSize) / toFloat (Coord.xRaw imageSize)

                                    else
                                        displayWidth
                            in
                            selectDrawingAnchor
                                guildOrDmId
                                (Drawing.MessageAnchor
                                    threadRoute
                                    (case imageId of
                                        RichText.PressedAttachedFileImage fileId ->
                                            Drawing.ImageAttachmentAnchor fileId

                                        RichText.PressedEmbedImage embedIndex ->
                                            Drawing.EmbedImageAnchor embedIndex
                                    )
                                )
                                position
                                ( displayWidth / 2, displayHeight / 2 )
                                -- Strokes on images are stored in the image's full resolution
                                -- coordinates so they stay aligned when the image is scaled
                                -- down to fit smaller screens
                                (if displayWidth > 0 then
                                    toFloat (Coord.xRaw imageSize) / displayWidth

                                 else
                                    1
                                )
                                model

                        _ ->
                            ( { model | imageViewer = Just (ImageViewer.init { url = fileUrl, imageSize = imageSize }) }
                            , Command.none
                            )

                MessageView.MessageView_NoOp ->
                    ( model, Command.none )

                MessageView.MessageViewMsg_PressedReactionEmoji emoji ->
                    FrontendExtra.updateLoggedIn (toggleReactionEmoji emoji guildOrDmId threadRoute model) model

                MessageView.MessageViewMsg_PressedCallStartedCard ->
                    case model.route of
                        DmRoute dmRoute ->
                            FrontendExtra.routePush model (DmRoute { dmRoute | tab = Just ChannelHeaderTab_VoiceChat })

                        HomePageRoute ->
                            ( model, Command.none )

                        AdminRoute _ ->
                            ( model, Command.none )

                        NewGuildRoute ->
                            ( model, Command.none )

                        GuildRoute guildId channelRoute channelsVisible ->
                            case channelRoute of
                                ChannelRoute channelId (NoThreadWithFriends a b) _ ->
                                    FrontendExtra.routePush
                                        model
                                        (GuildRoute
                                            guildId
                                            (ChannelRoute
                                                channelId
                                                (NoThreadWithFriends a b)
                                                (Just ChannelHeaderTab_VoiceChat)
                                            )
                                            channelsVisible
                                        )

                                ChannelRoute _ (ViewThreadWithFriends _ _ _) _ ->
                                    ( model, Command.none )

                                NewChannelRoute ->
                                    ( model, Command.none )

                                GuildSettingsRoute ->
                                    ( model, Command.none )

                                JoinRoute _ ->
                                    ( model, Command.none )

                        DiscordGuildRoute _ ->
                            ( model, Command.none )

                        DiscordDmRoute _ ->
                            ( model, Command.none )

                        AiChatRoute ->
                            ( model, Command.none )

                        SlackOAuthRedirect _ ->
                            ( model, Command.none )

                        TextEditorRoute ->
                            ( model, Command.none )

                        LinkDiscord _ ->
                            ( model, Command.none )

                        PublicGoMatchRoute _ ->
                            ( model, Command.none )

                MessageView.MessageViewMsg_PressedGameStartedCard ->
                    case threadRoute of
                        NoThreadWithMessage messageId ->
                            let
                                newRoute : Route
                                newRoute =
                                    Route.setChannelHeaderTab
                                        (Just (ChannelHeaderTab_Games (Just messageId)))
                                        model.route
                            in
                            if newRoute == model.route then
                                ( model, Command.none )

                            else
                                FrontendExtra.routePush model newRoute

                        ViewThreadWithMessage _ _ ->
                            ( model, Command.none )

                MessageView.MessageView_PressedUserIconAnchor elementPosition anchorHalfSize ->
                    case Route.toChannelHeaderTab model.route of
                        Just ChannelHeaderTab_Draw ->
                            selectDrawingAnchor
                                guildOrDmId
                                (Drawing.MessageAnchor threadRoute Drawing.UserIconAnchor)
                                elementPosition
                                anchorHalfSize
                                1
                                model

                        _ ->
                            ( model, Command.none )

                MessageView.MessageView_PressedTimestamp elementPosition anchorHalfSize ->
                    case Route.toChannelHeaderTab model.route of
                        Just ChannelHeaderTab_Draw ->
                            selectDrawingAnchor
                                guildOrDmId
                                (Drawing.MessageAnchor threadRoute Drawing.TimestampAnchor)
                                elementPosition
                                anchorHalfSize
                                1
                                model

                        _ ->
                            ( model, Command.none )

                MessageView.MessageView_PressedDateDivider date elementPosition anchorHalfSize ->
                    case Route.toChannelHeaderTab model.route of
                        Just ChannelHeaderTab_Draw ->
                            selectDrawingAnchor
                                guildOrDmId
                                (Drawing.DateDividerAnchor (Id.threadRouteWithoutMessage threadRoute) date)
                                elementPosition
                                anchorHalfSize
                                1
                                model

                        _ ->
                            ( model, Command.none )

                MessageView.MessageView_PressedCardAnchor elementPosition anchorHalfSize ->
                    case Route.toChannelHeaderTab model.route of
                        Just ChannelHeaderTab_Draw ->
                            selectDrawingAnchor
                                guildOrDmId
                                (Drawing.MessageAnchor threadRoute Drawing.CardAnchor)
                                elementPosition
                                anchorHalfSize
                                1
                                model

                        _ ->
                            ( model, Command.none )

                MessageView.MessageView_PressedUserIconButton otherUserId ->
                    handlePressedUserIconButton otherUserId model

                MessageView.MessageView_PressedDiscordUserIconButton otherUserId ->
                    handlePressedDiscordUserIconButton otherUserId model

        GotRegisterPushSubscription result ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    FrontendExtra.handleLocalChange
                        model.time
                        (Local_RegisterPushSubscription model.time result |> Just)
                        loggedIn
                        Command.none
                )
                model

        SelectedNotificationMode notificationMode ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    FrontendExtra.handleLocalChange
                        model.time
                        (Local_SetNotificationMode notificationMode |> Just)
                        loggedIn
                        (case notificationMode of
                            NoNotifications ->
                                Command.none

                            NotifyWhenRunning ->
                                Ports.requestNotificationPermission

                            PushNotifications ->
                                -- Registering the push subscription asks for notification permission
                                -- itself, since Safari on iOS needs that to happen before it awaits
                                -- anything. Asking here too would race it for the same prompt.
                                Ports.registerPushSubscriptionToJs (Local.model loggedIn.localState).publicVapidKey
                        )
                )
                model

        SelectedEmailNotifications emailNotifications ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    FrontendExtra.handleLocalChange
                        model.time
                        (Local_SetEmailNotifications emailNotifications |> Just)
                        loggedIn
                        Command.none
                )
                model

        ProfilePictureEditorMsg imageEditorMsg ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    let
                        ( newImageEditor, cmd ) =
                            ImageEditor.update
                                ImageEditor.ChangeUserAvatarRequest
                                model.windowSize
                                imageEditorMsg
                                loggedIn.profilePictureEditor
                    in
                    ( { loggedIn | profilePictureEditor = newImageEditor }
                    , Command.map ProfilePictureEditorToBackend ProfilePictureEditorMsg cmd
                    )
                )
                model

        GuildIconEditorMsg guildId imageEditorMsg ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    let
                        currentEditor : ImageEditor.Model
                        currentEditor =
                            case loggedIn.guildIconEditor of
                                Just ( existingGuildId, editor ) ->
                                    if existingGuildId == guildId then
                                        editor

                                    else
                                        ImageEditor.init

                                Nothing ->
                                    ImageEditor.init

                        ( newImageEditor, cmd ) =
                            ImageEditor.update
                                (ImageEditor.ChangeGuildIconRequest guildId)
                                model.windowSize
                                imageEditorMsg
                                currentEditor
                    in
                    ( { loggedIn | guildIconEditor = Just ( guildId, newImageEditor ) }
                    , Command.map ProfilePictureEditorToBackend (GuildIconEditorMsg guildId) cmd
                    )
                )
                model

        PressedGuildNotificationLevel guildId notificationLevel ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    FrontendExtra.handleLocalChange
                        model.time
                        (Local_SetGuildNotificationLevel guildId notificationLevel |> Just)
                        loggedIn
                        Command.none
                )
                model

        PressedDiscordGuildNotificationLevel userId guildId notificationLevel ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    FrontendExtra.handleLocalChange
                        model.time
                        (Local_SetDiscordGuildNotificationLevel userId guildId notificationLevel |> Just)
                        loggedIn
                        Command.none
                )
                model

        GotStartupData startupData ->
            case startupData of
                Ok startupData2 ->
                    ( setDevicePixelRatio startupData2.devicePixelRatio { model | startupData = startupData2 }
                    , checkAppVersion False
                    )

                Err error ->
                    let
                        _ =
                            Debug.log "GotStartupData failed! (after loading)" error
                    in
                    ( model, Command.none )

        GotDevicePixelRatio devicePixelRatio ->
            ( setDevicePixelRatio devicePixelRatio model, Command.none )

        PressedViewAttachedFileInfo guildOrDmId fileId ->
            viewImageInfo guildOrDmId fileId model

        EditMessage_PressedViewAttachedFileInfo guildOrDmId fileId ->
            viewImageInfo guildOrDmId fileId model

        PressedCloseImageInfo ->
            FrontendExtra.updateLoggedIn
                (\loggedIn -> ( { loggedIn | showFileToUploadInfo = Nothing }, Command.none ))
                model

        PressedMemberListBack ->
            startClosingChannelSidebar model

        PressedExportChannel exportChannelId ->
            ( model, Lamdera.sendToBackend (ExportChannelRequest exportChannelId) )

        PressedAddPrivateKeyToAccount ->
            case
                X25519.privateKeyFromListInt
                    (List.indexedMap
                        (\index value -> (index + 1) * Time.posixToMillis model.time + value)
                        model.startupData.randomSeed
                    )
            of
                Just privateKey ->
                    let
                        startupData : Ports.StartupData
                        startupData =
                            model.startupData
                    in
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            FrontendExtra.handleLocalChange
                                model.time
                                (X25519.toPublicKey privateKey |> Local_SetPublicKey |> Just)
                                { loggedIn | showNewPrivateKey = Just privateKey }
                                Command.none
                        )
                        -- The words that went into this key are dropped so that generating a
                        -- second key cannot come out the same as the first.
                        { model
                            | startupData =
                                { startupData | randomSeed = List.drop 8 startupData.randomSeed }
                        }

                Nothing ->
                    ( model, Command.none )

        PressedCloseNewPrivateKey ->
            FrontendExtra.updateLoggedIn
                (\loggedIn -> ( { loggedIn | showNewPrivateKey = Nothing }, Command.none ))
                model

        PressedExpandE2eeSection otherUserId ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    let
                        isExpanded : Bool
                        isExpanded =
                            Pages.Guild.e2eeSectionIsExpanded
                                otherUserId
                                (Local.model loggedIn.localState)
                                loggedIn
                    in
                    ( { loggedIn
                        | e2eeSectionsExpanded =
                            SeqDict.insert otherUserId (not isExpanded) loggedIn.e2eeSectionsExpanded
                      }
                    , Command.none
                    )
                )
                model

        PressedE2eeRisksAccepted isChecked ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    FrontendExtra.handleLocalChange
                        model.time
                        (Local_SetE2eeRisksAccepted isChecked |> Just)
                        loggedIn
                        Command.none
                )
                model

        PressedEnableE2ee otherUserId ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    FrontendExtra.handleLocalChange
                        model.time
                        (Local_RequestE2ee { otherUserId = otherUserId } |> Just)
                        loggedIn
                        Command.none
                )
                model

        PressedCancelE2eeRequest otherUserId ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    FrontendExtra.handleLocalChange
                        model.time
                        (Local_CancelE2eeRequest { otherUserId = otherUserId } |> Just)
                        loggedIn
                        Command.none
                )
                model

        TypedPrivateKey otherUserId text ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    let
                        trimmed : String
                        trimmed =
                            String.trim text
                    in
                    if String.endsWith "=" trimmed then
                        let
                            result : Result String (Command FrontendOnly ToBackend FrontendMsg_)
                            result =
                                case User.privateKeyForAccount trimmed (Local.model loggedIn.localState).localUser.user of
                                    Ok privateKey ->
                                        case storeSharedSecret otherUserId privateKey loggedIn of
                                            Ok command ->
                                                (command :: storeRemainingSharedSecrets otherUserId privateKey loggedIn)
                                                    |> Command.batch
                                                    |> Ok

                                            Err error ->
                                                Err error

                                    Err error ->
                                        Err error
                        in
                        case result of
                            Ok command ->
                                ( { loggedIn | e2eeError = Nothing, e2eePrivateKeyText = "" }, command )

                            Err error ->
                                ( { loggedIn | e2eeError = Just error, e2eePrivateKeyText = text }, Command.none )

                    else
                        ( { loggedIn | e2eeError = Nothing, e2eePrivateKeyText = text }, Command.none )
                )
                model

        EncryptionFromJs result ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    case result of
                        Ok (Encryption.FromJs_SharedSecretStored otherUserId) ->
                            let
                                loggedIn2 : LoggedIn2
                                loggedIn2 =
                                    { loggedIn
                                        | e2eeKeysOnThisDevice =
                                            SeqSet.insert otherUserId loggedIn.e2eeKeysOnThisDevice
                                    }

                                local : LocalState
                                local =
                                    Local.model loggedIn2.localState
                            in
                            if LocalState.dmE2eeRequestedByOtherUser otherUserId local || otherUserId == local.localUser.session.userId then
                                FrontendExtra.handleLocalChange
                                    model.time
                                    (Local_AcceptE2ee { otherUserId = otherUserId } model.time |> Just)
                                    loggedIn2
                                    Command.none

                            else
                                ( loggedIn2, Command.none )

                        Ok (Encryption.FromJs_SharedSecretFailed _ error) ->
                            ( { loggedIn | e2eeError = Just error }, Command.none )

                        Ok (Encryption.FromJs_MessageEncrypted requestId bytesHash cipherText) ->
                            case SeqDict.get requestId loggedIn.pendingEncryptedMessages of
                                Just pending ->
                                    let
                                        draft : ( AnyGuildOrDmId, ThreadRoute )
                                        draft =
                                            ( GuildOrDmId (GuildOrDmId_Dm { otherUserId = pending.otherUserId })
                                            , Id.threadRouteWithoutMaybeMessage pending.threadRoute
                                            )
                                    in
                                    FrontendExtra.handleLocalChange
                                        model.time
                                        (Local_SendEncryptedMessage
                                            model.time
                                            { otherUserId = pending.otherUserId }
                                            cipherText
                                            pending.threadRoute
                                            pending.attachedFiles
                                            |> Just
                                        )
                                        { loggedIn
                                            | pendingEncryptedMessages =
                                                SeqDict.remove requestId loggedIn.pendingEncryptedMessages
                                            , drafts = SeqDict.remove draft loggedIn.drafts
                                            , replyTo = SeqDict.remove draft loggedIn.replyTo
                                            , filesToUpload = SeqDict.remove draft loggedIn.filesToUpload
                                            , decryptedMessages =
                                                SeqDict.insert bytesHash (Ok pending.contentAndEmbeds) loggedIn.decryptedMessages
                                        }
                                        (Scroll.toBottomOfChannel
                                            Pages.Guild.conversationContainerId
                                            SetScrollToBottom
                                        )

                                Nothing ->
                                    ( loggedIn, Command.none )

                        Ok (Encryption.FromJs_MessageEncryptFailed requestId error) ->
                            -- The draft is deliberately left where it is, so that a
                            -- message that could not be encrypted is not also lost.
                            ( { loggedIn
                                | e2eeError = Just error
                                , pendingEncryptedMessages =
                                    SeqDict.remove requestId loggedIn.pendingEncryptedMessages
                              }
                            , Command.none
                            )

                        Ok (Encryption.FromJs_MessageDecrypted requestId bytesHash contentAndEmbeds) ->
                            FrontendExtra.handleDecryptedMessage requestId bytesHash (Ok contentAndEmbeds) model loggedIn

                        Ok (Encryption.FromJs_MessageDecryptFailed requestId bytesHash) ->
                            FrontendExtra.handleDecryptedMessage requestId bytesHash (Err ()) model loggedIn

                        Err error ->
                            ( { loggedIn | e2eeError = Just error }, Command.none )
                )
                model

        PageHasFocusChanged hasFocus ->
            let
                ( model2, cmd ) =
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            FrontendExtra.handleLocalChange
                                model.time
                                (if hasFocus then
                                    Local_CurrentlyViewing
                                        { markMessagesAsViewed = False }
                                        (LocalState.routeToViewing (MyUi.isMobile model) model.route (Local.model loggedIn.localState))
                                        |> Just

                                 else
                                    Local_CurrentlyViewing
                                        { markMessagesAsViewed = False }
                                        StopViewingChannel
                                        |> Just
                                )
                                { loggedIn | messageHover = NoMessageHover }
                                (if hasFocus then
                                    Ports.closeNotifications

                                 else
                                    Command.none
                                )
                        )
                        { model | pageHasFocus = hasFocus }
            in
            ( model2
            , Command.batch
                [ cmd
                , if hasFocus then
                    checkAppVersion True

                  else
                    Command.none
                ]
            )

        GotServiceWorkerMessage url ->
            case Url.fromString url of
                Just url2 ->
                    FrontendExtra.routePush model (Route.decode url2)

                Nothing ->
                    ( model, Command.none )

        VisualViewportResized _ ->
            ( model, Command.none )

        TextEditorMsg textEditorMsg ->
            case model.loginStatus of
                LoggedIn loggedIn ->
                    let
                        local =
                            Local.model loggedIn.localState

                        ( textEditor, outMsg ) =
                            TextEditor.update
                                local.localUser.session.userId
                                textEditorMsg
                                loggedIn.textEditor
                                local.textEditor
                    in
                    case outMsg of
                        TextEditor.OutMsg_LocalChange localChange ->
                            let
                                ( loggedIn2, cmds ) =
                                    FrontendExtra.handleLocalChange
                                        model.time
                                        (Local_TextEditor localChange |> Just)
                                        { loggedIn | textEditor = textEditor }
                                        Command.none
                            in
                            ( { model | loginStatus = LoggedIn loggedIn2 }, cmds )

                        TextEditor.OutMsg_Back ->
                            FrontendExtra.routePush model Route.HomePageRoute

                        TextEditor.NoOutMsg ->
                            ( { model | loginStatus = LoggedIn { loggedIn | textEditor = textEditor } }, Command.none )

                NotLoggedIn _ ->
                    ( model, Command.none )

        PressedDiscordAcknowledgment checked ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    FrontendExtra.handleLocalChange
                        model.time
                        (Just (Local_LinkDiscordAcknowledgementIsChecked checked))
                        loggedIn
                        Command.none
                )
                model

        PressedReloadDiscordUser discordUserId ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    FrontendExtra.handleLocalChange
                        model.time
                        (Local_StartReloadingDiscordUser model.time discordUserId |> Just)
                        loggedIn
                        Command.none
                )
                model

        PressedUnlinkDiscordUser discordUserId ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    FrontendExtra.handleLocalChange
                        model.time
                        (Local_UnlinkDiscordUser discordUserId |> Just)
                        loggedIn
                        Command.none
                )
                model

        PressedDiscordGuildMemberLabel data ->
            case model.loginStatus of
                LoggedIn loggedIn ->
                    let
                        local : LocalState
                        local =
                            Local.model loggedIn.localState
                    in
                    case
                        List.Extra.find
                            (\( _, channel ) ->
                                NonemptySet.unorderedEquals
                                    (NonemptySet.fromNonemptyList (Nonempty data.currentUserId [ data.otherUserId ]))
                                    (NonemptySet.fromNonemptyList (NonemptyDict.keys channel.members))
                            )
                            (SeqDict.toList local.discordDmChannels)
                    of
                        Just ( channelId, _ ) ->
                            FrontendExtra.routePush
                                model
                                (DiscordDmRoute
                                    { currentDiscordUserId = data.currentUserId
                                    , channelId = channelId
                                    , viewingMessage = Nothing
                                    , showMembersTab = HideChannelSettings
                                    , tab = Nothing
                                    , channelsVisible = ChannelsHiddenOnMobile
                                    }
                                )

                        Nothing ->
                            ( model, Command.none )

                NotLoggedIn _ ->
                    ( model, Command.none )

        TypedDiscordLinkBookmarklet ->
            ( model, Command.none )

        GotVersionNumber reloadOnNewVersion result ->
            case ( result, model.versionNumber, reloadOnNewVersion ) of
                ( Ok version, Just previousVersion, True ) ->
                    if version == previousVersion then
                        ( model, Command.none )

                    else
                        ( model, BrowserNavigation.reload )

                ( Ok version, _, _ ) ->
                    ( { model | versionNumber = Just version }, Command.none )

                ( Err _, _, _ ) ->
                    ( model, Command.none )

        PressedCloseExternalLinkWarning ->
            FrontendExtra.updateLoggedIn
                (\loggedIn -> ( { loggedIn | externalLinkWarning = Nothing }, Command.none ))
                model

        PressedAddDomainToWhitelist isChecked ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    case loggedIn.externalLinkWarning of
                        Just url ->
                            FrontendExtra.handleLocalChange
                                model.time
                                (Just (Local_SetDomainWhitelist isChecked (RichText.urlToDomain url)))
                                loggedIn
                                Command.none

                        Nothing ->
                            ( loggedIn, Command.none )
                )
                model

        TypedDomainWhitelist newText ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    case loggedIn.userOptions of
                        Just userOptions ->
                            ( { loggedIn
                                | userOptions =
                                    Just { userOptions | domainWhitelistInput = newText }
                              }
                            , Command.none
                            )

                        Nothing ->
                            ( loggedIn, Command.none )
                )
                model

        PressedSelectNewColor ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    case loggedIn.userOptions of
                        Just userOptions ->
                            ( { loggedIn
                                | userOptions =
                                    Just
                                        { userOptions
                                            | color =
                                                (Local.model loggedIn.localState).localUser.user.color
                                                    |> UserColor.startPicking
                                                    |> Just
                                        }
                              }
                            , Command.none
                            )

                        Nothing ->
                            ( loggedIn, Command.none )
                )
                model

        SelectedUserColor selection ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    case loggedIn.userOptions of
                        Just userOptions ->
                            ( { loggedIn | userOptions = Just { userOptions | color = Just selection } }
                            , Command.none
                            )

                        Nothing ->
                            ( loggedIn, Command.none )
                )
                model

        PressedSubmitUserColor ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    case loggedIn.userOptions of
                        Just userOptions ->
                            -- Saving is the end of picking, so the grid goes away again.
                            FrontendExtra.handleLocalChange
                                model.time
                                (Maybe.map (\selection -> Local_SetUserColor (UserColor.picked selection)) userOptions.color)
                                { loggedIn | userOptions = Just { userOptions | color = Nothing } }
                                Command.none

                        Nothing ->
                            ( loggedIn, Command.none )
                )
                model

        PressedResetUserColor ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    case loggedIn.userOptions of
                        Just userOptions ->
                            ( { loggedIn | userOptions = Just { userOptions | color = Nothing } }
                            , Command.none
                            )

                        Nothing ->
                            ( loggedIn, Command.none )
                )
                model

        PressedSaveDomainWhitelist ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    case loggedIn.userOptions of
                        Just userOptions ->
                            let
                                oldDomains : SeqSet RichText.Domain
                                oldDomains =
                                    (Local.model loggedIn.localState).localUser.user.domainWhitelist

                                newDomains : SeqSet RichText.Domain
                                newDomains =
                                    parseDomainWhitelistInput userOptions.domainWhitelistInput
                            in
                            List.foldl
                                (\domain ( l, cmds ) ->
                                    FrontendExtra.handleLocalChange
                                        model.time
                                        (Just (Local_SetDomainWhitelist True domain))
                                        l
                                        cmds
                                )
                                ( loggedIn, Command.none )
                                (SeqSet.toList (SeqSet.diff newDomains oldDomains))
                                |> (\acc ->
                                        List.foldl
                                            (\domain ( l, cmds ) ->
                                                FrontendExtra.handleLocalChange
                                                    model.time
                                                    (Just (Local_SetDomainWhitelist False domain))
                                                    l
                                                    cmds
                                            )
                                            acc
                                            (SeqSet.toList (SeqSet.diff oldDomains newDomains))
                                   )
                                |> Tuple.mapFirst
                                    (\l ->
                                        { l
                                            | userOptions =
                                                Maybe.map
                                                    (\uo ->
                                                        { uo
                                                            | domainWhitelistInput =
                                                                UserOptions.domainWhitelistToString
                                                                    (Local.model l.localState).localUser.user.domainWhitelist
                                                        }
                                                    )
                                                    l.userOptions
                                        }
                                    )

                        Nothing ->
                            ( loggedIn, Command.none )
                )
                model

        PressedResetDomainWhitelist ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    case loggedIn.userOptions of
                        Just userOptions ->
                            ( { loggedIn
                                | userOptions =
                                    Just
                                        { userOptions
                                            | domainWhitelistInput =
                                                UserOptions.domainWhitelistToString
                                                    (Local.model loggedIn.localState).localUser.user.domainWhitelist
                                        }
                              }
                            , Command.none
                            )

                        Nothing ->
                            ( loggedIn, Command.none )
                )
                model

        PressedContinueToSite ->
            FrontendExtra.updateLoggedIn
                (\loggedIn -> ( { loggedIn | externalLinkWarning = Nothing }, Command.none ))
                model

        EditMessage_MessageInputMsg guildOrDmId threadRoute messageInputMsg ->
            case messageInputMsg of
                MessageInput.PressedTextInput ->
                    FrontendExtra.handlePressedTextInput model

                MessageInput.TypedMessage text ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            case SeqDict.get ( guildOrDmId, threadRoute ) loggedIn.editMessage of
                                Just edit ->
                                    case MessageInput.largePastedText edit.text text of
                                        Just largePaste ->
                                            FrontendExtra.editMessage_gotPastedText
                                                ( guildOrDmId, threadRoute )
                                                largePaste
                                                loggedIn

                                        Nothing ->
                                            let
                                                oldTypingDebouncer : Bool
                                                oldTypingDebouncer =
                                                    loggedIn.typingDebouncer

                                                loggedIn2 : LoggedIn2
                                                loggedIn2 =
                                                    { loggedIn
                                                        | editMessage =
                                                            SeqDict.insert
                                                                ( guildOrDmId, threadRoute )
                                                                { edit | text = text }
                                                                loggedIn.editMessage
                                                        , typingDebouncer = False
                                                        , typedTextCounter = loggedIn.typedTextCounter + 1
                                                    }
                                            in
                                            FrontendExtra.handleLocalChange
                                                model.time
                                                (if oldTypingDebouncer then
                                                    --Local_MemberEditTyping model.time guildOrDmId edit.messageIndex |> Just
                                                    Local_MemberEditTyping
                                                        model.time
                                                        guildOrDmId
                                                        (case threadRoute of
                                                            ViewThread threadId ->
                                                                ViewThreadWithMessage threadId (Id.changeType edit.messageIndex)

                                                            NoThread ->
                                                                NoThreadWithMessage edit.messageIndex
                                                        )
                                                        |> Just

                                                 else
                                                    Nothing
                                                )
                                                { loggedIn2
                                                    | messageHover =
                                                        case loggedIn2.messageHover of
                                                            NoMessageHover ->
                                                                loggedIn2.messageHover

                                                            MessageHover _ _ ->
                                                                loggedIn2.messageHover

                                                            MessageMenu extraOptions ->
                                                                { extraOptions
                                                                    | mobileMode =
                                                                        MessageMenu.mobileMenuMaxHeight
                                                                            extraOptions
                                                                            (Local.model loggedIn2.localState)
                                                                            model
                                                                            |> MessageMenuFixed
                                                                }
                                                                    |> MessageMenu
                                                }
                                                (Command.batch
                                                    [ Process.sleep (Duration.seconds 1) |> Task.perform (\() -> DebouncedTyping)
                                                    , removePartialStickers loggedIn2.textInputFocus MessageMenu.editMessageTextInputId text
                                                    ]
                                                )

                                Nothing ->
                                    ( loggedIn, Command.none )
                        )
                        model

                MessageInput.PressedSendMessage { charsLeft } ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            case SeqDict.get ( guildOrDmId, threadRoute ) loggedIn.editMessage of
                                Just edit ->
                                    if charsLeft < 0 || FileStatus.hasUploadingFile edit.attachedFiles then
                                        ( loggedIn, Command.none )

                                    else
                                        let
                                            local : LocalState
                                            local =
                                                Local.model loggedIn.localState
                                        in
                                        FrontendExtra.handleLocalChange
                                            model.time
                                            (case guildOrDmId of
                                                GuildOrDmId guildOrDmId2 ->
                                                    case
                                                        ( String.Nonempty.fromString edit.text
                                                        , LocalState.guildOrDmIdToMessage
                                                            guildOrDmId2
                                                            (Id.threadRouteWithMessage edit.messageIndex threadRoute)
                                                            local
                                                        )
                                                    of
                                                        ( Just nonempty, Just ( message, _ ) ) ->
                                                            let
                                                                richText : Nonempty (RichText (Id UserId))
                                                                richText =
                                                                    RichText.fromNonemptyString
                                                                        local.localUser.timezone
                                                                        (User.allUsers local.localUser)
                                                                        nonempty
                                                            in
                                                            if message.content == richText then
                                                                Nothing

                                                            else
                                                                Local_SendEditMessage
                                                                    model.time
                                                                    model.timezone
                                                                    guildOrDmId2
                                                                    (case threadRoute of
                                                                        ViewThread threadId ->
                                                                            ViewThreadWithMessage threadId (Id.changeType edit.messageIndex)

                                                                        NoThread ->
                                                                            NoThreadWithMessage edit.messageIndex
                                                                    )
                                                                    nonempty
                                                                    (FileStatus.onlyUploadedFiles edit.attachedFiles)
                                                                    |> Just

                                                        _ ->
                                                            Nothing

                                                DiscordGuildOrDmId guildOrDmId2 ->
                                                    case
                                                        ( String.Nonempty.fromString edit.text
                                                        , LocalState.discordGuildOrDmIdToMessage
                                                            guildOrDmId2
                                                            (Id.threadRouteWithMessage edit.messageIndex threadRoute)
                                                            local
                                                        )
                                                    of
                                                        ( Just nonempty, Just ( message, _ ) ) ->
                                                            let
                                                                richText : Nonempty (RichText (Discord.Id Discord.UserId))
                                                                richText =
                                                                    RichText.fromNonemptyString
                                                                        local.localUser.timezone
                                                                        (LinkedAndOtherDiscordUsers.allDiscordUsers local.localUser.discordUsers)
                                                                        nonempty
                                                            in
                                                            if message.content == richText then
                                                                Nothing

                                                            else
                                                                case guildOrDmId2 of
                                                                    DiscordGuildOrDmId_Guild { currentUserId, guildId, channelId } ->
                                                                        Local_Discord_SendEditGuildMessage
                                                                            model.time
                                                                            model.timezone
                                                                            currentUserId
                                                                            guildId
                                                                            channelId
                                                                            (case threadRoute of
                                                                                ViewThread threadId ->
                                                                                    ViewThreadWithMessage threadId (Id.changeType edit.messageIndex)

                                                                                NoThread ->
                                                                                    NoThreadWithMessage edit.messageIndex
                                                                            )
                                                                            nonempty
                                                                            |> Just

                                                                    DiscordGuildOrDmId_Dm data ->
                                                                        Local_Discord_SendEditDmMessage
                                                                            model.time
                                                                            model.timezone
                                                                            data
                                                                            edit.messageIndex
                                                                            nonempty
                                                                            |> Just

                                                        _ ->
                                                            Nothing
                                            )
                                            (if MyUi.isMobile model then
                                                MessageMenu.close model loggedIn

                                             else
                                                { loggedIn
                                                    | editMessage = SeqDict.remove ( guildOrDmId, threadRoute ) loggedIn.editMessage
                                                }
                                            )
                                            (FrontendExtra.setFocus model Pages.Guild.channelTextInputId)

                                Nothing ->
                                    ( loggedIn, Command.none )
                        )
                        model

                MessageInput.TypedArrowInDropdown index ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            ( { loggedIn
                                | textInputFocus =
                                    case loggedIn.textInputFocus of
                                        Just textInputFocus ->
                                            case
                                                FrontendExtra.pingUserNameSoFar
                                                    MessageMenu.editMessageTextInputId
                                                    textInputFocus.selection
                                                    guildOrDmId
                                                    threadRoute
                                                    loggedIn
                                            of
                                                Just nameSoFar ->
                                                    { textInputFocus
                                                        | dropdown =
                                                            MessageDropdown.pressedArrowInDropdown
                                                                (MyUi.isMobile model)
                                                                model.timezone
                                                                model.time
                                                                nameSoFar
                                                                guildOrDmId
                                                                index
                                                                textInputFocus.dropdown
                                                                model.emojiData
                                                                (Local.model loggedIn.localState)
                                                    }
                                                        |> Just

                                                Nothing ->
                                                    loggedIn.textInputFocus

                                        Nothing ->
                                            loggedIn.textInputFocus
                                , previousTextInputFocus = loggedIn.textInputFocus
                              }
                            , Command.none
                            )
                        )
                        model

                MessageInput.TypedArrowUpInEmptyInput ->
                    ( model, Command.none )

                MessageInput.PressedDropdownItem dropdownIndex ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            case ( SeqDict.get ( guildOrDmId, threadRoute ) loggedIn.editMessage, loggedIn.textInputFocus ) of
                                ( Just edit, Just textInputFocus ) ->
                                    case
                                        ( String.Nonempty.fromString edit.text
                                        , FrontendExtra.pingUserNameSoFar
                                            MessageMenu.editMessageTextInputId
                                            textInputFocus.selection
                                            guildOrDmId
                                            threadRoute
                                            loggedIn
                                        )
                                    of
                                        ( Just nonempty, Just nameSoFar ) ->
                                            let
                                                ( pingUser, text2, cmd ) =
                                                    MessageDropdown.pressedDropdownItem
                                                        SetFocus
                                                        (MyUi.isMobile model)
                                                        model.time
                                                        nameSoFar
                                                        guildOrDmId
                                                        MessageMenu.editMessageTextInputId
                                                        dropdownIndex
                                                        textInputFocus.dropdown
                                                        model.emojiData
                                                        (Local.model loggedIn.localState)
                                                        nonempty
                                            in
                                            ( { loggedIn
                                                | textInputFocus = Just { textInputFocus | dropdown = pingUser }
                                                , previousTextInputFocus = loggedIn.textInputFocus
                                                , editMessage =
                                                    SeqDict.insert
                                                        ( guildOrDmId, threadRoute )
                                                        { edit | text = String.Nonempty.toString text2 }
                                                        loggedIn.editMessage
                                              }
                                            , cmd
                                            )

                                        _ ->
                                            ( loggedIn, Command.none )

                                _ ->
                                    ( loggedIn, Command.none )
                        )
                        model

                MessageInput.PressedPingDropdownContainer ->
                    ( model, FrontendExtra.setFocus model MessageMenu.editMessageTextInputId )

                MessageInput.PressedUploadFile ->
                    ( model, Effect.File.Select.files [] (EditMessage_SelectedFilesToAttach ( guildOrDmId, threadRoute )) )

                MessageInput.OnPasteFiles files ->
                    FrontendExtra.editMessage_gotFiles ( guildOrDmId, threadRoute ) files model

                MessageInput.PressedOpenEmojiSelector ->
                    ( model
                    , Dom.getElement MessageMenu.editMessageTextInputId
                        |> Task.attempt GotPositionForEmojiSelector_EditMessage
                    )

                MessageInput.TypedPageUp ->
                    pageUpOrDownScroll True model

                MessageInput.TypedPageDown ->
                    pageUpOrDownScroll False model

                MessageInput.TypedTabInCodeBlock range ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            ( { loggedIn
                                | editMessage =
                                    SeqDict.update
                                        ( guildOrDmId, threadRoute )
                                        (Maybe.map
                                            (\edit -> { edit | text = MessageInput.insertTab range edit.text })
                                        )
                                        loggedIn.editMessage
                                , typedTextCounter = loggedIn.typedTextCounter + 1
                              }
                            , Ports.execCommand
                                { htmlId = MessageMenu.editMessageTextInputId
                                , commands = [ Ports.InsertText MessageInput.tabText range ]
                                }
                            )
                        )
                        model

                MessageInput.IgnoredKeyPress ->
                    ( model, Command.none )

        PageUpGotViewport result ->
            case result of
                Ok viewport ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            let
                                local =
                                    Local.model loggedIn.localState
                            in
                            case
                                ( Route.toGuildOrDmId local.localUser.session.userId model.route
                                , viewport.viewport.y - 0.9 * (toFloat (Coord.yRaw model.windowSize) - MyUi.channelHeaderHeight) < Scroll.closeToTop
                                )
                            of
                                ( Just ( guildOrDmId, threadRoute ), True ) ->
                                    FrontendExtra.handleLocalChange
                                        model.time
                                        (loadOlderMessages guildOrDmId threadRoute local)
                                        loggedIn
                                        Command.none

                                _ ->
                                    ( loggedIn, Command.none )
                        )
                        model

                Err _ ->
                    ( model, Command.none )

        GotPositionForEmojiSelector_EditMessage result ->
            case result of
                Ok ok ->
                    pressedOpenEmojiSelector
                        MessageMenu.editMessageTextInputId
                        (EmojiSelectorForEditMessage (Coord.xy (round ok.element.x) (round ok.element.y)))
                        model

                Err _ ->
                    ( model, Command.none )

        GotPositionForEmojiSelector_SheepGameInput input result ->
            case result of
                Ok ok ->
                    pressedOpenEmojiSelector
                        (SheepGame.inputId input)
                        -- The selector is drawn under the input, so what it's positioned
                        -- against is the bottom of it rather than the top.
                        (EmojiSelectorForSheepGameInput
                            input
                            (Coord.xy (round ok.element.x) (round (ok.element.y + ok.element.height)))
                        )
                        model

                Err _ ->
                    ( model, Command.none )

        MessageInputMsg guildOrDmId threadRoute messageInputMsg ->
            case messageInputMsg of
                MessageInput.PressedTextInput ->
                    FrontendExtra.handlePressedTextInput model

                MessageInput.TypedMessage text ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            case
                                MessageInput.largePastedText
                                    (SeqDict.get ( guildOrDmId, threadRoute ) loggedIn.drafts
                                        |> Maybe.map String.Nonempty.toString
                                        |> Maybe.withDefault ""
                                    )
                                    text
                            of
                                Just largePaste ->
                                    FrontendExtra.gotPastedText guildOrDmId threadRoute largePaste loggedIn

                                Nothing ->
                                    FrontendExtra.handleLocalChange
                                        model.time
                                        (if loggedIn.typingDebouncer then
                                            Local_MemberTyping model.time ( guildOrDmId, threadRoute ) |> Just

                                         else
                                            Nothing
                                        )
                                        { loggedIn
                                            | drafts =
                                                case String.Nonempty.fromString text of
                                                    Just nonempty ->
                                                        SeqDict.insert ( guildOrDmId, threadRoute ) nonempty loggedIn.drafts

                                                    Nothing ->
                                                        SeqDict.remove ( guildOrDmId, threadRoute ) loggedIn.drafts
                                            , typingDebouncer = False
                                            , typedTextCounter = loggedIn.typedTextCounter + 1
                                        }
                                        (Command.batch
                                            [ Process.sleep Pages.Guild.typingDebouncerDelay |> Task.perform (\() -> DebouncedTyping)
                                            , Scroll.toBottomOfChannelIfAtBottom Pages.Guild.conversationContainerId SetScrollToBottom loggedIn.channelScrollPosition
                                            , removePartialStickers loggedIn.textInputFocus Pages.Guild.channelTextInputId text
                                            ]
                                        )
                        )
                        model

                MessageInput.PressedSendMessage { charsLeft } ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            let
                                guildOrDmIdWithThread : ( AnyGuildOrDmId, ThreadRoute )
                                guildOrDmIdWithThread =
                                    ( guildOrDmId, threadRoute )
                            in
                            case SeqDict.get guildOrDmIdWithThread loggedIn.drafts of
                                Just draft ->
                                    let
                                        local : LocalState
                                        local =
                                            Local.model loggedIn.localState

                                        nonempty : String.Nonempty.NonemptyString
                                        nonempty =
                                            User.redactPrivateKeys local.localUser.user draft

                                        safeToSend : Bool
                                        safeToSend =
                                            (charsLeft >= 0)
                                                && (case SeqDict.get guildOrDmIdWithThread loggedIn.filesToUpload of
                                                        Just dict ->
                                                            NonemptyDict.toSeqDict dict
                                                                |> FileStatus.hasUploadingFile
                                                                |> not

                                                        Nothing ->
                                                            True
                                                   )
                                                && (case guildOrDmId of
                                                        GuildOrDmId _ ->
                                                            True

                                                        DiscordGuildOrDmId guildOrDmId2 ->
                                                            LocalState.canSendDiscordMessage local guildOrDmId2 == Ok ()
                                                   )
                                    in
                                    if not safeToSend then
                                        ( loggedIn, Command.none )

                                    else
                                        case encryptedDmOtherUser guildOrDmId local of
                                            Just dmId ->
                                                startEncryptingMessage
                                                    dmId
                                                    threadRoute
                                                    { content =
                                                        RichText.fromNonemptyString
                                                            local.localUser.timezone
                                                            (User.allUsers local.localUser)
                                                            nonempty
                                                    , embeds = Array.empty
                                                    }
                                                    loggedIn

                                            Nothing ->
                                                FrontendExtra.handleLocalChange
                                                    model.time
                                                    ((case guildOrDmId of
                                                        GuildOrDmId guildOrDmId2 ->
                                                            Local_SendMessage
                                                                model.time
                                                                model.timezone
                                                                guildOrDmId2
                                                                nonempty
                                                                (case threadRoute of
                                                                    ViewThread threadId ->
                                                                        ViewThreadWithMaybeMessage
                                                                            threadId
                                                                            (SeqDict.get guildOrDmIdWithThread loggedIn.replyTo |> Maybe.map Id.changeType)

                                                                    NoThread ->
                                                                        NoThreadWithMaybeMessage
                                                                            (SeqDict.get guildOrDmIdWithThread loggedIn.replyTo)
                                                                )
                                                                (case SeqDict.get guildOrDmIdWithThread loggedIn.filesToUpload of
                                                                    Just dict ->
                                                                        NonemptyDict.toSeqDict dict |> FileStatus.onlyUploadedFiles

                                                                    Nothing ->
                                                                        SeqDict.empty
                                                                )
                                                                (case model.emojiData of
                                                                    Just emojiData2 ->
                                                                        RichText.fromNonemptyString Time.utc SeqDict.empty nonempty
                                                                            |> RichText.emojisAndCustomEmojis emojiData2
                                                                            |> SeqSet.fromList
                                                                            |> SeqSet.toList

                                                                    Nothing ->
                                                                        []
                                                                )

                                                        DiscordGuildOrDmId guildOrDmId2 ->
                                                            Local_Discord_SendMessage
                                                                model.time
                                                                model.timezone
                                                                guildOrDmId2
                                                                nonempty
                                                                (case threadRoute of
                                                                    ViewThread threadId ->
                                                                        ViewThreadWithMaybeMessage
                                                                            threadId
                                                                            (SeqDict.get guildOrDmIdWithThread loggedIn.replyTo |> Maybe.map Id.changeType)

                                                                    NoThread ->
                                                                        NoThreadWithMaybeMessage
                                                                            (SeqDict.get guildOrDmIdWithThread loggedIn.replyTo)
                                                                )
                                                                (case SeqDict.get guildOrDmIdWithThread loggedIn.filesToUpload of
                                                                    Just dict ->
                                                                        NonemptyDict.toSeqDict dict |> FileStatus.onlyUploadedFiles

                                                                    Nothing ->
                                                                        SeqDict.empty
                                                                )
                                                     )
                                                        |> Just
                                                    )
                                                    { loggedIn
                                                        | drafts = SeqDict.remove guildOrDmIdWithThread loggedIn.drafts
                                                        , replyTo = SeqDict.remove guildOrDmIdWithThread loggedIn.replyTo
                                                        , filesToUpload = SeqDict.remove guildOrDmIdWithThread loggedIn.filesToUpload
                                                    }
                                                    (if MyUi.isMobile model then
                                                        Scroll.toBottomOfChannelSmooth Pages.Guild.conversationContainerId SetScrollToBottom

                                                     else
                                                        Scroll.toBottomOfChannel Pages.Guild.conversationContainerId SetScrollToBottom
                                                    )

                                Nothing ->
                                    ( loggedIn, Command.none )
                        )
                        model

                MessageInput.TypedArrowInDropdown index ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            ( { loggedIn
                                | textInputFocus =
                                    case loggedIn.textInputFocus of
                                        Just textInputFocus ->
                                            case
                                                FrontendExtra.pingUserNameSoFar
                                                    Pages.Guild.channelTextInputId
                                                    textInputFocus.selection
                                                    guildOrDmId
                                                    threadRoute
                                                    loggedIn
                                            of
                                                Just nameSoFar ->
                                                    { textInputFocus
                                                        | dropdown =
                                                            MessageDropdown.pressedArrowInDropdown
                                                                (MyUi.isMobile model)
                                                                model.timezone
                                                                model.time
                                                                nameSoFar
                                                                guildOrDmId
                                                                index
                                                                textInputFocus.dropdown
                                                                model.emojiData
                                                                (Local.model loggedIn.localState)
                                                    }
                                                        |> Just

                                                Nothing ->
                                                    loggedIn.textInputFocus

                                        Nothing ->
                                            loggedIn.textInputFocus
                                , previousTextInputFocus = loggedIn.textInputFocus
                              }
                            , Command.none
                            )
                        )
                        model

                MessageInput.TypedArrowUpInEmptyInput ->
                    FrontendExtra.handlePressedArrowUpInEmptyInput model guildOrDmId threadRoute

                MessageInput.PressedDropdownItem index ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            case ( SeqDict.get ( guildOrDmId, threadRoute ) loggedIn.drafts, loggedIn.textInputFocus ) of
                                ( Just text, Just textInputFocus ) ->
                                    case
                                        FrontendExtra.pingUserNameSoFar
                                            Pages.Guild.channelTextInputId
                                            textInputFocus.selection
                                            guildOrDmId
                                            threadRoute
                                            loggedIn
                                    of
                                        Just nameSoFar ->
                                            let
                                                ( pingUser, text2, cmd ) =
                                                    MessageDropdown.pressedDropdownItem
                                                        SetFocus
                                                        (MyUi.isMobile model)
                                                        model.time
                                                        nameSoFar
                                                        guildOrDmId
                                                        Pages.Guild.channelTextInputId
                                                        index
                                                        textInputFocus.dropdown
                                                        model.emojiData
                                                        (Local.model loggedIn.localState)
                                                        text
                                            in
                                            ( { loggedIn
                                                | textInputFocus = Just { textInputFocus | dropdown = pingUser }
                                                , previousTextInputFocus = loggedIn.textInputFocus
                                                , drafts = SeqDict.insert ( guildOrDmId, threadRoute ) text2 loggedIn.drafts
                                              }
                                            , cmd
                                            )

                                        Nothing ->
                                            ( loggedIn, Command.none )

                                _ ->
                                    ( loggedIn, Command.none )
                        )
                        model

                MessageInput.PressedPingDropdownContainer ->
                    ( model, FrontendExtra.setFocus model Pages.Guild.channelTextInputId )

                MessageInput.PressedUploadFile ->
                    ( model, Effect.File.Select.files [] (SelectedFilesToAttach ( guildOrDmId, threadRoute )) )

                MessageInput.OnPasteFiles files ->
                    FrontendExtra.gotFiles guildOrDmId threadRoute files model

                MessageInput.PressedOpenEmojiSelector ->
                    pressedOpenEmojiSelector Pages.Guild.channelTextInputId EmojiSelectorForMessage model

                MessageInput.TypedPageUp ->
                    pageUpOrDownScroll True model

                MessageInput.TypedPageDown ->
                    pageUpOrDownScroll False model

                MessageInput.TypedTabInCodeBlock range ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            ( { loggedIn
                                | drafts =
                                    SeqDict.update
                                        ( guildOrDmId, threadRoute )
                                        (Maybe.map
                                            (\draft ->
                                                MessageInput.insertTab range (String.Nonempty.toString draft)
                                                    |> String.Nonempty.fromString
                                                    |> Maybe.withDefault draft
                                            )
                                        )
                                        loggedIn.drafts
                                , typedTextCounter = loggedIn.typedTextCounter + 1
                              }
                            , Ports.execCommand
                                { htmlId = Pages.Guild.channelTextInputId
                                , commands = [ Ports.InsertText MessageInput.tabText range ]
                                }
                            )
                        )
                        model

                MessageInput.IgnoredKeyPress ->
                    ( model, Command.none )

        GotEmojiData result ->
            case result of
                Ok emojiData ->
                    ( setEmojiData emojiData model, Command.none )

                Err error ->
                    let
                        _ =
                            Debug.log "emoji error" error
                    in
                    ( model, Command.none )

        EnableToFrontendLogging ->
            ( { model | toFrontendLogs = Just Array.empty }, Command.none )

        TextSelectionChanged ( maybeHtmlId, maybeRange ) ->
            selectionChanged maybeHtmlId maybeRange model

        DomFocusChanged ( maybeHtmlId, maybeRange ) ->
            textInputFocusChanged maybeHtmlId maybeRange model

        GotVoiceChatSignalFromJs result ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    case result of
                        Ok event ->
                            case event of
                                Call.FromJs_GotUserMediaDevices mediaDevices defaultDevices ->
                                    ( { loggedIn | voiceChat = Call.gotUserMediaDevices mediaDevices defaultDevices loggedIn.voiceChat }
                                    , Command.none
                                    )

                                Call.FromJs_GotUserMediaDevicesError error ->
                                    let
                                        voiceChat =
                                            loggedIn.voiceChat
                                    in
                                    ( { loggedIn | voiceChat = { voiceChat | userMediaDevices = FailedToGetMediaDevices error } }
                                    , Command.none
                                    )

                                Call.FromJs_SpeakingChanged connectionId isSpeaking ->
                                    let
                                        voiceChat : Call.Model
                                        voiceChat =
                                            loggedIn.voiceChat
                                    in
                                    ( { loggedIn
                                        | voiceChat =
                                            case connectionId of
                                                Call.IsConnection connection2 ->
                                                    { voiceChat
                                                        | isSpeaking =
                                                            if isSpeaking then
                                                                SeqSet.insert connection2 voiceChat.isSpeaking

                                                            else
                                                                SeqSet.remove connection2 voiceChat.isSpeaking
                                                    }

                                                Call.IsLocal ->
                                                    { voiceChat | localIsSpeaking = isSpeaking }
                                      }
                                    , Command.none
                                    )

                                Call.FromJs_StartConnectionError string ->
                                    let
                                        voiceChat : Call.Model
                                        voiceChat =
                                            loggedIn.voiceChat
                                    in
                                    ( { loggedIn | voiceChat = { voiceChat | startConnectionError = Just string } }
                                    , Command.none
                                    )

                        Err error ->
                            let
                                _ =
                                    Debug.log "voice chat port didn't decode" error
                            in
                            ( loggedIn, Command.none )
                )
                model

        PressedToggleAttachedFileSpoiler guildOrDmId { removeSpoiler, fileId } ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn
                        | drafts =
                            SeqDict.updateIfExists
                                guildOrDmId
                                (\text ->
                                    let
                                        allUsers : SeqDict (Id UserId) FrontendUser
                                        allUsers =
                                            Local.model loggedIn.localState |> .localUser |> User.allUsers

                                        timezone : Time.Zone
                                        timezone =
                                            Local.model loggedIn.localState |> .localUser |> .timezone
                                    in
                                    (if removeSpoiler then
                                        RichText.fromNonemptyString timezone allUsers text
                                            |> RichText.unspoilerAttachedFile fileId

                                     else
                                        RichText.fromNonemptyString timezone allUsers text
                                            |> RichText.spoilerAttachedFile fileId
                                    )
                                        |> RichText.toString timezone False allUsers
                                        |> String.Nonempty.fromString
                                        |> Maybe.withDefault text
                                )
                                loggedIn.drafts
                      }
                    , Command.none
                    )
                )
                model

        EditMessage_PressedToggleAttachedFileSpoiler guildOrDmId { removeSpoiler, fileId } ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn
                        | editMessage =
                            SeqDict.updateIfExists
                                guildOrDmId
                                (\edit ->
                                    case String.Nonempty.fromString edit.text of
                                        Just nonempty ->
                                            let
                                                allUsers : SeqDict (Id UserId) FrontendUser
                                                allUsers =
                                                    Local.model loggedIn.localState |> .localUser |> User.allUsers

                                                timezone2 : Time.Zone
                                                timezone2 =
                                                    Local.model loggedIn.localState |> .localUser |> .timezone
                                            in
                                            { edit
                                                | text =
                                                    (if removeSpoiler then
                                                        RichText.fromNonemptyString timezone2 allUsers nonempty
                                                            |> RichText.unspoilerAttachedFile fileId

                                                     else
                                                        RichText.fromNonemptyString timezone2 allUsers nonempty
                                                            |> RichText.spoilerAttachedFile fileId
                                                    )
                                                        |> RichText.toString timezone2 False allUsers
                                            }

                                        Nothing ->
                                            edit
                                )
                                loggedIn.editMessage
                      }
                    , Command.none
                    )
                )
                model

        VoiceChatMsg voiceChatMsg ->
            case voiceChatMsg of
                Call.SelectedAudioInputDevice deviceId ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            let
                                voiceChat : Call.Model
                                voiceChat =
                                    loggedIn.voiceChat

                                voiceChat2 =
                                    { voiceChat | selectedAudioInputDevice = Just deviceId }
                            in
                            ( { loggedIn | voiceChat = voiceChat2 }
                            , Command.batch
                                [ Call.toJs (Call.ToJs_SetInput True deviceId)
                                , Call.startLocalStream voiceChat2
                                ]
                            )
                        )
                        model

                Call.SelectedVideoInputDevice deviceId ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            let
                                voiceChat : Call.Model
                                voiceChat =
                                    loggedIn.voiceChat

                                voiceChat2 =
                                    { voiceChat | selectedVideoInputDevice = Just deviceId }
                            in
                            ( { loggedIn | voiceChat = voiceChat2 }
                            , Command.batch
                                [ Call.toJs (Call.ToJs_SetInput False deviceId)
                                , Call.startLocalStream voiceChat2
                                ]
                            )
                        )
                        model

                Call.PressedToggleMute ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            let
                                voiceChat : Call.Model
                                voiceChat =
                                    loggedIn.voiceChat

                                remoteCallData =
                                    voiceChat.remoteCallData

                                audioInputEnabled : Bool
                                audioInputEnabled =
                                    not remoteCallData.audioInputEnabled
                            in
                            FrontendExtra.handleLocalChange
                                model.time
                                (Call.Local_SetRemoteCallData { remoteCallData | audioInputEnabled = audioInputEnabled }
                                    |> Local_VoiceChatChange
                                    |> Just
                                )
                                { loggedIn
                                    | voiceChat =
                                        { voiceChat | remoteCallData = { remoteCallData | audioInputEnabled = audioInputEnabled } }
                                }
                                (Call.toJs (Call.ToJs_SetAudioInputEnabled audioInputEnabled))
                        )
                        model

                Call.PressedTogglePauseVideo ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            let
                                voiceChat : Call.Model
                                voiceChat =
                                    loggedIn.voiceChat

                                remoteCallData =
                                    voiceChat.remoteCallData

                                videoInputEnabled : Bool
                                videoInputEnabled =
                                    not remoteCallData.videoInputEnabled
                            in
                            FrontendExtra.handleLocalChange
                                model.time
                                (Call.Local_SetRemoteCallData { remoteCallData | videoInputEnabled = videoInputEnabled }
                                    |> Local_VoiceChatChange
                                    |> Just
                                )
                                { loggedIn
                                    | voiceChat =
                                        { voiceChat | remoteCallData = { remoteCallData | videoInputEnabled = videoInputEnabled } }
                                }
                                (Call.toJs (Call.ToJs_SetVideoInputEnabled videoInputEnabled))
                        )
                        model

                Call.PressedJoinCall roomId ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            ( loggedIn
                            , Call.startCallCmd
                                roomId
                                (Local.model loggedIn.localState).localUser.session.userId
                                model.clientId
                                loggedIn.voiceChat
                            )
                        )
                        model

                Call.PressedLeaveCall ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            let
                                local : LocalState
                                local =
                                    Local.model loggedIn.localState
                            in
                            FrontendExtra.handleLocalChange
                                model.time
                                (Local_VoiceChatChange (Call.Local_Leave model.time) |> Just)
                                loggedIn
                                (Call.leaveVoiceChatCmds local.calls)
                        )
                        model

                Call.PressedDownloadRecording roomId ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            let
                                voiceChat : Call.Model
                                voiceChat =
                                    loggedIn.voiceChat
                            in
                            case SeqDict.get roomId loggedIn.voiceChat.recordings of
                                Just (Nonempty recording rest) ->
                                    ( { loggedIn
                                        | voiceChat =
                                            { voiceChat
                                                | recordings =
                                                    case List.Nonempty.fromList rest of
                                                        Just nonempty ->
                                                            SeqDict.insert roomId nonempty voiceChat.recordings

                                                        Nothing ->
                                                            SeqDict.remove roomId voiceChat.recordings
                                            }
                                      }
                                    , Effect.File.Download.bytes
                                        ("recording " ++ UserAgent.browserToString model.startupData.userAgent.browser)
                                        recording.mimeType
                                        recording.data
                                    )

                                Nothing ->
                                    ( loggedIn, Command.none )
                        )
                        model

                Call.PressedCopyError text ->
                    copyText text model

                Call.ChangedVolume connectionId volume ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            let
                                voiceChat : Call.Model
                                voiceChat =
                                    loggedIn.voiceChat
                            in
                            ( { loggedIn
                                | voiceChat =
                                    { voiceChat
                                        | volume =
                                            SeqDict.insert connectionId.otherClientId volume voiceChat.volume
                                    }
                              }
                            , Call.toJs (Call.ToJs_SetVolume connectionId volume)
                            )
                        )
                        model

                Call.MouseEnterVideoNode connectionId ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            let
                                voiceChat : Call.Model
                                voiceChat =
                                    loggedIn.voiceChat
                            in
                            ( { loggedIn | voiceChat = { voiceChat | videoHover = Just connectionId } }
                            , Command.none
                            )
                        )
                        model

                Call.MouseExitVideoNode connectionId ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            let
                                voiceChat : Call.Model
                                voiceChat =
                                    loggedIn.voiceChat
                            in
                            ( { loggedIn
                                | voiceChat =
                                    { voiceChat
                                        | videoHover =
                                            if voiceChat.videoHover == Just connectionId then
                                                Nothing

                                            else
                                                voiceChat.videoHover
                                    }
                              }
                            , Command.none
                            )
                        )
                        model

                Call.DoubleClickedVideoNode ->
                    case model.loginStatus of
                        LoggedIn loggedIn ->
                            let
                                local : LocalState
                                local =
                                    Local.model loggedIn.localState
                            in
                            case Call.displayMode (MyUi.isMobile model) local.localUser.session.userId model.route local.calls of
                                Call.NoVideo ->
                                    ( model, Command.none )

                                Call.ShowLocalVideo ->
                                    ( model, Command.none )

                                Call.ShowLocalVideoAndCall _ ->
                                    ( model, Command.none )

                                Call.ShowLocalVideoAndCallThumbnail (Call.DmRoomId { otherUserId }) ->
                                    FrontendExtra.routePush
                                        model
                                        (DmRoute
                                            { channelId =
                                                DmChannelId.fromUserIds local.localUser.session.userId otherUserId
                                            , threadRoute = NoThreadWithFriends Nothing HideChannelSettings
                                            , tab = Just ChannelHeaderTab_VoiceChat
                                            , channelsVisible = ChannelsHiddenOnMobile
                                            }
                                        )

                                Call.ShowLocalVideoAndCallThumbnail (Call.GuildRoomId { guildId, channelId }) ->
                                    FrontendExtra.routePush
                                        model
                                        (GuildRoute
                                            guildId
                                            (ChannelRoute
                                                channelId
                                                (NoThreadWithFriends Nothing HideChannelSettings)
                                                (Just ChannelHeaderTab_VoiceChat)
                                            )
                                            ChannelsHiddenOnMobile
                                        )

                        NotLoggedIn _ ->
                            ( model, Command.none )

        FileDragEnter timeStamp ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn
                        | fileDragOverCount =
                            case loggedIn.fileDragOverCount of
                                FileDragging dragStart count ->
                                    FileDragging dragStart (OneOrGreater.increment count)

                                NoFileDrag _ ->
                                    FileDragging (Duration.addTo model.startupData.timeOrigin timeStamp) OneOrGreater.one
                      }
                    , Command.none
                    )
                )
                model

        FileDragLeave ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn
                        | fileDragOverCount =
                            case loggedIn.fileDragOverCount of
                                FileDragging dragStart count ->
                                    case OneOrGreater.toInt count - 1 |> OneOrGreater.fromInt of
                                        Just count2 ->
                                            FileDragging dragStart count2

                                        Nothing ->
                                            NoFileDrag (Just model.time)

                                NoFileDrag _ ->
                                    loggedIn.fileDragOverCount
                      }
                    , Command.none
                    )
                )
                model

        FileDropped files ->
            let
                modelReset =
                    FrontendExtra.updateLoggedIn
                        (\loggedIn -> ( { loggedIn | fileDragOverCount = NoFileDrag (Just model.time) }, Command.none ))
                        model
                        |> Tuple.first
            in
            case ( List.Nonempty.fromList files, modelReset.loginStatus ) of
                ( Just nonemptyFiles, LoggedIn loggedIn ) ->
                    case
                        FrontendExtra.canDropFiles
                            (MyUi.isMobile model)
                            (Local.model loggedIn.localState |> .localUser |> .session |> .userId)
                            modelReset.route
                    of
                        Just func ->
                            func nonemptyFiles modelReset

                        Nothing ->
                            ( modelReset, Command.none )

                _ ->
                    ( modelReset, Command.none )

        PressedChannelHeaderTab tab ->
            let
                sameTab : ChannelHeaderTab -> Maybe ChannelHeaderTab -> Maybe ChannelHeaderTab
                sameTab tabA tabB =
                    case tabB of
                        Just tabB2 ->
                            if Route.sameChannelHeaderTab tabA tabB2 then
                                Nothing

                            else
                                Just tabA

                        Nothing ->
                            Just tabA
            in
            case model.route of
                DmRoute dmRoute ->
                    FrontendExtra.routePush model (DmRoute { dmRoute | tab = sameTab tab dmRoute.tab })

                HomePageRoute ->
                    ( model, Command.none )

                AdminRoute _ ->
                    ( model, Command.none )

                NewGuildRoute ->
                    ( model, Command.none )

                GuildRoute guildId channelRoute channelsVisible ->
                    case channelRoute of
                        ChannelRoute channelId threadRoute currentTab ->
                            FrontendExtra.routePush
                                model
                                (GuildRoute
                                    guildId
                                    (ChannelRoute channelId threadRoute (sameTab tab currentTab))
                                    channelsVisible
                                )

                        _ ->
                            ( model, Command.none )

                DiscordGuildRoute routeData ->
                    case routeData.channelRoute of
                        DiscordChannel_ChannelRoute channelId threadRoute currentTab ->
                            FrontendExtra.routePush
                                model
                                (DiscordGuildRoute
                                    { routeData
                                        | channelRoute =
                                            DiscordChannel_ChannelRoute
                                                channelId
                                                threadRoute
                                                (sameTab tab currentTab)
                                    }
                                )

                        _ ->
                            ( model, Command.none )

                DiscordDmRoute routeData ->
                    FrontendExtra.routePush
                        model
                        (DiscordDmRoute { routeData | tab = sameTab tab routeData.tab })

                AiChatRoute ->
                    ( model, Command.none )

                SlackOAuthRedirect _ ->
                    ( model, Command.none )

                TextEditorRoute ->
                    ( model, Command.none )

                LinkDiscord _ ->
                    ( model, Command.none )

                PublicGoMatchRoute _ ->
                    ( model, Command.none )

        GoSpectatorMsg spectatorMsg ->
            case model.publicGoMatch of
                PublicGoMatch_Loaded data gameModel ->
                    ( { model
                        | publicGoMatch =
                            Go.updateSpectator spectatorMsg data.cache gameModel
                                |> PublicGoMatch_Loaded data
                      }
                    , Command.none
                    )

                PublicGoMatch_NotLoaded ->
                    ( model, Command.none )

                PublicGoMatch_Loading ->
                    ( model, Command.none )

                PublicGoMatch_Missing ->
                    ( model, Command.none )

        PressedUnregisterServiceWorkers ->
            ( model, Ports.unregisterServiceWorker )

        PressedLoadDebugData ->
            ( model, Ports.loadServiceWorkerData )

        GotServiceWorkerData serviceWorkerData ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn
                        | userOptions =
                            Maybe.map
                                (\userOptions ->
                                    { userOptions
                                        | debugData = Just { data = serviceWorkerData, loadedAt = model.time }
                                    }
                                )
                                loggedIn.userOptions
                      }
                    , Command.none
                    )
                )
                model

        DrawingMsg drawingMsg ->
            updateDrawing drawingMsg model

        PressedNewMessagesWarning ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn
                        | newMessagesWhileNotScrolledToBottom = 0

                        -- The conversation scrolls away from the anchor the user picked
                        -- so there's nothing left to draw on
                        , drawingMode = Drawing.NoSelectedAnchor
                        , channelScrollPosition = ScrolledToBottom
                      }
                    , Scroll.toBottomOfChannel Pages.Guild.conversationContainerId SetScrollToBottom
                    )
                )
                model

        LoadedPopSound result ->
            ( { model | popSound = result }, Command.none )

        TypedFriendsSearch text ->
            FrontendExtra.updateLoggedIn
                (\loggedIn -> ( { loggedIn | friendsSearch = text }, Command.none ))
                model

        PressedClearFriendsSearch ->
            FrontendExtra.updateLoggedIn
                (\loggedIn -> ( { loggedIn | friendsSearch = "" }, Command.none ))
                model

        TypedChannelSearch text ->
            FrontendExtra.updateLoggedIn
                (\loggedIn -> ( { loggedIn | channelSearch = text }, Command.none ))
                model

        PressedClearChannelSearch ->
            FrontendExtra.updateLoggedIn
                (\loggedIn -> ( { loggedIn | channelSearch = "" }, Command.none ))
                model

        PressedMuteChannel guildId channelId isMuted ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    FrontendExtra.handleLocalChange
                        model.time
                        (Local_SetMuteChannel guildId channelId isMuted |> Just)
                        loggedIn
                        Command.none
                )
                model

        PressedMuteThread guildId channelId threadId isMuted ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    FrontendExtra.handleLocalChange
                        model.time
                        (Local_SetMuteThread guildId channelId threadId isMuted |> Just)
                        loggedIn
                        Command.none
                )
                model

        PressedMuteDiscordChannel discordUserId guildId channelId isMuted ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    FrontendExtra.handleLocalChange
                        model.time
                        (Local_SetMuteDiscordChannel discordUserId guildId channelId isMuted |> Just)
                        loggedIn
                        Command.none
                )
                model

        PressedMuteDiscordThread discordUserId guildId channelId threadId isMuted ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    FrontendExtra.handleLocalChange
                        model.time
                        (Local_SetMuteDiscordThread discordUserId guildId channelId threadId isMuted |> Just)
                        loggedIn
                        Command.none
                )
                model

        PressedMuteGuild guildId isMuted ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    FrontendExtra.handleLocalChange
                        model.time
                        (Local_SetMuteGuild guildId isMuted |> Just)
                        loggedIn
                        Command.none
                )
                model

        PressedMuteDiscordGuild discordUserId guildId isMuted ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    FrontendExtra.handleLocalChange
                        model.time
                        (Local_SetMuteDiscordGuild discordUserId guildId isMuted |> Just)
                        loggedIn
                        Command.none
                )
                model

        PressedMarkChannelAsRead guildOrDmId threadRoute ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    FrontendExtra.handleLocalChange
                        model.time
                        (Local_SetLastViewed guildOrDmId threadRoute |> Just)
                        loggedIn
                        Command.none
                )
                model

        PressedMarkAllChannelsAsRead unreads ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    List.foldl
                        (\( guildOrDmId, threadRoute ) ( loggedIn2, cmds ) ->
                            FrontendExtra.handleLocalChange
                                model.time
                                (Local_SetLastViewed guildOrDmId threadRoute |> Just)
                                loggedIn2
                                cmds
                        )
                        ( loggedIn, Command.none )
                        unreads
                )
                model

        UnreadOverviewChannelMsg guildOrDmId messageId messageViewMsg ->
            case messageViewMsg of
                MessageView.MessageView_PressedSpoiler spoilerIndex ->
                    handleRevealSpoilers guildOrDmId (NoThreadWithMessage messageId) spoilerIndex model

                MessageView.MessageView_PressedNonWhitelistLink url ->
                    handlePressedNonWhitelistLink url model

                MessageView.MessageView_PressedImage { fileUrl, imageSize } ->
                    ( { model | imageViewer = Just (ImageViewer.init { url = fileUrl, imageSize = imageSize }) }
                    , Command.none
                    )

                MessageView.MessageView_MouseEnteredMessage ->
                    handleMouseEnteredMessage guildOrDmId (NoThreadWithMessage messageId) model

                MessageView.MessageView_MouseExitedMessage ->
                    handleMouseExitedMessage guildOrDmId (NoThreadWithMessage messageId) model

                MessageView.MessageView_TouchStart _ _ _ _ _ ->
                    ( model, Command.none )

                MessageView.MessageView_AltPressedMessage _ _ _ _ ->
                    ( model, Command.none )

                MessageView.MessageView_PressedReactionEmoji_Remove emoji ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            FrontendExtra.handleLocalChange
                                model.time
                                (Local_RemoveReactionEmoji guildOrDmId (NoThreadWithMessage messageId) emoji |> Just)
                                loggedIn
                                Command.none
                        )
                        model

                MessageView.MessageView_PressedReactionEmoji_Add emoji ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            FrontendExtra.handleLocalChange
                                model.time
                                (Local_AddReactionEmoji guildOrDmId (NoThreadWithMessage messageId) emoji |> Just)
                                loggedIn
                                Command.none
                        )
                        model

                MessageView.MessageView_PressedReplyLink ->
                    ( model, Command.none )

                MessageView.MessageViewMsg_PressedShowReactionEmojiSelector ->
                    showReactionEmojiSelector guildOrDmId (NoThreadWithMessage messageId) model

                MessageView.MessageViewMsg_PressedEditMessage ->
                    ( model, Command.none )

                MessageView.MessageViewMsg_PressedReply ->
                    ( model, Command.none )

                MessageView.MessageViewMsg_PressedShowFullMenu _ _ ->
                    ( model, Command.none )

                MessageView.MessageView_PressedViewThreadLink ->
                    ( model, Command.none )

                MessageView.MessageView_NoOp ->
                    ( model, Command.none )

                MessageView.MessageViewMsg_PressedReactionEmoji emoji ->
                    FrontendExtra.updateLoggedIn (toggleReactionEmoji emoji guildOrDmId (NoThreadWithMessage messageId) model) model

                MessageView.MessageViewMsg_PressedCallStartedCard ->
                    case guildOrDmId of
                        GuildOrDmId (GuildOrDmId_Guild { guildId, channelId }) ->
                            GuildRoute
                                guildId
                                (ChannelRoute
                                    channelId
                                    (NoThreadWithFriends Nothing HideChannelSettings)
                                    (Just ChannelHeaderTab_VoiceChat)
                                )
                                ChannelsHiddenOnMobile
                                |> FrontendExtra.routePush model

                        GuildOrDmId (GuildOrDmId_Dm { otherUserId }) ->
                            case model.loginStatus of
                                LoggedIn loggedIn ->
                                    DmRoute
                                        { channelId =
                                            DmChannelId.fromUserIds
                                                (Local.model loggedIn.localState).localUser.session.userId
                                                otherUserId
                                        , threadRoute = NoThreadWithFriends Nothing HideChannelSettings
                                        , tab = Just ChannelHeaderTab_VoiceChat
                                        , channelsVisible = ChannelsHiddenOnMobile
                                        }
                                        |> FrontendExtra.routePush model

                                NotLoggedIn _ ->
                                    ( model, Command.none )

                        DiscordGuildOrDmId _ ->
                            ( model, Command.none )

                MessageView.MessageViewMsg_PressedGameStartedCard ->
                    case guildOrDmId of
                        GuildOrDmId (GuildOrDmId_Guild { guildId, channelId }) ->
                            GuildRoute
                                guildId
                                (ChannelRoute
                                    channelId
                                    (NoThreadWithFriends Nothing HideChannelSettings)
                                    (Just (ChannelHeaderTab_Games (Just messageId)))
                                )
                                ChannelsHiddenOnMobile
                                |> FrontendExtra.routePush model

                        GuildOrDmId (GuildOrDmId_Dm { otherUserId }) ->
                            case model.loginStatus of
                                LoggedIn loggedIn ->
                                    DmRoute
                                        { channelId =
                                            DmChannelId.fromUserIds
                                                (Local.model loggedIn.localState).localUser.session.userId
                                                otherUserId
                                        , threadRoute = NoThreadWithFriends Nothing HideChannelSettings
                                        , tab = Just (ChannelHeaderTab_Games (Just messageId))
                                        , channelsVisible = ChannelsHiddenOnMobile
                                        }
                                        |> FrontendExtra.routePush model

                                NotLoggedIn _ ->
                                    ( model, Command.none )

                        DiscordGuildOrDmId _ ->
                            ( model, Command.none )

                MessageView.MessageView_PressedUserIconAnchor _ _ ->
                    ( model, Command.none )

                MessageView.MessageView_PressedTimestamp _ _ ->
                    ( model, Command.none )

                MessageView.MessageView_PressedDateDivider _ _ _ ->
                    ( model, Command.none )

                MessageView.MessageView_PressedCardAnchor _ _ ->
                    ( model, Command.none )

                MessageView.MessageView_PressedUserIconButton otherUserId ->
                    handlePressedUserIconButton otherUserId model

                MessageView.MessageView_PressedDiscordUserIconButton otherUserId ->
                    handlePressedDiscordUserIconButton otherUserId model

        UnreadOverviewThreadMsg guildOrDmId threadId messageId messageViewMsg ->
            case messageViewMsg of
                MessageView.MessageView_PressedSpoiler spoilerIndex ->
                    handleRevealSpoilers guildOrDmId (ViewThreadWithMessage threadId messageId) spoilerIndex model

                MessageView.MessageView_PressedNonWhitelistLink url ->
                    handlePressedNonWhitelistLink url model

                MessageView.MessageView_PressedImage { fileUrl, imageSize } ->
                    ( { model | imageViewer = Just (ImageViewer.init { url = fileUrl, imageSize = imageSize }) }
                    , Command.none
                    )

                MessageView.MessageView_MouseEnteredMessage ->
                    handleMouseEnteredMessage guildOrDmId (ViewThreadWithMessage threadId messageId) model

                MessageView.MessageView_MouseExitedMessage ->
                    handleMouseExitedMessage guildOrDmId (ViewThreadWithMessage threadId messageId) model

                MessageView.MessageView_TouchStart _ _ _ _ _ ->
                    ( model, Command.none )

                MessageView.MessageView_AltPressedMessage _ _ _ _ ->
                    ( model, Command.none )

                MessageView.MessageView_PressedReactionEmoji_Remove emoji ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            FrontendExtra.handleLocalChange
                                model.time
                                (Local_RemoveReactionEmoji guildOrDmId (ViewThreadWithMessage threadId messageId) emoji |> Just)
                                loggedIn
                                Command.none
                        )
                        model

                MessageView.MessageView_PressedReactionEmoji_Add emoji ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            FrontendExtra.handleLocalChange
                                model.time
                                (Local_AddReactionEmoji guildOrDmId (ViewThreadWithMessage threadId messageId) emoji |> Just)
                                loggedIn
                                Command.none
                        )
                        model

                MessageView.MessageView_PressedReplyLink ->
                    ( model, Command.none )

                MessageView.MessageViewMsg_PressedShowReactionEmojiSelector ->
                    showReactionEmojiSelector guildOrDmId (ViewThreadWithMessage threadId messageId) model

                MessageView.MessageViewMsg_PressedEditMessage ->
                    ( model, Command.none )

                MessageView.MessageViewMsg_PressedReply ->
                    ( model, Command.none )

                MessageView.MessageViewMsg_PressedShowFullMenu _ _ ->
                    ( model, Command.none )

                MessageView.MessageView_PressedViewThreadLink ->
                    ( model, Command.none )

                MessageView.MessageView_NoOp ->
                    ( model, Command.none )

                MessageView.MessageViewMsg_PressedReactionEmoji emoji ->
                    FrontendExtra.updateLoggedIn (toggleReactionEmoji emoji guildOrDmId (ViewThreadWithMessage threadId messageId) model) model

                MessageView.MessageViewMsg_PressedCallStartedCard ->
                    -- Calls are not supported inside threads
                    ( model, Command.none )

                MessageView.MessageViewMsg_PressedGameStartedCard ->
                    -- Games are not supported inside threads
                    ( model, Command.none )

                MessageView.MessageView_PressedUserIconAnchor _ _ ->
                    -- Anchors are only picked while drawing on a channel and the unread overview
                    -- isn't one
                    ( model, Command.none )

                MessageView.MessageView_PressedTimestamp _ _ ->
                    ( model, Command.none )

                MessageView.MessageView_PressedDateDivider _ _ _ ->
                    ( model, Command.none )

                MessageView.MessageView_PressedCardAnchor _ _ ->
                    ( model, Command.none )

                MessageView.MessageView_PressedUserIconButton otherUserId ->
                    handlePressedUserIconButton otherUserId model

                MessageView.MessageView_PressedDiscordUserIconButton otherUserId ->
                    handlePressedDiscordUserIconButton otherUserId model

        ValidatedE2eePrivateKey text keysValid ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn
                        | userOptions =
                            Maybe.map
                                (\userOptions ->
                                    { userOptions | e2eeKeysValid = keysValid, privateKeyText = text }
                                )
                                loggedIn.userOptions
                      }
                    , Command.none
                    )
                )
                model


handleMouseEnteredMessage : AnyGuildOrDmId -> ThreadRouteWithMessage -> LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg_ )
handleMouseEnteredMessage guildOrDmId threadRoute model =
    if MyUi.isMobile model then
        ( model, Command.none )

    else
        FrontendExtra.updateLoggedIn
            (\loggedIn ->
                ( case loggedIn.messageHover of
                    MessageMenu _ ->
                        loggedIn

                    _ ->
                        { loggedIn | messageHover = MessageHover guildOrDmId threadRoute }
                , Command.none
                )
            )
            model


handleMouseExitedMessage : AnyGuildOrDmId -> ThreadRouteWithMessage -> LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg_ )
handleMouseExitedMessage guildOrDmId threadRoute model =
    FrontendExtra.updateLoggedIn
        (\loggedIn ->
            ( { loggedIn
                | messageHover =
                    if MessageHover guildOrDmId threadRoute == loggedIn.messageHover then
                        NoMessageHover

                    else
                        loggedIn.messageHover
              }
            , Command.none
            )
        )
        model


handlePressedUserIconButton : Id UserId -> LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg_ )
handlePressedUserIconButton otherUserId model =
    case model.loginStatus of
        LoggedIn loggedIn ->
            FrontendExtra.routePush
                model
                (DmRoute
                    { channelId =
                        DmChannelId.fromUserIds
                            (Local.model loggedIn.localState).localUser.session.userId
                            otherUserId
                    , threadRoute = NoThreadWithFriends Nothing HideChannelSettings
                    , tab = Nothing
                    , channelsVisible = ChannelsHiddenOnMobile
                    }
                )

        NotLoggedIn _ ->
            ( model, Command.none )


handlePressedDiscordUserIconButton : Discord.Id Discord.UserId -> LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg_ )
handlePressedDiscordUserIconButton otherUserId model =
    case model.loginStatus of
        LoggedIn loggedIn ->
            case LocalState.discordDmChannelWithUser otherUserId (Local.model loggedIn.localState) of
                Just ( currentDiscordUserId, channelId ) ->
                    FrontendExtra.routePush
                        model
                        (DiscordDmRoute
                            { currentDiscordUserId = currentDiscordUserId
                            , channelId = channelId
                            , viewingMessage = Nothing
                            , showMembersTab = HideChannelSettings
                            , tab = Nothing
                            , channelsVisible = ChannelsHiddenOnMobile
                            }
                        )

                Nothing ->
                    ( model, Command.none )

        NotLoggedIn _ ->
            ( model, Command.none )


handlePressedNonWhitelistLink : Url -> LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg_ )
handlePressedNonWhitelistLink url model =
    FrontendExtra.updateLoggedIn
        (\loggedIn ->
            ( { loggedIn | externalLinkWarning = Just url }
            , Command.none
            )
        )
        model


handleRevealSpoilers : AnyGuildOrDmId -> ThreadRouteWithMessage -> Int -> LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg_ )
handleRevealSpoilers guildOrDmId threadRoute spoilerIndex model =
    FrontendExtra.updateLoggedIn
        (\loggedIn ->
            ( { loggedIn
                | revealedSpoilers =
                    SeqDict.update
                        guildOrDmId
                        (\maybe ->
                            let
                                { messages, threadMessages } =
                                    case maybe of
                                        Just a ->
                                            a

                                        Nothing ->
                                            { messages = SeqDict.empty
                                            , threadMessages = SeqDict.empty
                                            }
                            in
                            (case threadRoute of
                                ViewThreadWithMessage threadMessageIndex messageId ->
                                    { messages = messages
                                    , threadMessages =
                                        SeqDict.update
                                            threadMessageIndex
                                            (\maybe2 ->
                                                SeqDictHelper.addToSet
                                                    messageId
                                                    spoilerIndex
                                                    (Maybe.withDefault SeqDict.empty maybe2)
                                                    |> Just
                                            )
                                            threadMessages
                                    }

                                NoThreadWithMessage messageId ->
                                    { messages = SeqDictHelper.addToSet messageId spoilerIndex messages
                                    , threadMessages = threadMessages
                                    }
                            )
                                |> Just
                        )
                        loggedIn.revealedSpoilers
              }
            , Command.none
            )
        )
        model


{-| Anchor elements (profile images and timestamps) can always be clicked but
they only select a drawing anchor while the drawing tab is open.
-}
selectDrawingAnchor :
    AnyGuildOrDmId
    -> Drawing.AnchorType
    -> Point2d CssPixels ScreenCoordinate
    -> ( Float, Float )
    -> Float
    -> LoadedFrontend
    -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg_ )
selectDrawingAnchor guildOrDmId anchorType elementPosition anchorHalfSize pointScale model =
    FrontendExtra.updateLoggedIn
        (\loggedIn ->
            ( { loggedIn
                | drawingMode =
                    Drawing.initialAnchorSelection guildOrDmId anchorType elementPosition anchorHalfSize pointScale
                        |> Drawing.SelectedAnchor
              }
            , Command.none
            )
        )
        model


{-| Convert a pointer position (in viewport css pixels) into a point relative to
the selected anchor's top left corner, in the anchor's coordinate space. When
zoomed in the conversation is magnified around the center of the anchor, so the
pointer position is mapped back through that same transform.
-}
anchorRelativePoint : Drawing.SelectedAnchorData -> Float -> Float -> ( Float, Float )
anchorRelativePoint selected x y =
    let
        anchorPosition : { x : Float, y : Float }
        anchorPosition =
            Point2d.unwrap selected.position

        ( offsetX, offsetY ) =
            Drawing.zoomPointOffset selected
    in
    ( (offsetX + (x - anchorPosition.x - offsetX) / selected.zoom) * selected.pointScale
    , (offsetY + (y - anchorPosition.y - offsetY) / selected.zoom) * selected.pointScale
    )


updateDrawing : Drawing.Msg -> LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg_ )
updateDrawing drawingMsg model =
    FrontendExtra.updateLoggedIn
        (\loggedIn ->
            case loggedIn.drawingMode of
                Drawing.SelectedAnchor selected ->
                    case drawingMsg of
                        Drawing.PointerDown x y ->
                            case selected.stroke of
                                Nothing ->
                                    FrontendExtra.handleLocalChange
                                        model.time
                                        (Local_Drawing
                                            selected.guildOrDmId
                                            selected.anchorType
                                            (Drawing.StartStroke
                                                (anchorRelativePoint selected x y)
                                            )
                                            |> Just
                                        )
                                        { loggedIn
                                            | drawingMode =
                                                Drawing.SelectedAnchor { selected | stroke = Just { unsent = [] } }
                                        }
                                        Command.none

                                Just _ ->
                                    ( loggedIn, Command.none )

                        Drawing.PointerMoved x y ->
                            case selected.stroke of
                                Just stroke ->
                                    let
                                        unsent : List ( Float, Float )
                                        unsent =
                                            anchorRelativePoint selected x y :: stroke.unsent

                                        setStroke : Maybe Drawing.ActiveStroke -> LoggedIn2
                                        setStroke newStroke =
                                            { loggedIn
                                                | drawingMode =
                                                    Drawing.SelectedAnchor { selected | stroke = newStroke }
                                            }
                                    in
                                    -- Points are sent in small batches to avoid sending a
                                    -- message to the backend for every pointermove event.
                                    if List.length unsent >= 4 then
                                        FrontendExtra.handleLocalChange
                                            model.time
                                            (case List.Nonempty.fromList (List.reverse unsent) of
                                                Just points ->
                                                    Local_Drawing
                                                        selected.guildOrDmId
                                                        selected.anchorType
                                                        (Drawing.ContinueStroke points)
                                                        |> Just

                                                Nothing ->
                                                    Nothing
                                            )
                                            (setStroke (Just { unsent = [] }))
                                            Command.none

                                    else
                                        ( setStroke (Just { unsent = unsent }), Command.none )

                                Nothing ->
                                    ( loggedIn, Command.none )

                        Drawing.PointerUp ->
                            case selected.stroke of
                                Just stroke ->
                                    FrontendExtra.handleLocalChange
                                        model.time
                                        (Local_Drawing
                                            selected.guildOrDmId
                                            selected.anchorType
                                            (Drawing.EndStroke (List.reverse stroke.unsent))
                                            |> Just
                                        )
                                        { loggedIn
                                            | drawingMode =
                                                Drawing.SelectedAnchor { selected | stroke = Nothing }
                                        }
                                        Command.none

                                Nothing ->
                                    ( loggedIn, Command.none )

                        Drawing.PressedUndo ->
                            FrontendExtra.drawingUndo selected loggedIn model

                        Drawing.PressedRedo ->
                            FrontendExtra.drawingRedo selected loggedIn model

                        Drawing.PressedZoom ->
                            if selected.zoom == 1 then
                                ( { loggedIn
                                    | drawingMode =
                                        Drawing.SelectedAnchor
                                            { selected | zoom = Drawing.zoomLevel, zoomContainer = Nothing }
                                  }
                                  -- Measure the conversation container so the magnified view can be
                                  -- pinned on the right spot of the anchor.
                                , Dom.getElement Pages.Guild.conversationContainerId
                                    |> Task.attempt
                                        (\result ->
                                            (case result of
                                                Ok { element } ->
                                                    Just { x = element.x, y = element.y, width = element.width, height = element.height }

                                                Err _ ->
                                                    Nothing
                                            )
                                                |> Drawing.GotZoomContainer
                                                |> DrawingMsg
                                        )
                                )

                            else
                                ( { loggedIn
                                    | drawingMode =
                                        Drawing.SelectedAnchor { selected | zoom = 1, zoomContainer = Nothing }
                                  }
                                , Command.none
                                )

                        Drawing.GotZoomContainer maybeContainer ->
                            ( { loggedIn
                                | drawingMode = Drawing.SelectedAnchor { selected | zoomContainer = maybeContainer }
                              }
                            , Command.none
                            )

                        Drawing.PressedDone ->
                            ( { loggedIn | drawingMode = Drawing.NoSelectedAnchor }, Command.none )

                Drawing.NoSelectedAnchor ->
                    ( loggedIn, Command.none )
        )
        model


copyText : String -> LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly toMsg msg )
copyText text model =
    ( { model | lastCopied = Just { copiedAt = model.time, copied = CopiedText text } }
    , Ports.copyToClipboard text
    )


{-| Keep the app icon badge showing how many unread messages the user has. Only sent
to JS when the count changes, since it runs after every update.
-}
checkAppBadgeChange : LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly toMsg msg )
checkAppBadgeChange model =
    let
        count : Int
        count =
            case model.loginStatus of
                LoggedIn loggedIn ->
                    GuildColumn.unreadNotificationCount (Local.model loggedIn.localState)

                NotLoggedIn _ ->
                    0
    in
    if model.appBadgeCount == Just count then
        ( model, Command.none )

    else
        ( { model | appBadgeCount = Just count }, Ports.setAppBadge count )


checkCallDisplayModeChange : LoadedFrontend -> LoadedFrontend -> Command FrontendOnly toMsg msg
checkCallDisplayModeChange modelOld modelNew =
    case ( modelOld.loginStatus, modelNew.loginStatus ) of
        ( LoggedIn loggedInOld, LoggedIn loggedInNew ) ->
            let
                localOld =
                    Local.model loggedInOld.localState

                localNew =
                    Local.model loggedInNew.localState
            in
            Call.displayModeChangeCmd
                (Call.displayMode (MyUi.isMobile modelOld) localOld.localUser.session.userId modelOld.route localOld.calls)
                (Call.displayMode (MyUi.isMobile modelNew) localNew.localUser.session.userId modelNew.route localNew.calls)
                loggedInNew.voiceChat

        ( NotLoggedIn _, LoggedIn loggedInNew ) ->
            let
                localNew =
                    Local.model loggedInNew.localState
            in
            Call.displayModeChangeCmd
                Call.NoVideo
                (Call.displayMode (MyUi.isMobile modelNew) localNew.localUser.session.userId modelNew.route localNew.calls)
                loggedInNew.voiceChat

        ( LoggedIn loggedInOld, NotLoggedIn _ ) ->
            let
                localOld =
                    Local.model loggedInOld.localState
            in
            Call.displayModeChangeCmd
                (Call.displayMode (MyUi.isMobile modelOld) localOld.localUser.session.userId modelOld.route localOld.calls)
                Call.NoVideo
                loggedInOld.voiceChat

        _ ->
            Command.none


removePartialStickers : Maybe TextInputFocus -> HtmlId -> String -> Command FrontendOnly toMsg msg
removePartialStickers textInputFocus htmlId text =
    case
        List.filterMap
            (\( range, maybeStickerId ) ->
                case maybeStickerId of
                    Just _ ->
                        Nothing

                    Nothing ->
                        Just range
            )
            (RichText.stringToStickersAndCustomEmojis text)
    of
        [] ->
            Command.none

        list ->
            let
                text2 : String
                text2 =
                    List.foldl (\range text3 -> String.Extra.replaceSlice "" range.start range.end text3) text list
            in
            Ports.execCommand
                { htmlId = htmlId
                , commands =
                    [ Ports.Undo, Ports.InsertText text2 { start = 0, end = 999999 } ]
                        ++ (case textInputFocus of
                                Just textInputFocus2 ->
                                    if textInputFocus2.htmlId == htmlId then
                                        let
                                            selection2 =
                                                List.foldl
                                                    (\range selection ->
                                                        if range.end < selection.start then
                                                            -- Not entirely sure why the -1 is needed.
                                                            -- Maybe it's due to the current selection being out of date then the text changes by one character (since the user has pressed backspace)
                                                            { start = selection.start - Range.rangeSize range - 1
                                                            , end = selection.end - Range.rangeSize range - 1
                                                            }

                                                        else if range.start < selection.start then
                                                            { start = selection.start - (range.start - selection.start) - 1
                                                            , end = selection.end - (range.start - selection.start) - 1
                                                            }

                                                        else
                                                            selection
                                                    )
                                                    textInputFocus2.selection
                                                    list
                                        in
                                        [ Ports.SelectRange selection2 textInputFocus2.direction ]

                                    else
                                        []

                                Nothing ->
                                    []
                           )
                }


loadOlderMessages : AnyGuildOrDmId -> ThreadRoute -> LocalState -> Maybe LocalChange
loadOlderMessages guildOrDmId threadRoute local =
    let
        messagesLeft channel localChange =
            if Id.toInt channel.visibleMessages.oldest > 0 then
                Just localChange

            else
                Nothing
    in
    case guildOrDmId of
        GuildOrDmId (GuildOrDmId_Guild { guildId, channelId }) ->
            case LocalState.getGuildAndChannel { guildId = guildId, channelId = channelId } local of
                Just ( _, channel ) ->
                    case threadRoute of
                        NoThread ->
                            Local_LoadChannelMessages
                                (GuildOrDmId_Guild { guildId = guildId, channelId = channelId })
                                channel.visibleMessages.oldest
                                EmptyPlaceholder
                                |> messagesLeft channel

                        ViewThread threadId ->
                            let
                                thread =
                                    SeqDict.get threadId channel.threads |> Maybe.withDefault Thread.frontendInit
                            in
                            Local_LoadThreadMessages
                                (GuildOrDmId_Guild { guildId = guildId, channelId = channelId })
                                threadId
                                thread.visibleMessages.oldest
                                EmptyPlaceholder
                                |> messagesLeft thread

                Nothing ->
                    Nothing

        GuildOrDmId (GuildOrDmId_Dm { otherUserId }) ->
            let
                dmChannel : FrontendDmChannel
                dmChannel =
                    SeqDict.get otherUserId local.dmChannels
                        |> Maybe.withDefault DmChannel.frontendInit
            in
            case threadRoute of
                NoThread ->
                    Local_LoadChannelMessages
                        (GuildOrDmId_Dm { otherUserId = otherUserId })
                        dmChannel.visibleMessages.oldest
                        EmptyPlaceholder
                        |> messagesLeft dmChannel

                ViewThread threadId ->
                    let
                        thread =
                            SeqDict.get threadId dmChannel.threads |> Maybe.withDefault Thread.frontendInit
                    in
                    Local_LoadThreadMessages
                        (GuildOrDmId_Dm { otherUserId = otherUserId })
                        threadId
                        thread.visibleMessages.oldest
                        EmptyPlaceholder
                        |> messagesLeft thread

        DiscordGuildOrDmId ((DiscordGuildOrDmId_Guild { guildId, channelId }) as guildOrDmId2) ->
            case LocalState.getDiscordGuildAndChannel guildId channelId local of
                Just ( _, channel ) ->
                    case threadRoute of
                        NoThread ->
                            Local_Discord_LoadChannelMessages
                                guildOrDmId2
                                channel.visibleMessages.oldest
                                EmptyPlaceholder
                                |> messagesLeft channel

                        ViewThread threadId ->
                            let
                                thread =
                                    SeqDict.get threadId channel.threads |> Maybe.withDefault Thread.discordFrontendInit
                            in
                            Local_Discord_LoadThreadMessages
                                guildOrDmId2
                                threadId
                                thread.visibleMessages.oldest
                                EmptyPlaceholder
                                |> messagesLeft thread

                Nothing ->
                    Nothing

        DiscordGuildOrDmId ((DiscordGuildOrDmId_Dm data) as guildOrDmId2) ->
            case SeqDict.get data.channelId local.discordDmChannels of
                Just dmChannel ->
                    Local_Discord_LoadChannelMessages
                        guildOrDmId2
                        dmChannel.visibleMessages.oldest
                        EmptyPlaceholder
                        |> messagesLeft dmChannel

                Nothing ->
                    Nothing


pageUpOrDownScroll : Bool -> LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly toMsg FrontendMsg_ )
pageUpOrDownScroll isUp model =
    ( model
    , Command.batch
        [ Scroll.smoothScrollBy
            Pages.Guild.conversationContainerId
            ((if isUp then
                -0.9

              else
                0.9
             )
                * (toFloat (Coord.yRaw model.windowSize) - MyUi.channelHeaderHeight)
            )
        , Dom.getViewportOf Pages.Guild.conversationContainerId
            |> Task.attempt PageUpGotViewport
        ]
    )


messageHasReaction : EmojiOrCustomEmoji -> AnyGuildOrDmId -> ThreadRouteWithMessage -> LocalState -> Bool
messageHasReaction emoji guildOrDmId threadRoute local =
    case guildOrDmId of
        GuildOrDmId guildOrDmId3 ->
            case LocalState.messageReactions guildOrDmId3 threadRoute local |> SeqDict.get emoji of
                Just reactions ->
                    NonemptySet.member local.localUser.session.userId reactions

                Nothing ->
                    False

        DiscordGuildOrDmId (DiscordGuildOrDmId_Guild { currentUserId, guildId, channelId }) ->
            case LocalState.getDiscordGuildAndChannel guildId channelId local of
                Just ( _, channel ) ->
                    case
                        LocalState.messageReactionsHelper channel threadRoute
                            |> SeqDict.get emoji
                    of
                        Just reactions ->
                            NonemptySet.member currentUserId reactions

                        Nothing ->
                            False

                Nothing ->
                    False

        DiscordGuildOrDmId (DiscordGuildOrDmId_Dm data) ->
            case SeqDict.get data.channelId local.discordDmChannels of
                Just channel ->
                    case threadRoute of
                        NoThreadWithMessage messageId ->
                            case
                                LocalState.messageReactionsNoThread messageId channel
                                    |> SeqDict.get emoji
                            of
                                Just reactions ->
                                    NonemptySet.member data.currentUserId reactions

                                Nothing ->
                                    False

                        ViewThreadWithMessage _ _ ->
                            False

                Nothing ->
                    False


scrollEmojiIntoView : Int -> Command FrontendOnly ToBackend FrontendMsg_
scrollEmojiIntoView index =
    Task.map3
        (\button container viewport -> ( button, container, viewport ))
        (Dom.getElement (Emoji.emojiButtonId index))
        (Dom.getElement Emoji.scrollContainerId)
        (Dom.getViewportOf Emoji.scrollContainerId)
        |> Task.andThen
            (\( button, container, { viewport } ) ->
                let
                    buttonTop : Float
                    buttonTop =
                        button.element.y - container.element.y + viewport.y

                    buttonBottom : Float
                    buttonBottom =
                        buttonTop + button.element.height
                in
                if buttonTop < viewport.y then
                    Dom.setViewportOf Emoji.scrollContainerId viewport.x buttonTop

                else if buttonBottom > viewport.y + viewport.height then
                    Dom.setViewportOf Emoji.scrollContainerId viewport.x (buttonBottom - viewport.height)

                else
                    Task.succeed ()
            )
        |> Task.attempt (\_ -> FrontendNoOp)


toggleReactionEmoji :
    EmojiOrCustomEmoji
    -> AnyGuildOrDmId
    -> ThreadRouteWithMessage
    -> LoadedFrontend
    -> LoggedIn2
    -> ( LoggedIn2, Command FrontendOnly ToBackend FrontendMsg_ )
toggleReactionEmoji emoji guildOrDmId threadRoute model loggedIn =
    let
        local : LocalState
        local =
            Local.model loggedIn.localState

        hasReaction =
            messageHasReaction emoji guildOrDmId threadRoute local
    in
    FrontendExtra.handleLocalChange
        model.time
        ((if hasReaction then
            Local_RemoveReactionEmoji

          else
            Local_AddReactionEmoji
         )
            guildOrDmId
            threadRoute
            emoji
            |> Just
        )
        loggedIn
        (if hasReaction then
            Command.none

         else
            Scroll.toBottomOfChannelIfAtBottom Pages.Guild.conversationContainerId SetScrollToBottom loggedIn.channelScrollPosition
        )


pressedOpenEmojiSelector : HtmlId -> (Maybe Range -> EmojiSelector) -> LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg_ )
pressedOpenEmojiSelector textInputId emojiSelector model =
    FrontendExtra.updateLoggedIn
        (\loggedIn ->
            let
                emojiSelectorModel =
                    loggedIn.emojiSelector
            in
            ( { loggedIn
                | showEmojiSelector =
                    case loggedIn.showEmojiSelector of
                        EmojiSelectorHidden ->
                            case loggedIn.previousTextInputFocus of
                                Just textInputFocus ->
                                    if textInputFocus.htmlId == textInputId then
                                        emojiSelector (Just textInputFocus.selection)

                                    else
                                        emojiSelector Nothing

                                Nothing ->
                                    emojiSelector Nothing

                        _ ->
                            EmojiSelectorHidden
                , emojiSelector = { emojiSelectorModel | searchText = "", category = Emoji.selectorInit.category }
              }
            , Dom.focus Emoji.searchInputId |> Task.attempt (\_ -> SetFocus)
            )
        )
        model


insertEmojiOrSticker :
    HtmlId
    -> Maybe Range
    -> EmojiOrSticker
    -> LoadedFrontend
    -> LoggedIn2
    -> ( LoggedIn2, Command FrontendOnly toMsg msg )
insertEmojiOrSticker inputId maybeSelection emojiOrSticker model loggedIn =
    let
        text : String
        text =
            case emojiOrSticker of
                EmojiOrSticker_UnicodeEmoji emoji ->
                    case model.emojiData of
                        Just emojiData ->
                            Emoji.emojiWithSkinTone
                                (Local.model loggedIn.localState).localUser.user.emojiConfig.skinTone
                                emoji
                                emojiData
                                ++ " "

                        Nothing ->
                            ""

                EmojiOrSticker_Sticker stickerId ->
                    Sticker.idToString stickerId

                EmojiOrSticker_CustomEmoji customEmojiId ->
                    CustomEmoji.idToString customEmojiId
    in
    ( { loggedIn | showEmojiSelector = EmojiSelectorHidden }
    , case maybeSelection of
        Just range ->
            Ports.execCommand { htmlId = inputId, commands = [ Ports.InsertText text range ] }

        Nothing ->
            Ports.execCommand
                { htmlId = inputId
                , commands = [ Ports.InsertText text { start = 99999, end = 99999 } ]
                }
    )


selectionChanged :
    Maybe HtmlId
    -> Maybe ( Range, SelectionDirection )
    -> LoadedFrontend
    -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg_ )
selectionChanged maybeHtmlId maybeRange model =
    case ( maybeHtmlId, maybeRange ) of
        ( Just htmlId, Just ( range, direction ) ) ->
            case model.loginStatus of
                LoggedIn loggedIn ->
                    let
                        local =
                            Local.model loggedIn.localState

                        showDropdown : Bool
                        showDropdown =
                            ((htmlId == Pages.Guild.channelTextInputId) || (htmlId == MessageMenu.editMessageTextInputId))
                                && (case Route.toGuildOrDmId local.localUser.session.userId model.route of
                                        Just ( guildOrDmId, threadRoute ) ->
                                            case FrontendExtra.pingUserNameSoFar htmlId range guildOrDmId threadRoute loggedIn of
                                                Just (NameSoFar nameSoFar) ->
                                                    case guildOrDmId of
                                                        GuildOrDmId guildOrDmId2 ->
                                                            MessageDropdown.userDropdownList
                                                                (MyUi.isMobile model)
                                                                nameSoFar
                                                                guildOrDmId2
                                                                local
                                                                |> List.isEmpty
                                                                |> not

                                                        DiscordGuildOrDmId guildOrDmId2 ->
                                                            MessageDropdown.discordUserDropdownList
                                                                (MyUi.isMobile model)
                                                                nameSoFar
                                                                guildOrDmId2
                                                                local
                                                                |> List.isEmpty
                                                                |> not

                                                Just (EmojiSoFar emojiSoFar) ->
                                                    case model.emojiData of
                                                        Just emojiData2 ->
                                                            let
                                                                ( availableCustomEmojis, availableStickers ) =
                                                                    MessageMenu.availableCustomEmojisAndStickers
                                                                        guildOrDmId
                                                                        local
                                                            in
                                                            MessageDropdown.emojiDropdownList
                                                                (MyUi.isMobile model)
                                                                emojiSoFar
                                                                availableCustomEmojis
                                                                availableStickers
                                                                local.localUser
                                                                emojiData2
                                                                |> List.isEmpty
                                                                |> not

                                                        Nothing ->
                                                            False

                                                Just (TimestampSoFar _ _) ->
                                                    True

                                                Nothing ->
                                                    False

                                        Nothing ->
                                            False
                                   )
                    in
                    ( { model
                        | loginStatus =
                            { loggedIn
                                | textInputFocus =
                                    case loggedIn.textInputFocus of
                                        Just textInputFocus ->
                                            if htmlId == textInputFocus.htmlId then
                                                { textInputFocus
                                                    | selection = range
                                                    , dropdown =
                                                        if showDropdown then
                                                            textInputFocus.dropdown

                                                        else
                                                            Nothing
                                                }
                                                    |> Just

                                            else
                                                Just
                                                    { htmlId = htmlId
                                                    , selection = range
                                                    , direction = direction
                                                    , dropdown = Nothing
                                                    }

                                        Nothing ->
                                            Just
                                                { htmlId = htmlId
                                                , selection = range
                                                , direction = direction
                                                , dropdown = Nothing
                                                }
                                , previousTextInputFocus = loggedIn.textInputFocus
                                , drawingMode = Drawing.NoSelectedAnchor
                            }
                                |> LoggedIn
                      }
                    , Command.batch
                        [ if showDropdown then
                            Dom.getElement htmlId
                                |> Task.map (\{ element } -> { dropdownIndex = 0, inputElement = element })
                                |> Task.attempt (GotPingUserPosition htmlId)

                          else
                            Command.none
                        , case Route.toGuildOrDmId local.localUser.session.userId model.route of
                            Just guildOrDmId ->
                                if htmlId == Pages.Guild.channelTextInputId then
                                    case SeqDict.get guildOrDmId loggedIn.drafts of
                                        Just draft ->
                                            case
                                                adjustSelection
                                                    (Maybe.map .selection loggedIn.textInputFocus)
                                                    range
                                                    (String.Nonempty.toString draft)
                                            of
                                                Just range2 ->
                                                    Ports.execCommand { htmlId = htmlId, commands = [ Ports.SelectRange range2 direction ] }

                                                Nothing ->
                                                    Command.none

                                        Nothing ->
                                            Command.none

                                else if htmlId == MessageMenu.editMessageTextInputId then
                                    case SeqDict.get guildOrDmId loggedIn.editMessage of
                                        Just edit ->
                                            case adjustSelection (Maybe.map .selection loggedIn.textInputFocus) range edit.text of
                                                Just range2 ->
                                                    Ports.execCommand { htmlId = htmlId, commands = [ Ports.SelectRange range2 direction ] }

                                                Nothing ->
                                                    Command.none

                                        Nothing ->
                                            Command.none

                                else
                                    Command.none

                            Nothing ->
                                Command.none
                        ]
                    )

                NotLoggedIn notLoggedIn ->
                    ( { model
                        | loginStatus =
                            NotLoggedIn { notLoggedIn | textInputFocus = Just { htmlId = htmlId, selection = range, direction = direction } }
                      }
                    , Command.none
                    )

        _ ->
            ( model, Command.none )


adjustSelection : Maybe Range -> Range -> String -> Maybe Range
adjustSelection selectionOld selection text =
    let
        selectionOld2 : Range
        selectionOld2 =
            Maybe.withDefault { start = 0, end = 0 } selectionOld
    in
    List.Extra.findMap
        (\( stickerRange, maybeStickerId ) ->
            case maybeStickerId of
                Just _ ->
                    if selection.start == selection.end then
                        if Range.inside selection.start stickerRange then
                            if selection.start < selectionOld2.start then
                                Just { start = stickerRange.start, end = stickerRange.start }

                            else
                                Just { start = stickerRange.end, end = stickerRange.end }

                        else
                            Nothing

                    else if Range.inside selection.start stickerRange then
                        Just { start = stickerRange.start, end = selection.end }
                        {- The commented out code fixes an issue where you can't reduce the text selection using shift+arrows.
                           Unfortunately this fix makes it so selecting text via mouse or touch becomes unstable.
                           Since reducing text selection with shift+arrows is a narrow use case, that's the bug we're leaving in.
                           Both can be handled by tracking if the user is currently using the keyboard vs mouse/touch but that's a low priority feature.
                        -}
                        --if selection.start < selectionOld2.start then
                        --    Just { start = stickerRange.start, end = selection.end }
                        --
                        --else
                        --    Just { start = stickerRange.end, end = selection.end }

                    else if Range.inside selection.end stickerRange then
                        Just { start = selection.start, end = stickerRange.end }
                        --if selection.end < selectionOld2.end then
                        --    Just { start = selection.start, end = stickerRange.start }
                        --
                        --else
                        --    Just { start = selection.start, end = stickerRange.end }

                    else
                        Nothing

                Nothing ->
                    Nothing
        )
        (RichText.stringToStickersAndCustomEmojis text)


textInputFocusChanged : Maybe HtmlId -> Maybe ( Range, SelectionDirection ) -> LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg_ )
textInputFocusChanged maybeHtmlId maybeSelection model =
    case model.loginStatus of
        LoggedIn loggedIn ->
            ( { model
                | virtualKeyboardOpen = False
                , loginStatus =
                    LoggedIn
                        { loggedIn
                            | textInputFocus =
                                case maybeHtmlId of
                                    Just htmlId ->
                                        case maybeSelection of
                                            Just ( range, direction ) ->
                                                { htmlId = htmlId, selection = range, direction = direction, dropdown = Nothing }
                                                    |> Just

                                            Nothing ->
                                                Nothing

                                    Nothing ->
                                        Nothing
                            , previousTextInputFocus = loggedIn.textInputFocus
                        }
              }
            , case maybeHtmlId of
                Just htmlId ->
                    Command.batch
                        [ if UserAgent.isDesktop model.startupData.userAgent.device || Maybe.map .htmlId loggedIn.textInputFocus == Just htmlId then
                            Command.none

                          else
                            Ports.fixCursorPosition htmlId
                        , if htmlId == UserOptions.discordBookmarkletId then
                            Ports.textInputSelectAll htmlId

                          else
                            Command.none
                        ]

                Nothing ->
                    Command.none
            )

        NotLoggedIn notLoggedIn ->
            ( { model
                | virtualKeyboardOpen = False
                , loginStatus =
                    NotLoggedIn
                        { notLoggedIn
                            | textInputFocus =
                                case maybeHtmlId of
                                    Just htmlId ->
                                        case maybeSelection of
                                            Just ( range, direction ) ->
                                                { htmlId = htmlId, selection = range, direction = direction }
                                                    |> Just

                                            Nothing ->
                                                Nothing

                                    Nothing ->
                                        Nothing
                        }
              }
            , Command.none
            )


setShowMembers : ShowChannelSettings -> LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg_ )
setShowMembers showMembers model =
    case model.route of
        GuildRoute guildId (ChannelRoute channelId threadRoute tab) channelsVisible ->
            case threadRoute of
                NoThreadWithFriends a _ ->
                    FrontendExtra.routePush
                        model
                        (GuildRoute
                            guildId
                            (ChannelRoute channelId (NoThreadWithFriends a showMembers) tab)
                            channelsVisible
                        )

                ViewThreadWithFriends threadId a _ ->
                    FrontendExtra.routePush
                        model
                        (GuildRoute
                            guildId
                            (ChannelRoute channelId (ViewThreadWithFriends threadId a showMembers) tab)
                            channelsVisible
                        )

        GuildRoute _ _ _ ->
            ( model, Command.none )

        DmRoute dmRoute ->
            case dmRoute.threadRoute of
                NoThreadWithFriends a _ ->
                    FrontendExtra.routePush model (DmRoute { dmRoute | threadRoute = NoThreadWithFriends a showMembers })

                ViewThreadWithFriends threadId a _ ->
                    FrontendExtra.routePush
                        model
                        (DmRoute { dmRoute | threadRoute = ViewThreadWithFriends threadId a showMembers })

        DiscordGuildRoute guildRoute ->
            case guildRoute.channelRoute of
                DiscordChannel_ChannelRoute channelId threadRoute tab ->
                    (case threadRoute of
                        NoThreadWithFriends a _ ->
                            { guildRoute
                                | channelRoute =
                                    DiscordChannel_ChannelRoute channelId (NoThreadWithFriends a showMembers) tab
                            }

                        ViewThreadWithFriends threadId a _ ->
                            { guildRoute
                                | channelRoute =
                                    DiscordChannel_ChannelRoute channelId (ViewThreadWithFriends threadId a showMembers) tab
                            }
                    )
                        |> DiscordGuildRoute
                        |> FrontendExtra.routePush model

                _ ->
                    ( model, Command.none )

        DiscordDmRoute dmRoute ->
            FrontendExtra.routePush model (DiscordDmRoute { dmRoute | showMembersTab = showMembers })

        HomePageRoute ->
            ( model, Command.none )

        AdminRoute _ ->
            ( model, Command.none )

        NewGuildRoute ->
            ( model, Command.none )

        AiChatRoute ->
            ( model, Command.none )

        SlackOAuthRedirect _ ->
            ( model, Command.none )

        TextEditorRoute ->
            ( model, Command.none )

        LinkDiscord _ ->
            ( model, Command.none )

        PublicGoMatchRoute _ ->
            ( model, Command.none )


viewImageInfo :
    ( AnyGuildOrDmId, ThreadRoute )
    -> Id FileId
    -> LoadedFrontend
    -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg_ )
viewImageInfo guildOrDmId fileId model =
    FrontendExtra.updateLoggedIn
        (\loggedIn ->
            ( { loggedIn
                | showFileToUploadInfo =
                    case SeqDict.get guildOrDmId loggedIn.filesToUpload of
                        Just nonemptyDict ->
                            case NonemptyDict.get fileId nonemptyDict of
                                Just (FileStatus.FileUploaded fileData) ->
                                    case fileData.metadata of
                                        Just metadata ->
                                            { fileName = fileData.fileName
                                            , fileSize = fileData.fileSize
                                            , metadata = metadata
                                            , contentType = fileData.contentType
                                            , fileHash = fileData.fileHash
                                            }
                                                |> Just

                                        Nothing ->
                                            Nothing

                                _ ->
                                    Nothing

                        Nothing ->
                            Nothing
              }
            , Command.none
            )
        )
        model


{-| The message ahead of the given one. Marking a message as unread means the last message
that was read is the one before it, and -1 stands for nothing having been read at all, the
same value a conversation that was never opened falls back to.
-}
messageBefore : Id messageId -> Id messageId
messageBefore messageId =
    Id.toInt messageId - 1 |> Id.fromInt


handleEditable :
    Editable.Msg value
    -> (UserOptionsModel -> Editable.Model -> UserOptionsModel)
    -> (value -> LoggedIn2 -> ( LoggedIn2, Command FrontendOnly ToBackend FrontendMsg_ ))
    -> LoadedFrontend
    -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg_ )
handleEditable editableMsg setter acceptEdit model =
    FrontendExtra.updateLoggedIn
        (\loggedIn ->
            case loggedIn.userOptions of
                Just userOptions ->
                    case editableMsg of
                        Editable.Edit editable ->
                            ( { loggedIn | userOptions = setter userOptions editable |> Just }
                            , Command.none
                            )

                        Editable.PressedAcceptEdit value ->
                            acceptEdit value { loggedIn | userOptions = setter userOptions Editable.init |> Just }

                Nothing ->
                    ( loggedIn, Command.none )
        )
        model


pressedReply : AnyGuildOrDmId -> ThreadRouteWithMessage -> LoggedIn2 -> LoadedFrontend -> ( LoggedIn2, Command FrontendOnly ToBackend FrontendMsg_ )
pressedReply guildOrDmId threadRoute loggedIn model =
    ( MessageMenu.close
        model
        { loggedIn
            | replyTo =
                SeqDict.insert
                    ( guildOrDmId, Id.threadRouteWithoutMessage threadRoute )
                    (Id.threadRouteToMessageId threadRoute)
                    loggedIn.replyTo
        }
    , Command.batch
        [ FrontendExtra.setFocus model Pages.Guild.channelTextInputId
        , Scroll.toBottomOfChannelIfAtBottom Pages.Guild.conversationContainerId SetScrollToBottom loggedIn.channelScrollPosition
        ]
    )


pressedEditMessage : AnyGuildOrDmId -> ThreadRouteWithMessage -> LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg_ )
pressedEditMessage guildOrDmId threadRoute model =
    FrontendExtra.updateLoggedIn
        (\loggedIn ->
            let
                local : LocalState
                local =
                    Local.model loggedIn.localState

                maybeContentAndFiles : Maybe ( String, SeqDict (Id FileId) FileData )
                maybeContentAndFiles =
                    case guildOrDmId of
                        GuildOrDmId guildOrDmId2 ->
                            case LocalState.guildOrDmIdToMessage guildOrDmId2 threadRoute local of
                                Just ( message, _ ) ->
                                    ( RichText.toString local.localUser.timezone False (User.allUsers local.localUser) message.content
                                    , message.attachedFiles
                                    )
                                        |> Just

                                Nothing ->
                                    Nothing

                        DiscordGuildOrDmId guildOrDmId2 ->
                            case LocalState.discordGuildOrDmIdToMessage guildOrDmId2 threadRoute local of
                                Just ( message, _ ) ->
                                    ( RichText.toString
                                        local.localUser.timezone
                                        False
                                        (LinkedAndOtherDiscordUsers.allDiscordUsers local.localUser.discordUsers)
                                        message.content
                                    , message.attachedFiles
                                    )
                                        |> Just

                                Nothing ->
                                    Nothing
            in
            ( case maybeContentAndFiles of
                Just ( content, attachedFiles ) ->
                    let
                        loggedIn2 =
                            { loggedIn
                                | editMessage =
                                    SeqDict.insert
                                        ( guildOrDmId, Id.threadRouteWithoutMessage threadRoute )
                                        { messageIndex = Id.threadRouteToMessageId threadRoute
                                        , text = content
                                        , attachedFiles = SeqDict.map (\_ a -> FileUploaded a) attachedFiles
                                        }
                                        loggedIn.editMessage
                            }
                    in
                    { loggedIn2
                        | messageHover =
                            if MyUi.isMobile model then
                                case loggedIn2.messageHover of
                                    NoMessageHover ->
                                        loggedIn2.messageHover

                                    MessageHover _ _ ->
                                        loggedIn2.messageHover

                                    MessageMenu extraOptions ->
                                        { extraOptions
                                            | mobileMode =
                                                { offset = Types.messageMenuMobileOffset extraOptions.mobileMode
                                                , targetOffset = MessageMenu.mobileMenuMaxHeight extraOptions local model
                                                }
                                                    |> MessageMenuOpening
                                        }
                                            |> MessageMenu

                            else
                                NoMessageHover
                    }

                Nothing ->
                    loggedIn
            , Command.batch
                [ FrontendExtra.setFocus model MessageMenu.editMessageTextInputId
                , Scroll.toBottomOfChannelIfAtBottom Pages.Guild.conversationContainerId SetScrollToBottom loggedIn.channelScrollPosition
                ]
            )
        )
        model


{-| An emoji picked out of the selector for one of the answers or notes on a sheep game's
results screen.
-}
addSheepGameReaction :
    GuildOrDmId
    -> Id Id.ChannelMessageId
    -> SheepGame.ReactionTarget
    -> EmojiOrCustomEmoji
    -> LoadedFrontend
    -> LoggedIn2
    -> ( LoggedIn2, Command FrontendOnly ToBackend FrontendMsg_ )
addSheepGameReaction guildOrDmId matchId target emoji model loggedIn =
    FrontendExtra.handleLocalChange
        model.time
        (SheepGame.Action
            { userId = (Local.model loggedIn.localState).localUser.session.userId
            , time = model.time
            , change = SheepGame.AddedReaction target emoji
            }
            |> Game.LocalChange_SheepGame matchId
            |> Local_Game guildOrDmId
            |> Just
        )
        { loggedIn | showEmojiSelector = EmojiSelectorHidden }
        Command.none


showReactionEmojiSelector : AnyGuildOrDmId -> ThreadRouteWithMessage -> LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg_ )
showReactionEmojiSelector guildOrDmId messageIndex model =
    FrontendExtra.updateLoggedIn
        (\loggedIn ->
            let
                emojiSelectorModel =
                    loggedIn.emojiSelector
            in
            ( { loggedIn
                | showEmojiSelector =
                    case loggedIn.showEmojiSelector of
                        EmojiSelectorHidden ->
                            EmojiSelectorForReaction guildOrDmId messageIndex

                        EmojiSelectorForReaction _ _ ->
                            EmojiSelectorHidden

                        EmojiSelectorForMessage _ ->
                            EmojiSelectorHidden

                        EmojiSelectorForEditMessage _ _ ->
                            EmojiSelectorHidden

                        EmojiSelectorForSheepGameReaction _ _ _ ->
                            EmojiSelectorHidden

                        EmojiSelectorForSheepGameInput _ _ _ ->
                            EmojiSelectorHidden
                , emojiSelector = { emojiSelectorModel | searchText = "", category = Emoji.selectorInit.category }
              }
                |> MessageMenu.close model
            , if MyUi.isMobile model then
                Command.none

              else
                Dom.focus Emoji.searchInputId |> Task.attempt (\_ -> SetFocus)
            )
        )
        model


touchStart :
    Maybe ( AnyGuildOrDmId, ThreadRouteWithMessage, Bool )
    -> Maybe String
    -> Maybe String
    -> Time.Posix
    -> NonemptyDict Int Touch
    -> LoadedFrontend
    -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg_ )
touchStart maybeGuildOrDmIdAndMessageIndex maybeImageUrl maybeLinkUrl time touches model =
    case model.drag of
        NoDrag ->
            if isTouchingTextInput touches then
                ( model, Command.none )

            else
                ( { model | drag = DragStart time touches, dragPrevious = model.drag }
                , Command.batch
                    [ case NonemptyDict.toList touches of
                        [ _ ] ->
                            case maybeGuildOrDmIdAndMessageIndex of
                                Just ( guildOrMessageId, messageIndex, isThreadStarter ) ->
                                    Process.sleep (Duration.seconds 0.5)
                                        |> Task.perform
                                            (\() -> CheckMessageAltPress time guildOrMessageId messageIndex isThreadStarter maybeImageUrl maybeLinkUrl)

                                Nothing ->
                                    Command.none

                        _ ->
                            Command.none
                    , -- This is so the virtual keyboard gets hidden when we start dragging the channel sidebar
                      case ( model.loginStatus, MyUi.isMobile model ) of
                        ( LoggedIn loggedIn, True ) ->
                            case loggedIn.textInputFocus of
                                Just textInputFocus ->
                                    Dom.blur textInputFocus.htmlId |> Task.attempt (\_ -> RemoveFocus)

                                Nothing ->
                                    Command.none

                        _ ->
                            Command.none
                    ]
                )

        DragStart _ _ ->
            ( model, Command.none )

        Dragging _ ->
            ( model, Command.none )


handleAltPressedMessage : AnyGuildOrDmId -> ThreadRouteWithMessage -> Bool -> Maybe String -> Maybe String -> Coord CssPixels -> LoggedIn2 -> LocalState -> LoadedFrontend -> LoggedIn2
handleAltPressedMessage guildOrDmId threadRoute isThreadStarter maybeImageUrl maybeLinkUrl clickedAt loggedIn local model =
    { loggedIn
        | messageHover =
            MessageMenu
                { guildOrDmId = guildOrDmId
                , threadRoute = threadRoute
                , isThreadStarter = isThreadStarter
                , position = clickedAt
                , imageUrl = maybeImageUrl
                , linkUrl = maybeLinkUrl
                , mobileMode =
                    MessageMenuOpening
                        { offset = Quantity.zero
                        , targetOffset =
                            MessageMenu.mobileMenuOpeningOffset
                                guildOrDmId
                                threadRoute
                                local
                                model
                        }
                }
    }


handleTouchEnd : Time.Posix -> LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg_ )
handleTouchEnd time model =
    FrontendExtra.updateLoggedIn
        (\loggedIn ->
            let
                loggedIn2 : LoggedIn2
                loggedIn2 =
                    case loggedIn.sidebarMode of
                        ChannelSidebarDragging a ->
                            { loggedIn | sidebarMode = ChannelSidebarNotDragging { offset = a.offset } }

                        ChannelSidebarNotDragging _ ->
                            loggedIn

                ( loggedIn3, cmds ) =
                    finalizeWordSpellingDrag
                        time
                        model
                        (case loggedIn2.messageHover of
                            MessageMenu extraOptions ->
                                case extraOptions.mobileMode of
                                    MessageMenuDragging dragging ->
                                        let
                                            delta : Duration
                                            delta =
                                                Duration.from dragging.time time

                                            menuDelta : Quantity Float (Rate CssPixels Seconds)
                                            menuDelta =
                                                dragging.offset
                                                    |> Quantity.minus dragging.previousOffset
                                                    |> Quantity.per delta

                                            speedThreshold : Quantity Float (Rate CssPixels Seconds)
                                            speedThreshold =
                                                Quantity.rate (CssPixels.cssPixels -100) Duration.second

                                            menuHeight : Quantity Float CssPixels
                                            menuHeight =
                                                MessageMenu.mobileMenuMaxHeight
                                                    extraOptions
                                                    (Local.model loggedIn2.localState)
                                                    model

                                            halfwayPoint : Quantity Float CssPixels
                                            halfwayPoint =
                                                menuHeight |> Quantity.divideBy 2
                                        in
                                        if
                                            (dragging.offset |> Quantity.lessThan halfwayPoint)
                                                || (menuDelta |> Quantity.lessThan speedThreshold)
                                        then
                                            MessageMenu.close model loggedIn2

                                        else
                                            { loggedIn2
                                                | messageHover =
                                                    MessageMenu
                                                        { extraOptions
                                                            | mobileMode =
                                                                MessageMenuFixed
                                                                    (Quantity.min menuHeight dragging.offset)
                                                        }
                                            }

                                    _ ->
                                        loggedIn2

                            NoMessageHover ->
                                loggedIn2

                            MessageHover _ _ ->
                                loggedIn2
                        )
            in
            ( loggedIn3
            , Command.batch
                [ Process.sleep (Duration.milliseconds 30) |> Task.perform (\() -> OneFrameAfterDragEnd)
                , cmds
                ]
            )
        )
        { model | drag = NoDrag, dragPrevious = model.drag }
        |> (\( newModel, cmd ) ->
                case releasedSidebarDrag time model of
                    Just route ->
                        if route == newModel.route then
                            ( newModel, cmd )

                        else
                            FrontendExtra.routePush newModel route
                                |> Tuple.mapSecond (\routeCmd -> Command.batch [ cmd, routeCmd ])

                    Nothing ->
                        ( newModel, cmd )
           )


{-| Which of the two screens a swipe lands on once it's let go of. A fast enough flick
decides it on its own, otherwise whichever side of half way it was left on does. Nothing
when the swipe wasn't the sidebar.
-}
releasedSidebarDrag : Time.Posix -> LoadedFrontend -> Maybe Route
releasedSidebarDrag time model =
    case model.loginStatus of
        LoggedIn loggedIn ->
            case loggedIn.sidebarMode of
                ChannelSidebarDragging a ->
                    let
                        range : { min : Float, max : Float }
                        range =
                            channelSidebarDragRange model.route

                        sidebarDelta : Quantity Float (Rate CssPixels Seconds)
                        sidebarDelta =
                            a.offset
                                - a.previousOffset
                                |> (*) (toFloat (Coord.xRaw model.windowSize))
                                |> CssPixels.cssPixels
                                |> Quantity.per (Duration.from a.time time)

                        landsOnTheNearSide : Bool
                        landsOnTheNearSide =
                            (sidebarDelta |> Quantity.lessThan (Quantity.unsafe -100))
                                || ((a.offset < range.min + 0.5)
                                        && (sidebarDelta |> Quantity.lessThan (Quantity.unsafe 100))
                                   )
                    in
                    (case Route.toShowMembersTab model.route of
                        ( ShowChannelSettings, _ ) ->
                            if landsOnTheNearSide then
                                model.route

                            else
                                Route.setShowMembers HideChannelSettings model.route

                        ( HideChannelSettings, _ ) ->
                            Route.setChannelsVisible
                                (if landsOnTheNearSide then
                                    ChannelsHiddenOnMobile

                                 else
                                    ChannelsVisibleOnMobile
                                )
                                model.route
                    )
                        |> Just

                ChannelSidebarNotDragging _ ->
                    Nothing

        NotLoggedIn _ ->
            Nothing


finalizeWordSpellingDrag : Time.Posix -> LoadedFrontend -> LoggedIn2 -> ( LoggedIn2, Command FrontendOnly ToBackend FrontendMsg_ )
finalizeWordSpellingDrag time model loggedIn =
    case model.drag of
        Dragging dragging ->
            case dragging.target of
                Drag_Game ->
                    case FrontendExtra.currentGame (Local.model loggedIn.localState) model of
                        Just { guildOrDmId, matchId, match } ->
                            case SeqDict.get guildOrDmId loggedIn.games of
                                Just game ->
                                    let
                                        ( game2, outMsg ) =
                                            Game.dragEnd
                                                time
                                                model.windowSize
                                                (Local.model loggedIn.localState).localUser.session.userId
                                                (Touch.removeSafeAreaTopInset
                                                    model.startupData.safeAreaInsetTop
                                                    dragging.touches
                                                )
                                                matchId
                                                match
                                                game
                                    in
                                    FrontendExtra.handleLocalChange
                                        model.time
                                        (Maybe.map (Local_Game guildOrDmId) outMsg)
                                        { loggedIn | games = SeqDict.insert guildOrDmId game2 loggedIn.games }
                                        Command.none

                                Nothing ->
                                    ( loggedIn, Command.none )

                        Nothing ->
                            ( loggedIn, Command.none )

                _ ->
                    ( loggedIn, Command.none )

        _ ->
            ( loggedIn, Command.none )


dragTarget : NonemptyDict Int Touch -> LoadedFrontend -> Maybe DragTarget
dragTarget startTouches model =
    case model.loginStatus of
        LoggedIn loggedIn ->
            case loggedIn.drawingMode of
                -- A finger drawing a stroke would otherwise drag the channel sidebar
                -- along with it
                Drawing.SelectedAnchor _ ->
                    Nothing

                Drawing.NoSelectedAnchor ->
                    dragTargetHelper startTouches loggedIn model

        NotLoggedIn _ ->
            Nothing


dragTargetHelper : NonemptyDict Int Touch -> LoggedIn2 -> LoadedFrontend -> Maybe DragTarget
dragTargetHelper startTouches loggedIn model =
    let
        isMobile =
            MyUi.isMobile model

        local : LocalState
        local =
            Local.model loggedIn.localState

        centroid : Coord CssPixels
        centroid =
            Touch.touchCentroid startTouches

        insideBoard : Bool
        insideBoard =
            case FrontendExtra.currentGame local model of
                Just { guildOrDmId, match, matchId } ->
                    -- The board is laid out below the safe-area inset, so undo it before the
                    -- hit-test (the call thumbnail above is positioned including the inset, so
                    -- its check keeps the raw centroid).
                    Game.insideBoard
                        model.windowSize
                        (Touch.touchCentroid (Touch.removeSafeAreaTopInset model.startupData.safeAreaInsetTop startTouches))
                        guildOrDmId
                        matchId
                        match
                        loggedIn.games

                Nothing ->
                    False
    in
    case Call.displayMode (MyUi.isMobile model) local.localUser.session.userId model.route local.calls of
        Call.ShowLocalVideoAndCallThumbnail _ ->
            if Call.insideThumbnail centroid model loggedIn.voiceChat then
                Just Drag_CallThumbnail

            else if insideBoard then
                Just Drag_Game

            else if isMobile then
                Just Drag_Channel

            else
                Nothing

        _ ->
            if insideBoard then
                Just Drag_Game

            else if isMobile then
                Just Drag_Channel

            else
                Nothing


dragChannelSidebar : { min : Float, max : Float } -> Time.Posix -> Float -> ChannelSidebarMode -> ChannelSidebarMode
dragChannelSidebar range time delta sidebar =
    case sidebar of
        ChannelSidebarNotDragging { offset } ->
            ChannelSidebarDragging
                { offset = clamp range.min range.max (offset + delta)
                , previousOffset = offset
                , time = time
                }

        ChannelSidebarDragging record ->
            ChannelSidebarDragging
                { record | offset = clamp range.min range.max (record.offset + delta), time = time }


isTouchingTextInput : NonemptyDict Int Touch -> Bool
isTouchingTextInput touches =
    NonemptyDict.any
        (\_ touch ->
            (touch.target == Just MessageMenu.editMessageTextInputId)
                || (touch.target == Just Pages.Guild.channelTextInputId)
        )
        touches


{-| Back out of whichever of the three mobile screens the reader is on: the member column
gives way to the conversation view, and the conversation view to the guild's channel list.
Where it's heading lives in the route, so this is a route change and the offset slides its
way there on its own.
-}
startClosingChannelSidebar : LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg_ )
startClosingChannelSidebar model =
    case Route.toShowMembersTab model.route of
        ( ShowChannelSettings, _ ) ->
            setShowMembers HideChannelSettings model

        ( HideChannelSettings, _ ) ->
            FrontendExtra.routePush model (Route.setChannelsVisible ChannelsVisibleOnMobile model.route)


{-| Which of the three screens the mobile layout is heading for: the member column at 0,
the conversation view at 1, or the guild's channel list at 2.
-}
channelSidebarTarget : Route -> Float
channelSidebarTarget route =
    case Route.toShowMembersTab route of
        ( ShowChannelSettings, _ ) ->
            0

        ( HideChannelSettings, _ ) ->
            let
                helper channelsVisible =
                    case channelsVisible of
                        ChannelsVisibleOnMobile ->
                            2

                        ChannelsHiddenOnMobile ->
                            1
            in
            case route of
                GuildRoute _ _ channelsVisible ->
                    helper channelsVisible

                DiscordGuildRoute routeData ->
                    helper routeData.channelsVisible

                HomePageRoute ->
                    2

                AdminRoute _ ->
                    2

                NewGuildRoute ->
                    2

                DmRoute routeData ->
                    helper routeData.channelsVisible

                DiscordDmRoute routeData ->
                    helper routeData.channelsVisible

                AiChatRoute ->
                    2

                SlackOAuthRedirect _ ->
                    2

                TextEditorRoute ->
                    2

                LinkDiscord _ ->
                    2

                PublicGoMatchRoute _ ->
                    2



--case Route.toChannelsVisible route of
--    GuildChannelsHiddenOnMobile ->
--        1
--
--    GuildChannelsVisibleOnMobile ->
--        2


{-| A swipe only ever travels between the screen the route is on and the one next door, so
that letting go lands on one or the other.
-}
channelSidebarDragRange : Route -> { min : Float, max : Float }
channelSidebarDragRange route =
    case Route.toShowMembersTab route of
        ( ShowChannelSettings, _ ) ->
            { min = 0, max = 1 }

        ( HideChannelSettings, _ ) ->
            { min = 1, max = 2 }


sidebarSpeed : Quantity Float (Rate Unitless Seconds)
sidebarSpeed =
    Quantity.float 7 |> Quantity.per Duration.second


updateFromBackend :
    AudioData
    -> ToFrontend
    -> FrontendModel_
    -> ( FrontendModel_, Command FrontendOnly ToBackend FrontendMsg_, AudioCmd FrontendMsg_ )
updateFromBackend _ msg model =
    case model of
        Loading loading ->
            case msg of
                CheckLoginResponse loginType result ->
                    case result of
                        Ok loginData ->
                            tryInitLoadedFrontend
                                { loading | loginStatus = LoadSuccess loginData, loginType = loginType }

                        Err _ ->
                            tryInitLoadedFrontend
                                { loading | loginStatus = LoadError, loginType = loginType }

                YouConnected clientId ->
                    tryInitLoadedFrontend { loading | clientId = Just clientId }

                GetPublicGoMatchResponse result ->
                    tryInitLoadedFrontend
                        { loading
                            | publicGoMatch =
                                case result of
                                    Ok ok ->
                                        PublicGoMatch_Loaded
                                            { setup = ok.setup
                                            , actions = ok.actions
                                            , cache = Go.foldActions ok.setup ok.actions
                                            , creatorUser = ok.creatorUser
                                            , joinedUser = ok.joinedUser
                                            }
                                            Go.initGame

                                    Err () ->
                                        PublicGoMatch_Missing
                        }

                _ ->
                    ( model, Command.none, Audio.cmdNone )

        Loaded loaded ->
            let
                ( loaded2, cmds ) =
                    updateLoadedFromBackend
                        msg
                        (case loaded.toFrontendLogs of
                            Just logs ->
                                { loaded | toFrontendLogs = Array.push msg logs |> Just }

                            Nothing ->
                                loaded
                        )

                ( loaded3, badgeCmd ) =
                    checkAppBadgeChange loaded2
            in
            ( Loaded loaded3, Command.batch [ cmds, badgeCmd ], Audio.cmdNone )


updateLoadedFromBackend : ToFrontend -> LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg_ )
updateLoadedFromBackend msg model =
    case msg of
        CheckLoginResponse loginType _ ->
            ( { model | loginType = loginType }, Command.none )

        LoginWithTokenResponse result ->
            case model.loginStatus of
                NotLoggedIn notLoggedIn ->
                    case result of
                        LoginSuccess loginData ->
                            let
                                ( loggedIn, cmdA ) =
                                    loadedInitHelper model.startupData model.emojiData loginData model

                                ( model2, cmdB ) =
                                    FrontendExtra.routeRequest
                                        (Just model.route)
                                        model.route
                                        { model | loginStatus = LoggedIn loggedIn }
                            in
                            ( model2
                            , Command.batch
                                [ cmdA
                                , cmdB
                                , case ( model2.route, notLoggedIn.useInviteAfterLoggedIn ) of
                                    ( GuildRoute guildId _ _, Just inviteLinkId ) ->
                                        JoinGuildByInviteRequest guildId inviteLinkId
                                            |> Lamdera.sendToBackend

                                    _ ->
                                        Command.none
                                ]
                            )

                        LoginTokenInvalid loginCode ->
                            ( { model
                                | loginStatus =
                                    NotLoggedIn
                                        { notLoggedIn
                                            | loginForm =
                                                case notLoggedIn.loginForm of
                                                    Just loginForm ->
                                                        LoginForm.invalidCode loginCode loginForm |> Just

                                                    Nothing ->
                                                        Nothing
                                        }
                              }
                            , Command.none
                            )

                        NeedsTwoFactorToken ->
                            ( { model
                                | loginStatus =
                                    NotLoggedIn
                                        { notLoggedIn
                                            | loginForm =
                                                case notLoggedIn.loginForm of
                                                    Just loginForm ->
                                                        LoginForm.needsTwoFactor loginForm |> Just

                                                    Nothing ->
                                                        Nothing
                                        }
                              }
                            , Command.none
                            )

                        NeedsAccountSetup ->
                            ( { model
                                | loginStatus =
                                    NotLoggedIn
                                        { notLoggedIn | loginForm = Just LoginForm.needsUserData }
                              }
                            , Command.none
                            )

                        RecoveryPasswordInvalid ->
                            ( { model
                                | loginStatus =
                                    NotLoggedIn
                                        { notLoggedIn
                                            | recoveryLogin =
                                                RecoveryLogin.incorrectPassword notLoggedIn.recoveryLogin
                                        }
                              }
                            , Command.none
                            )

                LoggedIn _ ->
                    ( model, Command.none )

        LoggedOutSession ->
            FrontendExtra.logout model

        AdminToFrontend adminToFrontend ->
            case model.loginStatus of
                LoggedIn loggedIn ->
                    let
                        ( newAdmin, cmd ) =
                            Pages.Admin.updateFromBackend adminToFrontend loggedIn.admin
                    in
                    ( { model | loginStatus = LoggedIn { loggedIn | admin = newAdmin } }
                    , Command.map AdminToBackend AdminPageMsg cmd
                    )

                NotLoggedIn _ ->
                    ( model, Command.none )

        GetLoginTokenRateLimited ->
            case model.loginStatus of
                LoggedIn _ ->
                    ( model, Command.none )

                NotLoggedIn notLoggedIn ->
                    ( { model
                        | loginStatus =
                            NotLoggedIn
                                { notLoggedIn
                                    | loginForm =
                                        case notLoggedIn.loginForm of
                                            Just loginForm ->
                                                LoginForm.rateLimited loginForm |> Just

                                            Nothing ->
                                                Nothing
                                }
                      }
                    , Command.none
                    )

        SignupsDisabledResponse ->
            case model.loginStatus of
                LoggedIn _ ->
                    ( model, Command.none )

                NotLoggedIn notLoggedIn ->
                    ( { model
                        | loginStatus =
                            NotLoggedIn
                                { notLoggedIn
                                    | loginForm =
                                        case notLoggedIn.loginForm of
                                            Just loginForm ->
                                                LoginForm.signupsDisabled loginForm |> Just

                                            Nothing ->
                                                Nothing
                                }
                      }
                    , Command.none
                    )

        LocalChangeResponse changeId localChange ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    let
                        userId : Id UserId
                        userId =
                            (Local.model loggedIn.localState).localUser.session.userId

                        change : LocalMsg
                        change =
                            LocalChange userId localChange

                        localState : Local LocalMsg LocalState
                        localState =
                            Local.updateFromBackend FrontendExtra.changeUpdate (Just changeId) change loggedIn.localState

                        local : LocalState
                        local =
                            Local.model localState
                    in
                    ( { loggedIn
                        | localState = localState
                        , games =
                            case localChange of
                                -- The match has arrived, so there's finally something for the
                                -- view state that goes with it to be built from.
                                Local_Game guildOrDmId (Game.LoadMatch matchId (FilledInByBackend _)) ->
                                    Game.routeRequest
                                        model.time
                                        local.localUser
                                        guildOrDmId
                                        matchId
                                        (FrontendExtra.channelGames guildOrDmId local)
                                        loggedIn.games

                                _ ->
                                    loggedIn.games
                      }
                    , case localChange of
                        Local_Game guildOrDmId game ->
                            case game of
                                Game.CreatePublicLink _ _ ->
                                    Command.none

                                Game.LoadMatch matchId (FilledInByBackend _) ->
                                    case FrontendExtra.currentGamesTab local model.route of
                                        Just gamesTab ->
                                            if gamesTab.guildOrDmId == guildOrDmId && gamesTab.maybeMatchId == Just matchId then
                                                Scroll.toBottomOfChannelIfAtBottom
                                                    WordSpellingGame.pastWordsContainerId
                                                    SetScrollToBottom
                                                    ScrolledToBottom

                                            else
                                                Command.none

                                        Nothing ->
                                            Command.none

                                Game.LoadMatch _ EmptyPlaceholder ->
                                    Command.none

                                Game.LocalChange_Go _ _ ->
                                    Command.none

                                Game.LocalChange_WordSpellingGame _ _ ->
                                    Command.none

                                Game.LocalChange_SheepGame _ _ ->
                                    Command.none

                        Local_VoiceChatChange callChange ->
                            case callChange of
                                Call.Local_Leave _ ->
                                    Command.none

                                Call.Local_SetRemoteCallData _ ->
                                    Command.none

                        Local_TextEditor TextEditor.Local_Undo ->
                            case SeqDict.get local.localUser.session.userId local.textEditor.cursorPosition of
                                Just range ->
                                    Ports.setCursorPosition TextEditor.inputId range

                                Nothing ->
                                    Command.none

                        Local_NewGuild _ _ (FilledInByBackend guildId) ->
                            case SeqDict.get guildId local.guilds of
                                Just guild ->
                                    FrontendExtra.routeReplace
                                        model
                                        (GuildRoute
                                            guildId
                                            (ChannelRoute
                                                (LocalState.announcementChannel guild)
                                                (NoThreadWithFriends Nothing HideChannelSettings)
                                                Nothing
                                            )
                                            ChannelsHiddenOnMobile
                                        )

                                Nothing ->
                                    Command.none

                        Local_CurrentlyViewing _ viewing ->
                            case viewing of
                                ViewChannel data _ ->
                                    case Route.toGuildOrDmId userId model.route of
                                        Just ( GuildOrDmId (GuildOrDmId_Guild { guildId, channelId }), NoThread ) ->
                                            if data.id.guildId == guildId && data.id.channelId == channelId then
                                                Scroll.toBottomOfChannelIfAtBottom Pages.Guild.conversationContainerId SetScrollToBottom loggedIn.channelScrollPosition

                                            else
                                                Command.none

                                        _ ->
                                            Command.none

                                ViewDm data _ ->
                                    case Route.toGuildOrDmId userId model.route of
                                        Just ( GuildOrDmId (GuildOrDmId_Dm { otherUserId }), NoThread ) ->
                                            if data.id.otherUserId == otherUserId then
                                                Scroll.toBottomOfChannelIfAtBottom Pages.Guild.conversationContainerId SetScrollToBottom loggedIn.channelScrollPosition

                                            else
                                                Command.none

                                        _ ->
                                            Command.none

                                ViewChannelThread data _ ->
                                    case Route.toGuildOrDmId userId model.route of
                                        Just ( GuildOrDmId (GuildOrDmId_Guild { guildId, channelId }), ViewThread threadIdRoute ) ->
                                            if data.id.guildId == guildId && data.id.channelId == channelId && data.id.threadId == threadIdRoute then
                                                Scroll.toBottomOfChannelIfAtBottom Pages.Guild.conversationContainerId SetScrollToBottom loggedIn.channelScrollPosition

                                            else
                                                Command.none

                                        _ ->
                                            Command.none

                                ViewDmThread data _ ->
                                    case Route.toGuildOrDmId userId model.route of
                                        Just ( GuildOrDmId (GuildOrDmId_Dm { otherUserId }), ViewThread threadIdRoute ) ->
                                            if data.id.otherUserId == otherUserId && data.id.threadId == threadIdRoute then
                                                Scroll.toBottomOfChannelIfAtBottom Pages.Guild.conversationContainerId SetScrollToBottom loggedIn.channelScrollPosition

                                            else
                                                Command.none

                                        _ ->
                                            Command.none

                                StopViewingChannel ->
                                    Command.none

                                ViewDiscordChannel data _ ->
                                    case Route.toGuildOrDmId userId model.route of
                                        Just ( DiscordGuildOrDmId (DiscordGuildOrDmId_Guild { currentUserId, guildId, channelId }), NoThread ) ->
                                            if data.id.currentUserId == currentUserId && data.id.guildId == guildId && data.id.channelId == channelId then
                                                Scroll.toBottomOfChannelIfAtBottom Pages.Guild.conversationContainerId SetScrollToBottom loggedIn.channelScrollPosition

                                            else
                                                Command.none

                                        _ ->
                                            Command.none

                                ViewDiscordChannelThread data _ ->
                                    case Route.toGuildOrDmId userId model.route of
                                        Just ( DiscordGuildOrDmId (DiscordGuildOrDmId_Guild { currentUserId, guildId, channelId }), ViewThread threadIdRoute ) ->
                                            if data.id.currentUserId == currentUserId && data.id.guildId == guildId && data.id.channelId == channelId && data.id.threadId == threadIdRoute then
                                                Scroll.toBottomOfChannelIfAtBottom Pages.Guild.conversationContainerId SetScrollToBottom loggedIn.channelScrollPosition

                                            else
                                                Command.none

                                        _ ->
                                            Command.none

                                ViewDiscordDm data _ ->
                                    case Route.toGuildOrDmId userId model.route of
                                        Just ( DiscordGuildOrDmId (DiscordGuildOrDmId_Dm dmRoute), NoThread ) ->
                                            if data.id.channelId == dmRoute.channelId then
                                                Scroll.toBottomOfChannelIfAtBottom Pages.Guild.conversationContainerId SetScrollToBottom loggedIn.channelScrollPosition

                                            else
                                                Command.none

                                        _ ->
                                            Command.none

                                ViewOverview _ ->
                                    Command.none

                        Local_LoadChannelMessages _ previousOldestVisibleMessage (FilledInByBackend messagesLoaded) ->
                            if SeqDict.isEmpty messagesLoaded then
                                Command.none

                            else
                                Ports.shiftScrollByElementDelta
                                    Pages.Guild.conversationContainerId
                                    (Pages.Guild.channelMessageHtmlId previousOldestVisibleMessage)

                        Local_LoadThreadMessages _ _ previousOldestVisibleMessage (FilledInByBackend messagesLoaded) ->
                            if SeqDict.isEmpty messagesLoaded then
                                Command.none

                            else
                                Ports.shiftScrollByElementDelta
                                    Pages.Guild.conversationContainerId
                                    (Pages.Guild.threadMessageHtmlId previousOldestVisibleMessage)

                        Local_Discord_LoadChannelMessages _ previousOldestVisibleMessage (FilledInByBackend messagesLoaded) ->
                            if SeqDict.isEmpty messagesLoaded then
                                Command.none

                            else
                                Ports.shiftScrollByElementDelta
                                    Pages.Guild.conversationContainerId
                                    (Pages.Guild.channelMessageHtmlId previousOldestVisibleMessage)

                        Local_Discord_LoadThreadMessages _ _ previousOldestVisibleMessage (FilledInByBackend messagesLoaded) ->
                            if SeqDict.isEmpty messagesLoaded then
                                Command.none

                            else
                                Ports.shiftScrollByElementDelta
                                    Pages.Guild.conversationContainerId
                                    (Pages.Guild.threadMessageHtmlId previousOldestVisibleMessage)

                        _ ->
                            Command.none
                    )
                )
                model

        ChangeBroadcast change ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    let
                        localState : Local LocalMsg LocalState
                        localState =
                            Local.updateFromBackend FrontendExtra.changeUpdate Nothing change loggedIn.localState

                        local : LocalState
                        local =
                            Local.model localState

                        loggedIn2 : LoggedIn2
                        loggedIn2 =
                            { loggedIn | localState = localState }
                    in
                    case change of
                        ServerChange serverChange ->
                            case serverChange of
                                Server_TextEditor _ ->
                                    ( loggedIn2
                                    , case SeqDict.get local.localUser.session.userId local.textEditor.cursorPosition of
                                        Just range ->
                                            Ports.setCursorPosition TextEditor.inputId range

                                        Nothing ->
                                            Command.none
                                    )

                                Server_YouJoinedGuildByInvite (Ok { guildId, guild }) ->
                                    ( loggedIn2
                                    , case model.route of
                                        GuildRoute inviteGuildId _ _ ->
                                            if inviteGuildId == guildId then
                                                FrontendExtra.routeReplace
                                                    model
                                                    (GuildRoute
                                                        guildId
                                                        (ChannelRoute
                                                            (LocalState.announcementChannel guild)
                                                            (NoThreadWithFriends Nothing HideChannelSettings)
                                                            Nothing
                                                        )
                                                        ChannelsHiddenOnMobile
                                                    )

                                            else
                                                Command.none

                                        _ ->
                                            Command.none
                                    )

                                Server_SendMessage senderId _ _ guildOrDmId content maybeRepliedTo _ _ ->
                                    FrontendExtra.handleServerSendMessage senderId guildOrDmId content maybeRepliedTo local loggedIn2 model

                                Server_SendEncryptedMessage senderId _ _ id content maybeRepliedTo attachedFiles ->
                                    ( { loggedIn
                                        | nextDecryptionRequestId = Id.increment loggedIn.nextDecryptionRequestId
                                        , pendingDecryptedMessages =
                                            SeqDict.insert
                                                loggedIn.nextDecryptionRequestId
                                                { id = id
                                                , senderId = senderId
                                                , threadRoute = maybeRepliedTo
                                                , attachedFiles = attachedFiles
                                                }
                                                loggedIn.pendingDecryptedMessages
                                      }
                                    , Encryption.decryptMessage loggedIn2.nextDecryptionRequestId id content
                                    )

                                Server_Discord_SendMessage _ guildOrDmId _ content maybeRepliedTo _ _ ->
                                    let
                                        scrollsToBottom : Bool
                                        scrollsToBottom =
                                            -- The drawing tab holds the scroll position, otherwise the
                                            -- new message would throw off the stroke the user is drawing
                                            (Route.toChannelHeaderTab model.route /= Just ChannelHeaderTab_Draw)
                                                && (loggedIn2.channelScrollPosition == ScrolledToBottom)

                                        isViewingConversation : Bool
                                        isViewingConversation =
                                            Route.toGuildOrDmId local.localUser.session.userId model.route
                                                == Just
                                                    ( DiscordGuildOrDmId guildOrDmId
                                                    , Id.threadRouteWithoutMaybeMessage maybeRepliedTo
                                                    )

                                        helper senderId channel =
                                            Command.batch
                                                [ FrontendExtra.playNotificationSoundForDiscordMessage
                                                    senderId
                                                    guildOrDmId
                                                    maybeRepliedTo
                                                    channel
                                                    local
                                                    content
                                                    model
                                                , if scrollsToBottom then
                                                    if MyUi.isMobile model then
                                                        Scroll.toBottomOfChannelSmooth Pages.Guild.conversationContainerId SetScrollToBottom

                                                    else
                                                        Scroll.toBottomOfChannel Pages.Guild.conversationContainerId SetScrollToBottom

                                                  else
                                                    Command.none
                                                ]
                                    in
                                    ( if isViewingConversation && not scrollsToBottom then
                                        { loggedIn2
                                            | newMessagesWhileNotScrolledToBottom =
                                                loggedIn2.newMessagesWhileNotScrolledToBottom + 1
                                            , channelScrollPosition =
                                                case loggedIn2.channelScrollPosition of
                                                    ScrolledToBottom ->
                                                        ScrolledToMiddle

                                                    ScrolledToTop ->
                                                        loggedIn2.channelScrollPosition

                                                    ScrolledToMiddle ->
                                                        loggedIn2.channelScrollPosition
                                        }

                                      else
                                        loggedIn2
                                    , case guildOrDmId of
                                        DiscordGuildOrDmId_Guild { currentUserId, guildId, channelId } ->
                                            case LocalState.getDiscordGuildAndChannel guildId channelId local of
                                                Just ( _, channel ) ->
                                                    helper currentUserId channel

                                                Nothing ->
                                                    Command.none

                                        DiscordGuildOrDmId_Dm data ->
                                            case SeqDict.get data.channelId local.discordDmChannels of
                                                Just channel ->
                                                    helper
                                                        data.currentUserId
                                                        { messages = channel.messages, threads = SeqDict.empty }

                                                Nothing ->
                                                    Command.none
                                    )

                                Server_GotDmMessageEmbed userId threadRoute _ ->
                                    let
                                        id : ( AnyGuildOrDmId, ThreadRoute )
                                        id =
                                            ( GuildOrDmId (GuildOrDmId_Dm { otherUserId = userId })
                                            , Id.threadRouteWithoutMessage threadRoute
                                            )
                                    in
                                    ( loggedIn2
                                    , if Route.toGuildOrDmId local.localUser.session.userId model.route == Just id then
                                        Scroll.toBottomOfChannelIfAtBottom Pages.Guild.conversationContainerId SetScrollToBottom loggedIn2.channelScrollPosition

                                      else
                                        Command.none
                                    )

                                Server_GotGuildMessageEmbed guildId channelId threadRoute _ ->
                                    let
                                        id : ( AnyGuildOrDmId, ThreadRoute )
                                        id =
                                            ( GuildOrDmId (GuildOrDmId_Guild { guildId = guildId, channelId = channelId })
                                            , Id.threadRouteWithoutMessage threadRoute
                                            )
                                    in
                                    ( loggedIn2
                                    , if Route.toGuildOrDmId local.localUser.session.userId model.route == Just id then
                                        Scroll.toBottomOfChannelIfAtBottom Pages.Guild.conversationContainerId SetScrollToBottom loggedIn2.channelScrollPosition

                                      else
                                        Command.none
                                    )

                                Server_GotDiscordDmMessageEmbed channelId _ _ ->
                                    ( loggedIn2
                                    , case Route.toGuildOrDmId local.localUser.session.userId model.route of
                                        Just ( DiscordGuildOrDmId (DiscordGuildOrDmId_Dm data), _ ) ->
                                            if channelId == data.channelId then
                                                Scroll.toBottomOfChannelIfAtBottom Pages.Guild.conversationContainerId SetScrollToBottom loggedIn2.channelScrollPosition

                                            else
                                                Command.none

                                        _ ->
                                            Command.none
                                    )

                                Server_GotDiscordGuildMessageEmbed guildIdA channelIdA threadRouteA _ ->
                                    ( loggedIn2
                                    , case Route.toGuildOrDmId local.localUser.session.userId model.route of
                                        Just ( DiscordGuildOrDmId (DiscordGuildOrDmId_Guild { guildId, channelId }), threadRouteB ) ->
                                            if
                                                (guildIdA == guildId)
                                                    && (channelIdA == channelId)
                                                    && (Id.threadRouteWithoutMessage threadRouteA == threadRouteB)
                                            then
                                                Scroll.toBottomOfChannelIfAtBottom Pages.Guild.conversationContainerId SetScrollToBottom loggedIn2.channelScrollPosition

                                            else
                                                Command.none

                                        _ ->
                                            Command.none
                                    )

                                Server_AddReactionEmoji _ _ _ _ ->
                                    ( loggedIn2, Scroll.toBottomOfChannelIfAtBottom Pages.Guild.conversationContainerId SetScrollToBottom loggedIn2.channelScrollPosition )

                                Server_DiscordAddReactionGuildEmoji _ _ _ _ _ ->
                                    ( loggedIn2, Scroll.toBottomOfChannelIfAtBottom Pages.Guild.conversationContainerId SetScrollToBottom loggedIn2.channelScrollPosition )

                                Server_DiscordAddReactionDmEmoji _ _ _ _ ->
                                    ( loggedIn2, Scroll.toBottomOfChannelIfAtBottom Pages.Guild.conversationContainerId SetScrollToBottom loggedIn2.channelScrollPosition )

                                Server_VoiceChatChange voiceChatChange ->
                                    ( loggedIn2
                                    , Call.serverChangeCmd
                                        voiceChatChange
                                        local.localUser.session.userId
                                        local.calls
                                        loggedIn2.voiceChat
                                    )

                                Server_Game _ guildOrDmId gameChange ->
                                    let
                                        ( updatedGameModel, maybeScrollTo ) =
                                            Game.gameChangeFromServer
                                                model.time
                                                local.localUser
                                                gameChange
                                                (SeqDict.get guildOrDmId loggedIn2.games)
                                    in
                                    ( { loggedIn2
                                        | games = SeqDict.update guildOrDmId (\_ -> updatedGameModel) loggedIn2.games
                                      }
                                    , Command.batch
                                        [ -- A question the host has just put on screen is scrolled onto for
                                          -- anyone who was already at the bottom of the tab
                                          case maybeScrollTo of
                                            Just scrollTo ->
                                                scrollElementToTop scrollTo

                                            Nothing ->
                                                Command.none
                                        , -- Another player's move adds a Past moves entry; if we're
                                          -- watching that match, keep the list pinned to the bottom when
                                          -- it already was (mirrors the conversation view).
                                          case gameChange of
                                            Game.LocalChange_WordSpellingGame matchId (WordSpellingGame.Action _) ->
                                                case FrontendExtra.currentGamesTab local model.route of
                                                    Just gamesTab ->
                                                        if gamesTab.guildOrDmId == guildOrDmId && gamesTab.maybeMatchId == Just matchId then
                                                            Scroll.toBottomOfChannelIfAtBottom
                                                                WordSpellingGame.pastWordsContainerId
                                                                SetScrollToBottom
                                                                (case updatedGameModel of
                                                                    Just gameModel3 ->
                                                                        Game.wordSpellingScrollPosition matchId gameModel3

                                                                    Nothing ->
                                                                        ScrolledToBottom
                                                                )

                                                        else
                                                            Command.none

                                                    Nothing ->
                                                        Command.none

                                            _ ->
                                                Command.none
                                        ]
                                    )

                                _ ->
                                    ( loggedIn2, Command.none )

                        _ ->
                            ( loggedIn2, Command.none )
                )
                model

        TwoFactorAuthenticationToFrontend toFrontend2 ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn
                        | twoFactor = TwoFactorAuthentication.updateFromBackend toFrontend2 loggedIn.twoFactor
                      }
                    , Command.none
                    )
                )
                model

        AiChatToFrontend aiChatToFrontend ->
            let
                ( newAiChatModel, cmd ) =
                    AiChat.updateFromBackend aiChatToFrontend model.aiChatModel
            in
            ( { model | aiChatModel = newAiChatModel }, Command.map AiChatToBackend AiChatMsg cmd )

        YouConnected clientId ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn | isReloading = True }
                    , Lamdera.sendToBackend (ReloadDataRequest (routeToInitialDataRequest model.route))
                    )
                )
                { model | clientId = clientId }

        ReloadDataResponse reloadData ->
            case reloadData of
                Ok loginData ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            ( { loggedIn
                                | localState = loginDataToLocalState model.startupData model.emojiData loginData |> Local.init
                                , isReloading = False
                              }
                            , Command.none
                            )
                        )
                        model

                Err () ->
                    FrontendExtra.logout model

        LinkDiscordResponse result ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    case ( model.route, loggedIn.userOptions ) of
                        ( LinkDiscord _, Nothing ) ->
                            case result of
                                Ok () ->
                                    ( loggedIn, FrontendExtra.routeReplace model HomePageRoute )

                                Err _ ->
                                    ( loggedIn, FrontendExtra.routeReplace model (LinkDiscord (Err LinkDiscordServerError)) )

                        _ ->
                            ( loggedIn, Command.none )
                )
                model

        ProfilePictureEditorToFrontend imageEditorToFrontend ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    case imageEditorToFrontend of
                        ImageEditor.ChangeUserAvatarResponse ->
                            ( { loggedIn | profilePictureEditor = ImageEditor.init }, Command.none )

                        ImageEditor.ChangeGuildIconResponse _ ->
                            ( { loggedIn | guildIconEditor = Nothing }, Command.none )
                )
                model

        GetPublicGoMatchResponse result ->
            ( { model
                | publicGoMatch =
                    case result of
                        Ok ok ->
                            PublicGoMatch_Loaded
                                { setup = ok.setup
                                , actions = ok.actions
                                , cache = Go.foldActions ok.setup ok.actions
                                , creatorUser = ok.creatorUser
                                , joinedUser = ok.joinedUser
                                }
                                Go.initGame

                        Err () ->
                            PublicGoMatch_Missing
              }
            , Command.none
            )

        ExportChannelResponse { fileName, json } ->
            ( model, Effect.File.Download.string fileName "application/json" json )


view : AudioData -> FrontendModel_ -> Browser.Document FrontendMsg_
view _ model =
    { title = "AtChat"
    , body =
        [ case model of
            Loading loading ->
                (case loading.loginStatus of
                    LoadingData ->
                        [ Html.div [ Html.Attributes.id "loading" ] []
                        , MyUi.css
                        ]

                    LoadSuccess _ ->
                        case loading.time of
                            Just _ ->
                                -- Make sure all of these error messages are slightly different so we know which branch was reached
                                [ Html.text "Something isn't working."
                                ]

                            Nothing ->
                                [ Html.text "Something went wrong"
                                ]

                    LoadError ->
                        [ Html.text "Something went wrong when loading the page."
                        ]
                )
                    |> Html.span []

            Loaded loaded ->
                let
                    windowWidth : Int
                    windowWidth =
                        Coord.xRaw loaded.windowSize

                    isMobile =
                        MyUi.isMobile loaded

                    requiresLogin : (LoggedIn2 -> LocalState -> Element FrontendMsg_) -> Html FrontendMsg_
                    requiresLogin page =
                        case loaded.loginStatus of
                            LoggedIn loggedIn ->
                                let
                                    local =
                                        Local.model loggedIn.localState
                                in
                                FrontendExtra.layout
                                    loaded
                                    [ case loggedIn.userOptions of
                                        Just userOptions ->
                                            UserOptions.view
                                                loaded.windowSize
                                                loggedIn.textInputFocus
                                                loaded.time
                                                local
                                                loggedIn
                                                loaded
                                                userOptions
                                                |> Ui.inFront

                                        Nothing ->
                                            Ui.noAttr
                                    , case loggedIn.externalLinkWarning of
                                        Just url ->
                                            FrontendExtra.externalLinkWarning
                                                local.localUser.user.domainWhitelist
                                                isMobile
                                                url
                                                |> Ui.inFront

                                        Nothing ->
                                            Ui.noAttr
                                    , case loggedIn.showNewPrivateKey of
                                        Just privateKey ->
                                            FrontendExtra.newPrivateKeyWarning
                                                isMobile
                                                loaded
                                                local.localUser.user.email
                                                privateKey
                                                |> Ui.inFront

                                        Nothing ->
                                            Ui.noAttr
                                    , if loggedIn.isReloading then
                                        Ui.el
                                            [ Ui.background MyUi.background1
                                            , Ui.padding 8
                                            , Ui.width Ui.shrink
                                            , Ui.border 1
                                            , Ui.borderColor MyUi.border1
                                            , Ui.alignBottom
                                            , Ui.centerX
                                            ]
                                            (Ui.text "Reloading...")
                                            |> Ui.inFront

                                      else
                                        Ui.noAttr
                                    , Call.videoNodes
                                        local.localUser
                                        loaded
                                        loggedIn
                                        local.calls
                                        |> Html.map VoiceChatMsg
                                        |> Ui.html
                                        |> Ui.inFront
                                    ]
                                    (page loggedIn local)

                            NotLoggedIn notLoggedIn ->
                                LoginForm.view
                                    notLoggedIn.textInputFocus
                                    (Maybe.withDefault LoginForm.init notLoggedIn.loginForm)
                                    loaded.windowSize
                                    loaded.startupData.pwaStatus
                                    loaded.startupData.userAgent.browser
                                    |> Ui.map LoginFormMsg
                                    |> FrontendExtra.layout loaded
                                        [ Ui.background MyUi.background3
                                        , Ui.inFront (Pages.Home.header isMobile loaded.route loaded.loginStatus)
                                        ]
                in
                case loaded.route of
                    HomePageRoute ->
                        case loaded.loginStatus of
                            LoggedIn _ ->
                                requiresLogin
                                    (\loggedIn local ->
                                        Pages.Guild.homePageLoggedInView NoDmChannelSelected loaded loggedIn local
                                    )

                            NotLoggedIn notLoggedIn ->
                                FrontendExtra.layout
                                    loaded
                                    [ Ui.background MyUi.background3 ]
                                    (Ui.el
                                        [ Ui.inFront (Pages.Home.header isMobile loaded.route loaded.loginStatus)
                                        , Ui.height Ui.fill
                                        ]
                                        (case notLoggedIn.loginForm of
                                            Just loginForm2 ->
                                                LoginForm.view
                                                    notLoggedIn.textInputFocus
                                                    loginForm2
                                                    loaded.windowSize
                                                    loaded.startupData.pwaStatus
                                                    loaded.startupData.userAgent.browser
                                                    |> Ui.map LoginFormMsg

                                            Nothing ->
                                                Ui.Lazy.lazy Pages.Home.view windowWidth
                                        )
                                    )

                    AdminRoute _ ->
                        case ( loaded.loginStatus, loaded.loginType ) of
                            -- The backend can't email a login code to anyone when it has no
                            -- Postmark API key, so offer the recovery password instead. It's only
                            -- shown here to keep it off the normal login page.
                            ( NotLoggedIn notLoggedIn, LoginWithRecoveryPassword ) ->
                                RecoveryLogin.view notLoggedIn.recoveryLogin
                                    |> Ui.map RecoveryLoginMsg
                                    |> FrontendExtra.layout loaded
                                        [ Ui.background MyUi.background3
                                        , Ui.inFront (Pages.Home.header isMobile loaded.route loaded.loginStatus)
                                        ]

                            _ ->
                                requiresLogin
                                    (\loggedIn local ->
                                        case local.adminData of
                                            IsAdmin adminData ->
                                                case NonemptyDict.get local.localUser.session.userId adminData.users of
                                                    Just user ->
                                                        Pages.Admin.view
                                                            (MyUi.isMobile loaded)
                                                            loaded.versionNumber
                                                            loaded.time
                                                            local
                                                            adminData
                                                            user
                                                            loggedIn.admin
                                                            |> Ui.map AdminPageMsg

                                                    Nothing ->
                                                        Ui.text "User not found"

                                            IsAdminButDataNotLoaded ->
                                                Ui.text "Loading admin page..."

                                            _ ->
                                                errorPage loaded "Admin access required to view this page"
                                    )

                    NewGuildRoute ->
                        requiresLogin
                            (\loggedIn _ ->
                                Maybe.withDefault Pages.Guild.newGuildFormInit loggedIn.newGuildForm
                                    |> Pages.Guild.newGuildFormView
                            )

                    AiChatRoute ->
                        AiChat.view loaded.windowSize loaded.aiChatModel
                            |> Ui.map AiChatMsg
                            |> FrontendExtra.layout loaded
                                [ if
                                    (loaded.aiChatModel.chatHistory == "")
                                        && (loaded.aiChatModel.message == "")
                                        && MyUi.isMobile loaded
                                        && (loaded.startupData.pwaStatus == BrowserView)
                                  then
                                    Ui.inFront
                                        (Ui.el
                                            [ Ui.centerX
                                            , Ui.centerY
                                            , Ui.widthMax 380
                                            , Ui.padding 16
                                            ]
                                            (LoginForm.mobileWarning
                                                loaded.windowSize
                                                loaded.startupData.userAgent.browser
                                            )
                                        )

                                  else
                                    Ui.noAttr
                                ]

                    GuildRoute guildId maybeChannelId _ ->
                        requiresLogin (Pages.Guild.guildView loaded guildId maybeChannelId)

                    DiscordGuildRoute data ->
                        requiresLogin (Pages.Guild.discordGuildView loaded data)

                    DmRoute dmRoute ->
                        requiresLogin
                            (Pages.Guild.homePageLoggedInView (SelectedDmChannel dmRoute) loaded)

                    SlackOAuthRedirect result ->
                        FrontendExtra.layout
                            loaded
                            [ Ui.contentCenterX, Ui.contentCenterY ]
                            (case result of
                                Ok _ ->
                                    Ui.text "Slack is now linked with your account. You can return to the original page."

                                Err () ->
                                    Ui.text "Something went wrong when linking Slack to at-chat..."
                            )

                    TextEditorRoute ->
                        requiresLogin
                            (\_ local ->
                                TextEditor.view
                                    local.localUser.session.userId
                                    local.textEditor
                                    |> Ui.map TextEditorMsg
                            )

                    DiscordDmRoute routeData ->
                        requiresLogin
                            (Pages.Guild.homePageLoggedInView (SelectedDiscordDmChannel routeData) loaded)

                    LinkDiscord result ->
                        FrontendExtra.layout
                            loaded
                            [ Ui.contentCenterX, Ui.contentCenterY ]
                            (case ( loaded.loginStatus, result ) of
                                ( NotLoggedIn notLoggedIn, Ok _ ) ->
                                    Ui.column
                                        [ Ui.spacing 32 ]
                                        [ Ui.el
                                            [ Ui.Font.size 20, Ui.Font.center, Ui.widthMax 400, Ui.centerX ]
                                            (Ui.text "You aren't logged in here. Please log in and then we can link your Discord account.")
                                        , LoginForm.view
                                            notLoggedIn.textInputFocus
                                            (Maybe.withDefault LoginForm.init notLoggedIn.loginForm)
                                            loaded.windowSize
                                            -- Don't show PWA warning on this login screen
                                            InstalledPwa
                                            loaded.startupData.userAgent.browser
                                            |> Ui.map LoginFormMsg
                                        ]

                                ( LoggedIn _, Ok _ ) ->
                                    Ui.text "Linking..."

                                ( _, Err error ) ->
                                    errorPage
                                        loaded
                                        (case error of
                                            LinkDiscordExpired ->
                                                discordLinkExpiredText

                                            LinkDiscordServerError ->
                                                "Failed to link your Discord account due to a server error"

                                            LinkDiscordInvalidData ->
                                                "Failed to link your Discord account due to some problem with the bookmarklet"
                                        )
                            )

                    PublicGoMatchRoute _ ->
                        FrontendExtra.layout
                            loaded
                            [ Ui.background MyUi.background3, Ui.contentCenterX, Ui.contentCenterY ]
                            (case loaded.publicGoMatch of
                                PublicGoMatch_Loaded data gameModel ->
                                    Go.spectatorView loaded.time loaded.windowSize data gameModel
                                        |> Ui.map GoSpectatorMsg
                                        |> Ui.el
                                            [ Ui.htmlAttribute (Html.Attributes.id "public_go_container")
                                            , Ui.centerX
                                            , Ui.centerY
                                            , Ui.width Ui.shrink
                                            ]

                                PublicGoMatch_Missing ->
                                    errorPage loaded goMatchNotFoundText

                                PublicGoMatch_Loading ->
                                    Ui.el
                                        [ Ui.centerX, Ui.centerY, Ui.htmlAttribute (Html.Attributes.id "public_go_loading") ]
                                        (Ui.text "Loading match...")

                                PublicGoMatch_NotLoaded ->
                                    errorPage loaded "Something went wrong when loading Go match"
                            )
        ]
    }


errorPage : LoadedFrontend -> String -> Element FrontendMsg_
errorPage model text =
    Ui.el
        [ Ui.inFront (Pages.Home.header (MyUi.isMobile model) model.route model.loginStatus)
        , Ui.height Ui.fill
        ]
        (Ui.column
            [ Ui.centerY, Ui.spacing 16 ]
            [ Ui.el [ Ui.width Ui.shrink, Ui.centerX ] (Ui.text text)
            , Ui.el
                [ Ui.width Ui.shrink, Ui.centerX ]
                (MyUi.simpleButton
                    (Dom.id "frontend_goToHomepage")
                    (PressedLink HomePageRoute)
                    (Ui.text "Go to homepage")
                )
            ]
        )


routeToInitialDataRequest : Route -> InitialLoadRequest
routeToInitialDataRequest route =
    case route of
        GuildRoute guildId (ChannelRoute channelId threadRoute tab) _ ->
            InitialLoadRequested_Guild
                guildId
                channelId
                (case threadRoute of
                    ViewThreadWithFriends threadMessageId _ _ ->
                        ViewThread threadMessageId

                    NoThreadWithFriends _ _ ->
                        NoThread
                )
                tab

        DmRoute { channelId, threadRoute, tab } ->
            InitialLoadRequested_Dm
                channelId
                (case threadRoute of
                    ViewThreadWithFriends threadMessageId _ _ ->
                        ViewThread threadMessageId

                    NoThreadWithFriends _ _ ->
                        NoThread
                )
                tab

        DiscordGuildRoute data ->
            case data.channelRoute of
                DiscordChannel_ChannelRoute channelId threadRoute _ ->
                    InitialLoadRequested_DiscordGuild
                        data.currentDiscordUserId
                        data.guildId
                        channelId
                        (case threadRoute of
                            ViewThreadWithFriends threadMessageId _ _ ->
                                ViewThread threadMessageId

                            NoThreadWithFriends _ _ ->
                                NoThread
                        )

                _ ->
                    InitialLoadRequested_None

        DiscordDmRoute data ->
            InitialLoadRequested_DiscordDm data.currentDiscordUserId data.channelId

        AdminRoute { highlightLog } ->
            InitialLoadRequested_Admin
                (case highlightLog of
                    Just highlightLog2 ->
                        Just (Pagination.itemToPageId highlightLog2).pageId

                    Nothing ->
                        Nothing
                )

        _ ->
            InitialLoadRequested_None


{-| Whatever is being scrolled to has only just been added, so it isn't in the page until the
next render. The sleep lets that happen before we go looking for it.
-}
scrollElementToTop : Game.ScrollTo -> Command FrontendOnly ToBackend FrontendMsg_
scrollElementToTop { container, target } =
    Scroll.smoothScrollToTopOf container target
        |> Task.attempt (\_ -> SetScrollToBottom)


handleGameOutMsgs :
    List Game.OutMsg
    -> LoadedFrontend
    -> ( LoadedFrontend, List (Command FrontendOnly ToBackend FrontendMsg_) )
handleGameOutMsgs outMsgs model =
    List.foldl
        (\outMsg ( model2, cmds ) ->
            case outMsg of
                Game.CopyText text ->
                    let
                        ( copyModel, copyCmd ) =
                            copyText text model2
                    in
                    ( copyModel, copyCmd :: cmds )

                Game.OutSelectMatch newSelected ->
                    let
                        ( pushModel, pushCmd ) =
                            FrontendExtra.routePush
                                model2
                                (Route.setChannelHeaderTab (Just (ChannelHeaderTab_Games newSelected)) model2.route)
                    in
                    ( pushModel, pushCmd :: cmds )

                Game.OutLocalChange _ ->
                    ( model2, cmds )

                Game.ScrollToBottom htmlId ->
                    ( model2, Scroll.toBottomOfChannel htmlId SetScrollToBottom :: cmds )

                Game.SmoothScrollTo scrollTo ->
                    ( model2, scrollElementToTop scrollTo :: cmds )

                Game.SaveSheepGameQuestions _ ->
                    ( model2, cmds )

                Game.SaveSheepGameQuestionsAfterDelay counter ->
                    ( model2
                    , (Process.sleep Game.sheepGameQuestionsSaveDelay
                        |> Task.perform
                            (\() -> GameMsg (Game.CheckedSheepGameQuestionsDebounce counter))
                      )
                        :: cmds
                    )

                Game.SaveSheepGameInputAfterDelay matchId input counter ->
                    ( model2
                    , (Process.sleep Game.sheepGameInputSaveDelay
                        |> Task.perform
                            (\() -> GameMsg (Game.CheckedSheepGameSaveDebounce matchId input counter))
                      )
                        :: cmds
                    )

                Game.SelectSheepGameFilesToAttach input ->
                    ( model2
                    , Effect.File.Select.files
                        []
                        (\file files ->
                            List.Nonempty.Nonempty file files
                                |> Game.sheepGameFilesToAttach input
                                |> GameMsg
                        )
                        :: cmds
                    )

                Game.UploadSheepGameAttachedFiles input files ->
                    ( model2
                    , (List.Nonempty.toList files
                        |> List.map
                            (\( fileId, file ) ->
                                FileStatus.uploadGameFile
                                    (\result -> Game.sheepGameFileUploaded input fileId result |> GameMsg)
                                    (SheepGame.attachedFileTrackerId input fileId)
                                    file
                            )
                        |> Command.batch
                      )
                        :: cmds
                    )

                Game.CancelSheepGameAttachedFileUpload input fileId ->
                    ( model2
                    , Http.cancel (SheepGame.attachedFileTrackerId input fileId) :: cmds
                    )

                Game.ShowSheepGameAttachedFileInfo fileData ->
                    let
                        ( infoModel, infoCmd ) =
                            FrontendExtra.updateLoggedIn
                                (\loggedIn -> ( { loggedIn | showFileToUploadInfo = Just fileData }, Command.none ))
                                model2
                    in
                    ( infoModel, infoCmd :: cmds )

                Game.FetchWordDefinition word ->
                    ( model2
                    , Http.get
                        { url = WordSpellingGame.definitionApiUrl word
                        , expect =
                            Http.expectJson
                                (\result ->
                                    GameMsg (Game.WordSpellingGameMsg (WordSpellingGame.GotWordDefinition word result))
                                )
                                WordSpellingGame.decodeDefinition
                        }
                        :: cmds
                    )

                Game.OpenSheepGameReactionEmojiSelector guildOrDmId matchId target ->
                    let
                        ( selectorModel, selectorCmd ) =
                            FrontendExtra.updateLoggedIn
                                (\loggedIn ->
                                    let
                                        emojiSelectorModel : Emoji.Model
                                        emojiSelectorModel =
                                            loggedIn.emojiSelector
                                    in
                                    ( { loggedIn
                                        | showEmojiSelector =
                                            EmojiSelectorForSheepGameReaction guildOrDmId matchId target
                                        , emojiSelector =
                                            { emojiSelectorModel | searchText = "", category = Emoji.selectorInit.category }
                                      }
                                    , if MyUi.isMobile model2 then
                                        Command.none

                                      else
                                        Dom.focus Emoji.searchInputId |> Task.attempt (\_ -> SetFocus)
                                    )
                                )
                                model2
                    in
                    ( selectorModel, selectorCmd :: cmds )

                Game.ShowSheepGameImage { fileUrl, imageSize } ->
                    ( { model2 | imageViewer = Just (ImageViewer.init { url = fileUrl, imageSize = imageSize }) }
                    , cmds
                    )

                Game.OpenSheepGameEmojiSelector input ->
                    ( model2
                    , Task.attempt
                        (GotPositionForEmojiSelector_SheepGameInput input)
                        (Dom.getElement (SheepGame.inputContainerId input))
                        :: cmds
                    )

                Game.SetFocus htmlId ->
                    ( model2, FrontendExtra.setFocus model2 htmlId :: cmds )
        )
        ( model, [] )
        outMsgs


storeRemainingSharedSecrets :
    Id UserId
    -> X25519.PrivateKey
    -> LoggedIn2
    -> List (Command FrontendOnly ToBackend FrontendMsg_)
storeRemainingSharedSecrets alreadyHandled privateKey loggedIn =
    SeqDict.toList (Local.model loggedIn.localState).dmChannels
        |> List.filterMap
            (\( otherUserId, dmChannel ) ->
                case dmChannel.e2ee of
                    DmChannel.E2eeEnabled _ ->
                        if
                            (otherUserId == alreadyHandled)
                                || SeqSet.member otherUserId loggedIn.e2eeKeysOnThisDevice
                        then
                            Nothing

                        else
                            storeSharedSecret otherUserId privateKey loggedIn |> Result.toMaybe

                    DmChannel.E2eeRequestedBy _ ->
                        Nothing

                    DmChannel.E2eeDisabled ->
                        Nothing
            )


storeSharedSecret : Id UserId -> X25519.PrivateKey -> LoggedIn2 -> Result String (Command FrontendOnly ToBackend FrontendMsg_)
storeSharedSecret otherUserId privateKey loggedIn =
    let
        local : LocalState
        local =
            Local.model loggedIn.localState
    in
    case User.getUser otherUserId local.localUser |> Maybe.andThen .publicKey of
        Nothing ->
            Err "The other person hasn't created a private key yet"

        Just otherPublicKey ->
            case X25519.sharedSecret privateKey otherPublicKey of
                Nothing ->
                    Err "The other person's public key is not usable"

                Just secret ->
                    Encryption.storeSharedSecret otherUserId (X25519.sharedSecretToBytes secret) |> Ok


{-| The other person in the conversation, when this is a DM that has been encrypted.
`Nothing` for anything that goes to the server in the clear.
-}
encryptedDmOtherUser : AnyGuildOrDmId -> LocalState -> Maybe Viewing_DmId
encryptedDmOtherUser guildOrDmId local =
    case guildOrDmId of
        GuildOrDmId (GuildOrDmId_Dm { otherUserId }) ->
            case SeqDict.get otherUserId local.dmChannels |> Maybe.map .e2ee of
                Just (DmChannel.E2eeEnabled _) ->
                    Just { otherUserId = otherUserId }

                _ ->
                    Nothing

        _ ->
            Nothing


startEncryptingMessage :
    Viewing_DmId
    -> ThreadRoute
    -> ContentAndEmbeds (Id UserId)
    -> LoggedIn2
    -> ( LoggedIn2, Command FrontendOnly ToBackend FrontendMsg_ )
startEncryptingMessage id threadRoute contentAndEmbeds loggedIn =
    let
        guildOrDmId : ( AnyGuildOrDmId, ThreadRoute )
        guildOrDmId =
            ( GuildOrDmId (GuildOrDmId_Dm id), threadRoute )
    in
    ( { loggedIn
        | e2eeError = Nothing
        , nextEncryptionRequestId = Id.increment loggedIn.nextEncryptionRequestId
        , pendingEncryptedMessages =
            SeqDict.insert
                loggedIn.nextEncryptionRequestId
                { otherUserId = id.otherUserId
                , threadRoute =
                    case threadRoute of
                        ViewThread threadId ->
                            ViewThreadWithMaybeMessage
                                threadId
                                (SeqDict.get guildOrDmId loggedIn.replyTo |> Maybe.map Id.changeType)

                        NoThread ->
                            NoThreadWithMaybeMessage (SeqDict.get guildOrDmId loggedIn.replyTo)
                , attachedFiles =
                    case SeqDict.get guildOrDmId loggedIn.filesToUpload of
                        Just dict ->
                            NonemptyDict.toSeqDict dict |> FileStatus.onlyUploadedFiles

                        Nothing ->
                            SeqDict.empty
                , contentAndEmbeds = contentAndEmbeds
                }
                loggedIn.pendingEncryptedMessages
      }
    , Encryption.encryptMessage loggedIn.nextEncryptionRequestId id Message.contentAndEmbedsCodec contentAndEmbeds
    )
