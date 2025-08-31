module Frontend exposing (app, app_)

import AiChat
import Array exposing (Array)
import Browser exposing (UrlRequest(..))
import Browser.Navigation
import ChannelName
import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import DmChannel exposing (DmChannel)
import Duration exposing (Duration, Seconds)
import Ease
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
import Effect.Task as Task exposing (Task)
import Effect.Time as Time
import EmailAddress
import Emoji exposing (Emoji)
import Env
import FileName
import FileStatus exposing (FileData, FileId, FileStatus(..))
import GuildName
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Id exposing (ChannelId, ChannelMessageId, GuildOrDmId, GuildOrDmIdNoThread(..), Id, ThreadRoute(..), ThreadRouteWithMaybeMessage(..), ThreadRouteWithMessage(..), UserId)
import Json.Decode
import Lamdera as LamderaCore
import List.Extra
import List.Nonempty exposing (Nonempty(..))
import Local exposing (Local)
import LocalState exposing (AdminStatus(..), FrontendChannel, LocalState, LocalUser)
import LoginForm
import Message exposing (Message(..), UserTextMessageData)
import MessageInput
import MessageMenu
import MessageView
import MyUi
import NonemptyDict exposing (NonemptyDict)
import NonemptySet
import Pages.Admin
import Pages.Guild
import Pages.Home
import Pagination
import Ports exposing (PwaStatus(..))
import Quantity exposing (Quantity, Rate, Unitless)
import RichText exposing (RichText)
import Route exposing (ChannelRoute(..), Route(..))
import SeqDict exposing (SeqDict)
import SeqSet
import String.Nonempty
import Touch exposing (Touch)
import TwoFactorAuthentication exposing (TwoFactorState(..))
import Types exposing (AdminStatusLoginData(..), ChannelSidebarMode(..), Drag(..), EmojiSelector(..), FrontendModel(..), FrontendMsg(..), LoadStatus(..), LoadedFrontend, LoadingFrontend, LocalChange(..), LocalMsg(..), LoggedIn2, LoginData, LoginResult(..), LoginStatus(..), MessageHover(..), MessageHoverMobileMode(..), RevealedSpoilers, ServerChange(..), ToBackend(..), ToBeFilledInByBackend(..), ToFrontend(..))
import Ui exposing (Element)
import Ui.Anim
import Ui.Font
import Ui.Lazy
import Url exposing (Url)
import User exposing (BackendUser)
import UserOptions
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
        , Ports.isPushNotificationsRegisteredSubscription GotIsPushNotificationsRegistered
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
                                            MessageMenuClosing _ ->
                                                Effect.Browser.Events.onAnimationFrameDelta MessageMenuAnimated

                                            MessageMenuOpening _ ->
                                                Effect.Browser.Events.onAnimationFrameDelta MessageMenuAnimated

                                            MessageMenuDragging _ ->
                                                Subscription.none

                                            MessageMenuFixed _ ->
                                                Subscription.none
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
        , enabledPushNotifications = False
        }
    , Command.batch
        [ Task.perform GotTime Time.now
        , BrowserNavigation.replaceUrl key (Route.encode route)
        , Task.perform (\{ viewport } -> GotWindowSize (round viewport.width) (round viewport.height)) Dom.getViewport
        , Lamdera.sendToBackend CheckLoginRequest
        , Ports.loadSounds
        , Ports.checkNotificationPermission
        , Ports.checkPwaStatus
        , Task.perform GotTimezone Time.here
        , Ports.isPushNotificationsRegistered
        ]
    )


initLoadedFrontend :
    LoadingFrontend
    -> Time.Posix
    -> Result () LoginData
    -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg )
initLoadedFrontend loading time loginResult =
    let
        ( loginStatus, cmdB ) =
            case loginResult of
                Ok loginData ->
                    loadedInitHelper time loading.timezone loginData loading |> Tuple.mapFirst LoggedIn

                Err () ->
                    ( NotLoggedIn
                        { loginForm = Nothing
                        , useInviteAfterLoggedIn = Nothing
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
            , textInputFocus = Nothing
            , notificationPermission = loading.notificationPermission
            , pwaStatus = loading.pwaStatus
            , drag = NoDrag
            , dragPrevious = NoDrag
            , scrolledToBottomOfChannel = True
            , aiChatModel = aiChatModel
            , enabledPushNotifications = loading.enabledPushNotifications
            }

        ( model2, cmdA ) =
            routeRequest Nothing model.route model
    in
    ( model2
    , Command.batch [ cmdB, cmdA, Command.map AiChatToBackend AiChatMsg aiChatCmd ]
    )


loadedInitHelper :
    Time.Posix
    -> Time.Zone
    -> LoginData
    -> { a | windowSize : Coord CssPixels, navigationKey : Key, route : Route }
    -> ( LoggedIn2, Command FrontendOnly ToBackend FrontendMsg )
loadedInitHelper time timezone loginData loading =
    let
        localState : LocalState
        localState =
            loginDataToLocalState timezone loginData

        maybeAdmin : Maybe ( Pages.Admin.Model, Maybe Pages.Admin.AdminChange, Command FrontendOnly ToBackend msg )
        maybeAdmin =
            case loginData.adminData of
                IsAdminLoginData _ ->
                    let
                        ( logPagination, paginationCmd ) =
                            Pagination.init localState.localUser.user.lastLogPageViewed
                    in
                    Pages.Admin.init
                        logPagination
                        (case loading.route of
                            AdminRoute params ->
                                params

                            _ ->
                                { highlightLog = Nothing }
                        )
                        |> (\( a, b ) ->
                                ( a
                                , b
                                , Command.map
                                    (\toMsg -> Pages.Admin.LogPaginationToBackend toMsg |> AdminToBackend)
                                    identity
                                    paginationCmd
                                )
                           )
                        |> Just

                IsNotAdminLoginData ->
                    Nothing

        loggedIn : LoggedIn2
        loggedIn =
            { localState = Local.init localState
            , admin = Maybe.map (\( a, _, _ ) -> a) maybeAdmin
            , drafts = SeqDict.empty
            , newChannelForm = SeqDict.empty
            , editChannelForm = SeqDict.empty
            , newGuildForm = Nothing
            , channelNameHover = Nothing
            , typingDebouncer = True
            , pingUser = Nothing
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
            , sessionId = loginData.sessionId
            , isReloading = False
            }

        cmds : Command FrontendOnly ToBackend FrontendMsg
        cmds =
            Command.batch
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
                , case maybeAdmin of
                    Just ( _, _, cmd ) ->
                        cmd

                    Nothing ->
                        Command.none
                ]
    in
    handleLocalChange
        time
        (case maybeAdmin of
            Just ( _, Just adminChange, _ ) ->
                Local_Admin adminChange |> Just

            _ ->
                Nothing
        )
        loggedIn
        cmds


loginDataToLocalState : Time.Zone -> LoginData -> LocalState
loginDataToLocalState timezone loginData =
    { adminData =
        case loginData.adminData of
            IsAdminLoginData adminData ->
                IsAdmin
                    { users = adminData.users
                    , emailNotificationsEnabled = adminData.emailNotificationsEnabled
                    , twoFactorAuthentication = adminData.twoFactorAuthentication
                    , botToken = adminData.botToken
                    , privateVapidKey = adminData.privateVapidKey
                    }

            IsNotAdminLoginData ->
                IsNotAdmin
    , guilds = loginData.guilds
    , dmChannels = loginData.dmChannels
    , joinGuildError = Nothing
    , localUser =
        { userId = loginData.userId
        , user = loginData.user
        , otherUsers = loginData.otherUsers
        , timezone = timezone
        }
    , publicVapidKey = loginData.publicVapidKey
    }


tryInitLoadedFrontend : LoadingFrontend -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
tryInitLoadedFrontend loading =
    Maybe.map2
        (\time loginResult -> initLoadedFrontend loading time loginResult |> Tuple.mapFirst Loaded)
        loading.time
        (case loading.loginStatus of
            LoadingData ->
                Nothing

            LoadSuccess loginData ->
                Just (Ok loginData)

            LoadError ->
                Just (Err ())
        )
        |> Maybe.withDefault ( Loading loading, Command.none )


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

                GotIsPushNotificationsRegistered isEnabled ->
                    tryInitLoadedFrontend { loading | enabledPushNotifications = isEnabled }

                _ ->
                    ( model, Command.none )

        Loaded loaded ->
            case ( isPressMsg msg, loaded.dragPrevious ) of
                ( True, Dragging _ ) ->
                    ( model, Command.none )

                _ ->
                    updateLoaded msg loaded |> Tuple.mapFirst Loaded


routeRequest : Maybe Route -> Route -> LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg )
routeRequest previousRoute newRoute model =
    let
        model2 : LoadedFrontend
        model2 =
            { model | route = newRoute }
    in
    case newRoute of
        HomePageRoute ->
            ( { model2
                | loginStatus =
                    case model2.loginStatus of
                        NotLoggedIn notLoggedIn ->
                            NotLoggedIn { notLoggedIn | loginForm = Nothing }

                        LoggedIn _ ->
                            model2.loginStatus
              }
            , Command.none
            )

        AdminRoute { highlightLog } ->
            updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn
                        | admin =
                            case loggedIn.admin of
                                Just admin ->
                                    Just { admin | highlightLog = highlightLog }

                                Nothing ->
                                    loggedIn.admin
                      }
                    , Command.none
                    )
                )
                model2

        GuildRoute guildId channelRoute ->
            let
                model3 : LoadedFrontend
                model3 =
                    { model2
                        | loginStatus =
                            case model2.loginStatus of
                                LoggedIn loggedIn ->
                                    LoggedIn { loggedIn | revealedSpoilers = Nothing }

                                NotLoggedIn _ ->
                                    model2.loginStatus
                    }

                ( sameGuild, sameChannel ) =
                    case previousRoute of
                        Just (GuildRoute previousGuildId previousChannelRoute) ->
                            ( guildId == previousGuildId
                            , guildId == previousGuildId && channelRoute == previousChannelRoute
                            )

                        _ ->
                            ( False, False )
            in
            case channelRoute of
                ChannelRoute channelId threadRoute ->
                    updateLoggedIn
                        (\loggedIn ->
                            let
                                scrollToBottom : Command FrontendOnly ToBackend FrontendMsg
                                scrollToBottom =
                                    if sameChannel then
                                        Command.none

                                    else
                                        Process.sleep Duration.millisecond
                                            |> Task.andThen (\() -> Dom.setViewportOf Pages.Guild.conversationContainerId 0 9999999)
                                            |> Task.attempt (\_ -> ScrolledToBottom)
                            in
                            handleLocalChange
                                model3.time
                                (Just (Local_ViewChannel guildId channelId))
                                (if sameGuild || previousRoute == Nothing then
                                    startOpeningChannelSidebar loggedIn

                                 else
                                    loggedIn
                                )
                                (Command.batch
                                    [ setFocus model3 Pages.Guild.channelTextInputId
                                    , case threadRoute of
                                        ViewThreadWithMaybeMessage _ maybeMessageIndex ->
                                            case maybeMessageIndex of
                                                Just messageIndex ->
                                                    smoothScroll (Pages.Guild.threadMessageHtmlId messageIndex)
                                                        |> Task.attempt (\_ -> ScrolledToMessage)

                                                Nothing ->
                                                    scrollToBottom

                                        NoThreadWithMaybeMessage maybeMessageIndex ->
                                            case maybeMessageIndex of
                                                Just messageIndex ->
                                                    smoothScroll (Pages.Guild.channelMessageHtmlId messageIndex)
                                                        |> Task.attempt (\_ -> ScrolledToMessage)

                                                Nothing ->
                                                    scrollToBottom
                                    ]
                                )
                        )
                        model3

                NewChannelRoute ->
                    updateLoggedIn
                        (\loggedIn ->
                            ( if sameGuild || previousRoute == Nothing then
                                startOpeningChannelSidebar loggedIn

                              else
                                loggedIn
                            , Command.none
                            )
                        )
                        model3

                EditChannelRoute _ ->
                    updateLoggedIn
                        (\loggedIn ->
                            ( if sameGuild || previousRoute == Nothing then
                                startOpeningChannelSidebar loggedIn

                              else
                                loggedIn
                            , Command.none
                            )
                        )
                        model3

                InviteLinkCreatorRoute ->
                    updateLoggedIn
                        (\loggedIn ->
                            ( if sameGuild || previousRoute == Nothing then
                                startOpeningChannelSidebar loggedIn

                              else
                                loggedIn
                            , Command.none
                            )
                        )
                        model3

                JoinRoute inviteLinkId ->
                    case model3.loginStatus of
                        NotLoggedIn notLoggedIn ->
                            ( { model3
                                | loginStatus =
                                    { notLoggedIn | useInviteAfterLoggedIn = Just inviteLinkId }
                                        |> NotLoggedIn
                              }
                            , Command.none
                            )

                        LoggedIn loggedIn ->
                            let
                                local =
                                    Local.model loggedIn.localState
                            in
                            ( model3
                            , Command.batch
                                [ JoinGuildByInviteRequest guildId inviteLinkId |> Lamdera.sendToBackend
                                , case SeqDict.get guildId local.guilds of
                                    Just guild ->
                                        routeReplace
                                            model3
                                            (GuildRoute
                                                guildId
                                                (ChannelRoute (LocalState.announcementChannel guild) (NoThreadWithMaybeMessage Nothing))
                                            )

                                    Nothing ->
                                        Command.none
                                ]
                            )

        AiChatRoute ->
            ( model2, Command.map AiChatToBackend AiChatMsg AiChat.getModels )

        DmRoute _ threadRoute ->
            let
                model3 : LoadedFrontend
                model3 =
                    { model2
                        | loginStatus =
                            case model2.loginStatus of
                                LoggedIn loggedIn ->
                                    LoggedIn { loggedIn | revealedSpoilers = Nothing }

                                NotLoggedIn _ ->
                                    model2.loginStatus
                    }
            in
            updateLoggedIn
                (\loggedIn ->
                    let
                        scrollToBottom : Command FrontendOnly ToBackend FrontendMsg
                        scrollToBottom =
                            Process.sleep Duration.millisecond
                                |> Task.andThen (\() -> Dom.setViewportOf Pages.Guild.conversationContainerId 0 9999999)
                                |> Task.attempt (\_ -> ScrolledToBottom)
                    in
                    ( startOpeningChannelSidebar loggedIn
                    , Command.batch
                        [ setFocus model3 Pages.Guild.channelTextInputId
                        , case threadRoute of
                            ViewThreadWithMaybeMessage _ maybeMessageIndex ->
                                case maybeMessageIndex of
                                    Just messageIndex ->
                                        smoothScroll (Pages.Guild.threadMessageHtmlId messageIndex)
                                            |> Task.attempt (\_ -> ScrolledToMessage)

                                    Nothing ->
                                        scrollToBottom

                            NoThreadWithMaybeMessage maybeMessageIndex ->
                                case maybeMessageIndex of
                                    Just messageIndex ->
                                        smoothScroll (Pages.Guild.channelMessageHtmlId messageIndex)
                                            |> Task.attempt (\_ -> ScrolledToMessage)

                                    Nothing ->
                                        scrollToBottom
                        ]
                    )
                )
                model3


