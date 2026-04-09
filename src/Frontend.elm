module Frontend exposing (app, app_)

import AiChat
import Array exposing (Array)
import Browser exposing (UrlRequest(..))
import Browser.Navigation
import ChannelName
import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Discord
import DmChannel exposing (FrontendDmChannel)
import Duration exposing (Duration, Seconds)
import Editable
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Browser.Events
import Effect.Browser.Navigation as BrowserNavigation exposing (Key)
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.File as File exposing (File)
import Effect.File.Select
import Effect.Http as Http
import Effect.Lamdera as Lamdera
import Effect.Process as Process
import Effect.Subscription as Subscription exposing (Subscription)
import Effect.Task as Task
import Effect.Time as Time
import Emoji exposing (Emoji, EmojiOrSticker(..))
import FileName
import FileStatus exposing (FileData, FileId, FileStatus(..))
import FrontendExtra
import GuildName
import Html exposing (Html)
import Html.Attributes
import Id exposing (AnyGuildOrDmId(..), ChannelId, ChannelMessageId, DiscordGuildOrDmId(..), GuildOrDmId(..), Id, ThreadRoute(..), ThreadRouteWithMaybeMessage(..), ThreadRouteWithMessage(..), UserId)
import ImageEditor
import Json.Decode
import Lamdera as LamderaCore
import List.Extra
import List.Nonempty exposing (Nonempty(..))
import Local exposing (Local)
import LocalState exposing (AdminStatus(..), LocalState)
import LoginForm
import Message exposing (MessageNoReply(..), MessageStateNoReply(..), UserTextMessageDataNoReply)
import MessageInput exposing (NameSoFar(..))
import MessageMenu
import MessageView
import MyUi
import NonemptyDict exposing (NonemptyDict)
import NonemptySet
import Pages.Admin
import Pages.Guild exposing (DmChannelSelection(..))
import Pages.Home
import Pagination
import Ports exposing (PwaStatus(..))
import Quantity exposing (Quantity, Rate, Unitless)
import Range exposing (Range, SelectionDirection)
import RichText exposing (RichText)
import Route exposing (ChannelRoute(..), DiscordChannelRoute(..), LinkDiscordError(..), Route(..), ShowMembersTab(..), ThreadRouteWithFriends(..))
import Scroll
import SeqDict exposing (SeqDict)
import Sticker
import String.Nonempty
import TextEditor
import Thread
import Touch exposing (Touch)
import TwoFactorAuthentication exposing (TwoFactorState(..))
import Types exposing (AdminStatusLoginData(..), ChannelSidebarMode(..), Drag(..), EmojiSelector(..), FrontendModel(..), FrontendMsg(..), GuildChannelNameHover(..), InitialLoadRequest(..), LoadStatus(..), LoadedFrontend, LoadingFrontend, LocalChange(..), LocalMsg(..), LoggedIn2, LoginData, LoginResult(..), LoginStatus(..), MessageHover(..), MessageHoverMobileMode(..), RevealedSpoilers, ScrollPosition(..), ServerChange(..), ToBackend(..), ToFrontend(..), UserOptionsModel)
import Ui exposing (Element)
import Ui.Anim
import Ui.Font
import Ui.Lazy
import Untrusted
import Url exposing (Url)
import UserAgent exposing (UserAgent)
import UserOptions
import UserSession exposing (NotificationMode(..), SetViewing(..), ToBeFilledInByBackend(..))
import Vector2d


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
    { init = init
    , onUrlRequest = onUrlRequest
    , onUrlChange = onUrlChange
    , update = update
    , updateFromBackend = updateFromBackend
    , subscriptions = subscriptions
    , view = view
    }


subscriptions : FrontendModel -> Subscription FrontendOnly FrontendMsg
subscriptions model =
    Subscription.batch
        [ Effect.Browser.Events.onResize GotWindowSize
        , Time.every (Duration.seconds 2) GotTime
        , Effect.Browser.Events.onKeyDown (Json.Decode.field "key" Json.Decode.string |> Json.Decode.map KeyDown)
        , Ports.checkNotificationPermissionResponse CheckedNotificationPermission
        , Ports.checkPwaStatusResponse CheckedPwaStatus
        , AiChat.subscriptions |> Subscription.map AiChatMsg
        , Ports.scrollbarWidthSub GotScrollbarWidth
        , Ports.pageHasFocus PageHasFocusChanged
        , Ports.userAgentSub GotUserAgent
        , Ports.serviceWorkerMessage GotServiceWorkerMessage
        , Ports.visualViewportResized VisualViewportResized
        , Ports.selectionChanged TextSelectionChanged
        , Ports.focusChanged DomFocusChanged
        , case model of
            Loading _ ->
                Subscription.none

            Loaded loaded ->
                Subscription.batch
                    [ case loaded.route of
                        GuildRoute _ (ChannelRoute _ _) ->
                            Effect.Browser.Events.onVisibilityChange VisibilityChanged

                        _ ->
                            Subscription.none
                    , case loaded.loginStatus of
                        LoggedIn loggedIn ->
                            Subscription.batch
                                [ SeqDict.foldl
                                    (\guildOrDmId filesToUpload list ->
                                        NonemptyDict.foldl
                                            (\fileId fileStatus list2 ->
                                                case fileStatus of
                                                    FileUploading _ _ _ ->
                                                        Http.track
                                                            (FileStatus.uploadTrackerId guildOrDmId fileId)
                                                            (FileUploadProgress guildOrDmId fileId)
                                                            :: list2

                                                    FileUploaded _ ->
                                                        list2

                                                    FileError _ _ _ _ ->
                                                        list2
                                            )
                                            list
                                            filesToUpload
                                    )
                                    []
                                    loggedIn.filesToUpload
                                    |> Subscription.batch
                                , case loggedIn.sidebarMode of
                                    ChannelSidebarOpened ->
                                        Subscription.none

                                    ChannelSidebarClosed ->
                                        Subscription.none

                                    ChannelSidebarDragging _ ->
                                        Subscription.none

                                    ChannelSidebarClosing _ ->
                                        Effect.Browser.Events.onAnimationFrameDelta ChannelSidebarAnimated

                                    ChannelSidebarOpening _ ->
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
                                ]

                        NotLoggedIn _ ->
                            Subscription.none
                    ]
        , Ports.registerPushSubscription GotRegisterPushSubscription
        ]


onUrlRequest : UrlRequest -> FrontendMsg
onUrlRequest =
    UrlClicked


onUrlChange : Url -> FrontendMsg
onUrlChange =
    UrlChanged


init : Url -> Key -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
init url key =
    let
        route : Route
        route =
            Route.decode url
    in
    ( Loading
        { navigationKey = key
        , route = route
        , windowSize = Coord.xy 1920 1080
        , time = Nothing
        , timezone = Time.utc
        , loginStatus = LoadingData
        , notificationPermission = Ports.Denied
        , pwaStatus = Ports.BrowserView
        , scrollbarWidth = 0
        , userAgent = Nothing
        }
    , Command.batch
        [ Task.perform GotTime Time.now
        , BrowserNavigation.replaceUrl key (Route.encode route)
        , Task.perform (\{ viewport } -> GotWindowSize (round viewport.width) (round viewport.height)) Dom.getViewport
        , Lamdera.sendToBackend
            (CheckLoginRequest (routeToInitialDataRequest route))
        , Ports.loadSounds
        , Ports.checkNotificationPermission
        , Ports.checkPwaStatus
        , Task.perform GotTimezone Time.here
        , Ports.getScrollbarWidth
        , Ports.getUserAgent
        ]
    )


initLoadedFrontend :
    LoadingFrontend
    -> Time.Posix
    -> UserAgent
    -> Result () LoginData
    -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg )
initLoadedFrontend loading time userAgent loginResult =
    let
        ( loginStatus, cmdB ) =
            case loginResult of
                Ok loginData ->
                    loadedInitHelper loading.timezone userAgent loginData loading |> Tuple.mapFirst LoggedIn

                Err () ->
                    ( NotLoggedIn
                        { loginForm = Nothing
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
            , route = loading.route
            , time = time
            , timezone = loading.timezone
            , windowSize = loading.windowSize
            , virtualKeyboardOpen = False
            , loginStatus = loginStatus
            , elmUiState = Ui.Anim.init
            , lastCopied = Nothing
            , notificationPermission = loading.notificationPermission
            , pwaStatus = loading.pwaStatus
            , drag = NoDrag
            , dragPrevious = NoDrag
            , aiChatModel = aiChatModel
            , scrollbarWidth = loading.scrollbarWidth
            , userAgent = userAgent
            , pageHasFocus = True
            , versionNumber = Nothing
            , emojiData = Nothing
            , toFrontendLogs = Nothing
            }

        ( model2, cmdA ) =
            FrontendExtra.routeRequest Nothing model.route model
    in
    ( model2
    , Command.batch
        [ cmdB
        , cmdA
        , Command.map AiChatToBackend AiChatMsg aiChatCmd
        , Http.get { url = "/_i", expect = Http.expectJson GotVersionNumber (Json.Decode.field "v" Json.Decode.int) }
        , case loginResult of
            Ok _ ->
                Ports.registerServiceWorker

            Err _ ->
                Command.none
        , Emoji.requestEmojiData GotEmojiData
        ]
    )


loadedInitHelper :
    Time.Zone
    -> UserAgent
    -> LoginData
    -> { a | windowSize : Coord CssPixels, navigationKey : Key, route : Route }
    -> ( LoggedIn2, Command FrontendOnly ToBackend FrontendMsg )
loadedInitHelper timezone userAgent loginData loading =
    let
        localState : LocalState
        localState =
            loginDataToLocalState userAgent timezone loginData

        loggedIn : LoggedIn2
        loggedIn =
            { localState = Local.init localState
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
            , newGuildForm = Nothing
            , channelNameHover = NoChannelNameHover
            , typingDebouncer = True
            , textInputFocus = Nothing
            , previousTextInputFocus = Nothing
            , messageHover = NoMessageHover
            , showEmojiSelector = EmojiSelectorHidden
            , editMessage = SeqDict.empty
            , replyTo = SeqDict.empty
            , revealedSpoilers = Nothing
            , sidebarMode = ChannelSidebarOpened
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
            , externalLinkWarning = Nothing
            , emojiSelector = Emoji.selectorInit
            }
    in
    ( loggedIn
    , case loading.route of
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
    )


loginDataToLocalState : UserAgent -> Time.Zone -> LoginData -> LocalState
loginDataToLocalState userAgent timezone loginData =
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
        , user = loginData.user
        , otherUsers = loginData.otherUsers
        , otherDiscordUsers = loginData.otherDiscordUsers
        , linkedDiscordUsers = loginData.linkedDiscordUsers
        , timezone = timezone
        , userAgent = userAgent
        , stickers = loginData.stickers
        }
    , otherSessions = loginData.otherSessions
    , publicVapidKey = loginData.publicVapidKey
    , textEditor = loginData.textEditor
    }


tryInitLoadedFrontend : LoadingFrontend -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
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
    case ( loading.time, maybeLoginStatus, loading.userAgent ) of
        ( Just time, Just loginStatus, Just userAgent ) ->
            initLoadedFrontend loading time userAgent loginStatus |> Tuple.mapFirst Loaded

        _ ->
            ( Loading loading, Command.none )


update : FrontendMsg -> FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
update msg model =
    case model of
        Loading loading ->
            case msg of
                GotTime time ->
                    tryInitLoadedFrontend { loading | time = Just time }

                GotWindowSize width height ->
                    ( Loading { loading | windowSize = Coord.xy width height }, Command.none )

                CheckedNotificationPermission permission ->
                    ( Loading { loading | notificationPermission = permission }, Command.none )

                CheckedPwaStatus pwaStatus ->
                    ( Loading { loading | pwaStatus = pwaStatus }, Command.none )

                GotTimezone timezone ->
                    ( Loading { loading | timezone = timezone }, Command.none )

                GotScrollbarWidth width ->
                    ( Loading { loading | scrollbarWidth = width }, Command.none )

                GotUserAgent userAgent ->
                    tryInitLoadedFrontend { loading | userAgent = Just userAgent }

                _ ->
                    ( model, Command.none )

        Loaded loaded ->
            case ( FrontendExtra.isPressMsg msg, loaded.dragPrevious ) of
                ( True, Dragging _ ) ->
                    ( model, Command.none )

                ( True, _ ) ->
                    updateLoaded msg loaded
                        |> Tuple.mapFirst
                            (\loaded2 ->
                                case loaded2.loginStatus of
                                    LoggedIn loggedIn ->
                                        { loaded2
                                            | loginStatus = LoggedIn { loggedIn | previousTextInputFocus = Nothing }
                                        }
                                            |> Loaded

                                    NotLoggedIn _ ->
                                        Loaded loaded2
                            )

                _ ->
                    updateLoaded msg loaded |> Tuple.mapFirst Loaded