routeRequiresLogin : Route -> Bool
routeRequiresLogin route =
    case route of
        HomePageRoute ->
            False

        AdminRoute _ ->
            True

        AiChatRoute ->
            False

        GuildRoute _ _ ->
            True

        DmRoute _ _ ->
            True


isPressMsg : FrontendMsg -> Bool
isPressMsg msg =
    case msg of
        UrlClicked _ ->
            False

        UrlChanged _ ->
            False

        GotTime _ ->
            False

        GotWindowSize _ _ ->
            False

        LoginFormMsg loginFormMsg ->
            LoginForm.isPressMsg loginFormMsg

        PressedShowLogin ->
            True

        AdminPageMsg _ ->
            False

        PressedLogOut ->
            True

        ElmUiMsg _ ->
            False

        ScrolledToLogSection ->
            False

        PressedLink _ ->
            True

        TypedMessage _ _ ->
            False

        PressedSendMessage _ _ ->
            True

        NewChannelFormChanged _ _ ->
            False

        PressedSubmitNewChannel _ _ ->
            False

        MouseEnteredChannelName _ _ _ ->
            False

        MouseExitedChannelName _ _ _ ->
            False

        EditChannelFormChanged _ _ _ ->
            False

        PressedCancelEditChannelChanges _ _ ->
            True

        PressedSubmitEditChannelChanges _ _ _ ->
            True

        PressedDeleteChannel _ _ ->
            True

        PressedCreateInviteLink _ ->
            True

        FrontendNoOp ->
            False

        PressedCopyText _ ->
            True

        PressedCreateGuild ->
            True

        NewGuildFormChanged _ ->
            False

        PressedSubmitNewGuild _ ->
            True

        PressedCancelNewGuild ->
            True

        DebouncedTyping ->
            False

        GotPingUserPosition _ ->
            False

        PressedPingUser _ _ ->
            True

        SetFocus ->
            False

        RemoveFocus ->
            False

        PressedArrowInDropdown _ _ ->
            True

        TextInputGotFocus _ ->
            False

        TextInputLostFocus _ ->
            False

        KeyDown _ ->
            False

        MessageMenu_PressedShowReactionEmojiSelector _ _ _ ->
            True

        MessageMenu_PressedEditMessage _ _ ->
            True

        PressedEmojiSelectorEmoji _ ->
            True

        GotPingUserPositionForEditMessage _ ->
            False

        TypedEditMessage _ _ ->
            False

        PressedSendEditMessage _ ->
            True

        PressedArrowInDropdownForEditMessage _ _ ->
            True

        PressedPingUserForEditMessage _ _ ->
            True

        PressedArrowUpInEmptyInput _ ->
            True

        MessageMenu_PressedReply _ ->
            True

        PressedCloseReplyTo _ ->
            True

        VisibilityChanged _ ->
            False

        CheckedNotificationPermission _ ->
            False

        CheckedPwaStatus _ ->
            False

        TouchStart _ _ _ ->
            False

        TouchMoved _ _ ->
            False

        TouchEnd _ ->
            False

        TouchCancel _ ->
            False

        ChannelSidebarAnimated _ ->
            False

        MessageMenuAnimated _ ->
            False

        ScrolledToBottom ->
            False

        PressedChannelHeaderBackButton ->
            True

        UserScrolled _ ->
            False

        PressedBody ->
            True

        PressedReactionEmojiContainer ->
            True

        MessageMenu_PressedDeleteMessage _ _ ->
            True

        ScrolledToMessage ->
            False

        MessageMenu_PressedClose ->
            True

        MessageMenu_PressedContainer ->
            True

        PressedCancelMessageEdit _ ->
            True

        PressedPingDropdownContainer ->
            True

        PressedEditMessagePingDropdownContainer ->
            True

        CheckMessageAltPress _ _ _ _ ->
            False

        PressedShowUserOption ->
            True

        PressedCloseUserOptions ->
            True

        TwoFactorMsg twoFactorMsg ->
            TwoFactorAuthentication.isPressMsg twoFactorMsg

        AiChatMsg aiChatMsg ->
            AiChat.isPressMsg aiChatMsg

        UserNameEditableMsg editableMsg ->
            Editable.isPressMsg editableMsg

        BotTokenEditableMsg editableMsg ->
            Editable.isPressMsg editableMsg

        PublicVapidKeyEditableMsg editableMsg ->
            Editable.isPressMsg editableMsg

        OneFrameAfterDragEnd ->
            False

        PressedAttachFiles _ ->
            True

        SelectedFilesToAttach _ _ _ ->
            False

        GotFileHashName _ _ _ ->
            False

        PressedDeleteAttachedFile _ _ ->
            True

        EditMessage_PressedDeleteAttachedFile _ _ ->
            True

        EditMessage_PressedAttachFiles _ ->
            True

        EditMessage_SelectedFilesToAttach _ _ _ ->
            False

        EditMessage_GotFileHashName _ _ _ _ ->
            False

        EditMessage_PastedFiles _ _ ->
            False

        PastedFiles _ _ ->
            False

        PressedTextInput ->
            True

        GotTimezone _ ->
            False

        FileUploadProgress _ _ _ ->
            False

        MessageMenu_PressedOpenThread _ ->
            True

        MessageViewMsg _ _ messageViewMsg ->
            MessageView.isPressMsg messageViewMsg

        GotRegisterPushSubscription _ ->
            False

        ToggledEnablePushNotifications _ ->
            True

        GotIsPushNotificationsRegistered _ ->
            False

        PrivateVapidKeyEditableMsg editableMsg ->
            Editable.isPressMsg editableMsg


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
                    ( model, BrowserNavigation.load url )

        UrlChanged url ->
            routeRequest (Just model.route) (Route.decode url) model

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
            updateLoggedIn
                (\loggedIn ->
                    case ( loggedIn.admin, (Local.model loggedIn.localState).adminData ) of
                        ( Just admin, IsAdmin adminData ) ->
                            let
                                ( newAdmin, cmd, maybeLocalChange ) =
                                    Pages.Admin.update
                                        model.navigationKey
                                        model.time
                                        adminData
                                        (Local.model loggedIn.localState)
                                        adminPageMsg
                                        admin
                            in
                            handleLocalChange
                                model.time
                                (Maybe.map Local_Admin maybeLocalChange)
                                { loggedIn | admin = Just newAdmin }
                                (Command.map AdminToBackend AdminPageMsg cmd)

                        _ ->
                            ( loggedIn, Command.none )
                )
                model

        LoginFormMsg loginFormMsg ->
            case model.loginStatus of
                LoggedIn _ ->
                    ( model, Command.none )

                NotLoggedIn notLoggedIn ->
                    case
                        LoginForm.update
                            (\email -> GetLoginTokenRequest email |> Lamdera.sendToBackend)
                            (\loginToken -> LoginWithTokenRequest loginToken |> Lamdera.sendToBackend)
                            (\loginToken -> LoginWithTwoFactorRequest loginToken |> Lamdera.sendToBackend)
                            (\name -> FinishUserCreationRequest name |> Lamdera.sendToBackend)
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
                            if routeRequiresLogin model2.route then
                                routePush model2 HomePageRoute

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
                    updateLoggedIn
                        (\loggedIn ->
                            handleLocalChange
                                model.time
                                (case routeToGuildOrDmIdNoThread model.route of
                                    Just ( guildOrDmId, threadRoute ) ->
                                        case guildOrDmIdNoThreadToMessages guildOrDmId threadRoute (Local.model loggedIn.localState) of
                                            Just messages ->
                                                Local_SetLastViewed
                                                    guildOrDmId
                                                    (case threadRoute of
                                                        ViewThreadWithMaybeMessage threadMessageId _ ->
                                                            ViewThreadWithMessage threadMessageId (Array.length messages - 1 |> Id.fromInt)

                                                        NoThreadWithMaybeMessage _ ->
                                                            NoThreadWithMessage (Array.length messages - 1 |> Id.fromInt)
                                                    )
                                                    |> Just

                                            Nothing ->
                                                Nothing

                                    Nothing ->
                                        Nothing
                                )
                                loggedIn
                                Command.none
                        )
                        model

                ( model3, routeCmd ) =
                    routePush model2 route
            in
            ( model3
            , Command.batch
                [ cmd
                , routeCmd
                , notificationRequest
                ]
            )

        TypedMessage guildOrDmId text ->
            updateLoggedIn
                (\loggedIn ->
                    let
                        ( pingUser, cmd ) =
                            MessageInput.multilineUpdate
                                (Pages.Guild.messageInputConfig guildOrDmId)
                                Pages.Guild.channelTextInputId
                                text
                                (case SeqDict.get guildOrDmId loggedIn.drafts of
                                    Just nonempty ->
                                        String.Nonempty.toString nonempty

                                    Nothing ->
                                        ""
                                )
                                loggedIn.pingUser
                    in
                    handleLocalChange
                        model.time
                        (if loggedIn.typingDebouncer then
                            Local_MemberTyping model.time guildOrDmId |> Just

                         else
                            Nothing
                        )
                        { loggedIn
                            | pingUser = pingUser
                            , drafts =
                                case String.Nonempty.fromString text of
                                    Just nonempty ->
                                        SeqDict.insert guildOrDmId nonempty loggedIn.drafts

                                    Nothing ->
                                        SeqDict.remove guildOrDmId loggedIn.drafts
                            , typingDebouncer = False
                        }
                        (Command.batch
                            [ cmd
                            , Process.sleep (Duration.seconds 1)
                                |> Task.perform (\() -> DebouncedTyping)
                            ]
                        )
                )
                model

        DebouncedTyping ->
            updateLoggedIn
                (\loggedIn -> ( { loggedIn | typingDebouncer = True }, Command.none ))
                model

        PressedSendMessage guildOrDmId threadRoute ->
            updateLoggedIn
                (\loggedIn ->
                    let
                        guildOrDmIdWithThread : GuildOrDmId
                        guildOrDmIdWithThread =
                            ( guildOrDmId, threadRoute )
                    in
                    case SeqDict.get guildOrDmIdWithThread loggedIn.drafts of
                        Just nonempty ->
                            let
                                local : LocalState
                                local =
                                    Local.model loggedIn.localState
                            in
                            handleLocalChange
                                model.time
                                (Local_SendMessage
                                    model.time
                                    guildOrDmId
                                    (RichText.fromNonemptyString (LocalState.allUsers local) nonempty)
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
                                    |> Just
                                )
                                { loggedIn
                                    | drafts = SeqDict.remove guildOrDmIdWithThread loggedIn.drafts
                                    , replyTo = SeqDict.remove guildOrDmIdWithThread loggedIn.replyTo
                                    , filesToUpload = SeqDict.remove guildOrDmIdWithThread loggedIn.filesToUpload
                                }
                                scrollToBottomOfChannel

                        Nothing ->
                            ( loggedIn, Command.none )
                )
                model

        PressedAttachFiles guildOrDmId ->
            ( model, Effect.File.Select.files [] (SelectedFilesToAttach guildOrDmId) )

        SelectedFilesToAttach guildOrDmId file files ->
            gotFiles guildOrDmId (Nonempty file files) model

        NewChannelFormChanged guildId newChannelForm ->
            updateLoggedIn
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
                                    handleLocalChange
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
                                    routePush
                                        { model | loginStatus = LoggedIn loggedIn2 }
                                        (GuildRoute guildId (ChannelRoute nextChannelId (NoThreadWithMaybeMessage Nothing)))
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
            updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn | channelNameHover = Just ( guildId, channelId, threadRoute ) }, Command.none )
                )
                model

        MouseExitedChannelName guildId channelId threadRoute ->
            updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn
                        | channelNameHover =
                            if loggedIn.channelNameHover == Just ( guildId, channelId, threadRoute ) then
                                Nothing

                            else
                                loggedIn.channelNameHover
                      }
                    , Command.none
                    )
                )
                model

        EditChannelFormChanged guildId channelId newChannelForm ->
            updateLoggedIn
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
                    routePush
                        { model
                            | loginStatus =
                                LoggedIn
                                    { loggedIn
                                        | editChannelForm =
                                            SeqDict.remove ( guildId, channelId ) loggedIn.editChannelForm
                                    }
                        }
                        (GuildRoute guildId (ChannelRoute channelId (NoThreadWithMaybeMessage Nothing)))

                NotLoggedIn _ ->
                    ( model, Command.none )

        PressedSubmitEditChannelChanges guildId channelId form ->
            updateLoggedIn
                (\loggedIn ->
                    case ChannelName.fromString form.name of
                        Ok channelName ->
                            handleLocalChange
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
                                    routePush
                                        model
                                        (GuildRoute
                                            guildId
                                            (ChannelRoute (LocalState.announcementChannel guild) (NoThreadWithMaybeMessage Nothing))
                                        )

                                Nothing ->
                                    ( model, Command.none )

                        ( loggedIn2, cmd2 ) =
                            handleLocalChange
                                model2.time
                                (Local_DeleteChannel guildId channelId |> Just)
                                { loggedIn
                                    | drafts =
                                        SeqDict.remove
                                            ( GuildOrDmId_Guild_NoThread guildId channelId, NoThread )
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
            updateLoggedIn
                (\loggedIn ->
                    handleLocalChange
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
            updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn | newGuildForm = Just Pages.Guild.newGuildFormInit }
                    , Command.none
                    )
                )
                model

        NewGuildFormChanged newGuildForm ->
            updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn | newGuildForm = Just newGuildForm }
                    , Command.none
                    )
                )
                model

        PressedSubmitNewGuild newGuildForm ->
            updateLoggedIn
                (\loggedIn ->
                    case GuildName.fromString newGuildForm.name of
                        Ok guildName ->
                            handleLocalChange
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
            updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn | newGuildForm = Nothing }
                    , Command.none
                    )
                )
                model

        GotPingUserPosition result ->
            updateLoggedIn
                (\loggedIn ->
                    ( case result of
                        Ok ok ->
                            { loggedIn | pingUser = Just ok }

                        Err _ ->
                            loggedIn
                    , Command.none
                    )
                )
                model

        PressedPingUser ( guildOrDmId, threadRoute ) index ->
            updateLoggedIn
                (\loggedIn ->
                    case SeqDict.get ( guildOrDmId, threadRoute ) loggedIn.drafts of
                        Just text ->
                            let
                                ( pingUser, text2, cmd ) =
                                    MessageInput.pressedPingUser
                                        SetFocus
                                        guildOrDmId
                                        Pages.Guild.channelTextInputId
                                        index
                                        loggedIn.pingUser
                                        (Local.model loggedIn.localState)
                                        text
                            in
                            ( { loggedIn
                                | pingUser = pingUser
                                , drafts = SeqDict.insert ( guildOrDmId, threadRoute ) text2 loggedIn.drafts
                              }
                            , cmd
                            )

                        Nothing ->
                            ( loggedIn, Command.none )
                )
                model

        SetFocus ->
            ( model, Command.none )

        RemoveFocus ->
            ( model, Command.none )

        PressedArrowInDropdown guildOrDmId index ->
            updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn
                        | pingUser =
                            MessageInput.pressedArrowInDropdown
                                guildOrDmId
                                index
                                loggedIn.pingUser
                                (Local.model loggedIn.localState)
                      }
                    , Command.none
                    )
                )
                model

        TextInputGotFocus htmlId ->
            ( { model | textInputFocus = Just htmlId }, Command.none )

        TextInputLostFocus htmlId ->
            updateLoggedIn
                (\loggedIn -> ( loggedIn, Command.none ))
                { model
                    | textInputFocus =
                        if Just htmlId == model.textInputFocus then
                            Nothing

                        else
                            model.textInputFocus
                    , virtualKeyboardOpen = False
                }

        KeyDown key ->
            case key of
                "Escape" ->
                    updateLoggedIn
                        (\loggedIn ->
                            let
                                loggedIn2 =
                                    MessageMenu.close model loggedIn
                            in
                            case loggedIn2.pingUser of
                                Just _ ->
                                    ( { loggedIn2 | pingUser = Nothing, showEmojiSelector = EmojiSelectorHidden }
                                    , setFocus model Pages.Guild.channelTextInputId
                                    )

                                Nothing ->
                                    case loggedIn2.showEmojiSelector of
                                        EmojiSelectorHidden ->
                                            case routeToGuildOrDmId model.route of
                                                Just ( guildOrDmId, threadRoute ) ->
                                                    handleLocalChange
                                                        model.time
                                                        (case
                                                            guildOrDmIdToMessages
                                                                ( guildOrDmId, threadRoute )
                                                                (Local.model loggedIn2.localState)
                                                         of
                                                            Just messages ->
                                                                case guildOrDmId of
                                                                    GuildOrDmId_Guild_NoThread guildId channelId ->
                                                                        Local_SetLastViewed
                                                                            (GuildOrDmId_Guild_NoThread guildId channelId)
                                                                            (case threadRoute of
                                                                                ViewThread threadId ->
                                                                                    ViewThreadWithMessage
                                                                                        threadId
                                                                                        (Array.length messages - 1 |> Id.fromInt)

                                                                                NoThread ->
                                                                                    NoThreadWithMessage
                                                                                        (Array.length messages - 1 |> Id.fromInt)
                                                                            )
                                                                            |> Just

                                                                    GuildOrDmId_Dm_NoThread otherUserId ->
                                                                        Local_SetLastViewed
                                                                            (GuildOrDmId_Dm_NoThread otherUserId)
                                                                            (case threadRoute of
                                                                                ViewThread threadId ->
                                                                                    ViewThreadWithMessage
                                                                                        threadId
                                                                                        (Array.length messages - 1 |> Id.fromInt)

                                                                                NoThread ->
                                                                                    NoThreadWithMessage
                                                                                        (Array.length messages - 1 |> Id.fromInt)
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
                                                        (setFocus model Pages.Guild.channelTextInputId)

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

        MessageMenu_PressedEditMessage guildOrDmId threadRoute ->
            pressedEditMessage guildOrDmId threadRoute model

        PressedEmojiSelectorEmoji emoji ->
            updateLoggedIn
                (\loggedIn ->
                    case loggedIn.showEmojiSelector of
                        EmojiSelectorHidden ->
                            ( loggedIn, Command.none )

                        EmojiSelectorForReaction guildOrDmId threadRoute ->
                            handleLocalChange
                                model.time
                                (Local_AddReactionEmoji guildOrDmId threadRoute emoji |> Just)
                                { loggedIn | showEmojiSelector = EmojiSelectorHidden }
                                Command.none

                        EmojiSelectorForMessage ->
                            ( loggedIn, Command.none )
                )
                model

        GotPingUserPositionForEditMessage result ->
            updateLoggedIn
                (\loggedIn ->
                    ( case result of
                        Ok ok ->
                            { loggedIn | pingUser = Just ok }

                        Err _ ->
                            loggedIn
                    , Command.none
                    )
                )
                model

        TypedEditMessage ( guildOrDmId, threadRoute ) text ->
            updateLoggedIn
                (\loggedIn ->
                    case SeqDict.get ( guildOrDmId, threadRoute ) loggedIn.editMessage of
                        Just edit ->
                            let
                                ( pingUser, cmd ) =
                                    MessageInput.multilineUpdate
                                        (MessageMenu.editMessageTextInputConfig guildOrDmId threadRoute)
                                        MessageMenu.editMessageTextInputId
                                        text
                                        edit.text
                                        loggedIn.pingUser

                                oldTypingDebouncer : Bool
                                oldTypingDebouncer =
                                    loggedIn.typingDebouncer

                                loggedIn2 : LoggedIn2
                                loggedIn2 =
                                    { loggedIn
                                        | pingUser = pingUser
                                        , editMessage =
                                            SeqDict.insert
                                                ( guildOrDmId, threadRoute )
                                                { edit | text = text }
                                                loggedIn.editMessage
                                        , typingDebouncer = False
                                    }
                            in
                            handleLocalChange
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
                                                            loggedIn2
                                                            model
                                                            |> MessageMenuFixed
                                                }
                                                    |> MessageMenu
                                }
                                (Command.batch
                                    [ cmd
                                    , Process.sleep (Duration.seconds 1)
                                        |> Task.perform (\() -> DebouncedTyping)
                                    ]
                                )

                        Nothing ->
                            ( loggedIn, Command.none )
                )
                model

        PressedSendEditMessage ( guildOrDmId, threadRoute ) ->
            updateLoggedIn
                (\loggedIn ->
                    case SeqDict.get ( guildOrDmId, threadRoute ) loggedIn.editMessage of
                        Just edit ->
                            let
                                local : LocalState
                                local =
                                    Local.model loggedIn.localState
                            in
                            handleLocalChange
                                model.time
                                (case
                                    ( String.Nonempty.fromString edit.text
                                    , guildOrDmIdToMessage ( guildOrDmId, threadRoute ) edit.messageIndex local
                                    )
                                 of
                                    ( Just nonempty, Just message ) ->
                                        let
                                            richText : Nonempty RichText
                                            richText =
                                                RichText.fromNonemptyString
                                                    (LocalState.allUsers local)
                                                    nonempty
                                        in
                                        if message.content == richText then
                                            Nothing

                                        else
                                            --Local_SendEditMessage
                                            --    model.time
                                            --    guildOrDmId
                                            --    edit.messageIndex
                                            --    richText
                                            --    (FileStatus.onlyUploadedFiles edit.attachedFiles)
                                            --    |> Just
                                            Local_SendEditMessage
                                                model.time
                                                guildOrDmId
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
                                )
                                { loggedIn
                                    | editMessage = SeqDict.remove ( guildOrDmId, threadRoute ) loggedIn.editMessage
                                    , messageHover = NoMessageHover
                                }
                                (setFocus model Pages.Guild.channelTextInputId)

                        Nothing ->
                            ( loggedIn, Command.none )
                )
                model

        PressedArrowInDropdownForEditMessage guildOrDmId index ->
            updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn
                        | pingUser =
                            MessageInput.pressedArrowInDropdown
                                guildOrDmId
                                index
                                loggedIn.pingUser
                                (Local.model loggedIn.localState)
                      }
                    , Command.none
                    )
                )
                model

        PressedPingUserForEditMessage ( guildOrDmId, threadRoute ) dropdownIndex ->
            updateLoggedIn
                (\loggedIn ->
                    case SeqDict.get ( guildOrDmId, threadRoute ) loggedIn.editMessage of
                        Just edit ->
                            case String.Nonempty.fromString edit.text of
                                Just nonempty ->
                                    let
                                        ( pingUser, text2, cmd ) =
                                            MessageInput.pressedPingUser
                                                SetFocus
                                                guildOrDmId
                                                MessageMenu.editMessageTextInputId
                                                dropdownIndex
                                                loggedIn.pingUser
                                                (Local.model loggedIn.localState)
                                                nonempty
                                    in
                                    ( { loggedIn
                                        | pingUser = pingUser
                                        , editMessage =
                                            SeqDict.insert
                                                ( guildOrDmId, threadRoute )
                                                { edit | text = String.Nonempty.toString text2 }
                                                loggedIn.editMessage
                                      }
                                    , cmd
                                    )

                                Nothing ->
                                    ( loggedIn, Command.none )

                        Nothing ->
                            ( loggedIn, Command.none )
                )
                model

        PressedArrowUpInEmptyInput guildOrDmId ->
            updateLoggedIn
                (\loggedIn ->
                    let
                        local : LocalState
                        local =
                            Local.model loggedIn.localState

                        maybeMessages : Maybe (Array Message)
                        maybeMessages =
                            guildOrDmIdToMessages guildOrDmId local
                    in
                    case maybeMessages of
                        Just messages ->
                            let
                                messageCount : Int
                                messageCount =
                                    Array.length messages

                                mostRecentMessage : Maybe ( Id ChannelMessageId, UserTextMessageData )
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
                                                    UserTextMessage data ->
                                                        if local.localUser.userId == data.createdBy then
                                                            Just ( index, data )

                                                        else
                                                            Nothing

                                                    UserJoinedMessage _ _ _ ->
                                                        Nothing

                                                    DeletedMessage _ ->
                                                        Nothing
                                            )
                            in
                            case mostRecentMessage of
                                Just ( index, message ) ->
                                    ( { loggedIn
                                        | editMessage =
                                            SeqDict.insert
                                                guildOrDmId
                                                { messageIndex = index
                                                , text =
                                                    RichText.toString (LocalState.allUsers local) message.content
                                                , attachedFiles =
                                                    SeqDict.map (\_ a -> FileUploaded a) message.attachedFiles
                                                }
                                                loggedIn.editMessage
                                      }
                                    , setFocus model MessageMenu.editMessageTextInputId
                                    )

                                Nothing ->
                                    ( loggedIn, Command.none )

                        Nothing ->
                            ( loggedIn, Command.none )
                )
                model

        MessageMenu_PressedReply messageIndex ->
            case routeToGuildOrDmId model.route of
                Just guildOrDmId ->
                    pressedReply guildOrDmId messageIndex model

                Nothing ->
                    ( model, Command.none )

        MessageMenu_PressedOpenThread messageIndex ->
            case ( model.route, model.loginStatus ) of
                ( GuildRoute guildId (ChannelRoute channelId (NoThreadWithMaybeMessage _)), LoggedIn loggedIn ) ->
                    routePush
                        { model | loginStatus = MessageMenu.close model loggedIn |> LoggedIn }
                        (GuildRoute guildId (ChannelRoute channelId (ViewThreadWithMaybeMessage messageIndex Nothing)))

                ( DmRoute otherUserId (NoThreadWithMaybeMessage _), LoggedIn loggedIn ) ->
                    routePush
                        { model | loginStatus = MessageMenu.close model loggedIn |> LoggedIn }
                        (DmRoute otherUserId (ViewThreadWithMaybeMessage messageIndex Nothing))

                _ ->
                    ( model, Command.none )

        PressedCloseReplyTo guildOrDmId ->
            updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn | replyTo = SeqDict.remove guildOrDmId loggedIn.replyTo }
                    , setFocus model Pages.Guild.channelTextInputId
                    )
                )
                model

        VisibilityChanged visibility ->
            case visibility of
                Effect.Browser.Events.Visible ->
                    ( model
                    , Command.batch
                        [ setFocus model Pages.Guild.channelTextInputId
                        , Ports.setFavicon "favicon.ico"
                        ]
                    )

                Effect.Browser.Events.Hidden ->
                    ( model, Command.none )

        CheckedNotificationPermission notificationPermission ->
            ( { model | notificationPermission = notificationPermission }, Command.none )

        CheckedPwaStatus pwaStatus ->
            ( { model | pwaStatus = pwaStatus }, Command.none )

        TouchStart time maybeGuildOrDmIdAndMessageIndex touches ->
            touchStart time maybeGuildOrDmIdAndMessageIndex touches model

        TouchMoved time newTouches ->
            case model.drag of
                Dragging dragging ->
                    updateLoggedIn
                        (\loggedIn ->
                            let
                                averageMove : { x : Float, y : Float }
                                averageMove =
                                    Touch.averageTouchMove dragging.touches newTouches |> Vector2d.unwrap
                            in
                            ( case loggedIn.messageHover of
                                MessageMenu messageMenu ->
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
                                                        loggedIn
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
                                                case ( model.textInputFocus, isTouchingTextInput dragging.touches ) of
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
                    updateLoggedIn
                        (\loggedIn ->
                            ( if horizontalStart then
                                let
                                    tHorizontal : Float
                                    tHorizontal =
                                        averageMove.x / toFloat (Coord.xRaw model.windowSize)
                                in
                                { loggedIn
                                    | sidebarMode =
                                        case ( model.textInputFocus, isTouchingTextInput startTouches ) of
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
            updateLoggedIn
                (\loggedIn ->
                    case loggedIn.sidebarMode of
                        ChannelSidebarClosed ->
                            ( loggedIn, Command.none )

                        ChannelSidebarOpened ->
                            ( loggedIn, Command.none )

                        ChannelSidebarOpening { offset } ->
                            let
                                offset2 =
                                    offset - Quantity.unwrap (Quantity.for elapsedTime sidebarSpeed)
                            in
                            ( { loggedIn
                                | sidebarMode =
                                    if offset2 <= 0 then
                                        ChannelSidebarOpened

                                    else
                                        ChannelSidebarOpening { offset = offset2 }
                              }
                            , Command.none
                            )

                        ChannelSidebarClosing { offset } ->
                            let
                                offset2 =
                                    offset + Quantity.unwrap (Quantity.for elapsedTime sidebarSpeed)
                            in
                            ( { loggedIn
                                | sidebarMode =
                                    if offset2 >= 1 then
                                        ChannelSidebarClosed

                                    else
                                        ChannelSidebarClosing { offset = offset2 }
                              }
                            , Dom.blur Pages.Guild.channelTextInputId |> Task.attempt (\_ -> RemoveFocus)
                            )

                        ChannelSidebarDragging _ ->
                            ( loggedIn, Command.none )
                )
                model

        ScrolledToBottom ->
            ( model, Command.none )

        PressedChannelHeaderBackButton ->
            updateLoggedIn (\loggedIn -> ( startClosingChannelSidebar loggedIn, Command.none )) model

        UserScrolled { scrolledToBottomOfChannel } ->
            ( { model | scrolledToBottomOfChannel = scrolledToBottomOfChannel }, Command.none )

        PressedBody ->
            updateLoggedIn
                (\loggedIn ->
                    ( MessageMenu.close
                        model
                        { loggedIn | showEmojiSelector = EmojiSelectorHidden }
                    , Command.none
                    )
                )
                model

        PressedReactionEmojiContainer ->
            ( model, Command.none )

        MessageMenu_PressedDeleteMessage guildOrDmId messageIndex ->
            updateLoggedIn
                (\loggedIn ->
                    handleLocalChange
                        model.time
                        (Just (Local_DeleteMessage guildOrDmId messageIndex))
                        (MessageMenu.close model loggedIn)
                        Command.none
                )
                model

        ScrolledToMessage ->
            ( model, Command.none )

        MessageMenu_PressedClose ->
            updateLoggedIn (\loggedIn -> ( MessageMenu.close model loggedIn, Command.none )) model

        MessageMenu_PressedContainer ->
            ( model, Command.none )

        PressedCancelMessageEdit guildOrDmId ->
            updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn | editMessage = SeqDict.remove guildOrDmId loggedIn.editMessage }
                    , Command.none
                    )
                )
                model

        PressedPingDropdownContainer ->
            ( model, setFocus model Pages.Guild.channelTextInputId )

        PressedEditMessagePingDropdownContainer ->
            ( model, setFocus model MessageMenu.editMessageTextInputId )

        CheckMessageAltPress startTime guildOrDmId threadRoute isThreadStarter ->
            case model.drag of
                DragStart dragStart _ ->
                    if startTime == dragStart then
                        updateLoggedIn
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
            updateLoggedIn
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

                                        MessageMenuClosing offset ->
                                            let
                                                offsetNext : Quantity Float CssPixels
                                                offsetNext =
                                                    offset
                                                        |> Quantity.minus (Quantity.for elapsedTime MessageMenu.messageMenuSpeed)
                                            in
                                            if offsetNext |> Quantity.lessThanOrEqualToZero then
                                                NoMessageHover

                                            else
                                                { messageMenu | mobileMode = MessageMenuClosing offsetNext }
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
            updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn | userOptions = Just UserOptions.init }, Command.none )
                )
                model

        PressedCloseUserOptions ->
            updateLoggedIn
                (\loggedIn -> ( { loggedIn | userOptions = Nothing }, Command.none ))
                model

        TwoFactorMsg twoFactorMsg ->
            updateLoggedIn
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
            updateLoggedIn
                (\loggedIn ->
                    case loggedIn.userOptions of
                        Just userOptions ->
                            case editableMsg of
                                Editable.Edit editable ->
                                    ( { loggedIn | userOptions = Just { userOptions | name = editable } }
                                    , Command.none
                                    )

                                Editable.PressedAcceptEdit value ->
                                    handleLocalChange
                                        model.time
                                        (Just (Local_SetName value))
                                        { loggedIn | userOptions = Just { userOptions | name = Editable.init } }
                                        Command.none

                        Nothing ->
                            ( loggedIn, Command.none )
                )
                model

        BotTokenEditableMsg editableMsg ->
            updateLoggedIn
                (\loggedIn ->
                    case loggedIn.userOptions of
                        Just userOptions ->
                            case editableMsg of
                                Editable.Edit editable ->
                                    ( { loggedIn | userOptions = Just { userOptions | botToken = editable } }
                                    , Command.none
                                    )

                                Editable.PressedAcceptEdit value ->
                                    handleLocalChange
                                        model.time
                                        (Just (Local_Admin (Pages.Admin.SetDiscordBotToken value)))
                                        { loggedIn | userOptions = Just { userOptions | botToken = Editable.init } }
                                        Command.none

                        Nothing ->
                            ( loggedIn, Command.none )
                )
                model

        PublicVapidKeyEditableMsg editableMsg ->
            updateLoggedIn
                (\loggedIn ->
                    case loggedIn.userOptions of
                        Just userOptions ->
                            case editableMsg of
                                Editable.Edit editable ->
                                    ( { loggedIn | userOptions = Just { userOptions | publicVapidKey = editable } }
                                    , Command.none
                                    )

                                Editable.PressedAcceptEdit value ->
                                    handleLocalChange
                                        model.time
                                        (Just (Local_Admin (Pages.Admin.SetPublicVapidKey value)))
                                        { loggedIn | userOptions = Just { userOptions | publicVapidKey = Editable.init } }
                                        Command.none

                        Nothing ->
                            ( loggedIn, Command.none )
                )
                model

        PrivateVapidKeyEditableMsg editableMsg ->
            updateLoggedIn
                (\loggedIn ->
                    case loggedIn.userOptions of
                        Just userOptions ->
                            case editableMsg of
                                Editable.Edit editable ->
                                    ( { loggedIn | userOptions = Just { userOptions | privateVapidKey = editable } }
                                    , Command.none
                                    )

                                Editable.PressedAcceptEdit value ->
                                    handleLocalChange
                                        model.time
                                        (Just (Local_Admin (Pages.Admin.SetPrivateVapidKey value)))
                                        { loggedIn | userOptions = Just { userOptions | privateVapidKey = Editable.init } }
                                        Command.none

                        Nothing ->
                            ( loggedIn, Command.none )
                )
                model

        OneFrameAfterDragEnd ->
            ( { model | dragPrevious = model.drag }, Command.none )

        GotFileHashName guildOrDmId fileStatusId result ->
            updateLoggedIn
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
            updateLoggedIn
                (\loggedIn ->
                    let
                        local =
                            Local.model loggedIn.localState

                        allUsers =
                            LocalState.allUsers local
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
            updateLoggedIn
                (\loggedIn ->
                    let
                        local =
                            Local.model loggedIn.localState

                        allUsers =
                            LocalState.allUsers local
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

        EditMessage_PressedAttachFiles guildOrDmId ->
            ( model, Effect.File.Select.files [] (EditMessage_SelectedFilesToAttach guildOrDmId) )

        EditMessage_SelectedFilesToAttach guildOrDmId file files ->
            editMessage_gotFiles guildOrDmId (Nonempty file files) model

        EditMessage_GotFileHashName guildOrDmId messageIndex fileId result ->
            updateLoggedIn
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

        EditMessage_PastedFiles guildOrDmId files ->
            editMessage_gotFiles guildOrDmId files model

        PastedFiles guildOrDmId files ->
            gotFiles guildOrDmId files model

        PressedTextInput ->
            ( { model | virtualKeyboardOpen = True }, Command.none )

        FileUploadProgress guildOrDmId fileId progress ->
            updateLoggedIn
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
                guildOrDmIdWithThread : GuildOrDmId
                guildOrDmIdWithThread =
                    ( guildOrDmId, Id.threadRouteWithoutMessage threadRoute )
            in
            case messageViewMsg of
                MessageView.MessageView_PressedSpoiler spoilerIndex ->
                    updateLoggedIn
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
                        updateLoggedIn
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
                    updateLoggedIn
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
                    updateLoggedIn
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
                    updateLoggedIn
                        (\loggedIn ->
                            handleLocalChange
                                model.time
                                (Local_RemoveReactionEmoji guildOrDmId threadRoute emoji |> Just)
                                loggedIn
                                Command.none
                        )
                        model

                MessageView.MessageView_PressedReactionEmoji_Add emoji ->
                    updateLoggedIn
                        (\loggedIn ->
                            handleLocalChange
                                model.time
                                (Local_AddReactionEmoji guildOrDmId threadRoute emoji |> Just)
                                loggedIn
                                Command.none
                        )
                        model

                MessageView.MessageView_PressedReplyLink ->
                    case model.loginStatus of
                        LoggedIn loggedIn ->
                            case guildOrDmIdNoThreadToMessage guildOrDmId threadRoute (Local.model loggedIn.localState) of
                                Just (UserTextMessage message) ->
                                    case ( guildOrDmId, message.repliedTo ) of
                                        ( GuildOrDmId_Guild_NoThread guildId channelId, Just repliedTo ) ->
                                            routePush
                                                model
                                                (GuildRoute guildId
                                                    (ChannelRoute
                                                        channelId
                                                        (case threadRoute of
                                                            ViewThreadWithMessage threadMessageId _ ->
                                                                ViewThreadWithMaybeMessage
                                                                    threadMessageId
                                                                    (Just (Id.changeType repliedTo))

                                                            NoThreadWithMessage _ ->
                                                                NoThreadWithMaybeMessage (Just repliedTo)
                                                        )
                                                    )
                                                )

                                        ( GuildOrDmId_Dm_NoThread otherUserId, Just repliedTo ) ->
                                            routePush
                                                model
                                                (DmRoute
                                                    otherUserId
                                                    (case threadRoute of
                                                        ViewThreadWithMessage threadMessageId _ ->
                                                            ViewThreadWithMaybeMessage
                                                                threadMessageId
                                                                (Just (Id.changeType repliedTo))

                                                        NoThreadWithMessage _ ->
                                                            NoThreadWithMaybeMessage (Just repliedTo)
                                                    )
                                                )

                                        ( _, Nothing ) ->
                                            ( model, Command.none )

                                _ ->
                                    ( model, Command.none )

                        NotLoggedIn _ ->
                            ( model, Command.none )

                MessageView.MessageViewMsg_PressedShowReactionEmojiSelector _ ->
                    showReactionEmojiSelector guildOrDmId threadRoute model

                MessageView.MessageViewMsg_PressedEditMessage ->
                    pressedEditMessage guildOrDmId threadRoute model

                MessageView.MessageViewMsg_PressedReply ->
                    pressedReply guildOrDmId threadRoute model

                MessageView.MessageViewMsg_PressedShowFullMenu isThreadStarter clickedAt ->
                    updateLoggedIn
                        (\loggedIn ->
                            let
                                local : LocalState
                                local =
                                    Local.model loggedIn.localState

                                menuHeight : Int
                                menuHeight =
                                    MessageMenu.menuHeight
                                        { guildOrDmId = guildOrDmId
                                        , threadRoute = threadRoute
                                        , position = clickedAt
                                        }
                                        local
                                        model
                            in
                            ( { loggedIn
                                | messageHover =
                                    MessageMenu
                                        { position =
                                            -- Move the menu up if it's too close to the bottom of the screen
                                            if Coord.yRaw clickedAt + menuHeight + 60 > Coord.yRaw model.windowSize then
                                                Coord.plus
                                                    (Coord.xy (-MessageMenu.width - 8) (-8 - menuHeight))
                                                    clickedAt

                                            else
                                                Coord.plus
                                                    (Coord.xy (-MessageMenu.width - 8) -8)
                                                    clickedAt
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
                        ( GuildOrDmId_Guild_NoThread guildId channelId, NoThreadWithMessage messageId ) ->
                            routePush model (GuildRoute guildId (ChannelRoute channelId (ViewThreadWithMaybeMessage messageId Nothing)))

                        ( GuildOrDmId_Dm_NoThread otherUserId, NoThreadWithMessage messageId ) ->
                            routePush model (DmRoute otherUserId (ViewThreadWithMaybeMessage messageId Nothing))

                        _ ->
                            ( model, Command.none )

        GotRegisterPushSubscription result ->
            let
                _ =
                    Debug.log "Got register PushSubscription" result
            in
            ( model
            , case result of
                Ok endpoint ->
                    Lamdera.sendToBackend (RegisterPushSubscriptionRequest endpoint)

                Err _ ->
                    Command.none
            )

        ToggledEnablePushNotifications isEnabled ->
            updateLoggedIn
                (\loggedIn ->
                    ( loggedIn
                    , if isEnabled then
                        Ports.registerPushSubscriptionToJs (Local.model loggedIn.localState).publicVapidKey

                      else
                        Command.batch
                            [ Ports.unregisterPushSubscriptionToJs
                            , Lamdera.sendToBackend UnregisterPushSubscriptionRequest
                            ]
                    )
                )
                { model | enabledPushNotifications = isEnabled }

        GotIsPushNotificationsRegistered isEnabled ->
            ( { model | enabledPushNotifications = isEnabled }, Command.none )


pressedReply : GuildOrDmIdNoThread -> ThreadRouteWithMessage -> LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg )
pressedReply guildOrDmId threadRoute model =
    updateLoggedIn
        (\loggedIn ->
            ( MessageMenu.close
                model
                { loggedIn | replyTo = SeqDict.insert guildOrDmId threadRoute loggedIn.replyTo }
            , setFocus model Pages.Guild.channelTextInputId
            )
        )
        model


pressedEditMessage : GuildOrDmIdNoThread -> ThreadRouteWithMessage -> LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg )
pressedEditMessage guildOrDmId messageIndex model =
    updateLoggedIn
        (\loggedIn ->
            let
                maybeMessage : Maybe UserTextMessageData
                maybeMessage =
                    case LocalState.getMessages guildOrDmId local of
                        Just ( _, messages ) ->
                            case LocalState.getArray messageIndex messages of
                                Just (UserTextMessage data) ->
                                    Just data

                                _ ->
                                    Nothing

                        Nothing ->
                            Nothing

                local : LocalState
                local =
                    Local.model loggedIn.localState
            in
            ( case maybeMessage of
                Just message ->
                    let
                        loggedIn2 =
                            { loggedIn
                                | editMessage =
                                    SeqDict.insert
                                        guildOrDmId
                                        { messageIndex = messageIndex
                                        , text =
                                            RichText.toString (LocalState.allUsers local) message.content
                                        , attachedFiles =
                                            SeqDict.map (\_ a -> FileUploaded a) message.attachedFiles
                                        }
                                        loggedIn.editMessage
                            }
                    in
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
                                            { offset =
                                                Types.messageMenuMobileOffset extraOptions.mobileMode
                                            , targetOffset =
                                                MessageMenu.mobileMenuMaxHeight
                                                    extraOptions
                                                    local
                                                    loggedIn2
                                                    model
                                            }
                                                |> MessageMenuOpening
                                    }
                                        |> MessageMenu
                    }

                Nothing ->
                    loggedIn
            , setFocus model MessageMenu.editMessageTextInputId
            )
        )
        model


showReactionEmojiSelector : GuildOrDmIdNoThread -> ThreadRouteWithMessage -> LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg )
showReactionEmojiSelector guildOrDmId messageIndex model =
    updateLoggedIn
        (\loggedIn ->
            ( { loggedIn
                | showEmojiSelector =
                    case loggedIn.showEmojiSelector of
                        EmojiSelectorHidden ->
                            EmojiSelectorForReaction guildOrDmId messageIndex

                        EmojiSelectorForReaction _ _ ->
                            EmojiSelectorHidden

                        EmojiSelectorForMessage ->
                            EmojiSelectorHidden
                , messageHover =
                    case loggedIn.messageHover of
                        NoMessageHover ->
                            loggedIn.messageHover

                        MessageHover _ _ ->
                            loggedIn.messageHover

                        MessageMenu a ->
                            MessageHover a.guildOrDmId a.threadRoute
              }
            , Command.none
            )
        )
        model


touchStart :
    Maybe ( GuildOrDmIdNoThread, ThreadRouteWithMessage, Bool )
    -> Time.Posix
    -> NonemptyDict Int Touch
    -> LoadedFrontend
    -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg )
touchStart maybeGuildOrDmIdAndMessageIndex time touches model =
    case model.drag of
        NoDrag ->
            ( { model | drag = DragStart time touches, dragPrevious = model.drag }
            , case NonemptyDict.toList touches of
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
            )

        DragStart _ _ ->
            ( model, Command.none )

        Dragging _ ->
            ( model, Command.none )


gotFiles : GuildOrDmId -> Nonempty File -> LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg )
gotFiles guildOrDmId files model =
    updateLoggedIn
        (\loggedIn ->
            let
                ( fileText, cmds, dict ) =
                    case SeqDict.get guildOrDmId loggedIn.filesToUpload of
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
                                    , FileStatus.upload
                                        (GotFileHashName guildOrDmId id)
                                        loggedIn.sessionId
                                        guildOrDmId
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
                                    FileStatus.upload
                                        (GotFileHashName guildOrDmId id)
                                        loggedIn.sessionId
                                        guildOrDmId
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
                    SeqDict.insert guildOrDmId dict loggedIn.filesToUpload
                , drafts =
                    case String.join " " fileText |> String.Nonempty.fromString of
                        Just fileText2 ->
                            SeqDict.update
                                guildOrDmId
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
    GuildOrDmId
    -> Nonempty File
    -> LoadedFrontend
    -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg )
editMessage_gotFiles guildOrDmId files model =
    updateLoggedIn
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
                                    , FileStatus.upload
                                        (EditMessage_GotFileHashName guildOrDmId edit.messageIndex fileId)
                                        loggedIn.sessionId
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


handleAltPressedMessage : GuildOrDmIdNoThread -> ThreadRouteWithMessage -> Bool -> Coord CssPixels -> LoggedIn2 -> LocalState -> LoadedFrontend -> LoggedIn2
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
    updateLoggedIn
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
                MessageMenu messageMenu ->
                    case messageMenu.mobileMode of
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
                                        messageMenu
                                        (Local.model loggedIn2.localState)
                                        loggedIn2
                                        model

                                halfwayPoint : Quantity Float CssPixels
                                halfwayPoint =
                                    menuHeight |> Quantity.divideBy 2
                            in
                            { loggedIn2
                                | messageHover =
                                    MessageMenu
                                        { messageMenu
                                            | mobileMode =
                                                if
                                                    (dragging.offset |> Quantity.lessThan halfwayPoint)
                                                        || (menuDelta |> Quantity.lessThan speedThreshold)
                                                then
                                                    MessageMenuClosing dragging.offset

                                                else
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


smoothScroll : HtmlId -> Task FrontendOnly Dom.Error ()
smoothScroll targetId =
    Task.map2
        Tuple.pair
        (Dom.getElement targetId)
        (Dom.getViewportOf Pages.Guild.conversationContainerId)
        |> Task.andThen
            (\( { element }, { viewport } ) ->
                if element.y > 0 then
                    Dom.setViewportOf
                        Pages.Guild.conversationContainerId
                        0
                        (viewport.y + element.y - Pages.Guild.channelHeaderHeight)

                else
                    smoothScrollY
                        0
                        viewport.x
                        viewport.y
                        (viewport.y + element.y - Pages.Guild.channelHeaderHeight)
            )


smoothScrollSteps : number
smoothScrollSteps =
    20


smoothScrollY : Int -> Float -> Float -> Float -> Task FrontendOnly Dom.Error ()
smoothScrollY stepsLeft x startY endY =
    let
        t =
            toFloat stepsLeft / smoothScrollSteps |> Ease.inOutQuart

        y : Float
        y =
            startY + (endY - startY) * t
    in
    if stepsLeft > smoothScrollSteps then
        Task.succeed ()

    else
        Dom.setViewportOf Pages.Guild.conversationContainerId x y
            |> Task.andThen (\() -> smoothScrollY (stepsLeft + 1) x startY endY)


isTouchingTextInput : NonemptyDict Int Touch -> Bool
isTouchingTextInput touches =
    NonemptyDict.any
        (\_ touch ->
            (touch.target == MessageMenu.editMessageTextInputId)
                || (touch.target == Pages.Guild.channelTextInputId)
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


startOpeningChannelSidebar : LoggedIn2 -> LoggedIn2
startOpeningChannelSidebar loggedIn =
    { loggedIn
        | sidebarMode =
            ChannelSidebarOpening
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


setFocus : LoadedFrontend -> HtmlId -> Command FrontendOnly toMsg FrontendMsg
setFocus model htmlId =
    if MyUi.isMobile model then
        Command.none

    else
        Dom.focus htmlId |> Task.attempt (\_ -> SetFocus)


changeUpdate : LocalMsg -> LocalState -> LocalState
changeUpdate localMsg local =
    case localMsg of
        LocalChange changedBy localChange ->
            case localChange of
                Local_Invalid ->
                    local

                Local_Admin adminChange ->
                    case local.adminData of
                        IsAdmin adminData ->
                            Pages.Admin.updateAdmin changedBy adminChange adminData local

                        IsNotAdmin ->
                            local

                Local_SendMessage createdAt guildOrDmId text threadRouteWithRepliedTo attachedFiles ->
                    case guildOrDmId of
                        GuildOrDmId_Guild_NoThread guildId channelId ->
                            case LocalState.getGuildAndChannel guildId channelId local of
                                Just ( guild, channel ) ->
                                    let
                                        user =
                                            local.localUser.user

                                        localUser =
                                            local.localUser
                                    in
                                    { local
                                        | guilds =
                                            SeqDict.insert
                                                guildId
                                                { guild
                                                    | channels =
                                                        SeqDict.insert
                                                            channelId
                                                            (LocalState.createThreadMessage
                                                                Nothing
                                                                (UserTextMessage
                                                                    { createdAt = createdAt
                                                                    , createdBy = local.localUser.userId
                                                                    , content = text
                                                                    , reactions = SeqDict.empty
                                                                    , editedAt = Nothing
                                                                    , repliedTo =
                                                                        case threadRouteWithRepliedTo of
                                                                            ViewThreadWithMaybeMessage _ replyTo ->
                                                                                Maybe.map Id.changeType replyTo

                                                                            NoThreadWithMaybeMessage replyTo ->
                                                                                replyTo
                                                                    , attachedFiles = attachedFiles
                                                                    }
                                                                )
                                                                (case threadRouteWithRepliedTo of
                                                                    ViewThreadWithMaybeMessage threadMessageId _ ->
                                                                        ViewThread threadMessageId

                                                                    NoThreadWithMaybeMessage _ ->
                                                                        NoThread
                                                                )
                                                                channel
                                                            )
                                                            guild.channels
                                                }
                                                local.guilds
                                        , localUser =
                                            { localUser
                                                | user =
                                                    { user
                                                        | lastViewed =
                                                            SeqDict.insert
                                                                guildOrDmId
                                                                (Array.length channel.messages |> Id.fromInt)
                                                                user.lastViewed
                                                    }
                                            }
                                    }

                                Nothing ->
                                    local

                        GuildOrDmId_Dm_NoThread otherUserId ->
                            let
                                user =
                                    local.localUser.user

                                localUser =
                                    local.localUser

                                dmChannel : DmChannel
                                dmChannel =
                                    SeqDict.get otherUserId local.dmChannels
                                        |> Maybe.withDefault DmChannel.init
                                        |> LocalState.createThreadMessage
                                            Nothing
                                            (UserTextMessage
                                                { createdAt = createdAt
                                                , createdBy = local.localUser.userId
                                                , content = text
                                                , reactions = SeqDict.empty
                                                , editedAt = Nothing
                                                , repliedTo =
                                                    case threadRouteWithRepliedTo of
                                                        ViewThreadWithMaybeMessage _ replyTo ->
                                                            Maybe.map Id.changeType replyTo

                                                        NoThreadWithMaybeMessage replyTo ->
                                                            replyTo
                                                , attachedFiles = attachedFiles
                                                }
                                            )
                                            (case threadRouteWithRepliedTo of
                                                ViewThreadWithMaybeMessage threadMessageId _ ->
                                                    ViewThread threadMessageId

                                                NoThreadWithMaybeMessage _ ->
                                                    NoThread
                                            )
                            in
                            { local
                                | dmChannels = SeqDict.insert otherUserId dmChannel local.dmChannels
                                , localUser =
                                    { localUser
                                        | user =
                                            { user
                                                | lastViewed =
                                                    SeqDict.insert
                                                        guildOrDmId
                                                        (Array.length dmChannel.messages - 1 |> Id.fromInt)
                                                        user.lastViewed
                                            }
                                    }
                            }

                Local_NewChannel time guildId channelName ->
                    { local
                        | guilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.createChannelFrontend time local.localUser.userId channelName)
                                local.guilds
                    }

                Local_EditChannel guildId channelId channelName ->
                    { local
                        | guilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.editChannel channelName channelId)
                                local.guilds
                    }

                Local_DeleteChannel guildId channelId ->
                    { local
                        | guilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.deleteChannelFrontend channelId)
                                local.guilds
                    }

                Local_NewInviteLink time guildId inviteLinkId ->
                    case inviteLinkId of
                        EmptyPlaceholder ->
                            local

                        FilledInByBackend inviteLinkId2 ->
                            { local
                                | guilds =
                                    SeqDict.updateIfExists
                                        guildId
                                        (LocalState.addInvite inviteLinkId2 local.localUser.userId time)
                                        local.guilds
                            }

                Local_NewGuild time guildName guildIdPlaceholder ->
                    case guildIdPlaceholder of
                        EmptyPlaceholder ->
                            local

                        FilledInByBackend guildId ->
                            { local
                                | guilds =
                                    SeqDict.insert
                                        guildId
                                        (LocalState.createGuild time local.localUser.userId guildName
                                            |> LocalState.guildToFrontend
                                        )
                                        local.guilds
                            }

                Local_MemberTyping time guildOrDmId ->
                    memberTyping time local.localUser.userId guildOrDmId local

                Local_AddReactionEmoji guildOrDmId messageIndex emoji ->
                    addReactionEmoji local.localUser.userId guildOrDmId messageIndex emoji local

                Local_RemoveReactionEmoji guildOrDmId messageIndex emoji ->
                    removeReactionEmoji local.localUser.userId guildOrDmId messageIndex emoji local

                Local_SendEditMessage time guildOrDmId threadRoute newContent attachedFiles ->
                    editMessage time local.localUser.userId guildOrDmId newContent attachedFiles threadRoute local

                Local_MemberEditTyping time guildOrDmId threadRoute ->
                    memberEditTyping time local.localUser.userId guildOrDmId threadRoute local

                Local_SetLastViewed guildOrDmId threadRoute ->
                    let
                        user =
                            local.localUser.user

                        localUser =
                            local.localUser
                    in
                    case threadRoute of
                        ViewThreadWithMessage threadMessageId messageId ->
                            { local
                                | localUser =
                                    { localUser
                                        | user =
                                            { user
                                                | lastViewedThreads =
                                                    SeqDict.insert ( guildOrDmId, threadMessageId ) messageId user.lastViewedThreads
                                            }
                                    }
                            }

                        NoThreadWithMessage messageId ->
                            { local
                                | localUser =
                                    { localUser
                                        | user =
                                            { user
                                                | lastViewed =
                                                    SeqDict.insert guildOrDmId messageId user.lastViewed
                                            }
                                    }
                            }

                Local_DeleteMessage guildOrDmId messageIndex ->
                    deleteMessage local.localUser.userId guildOrDmId messageIndex local

                Local_ViewChannel guildId channelId ->
                    let
                        localUser =
                            local.localUser
                    in
                    { local
                        | localUser =
                            { localUser | user = User.setLastChannelViewed guildId channelId localUser.user }
                    }

                Local_SetName name ->
                    let
                        localUser =
                            local.localUser
                    in
                    { local | localUser = { localUser | user = User.setName name localUser.user } }

        ServerChange serverChange ->
            case serverChange of
                Server_SendMessage userId createdAt guildOrDmId text threadRouteWithRepliedTo attachedFiles ->
                    case guildOrDmId of
                        GuildOrDmId_Guild_NoThread guildId channelId ->
                            case LocalState.getGuildAndChannel guildId channelId local of
                                Just ( guild, channel ) ->
                                    let
                                        localUser : LocalUser
                                        localUser =
                                            local.localUser

                                        user : BackendUser
                                        user =
                                            localUser.user
                                    in
                                    { local
                                        | guilds =
                                            SeqDict.insert
                                                guildId
                                                { guild
                                                    | channels =
                                                        SeqDict.insert
                                                            channelId
                                                            (case threadRouteWithRepliedTo of
                                                                ViewThreadWithMaybeMessage threadId maybeReplyTo ->
                                                                    LocalState.createThreadMessage
                                                                        Nothing
                                                                        threadId
                                                                        (UserTextMessage
                                                                            { createdAt = createdAt
                                                                            , createdBy = userId
                                                                            , content = text
                                                                            , reactions = SeqDict.empty
                                                                            , editedAt = Nothing
                                                                            , repliedTo = maybeReplyTo
                                                                            , attachedFiles = attachedFiles
                                                                            }
                                                                        )
                                                                        channel

                                                                NoThreadWithMaybeMessage maybeReplyTo ->
                                                                    LocalState.createChannelMessage
                                                                        Nothing
                                                                        (UserTextMessage
                                                                            { createdAt = createdAt
                                                                            , createdBy = userId
                                                                            , content = text
                                                                            , reactions = SeqDict.empty
                                                                            , editedAt = Nothing
                                                                            , repliedTo = maybeReplyTo
                                                                            , attachedFiles = attachedFiles
                                                                            }
                                                                        )
                                                                        channel
                                                            )
                                                            guild.channels
                                                }
                                                local.guilds
                                        , localUser =
                                            { localUser
                                                | user =
                                                    if userId == localUser.userId then
                                                        { user
                                                            | lastViewed =
                                                                SeqDict.insert
                                                                    guildOrDmId
                                                                    (Array.length channel.messages |> Id.fromInt)
                                                                    user.lastViewed
                                                        }

                                                    else
                                                        user
                                            }
                                    }

                                Nothing ->
                                    local

                        GuildOrDmId_Dm_NoThread otherUserId ->
                            let
                                localUser : LocalUser
                                localUser =
                                    local.localUser

                                user : BackendUser
                                user =
                                    localUser.user

                                dmChannel : DmChannel
                                dmChannel =
                                    SeqDict.get otherUserId local.dmChannels |> Maybe.withDefault DmChannel.init

                                dmChannel2 : DmChannel
                                dmChannel2 =
                                    case threadRouteWithRepliedTo of
                                        ViewThreadWithMaybeMessage threadId maybeReplyTo ->
                                            LocalState.createThreadMessage
                                                Nothing
                                                threadId
                                                (UserTextMessage
                                                    { createdAt = createdAt
                                                    , createdBy = userId
                                                    , content = text
                                                    , reactions = SeqDict.empty
                                                    , editedAt = Nothing
                                                    , repliedTo = maybeReplyTo
                                                    , attachedFiles = attachedFiles
                                                    }
                                                )
                                                dmChannel

                                        NoThreadWithMaybeMessage maybeReplyTo ->
                                            LocalState.createChannelMessage
                                                Nothing
                                                (UserTextMessage
                                                    { createdAt = createdAt
                                                    , createdBy = userId
                                                    , content = text
                                                    , reactions = SeqDict.empty
                                                    , editedAt = Nothing
                                                    , repliedTo = maybeReplyTo
                                                    , attachedFiles = attachedFiles
                                                    }
                                                )
                                                dmChannel
                            in
                            { local
                                | dmChannels = SeqDict.insert otherUserId dmChannel2 local.dmChannels
                                , localUser =
                                    { localUser
                                        | user =
                                            if userId == localUser.userId then
                                                { user
                                                    | lastViewed =
                                                        SeqDict.insert
                                                            guildOrDmId
                                                            (Array.length dmChannel2.messages - 1 |> Id.fromInt)
                                                            user.lastViewed
                                                }

                                            else
                                                user
                                    }
                            }

                Server_NewChannel time guildId channelName ->
                    { local
                        | guilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.createChannelFrontend time local.localUser.userId channelName)
                                local.guilds
                    }

                Server_EditChannel guildId channelId channelName ->
                    { local
                        | guilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.editChannel channelName channelId)
                                local.guilds
                    }

                Server_DeleteChannel guildId channelId ->
                    { local
                        | guilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.deleteChannelFrontend channelId)
                                local.guilds
                    }

                Server_NewInviteLink time userId guildId inviteLinkId ->
                    { local
                        | guilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.addInvite inviteLinkId userId time)
                                local.guilds
                    }

                Server_MemberJoined time userId guildId user ->
                    let
                        localUser =
                            local.localUser
                    in
                    { local
                        | guilds =
                            SeqDict.updateIfExists
                                guildId
                                (\guild -> LocalState.addMember time userId guild |> Result.withDefault guild)
                                local.guilds
                        , localUser = { localUser | otherUsers = SeqDict.insert userId user localUser.otherUsers }
                    }

                Server_YouJoinedGuildByInvite result ->
                    case result of
                        Ok ok ->
                            let
                                localUser =
                                    local.localUser
                            in
                            { local
                                | guilds =
                                    SeqDict.insert ok.guildId ok.guild local.guilds
                                , localUser =
                                    { localUser
                                        | otherUsers =
                                            SeqDict.insert
                                                ok.guild.owner
                                                ok.owner
                                                localUser.otherUsers
                                                |> SeqDict.union ok.members
                                        , user =
                                            LocalState.markAllChannelsAsViewed
                                                ok.guildId
                                                ok.guild
                                                localUser.user
                                    }
                            }

                        Err error ->
                            { local | joinGuildError = Just error }

                Server_MemberTyping time userId guildOrDmId ->
                    memberTyping time userId guildOrDmId local

                Server_AddReactionEmoji userId guildOrDmId messageIndex emoji ->
                    addReactionEmoji userId guildOrDmId messageIndex emoji local

                Server_RemoveReactionEmoji userId guildOrDmId messageIndex emoji ->
                    removeReactionEmoji userId guildOrDmId messageIndex emoji local

                Server_SendEditMessage time userId guildOrDmId messageIndex newContent attachedFiles ->
                    editMessage time userId guildOrDmId newContent attachedFiles messageIndex local

                Server_MemberEditTyping time userId guildOrDmId messageIndex ->
                    memberEditTyping time userId guildOrDmId messageIndex local

                Server_DeleteMessage userId guildOrDmId messageIndex ->
                    deleteMessage userId guildOrDmId messageIndex local

                Server_DiscordDeleteMessage messageId ->
                    { local
                        | guilds =
                            SeqDict.updateIfExists
                                messageId.guildId
                                (\guild ->
                                    { guild
                                        | channels =
                                            SeqDict.updateIfExists
                                                messageId.channelId
                                                (\channel ->
                                                    case LocalState.getArray messageId.messageIndex channel.messages of
                                                        Just (UserTextMessage data) ->
                                                            { channel
                                                                | messages =
                                                                    LocalState.setArray
                                                                        messageId.messageIndex
                                                                        (DeletedMessage data.createdAt)
                                                                        channel.messages
                                                            }

                                                        _ ->
                                                            channel
                                                )
                                                guild.channels
                                    }
                                )
                                local.guilds
                    }

                Server_SetName userId name ->
                    let
                        localUser : LocalUser
                        localUser =
                            local.localUser
                    in
                    { local
                        | localUser =
                            { localUser
                                | otherUsers =
                                    SeqDict.updateIfExists userId (User.setName name) localUser.otherUsers
                            }
                    }

                Server_DiscordDirectMessage time discordMessageId sender richText replyTo ->
                    { local
                        | dmChannels =
                            SeqDict.update
                                sender
                                (\maybe ->
                                    Maybe.withDefault DmChannel.init maybe
                                        |> LocalState.createChannelMessage
                                            (Just discordMessageId)
                                            (UserTextMessage
                                                { createdAt = time
                                                , createdBy = sender
                                                , content = richText
                                                , reactions = SeqDict.empty
                                                , editedAt = Nothing
                                                , repliedTo = replyTo
                                                , attachedFiles = SeqDict.empty
                                                }
                                            )
                                        |> Just
                                )
                                local.dmChannels
                    }

                Server_PushNotificationsReset publicVapidKey ->
                    { local | publicVapidKey = publicVapidKey }