updateLoaded : FrontendMsg -> LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg )
updateLoaded msg model =
    case msg of
        UrlClicked urlRequest ->
            case urlRequest of
                Internal url ->
                    let
                        route : Route
                        route =
                            Route.decode url
                    in
                    ( model
                    , Command.batch
                        [ if model.route == route then
                            BrowserNavigation.replaceUrl model.navigationKey (Route.encode route)

                          else
                            BrowserNavigation.pushUrl model.navigationKey (Route.encode route)
                        ]
                    )

                External url ->
                    ( model
                    , BrowserNavigation.load url
                    )

        UrlChanged url ->
            FrontendExtra.routeRequest (Just model.route) (Route.decode url) model

        GotTime time ->
            ( { model | time = time }, Command.none )

        GotWindowSize width height ->
            ( { model | windowSize = Coord.xy width height }, Command.none )

        GotTimezone _ ->
            -- We should only get the timezone while loading
            ( model, Command.none )

        PressedShowLogin ->
            case model.loginStatus of
                LoggedIn _ ->
                    ( model, Command.none )

                NotLoggedIn notLoggedIn ->
                    ( { model | loginStatus = NotLoggedIn { notLoggedIn | loginForm = Just LoginForm.init } }
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
                                    ( { model | lastCopied = Just { copiedAt = model.time, copiedText = text } }
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
                                LoginWithTokenRequest requestMessagesFor loginToken model.userAgent
                                    |> Lamdera.sendToBackend
                            )
                            (\loginToken ->
                                LoginWithTwoFactorRequest requestMessagesFor loginToken model.userAgent
                                    |> Lamdera.sendToBackend
                            )
                            (\name ->
                                FinishUserCreationRequest requestMessagesFor name model.userAgent
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

        PressedLogOut ->
            ( model, Lamdera.sendToBackend LogOutRequest )

        ScrolledToLogSection ->
            ( model, Command.none )

        ElmUiMsg elmUiMsg ->
            ( { model | elmUiState = Ui.Anim.update ElmUiMsg elmUiMsg model.elmUiState }, Command.none )

        PressedLink route ->
            let
                notificationRequest : Command FrontendOnly toMsg msg
                notificationRequest =
                    case model.notificationPermission of
                        Ports.NotAsked ->
                            Ports.requestNotificationPermission

                        _ ->
                            Command.none

                ( model2, cmd ) =
                    FrontendExtra.updateLoggedIn (setLastViewedToLatestMessage model) model

                ( model3, routeCmd ) =
                    FrontendExtra.routePush model2 route
            in
            ( model3, Command.batch [ cmd, routeCmd, notificationRequest ] )

        DebouncedTyping ->
            FrontendExtra.updateLoggedIn
                (\loggedIn -> ( { loggedIn | typingDebouncer = True }, Command.none ))
                model

        SelectedFilesToAttach ( guildOrDmId, threadRoute ) file files ->
            gotFiles guildOrDmId threadRoute (Nonempty file files) model

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
                    case ChannelName.fromString newChannelForm.name of
                        Ok channelName ->
                            let
                                oldLoggedIn : LoggedIn2
                                oldLoggedIn =
                                    loggedIn

                                ( loggedIn2, cmd ) =
                                    FrontendExtra.handleLocalChange
                                        model.time
                                        (Local_NewChannel model.time guildId channelName |> Just)
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
                                            (ChannelRoute nextChannelId (NoThreadWithFriends Nothing HideMembersTab))
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

        MouseEnteredChannelName guildId channelId threadRoute ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn | channelNameHover = GuildChannelNameHover guildId channelId threadRoute }, Command.none )
                )
                model

        MouseExitedChannelName guildId channelId threadRoute ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn
                        | channelNameHover =
                            if loggedIn.channelNameHover == GuildChannelNameHover guildId channelId threadRoute then
                                NoChannelNameHover

                            else
                                loggedIn.channelNameHover
                      }
                    , Command.none
                    )
                )
                model

        MouseEnteredDiscordChannelName guildId channelId threadRoute ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn | channelNameHover = DiscordGuildChannelNameHover guildId channelId threadRoute }, Command.none )
                )
                model

        MouseExitedDiscordChannelName guildId channelId threadRoute ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn
                        | channelNameHover =
                            if loggedIn.channelNameHover == DiscordGuildChannelNameHover guildId channelId threadRoute then
                                NoChannelNameHover

                            else
                                loggedIn.channelNameHover
                      }
                    , Command.none
                    )
                )
                model

        EditChannelFormChanged guildId channelId newChannelForm ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn
                        | editChannelForm =
                            SeqDict.insert
                                ( guildId, channelId )
                                newChannelForm
                                loggedIn.editChannelForm
                      }
                    , Command.none
                    )
                )
                model

        PressedCancelEditChannelChanges guildId channelId ->
            case model.loginStatus of
                LoggedIn loggedIn ->
                    FrontendExtra.routePush
                        { model
                            | loginStatus =
                                LoggedIn
                                    { loggedIn
                                        | editChannelForm =
                                            SeqDict.remove ( guildId, channelId ) loggedIn.editChannelForm
                                    }
                        }
                        (GuildRoute
                            guildId
                            (ChannelRoute channelId (NoThreadWithFriends Nothing HideMembersTab))
                        )

                NotLoggedIn _ ->
                    ( model, Command.none )

        PressedSubmitEditChannelChanges guildId channelId form ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    case ChannelName.fromString form.name of
                        Ok channelName ->
                            FrontendExtra.handleLocalChange
                                model.time
                                (Local_EditChannel guildId channelId channelName |> Just)
                                { loggedIn
                                    | editChannelForm =
                                        SeqDict.remove ( guildId, channelId ) loggedIn.editChannelForm
                                }
                                Command.none

                        Err _ ->
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
                                                (NoThreadWithFriends Nothing HideMembersTab)
                                            )
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
                                            ( GuildOrDmId (GuildOrDmId_Guild guildId channelId), NoThread )
                                            loggedIn.drafts
                                    , editChannelForm =
                                        SeqDict.remove ( guildId, channelId ) loggedIn.editChannelForm
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

        FrontendNoOp ->
            ( model, Command.none )

        PressedCopyText text ->
            ( { model | lastCopied = Just { copiedAt = model.time, copiedText = text } }
            , Ports.copyToClipboard text
            )

        PressedCreateGuild ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn | newGuildForm = Just Pages.Guild.newGuildFormInit }
                    , Command.none
                    )
                )
                model

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
                                { loggedIn | newGuildForm = Nothing }
                                Command.none

                        Err _ ->
                            ( { loggedIn | newGuildForm = Just { newGuildForm | pressedSubmit = True } }
                            , Command.none
                            )
                )
                model

        PressedCancelNewGuild ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn | newGuildForm = Nothing }
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

        KeyDown key ->
            case key of
                "Escape" ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            let
                                loggedIn2 =
                                    MessageMenu.close model loggedIn

                                isPingUserDropdownOpen : Maybe ( LoggedIn2, Command FrontendOnly toMsg FrontendMsg )
                                isPingUserDropdownOpen =
                                    case loggedIn2.textInputFocus of
                                        Just textInputFocus ->
                                            if textInputFocus.htmlId == Emoji.searchInputId then
                                                ( { loggedIn2
                                                    | emojiSelector = Emoji.setSearch "" loggedIn2.emojiSelector
                                                  }
                                                , Dom.blur Emoji.searchInputId
                                                    |> Task.attempt
                                                        (\result ->
                                                            let
                                                                _ =
                                                                    Debug.log "result" result
                                                            in
                                                            RemoveFocus
                                                        )
                                                )
                                                    |> Just

                                            else
                                                case textInputFocus.dropdown of
                                                    Just _ ->
                                                        ( { loggedIn2
                                                            | textInputFocus = Just { textInputFocus | dropdown = Nothing }
                                                            , previousTextInputFocus = loggedIn2.textInputFocus
                                                            , showEmojiSelector = EmojiSelectorHidden
                                                          }
                                                        , Command.none
                                                        )
                                                            |> Just

                                                    Nothing ->
                                                        Nothing

                                        Nothing ->
                                            Nothing
                            in
                            case isPingUserDropdownOpen of
                                Just a ->
                                    a

                                Nothing ->
                                    case loggedIn2.showEmojiSelector of
                                        EmojiSelectorHidden ->
                                            case Route.toGuildOrDmId model.route of
                                                Just ( guildOrDmId, threadRoute ) ->
                                                    FrontendExtra.handleLocalChange
                                                        model.time
                                                        (case
                                                            LocalState.guildOrDmIdToMessagesCount
                                                                guildOrDmId
                                                                threadRoute
                                                                (Local.model loggedIn2.localState)
                                                         of
                                                            Just messages ->
                                                                Local_SetLastViewed
                                                                    guildOrDmId
                                                                    (case threadRoute of
                                                                        ViewThread threadId ->
                                                                            ViewThreadWithMessage
                                                                                threadId
                                                                                (messages - 1 |> Id.fromInt)

                                                                        NoThread ->
                                                                            NoThreadWithMessage
                                                                                (messages - 1 |> Id.fromInt)
                                                                    )
                                                                    |> Just

                                                            Nothing ->
                                                                Nothing
                                                        )
                                                        (if
                                                            SeqDict.member ( guildOrDmId, threadRoute ) loggedIn2.editMessage
                                                                || SeqDict.member ( guildOrDmId, NoThread ) loggedIn2.editMessage
                                                         then
                                                            { loggedIn2
                                                                | editMessage =
                                                                    SeqDict.remove ( guildOrDmId, threadRoute ) loggedIn2.editMessage
                                                                        |> SeqDict.remove ( guildOrDmId, NoThread )
                                                            }

                                                         else
                                                            { loggedIn2
                                                                | replyTo =
                                                                    SeqDict.remove ( guildOrDmId, threadRoute ) loggedIn2.replyTo
                                                            }
                                                        )
                                                        (FrontendExtra.setFocus model Pages.Guild.channelTextInputId)

                                                Nothing ->
                                                    ( loggedIn2, Command.none )

                                        _ ->
                                            ( { loggedIn2 | showEmojiSelector = EmojiSelectorHidden }, Command.none )
                        )
                        model

                _ ->
                    ( model, Command.none )

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
                                        EmojiOrSticker_Emoji emoji ->
                                            FrontendExtra.handleLocalChange
                                                model.time
                                                (Local_AddReactionEmoji guildOrDmId threadRoute emoji |> Just)
                                                { loggedIn | showEmojiSelector = EmojiSelectorHidden }
                                                (Scroll.toBottomOfChannelIfAtBottom loggedIn.channelScrollPosition)

                                        EmojiOrSticker_Sticker _ ->
                                            ( loggedIn, Command.none )

                                EmojiSelectorForMessage maybeSelection ->
                                    insertEmojiOrSticker Pages.Guild.channelTextInputId maybeSelection emojiOrSticker model loggedIn

                                EmojiSelectorForEditMessage _ maybeSelection ->
                                    insertEmojiOrSticker MessageMenu.editMessageTextInputId maybeSelection emojiOrSticker model loggedIn
                        )
                        model

                Emoji.PressedContainer ->
                    ( model, Command.none )

                Emoji.PressedCategory category ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            FrontendExtra.handleLocalChange
                                model.time
                                (Local_SetEmojiCategory category |> Just)
                                loggedIn
                                Command.none
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

                Emoji.MouseEnteredEmoji emoji ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            let
                                emojiSelector =
                                    loggedIn.emojiSelector
                            in
                            ( { loggedIn | emojiSelector = { emojiSelector | emojiHovered = Just emoji } }
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

        MessageMenu_PressedReply threadRoute ->
            case Route.toGuildOrDmId model.route of
                Just ( guildOrDmId, _ ) ->
                    pressedReply guildOrDmId threadRoute model

                Nothing ->
                    ( model, Command.none )

        MessageMenu_PressedOpenThread messageIndex ->
            case ( model.route, model.loginStatus ) of
                ( GuildRoute guildId (ChannelRoute channelId (NoThreadWithFriends _ _)), LoggedIn loggedIn ) ->
                    FrontendExtra.routePush
                        { model | loginStatus = MessageMenu.close model loggedIn |> LoggedIn }
                        (GuildRoute
                            guildId
                            (ChannelRoute channelId (ViewThreadWithFriends messageIndex Nothing HideMembersTab))
                        )

                ( DmRoute dmRoute, LoggedIn loggedIn ) ->
                    case dmRoute.threadRoute of
                        NoThreadWithFriends _ _ ->
                            FrontendExtra.routePush
                                { model | loginStatus = MessageMenu.close model loggedIn |> LoggedIn }
                                (DmRoute { dmRoute | threadRoute = ViewThreadWithFriends messageIndex Nothing HideMembersTab })

                        ViewThreadWithFriends _ _ _ ->
                            ( model, Command.none )

                ( DiscordGuildRoute guildRoute, LoggedIn loggedIn ) ->
                    case guildRoute.channelRoute of
                        DiscordChannel_ChannelRoute channelId (NoThreadWithFriends _ _) ->
                            FrontendExtra.routePush
                                { model | loginStatus = MessageMenu.close model loggedIn |> LoggedIn }
                                (DiscordGuildRoute
                                    { guildRoute
                                        | channelRoute =
                                            DiscordChannel_ChannelRoute
                                                channelId
                                                (ViewThreadWithFriends messageIndex Nothing HideMembersTab)
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
                        , Ports.setFavicon "favicon.ico"
                        , Ports.closeNotifications
                        ]
                    )

                Effect.Browser.Events.Hidden ->
                    ( model, Command.none )

        CheckedNotificationPermission notificationPermission ->
            ( { model | notificationPermission = notificationPermission }, Command.none )

        CheckedPwaStatus pwaStatus ->
            ( { model | pwaStatus = pwaStatus }, Command.none )

        TouchStart maybeGuildOrDmIdAndMessageIndex time touches ->
            touchStart maybeGuildOrDmIdAndMessageIndex time touches model

        TouchMoved time newTouches ->
            case model.drag of
                Dragging dragging ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            let
                                averageMove : { x : Float, y : Float }
                                averageMove =
                                    Touch.averageTouchMove dragging.touches newTouches |> Vector2d.unwrap
                            in
                            ( case ( loggedIn.showFileToUploadInfo, loggedIn.messageHover ) of
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
                                                        dragChannelSidebar time tHorizontal loggedIn.sidebarMode
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
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            ( if horizontalStart then
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
                                                dragChannelSidebar time tHorizontal loggedIn.sidebarMode
                                }

                              else
                                loggedIn
                            , Command.none
                            )
                        )
                        { model
                            | drag = Dragging { horizontalStart = horizontalStart, touches = startTouches }
                            , dragPrevious = model.drag
                        }

        TouchEnd time ->
            handleTouchEnd time model

        TouchCancel time ->
            handleTouchEnd time model

        ChannelSidebarAnimated elapsedTime ->
            let
                _ =
                    Debug.log "Animation frame" ()
            in
            case model.loginStatus of
                LoggedIn loggedIn ->
                    case loggedIn.sidebarMode of
                        ChannelSidebarClosed ->
                            ( model, Command.none )

                        ChannelSidebarOpened ->
                            ( model, Command.none )

                        ChannelSidebarOpening { offset } ->
                            let
                                offset2 =
                                    offset - Quantity.unwrap (Quantity.for elapsedTime sidebarSpeed)
                            in
                            ( { model
                                | loginStatus =
                                    { loggedIn
                                        | sidebarMode =
                                            if offset2 <= 0 then
                                                ChannelSidebarOpened

                                            else
                                                ChannelSidebarOpening { offset = offset2 }
                                    }
                                        |> LoggedIn
                              }
                            , Command.none
                            )

                        ChannelSidebarClosing { offset } ->
                            let
                                offset2 =
                                    offset + Quantity.unwrap (Quantity.for elapsedTime sidebarSpeed)

                                showMember =
                                    case model.route of
                                        GuildRoute _ (ChannelRoute _ threadRoute) ->
                                            case threadRoute of
                                                ViewThreadWithFriends _ _ showMembers2 ->
                                                    showMembers2

                                                NoThreadWithFriends _ showMembers2 ->
                                                    showMembers2

                                        DmRoute dmRoute ->
                                            case dmRoute.threadRoute of
                                                ViewThreadWithFriends _ _ showMembers2 ->
                                                    showMembers2

                                                NoThreadWithFriends _ showMembers2 ->
                                                    showMembers2

                                        _ ->
                                            HideMembersTab
                            in
                            case showMember of
                                ShowMembersTab ->
                                    if offset2 >= 1 then
                                        setShowMembers
                                            HideMembersTab
                                            { model
                                                | loginStatus =
                                                    { loggedIn | sidebarMode = ChannelSidebarOpened }
                                                        |> LoggedIn
                                            }

                                    else
                                        ( { model
                                            | loginStatus =
                                                { loggedIn
                                                    | sidebarMode =
                                                        ChannelSidebarClosing { offset = offset2 }
                                                }
                                                    |> LoggedIn
                                          }
                                        , Command.none
                                        )

                                HideMembersTab ->
                                    ( { model
                                        | loginStatus =
                                            { loggedIn
                                                | sidebarMode =
                                                    if offset2 >= 1 then
                                                        ChannelSidebarClosed

                                                    else
                                                        ChannelSidebarClosing { offset = offset2 }
                                            }
                                                |> LoggedIn
                                      }
                                    , Dom.blur Pages.Guild.channelTextInputId |> Task.attempt (\_ -> RemoveFocus)
                                    )

                        ChannelSidebarDragging _ ->
                            ( model, Command.none )

                NotLoggedIn _ ->
                    ( model, Command.none )

        SetScrollToBottom ->
            ( model, Command.none )

        PressedChannelHeaderBackButton ->
            FrontendExtra.updateLoggedIn (\loggedIn -> ( startClosingChannelSidebar loggedIn, Command.none )) model

        PressedShowMembers ->
            setShowMembers ShowMembersTab model

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
                                (case guildOrDmId of
                                    GuildOrDmId (GuildOrDmId_Guild guildId channelId) ->
                                        case LocalState.getGuildAndChannel guildId channelId local of
                                            Just ( _, channel ) ->
                                                (case threadRoute of
                                                    NoThread ->
                                                        Local_LoadChannelMessages
                                                            (GuildOrDmId_Guild guildId channelId)
                                                            channel.visibleMessages.oldest
                                                            EmptyPlaceholder

                                                    ViewThread threadId ->
                                                        Local_LoadThreadMessages
                                                            (GuildOrDmId_Guild guildId channelId)
                                                            threadId
                                                            (SeqDict.get threadId channel.threads
                                                                |> Maybe.withDefault Thread.frontendInit
                                                                |> .visibleMessages
                                                                |> .oldest
                                                            )
                                                            EmptyPlaceholder
                                                )
                                                    |> Just

                                            Nothing ->
                                                Nothing

                                    GuildOrDmId (GuildOrDmId_Dm otherUserId) ->
                                        let
                                            dmChannel : FrontendDmChannel
                                            dmChannel =
                                                SeqDict.get otherUserId local.dmChannels
                                                    |> Maybe.withDefault DmChannel.frontendInit
                                        in
                                        (case threadRoute of
                                            NoThread ->
                                                Local_LoadChannelMessages
                                                    (GuildOrDmId_Dm otherUserId)
                                                    dmChannel.visibleMessages.oldest
                                                    EmptyPlaceholder

                                            ViewThread threadId ->
                                                Local_LoadThreadMessages
                                                    (GuildOrDmId_Dm otherUserId)
                                                    threadId
                                                    (SeqDict.get threadId dmChannel.threads
                                                        |> Maybe.withDefault Thread.frontendInit
                                                        |> .visibleMessages
                                                        |> .oldest
                                                    )
                                                    EmptyPlaceholder
                                        )
                                            |> Just

                                    DiscordGuildOrDmId ((DiscordGuildOrDmId_Guild _ guildId channelId) as guildOrDmId2) ->
                                        case LocalState.getDiscordGuildAndChannel guildId channelId local of
                                            Just ( _, channel ) ->
                                                (case threadRoute of
                                                    NoThread ->
                                                        Local_Discord_LoadChannelMessages
                                                            guildOrDmId2
                                                            channel.visibleMessages.oldest
                                                            EmptyPlaceholder

                                                    ViewThread threadId ->
                                                        Local_Discord_LoadThreadMessages
                                                            guildOrDmId2
                                                            threadId
                                                            (SeqDict.get threadId channel.threads
                                                                |> Maybe.withDefault Thread.discordFrontendInit
                                                                |> .visibleMessages
                                                                |> .oldest
                                                            )
                                                            EmptyPlaceholder
                                                )
                                                    |> Just

                                            Nothing ->
                                                Nothing

                                    DiscordGuildOrDmId ((DiscordGuildOrDmId_Dm data) as guildOrDmId2) ->
                                        case SeqDict.get data.channelId local.discordDmChannels of
                                            Just dmChannel ->
                                                Local_Discord_LoadChannelMessages
                                                    guildOrDmId2
                                                    dmChannel.visibleMessages.oldest
                                                    EmptyPlaceholder
                                                    |> Just

                                            Nothing ->
                                                Nothing
                                )
                                { loggedIn | channelScrollPosition = scrollPosition }
                                Command.none

                        ScrolledToBottom ->
                            ( { loggedIn | channelScrollPosition = scrollPosition }, Command.none )

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

        CheckMessageAltPress startTime guildOrDmId threadRoute isThreadStarter ->
            case model.drag of
                DragStart dragStart _ ->
                    if startTime == dragStart then
                        FrontendExtra.updateLoggedIn
                            (\loggedIn ->
                                ( handleAltPressedMessage
                                    guildOrDmId
                                    threadRoute
                                    isThreadStarter
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
                    ( { loggedIn | userOptions = Just UserOptions.init }, Command.none )
                )
                model

        PressedCloseUserOptions ->
            FrontendExtra.updateLoggedIn
                (\loggedIn -> ( { loggedIn | userOptions = Nothing }, Command.none ))
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
                            LocalState.allUsers local.localUser
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
                                                RichText.fromNonemptyString allUsers draft
                                                    |> RichText.removeAttachedFile fileId
                                            of
                                                Just richText ->
                                                    RichText.toString allUsers richText
                                                        |> String.Nonempty.fromString

                                                Nothing ->
                                                    Nothing

                                        Nothing ->
                                            Nothing
                                )
                                loggedIn.drafts
                      }
                    , Command.none
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
                            LocalState.allUsers local.localUser
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
                                                            RichText.fromNonemptyString allUsers nonempty
                                                                |> RichText.removeAttachedFile fileId
                                                        of
                                                            Just richText ->
                                                                RichText.toString allUsers richText

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
                    , Command.none
                    )
                )
                model

        EditMessage_SelectedFilesToAttach guildOrDmId file files ->
            editMessage_gotFiles guildOrDmId (Nonempty file files) model

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
                                            FileUploading fileName fileSize contentType ->
                                                FileUploading
                                                    fileName
                                                    (case progress of
                                                        Http.Sending progress2 ->
                                                            progress2

                                                        Http.Receiving { received } ->
                                                            { sent = received, size = fileSize.size }
                                                    )
                                                    contentType

                                            FileUploaded _ ->
                                                fileStatus

                                            FileError _ _ _ _ ->
                                                fileStatus
                                    )
                                )
                                loggedIn.filesToUpload
                      }
                    , Command.none
                    )
                )
                model

        MessageViewMsg guildOrDmId threadRoute messageViewMsg ->
            let
                guildOrDmIdWithThread : ( AnyGuildOrDmId, ThreadRoute )
                guildOrDmIdWithThread =
                    ( guildOrDmId, Id.threadRouteWithoutMessage threadRoute )
            in
            case messageViewMsg of
                MessageView.MessageView_PressedSpoiler spoilerIndex ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            let
                                revealedSpoilers : RevealedSpoilers
                                revealedSpoilers =
                                    case loggedIn.revealedSpoilers of
                                        Just a ->
                                            if a.guildOrDmId == guildOrDmIdWithThread then
                                                a

                                            else
                                                { guildOrDmId = guildOrDmIdWithThread
                                                , messages = SeqDict.empty
                                                , threadMessages = SeqDict.empty
                                                }

                                        Nothing ->
                                            { guildOrDmId = guildOrDmIdWithThread
                                            , messages = SeqDict.empty
                                            , threadMessages = SeqDict.empty
                                            }
                            in
                            ( { loggedIn
                                | revealedSpoilers =
                                    (case threadRoute of
                                        ViewThreadWithMessage threadMessageIndex messageId ->
                                            { revealedSpoilers
                                                | threadMessages =
                                                    SeqDict.update
                                                        threadMessageIndex
                                                        (\maybe ->
                                                            SeqDict.update
                                                                messageId
                                                                (\maybe2 ->
                                                                    (case maybe2 of
                                                                        Just revealed ->
                                                                            NonemptySet.insert spoilerIndex revealed

                                                                        Nothing ->
                                                                            NonemptySet.singleton spoilerIndex
                                                                    )
                                                                        |> Just
                                                                )
                                                                (Maybe.withDefault SeqDict.empty maybe)
                                                                |> Just
                                                        )
                                                        revealedSpoilers.threadMessages
                                            }

                                        NoThreadWithMessage messageId ->
                                            { revealedSpoilers
                                                | messages =
                                                    SeqDict.update
                                                        messageId
                                                        (\maybe ->
                                                            (case maybe of
                                                                Just revealed ->
                                                                    NonemptySet.insert spoilerIndex revealed

                                                                Nothing ->
                                                                    NonemptySet.singleton spoilerIndex
                                                            )
                                                                |> Just
                                                        )
                                                        revealedSpoilers.messages
                                            }
                                    )
                                        |> Just
                              }
                            , Command.none
                            )
                        )
                        model

                MessageView.MessageView_MouseEnteredMessage ->
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

                MessageView.MessageView_MouseExitedMessage ->
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

                MessageView.MessageView_TouchStart time isThreadStarter touches ->
                    touchStart (Just ( guildOrDmId, threadRoute, isThreadStarter )) time touches model

                MessageView.MessageView_AltPressedMessage isThreadStarter clickedAt ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            ( handleAltPressedMessage
                                guildOrDmId
                                threadRoute
                                isThreadStarter
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
                                (Scroll.toBottomOfChannelIfAtBottom loggedIn.channelScrollPosition)
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
                                                ( GuildOrDmId_Guild guildId channelId, ViewThreadWithMaybeMessage threadId (Just repliedTo) ) ->
                                                    FrontendExtra.routePush
                                                        model
                                                        (GuildRoute guildId
                                                            (ChannelRoute
                                                                channelId
                                                                (ViewThreadWithFriends threadId (Just repliedTo) HideMembersTab)
                                                            )
                                                        )

                                                ( GuildOrDmId_Dm otherUserId, NoThreadWithMaybeMessage (Just repliedTo) ) ->
                                                    FrontendExtra.routePush
                                                        model
                                                        (DmRoute
                                                            { otherUserId = otherUserId
                                                            , threadRoute =
                                                                NoThreadWithFriends (Just repliedTo) HideMembersTab
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
                                                ( DiscordGuildOrDmId_Guild currentDiscordUserId guildId channelId, ViewThreadWithMaybeMessage threadId (Just repliedTo) ) ->
                                                    FrontendExtra.routePush
                                                        model
                                                        ({ currentDiscordUserId = currentDiscordUserId
                                                         , guildId = guildId
                                                         , channelRoute =
                                                            DiscordChannel_ChannelRoute
                                                                channelId
                                                                (ViewThreadWithFriends threadId (Just repliedTo) HideMembersTab)
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
                                                            , showMembersTab = HideMembersTab
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
                    pressedReply guildOrDmId threadRoute model

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
                        ( GuildOrDmId (GuildOrDmId_Guild guildId channelId), NoThreadWithMessage messageId ) ->
                            FrontendExtra.routePush
                                model
                                (GuildRoute
                                    guildId
                                    (ChannelRoute channelId (ViewThreadWithFriends messageId Nothing HideMembersTab))
                                )

                        ( GuildOrDmId (GuildOrDmId_Dm otherUserId), NoThreadWithMessage messageId ) ->
                            { otherUserId = otherUserId, threadRoute = ViewThreadWithFriends messageId Nothing HideMembersTab }
                                |> DmRoute
                                |> FrontendExtra.routePush model

                        ( DiscordGuildOrDmId (DiscordGuildOrDmId_Guild currentDiscordUserId guildId channelId), NoThreadWithMessage messageId ) ->
                            FrontendExtra.routePush
                                model
                                ({ currentDiscordUserId = currentDiscordUserId
                                 , guildId = guildId
                                 , channelRoute = DiscordChannel_ChannelRoute channelId (ViewThreadWithFriends messageId Nothing HideMembersTab)
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
                                    , showMembersTab = HideMembersTab
                                    }
                                )

                        _ ->
                            ( model, Command.none )

                MessageView.MessageView_PressedNonWhitelistLink url ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            ( { loggedIn | externalLinkWarning = Just url }
                            , Command.none
                            )
                        )
                        model

                MessageView.MessageView_NoOp ->
                    ( model, Command.none )

                MessageView.MessageViewMsg_PressedReactionEmoji emoji ->
                    FrontendExtra.updateLoggedIn (toggleReactionEmoji emoji guildOrDmId threadRoute model) model

        GotRegisterPushSubscription result ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    case result of
                        Ok endpoint ->
                            FrontendExtra.handleLocalChange
                                model.time
                                (Local_RegisterPushSubscription endpoint |> Just)
                                loggedIn
                                Command.none

                        Err _ ->
                            ( loggedIn, Command.none )
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
                                Command.none

                            PushNotifications ->
                                Ports.registerPushSubscriptionToJs (Local.model loggedIn.localState).publicVapidKey
                        )
                )
                model

        ProfilePictureEditorMsg imageEditorMsg ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    let
                        local : LocalState
                        local =
                            Local.model loggedIn.localState

                        ( newImageEditor, cmd ) =
                            ImageEditor.update
                                local.localUser.session.sessionIdHash
                                model.windowSize
                                imageEditorMsg
                                loggedIn.profilePictureEditor
                    in
                    ( { loggedIn | profilePictureEditor = newImageEditor }
                    , Command.map ProfilePictureEditorToBackend ProfilePictureEditorMsg cmd
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

        GotScrollbarWidth width ->
            ( { model | scrollbarWidth = width }, Command.none )

        GotUserAgent userAgent ->
            ( { model | userAgent = userAgent }, Command.none )

        PressedViewAttachedFileInfo guildOrDmId fileId ->
            viewImageInfo guildOrDmId fileId model

        EditMessage_PressedViewAttachedFileInfo guildOrDmId fileId ->
            viewImageInfo guildOrDmId fileId model

        PressedCloseImageInfo ->
            FrontendExtra.updateLoggedIn
                (\loggedIn -> ( { loggedIn | showFileToUploadInfo = Nothing }, Command.none ))
                model

        PressedMemberListBack ->
            FrontendExtra.updateLoggedIn (\loggedIn -> ( startClosingChannelSidebar loggedIn, Command.none )) model

        PageHasFocusChanged hasFocus ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    FrontendExtra.handleLocalChange
                        model.time
                        (if hasFocus then
                            Local_CurrentlyViewing (LocalState.routeToViewing model.route (Local.model loggedIn.localState)) |> Just

                         else
                            Local_CurrentlyViewing StopViewingChannel |> Just
                        )
                        loggedIn
                        (if hasFocus then
                            Ports.closeNotifications

                         else
                            Command.none
                        )
                )
                { model | pageHasFocus = hasFocus }

        GotServiceWorkerMessage url ->
            case Url.fromString url of
                Just url2 ->
                    FrontendExtra.routePush model (Route.decode url2)

                Nothing ->
                    ( model, Command.none )

        VisualViewportResized _ ->
            ( model, Command.none )

        TextEditorMsg textEditorMsg ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    let
                        local =
                            Local.model loggedIn.localState

                        ( textEditor, localChange ) =
                            TextEditor.update
                                local.localUser.session.userId
                                textEditorMsg
                                loggedIn.textEditor
                                local.textEditor
                    in
                    FrontendExtra.handleLocalChange
                        model.time
                        (Maybe.map Local_TextEditor localChange)
                        { loggedIn | textEditor = textEditor }
                        Command.none
                )
                model

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

        PressedLinkDiscordUser ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn
                        | userOptions =
                            Maybe.map
                                (\userOptions -> { userOptions | showLinkDiscordSetup = True })
                                loggedIn.userOptions
                      }
                    , Command.none
                    )
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
                                    , showMembersTab = HideMembersTab
                                    }
                                )

                        Nothing ->
                            ( model, Command.none )

                NotLoggedIn _ ->
                    ( model, Command.none )

        TypedDiscordLinkBookmarklet ->
            ( model, Command.none )

        GotVersionNumber result ->
            ( { model
                | versionNumber =
                    case result of
                        Ok version ->
                            Just version

                        Err _ ->
                            model.versionNumber
              }
            , Command.none
            )

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

        PressedRemoveDomainFromWhitelist domain ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    FrontendExtra.handleLocalChange
                        model.time
                        (Just (Local_SetDomainWhitelist False domain))
                        loggedIn
                        Command.none
                )
                model

        PressedContinueToSite ->
            FrontendExtra.updateLoggedIn
                (\loggedIn -> ( { loggedIn | externalLinkWarning = Nothing }, Command.none ))
                model

        EditMessage_MessageInputMsg guildOrDmId threadRoute messageInputMsg ->
            case messageInputMsg of
                MessageInput.PressedTextInput ->
                    ( { model | virtualKeyboardOpen = True }, Command.none )

                MessageInput.TypedMessage text ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            case SeqDict.get ( guildOrDmId, threadRoute ) loggedIn.editMessage of
                                Just edit ->
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
                                        (Process.sleep (Duration.seconds 1)
                                            |> Task.perform (\() -> DebouncedTyping)
                                        )

                                Nothing ->
                                    ( loggedIn, Command.none )
                        )
                        model

                MessageInput.PressedSendMessage ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            case SeqDict.get ( guildOrDmId, threadRoute ) loggedIn.editMessage of
                                Just edit ->
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
                                                                    (LocalState.allUsers local.localUser)
                                                                    nonempty
                                                        in
                                                        if message.content == richText then
                                                            Nothing

                                                        else
                                                            Local_SendEditMessage
                                                                model.time
                                                                guildOrDmId2
                                                                (case threadRoute of
                                                                    ViewThread threadId ->
                                                                        ViewThreadWithMessage threadId (Id.changeType edit.messageIndex)

                                                                    NoThread ->
                                                                        NoThreadWithMessage edit.messageIndex
                                                                )
                                                                richText
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
                                                                    (LocalState.allDiscordUsers local.localUser)
                                                                    nonempty
                                                        in
                                                        if message.content == richText then
                                                            Nothing

                                                        else
                                                            case guildOrDmId2 of
                                                                DiscordGuildOrDmId_Guild currentUserId guildId channelId ->
                                                                    Local_Discord_SendEditGuildMessage
                                                                        model.time
                                                                        currentUserId
                                                                        guildId
                                                                        channelId
                                                                        (case threadRoute of
                                                                            ViewThread threadId ->
                                                                                ViewThreadWithMessage threadId (Id.changeType edit.messageIndex)

                                                                            NoThread ->
                                                                                NoThreadWithMessage edit.messageIndex
                                                                        )
                                                                        richText
                                                                        |> Just

                                                                DiscordGuildOrDmId_Dm data ->
                                                                    Local_Discord_SendEditDmMessage
                                                                        model.time
                                                                        data
                                                                        edit.messageIndex
                                                                        richText
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

                MessageInput.PressedArrowInDropdown index ->
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
                                                            MessageInput.pressedArrowInDropdown
                                                                (MyUi.isMobile model)
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

                MessageInput.PressedArrowUpInEmptyInput ->
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
                                                    MessageInput.pressedDropdownItem
                                                        SetFocus
                                                        (MyUi.isMobile model)
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
                    editMessage_gotFiles ( guildOrDmId, threadRoute ) files model

                MessageInput.PressedOpenEmojiSelector ->
                    ( model
                    , Dom.getElement MessageMenu.editMessageTextInputId
                        |> Task.attempt GotEditMessageTextInputPositionForEmojiSelector
                    )

        GotEditMessageTextInputPositionForEmojiSelector result ->
            case result of
                Ok ok ->
                    pressedOpenEmojiSelector
                        MessageMenu.editMessageTextInputId
                        (EmojiSelectorForEditMessage (Coord.xy (round ok.element.x) (round ok.element.y)))
                        model

                Err _ ->
                    ( model, Command.none )

        MessageInputMsg guildOrDmId threadRoute messageInputMsg ->
            case messageInputMsg of
                MessageInput.PressedTextInput ->
                    ( { model | virtualKeyboardOpen = True }, Command.none )

                MessageInput.TypedMessage text ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
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
                                }
                                (Command.batch
                                    [ Process.sleep Pages.Guild.typingDebouncerDelay |> Task.perform (\() -> DebouncedTyping)
                                    , Scroll.toBottomOfChannelIfAtBottom loggedIn.channelScrollPosition
                                    , Ports.execCommand
                                        { htmlId = Pages.Guild.channelTextInputId
                                        , commands =
                                            List.map
                                                (\range -> { range = range, text = "" })
                                                (RichText.partialStickers text)
                                        }
                                    ]
                                )
                        )
                        model

                MessageInput.PressedSendMessage ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            let
                                guildOrDmIdWithThread : ( AnyGuildOrDmId, ThreadRoute )
                                guildOrDmIdWithThread =
                                    ( guildOrDmId, threadRoute )
                            in
                            case SeqDict.get guildOrDmIdWithThread loggedIn.drafts of
                                Just nonempty ->
                                    let
                                        local : LocalState
                                        local =
                                            Local.model loggedIn.localState

                                        safeToSend : Bool
                                        safeToSend =
                                            case guildOrDmId of
                                                GuildOrDmId _ ->
                                                    True

                                                DiscordGuildOrDmId guildOrDmId2 ->
                                                    LocalState.canSendDiscordMessage local guildOrDmId2 == Ok ()
                                    in
                                    if safeToSend then
                                        FrontendExtra.handleLocalChange
                                            model.time
                                            ((case guildOrDmId of
                                                GuildOrDmId guildOrDmId2 ->
                                                    Local_SendMessage
                                                        model.time
                                                        guildOrDmId2
                                                        (RichText.fromNonemptyString (LocalState.allUsers local.localUser) nonempty)
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

                                                DiscordGuildOrDmId guildOrDmId2 ->
                                                    Local_Discord_SendMessage
                                                        model.time
                                                        guildOrDmId2
                                                        (RichText.fromNonemptyString (LocalState.allDiscordUsers local.localUser) nonempty)
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
                                                Scroll.toBottomOfChannelSmooth

                                             else
                                                Scroll.toBottomOfChannel
                                            )

                                    else
                                        ( loggedIn, Command.none )

                                Nothing ->
                                    ( loggedIn, Command.none )
                        )
                        model

                MessageInput.PressedArrowInDropdown index ->
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
                                                            MessageInput.pressedArrowInDropdown
                                                                (MyUi.isMobile model)
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

                MessageInput.PressedArrowUpInEmptyInput ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            case guildOrDmId of
                                GuildOrDmId guildOrDmId2 ->
                                    let
                                        local : LocalState
                                        local =
                                            Local.model loggedIn.localState

                                        maybeMessages : Maybe (Array (MessageStateNoReply (Id UserId)))
                                        maybeMessages =
                                            LocalState.guildOrDmIdToMessages ( guildOrDmId2, threadRoute ) local
                                    in
                                    case maybeMessages of
                                        Just messages ->
                                            let
                                                messageCount : Int
                                                messageCount =
                                                    Array.length messages

                                                mostRecentMessage : Maybe ( Id ChannelMessageId, UserTextMessageDataNoReply (Id UserId) )
                                                mostRecentMessage =
                                                    (if messageCount < 5 then
                                                        Array.toList messages
                                                            |> List.indexedMap (\index data -> ( Id.fromInt index, data ))

                                                     else
                                                        Array.slice (messageCount - 5) messageCount messages
                                                            |> Array.toList
                                                            |> List.indexedMap
                                                                (\index message ->
                                                                    ( messageCount + index - 5 |> Id.fromInt, message )
                                                                )
                                                    )
                                                        |> List.reverse
                                                        |> List.Extra.findMap
                                                            (\( index, message ) ->
                                                                case message of
                                                                    MessageLoaded_NoReply message2 ->
                                                                        case message2 of
                                                                            UserTextMessage_NoReply data ->
                                                                                if local.localUser.session.userId == data.createdBy then
                                                                                    Just ( index, data )

                                                                                else
                                                                                    Nothing

                                                                            UserJoinedMessage_NoReply _ _ _ ->
                                                                                Nothing

                                                                            DeletedMessage_NoReply _ ->
                                                                                Nothing

                                                                    MessageUnloaded_NoReply ->
                                                                        Nothing
                                                            )
                                            in
                                            case mostRecentMessage of
                                                Just ( index, message ) ->
                                                    ( { loggedIn
                                                        | editMessage =
                                                            SeqDict.insert
                                                                ( GuildOrDmId guildOrDmId2, threadRoute )
                                                                { messageIndex = index
                                                                , text =
                                                                    RichText.toString (LocalState.allUsers local.localUser) message.content
                                                                , attachedFiles =
                                                                    SeqDict.map (\_ a -> FileUploaded a) message.attachedFiles
                                                                }
                                                                loggedIn.editMessage
                                                      }
                                                    , FrontendExtra.setFocus model MessageMenu.editMessageTextInputId
                                                    )

                                                Nothing ->
                                                    ( loggedIn, Command.none )

                                        Nothing ->
                                            ( loggedIn, Command.none )

                                DiscordGuildOrDmId guildOrDmId2 ->
                                    let
                                        local : LocalState
                                        local =
                                            Local.model loggedIn.localState

                                        maybeMessages : Maybe (Array (MessageStateNoReply (Discord.Id Discord.UserId)))
                                        maybeMessages =
                                            LocalState.discordGuildOrDmIdToMessages guildOrDmId2 threadRoute local

                                        currentUserId : Discord.Id Discord.UserId
                                        currentUserId =
                                            case guildOrDmId2 of
                                                DiscordGuildOrDmId_Guild currentUserId2 _ _ ->
                                                    currentUserId2

                                                DiscordGuildOrDmId_Dm data ->
                                                    data.currentUserId
                                    in
                                    case maybeMessages of
                                        Just messages ->
                                            let
                                                messageCount : Int
                                                messageCount =
                                                    Array.length messages

                                                mostRecentMessage : Maybe ( Id ChannelMessageId, UserTextMessageDataNoReply (Discord.Id Discord.UserId) )
                                                mostRecentMessage =
                                                    (if messageCount < 5 then
                                                        Array.toList messages
                                                            |> List.indexedMap (\index data -> ( Id.fromInt index, data ))

                                                     else
                                                        Array.slice (messageCount - 5) messageCount messages
                                                            |> Array.toList
                                                            |> List.indexedMap
                                                                (\index message ->
                                                                    ( messageCount + index - 5 |> Id.fromInt, message )
                                                                )
                                                    )
                                                        |> List.reverse
                                                        |> List.Extra.findMap
                                                            (\( index, message ) ->
                                                                case message of
                                                                    MessageLoaded_NoReply message2 ->
                                                                        case message2 of
                                                                            UserTextMessage_NoReply data ->
                                                                                if currentUserId == data.createdBy then
                                                                                    Just ( index, data )

                                                                                else
                                                                                    Nothing

                                                                            UserJoinedMessage_NoReply _ _ _ ->
                                                                                Nothing

                                                                            DeletedMessage_NoReply _ ->
                                                                                Nothing

                                                                    MessageUnloaded_NoReply ->
                                                                        Nothing
                                                            )
                                            in
                                            case mostRecentMessage of
                                                Just ( index, message ) ->
                                                    ( { loggedIn
                                                        | editMessage =
                                                            SeqDict.insert
                                                                ( DiscordGuildOrDmId guildOrDmId2, threadRoute )
                                                                { messageIndex = index
                                                                , text =
                                                                    RichText.toString
                                                                        (LocalState.allDiscordUsers local.localUser)
                                                                        message.content
                                                                , attachedFiles =
                                                                    SeqDict.map (\_ a -> FileUploaded a) message.attachedFiles
                                                                }
                                                                loggedIn.editMessage
                                                      }
                                                    , FrontendExtra.setFocus model MessageMenu.editMessageTextInputId
                                                    )

                                                Nothing ->
                                                    ( loggedIn, Command.none )

                                        Nothing ->
                                            ( loggedIn, Command.none )
                        )
                        model

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
                                                    MessageInput.pressedDropdownItem
                                                        SetFocus
                                                        (MyUi.isMobile model)
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
                    gotFiles guildOrDmId threadRoute files model

                MessageInput.PressedOpenEmojiSelector ->
                    pressedOpenEmojiSelector Pages.Guild.channelTextInputId EmojiSelectorForMessage model

        GotEmojiData result ->
            case result of
                Ok emojiData ->
                    ( { model | emojiData = Just emojiData }, Command.none )

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



--selectionChanged maybeHtmlId maybeRange model


messageHasReaction : Emoji -> AnyGuildOrDmId -> ThreadRouteWithMessage -> LocalState -> Bool
messageHasReaction emoji guildOrDmId threadRoute local =
    case guildOrDmId of
        GuildOrDmId guildOrDmId3 ->
            case LocalState.messageReactions guildOrDmId3 threadRoute local |> SeqDict.get emoji of
                Just reactions ->
                    NonemptySet.member local.localUser.session.userId reactions

                Nothing ->
                    False

        DiscordGuildOrDmId (DiscordGuildOrDmId_Guild currentUserId guildId channelId) ->
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


toggleReactionEmoji :
    Emoji
    -> AnyGuildOrDmId
    -> ThreadRouteWithMessage
    -> LoadedFrontend
    -> LoggedIn2
    -> ( LoggedIn2, Command FrontendOnly ToBackend FrontendMsg )
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
            Scroll.toBottomOfChannelIfAtBottom loggedIn.channelScrollPosition
        )


pressedOpenEmojiSelector : HtmlId -> (Maybe Range -> EmojiSelector) -> LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg )
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
                , emojiSelector = { emojiSelectorModel | searchText = "" }
              }
            , Command.none
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
            case ( emojiOrSticker, model.emojiData ) of
                ( EmojiOrSticker_Emoji emoji, Just emojiData ) ->
                    Emoji.emojiWithSkinTone
                        (Local.model loggedIn.localState).localUser.user.emojiConfig.skinTone
                        emoji
                        emojiData
                        ++ " "

                ( EmojiOrSticker_Sticker stickerId, _ ) ->
                    Sticker.idToString stickerId

                _ ->
                    ""
    in
    ( { loggedIn | showEmojiSelector = EmojiSelectorHidden }
    , case maybeSelection of
        Just range ->
            Ports.execCommand { htmlId = inputId, commands = [ { range = range, text = text } ] }

        Nothing ->
            Ports.execCommand
                { htmlId = inputId
                , commands = [ { range = { start = 99999, end = 99999 }, text = text } ]
                }
    )