memberTyping : Time.Posix -> Id UserId -> GuildOrDmId -> LocalState -> LocalState
memberTyping time userId ( guildOrDmId, threadRoute ) local =
    case guildOrDmId of
        GuildOrDmId_Guild_NoThread guildId channelId ->
            { local
                | guilds =
                    SeqDict.updateIfExists
                        guildId
                        (LocalState.updateChannel (LocalState.memberIsTyping userId time threadRoute) channelId)
                        local.guilds
            }

        GuildOrDmId_Dm_NoThread otherUserId ->
            { local
                | dmChannels =
                    SeqDict.updateIfExists
                        otherUserId
                        (LocalState.memberIsTyping userId time threadRoute)
                        local.dmChannels
            }


addReactionEmoji : Id UserId -> GuildOrDmId -> Id ChannelMessageId -> Emoji -> LocalState -> LocalState
addReactionEmoji userId ( guildOrDmId, threadRoute ) messageIndex emoji local =
    case guildOrDmId of
        GuildOrDmId_Guild_NoThread guildId channelId ->
            { local
                | guilds =
                    SeqDict.updateIfExists
                        guildId
                        (LocalState.updateChannel
                            (LocalState.addReactionEmoji emoji userId threadRoute messageIndex)
                            channelId
                        )
                        local.guilds
            }

        GuildOrDmId_Dm_NoThread otherUserId ->
            { local
                | dmChannels =
                    SeqDict.updateIfExists
                        otherUserId
                        (LocalState.addReactionEmoji emoji userId threadRoute messageIndex)
                        local.dmChannels
            }


removeReactionEmoji : Id UserId -> GuildOrDmId -> Id ChannelMessageId -> Emoji -> LocalState -> LocalState
removeReactionEmoji userId ( guildOrDmId, threadRoute ) messageIndex emoji local =
    case guildOrDmId of
        GuildOrDmId_Guild_NoThread guildId channelId ->
            { local
                | guilds =
                    SeqDict.updateIfExists
                        guildId
                        (LocalState.updateChannel
                            (LocalState.removeReactionEmoji emoji userId threadRoute messageIndex)
                            channelId
                        )
                        local.guilds
            }

        GuildOrDmId_Dm_NoThread otherUserId ->
            { local
                | dmChannels =
                    SeqDict.updateIfExists
                        otherUserId
                        (LocalState.removeReactionEmoji emoji userId threadRoute messageIndex)
                        local.dmChannels
            }


memberEditTyping : Time.Posix -> Id UserId -> GuildOrDmIdNoThread -> ThreadRouteWithMessage -> LocalState -> LocalState
memberEditTyping time userId guildOrDmId threadRoute local =
    case guildOrDmId of
        GuildOrDmId_Guild_NoThread guildId channelId ->
            { local
                | guilds =
                    SeqDict.updateIfExists
                        guildId
                        (\guild ->
                            LocalState.memberIsEditTyping userId time channelId threadRoute guild
                                |> Result.withDefault guild
                        )
                        local.guilds
            }

        GuildOrDmId_Dm_NoThread otherUserId ->
            { local
                | dmChannels =
                    SeqDict.updateIfExists
                        otherUserId
                        (\dmChannel ->
                            LocalState.memberIsEditTypingHelper time userId threadRoute dmChannel
                                |> Result.withDefault dmChannel
                        )
                        local.dmChannels
            }