selectionChanged :
    Maybe HtmlId
    -> Maybe ( Range, SelectionDirection )
    -> LoadedFrontend
    -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg )
selectionChanged maybeHtmlId maybeRange model =
    case ( maybeHtmlId, maybeRange ) of
        ( Just htmlId, Just ( range, direction ) ) ->
            case model.loginStatus of
                LoggedIn loggedIn ->
                    let
                        showDropdown : Bool
                        showDropdown =
                            ((htmlId == Pages.Guild.channelTextInputId) || (htmlId == MessageMenu.editMessageTextInputId))
                                && (case Route.toGuildOrDmId model.route of
                                        Just ( guildOrDmId, threadRoute ) ->
                                            case FrontendExtra.pingUserNameSoFar htmlId range guildOrDmId threadRoute loggedIn of
                                                Just (NameSoFar nameSoFar) ->
                                                    case guildOrDmId of
                                                        GuildOrDmId guildOrDmId2 ->
                                                            MessageInput.userDropdownList
                                                                (MyUi.isMobile model)
                                                                nameSoFar
                                                                guildOrDmId2
                                                                (Local.model loggedIn.localState)
                                                                |> List.isEmpty
                                                                |> not

                                                        DiscordGuildOrDmId guildOrDmId2 ->
                                                            MessageInput.discordUserDropdownList
                                                                (MyUi.isMobile model)
                                                                nameSoFar
                                                                guildOrDmId2
                                                                (Local.model loggedIn.localState)
                                                                |> List.isEmpty
                                                                |> not

                                                Just (EmojiSoFar emojiSoFar) ->
                                                    case model.emojiData of
                                                        Just emojiData2 ->
                                                            MessageInput.emojiDropdownList (MyUi.isMobile model) emojiSoFar emojiData2
                                                                |> List.isEmpty
                                                                |> not

                                                        Nothing ->
                                                            False

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
                            }
                                |> LoggedIn
                      }
                    , if showDropdown then
                        Dom.getElement htmlId
                            |> Task.map (\{ element } -> { dropdownIndex = 0, inputElement = element })
                            |> Task.attempt (GotPingUserPosition htmlId)

                      else
                        Command.none
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