editMessage :
    Time.Posix
    -> Id UserId
    -> GuildOrDmIdNoThread
    -> Nonempty RichText
    -> SeqDict (Id FileId) FileData
    -> ThreadRouteWithMessage
    -> LocalState
    -> LocalState
editMessage time userId guildOrDmId newContent attachedFiles threadRoute local =
    case guildOrDmId of
        GuildOrDmId_Guild_NoThread guildId channelId ->
            { local
                | guilds =
                    SeqDict.updateIfExists
                        guildId
                        (LocalState.updateChannel
                            (\channel ->
                                LocalState.editMessageHelper
                                    time
                                    userId
                                    newContent
                                    attachedFiles
                                    threadRoute
                                    channel
                                    |> Result.withDefault channel
                            )
                            channelId
                        )
                        local.guilds
            }

        GuildOrDmId_Dm_NoThread otherUserId ->
            { local
                | dmChannels =
                    SeqDict.updateIfExists
                        otherUserId
                        (\dmChannel ->
                            LocalState.editMessageHelper
                                time
                                userId
                                newContent
                                attachedFiles
                                threadRoute
                                dmChannel
                                |> Result.withDefault dmChannel
                        )
                        local.dmChannels
            }


deleteMessage : Id UserId -> GuildOrDmIdNoThread -> ThreadRouteWithMessage -> LocalState -> LocalState
deleteMessage userId guildOrDmId threadRoute local =
    case guildOrDmId of
        GuildOrDmId_Guild_NoThread guildId channelId ->
            case SeqDict.get guildId local.guilds of
                Just guild ->
                    case LocalState.deleteMessage userId channelId threadRoute guild of
                        Ok guild2 ->
                            { local
                                | guilds =
                                    SeqDict.insert guildId guild2 local.guilds
                            }

                        Err () ->
                            local

                Nothing ->
                    local

        GuildOrDmId_Dm_NoThread otherUserId ->
            { local
                | dmChannels =
                    SeqDict.updateIfExists
                        otherUserId
                        (\dmChannel ->
                            LocalState.deleteMessageHelper
                                userId
                                threadRoute
                                dmChannel
                                |> Result.withDefault dmChannel
                        )
                        local.dmChannels
            }


handleLocalChange :
    Time.Posix
    -> Maybe LocalChange
    -> LoggedIn2
    -> Command FrontendOnly ToBackend msg
    -> ( LoggedIn2, Command FrontendOnly ToBackend msg )
handleLocalChange time maybeLocalChange loggedIn cmds =
    case maybeLocalChange of
        Just localChange ->
            let
                ( changeId, localState2 ) =
                    Local.update
                        changeUpdate
                        time
                        (LocalChange (Local.model loggedIn.localState).localUser.userId localChange)
                        loggedIn.localState
            in
            ( { loggedIn | localState = localState2 }
            , Command.batch
                [ cmds
                , LocalModelChangeRequest changeId localChange |> Lamdera.sendToBackend
                ]
            )

        Nothing ->
            ( loggedIn, cmds )


updateLoggedIn :
    (LoggedIn2 -> ( LoggedIn2, Command FrontendOnly ToBackend FrontendMsg ))
    -> LoadedFrontend
    -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg )
updateLoggedIn updateFunc model =
    case model.loginStatus of
        LoggedIn loggedIn ->
            updateFunc loggedIn |> Tuple.mapFirst (\a -> { model | loginStatus = LoggedIn a })

        NotLoggedIn _ ->
            ( model, Command.none )


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
            updateLoadedFromBackend msg loaded |> Tuple.mapFirst Loaded


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
                                    loadedInitHelper model.time model.timezone loginData model

                                ( model2, cmdB ) =
                                    routeRequest
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
            logout model

        AdminToFrontend adminToFrontend ->
            case model.loginStatus of
                LoggedIn loggedIn ->
                    case loggedIn.admin of
                        Just admin ->
                            let
                                ( newAdmin, cmd ) =
                                    Pages.Admin.updateFromBackend adminToFrontend admin
                            in
                            ( { model | loginStatus = LoggedIn { loggedIn | admin = Just newAdmin } }
                            , Command.map AdminToBackend AdminPageMsg cmd
                            )

                        Nothing ->
                            ( model, Command.none )

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

        LocalChangeResponse changeId localChange ->
            updateLoggedIn
                (\loggedIn ->
                    let
                        userId : Id UserId
                        userId =
                            (Local.model loggedIn.localState).localUser.userId

                        change : LocalMsg
                        change =
                            LocalChange userId localChange

                        localState : Local LocalMsg LocalState
                        localState =
                            Local.updateFromBackend changeUpdate (Just changeId) change loggedIn.localState
                    in
                    ( { loggedIn | localState = localState }
                    , case localChange of
                        Local_NewGuild _ _ (FilledInByBackend guildId) ->
                            case SeqDict.get guildId (Local.model localState).guilds of
                                Just guild ->
                                    routeReplace
                                        model
                                        (GuildRoute
                                            guildId
                                            (ChannelRoute
                                                (LocalState.announcementChannel guild)
                                                (NoThreadWithMaybeMessage Nothing)
                                            )
                                        )

                                Nothing ->
                                    Command.none

                        _ ->
                            Command.none
                    )
                )
                model

        ChangeBroadcast change ->
            updateLoggedIn
                (\loggedIn ->
                    let
                        localState : Local LocalMsg LocalState
                        localState =
                            Local.updateFromBackend changeUpdate Nothing change loggedIn.localState

                        local : LocalState
                        local =
                            Local.model localState
                    in
                    ( { loggedIn | localState = localState }
                    , case change of
                        ServerChange (Server_YouJoinedGuildByInvite (Ok { guildId, guild })) ->
                            case model.route of
                                GuildRoute inviteGuildId _ ->
                                    if inviteGuildId == guildId then
                                        routeReplace
                                            model
                                            (GuildRoute
                                                guildId
                                                (ChannelRoute
                                                    (LocalState.announcementChannel guild)
                                                    (NoThreadWithMaybeMessage Nothing)
                                                )
                                            )

                                    else
                                        Command.none

                                _ ->
                                    Command.none

                        ServerChange (Server_SendMessage senderId _ guildOrDmId content maybeRepliedTo _) ->
                            case guildOrDmId of
                                GuildOrDmId_Guild_NoThread guildId channelId ->
                                    case LocalState.getGuildAndChannel guildId channelId local of
                                        Just ( _, channel ) ->
                                            Command.batch
                                                [ playNotificationSound
                                                    senderId
                                                    maybeRepliedTo
                                                    channel
                                                    local
                                                    content
                                                    model
                                                , if model.scrolledToBottomOfChannel then
                                                    scrollToBottomOfChannel

                                                  else
                                                    Command.none
                                                ]

                                        Nothing ->
                                            Command.none

                                GuildOrDmId_Dm_NoThread _ ->
                                    Command.none

                        _ ->
                            Command.none
                    )
                )
                model

        TwoFactorAuthenticationToFrontend toFrontend2 ->
            updateLoggedIn
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
            updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn | isReloading = True }, Lamdera.sendToBackend ReloadDataRequest )
                )
                model

        ReloadDataResponse reloadData ->
            case reloadData of
                Ok loginData ->
                    updateLoggedIn
                        (\loggedIn ->
                            ( { loggedIn
                                | localState = loginDataToLocalState model.timezone loginData |> Local.init
                                , isReloading = False
                              }
                            , Command.none
                            )
                        )
                        model

                Err () ->
                    logout model


logout : LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg )
logout model =
    case model.loginStatus of
        LoggedIn _ ->
            let
                model2 : LoadedFrontend
                model2 =
                    { model
                        | loginStatus =
                            NotLoggedIn { loginForm = Nothing, useInviteAfterLoggedIn = Nothing }
                    }
            in
            if routeRequiresLogin model2.route then
                routePush model2 HomePageRoute

            else
                ( model2, Command.none )

        NotLoggedIn _ ->
            ( model, Command.none )


scrollToBottomOfChannel : Command FrontendOnly toMsg FrontendMsg
scrollToBottomOfChannel =
    Dom.setViewportOf Pages.Guild.conversationContainerId 0 9999999 |> Task.attempt (\_ -> ScrolledToBottom)


playNotificationSound :
    Id UserId
    -> ThreadRouteWithMaybeMessage
    -> FrontendChannel
    -> LocalState
    -> Nonempty RichText
    -> LoadedFrontend
    -> Command FrontendOnly toMsg msg
playNotificationSound senderId threadRouteWithRepliedTo channel local content model =
    if False then
        if
            SeqSet.member
                local.localUser.userId
                (LocalState.usersToNotify senderId threadRouteWithRepliedTo channel content)
        then
            Command.batch
                [ Ports.playSound "pop"
                , Ports.setFavicon "/favicon-red.ico"
                , case model.notificationPermission of
                    Ports.Granted ->
                        Ports.showNotification
                            (User.toString senderId (LocalState.allUsers local))
                            (RichText.toString (LocalState.allUsers local) content)

                    _ ->
                        Command.none
                ]

        else
            Command.none

    else
        Command.none


pendingChangesText : LocalChange -> String
pendingChangesText localChange =
    case localChange of
        Local_Invalid ->
            -- We should never have a invalid change in the local msg queue
            "InvalidChange"

        Local_Admin adminChange ->
            case adminChange of
                Pages.Admin.ChangeUsers _ ->
                    "Changed users via admin page"

                Pages.Admin.ExpandSection _ ->
                    "Expanded section in admin page"

                Pages.Admin.CollapseSection _ ->
                    "Collapsed section in admin page"

                Pages.Admin.LogPageChanged int ->
                    "Switched to log page " ++ String.fromInt int

                Pages.Admin.SetEmailNotificationsEnabled isEnabled ->
                    if isEnabled then
                        "Enabled email notifications"

                    else
                        "Disabled email notifications"

                Pages.Admin.SetDiscordBotToken _ ->
                    "Set Discord bot token"

                Pages.Admin.SetPrivateVapidKey _ ->
                    "Set private vapid key"

                Pages.Admin.SetPublicVapidKey _ ->
                    "Set public vapid key"

        Local_SendMessage _ _ _ _ _ ->
            "Sent a message"

        Local_NewChannel _ _ _ ->
            "Created new channel"

        Local_EditChannel _ _ _ ->
            "Edited channel"

        Local_DeleteChannel _ _ ->
            "Deleted channel"

        Local_NewInviteLink _ _ _ ->
            "Created invite link"

        Local_NewGuild _ _ _ ->
            "Created new guild"

        Local_MemberTyping _ _ ->
            "Is typing notification"

        Local_AddReactionEmoji _ _ _ ->
            "Added reaction emoji"

        Local_RemoveReactionEmoji _ _ _ ->
            "Removed reaction emoji"

        Local_SendEditMessage _ _ _ _ _ ->
            "Edit message"

        Local_MemberEditTyping _ _ _ ->
            "Editing message"

        Local_SetLastViewed _ _ ->
            "Viewed channel"

        Local_DeleteMessage _ _ ->
            "Delete message"

        Local_ViewChannel _ _ ->
            "View channel"

        Local_SetName _ ->
            "Set display name"