textInputFocusChanged : Maybe HtmlId -> Maybe ( Range, SelectionDirection ) -> LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg )
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
                        [ if model.userAgent.device == UserAgent.Desktop || Maybe.map .htmlId loggedIn.textInputFocus == Just htmlId then
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


setShowMembers : ShowMembersTab -> LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg )
setShowMembers showMembers model =
    case model.route of
        GuildRoute guildId (ChannelRoute channelId threadRoute) ->
            case threadRoute of
                NoThreadWithFriends a _ ->
                    FrontendExtra.routePush
                        model
                        (GuildRoute guildId (ChannelRoute channelId (NoThreadWithFriends a showMembers)))

                ViewThreadWithFriends threadId a _ ->
                    FrontendExtra.routePush
                        model
                        (GuildRoute
                            guildId
                            (ChannelRoute channelId (ViewThreadWithFriends threadId a showMembers))
                        )

        DmRoute dmRoute ->
            case dmRoute.threadRoute of
                NoThreadWithFriends a _ ->
                    FrontendExtra.routePush model (DmRoute { dmRoute | threadRoute = NoThreadWithFriends a showMembers })

                ViewThreadWithFriends threadId a _ ->
                    FrontendExtra.routePush
                        model
                        (DmRoute { dmRoute | threadRoute = ViewThreadWithFriends threadId a showMembers })

        _ ->
            ( model, Command.none )


viewImageInfo :
    ( AnyGuildOrDmId, ThreadRoute )
    -> Id FileId
    -> LoadedFrontend
    -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg )
viewImageInfo guildOrDmId fileId model =
    FrontendExtra.updateLoggedIn
        (\loggedIn ->
            ( { loggedIn
                | showFileToUploadInfo =
                    case SeqDict.get guildOrDmId loggedIn.filesToUpload of
                        Just nonemptyDict ->
                            case NonemptyDict.get fileId nonemptyDict of
                                Just (FileStatus.FileUploaded fileData) ->
                                    case fileData.imageMetadata of
                                        Just metadata ->
                                            { fileName = fileData.fileName
                                            , fileSize = fileData.fileSize
                                            , imageMetadata = metadata
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


setLastViewedToLatestMessage : LoadedFrontend -> LoggedIn2 -> ( LoggedIn2, Command FrontendOnly ToBackend FrontendMsg )
setLastViewedToLatestMessage model loggedIn =
    FrontendExtra.handleLocalChange
        model.time
        (case Route.toGuildOrDmId model.route of
            Just ( guildOrDmId, threadRoute ) ->
                case LocalState.guildOrDmIdToMessagesCount guildOrDmId threadRoute (Local.model loggedIn.localState) of
                    Just messages ->
                        Local_SetLastViewed
                            guildOrDmId
                            (case threadRoute of
                                ViewThread threadMessageId ->
                                    ViewThreadWithMessage threadMessageId (messages - 1 |> Id.fromInt)

                                NoThread ->
                                    NoThreadWithMessage (messages - 1 |> Id.fromInt)
                            )
                            |> Just

                    Nothing ->
                        Nothing

            Nothing ->
                Nothing
        )
        loggedIn
        Command.none


handleEditable :
    Editable.Msg value
    -> (UserOptionsModel -> Editable.Model -> UserOptionsModel)
    -> (value -> LoggedIn2 -> ( LoggedIn2, Command FrontendOnly ToBackend FrontendMsg ))
    -> LoadedFrontend
    -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg )
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


pressedReply : AnyGuildOrDmId -> ThreadRouteWithMessage -> LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg )
pressedReply guildOrDmId threadRoute model =
    FrontendExtra.updateLoggedIn
        (\loggedIn ->
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
                , Scroll.toBottomOfChannelIfAtBottom loggedIn.channelScrollPosition
                ]
            )
        )
        model


pressedEditMessage : AnyGuildOrDmId -> ThreadRouteWithMessage -> LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg )
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
                                    ( RichText.toString (LocalState.allUsers local.localUser) message.content
                                    , message.attachedFiles
                                    )
                                        |> Just

                                Nothing ->
                                    Nothing

                        DiscordGuildOrDmId guildOrDmId2 ->
                            case LocalState.discordGuildOrDmIdToMessage guildOrDmId2 threadRoute local of
                                Just ( message, _ ) ->
                                    ( RichText.toString (LocalState.allDiscordUsers local.localUser) message.content
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
                , Scroll.toBottomOfChannelIfAtBottom loggedIn.channelScrollPosition
                ]
            )
        )
        model


showReactionEmojiSelector : AnyGuildOrDmId -> ThreadRouteWithMessage -> LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg )
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
                , emojiSelector = { emojiSelectorModel | searchText = "" }
              }
                |> MessageMenu.close model
            , Command.none
            )
        )
        model


touchStart :
    Maybe ( AnyGuildOrDmId, ThreadRouteWithMessage, Bool )
    -> Time.Posix
    -> NonemptyDict Int Touch
    -> LoadedFrontend
    -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg )
touchStart maybeGuildOrDmIdAndMessageIndex time touches model =
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
                                            (\() -> CheckMessageAltPress time guildOrMessageId messageIndex isThreadStarter)

                                Nothing ->
                                    Command.none

                        _ ->
                            Command.none
                    , case model.loginStatus of
                        LoggedIn loggedIn ->
                            case loggedIn.textInputFocus of
                                Just textInputFocus ->
                                    Dom.blur textInputFocus.htmlId |> Task.attempt (\_ -> RemoveFocus)

                                Nothing ->
                                    Command.none

                        NotLoggedIn _ ->
                            Command.none
                    ]
                )

        DragStart _ _ ->
            ( model, Command.none )

        Dragging _ ->
            ( model, Command.none )


gotFiles :
    AnyGuildOrDmId
    -> ThreadRoute
    -> Nonempty File
    -> LoadedFrontend
    -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg )
gotFiles guildOrDmId threadRoute files model =
    FrontendExtra.updateLoggedIn
        (\loggedIn ->
            let
                local : LocalState
                local =
                    Local.model loggedIn.localState

                ( fileText, cmds, dict ) =
                    case SeqDict.get ( guildOrDmId, threadRoute ) loggedIn.filesToUpload of
                        Just dict2 ->
                            List.Nonempty.foldl
                                (\file2 ( fileText2, cmds2, dict3 ) ->
                                    let
                                        id =
                                            Id.nextId (NonemptyDict.toSeqDict dict3)
                                    in
                                    ( fileText2
                                        ++ [ RichText.attachedFilePrefix
                                                ++ Id.toString id
                                                ++ RichText.attachedFileSuffix
                                           ]
                                    , FileStatus.uploadFile
                                        (GotFileHashName ( guildOrDmId, threadRoute ) id)
                                        local.localUser.session.sessionIdHash
                                        ( guildOrDmId, threadRoute )
                                        id
                                        file2
                                        :: cmds2
                                    , NonemptyDict.insert
                                        id
                                        (FileUploading
                                            (File.name file2 |> FileName.fromString)
                                            { sent = 0, size = File.size file2 }
                                            (File.mime file2 |> FileStatus.contentType)
                                        )
                                        dict3
                                    )
                                )
                                ( [], [], dict2 )
                                files

                        Nothing ->
                            ( List.indexedMap
                                (\index _ ->
                                    RichText.attachedFilePrefix
                                        ++ Id.toString (Id.fromInt (index + 1))
                                        ++ RichText.attachedFileSuffix
                                )
                                (List.Nonempty.toList files)
                            , List.indexedMap
                                (\index file2 ->
                                    let
                                        id : Id FileId
                                        id =
                                            Id.fromInt (index + 1)
                                    in
                                    FileStatus.uploadFile
                                        (GotFileHashName ( guildOrDmId, threadRoute ) id)
                                        local.localUser.session.sessionIdHash
                                        ( guildOrDmId, threadRoute )
                                        id
                                        file2
                                )
                                (List.Nonempty.toList files)
                            , List.Nonempty.indexedMap
                                (\index file2 ->
                                    ( Id.fromInt (index + 1)
                                    , FileUploading
                                        (File.name file2 |> FileName.fromString)
                                        { sent = 0, size = File.size file2 }
                                        (File.mime file2 |> FileStatus.contentType)
                                    )
                                )
                                files
                                |> NonemptyDict.fromNonemptyList
                            )
            in
            ( { loggedIn
                | filesToUpload =
                    SeqDict.insert ( guildOrDmId, threadRoute ) dict loggedIn.filesToUpload
                , drafts =
                    case String.join " " fileText |> String.Nonempty.fromString of
                        Just fileText2 ->
                            SeqDict.update
                                ( guildOrDmId, threadRoute )
                                (\maybe ->
                                    case maybe of
                                        Just draft ->
                                            String.Nonempty.append_ draft (" " ++ String.Nonempty.toString fileText2)
                                                |> Just

                                        Nothing ->
                                            Just fileText2
                                )
                                loggedIn.drafts

                        Nothing ->
                            loggedIn.drafts
              }
            , Command.batch cmds
            )
        )
        model