layout : LoadedFrontend -> List (Ui.Attribute FrontendMsg) -> Element FrontendMsg -> Html FrontendMsg
layout model attributes child =
    Ui.Anim.layout
        { options = []
        , toMsg = ElmUiMsg
        , breakpoints = Nothing
        }
        model.elmUiState
        ((case model.loginStatus of
            LoggedIn loggedIn ->
                let
                    local =
                        Local.model loggedIn.localState

                    maybeMessageId : Maybe GuildOrDmId
                    maybeMessageId =
                        routeToGuildOrDmId model.route
                in
                [ Local.networkError
                    (\change ->
                        case change of
                            LocalChange _ localChange ->
                                pendingChangesText localChange

                            ServerChange _ ->
                                ""
                    )
                    model.time
                    loggedIn.localState
                    |> Ui.inFront
                , case maybeMessageId of
                    Just ( guildOrDmId, threadRoute ) ->
                        case loggedIn.pingUser of
                            Just pingUser ->
                                MessageInput.pingDropdownView
                                    (case pingUser.target of
                                        MessageInput.NewMessage ->
                                            Pages.Guild.messageInputConfig ( guildOrDmId, threadRoute )

                                        MessageInput.EditMessage ->
                                            MessageMenu.editMessageTextInputConfig guildOrDmId threadRoute
                                    )
                                    guildOrDmId
                                    local
                                    Pages.Guild.dropdownButtonId
                                    pingUser
                                    |> Ui.inFront

                            Nothing ->
                                Ui.noAttr

                    _ ->
                        Ui.noAttr
                , case loggedIn.messageHover of
                    MessageMenu extraOptions ->
                        MessageMenu.view model extraOptions local loggedIn
                            |> Ui.inFront

                    MessageHover _ _ ->
                        Ui.noAttr

                    NoMessageHover ->
                        Ui.noAttr
                ]

            NotLoggedIn _ ->
                []
         )
            ++ Ui.Font.family [ Ui.Font.sansSerif ]
            :: Ui.height Ui.fill
            :: Ui.behindContent (Ui.html MyUi.css)
            :: Ui.Font.size 16
            :: Ui.Font.color MyUi.font1
            :: Ui.htmlAttribute (Html.Events.onClick PressedBody)
            :: attributes
            ++ (if MyUi.isMobile model then
                    [ Html.Events.on "touchstart" (Touch.touchEventDecoder (TouchStart Nothing)) |> Ui.htmlAttribute
                    , Html.Events.on "touchmove" (Touch.touchEventDecoder TouchMoved) |> Ui.htmlAttribute
                    , Html.Events.on
                        "touchend"
                        (Json.Decode.field "timeStamp" Json.Decode.float
                            |> Json.Decode.map (\time -> round time |> Time.millisToPosix |> TouchEnd)
                        )
                        |> Ui.htmlAttribute
                    , Html.Events.on
                        "touchcancel"
                        (Json.Decode.field "timeStamp" Json.Decode.float
                            |> Json.Decode.map (\time -> round time |> Time.millisToPosix |> TouchCancel)
                        )
                        |> Ui.htmlAttribute
                    , Ui.clip
                    , MyUi.htmlStyle "user-select" "none"
                    , MyUi.htmlStyle "-webkit-user-select" "none"
                    ]

                else
                    []
               )
        )
        child


routePush : LoadedFrontend -> Route -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg )
routePush model route =
    if MyUi.isMobile model then
        routeRequest (Just model.route) route model

    else
        ( model, BrowserNavigation.pushUrl model.navigationKey (Route.encode route) )


routeReplace : LoadedFrontend -> Route -> Command FrontendOnly ToBackend FrontendMsg
routeReplace model route =
    BrowserNavigation.replaceUrl model.navigationKey (Route.encode route)


view : FrontendModel -> Browser.Document FrontendMsg
view model =
    { title = "AtChat"
    , body =
        [ case model of
            Loading loading ->
                let
                    supportEmail =
                        EmailAddress.toString Env.contactEmail

                    supportLink =
                        Html.a [ Html.Attributes.href ("mailto:" ++ supportEmail) ] [ Html.text supportEmail ]
                in
                (case loading.loginStatus of
                    LoadingData ->
                        [ Html.div [ Html.Attributes.id "loading" ] []
                        ]

                    LoadSuccess _ ->
                        case loading.time of
                            Just _ ->
                                -- Make sure all of these error messages are slightly different so we know which branch was reached
                                [ Html.text "Something went isn't working. Please contact "
                                , supportLink
                                ]

                            Nothing ->
                                [ Html.text "Something went wrong. Please contact "
                                , supportLink
                                ]

                    LoadError ->
                        [ Html.text "Something went wrong when loading the page. Please contact "
                        , supportLink
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
                                layout
                                    loaded
                                    [ case loggedIn.userOptions of
                                        Just userOptions ->
                                            UserOptions.view
                                                (MyUi.isMobile loaded)
                                                loaded.time
                                                local
                                                loggedIn
                                                loaded
                                                userOptions
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

                            NotLoggedIn { loginForm } ->
                                LoginForm.view
                                    (Maybe.withDefault LoginForm.init loginForm)
                                    (MyUi.isMobile loaded)
                                    loaded.pwaStatus
                                    |> Ui.map LoginFormMsg
                                    |> layout loaded
                                        [ Ui.background MyUi.background3
                                        , Ui.inFront (Pages.Home.header isMobile loaded.loginStatus)
                                        ]
                in
                case loaded.route of
                    HomePageRoute ->
                        layout
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
                                        Nothing
                                        loaded
                                        loggedIn
                                        (Local.model loggedIn.localState)

                                NotLoggedIn { loginForm } ->
                                    Ui.el
                                        [ Ui.inFront (Pages.Home.header isMobile loaded.loginStatus)
                                        , Ui.height Ui.fill
                                        ]
                                        (case loginForm of
                                            Just loginForm2 ->
                                                LoginForm.view loginForm2 (MyUi.isMobile loaded) loaded.pwaStatus |> Ui.map LoginFormMsg

                                            Nothing ->
                                                Ui.Lazy.lazy Pages.Home.view windowWidth
                                        )
                            )

                    AdminRoute _ ->
                        requiresLogin
                            (\loggedIn local ->
                                case ( loggedIn.admin, local.adminData ) of
                                    ( Just admin, IsAdmin adminData ) ->
                                        case NonemptyDict.get local.localUser.userId adminData.users of
                                            Just user ->
                                                Pages.Admin.view
                                                    loaded.timezone
                                                    adminData
                                                    user
                                                    admin
                                                    |> Ui.map AdminPageMsg

                                            Nothing ->
                                                Ui.text "User not found"

                                    _ ->
                                        Ui.el
                                            [ Ui.centerY, Ui.centerX, Ui.width Ui.shrink ]
                                            (Ui.text "Admin access required to view this page")
                            )

                    AiChatRoute ->
                        AiChat.view loaded.windowSize loaded.aiChatModel
                            |> Ui.map AiChatMsg
                            |> layout loaded
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

                    DmRoute userId thread ->
                        requiresLogin
                            (Pages.Guild.homePageLoggedInView (Just ( userId, thread )) loaded)
        ]
    }


guildOrDmIdToMessage : GuildOrDmId -> Id ChannelMessageId -> LocalState -> Maybe UserTextMessageData
guildOrDmIdToMessage guildOrDmId messageIndex local =
    case guildOrDmIdToMessages guildOrDmId local of
        Just messages ->
            case LocalState.getArray messageIndex messages of
                Just (UserTextMessage data) ->
                    Just data

                _ ->
                    Nothing

        Nothing ->
            Nothing


guildOrDmIdToMessages : GuildOrDmId -> LocalState -> Maybe (Array Message)
guildOrDmIdToMessages ( guildOrDmId, threadRoute ) local =
    case guildOrDmId of
        GuildOrDmId_Guild_NoThread guildId channelId ->
            case LocalState.getGuildAndChannel guildId channelId local of
                Just ( _, channel ) ->
                    case threadRoute of
                        ViewThread threadMessageIndex ->
                            SeqDict.get threadMessageIndex channel.threads |> Maybe.map .messages

                        NoThread ->
                            Just channel.messages

                Nothing ->
                    Nothing

        GuildOrDmId_Dm_NoThread otherUserId ->
            case SeqDict.get otherUserId local.dmChannels of
                Just dmChannel ->
                    case threadRoute of
                        ViewThread threadMessageIndex ->
                            SeqDict.get threadMessageIndex dmChannel.threads |> Maybe.map .messages

                        NoThread ->
                            Just dmChannel.messages

                Nothing ->
                    Nothing


guildOrDmIdNoThreadToMessages : GuildOrDmIdNoThread -> ThreadRouteWithMaybeMessage -> LocalState -> Maybe (Array Message)
guildOrDmIdNoThreadToMessages guildOrDmId threadRoute local =
    case guildOrDmId of
        GuildOrDmId_Guild_NoThread guildId channelId ->
            case LocalState.getGuildAndChannel guildId channelId local of
                Just ( _, channel ) ->
                    case threadRoute of
                        ViewThreadWithMaybeMessage threadMessageIndex _ ->
                            SeqDict.get threadMessageIndex channel.threads |> Maybe.map .messages

                        NoThreadWithMaybeMessage _ ->
                            Just channel.messages

                Nothing ->
                    Nothing

        GuildOrDmId_Dm_NoThread otherUserId ->
            case SeqDict.get otherUserId local.dmChannels of
                Just dmChannel ->
                    case threadRoute of
                        ViewThreadWithMaybeMessage threadMessageIndex _ ->
                            SeqDict.get threadMessageIndex dmChannel.threads |> Maybe.map .messages

                        NoThreadWithMaybeMessage _ ->
                            Just dmChannel.messages

                Nothing ->
                    Nothing


guildOrDmIdNoThreadToMessage : GuildOrDmIdNoThread -> ThreadRouteWithMessage -> LocalState -> Maybe Message
guildOrDmIdNoThreadToMessage guildOrDmId threadRoute local =
    case guildOrDmId of
        GuildOrDmId_Guild_NoThread guildId channelId ->
            case LocalState.getGuildAndChannel guildId channelId local of
                Just ( _, channel ) ->
                    case threadRoute of
                        ViewThreadWithMessage threadMessageIndex messageId ->
                            SeqDict.get threadMessageIndex channel.threads
                                |> Maybe.withDefault DmChannel.threadInit
                                |> .messages
                                |> LocalState.getArray messageId

                        NoThreadWithMessage messageId ->
                            LocalState.getArray messageId channel.messages

                Nothing ->
                    Nothing

        GuildOrDmId_Dm_NoThread otherUserId ->
            case SeqDict.get otherUserId local.dmChannels of
                Just dmChannel ->
                    case threadRoute of
                        ViewThreadWithMessage threadMessageIndex messageId ->
                            SeqDict.get threadMessageIndex dmChannel.threads
                                |> Maybe.withDefault DmChannel.threadInit
                                |> .messages
                                |> LocalState.getArray messageId

                        NoThreadWithMessage messageId ->
                            LocalState.getArray messageId dmChannel.messages

                Nothing ->
                    Nothing


routeToGuildOrDmId : Route -> Maybe GuildOrDmId
routeToGuildOrDmId route =
    case route of
        GuildRoute guildId (ChannelRoute channelId threadRoute) ->
            ( GuildOrDmId_Guild_NoThread guildId channelId
            , case threadRoute of
                ViewThreadWithMaybeMessage threadMessageId _ ->
                    ViewThread threadMessageId

                NoThreadWithMaybeMessage _ ->
                    NoThread
            )
                |> Just

        DmRoute otherUserId threadRoute ->
            ( GuildOrDmId_Dm_NoThread otherUserId
            , case threadRoute of
                ViewThreadWithMaybeMessage threadMessageId _ ->
                    ViewThread threadMessageId

                NoThreadWithMaybeMessage _ ->
                    NoThread
            )
                |> Just

        _ ->
            Nothing


routeToGuildOrDmIdNoThread : Route -> Maybe ( GuildOrDmIdNoThread, ThreadRouteWithMaybeMessage )
routeToGuildOrDmIdNoThread route =
    case route of
        GuildRoute guildId (ChannelRoute channelId threadRoute) ->
            ( GuildOrDmId_Guild_NoThread guildId channelId, threadRoute ) |> Just

        DmRoute otherUserId threadRoute ->
            ( GuildOrDmId_Dm_NoThread otherUserId, threadRoute ) |> Just

        _ ->
            Nothing