editMessage_gotFiles :
    ( AnyGuildOrDmId, ThreadRoute )
    -> Nonempty File
    -> LoadedFrontend
    -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg )
editMessage_gotFiles guildOrDmId files model =
    FrontendExtra.updateLoggedIn
        (\loggedIn ->
            case SeqDict.get guildOrDmId loggedIn.editMessage of
                Just edit ->
                    let
                        ( fileText, cmds, dict ) =
                            List.Nonempty.foldl
                                (\file2 ( fileText2, cmds2, dict3 ) ->
                                    let
                                        fileId : Id FileId
                                        fileId =
                                            Id.nextId dict3
                                    in
                                    ( fileText2
                                        ++ [ " "
                                                ++ RichText.attachedFilePrefix
                                                ++ Id.toString fileId
                                                ++ RichText.attachedFileSuffix
                                           ]
                                    , FileStatus.uploadFile
                                        (EditMessage_GotFileHashName guildOrDmId edit.messageIndex fileId)
                                        (Local.model loggedIn.localState).localUser.session.sessionIdHash
                                        guildOrDmId
                                        fileId
                                        file2
                                        :: cmds2
                                    , SeqDict.insert
                                        fileId
                                        (FileUploading
                                            (File.name file2 |> FileName.fromString)
                                            { sent = 0, size = File.size file2 }
                                            (File.mime file2 |> FileStatus.contentType)
                                        )
                                        dict3
                                    )
                                )
                                ( [], [], edit.attachedFiles )
                                files
                    in
                    ( { loggedIn
                        | editMessage =
                            SeqDict.insert
                                guildOrDmId
                                { edit
                                    | text = edit.text ++ String.concat fileText
                                    , attachedFiles = dict
                                }
                                loggedIn.editMessage
                      }
                    , Command.batch cmds
                    )

                Nothing ->
                    ( loggedIn, Command.none )
        )
        model


handleAltPressedMessage : AnyGuildOrDmId -> ThreadRouteWithMessage -> Bool -> Coord CssPixels -> LoggedIn2 -> LocalState -> LoadedFrontend -> LoggedIn2
handleAltPressedMessage guildOrDmId threadRoute isThreadStarter clickedAt loggedIn local model =
    { loggedIn
        | messageHover =
            MessageMenu
                { guildOrDmId = guildOrDmId
                , threadRoute = threadRoute
                , isThreadStarter = isThreadStarter
                , position = clickedAt
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


handleTouchEnd : Time.Posix -> LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg )
handleTouchEnd time model =
    FrontendExtra.updateLoggedIn
        (\loggedIn ->
            let
                loggedIn2 : LoggedIn2
                loggedIn2 =
                    case loggedIn.sidebarMode of
                        ChannelSidebarDragging a ->
                            let
                                delta : Duration
                                delta =
                                    Duration.from a.time time

                                sidebarDelta : Quantity Float (Rate CssPixels Seconds)
                                sidebarDelta =
                                    a.offset
                                        - a.previousOffset
                                        |> (*) (toFloat (Coord.xRaw model.windowSize))
                                        |> CssPixels.cssPixels
                                        |> Quantity.per delta
                            in
                            { loggedIn
                                | sidebarMode =
                                    if
                                        (sidebarDelta |> Quantity.lessThan (Quantity.unsafe -100))
                                            || ((a.offset < 0.5)
                                                    && (sidebarDelta |> Quantity.lessThan (Quantity.unsafe 100))
                                               )
                                    then
                                        ChannelSidebarOpening { offset = clamp 0 1 a.offset }

                                    else
                                        ChannelSidebarClosing { offset = clamp 0 1 a.offset }
                            }

                        _ ->
                            loggedIn
            in
            ( case loggedIn2.messageHover of
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
            , Process.sleep (Duration.milliseconds 30) |> Task.perform (\() -> OneFrameAfterDragEnd)
            )
        )
        { model | drag = NoDrag, dragPrevious = model.drag }


dragChannelSidebar : Time.Posix -> Float -> ChannelSidebarMode -> ChannelSidebarMode
dragChannelSidebar time delta sidebar =
    case sidebar of
        ChannelSidebarClosed ->
            ChannelSidebarDragging { offset = 1, previousOffset = 1, time = time }

        ChannelSidebarOpened ->
            ChannelSidebarDragging { offset = 0, previousOffset = 0, time = time }

        ChannelSidebarClosing { offset } ->
            ChannelSidebarDragging { offset = clamp 0 1 (offset + delta), previousOffset = offset, time = time }

        ChannelSidebarOpening { offset } ->
            ChannelSidebarDragging { offset = clamp 0 1 (offset + delta), previousOffset = offset, time = time }

        ChannelSidebarDragging record ->
            ChannelSidebarDragging
                { record | offset = clamp 0 1 (record.offset + delta), time = time }


isTouchingTextInput : NonemptyDict Int Touch -> Bool
isTouchingTextInput touches =
    NonemptyDict.any
        (\_ touch ->
            (touch.target == Just MessageMenu.editMessageTextInputId)
                || (touch.target == Just Pages.Guild.channelTextInputId)
        )
        touches


startClosingChannelSidebar : LoggedIn2 -> LoggedIn2
startClosingChannelSidebar loggedIn =
    { loggedIn
        | sidebarMode =
            ChannelSidebarClosing
                { offset =
                    case loggedIn.sidebarMode of
                        ChannelSidebarClosing { offset } ->
                            offset

                        ChannelSidebarClosed ->
                            1

                        ChannelSidebarOpened ->
                            0

                        ChannelSidebarOpening { offset } ->
                            offset

                        ChannelSidebarDragging { offset } ->
                            offset
                }
    }


sidebarSpeed : Quantity Float (Rate Unitless Seconds)
sidebarSpeed =
    Quantity.float 7 |> Quantity.per Duration.second


updateFromBackend : ToFrontend -> FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
updateFromBackend msg model =
    case model of
        Loading loading ->
            case msg of
                CheckLoginResponse result ->
                    case result of
                        Ok loginData ->
                            tryInitLoadedFrontend { loading | loginStatus = LoadSuccess loginData }

                        Err _ ->
                            tryInitLoadedFrontend { loading | loginStatus = LoadError }

                _ ->
                    ( model, Command.none )

        Loaded loaded ->
            updateLoadedFromBackend
                msg
                (case loaded.toFrontendLogs of
                    Just logs ->
                        { loaded | toFrontendLogs = Array.push msg logs |> Just }

                    Nothing ->
                        loaded
                )
                |> Tuple.mapFirst Loaded


updateLoadedFromBackend : ToFrontend -> LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg )
updateLoadedFromBackend msg model =
    case msg of
        CheckLoginResponse _ ->
            ( model, Command.none )

        LoginWithTokenResponse result ->
            case model.loginStatus of
                NotLoggedIn notLoggedIn ->
                    case result of
                        LoginSuccess loginData ->
                            let
                                ( loggedIn, cmdA ) =
                                    loadedInitHelper model.timezone model.userAgent loginData model

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
                                    ( GuildRoute guildId _, Just inviteLinkId ) ->
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
                    ( { loggedIn | localState = localState }
                    , case localChange of
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
                                                (NoThreadWithFriends Nothing HideMembersTab)
                                            )
                                        )

                                Nothing ->
                                    Command.none

                        Local_CurrentlyViewing viewing ->
                            case viewing of
                                ViewChannel guildId channelId _ ->
                                    case Route.toGuildOrDmId model.route of
                                        Just ( GuildOrDmId (GuildOrDmId_Guild guildIdRoute channelIdRoute), NoThread ) ->
                                            if guildId == guildIdRoute && channelId == channelIdRoute then
                                                Scroll.toBottomOfChannelIfAtBottom loggedIn.channelScrollPosition

                                            else
                                                Command.none

                                        _ ->
                                            Command.none

                                ViewDm otherUserId _ ->
                                    case Route.toGuildOrDmId model.route of
                                        Just ( GuildOrDmId (GuildOrDmId_Dm otherUserIdRoute), NoThread ) ->
                                            if otherUserId == otherUserIdRoute then
                                                Scroll.toBottomOfChannelIfAtBottom loggedIn.channelScrollPosition

                                            else
                                                Command.none

                                        _ ->
                                            Command.none

                                ViewChannelThread guildId channelId threadId _ ->
                                    case Route.toGuildOrDmId model.route of
                                        Just ( GuildOrDmId (GuildOrDmId_Guild guildIdRoute channelIdRoute), ViewThread threadIdRoute ) ->
                                            if guildId == guildIdRoute && channelId == channelIdRoute && threadId == threadIdRoute then
                                                Scroll.toBottomOfChannelIfAtBottom loggedIn.channelScrollPosition

                                            else
                                                Command.none

                                        _ ->
                                            Command.none

                                ViewDmThread otherUserId threadId _ ->
                                    case Route.toGuildOrDmId model.route of
                                        Just ( GuildOrDmId (GuildOrDmId_Dm otherUserIdRoute), ViewThread threadIdRoute ) ->
                                            if otherUserId == otherUserIdRoute && threadId == threadIdRoute then
                                                Scroll.toBottomOfChannelIfAtBottom loggedIn.channelScrollPosition

                                            else
                                                Command.none

                                        _ ->
                                            Command.none

                                StopViewingChannel ->
                                    Command.none

                                ViewDiscordChannel guildId channelId userId2 _ ->
                                    case Route.toGuildOrDmId model.route of
                                        Just ( DiscordGuildOrDmId (DiscordGuildOrDmId_Guild currentDiscordUserId guildIdRoute channelIdRoute), NoThread ) ->
                                            if userId2 == currentDiscordUserId && guildId == guildIdRoute && channelId == channelIdRoute then
                                                Scroll.toBottomOfChannelIfAtBottom loggedIn.channelScrollPosition

                                            else
                                                Command.none

                                        _ ->
                                            Command.none

                                ViewDiscordChannelThread guildId channelId userId2 threadId _ ->
                                    case Route.toGuildOrDmId model.route of
                                        Just ( DiscordGuildOrDmId (DiscordGuildOrDmId_Guild currentDiscordUserId guildIdRoute channelIdRoute), ViewThread threadIdRoute ) ->
                                            if userId2 == currentDiscordUserId && guildId == guildIdRoute && channelId == channelIdRoute && threadId == threadIdRoute then
                                                Scroll.toBottomOfChannelIfAtBottom loggedIn.channelScrollPosition

                                            else
                                                Command.none

                                        _ ->
                                            Command.none

                                ViewDiscordDm _ channelId _ ->
                                    case Route.toGuildOrDmId model.route of
                                        Just ( DiscordGuildOrDmId (DiscordGuildOrDmId_Dm data), NoThread ) ->
                                            if channelId == data.channelId then
                                                Scroll.toBottomOfChannelIfAtBottom loggedIn.channelScrollPosition

                                            else
                                                Command.none

                                        _ ->
                                            Command.none

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
                                        GuildRoute inviteGuildId _ ->
                                            if inviteGuildId == guildId then
                                                FrontendExtra.routeReplace
                                                    model
                                                    (GuildRoute
                                                        guildId
                                                        (ChannelRoute
                                                            (LocalState.announcementChannel guild)
                                                            (NoThreadWithFriends Nothing HideMembersTab)
                                                        )
                                                    )

                                            else
                                                Command.none

                                        _ ->
                                            Command.none
                                    )

                                Server_SendMessage senderId _ guildOrDmId content maybeRepliedTo _ _ ->
                                    let
                                        helper channel =
                                            Command.batch
                                                [ FrontendExtra.playNotificationSound
                                                    senderId
                                                    guildOrDmId
                                                    maybeRepliedTo
                                                    channel
                                                    local
                                                    content
                                                    model
                                                , case loggedIn2.channelScrollPosition of
                                                    ScrolledToBottom ->
                                                        if MyUi.isMobile model then
                                                            Scroll.toBottomOfChannelSmooth

                                                        else
                                                            Scroll.toBottomOfChannel

                                                    ScrolledToMiddle ->
                                                        Command.none

                                                    ScrolledToTop ->
                                                        Command.none
                                                ]
                                    in
                                    ( loggedIn2
                                    , case guildOrDmId of
                                        GuildOrDmId_Guild guildId channelId ->
                                            case LocalState.getGuildAndChannel guildId channelId local of
                                                Just ( _, channel ) ->
                                                    helper channel

                                                Nothing ->
                                                    Command.none

                                        GuildOrDmId_Dm otherUserId ->
                                            case SeqDict.get otherUserId local.dmChannels of
                                                Just channel ->
                                                    helper channel

                                                Nothing ->
                                                    Command.none
                                    )

                                Server_Discord_SendMessage _ guildOrDmId content maybeRepliedTo _ _ ->
                                    let
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
                                                , case loggedIn2.channelScrollPosition of
                                                    ScrolledToBottom ->
                                                        if MyUi.isMobile model then
                                                            Scroll.toBottomOfChannelSmooth

                                                        else
                                                            Scroll.toBottomOfChannel

                                                    ScrolledToMiddle ->
                                                        Command.none

                                                    ScrolledToTop ->
                                                        Command.none
                                                ]
                                    in
                                    ( loggedIn2
                                    , case guildOrDmId of
                                        DiscordGuildOrDmId_Guild senderId guildId channelId ->
                                            case LocalState.getDiscordGuildAndChannel guildId channelId local of
                                                Just ( _, channel ) ->
                                                    helper senderId channel

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
                                            ( GuildOrDmId (GuildOrDmId_Dm userId)
                                            , Id.threadRouteWithoutMessage threadRoute
                                            )
                                    in
                                    ( loggedIn2
                                    , if Route.toGuildOrDmId model.route == Just id then
                                        Scroll.toBottomOfChannelIfAtBottom loggedIn2.channelScrollPosition

                                      else
                                        Command.none
                                    )

                                Server_GotGuildMessageEmbed guildId channelId threadRoute _ ->
                                    let
                                        id : ( AnyGuildOrDmId, ThreadRoute )
                                        id =
                                            ( GuildOrDmId (GuildOrDmId_Guild guildId channelId)
                                            , Id.threadRouteWithoutMessage threadRoute
                                            )
                                    in
                                    ( loggedIn2
                                    , if Route.toGuildOrDmId model.route == Just id then
                                        Scroll.toBottomOfChannelIfAtBottom loggedIn2.channelScrollPosition

                                      else
                                        Command.none
                                    )

                                Server_GotDiscordDmMessageEmbed channelId _ _ ->
                                    ( loggedIn2
                                    , case Route.toGuildOrDmId model.route of
                                        Just ( DiscordGuildOrDmId (DiscordGuildOrDmId_Dm data), _ ) ->
                                            if channelId == data.channelId then
                                                Scroll.toBottomOfChannelIfAtBottom loggedIn2.channelScrollPosition

                                            else
                                                Command.none

                                        _ ->
                                            Command.none
                                    )

                                Server_GotDiscordGuildMessageEmbed guildIdA channelIdA threadRouteA _ ->
                                    ( loggedIn2
                                    , case Route.toGuildOrDmId model.route of
                                        Just ( DiscordGuildOrDmId (DiscordGuildOrDmId_Guild _ guildIdB channelIdB), threadRouteB ) ->
                                            if
                                                (guildIdA == guildIdB)
                                                    && (channelIdA == channelIdB)
                                                    && (Id.threadRouteWithoutMessage threadRouteA == threadRouteB)
                                            then
                                                Scroll.toBottomOfChannelIfAtBottom loggedIn2.channelScrollPosition

                                            else
                                                Command.none

                                        _ ->
                                            Command.none
                                    )

                                Server_AddReactionEmoji _ _ _ _ ->
                                    ( loggedIn2, Scroll.toBottomOfChannelIfAtBottom loggedIn2.channelScrollPosition )

                                Server_DiscordAddReactionGuildEmoji _ _ _ _ _ ->
                                    ( loggedIn2, Scroll.toBottomOfChannelIfAtBottom loggedIn2.channelScrollPosition )

                                Server_DiscordAddReactionDmEmoji _ _ _ _ ->
                                    ( loggedIn2, Scroll.toBottomOfChannelIfAtBottom loggedIn2.channelScrollPosition )

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

        YouConnected ->
            FrontendExtra.updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn | isReloading = True }
                    , Lamdera.sendToBackend (ReloadDataRequest (routeToInitialDataRequest model.route))
                    )
                )
                model

        ReloadDataResponse reloadData ->
            case reloadData of
                Ok loginData ->
                    FrontendExtra.updateLoggedIn
                        (\loggedIn ->
                            ( { loggedIn
                                | localState =
                                    loginDataToLocalState model.userAgent model.timezone loginData |> Local.init
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
                )
                model


view : FrontendModel -> Browser.Document FrontendMsg
view model =
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
                                [ Html.text "Something went wrong."
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

                    requiresLogin : (LoggedIn2 -> LocalState -> Element FrontendMsg) -> Html FrontendMsg
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
                                                (MyUi.isMobile loaded)
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
                                    ]
                                    (page loggedIn local)

                            NotLoggedIn notLoggedIn ->
                                LoginForm.view
                                    notLoggedIn.textInputFocus
                                    (Maybe.withDefault LoginForm.init notLoggedIn.loginForm)
                                    (MyUi.isMobile loaded)
                                    loaded.pwaStatus
                                    |> Ui.map LoginFormMsg
                                    |> FrontendExtra.layout loaded
                                        [ Ui.background MyUi.background3
                                        , Ui.inFront (Pages.Home.header isMobile loaded.loginStatus)
                                        ]
                in
                case loaded.route of
                    HomePageRoute ->
                        FrontendExtra.layout
                            loaded
                            [ Ui.background MyUi.background3
                            , case loaded.loginStatus of
                                LoggedIn loggedIn ->
                                    let
                                        local =
                                            Local.model loggedIn.localState
                                    in
                                    case loggedIn.userOptions of
                                        Just userOptions ->
                                            UserOptions.view
                                                (MyUi.isMobile loaded)
                                                loggedIn.textInputFocus
                                                loaded.time
                                                local
                                                loggedIn
                                                loaded
                                                userOptions
                                                |> Ui.inFront

                                        Nothing ->
                                            Ui.noAttr

                                NotLoggedIn _ ->
                                    Ui.noAttr
                            ]
                            (case loaded.loginStatus of
                                LoggedIn loggedIn ->
                                    Pages.Guild.homePageLoggedInView
                                        NoDmChannelSelected
                                        loaded
                                        loggedIn
                                        (Local.model loggedIn.localState)

                                NotLoggedIn notLoggedIn ->
                                    Ui.el
                                        [ Ui.inFront (Pages.Home.header isMobile loaded.loginStatus)
                                        , Ui.height Ui.fill
                                        ]
                                        (case notLoggedIn.loginForm of
                                            Just loginForm2 ->
                                                LoginForm.view notLoggedIn.textInputFocus loginForm2 (MyUi.isMobile loaded) loaded.pwaStatus
                                                    |> Ui.map LoginFormMsg

                                            Nothing ->
                                                Ui.Lazy.lazy Pages.Home.view windowWidth
                                        )
                            )

                    AdminRoute _ ->
                        requiresLogin
                            (\loggedIn local ->
                                case local.adminData of
                                    IsAdmin adminData ->
                                        case NonemptyDict.get local.localUser.session.userId adminData.users of
                                            Just user ->
                                                Pages.Admin.view
                                                    (MyUi.isMobile loaded)
                                                    loaded.versionNumber
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

                    AiChatRoute ->
                        AiChat.view loaded.windowSize loaded.aiChatModel
                            |> Ui.map AiChatMsg
                            |> FrontendExtra.layout loaded
                                [ if
                                    (loaded.aiChatModel.chatHistory == "")
                                        && (loaded.aiChatModel.message == "")
                                        && MyUi.isMobile loaded
                                        && (loaded.pwaStatus == BrowserView)
                                  then
                                    Ui.inFront
                                        (Ui.el
                                            [ Ui.centerX
                                            , Ui.centerY
                                            , Ui.widthMax 380
                                            , Ui.padding 16
                                            ]
                                            LoginForm.mobileWarning
                                        )

                                  else
                                    Ui.noAttr
                                ]

                    GuildRoute guildId maybeChannelId ->
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
                                            (MyUi.isMobile loaded)
                                            -- Don't show PWA warning on this login screen
                                            InstalledPwa
                                            |> Ui.map LoginFormMsg
                                        ]

                                ( LoggedIn _, Ok _ ) ->
                                    Ui.text "Linking..."

                                ( _, Err error ) ->
                                    errorPage
                                        loaded
                                        (case error of
                                            LinkDiscordExpired ->
                                                "This Discord link has expired"

                                            LinkDiscordServerError ->
                                                "Failed to link your Discord account due to a server error"

                                            LinkDiscordInvalidData ->
                                                "Failed to link your Discord account due to some problem with the bookmarklet"
                                        )
                            )
        ]
    }


errorPage : LoadedFrontend -> String -> Element FrontendMsg
errorPage model text =
    Ui.el
        [ Ui.inFront (Pages.Home.header (MyUi.isMobile model) model.loginStatus)
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
        GuildRoute guildId (ChannelRoute channelId threadRoute) ->
            InitialLoadRequested_Channel
                (GuildOrDmId_Guild guildId channelId |> GuildOrDmId)
                (case threadRoute of
                    ViewThreadWithFriends threadMessageId _ _ ->
                        ViewThread threadMessageId

                    NoThreadWithFriends _ _ ->
                        NoThread
                )

        DmRoute { otherUserId, threadRoute } ->
            InitialLoadRequested_Channel
                (GuildOrDmId_Dm otherUserId |> GuildOrDmId)
                (case threadRoute of
                    ViewThreadWithFriends threadMessageId _ _ ->
                        ViewThread threadMessageId

                    NoThreadWithFriends _ _ ->
                        NoThread
                )

        DiscordGuildRoute data ->
            case data.channelRoute of
                DiscordChannel_ChannelRoute channelId threadRoute ->
                    InitialLoadRequested_Channel
                        (DiscordGuildOrDmId_Guild data.currentDiscordUserId data.guildId channelId |> DiscordGuildOrDmId)
                        (case threadRoute of
                            ViewThreadWithFriends threadMessageId _ _ ->
                                ViewThread threadMessageId

                            NoThreadWithFriends _ _ ->
                                NoThread
                        )

                _ ->
                    InitialLoadRequested_None

        DiscordDmRoute data ->
            InitialLoadRequested_Channel
                (DiscordGuildOrDmId_Dm { currentUserId = data.currentDiscordUserId, channelId = data.channelId }
                    |> DiscordGuildOrDmId
                )
                NoThread

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
