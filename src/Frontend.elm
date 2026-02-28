module Frontend exposing (app, app_)

import AiChat
import Array exposing (Array)
import Browser exposing (UrlRequest(..))
import Browser.Navigation
import ChannelName
import Codec
import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Discord.Id
import DmChannel exposing (DiscordFrontendDmChannel, FrontendDmChannel)
import Duration exposing (Duration, Seconds)
import Ease
import Editable
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Browser.Events
import Effect.Browser.Navigation as BrowserNavigation exposing (Key)
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.File as File exposing (File)
import Effect.File.Download
import Effect.File.Select
import Effect.Http as Http
import Effect.Lamdera as Lamdera
import Effect.Process as Process
import Effect.Subscription as Subscription exposing (Subscription)
import Effect.Task as Task exposing (Task)
import Effect.Time as Time
import Emoji exposing (Emoji)
import FileName
import FileStatus exposing (FileData, FileId, FileStatus(..))
import GuildExport
import GuildName
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Id exposing (AnyGuildOrDmId(..), ChannelId, ChannelMessageId, DiscordGuildOrDmId(..), GuildOrDmId(..), Id, ThreadRoute(..), ThreadRouteWithMaybeMessage(..), ThreadRouteWithMessage(..), UserId)
import ImageEditor
import Json.Decode
import Lamdera as LamderaCore
import List.Extra
import List.Nonempty exposing (Nonempty(..))
import Local exposing (Local)
import LocalState exposing (AdminStatus(..), ChangeAttachments(..), FrontendChannel, LocalState, LocalUser)
import LoginForm
import Message exposing (Message(..), MessageNoReply(..), MessageState(..), MessageStateNoReply(..), UserTextMessageDataNoReply)
import MessageInput
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
import RichText exposing (RichText)
import Route exposing (ChannelRoute(..), DiscordChannelRoute(..), LinkDiscordError(..), Route(..), ShowMembersTab(..), ThreadRouteWithFriends(..))
import SeqDict exposing (SeqDict)
import SeqSet
import String.Nonempty
import TextEditor
import Thread exposing (FrontendGenericThread, FrontendThread)
import Touch exposing (Touch)
import TwoFactorAuthentication exposing (TwoFactorState(..))
import Types exposing (AdminStatusLoginData(..), ChannelSidebarMode(..), Drag(..), EmojiSelector(..), FrontendModel(..), FrontendMsg(..), GuildChannelNameHover(..), LoadStatus(..), LoadedFrontend, LoadingFrontend, LocalChange(..), LocalMsg(..), LoggedIn2, LoginData, LoginResult(..), LoginStatus(..), MessageHover(..), MessageHoverMobileMode(..), RevealedSpoilers, ScrollPosition(..), ServerChange(..), ToBackend(..), ToFrontend(..), UserOptionsModel)
import Ui exposing (Element)
import Ui.Anim
import Ui.Font
import Ui.Lazy
import Url exposing (Url)
import User exposing (DiscordUserLoadingData(..), FrontendCurrentUser, LastDmViewed(..), NotificationLevel(..))
import UserAgent exposing (UserAgent)
import UserOptions
import UserSession exposing (NotificationMode(..), PushSubscription(..), SetViewing(..), ToBeFilledInByBackend(..), UserSession)
import Vector2d
import VisibleMessages exposing (VisibleMessages)


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
            Route.decode (Debug.log "url" url)
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
        , Lamdera.sendToBackend (CheckLoginRequest (routeToGuildOrDmId route))
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
                    loadedInitHelper time loading.timezone userAgent loginData loading |> Tuple.mapFirst LoggedIn

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
            , aiChatModel = aiChatModel
            , scrollbarWidth = loading.scrollbarWidth
            , userAgent = userAgent
            , pageHasFocus = True
            }

        ( model2, cmdA ) =
            routeRequest Nothing model.route model
    in
    ( model2
    , Command.batch
        [ cmdB
        , cmdA
        , Command.map AiChatToBackend AiChatMsg aiChatCmd
        , case loginResult of
            Ok _ ->
                Ports.registerServiceWorker

            Err _ ->
                Command.none
        ]
    )


loadedInitHelper :
    Time.Posix
    -> Time.Zone
    -> UserAgent
    -> LoginData
    -> { a | windowSize : Coord CssPixels, navigationKey : Key, route : Route }
    -> ( LoggedIn2, Command FrontendOnly ToBackend FrontendMsg )
loadedInitHelper time timezone userAgent loginData loading =
    let
        localState : LocalState
        localState =
            loginDataToLocalState userAgent timezone loginData

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
            , channelNameHover = NoChannelNameHover
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
            , showFileToUploadInfo = Nothing
            , isReloading = False
            , channelScrollPosition = ScrolledToBottom
            , textEditor = TextEditor.init
            , profilePictureEditor = ImageEditor.init
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


loginDataToLocalState : UserAgent -> Time.Zone -> LoginData -> LocalState
loginDataToLocalState userAgent timezone loginData =
    { adminData =
        case loginData.adminData of
            IsAdminLoginData adminData ->
                IsAdmin
                    { users = adminData.users
                    , emailNotificationsEnabled = adminData.emailNotificationsEnabled
                    , twoFactorAuthentication = adminData.twoFactorAuthentication
                    , privateVapidKey = adminData.privateVapidKey
                    , slackClientSecret = adminData.slackClientSecret
                    , openRouterKey = adminData.openRouterKey
                    , discordDmChannels = adminData.discordDmChannels
                    , discordUsers = adminData.discordUsers
                    , discordGuilds = adminData.discordGuilds
                    , guilds = adminData.guilds
                    }

            IsNotAdminLoginData ->
                IsNotAdmin
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
            case ( isPressMsg msg, loaded.dragPrevious ) of
                ( True, Dragging _ ) ->
                    ( model, Command.none )

                _ ->
                    updateLoaded msg loaded |> Tuple.mapFirst Loaded


routeViewingLocalChange : LocalState -> Route -> Maybe LocalChange
routeViewingLocalChange local route =
    let
        localChange : SetViewing
        localChange =
            LocalState.routeToViewing route local
    in
    if UserSession.setViewingToCurrentlyViewing localChange == local.localUser.session.currentlyViewing then
        Nothing

    else
        Just (Local_CurrentlyViewing localChange)


routeRequest : Maybe Route -> Route -> LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg )
routeRequest previousRoute newRoute model =
    let
        ( model2, viewCmd ) =
            updateLoggedIn
                (\loggedIn ->
                    handleLocalChange
                        model.time
                        (routeViewingLocalChange (Local.model loggedIn.localState) newRoute)
                        loggedIn
                        Command.none
                )
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
            , viewCmd
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
                        , userOptions = Nothing
                      }
                    , viewCmd
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

                ( sameGuild, _ ) =
                    case previousRoute of
                        Just (GuildRoute previousGuildId previousChannelRoute) ->
                            ( guildId == previousGuildId
                            , guildId == previousGuildId && channelRoute == previousChannelRoute
                            )

                        _ ->
                            ( False, False )
            in
            case channelRoute of
                ChannelRoute _ threadRoute ->
                    let
                        showMembers : ShowMembersTab
                        showMembers =
                            case threadRoute of
                                ViewThreadWithFriends _ _ showMembers2 ->
                                    showMembers2

                                NoThreadWithFriends _ showMembers2 ->
                                    showMembers2

                        --previousShowMembers : ShowMembersTab
                        --previousShowMembers =
                        --    case threadRoute of
                        --        ViewThreadWithFriends threadId _ showMembers2 ->
                        --            showMembers2
                        --
                        --        NoThreadWithFriends maybeId showMembers2 ->
                        --            showMembers2
                    in
                    updateLoggedIn
                        (\loggedIn ->
                            ( case showMembers of
                                ShowMembersTab ->
                                    startOpeningChannelSidebar { loggedIn | sidebarMode = ChannelSidebarClosed }

                                HideMembersTab ->
                                    if sameGuild || previousRoute == Nothing then
                                        startOpeningChannelSidebar loggedIn

                                    else
                                        loggedIn
                            , Command.batch [ viewCmd, openChannelCmds threadRoute model3 ]
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
                            , viewCmd
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
                            , viewCmd
                            )
                        )
                        model3

                GuildSettingsRoute ->
                    updateLoggedIn
                        (\loggedIn ->
                            ( if sameGuild || previousRoute == Nothing then
                                startOpeningChannelSidebar loggedIn

                              else
                                loggedIn
                            , viewCmd
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
                            , viewCmd
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
                                                (ChannelRoute
                                                    (LocalState.announcementChannel guild)
                                                    (NoThreadWithFriends Nothing HideMembersTab)
                                                )
                                            )

                                    Nothing ->
                                        viewCmd
                                ]
                            )

        DiscordGuildRoute { currentDiscordUserId, guildId, channelRoute } ->
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

                ( sameGuild, _ ) =
                    case previousRoute of
                        Just (DiscordGuildRoute a) ->
                            ( currentDiscordUserId == a.currentDiscordUserId && guildId == a.guildId
                            , currentDiscordUserId == a.currentDiscordUserId && guildId == a.guildId && channelRoute == a.channelRoute
                            )

                        _ ->
                            ( False, False )
            in
            case channelRoute of
                DiscordChannel_ChannelRoute _ threadRoute ->
                    let
                        showMembers : ShowMembersTab
                        showMembers =
                            case threadRoute of
                                ViewThreadWithFriends _ _ showMembers2 ->
                                    showMembers2

                                NoThreadWithFriends _ showMembers2 ->
                                    showMembers2

                        --previousShowMembers : ShowMembersTab
                        --previousShowMembers =
                        --    case threadRoute of
                        --        ViewThreadWithFriends threadId _ showMembers2 ->
                        --            showMembers2
                        --
                        --        NoThreadWithFriends maybeId showMembers2 ->
                        --            showMembers2
                    in
                    updateLoggedIn
                        (\loggedIn ->
                            ( case showMembers of
                                ShowMembersTab ->
                                    startOpeningChannelSidebar { loggedIn | sidebarMode = ChannelSidebarClosed }

                                HideMembersTab ->
                                    if sameGuild || previousRoute == Nothing then
                                        startOpeningChannelSidebar loggedIn

                                    else
                                        loggedIn
                            , Command.batch [ viewCmd, openChannelCmds threadRoute model3 ]
                            )
                        )
                        model3

                DiscordChannel_NewChannelRoute ->
                    updateLoggedIn
                        (\loggedIn ->
                            ( if sameGuild || previousRoute == Nothing then
                                startOpeningChannelSidebar loggedIn

                              else
                                loggedIn
                            , viewCmd
                            )
                        )
                        model3

                DiscordChannel_EditChannelRoute _ ->
                    updateLoggedIn
                        (\loggedIn ->
                            ( if sameGuild || previousRoute == Nothing then
                                startOpeningChannelSidebar loggedIn

                              else
                                loggedIn
                            , viewCmd
                            )
                        )
                        model3

                DiscordChannel_GuildSettingsRoute ->
                    updateLoggedIn
                        (\loggedIn ->
                            ( if sameGuild || previousRoute == Nothing then
                                startOpeningChannelSidebar loggedIn

                              else
                                loggedIn
                            , viewCmd
                            )
                        )
                        model3

        AiChatRoute ->
            ( model2, Command.batch [ viewCmd, Command.map AiChatToBackend AiChatMsg AiChat.getModels ] )

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
                    ( startOpeningChannelSidebar loggedIn
                    , Command.batch [ viewCmd, openChannelCmds threadRoute model3 ]
                    )
                )
                model3

        DiscordDmRoute routeData ->
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
                    ( startOpeningChannelSidebar loggedIn
                    , Command.batch
                        [ viewCmd
                        , openChannelCmds (NoThreadWithFriends routeData.viewingMessage routeData.showMembersTab) model3
                        ]
                    )
                )
                model3

        SlackOAuthRedirect result ->
            ( model2
            , case result of
                Ok ( code, sessionId ) ->
                    Lamdera.sendToBackend (LinkSlackOAuthCode code sessionId)

                Err () ->
                    viewCmd
            )

        TextEditorRoute ->
            ( model2, Command.none )

        LinkDiscord result ->
            ( model2
            , case ( model2.loginStatus, result ) of
                ( LoggedIn _, Ok userData ) ->
                    LinkDiscordRequest userData |> Lamdera.sendToBackend

                _ ->
                    Command.none
            )


openChannelCmds :
    ThreadRouteWithFriends
    -> LoadedFrontend
    -> Command FrontendOnly ToBackend FrontendMsg
openChannelCmds threadRoute model3 =
    let
        scrollToBottom : Command FrontendOnly ToBackend FrontendMsg
        scrollToBottom =
            Process.sleep Duration.millisecond
                |> Task.andThen (\() -> Dom.setViewportOf Pages.Guild.conversationContainerId 0 9999999)
                |> Task.attempt (\_ -> SetScrollToBottom)
    in
    Command.batch
        [ setFocus model3 Pages.Guild.channelTextInputId
        , case threadRoute of
            ViewThreadWithFriends _ maybeMessageIndex _ ->
                case maybeMessageIndex of
                    Just messageIndex ->
                        smoothScroll (Pages.Guild.threadMessageHtmlId messageIndex)
                            |> Task.attempt (\_ -> ScrolledToMessage)

                    Nothing ->
                        scrollToBottom

            NoThreadWithFriends maybeMessageIndex _ ->
                case maybeMessageIndex of
                    Just messageIndex ->
                        smoothScroll (Pages.Guild.channelMessageHtmlId messageIndex)
                            |> Task.attempt (\_ -> ScrolledToMessage)

                    Nothing ->
                        scrollToBottom
        ]


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

        DiscordGuildRoute _ ->
            True

        DmRoute _ _ ->
            True

        SlackOAuthRedirect _ ->
            False

        TextEditorRoute ->
            False

        DiscordDmRoute _ ->
            True

        LinkDiscord _ ->
            False


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

        SetScrollToBottom ->
            False

        PressedChannelHeaderBackButton ->
            True

        UserScrolled _ _ _ ->
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

        ProfilePictureEditorMsg imageEditorMsg ->
            ImageEditor.isPressMsg imageEditorMsg

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

        SelectedNotificationMode _ ->
            True

        PressedGuildNotificationLevel _ _ ->
            True

        GotScrollbarWidth _ ->
            False

        PressedViewAttachedFileInfo _ _ ->
            True

        EditMessage_PressedViewAttachedFileInfo _ _ ->
            True

        PressedCloseImageInfo ->
            True

        PressedShowMembers ->
            True

        PressedMemberListBack ->
            True

        GotUserAgent _ ->
            False

        PageHasFocusChanged _ ->
            False

        GotServiceWorkerMessage _ ->
            False

        VisualViewportResized _ ->
            False

        TextEditorMsg textEditorMsg ->
            TextEditor.isPress textEditorMsg

        PressedLinkDiscordUser ->
            True

        PressedReloadDiscordUser _ ->
            True

        PressedUnlinkDiscordUser _ ->
            True

        MouseEnteredDiscordChannelName _ _ _ ->
            False

        MouseExitedDiscordChannelName _ _ _ ->
            False

        PressedDiscordGuildMemberLabel _ ->
            True

        PressedDiscordFriendLabel _ ->
            True

        PressedExportGuild _ ->
            True

        PressedExportDiscordGuild _ ->
            True

        PressedImportGuild ->
            True

        GuildImportFileSelected _ ->
            False

        GotGuildImportFileContent _ ->
            False

        PressedImportDiscordGuild ->
            True

        DiscordGuildImportFileSelected _ ->
            False

        GotDiscordGuildImportFileContent _ ->
            False

        TypedDiscordLinkBookmarklet ->
            False


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
            case model.loginStatus of
                LoggedIn loggedIn ->
                    case ( loggedIn.admin, (Local.model loggedIn.localState).adminData ) of
                        ( Just admin, IsAdmin adminData ) ->
                            let
                                ( newAdmin, cmd, outMsg ) =
                                    Pages.Admin.update
                                        model.navigationKey
                                        model.time
                                        adminData
                                        (Local.model loggedIn.localState)
                                        adminPageMsg
                                        admin

                                loggedIn2 : LoggedIn2
                                loggedIn2 =
                                    { loggedIn | admin = Just newAdmin }
                            in
                            case outMsg of
                                Pages.Admin.AdminChange adminChange ->
                                    let
                                        ( loggedIn3, cmd2 ) =
                                            handleLocalChange
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
                                    routePush { model | loginStatus = LoggedIn loggedIn2 } HomePageRoute

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
                        requestMessagesFor : Maybe ( AnyGuildOrDmId, ThreadRoute )
                        requestMessagesFor =
                            routeToGuildOrDmId model.route
                    in
                    case
                        LoginForm.update
                            (\email -> GetLoginTokenRequest email |> Lamdera.sendToBackend)
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
                    updateLoggedIn (setLastViewedToLatestMessage model) model

                ( model3, routeCmd ) =
                    routePush model2 route
            in
            ( model3, Command.batch [ cmd, Debug.log "routeCmd" routeCmd, notificationRequest ] )

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
                            , Process.sleep Pages.Guild.typingDebouncerDelay
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
                                handleLocalChange
                                    model.time
                                    ((case guildOrDmId of
                                        GuildOrDmId guildOrDmId2 ->
                                            Local_SendMessage
                                                model.time
                                                guildOrDmId2
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

                                        DiscordGuildOrDmId guildOrDmId2 ->
                                            Local_Discord_SendMessage
                                                model.time
                                                guildOrDmId2
                                                (RichText.fromNonemptyString (LocalState.allDiscordUsers2 local.localUser) nonempty)
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
                                        smoothScrollToBottomOfChannel

                                     else
                                        scrollToBottomOfChannel
                                    )

                            else
                                ( loggedIn, Command.none )

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
            updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn | channelNameHover = GuildChannelNameHover guildId channelId threadRoute }, Command.none )
                )
                model

        MouseExitedChannelName guildId channelId threadRoute ->
            updateLoggedIn
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
            updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn | channelNameHover = DiscordGuildChannelNameHover guildId channelId threadRoute }, Command.none )
                )
                model

        MouseExitedDiscordChannelName guildId channelId threadRoute ->
            updateLoggedIn
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
                        (GuildRoute
                            guildId
                            (ChannelRoute channelId (NoThreadWithFriends Nothing HideMembersTab))
                        )

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
                                            (ChannelRoute
                                                (LocalState.announcementChannel guild)
                                                (NoThreadWithFriends Nothing HideMembersTab)
                                            )
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
            ( { model | textInputFocus = Just htmlId }
            , Command.batch
                [ if model.userAgent.device == UserAgent.Desktop || model.textInputFocus == Just htmlId then
                    Command.none

                  else
                    Ports.fixCursorPosition htmlId
                , if htmlId == UserOptions.discordBookmarkletId then
                    Ports.textInputSelectAll htmlId

                  else
                    Command.none
                ]
            )

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
                                                            guildOrDmIdToMessagesCount
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
                                (case guildOrDmId of
                                    GuildOrDmId guildOrDmId2 ->
                                        case
                                            ( String.Nonempty.fromString edit.text
                                            , guildOrDmIdToMessage guildOrDmId2 (Id.threadRouteWithMessage edit.messageIndex threadRoute) local
                                            )
                                        of
                                            ( Just nonempty, Just ( message, _ ) ) ->
                                                let
                                                    richText : Nonempty (RichText (Id UserId))
                                                    richText =
                                                        RichText.fromNonemptyString
                                                            (LocalState.allUsers local)
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
                                            , discordGuildOrDmIdToMessage guildOrDmId2 (Id.threadRouteWithMessage edit.messageIndex threadRoute) local
                                            )
                                        of
                                            ( Just nonempty, Just ( message, _ ) ) ->
                                                let
                                                    richText : Nonempty (RichText (Discord.Id.Id Discord.Id.UserId))
                                                    richText =
                                                        RichText.fromNonemptyString
                                                            (LocalState.allDiscordUsers2 local.localUser)
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

        PressedArrowUpInEmptyInput ( guildOrDmId, threadRoute ) ->
            updateLoggedIn
                (\loggedIn ->
                    case guildOrDmId of
                        GuildOrDmId guildOrDmId2 ->
                            let
                                local : LocalState
                                local =
                                    Local.model loggedIn.localState

                                maybeMessages : Maybe (Array (MessageStateNoReply (Id UserId)))
                                maybeMessages =
                                    guildOrDmIdToMessages ( guildOrDmId2, threadRoute ) local
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

                        DiscordGuildOrDmId guildOrDmId2 ->
                            let
                                local : LocalState
                                local =
                                    Local.model loggedIn.localState

                                maybeMessages : Maybe (Array (MessageStateNoReply (Discord.Id.Id Discord.Id.UserId)))
                                maybeMessages =
                                    discordGuildOrDmIdToMessages guildOrDmId2 threadRoute local

                                currentUserId : Discord.Id.Id Discord.Id.UserId
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

                                        mostRecentMessage : Maybe ( Id ChannelMessageId, UserTextMessageDataNoReply (Discord.Id.Id Discord.Id.UserId) )
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
                                                                (LocalState.allDiscordUsers2 local.localUser)
                                                                message.content
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

        MessageMenu_PressedReply threadRoute ->
            case routeToGuildOrDmId model.route of
                Just ( guildOrDmId, _ ) ->
                    pressedReply guildOrDmId threadRoute model

                Nothing ->
                    ( model, Command.none )

        MessageMenu_PressedOpenThread messageIndex ->
            case ( model.route, model.loginStatus ) of
                ( GuildRoute guildId (ChannelRoute channelId (NoThreadWithFriends _ _)), LoggedIn loggedIn ) ->
                    routePush
                        { model | loginStatus = MessageMenu.close model loggedIn |> LoggedIn }
                        (GuildRoute
                            guildId
                            (ChannelRoute channelId (ViewThreadWithFriends messageIndex Nothing HideMembersTab))
                        )

                ( DmRoute otherUserId (NoThreadWithFriends _ _), LoggedIn loggedIn ) ->
                    routePush
                        { model | loginStatus = MessageMenu.close model loggedIn |> LoggedIn }
                        (DmRoute otherUserId (ViewThreadWithFriends messageIndex Nothing HideMembersTab))

                ( DiscordGuildRoute guildRoute, LoggedIn loggedIn ) ->
                    case guildRoute.channelRoute of
                        DiscordChannel_ChannelRoute channelId (NoThreadWithFriends _ _) ->
                            routePush
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
                    updateLoggedIn
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

                                        DmRoute _ threadRoute ->
                                            case threadRoute of
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
            updateLoggedIn (\loggedIn -> ( startClosingChannelSidebar loggedIn, Command.none )) model

        PressedShowMembers ->
            setShowMembers ShowMembersTab model

        UserScrolled guildOrDmId threadRoute scrollPosition ->
            updateLoggedIn
                (\loggedIn ->
                    case scrollPosition of
                        ScrolledToTop ->
                            let
                                local : LocalState
                                local =
                                    Local.model loggedIn.localState
                            in
                            handleLocalChange
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
            handleEditable
                editableMsg
                (\userOptions value -> { userOptions | name = value })
                (\value loggedIn -> handleLocalChange model.time (Just (Local_SetName value)) loggedIn Command.none)
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
                guildOrDmIdWithThread : ( AnyGuildOrDmId, ThreadRoute )
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
                            case guildOrDmId of
                                GuildOrDmId guildOrDmId2 ->
                                    case guildOrDmIdToMessage guildOrDmId2 threadRoute (Local.model loggedIn.localState) of
                                        Just ( _, maybeRepliedTo ) ->
                                            case ( guildOrDmId2, maybeRepliedTo ) of
                                                ( GuildOrDmId_Guild guildId channelId, ViewThreadWithMaybeMessage threadId (Just repliedTo) ) ->
                                                    routePush
                                                        model
                                                        (GuildRoute guildId
                                                            (ChannelRoute
                                                                channelId
                                                                (ViewThreadWithFriends threadId (Just repliedTo) HideMembersTab)
                                                            )
                                                        )

                                                ( GuildOrDmId_Dm otherUserId, NoThreadWithMaybeMessage (Just repliedTo) ) ->
                                                    routePush
                                                        model
                                                        (DmRoute
                                                            otherUserId
                                                            (NoThreadWithFriends (Just repliedTo) HideMembersTab)
                                                        )

                                                _ ->
                                                    ( model, Command.none )

                                        _ ->
                                            ( model, Command.none )

                                DiscordGuildOrDmId guildOrDmId2 ->
                                    case discordGuildOrDmIdToMessage guildOrDmId2 threadRoute (Local.model loggedIn.localState) of
                                        Just ( _, maybeRepliedTo ) ->
                                            case ( guildOrDmId2, maybeRepliedTo ) of
                                                ( DiscordGuildOrDmId_Guild currentDiscordUserId guildId channelId, ViewThreadWithMaybeMessage threadId (Just repliedTo) ) ->
                                                    routePush
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
                                                    routePush
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
                    updateLoggedIn
                        (\loggedIn ->
                            let
                                local : LocalState
                                local =
                                    Local.model loggedIn.localState

                                menuHeight : Int
                                menuHeight =
                                    MessageMenu.desktopMenuHeight
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
                        ( GuildOrDmId (GuildOrDmId_Guild guildId channelId), NoThreadWithMessage messageId ) ->
                            routePush
                                model
                                (GuildRoute
                                    guildId
                                    (ChannelRoute channelId (ViewThreadWithFriends messageId Nothing HideMembersTab))
                                )

                        ( GuildOrDmId (GuildOrDmId_Dm otherUserId), NoThreadWithMessage messageId ) ->
                            routePush
                                model
                                (DmRoute otherUserId (ViewThreadWithFriends messageId Nothing HideMembersTab))

                        ( DiscordGuildOrDmId (DiscordGuildOrDmId_Guild currentDiscordUserId guildId channelId), NoThreadWithMessage messageId ) ->
                            routePush
                                model
                                ({ currentDiscordUserId = currentDiscordUserId
                                 , guildId = guildId
                                 , channelRoute = DiscordChannel_ChannelRoute channelId (ViewThreadWithFriends messageId Nothing HideMembersTab)
                                 }
                                    |> DiscordGuildRoute
                                )

                        ( DiscordGuildOrDmId (DiscordGuildOrDmId_Dm { currentUserId, channelId }), NoThreadWithMessage _ ) ->
                            routePush
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

        GotRegisterPushSubscription result ->
            updateLoggedIn
                (\loggedIn ->
                    case result of
                        Ok endpoint ->
                            handleLocalChange
                                model.time
                                (Local_RegisterPushSubscription endpoint |> Just)
                                loggedIn
                                Command.none

                        Err _ ->
                            ( loggedIn, Command.none )
                )
                model

        SelectedNotificationMode notificationMode ->
            updateLoggedIn
                (\loggedIn ->
                    handleLocalChange
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
            updateLoggedIn
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
            updateLoggedIn
                (\loggedIn ->
                    handleLocalChange
                        model.time
                        (Local_SetGuildNotificationLevel guildId notificationLevel |> Just)
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
            updateLoggedIn
                (\loggedIn -> ( { loggedIn | showFileToUploadInfo = Nothing }, Command.none ))
                model

        PressedMemberListBack ->
            updateLoggedIn (\loggedIn -> ( startClosingChannelSidebar loggedIn, Command.none )) model

        PageHasFocusChanged hasFocus ->
            updateLoggedIn
                (\loggedIn ->
                    handleLocalChange
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
                    routePush model (Route.decode url2)

                Nothing ->
                    ( model, Command.none )

        VisualViewportResized _ ->
            ( model, Command.none )

        TextEditorMsg textEditorMsg ->
            updateLoggedIn
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
                    handleLocalChange
                        model.time
                        (Maybe.map Local_TextEditor localChange)
                        { loggedIn | textEditor = textEditor }
                        Command.none
                )
                model

        PressedLinkDiscordUser ->
            updateLoggedIn
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
            updateLoggedIn
                (\loggedIn ->
                    handleLocalChange
                        model.time
                        (Local_StartReloadingDiscordUser model.time discordUserId |> Just)
                        loggedIn
                        Command.none
                )
                model

        PressedUnlinkDiscordUser discordUserId ->
            updateLoggedIn
                (\loggedIn ->
                    handleLocalChange
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
                                    channel.members
                            )
                            (SeqDict.toList local.discordDmChannels)
                    of
                        Just ( channelId, _ ) ->
                            routePush
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

        PressedDiscordFriendLabel channelId ->
            case model.loginStatus of
                LoggedIn loggedIn ->
                    let
                        local : LocalState
                        local =
                            Local.model loggedIn.localState
                    in
                    case SeqDict.get channelId local.discordDmChannels of
                        Just channel ->
                            let
                                maybeCurrentDiscordUser : Maybe (Discord.Id.Id Discord.Id.UserId)
                                maybeCurrentDiscordUser =
                                    List.Extra.findMap
                                        (\( userId, _ ) ->
                                            if NonemptySet.member userId channel.members then
                                                Just userId

                                            else
                                                Nothing
                                        )
                                        (SeqDict.toList local.localUser.linkedDiscordUsers)
                            in
                            case maybeCurrentDiscordUser of
                                Just currentUserId ->
                                    routePush
                                        model
                                        (DiscordDmRoute
                                            { currentDiscordUserId = currentUserId
                                            , channelId = channelId
                                            , viewingMessage = Nothing
                                            , showMembersTab = HideMembersTab
                                            }
                                        )

                                Nothing ->
                                    ( model, Command.none )

                        Nothing ->
                            ( model, Command.none )

                NotLoggedIn _ ->
                    ( model, Command.none )

        PressedExportGuild guildId ->
            ( model, Lamdera.sendToBackend (ExportGuildRequest guildId) )

        PressedExportDiscordGuild guildId ->
            ( model, Lamdera.sendToBackend (ExportDiscordGuildRequest guildId) )

        PressedImportGuild ->
            ( model, Effect.File.Select.file [ "application/json" ] GuildImportFileSelected )

        GuildImportFileSelected file ->
            ( model
            , Task.perform GotGuildImportFileContent (File.toString file)
            )

        GotGuildImportFileContent content ->
            case Codec.decodeString GuildExport.backendGuildCodec content of
                Ok guild ->
                    ( model, Lamdera.sendToBackend (ImportGuildRequest guild) )

                Err _ ->
                    -- Could show an error message to the user
                    ( model, Command.none )

        PressedImportDiscordGuild ->
            ( model
            , Effect.File.Select.file [ "application/json" ] DiscordGuildImportFileSelected
            )

        DiscordGuildImportFileSelected file ->
            ( model
            , Task.perform GotDiscordGuildImportFileContent (File.toString file)
            )

        GotDiscordGuildImportFileContent content ->
            case Codec.decodeString GuildExport.discordExportCodec content of
                Ok guild ->
                    ( model, Lamdera.sendToBackend (ImportDiscordGuildRequest guild) )

                Err _ ->
                    -- Could show an error message to the user
                    ( model, Command.none )

        TypedDiscordLinkBookmarklet ->
            ( model, Command.none )


setShowMembers : ShowMembersTab -> LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg )
setShowMembers showMembers model =
    case model.route of
        GuildRoute guildId (ChannelRoute channelId threadRoute) ->
            case threadRoute of
                NoThreadWithFriends a _ ->
                    routePush
                        model
                        (GuildRoute guildId (ChannelRoute channelId (NoThreadWithFriends a showMembers)))

                ViewThreadWithFriends threadId a _ ->
                    routePush
                        model
                        (GuildRoute
                            guildId
                            (ChannelRoute channelId (ViewThreadWithFriends threadId a showMembers))
                        )

        DmRoute otherUserId threadRoute ->
            case threadRoute of
                NoThreadWithFriends a _ ->
                    routePush model (DmRoute otherUserId (NoThreadWithFriends a showMembers))

                ViewThreadWithFriends threadId a _ ->
                    routePush model (DmRoute otherUserId (ViewThreadWithFriends threadId a showMembers))

        _ ->
            ( model, Command.none )


viewImageInfo :
    ( AnyGuildOrDmId, ThreadRoute )
    -> Id FileId
    -> LoadedFrontend
    -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg )
viewImageInfo guildOrDmId fileId model =
    updateLoggedIn
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
    handleLocalChange
        model.time
        (case routeToGuildOrDmId model.route of
            Just ( guildOrDmId, threadRoute ) ->
                case guildOrDmIdToMessagesCount guildOrDmId threadRoute (Local.model loggedIn.localState) of
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
    updateLoggedIn
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
    updateLoggedIn
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
            , setFocus model Pages.Guild.channelTextInputId
            )
        )
        model


pressedEditMessage : AnyGuildOrDmId -> ThreadRouteWithMessage -> LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg )
pressedEditMessage guildOrDmId threadRoute model =
    updateLoggedIn
        (\loggedIn ->
            let
                local : LocalState
                local =
                    Local.model loggedIn.localState

                maybeContentAndFiles : Maybe ( String, SeqDict (Id FileId) FileData )
                maybeContentAndFiles =
                    case guildOrDmId of
                        GuildOrDmId guildOrDmId2 ->
                            case guildOrDmIdToMessage guildOrDmId2 threadRoute local of
                                Just ( message, _ ) ->
                                    ( RichText.toString (LocalState.allUsers local) message.content
                                    , message.attachedFiles
                                    )
                                        |> Just

                                Nothing ->
                                    Nothing

                        DiscordGuildOrDmId guildOrDmId2 ->
                            case discordGuildOrDmIdToMessage guildOrDmId2 threadRoute local of
                                Just ( message, _ ) ->
                                    ( RichText.toString (LocalState.allDiscordUsers2 local.localUser) message.content
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
            , setFocus model MessageMenu.editMessageTextInputId
            )
        )
        model


showReactionEmojiSelector : AnyGuildOrDmId -> ThreadRouteWithMessage -> LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg )
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
                    , case model.textInputFocus of
                        Just textInputId ->
                            Dom.blur textInputId |> Task.attempt (\_ -> RemoveFocus)

                        Nothing ->
                            Command.none
                    ]
                )

        DragStart _ _ ->
            ( model, Command.none )

        Dragging _ ->
            ( model, Command.none )


gotFiles : ( AnyGuildOrDmId, ThreadRoute ) -> Nonempty File -> LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg )
gotFiles guildOrDmId files model =
    updateLoggedIn
        (\loggedIn ->
            let
                local : LocalState
                local =
                    Local.model loggedIn.localState

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
                                    , FileStatus.uploadFile
                                        (GotFileHashName guildOrDmId id)
                                        local.localUser.session.sessionIdHash
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
                                    FileStatus.uploadFile
                                        (GotFileHashName guildOrDmId id)
                                        local.localUser.session.sessionIdHash
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
    ( AnyGuildOrDmId, ThreadRoute )
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
                        GuildOrDmId_Guild guildId channelId ->
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
                                                            (case threadRouteWithRepliedTo of
                                                                ViewThreadWithMaybeMessage threadId maybeReplyTo ->
                                                                    LocalState.createThreadMessageFrontend
                                                                        threadId
                                                                        (UserTextMessage
                                                                            { createdAt = createdAt
                                                                            , createdBy = localUser.session.userId
                                                                            , content = text
                                                                            , reactions = SeqDict.empty
                                                                            , editedAt = Nothing
                                                                            , repliedTo = maybeReplyTo
                                                                            , attachedFiles = attachedFiles
                                                                            }
                                                                        )
                                                                        channel

                                                                NoThreadWithMaybeMessage maybeReplyTo ->
                                                                    LocalState.createChannelMessageFrontend
                                                                        (UserTextMessage
                                                                            { createdAt = createdAt
                                                                            , createdBy = localUser.session.userId
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
                                                    { user
                                                        | lastViewed =
                                                            SeqDict.insert
                                                                (GuildOrDmId guildOrDmId)
                                                                (Array.length channel.messages |> Id.fromInt)
                                                                user.lastViewed
                                                    }
                                            }
                                    }

                                Nothing ->
                                    local

                        GuildOrDmId_Dm otherUserId ->
                            let
                                user =
                                    local.localUser.user

                                localUser =
                                    local.localUser

                                dmChannel : FrontendDmChannel
                                dmChannel =
                                    SeqDict.get otherUserId local.dmChannels
                                        |> Maybe.withDefault DmChannel.frontendInit

                                dmChannel2 : FrontendDmChannel
                                dmChannel2 =
                                    case threadRouteWithRepliedTo of
                                        ViewThreadWithMaybeMessage threadId maybeReplyTo ->
                                            LocalState.createThreadMessageFrontend
                                                threadId
                                                (UserTextMessage
                                                    { createdAt = createdAt
                                                    , createdBy = localUser.session.userId
                                                    , content = text
                                                    , reactions = SeqDict.empty
                                                    , editedAt = Nothing
                                                    , repliedTo = maybeReplyTo
                                                    , attachedFiles = attachedFiles
                                                    }
                                                )
                                                dmChannel

                                        NoThreadWithMaybeMessage maybeReplyTo ->
                                            LocalState.createChannelMessageFrontend
                                                (UserTextMessage
                                                    { createdAt = createdAt
                                                    , createdBy = localUser.session.userId
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
                                            { user
                                                | lastViewed =
                                                    SeqDict.insert
                                                        (GuildOrDmId guildOrDmId)
                                                        (DmChannel.latestMessageId dmChannel2)
                                                        user.lastViewed
                                            }
                                    }
                            }

                Local_Discord_SendMessage createdAt guildOrDmId text threadRouteWithRepliedTo attachedFiles ->
                    case guildOrDmId of
                        DiscordGuildOrDmId_Guild currentDiscordUserId guildId channelId ->
                            case LocalState.getDiscordGuildAndChannel guildId channelId local of
                                Just ( guild, channel ) ->
                                    let
                                        user =
                                            local.localUser.user

                                        localUser =
                                            local.localUser
                                    in
                                    { local
                                        | discordGuilds =
                                            SeqDict.insert
                                                guildId
                                                { guild
                                                    | channels =
                                                        SeqDict.insert
                                                            channelId
                                                            (case threadRouteWithRepliedTo of
                                                                ViewThreadWithMaybeMessage threadId maybeReplyTo ->
                                                                    LocalState.createThreadMessageFrontend
                                                                        threadId
                                                                        (UserTextMessage
                                                                            { createdAt = createdAt
                                                                            , createdBy = currentDiscordUserId
                                                                            , content = text
                                                                            , reactions = SeqDict.empty
                                                                            , editedAt = Nothing
                                                                            , repliedTo = maybeReplyTo
                                                                            , attachedFiles = attachedFiles
                                                                            }
                                                                        )
                                                                        channel

                                                                NoThreadWithMaybeMessage maybeReplyTo ->
                                                                    LocalState.createChannelMessageFrontend
                                                                        (UserTextMessage
                                                                            { createdAt = createdAt
                                                                            , createdBy = currentDiscordUserId
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
                                                local.discordGuilds
                                        , localUser =
                                            { localUser
                                                | user =
                                                    { user
                                                        | lastViewed =
                                                            SeqDict.insert
                                                                (DiscordGuildOrDmId guildOrDmId)
                                                                (Array.length channel.messages |> Id.fromInt)
                                                                user.lastViewed
                                                    }
                                            }
                                    }

                                Nothing ->
                                    local

                        DiscordGuildOrDmId_Dm { currentUserId, channelId } ->
                            case SeqDict.get channelId local.discordDmChannels of
                                Just dmChannel ->
                                    let
                                        user =
                                            local.localUser.user

                                        localUser =
                                            local.localUser
                                    in
                                    { local
                                        | discordDmChannels =
                                            SeqDict.insert
                                                channelId
                                                (case threadRouteWithRepliedTo of
                                                    ViewThreadWithMaybeMessage _ _ ->
                                                        -- Not supported for a Discord DM channel
                                                        dmChannel

                                                    NoThreadWithMaybeMessage maybeReplyTo ->
                                                        LocalState.createChannelMessageFrontend
                                                            (UserTextMessage
                                                                { createdAt = createdAt
                                                                , createdBy = currentUserId
                                                                , content = text
                                                                , reactions = SeqDict.empty
                                                                , editedAt = Nothing
                                                                , repliedTo = maybeReplyTo
                                                                , attachedFiles = attachedFiles
                                                                }
                                                            )
                                                            dmChannel
                                                )
                                                local.discordDmChannels
                                        , localUser =
                                            { localUser
                                                | user =
                                                    { user
                                                        | lastViewed =
                                                            SeqDict.insert
                                                                (DiscordGuildOrDmId guildOrDmId)
                                                                (Array.length dmChannel.messages |> Id.fromInt)
                                                                user.lastViewed
                                                    }
                                            }
                                    }

                                Nothing ->
                                    local

                Local_NewChannel time guildId channelName ->
                    { local
                        | guilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.createChannelFrontend time local.localUser.session.userId channelName)
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
                                        (LocalState.addInvite inviteLinkId2 local.localUser.session.userId time)
                                        local.guilds
                            }

                Local_NewGuild time guildName guildIdPlaceholder ->
                    case guildIdPlaceholder of
                        EmptyPlaceholder ->
                            local

                        FilledInByBackend guildId ->
                            let
                                guild =
                                    LocalState.createGuild time local.localUser.session.userId guildName
                            in
                            { local
                                | guilds =
                                    SeqDict.insert
                                        guildId
                                        (LocalState.guildToFrontend (Just ( LocalState.announcementChannel guild, NoThread )) guild)
                                        local.guilds
                            }

                Local_MemberTyping time guildOrDmId ->
                    memberTyping time local.localUser.session.userId guildOrDmId local

                Local_AddReactionEmoji guildOrDmId threadRoute emoji ->
                    addReactionEmoji local.localUser.session.userId guildOrDmId threadRoute emoji local

                Local_RemoveReactionEmoji guildOrDmId threadRoute emoji ->
                    removeReactionEmoji local.localUser.session.userId guildOrDmId threadRoute emoji local

                Local_SendEditMessage time guildOrDmId threadRoute newContent attachedFiles ->
                    editMessage time local.localUser.session.userId guildOrDmId newContent attachedFiles threadRoute local

                Local_Discord_SendEditGuildMessage time currentUserId guildId channelId threadRoute newContent ->
                    { local
                        | discordGuilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.updateChannel
                                    (\channel ->
                                        LocalState.editMessageFrontendHelper
                                            time
                                            currentUserId
                                            newContent
                                            DoNotChangeAttachments
                                            threadRoute
                                            channel
                                            |> Result.withDefault channel
                                    )
                                    channelId
                                )
                                local.discordGuilds
                    }

                Local_Discord_SendEditDmMessage time dmData messageId newContent ->
                    { local
                        | discordDmChannels =
                            SeqDict.updateIfExists
                                dmData.channelId
                                (\dmChannel ->
                                    LocalState.editMessageFrontendHelperNoThread
                                        time
                                        dmData.currentUserId
                                        newContent
                                        DoNotChangeAttachments
                                        messageId
                                        dmChannel
                                        |> Result.withDefault dmChannel
                                )
                                local.discordDmChannels
                    }

                Local_MemberEditTyping time guildOrDmId threadRoute ->
                    memberEditTyping time local.localUser.session.userId guildOrDmId threadRoute local

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

                Local_DeleteMessage guildOrDmId threadRoute ->
                    deleteMessage guildOrDmId threadRoute local

                Local_CurrentlyViewing viewing ->
                    let
                        localUser : LocalUser
                        localUser =
                            local.localUser

                        session : UserSession
                        session =
                            UserSession.setCurrentlyViewing
                                (UserSession.setViewingToCurrentlyViewing viewing)
                                localUser.session
                    in
                    case viewing of
                        ViewDm otherUserId messagesLoaded ->
                            { local
                                | localUser =
                                    { localUser
                                        | user = User.setLastDmViewed (DmChannelLastViewed otherUserId NoThread) localUser.user
                                        , session = session
                                    }
                                , dmChannels =
                                    SeqDict.updateIfExists
                                        otherUserId
                                        (loadMessages messagesLoaded)
                                        local.dmChannels
                            }

                        ViewDmThread otherUserId threadId messagesLoaded ->
                            { local
                                | localUser =
                                    { localUser
                                        | user =
                                            User.setLastDmViewed (DmChannelLastViewed otherUserId (ViewThread threadId)) localUser.user
                                        , session = session
                                    }
                                , dmChannels =
                                    SeqDict.updateIfExists
                                        otherUserId
                                        (\dmChannel ->
                                            { dmChannel
                                                | threads =
                                                    SeqDict.updateIfExists
                                                        threadId
                                                        (loadMessages messagesLoaded)
                                                        dmChannel.threads
                                            }
                                        )
                                        local.dmChannels
                            }

                        ViewDiscordDm _ channelId messagesLoaded ->
                            { local
                                | localUser =
                                    { localUser
                                        | user = User.setLastDmViewed (DiscordDmChannelLastViewed channelId) localUser.user
                                        , session = session
                                    }
                                , discordDmChannels =
                                    SeqDict.updateIfExists
                                        channelId
                                        (loadMessages messagesLoaded)
                                        local.discordDmChannels
                            }

                        ViewChannel guildId channelId messagesLoaded ->
                            { local
                                | localUser =
                                    { localUser
                                        | user = User.setLastChannelViewed guildId channelId NoThread localUser.user
                                        , session = session
                                    }
                                , guilds =
                                    SeqDict.updateIfExists
                                        guildId
                                        (LocalState.updateChannel (loadMessages messagesLoaded) channelId)
                                        local.guilds
                            }

                        ViewChannelThread guildId channelId threadId messagesLoaded ->
                            { local
                                | localUser =
                                    { localUser
                                        | user =
                                            User.setLastChannelViewed guildId channelId (ViewThread threadId) localUser.user
                                        , session = session
                                    }
                                , guilds =
                                    SeqDict.updateIfExists
                                        guildId
                                        (LocalState.updateChannel
                                            (\channel ->
                                                { channel
                                                    | threads =
                                                        SeqDict.updateIfExists
                                                            threadId
                                                            (loadMessages messagesLoaded)
                                                            channel.threads
                                                }
                                            )
                                            channelId
                                        )
                                        local.guilds
                            }

                        StopViewingChannel ->
                            { local | localUser = { localUser | session = session } }

                        ViewDiscordChannel guildId channelId _ messagesLoaded ->
                            { local
                                | localUser =
                                    { localUser
                                        | user =
                                            User.setLastDiscordChannelViewed
                                                guildId
                                                channelId
                                                NoThread
                                                localUser.user
                                        , session = session
                                    }
                                , discordGuilds =
                                    SeqDict.updateIfExists
                                        guildId
                                        (LocalState.updateChannel (loadMessages messagesLoaded) channelId)
                                        local.discordGuilds
                            }

                        ViewDiscordChannelThread guildId channelId _ threadId messagesLoaded ->
                            { local
                                | localUser =
                                    { localUser
                                        | user =
                                            User.setLastDiscordChannelViewed
                                                guildId
                                                channelId
                                                (ViewThread threadId)
                                                localUser.user
                                        , session = session
                                    }
                                , discordGuilds =
                                    SeqDict.updateIfExists
                                        guildId
                                        (LocalState.updateChannel
                                            (\channel ->
                                                { channel
                                                    | threads =
                                                        SeqDict.updateIfExists
                                                            threadId
                                                            (loadMessages messagesLoaded)
                                                            channel.threads
                                                }
                                            )
                                            channelId
                                        )
                                        local.discordGuilds
                            }

                Local_SetName name ->
                    let
                        localUser =
                            local.localUser
                    in
                    { local | localUser = { localUser | user = User.setName name localUser.user } }

                Local_LoadChannelMessages guildOrDmId previousOldestVisibleMessage messagesLoaded ->
                    case guildOrDmId of
                        GuildOrDmId_Guild guildId channelId ->
                            { local
                                | guilds =
                                    SeqDict.updateIfExists
                                        guildId
                                        (LocalState.updateChannel
                                            (loadOlderMessages previousOldestVisibleMessage messagesLoaded)
                                            channelId
                                        )
                                        local.guilds
                            }

                        GuildOrDmId_Dm otherUserId ->
                            { local
                                | dmChannels =
                                    SeqDict.updateIfExists
                                        otherUserId
                                        (loadOlderMessages previousOldestVisibleMessage messagesLoaded)
                                        local.dmChannels
                            }

                Local_LoadThreadMessages guildOrDmId threadId previousOldestVisibleMessage messagesLoaded ->
                    case guildOrDmId of
                        GuildOrDmId_Guild guildId channelId ->
                            { local
                                | guilds =
                                    SeqDict.updateIfExists
                                        guildId
                                        (LocalState.updateChannel
                                            (\channel ->
                                                { channel
                                                    | threads =
                                                        SeqDict.updateIfExists
                                                            threadId
                                                            (loadOlderMessages
                                                                previousOldestVisibleMessage
                                                                messagesLoaded
                                                            )
                                                            channel.threads
                                                }
                                            )
                                            channelId
                                        )
                                        local.guilds
                            }

                        GuildOrDmId_Dm otherUserId ->
                            { local
                                | dmChannels =
                                    SeqDict.updateIfExists
                                        otherUserId
                                        (\dmChannel ->
                                            { dmChannel
                                                | threads =
                                                    SeqDict.updateIfExists
                                                        threadId
                                                        (loadOlderMessages
                                                            previousOldestVisibleMessage
                                                            messagesLoaded
                                                        )
                                                        dmChannel.threads
                                            }
                                        )
                                        local.dmChannels
                            }

                Local_Discord_LoadChannelMessages guildOrDmId previousOldestVisibleMessage messagesLoaded ->
                    case guildOrDmId of
                        DiscordGuildOrDmId_Guild _ guildId channelId ->
                            { local
                                | discordGuilds =
                                    SeqDict.updateIfExists
                                        guildId
                                        (LocalState.updateChannel
                                            (loadOlderMessages previousOldestVisibleMessage messagesLoaded)
                                            channelId
                                        )
                                        local.discordGuilds
                            }

                        DiscordGuildOrDmId_Dm data ->
                            { local
                                | discordDmChannels =
                                    SeqDict.updateIfExists
                                        data.channelId
                                        (loadOlderMessages previousOldestVisibleMessage messagesLoaded)
                                        local.discordDmChannels
                            }

                Local_Discord_LoadThreadMessages guildOrDmId threadId previousOldestVisibleMessage messagesLoaded ->
                    case guildOrDmId of
                        DiscordGuildOrDmId_Guild _ guildId channelId ->
                            { local
                                | discordGuilds =
                                    SeqDict.updateIfExists
                                        guildId
                                        (LocalState.updateChannel
                                            (\channel ->
                                                { channel
                                                    | threads =
                                                        SeqDict.updateIfExists
                                                            threadId
                                                            (loadOlderMessages
                                                                previousOldestVisibleMessage
                                                                messagesLoaded
                                                            )
                                                            channel.threads
                                                }
                                            )
                                            channelId
                                        )
                                        local.discordGuilds
                            }

                        DiscordGuildOrDmId_Dm _ ->
                            local

                Local_SetGuildNotificationLevel guildId notificationLevel ->
                    let
                        localUser =
                            local.localUser
                    in
                    { local
                        | localUser =
                            { localUser
                                | user =
                                    User.setGuildNotificationLevel
                                        guildId
                                        notificationLevel
                                        localUser.user
                            }
                    }

                Local_SetNotificationMode notificationMode ->
                    let
                        localUser : LocalUser
                        localUser =
                            local.localUser

                        session : UserSession
                        session =
                            localUser.session
                    in
                    { local | localUser = { localUser | session = { session | notificationMode = notificationMode } } }

                Local_RegisterPushSubscription pushSubscription ->
                    let
                        localUser : LocalUser
                        localUser =
                            local.localUser

                        session : UserSession
                        session =
                            localUser.session
                    in
                    { local
                        | localUser =
                            { localUser | session = { session | pushSubscription = Subscribed pushSubscription } }
                    }

                Local_TextEditor localChange2 ->
                    { local
                        | textEditor =
                            TextEditor.localChangeUpdate local.localUser.session.userId localChange2 local.textEditor
                    }

                Local_UnlinkDiscordUser userId ->
                    unlinkDiscordUser userId local

                Local_StartReloadingDiscordUser time discordUserId ->
                    startReloadingDiscordUser time discordUserId local

        ServerChange serverChange ->
            case serverChange of
                Server_SendMessage userId createdAt guildOrDmId text threadRouteWithRepliedTo attachedFiles ->
                    case guildOrDmId of
                        GuildOrDmId_Guild guildId channelId ->
                            case LocalState.getGuildAndChannel guildId channelId local of
                                Just ( guild, channel ) ->
                                    let
                                        localUser : LocalUser
                                        localUser =
                                            local.localUser

                                        user : FrontendCurrentUser
                                        user =
                                            localUser.user

                                        isNotViewing : Bool
                                        isNotViewing =
                                            isViewing
                                                (GuildOrDmId guildOrDmId)
                                                (case threadRouteWithRepliedTo of
                                                    ViewThreadWithMaybeMessage threadId _ ->
                                                        ViewThread threadId

                                                    NoThreadWithMaybeMessage _ ->
                                                        NoThread
                                                )
                                                local
                                                |> not
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
                                                                    LocalState.createThreadMessageFrontend
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
                                                                    LocalState.createChannelMessageFrontend
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
                                                    if userId == localUser.session.userId then
                                                        { user
                                                            | lastViewed =
                                                                SeqDict.insert
                                                                    (GuildOrDmId guildOrDmId)
                                                                    (Array.length channel.messages |> Id.fromInt)
                                                                    user.lastViewed
                                                        }

                                                    else if
                                                        isNotViewing
                                                            && (LocalState.usersMentionedOrRepliedToFrontend
                                                                    threadRouteWithRepliedTo
                                                                    text
                                                                    channel
                                                                    |> SeqSet.member localUser.session.userId
                                                               )
                                                    then
                                                        User.addDirectMention
                                                            guildId
                                                            channelId
                                                            (case threadRouteWithRepliedTo of
                                                                ViewThreadWithMaybeMessage threadId _ ->
                                                                    ViewThread threadId

                                                                NoThreadWithMaybeMessage _ ->
                                                                    NoThread
                                                            )
                                                            user

                                                    else
                                                        user
                                            }
                                    }

                                Nothing ->
                                    local

                        GuildOrDmId_Dm otherUserId ->
                            let
                                localUser : LocalUser
                                localUser =
                                    local.localUser

                                user : FrontendCurrentUser
                                user =
                                    localUser.user

                                dmChannel : FrontendDmChannel
                                dmChannel =
                                    SeqDict.get otherUserId local.dmChannels |> Maybe.withDefault DmChannel.frontendInit

                                dmChannel2 : FrontendDmChannel
                                dmChannel2 =
                                    case threadRouteWithRepliedTo of
                                        ViewThreadWithMaybeMessage threadId maybeReplyTo ->
                                            LocalState.createThreadMessageFrontend
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
                                            LocalState.createChannelMessageFrontend
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
                                            if userId == localUser.session.userId then
                                                { user
                                                    | lastViewed =
                                                        SeqDict.insert
                                                            (GuildOrDmId guildOrDmId)
                                                            (DmChannel.latestMessageId dmChannel2)
                                                            user.lastViewed
                                                }

                                            else
                                                user
                                    }
                            }

                Server_Discord_SendMessage createdAt guildOrDmId text threadRouteWithRepliedTo attachedFiles ->
                    case guildOrDmId of
                        DiscordGuildOrDmId_Guild discordUserId guildId channelId ->
                            case LocalState.getDiscordGuildAndChannel guildId channelId local of
                                Just ( guild, channel ) ->
                                    let
                                        localUser : LocalUser
                                        localUser =
                                            local.localUser

                                        user : FrontendCurrentUser
                                        user =
                                            localUser.user

                                        isNotViewing : Bool
                                        isNotViewing =
                                            isViewing
                                                (DiscordGuildOrDmId guildOrDmId)
                                                (case threadRouteWithRepliedTo of
                                                    ViewThreadWithMaybeMessage threadId _ ->
                                                        ViewThread threadId

                                                    NoThreadWithMaybeMessage _ ->
                                                        NoThread
                                                )
                                                local
                                                |> not
                                    in
                                    { local
                                        | discordGuilds =
                                            SeqDict.insert
                                                guildId
                                                { guild
                                                    | channels =
                                                        SeqDict.insert
                                                            channelId
                                                            (case threadRouteWithRepliedTo of
                                                                ViewThreadWithMaybeMessage threadId maybeReplyTo ->
                                                                    LocalState.createThreadMessageFrontend
                                                                        threadId
                                                                        (UserTextMessage
                                                                            { createdAt = createdAt
                                                                            , createdBy = discordUserId
                                                                            , content = text
                                                                            , reactions = SeqDict.empty
                                                                            , editedAt = Nothing
                                                                            , repliedTo = maybeReplyTo
                                                                            , attachedFiles = attachedFiles
                                                                            }
                                                                        )
                                                                        channel

                                                                NoThreadWithMaybeMessage maybeReplyTo ->
                                                                    LocalState.createChannelMessageFrontend
                                                                        (UserTextMessage
                                                                            { createdAt = createdAt
                                                                            , createdBy = discordUserId
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
                                                local.discordGuilds
                                        , localUser =
                                            { localUser
                                                | user =
                                                    if SeqDict.member discordUserId localUser.linkedDiscordUsers then
                                                        { user
                                                            | lastViewed =
                                                                SeqDict.insert
                                                                    (DiscordGuildOrDmId guildOrDmId)
                                                                    (Array.length channel.messages |> Id.fromInt)
                                                                    user.lastViewed
                                                        }

                                                    else if
                                                        isNotViewing
                                                            && (LocalState.usersMentionedOrRepliedToFrontend
                                                                    threadRouteWithRepliedTo
                                                                    text
                                                                    channel
                                                                    |> SeqSet.member discordUserId
                                                               )
                                                    then
                                                        User.addDiscordDirectMention
                                                            guildId
                                                            channelId
                                                            (case threadRouteWithRepliedTo of
                                                                ViewThreadWithMaybeMessage threadId _ ->
                                                                    ViewThread threadId

                                                                NoThreadWithMaybeMessage _ ->
                                                                    NoThread
                                                            )
                                                            user

                                                    else
                                                        user
                                            }
                                    }

                                Nothing ->
                                    local

                        DiscordGuildOrDmId_Dm data ->
                            case SeqDict.get data.channelId local.discordDmChannels of
                                Just dmChannel ->
                                    let
                                        localUser : LocalUser
                                        localUser =
                                            local.localUser

                                        user : FrontendCurrentUser
                                        user =
                                            localUser.user

                                        dmChannel2 : DiscordFrontendDmChannel
                                        dmChannel2 =
                                            LocalState.createChannelMessageFrontend
                                                (UserTextMessage
                                                    { createdAt = createdAt
                                                    , createdBy = data.currentUserId
                                                    , content = text
                                                    , reactions = SeqDict.empty
                                                    , editedAt = Nothing
                                                    , repliedTo =
                                                        case threadRouteWithRepliedTo of
                                                            NoThreadWithMaybeMessage maybeReplyTo ->
                                                                maybeReplyTo

                                                            ViewThreadWithMaybeMessage _ _ ->
                                                                Nothing
                                                    , attachedFiles = attachedFiles
                                                    }
                                                )
                                                dmChannel
                                    in
                                    { local
                                        | discordDmChannels = SeqDict.insert data.channelId dmChannel2 local.discordDmChannels
                                        , localUser =
                                            { localUser
                                                | user =
                                                    if SeqDict.member data.currentUserId localUser.linkedDiscordUsers then
                                                        { user
                                                            | lastViewed =
                                                                SeqDict.insert
                                                                    (DiscordGuildOrDmId guildOrDmId)
                                                                    (DmChannel.latestMessageId dmChannel2)
                                                                    user.lastViewed
                                                        }

                                                    else
                                                        user
                                            }
                                    }

                                Nothing ->
                                    local

                Server_NewChannel time guildId channelName ->
                    { local
                        | guilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.createChannelFrontend time local.localUser.session.userId channelName)
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
                                (\guild -> LocalState.addMemberFrontend time userId guild |> Result.withDefault guild)
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
                    addReactionEmoji userId (GuildOrDmId guildOrDmId) messageIndex emoji local

                Server_RemoveReactionEmoji userId guildOrDmId messageIndex emoji ->
                    removeReactionEmoji userId (GuildOrDmId guildOrDmId) messageIndex emoji local

                Server_DiscordAddReactionGuildEmoji userId guildId channelId threadRoute emoji ->
                    { local
                        | discordGuilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.updateChannel
                                    (LocalState.addReactionEmojiFrontend emoji userId threadRoute)
                                    channelId
                                )
                                local.discordGuilds
                    }

                Server_DiscordAddReactionDmEmoji userId channelId messageId emoji ->
                    { local
                        | discordDmChannels =
                            SeqDict.updateIfExists
                                channelId
                                (LocalState.addReactionEmojiFrontendHelper emoji userId messageId)
                                local.discordDmChannels
                    }

                Server_DiscordRemoveReactionGuildEmoji userId guildId channelId threadRoute emoji ->
                    { local
                        | discordGuilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.updateChannel
                                    (LocalState.removeReactionEmojiFrontend emoji userId threadRoute)
                                    channelId
                                )
                                local.discordGuilds
                    }

                Server_DiscordRemoveReactionDmEmoji userId channelId messageId emoji ->
                    { local
                        | discordDmChannels =
                            SeqDict.updateIfExists
                                channelId
                                (LocalState.removeReactionEmojiFrontendHelper emoji userId messageId)
                                local.discordDmChannels
                    }

                Server_SendEditMessage time userId guildOrDmId messageIndex newContent attachedFiles ->
                    editMessage time userId guildOrDmId newContent attachedFiles messageIndex local

                Server_DiscordSendEditGuildMessage time editedBy guildId channelId threadRoute newContent ->
                    { local
                        | discordGuilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.updateChannel
                                    (\channel ->
                                        LocalState.editMessageFrontendHelper
                                            time
                                            editedBy
                                            newContent
                                            DoNotChangeAttachments
                                            threadRoute
                                            channel
                                            |> Result.withDefault channel
                                    )
                                    channelId
                                )
                                local.discordGuilds
                    }

                Server_DiscordSendEditDmMessage time data messageId newContent ->
                    { local
                        | discordDmChannels =
                            SeqDict.updateIfExists
                                data.channelId
                                (\dmChannel ->
                                    LocalState.editMessageFrontendHelperNoThread
                                        time
                                        data.currentUserId
                                        newContent
                                        DoNotChangeAttachments
                                        messageId
                                        dmChannel
                                        |> Result.withDefault dmChannel
                                )
                                local.discordDmChannels
                    }

                Server_MemberEditTyping time userId guildOrDmId messageIndex ->
                    memberEditTyping time userId guildOrDmId messageIndex local

                Server_DeleteMessage guildOrDmId messageIndex ->
                    deleteMessage guildOrDmId messageIndex local

                Server_DiscordDeleteGuildMessage guildId channelId threadRoute ->
                    { local
                        | discordGuilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.deleteMessageFrontend channelId threadRoute)
                                local.discordGuilds
                    }

                Server_DiscordDeleteDmMessage channelId messageId ->
                    { local
                        | discordDmChannels =
                            SeqDict.updateIfExists
                                channelId
                                (LocalState.deleteMessageFrontendNoThread messageId)
                                local.discordDmChannels
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

                Server_SetUserIcon userId icon ->
                    let
                        localUser : LocalUser
                        localUser =
                            local.localUser
                    in
                    { local
                        | localUser =
                            { localUser
                                | user =
                                    if localUser.session.userId == userId then
                                        User.setIcon icon localUser.user

                                    else
                                        localUser.user
                                , otherUsers =
                                    SeqDict.updateIfExists userId (User.setIcon icon) localUser.otherUsers
                            }
                    }

                Server_PushNotificationsReset publicVapidKey ->
                    { local | publicVapidKey = publicVapidKey }

                Server_SetGuildNotificationLevel guildId notificationLevel ->
                    let
                        localUser =
                            local.localUser
                    in
                    { local
                        | localUser =
                            { localUser | user = User.setGuildNotificationLevel guildId notificationLevel localUser.user }
                    }

                Server_PushNotificationFailed error ->
                    let
                        localUser : LocalUser
                        localUser =
                            local.localUser

                        session : UserSession
                        session =
                            localUser.session
                    in
                    { local
                        | localUser =
                            { localUser | session = { session | pushSubscription = SubscriptionError error } }
                    }

                Server_NewSession sessionId session ->
                    { local | otherSessions = SeqDict.insert sessionId session local.otherSessions }

                Server_LoggedOut sessionId ->
                    { local | otherSessions = SeqDict.remove sessionId local.otherSessions }

                Server_CurrentlyViewing sessionIdHash currentlyViewing ->
                    let
                        localUser : LocalUser
                        localUser =
                            local.localUser
                    in
                    if sessionIdHash == localUser.session.sessionIdHash then
                        { local
                            | localUser =
                                { localUser
                                    | session = UserSession.setCurrentlyViewing currentlyViewing localUser.session
                                }
                        }

                    else
                        { local
                            | otherSessions =
                                SeqDict.updateIfExists
                                    sessionIdHash
                                    (UserSession.setCurrentlyViewing currentlyViewing)
                                    local.otherSessions
                        }

                Server_TextEditor serverChange2 ->
                    { local | textEditor = TextEditor.changeUpdate serverChange2 local.textEditor }

                Server_LinkDiscordUser userId user ->
                    let
                        localUser =
                            local.localUser
                    in
                    { local
                        | localUser =
                            { localUser | linkedDiscordUsers = SeqDict.insert userId user localUser.linkedDiscordUsers }
                    }

                Server_UnlinkDiscordUser userId ->
                    unlinkDiscordUser userId local

                Server_DiscordChannelCreated guildId channelId channelName ->
                    { local
                        | discordGuilds =
                            SeqDict.updateIfExists
                                guildId
                                (\guild ->
                                    { guild
                                        | channels =
                                            SeqDict.update
                                                channelId
                                                (\maybeChannel ->
                                                    case maybeChannel of
                                                        Just _ ->
                                                            maybeChannel

                                                        Nothing ->
                                                            { name = channelName
                                                            , messages = Array.empty
                                                            , visibleMessages = VisibleMessages.empty
                                                            , lastTypedAt = SeqDict.empty
                                                            , threads = SeqDict.empty
                                                            }
                                                                |> Just
                                                )
                                                guild.channels
                                    }
                                )
                                local.discordGuilds
                    }

                Server_DiscordDmChannelCreated channelId members ->
                    { local
                        | discordDmChannels =
                            SeqDict.update
                                channelId
                                (\maybeChannel ->
                                    case maybeChannel of
                                        Just _ ->
                                            maybeChannel

                                        Nothing ->
                                            { messages = Array.empty
                                            , visibleMessages = VisibleMessages.empty
                                            , lastTypedAt = SeqDict.empty
                                            , members = members
                                            }
                                                |> Just
                                )
                                local.discordDmChannels
                    }

                Server_DiscordNeedsAuthAgain userId ->
                    let
                        localUser =
                            local.localUser
                    in
                    { local
                        | localUser =
                            { localUser
                                | linkedDiscordUsers =
                                    SeqDict.updateIfExists
                                        userId
                                        (\user -> { user | needsAuthAgain = True })
                                        localUser.linkedDiscordUsers
                            }
                    }

                Server_DiscordUserLoadingDataIsDone discordUserId result ->
                    let
                        localUser =
                            local.localUser
                    in
                    case result of
                        Ok data ->
                            { local
                                | localUser =
                                    { localUser
                                        | linkedDiscordUsers =
                                            SeqDict.updateIfExists
                                                discordUserId
                                                (\user ->
                                                    { user
                                                        | isLoadingData =
                                                            case result of
                                                                Ok _ ->
                                                                    DiscordUserLoadedSuccessfully

                                                                Err time ->
                                                                    DiscordUserLoadingFailed time
                                                    }
                                                )
                                                localUser.linkedDiscordUsers
                                        , otherDiscordUsers = SeqDict.foldl SeqDict.insert localUser.otherDiscordUsers data.discordUsers
                                    }
                                , discordGuilds = SeqDict.foldl SeqDict.insert local.discordGuilds data.discordGuilds
                                , discordDmChannels = SeqDict.foldl SeqDict.insert local.discordDmChannels data.discordDms
                            }

                        Err time ->
                            { local
                                | localUser =
                                    { localUser
                                        | linkedDiscordUsers =
                                            SeqDict.updateIfExists
                                                discordUserId
                                                (\user -> { user | isLoadingData = DiscordUserLoadingFailed time })
                                                localUser.linkedDiscordUsers
                                    }
                            }

                Server_StartReloadingDiscordUser time discordUserId ->
                    startReloadingDiscordUser time discordUserId local


startReloadingDiscordUser : Time.Posix -> Discord.Id.Id Discord.Id.UserId -> LocalState -> LocalState
startReloadingDiscordUser time discordUserId local =
    let
        localUser : LocalUser
        localUser =
            local.localUser
    in
    { local
        | localUser =
            { localUser
                | linkedDiscordUsers =
                    SeqDict.updateIfExists
                        discordUserId
                        (\user -> { user | isLoadingData = DiscordUserLoadingData time })
                        localUser.linkedDiscordUsers
            }
    }


unlinkDiscordUser : Discord.Id.Id Discord.Id.UserId -> LocalState -> LocalState
unlinkDiscordUser userId local =
    let
        localUser =
            local.localUser
    in
    { local
        | localUser =
            { localUser | linkedDiscordUsers = SeqDict.remove userId localUser.linkedDiscordUsers }
    }


memberTyping : Time.Posix -> Id UserId -> ( AnyGuildOrDmId, ThreadRoute ) -> LocalState -> LocalState
memberTyping time userId ( guildOrDmId, threadRoute ) local =
    case guildOrDmId of
        GuildOrDmId (GuildOrDmId_Guild guildId channelId) ->
            { local
                | guilds =
                    SeqDict.updateIfExists
                        guildId
                        (LocalState.updateChannel (LocalState.memberIsTyping userId time threadRoute) channelId)
                        local.guilds
            }

        GuildOrDmId (GuildOrDmId_Dm otherUserId) ->
            { local
                | dmChannels =
                    SeqDict.updateIfExists
                        otherUserId
                        (LocalState.memberIsTyping userId time threadRoute)
                        local.dmChannels
            }

        DiscordGuildOrDmId (DiscordGuildOrDmId_Guild currentDiscordUserId guildId channelId) ->
            { local
                | discordGuilds =
                    SeqDict.updateIfExists
                        guildId
                        (LocalState.updateChannel
                            (LocalState.memberIsTyping currentDiscordUserId time threadRoute)
                            channelId
                        )
                        local.discordGuilds
            }

        DiscordGuildOrDmId (DiscordGuildOrDmId_Dm { currentUserId, channelId }) ->
            { local
                | discordDmChannels =
                    SeqDict.updateIfExists
                        channelId
                        (LocalState.memberIsTypingHelper currentUserId time)
                        local.discordDmChannels
            }


addReactionEmoji : Id UserId -> AnyGuildOrDmId -> ThreadRouteWithMessage -> Emoji -> LocalState -> LocalState
addReactionEmoji userId guildOrDmId threadRoute emoji local =
    case guildOrDmId of
        GuildOrDmId (GuildOrDmId_Guild guildId channelId) ->
            { local
                | guilds =
                    SeqDict.updateIfExists
                        guildId
                        (LocalState.updateChannel
                            (LocalState.addReactionEmojiFrontend emoji userId threadRoute)
                            channelId
                        )
                        local.guilds
            }

        GuildOrDmId (GuildOrDmId_Dm otherUserId) ->
            { local
                | dmChannels =
                    SeqDict.updateIfExists
                        otherUserId
                        (LocalState.addReactionEmojiFrontend emoji userId threadRoute)
                        local.dmChannels
            }

        DiscordGuildOrDmId (DiscordGuildOrDmId_Guild currentDiscordUserId guildId channelId) ->
            { local
                | discordGuilds =
                    SeqDict.updateIfExists
                        guildId
                        (LocalState.updateChannel
                            (LocalState.addReactionEmojiFrontend emoji currentDiscordUserId threadRoute)
                            channelId
                        )
                        local.discordGuilds
            }

        DiscordGuildOrDmId (DiscordGuildOrDmId_Dm { currentUserId, channelId }) ->
            case threadRoute of
                ViewThreadWithMessage _ _ ->
                    local

                NoThreadWithMessage messageId ->
                    { local
                        | discordDmChannels =
                            SeqDict.updateIfExists
                                channelId
                                (LocalState.addReactionEmojiFrontendHelper emoji currentUserId messageId)
                                local.discordDmChannels
                    }


removeReactionEmoji :
    Id UserId
    -> AnyGuildOrDmId
    -> ThreadRouteWithMessage
    -> Emoji
    -> LocalState
    -> LocalState
removeReactionEmoji userId guildOrDmId threadRoute emoji local =
    case guildOrDmId of
        GuildOrDmId (GuildOrDmId_Guild guildId channelId) ->
            { local
                | guilds =
                    SeqDict.updateIfExists
                        guildId
                        (LocalState.updateChannel
                            (LocalState.removeReactionEmojiFrontend emoji userId threadRoute)
                            channelId
                        )
                        local.guilds
            }

        GuildOrDmId (GuildOrDmId_Dm otherUserId) ->
            { local
                | dmChannels =
                    SeqDict.updateIfExists
                        otherUserId
                        (LocalState.removeReactionEmojiFrontend emoji userId threadRoute)
                        local.dmChannels
            }

        DiscordGuildOrDmId (DiscordGuildOrDmId_Guild currentDiscordUserId guildId channelId) ->
            { local
                | discordGuilds =
                    SeqDict.updateIfExists
                        guildId
                        (LocalState.updateChannel
                            (LocalState.removeReactionEmojiFrontend emoji currentDiscordUserId threadRoute)
                            channelId
                        )
                        local.discordGuilds
            }

        DiscordGuildOrDmId (DiscordGuildOrDmId_Dm { currentUserId, channelId }) ->
            case threadRoute of
                ViewThreadWithMessage _ _ ->
                    local

                NoThreadWithMessage messageId ->
                    { local
                        | discordDmChannels =
                            SeqDict.updateIfExists
                                channelId
                                (LocalState.removeReactionEmojiFrontendHelper emoji currentUserId messageId)
                                local.discordDmChannels
                    }


memberEditTyping : Time.Posix -> Id UserId -> AnyGuildOrDmId -> ThreadRouteWithMessage -> LocalState -> LocalState
memberEditTyping time userId guildOrDmId threadRoute local =
    case guildOrDmId of
        GuildOrDmId (GuildOrDmId_Guild guildId channelId) ->
            { local
                | guilds =
                    SeqDict.updateIfExists
                        guildId
                        (\guild ->
                            LocalState.memberIsEditTypingFrontend userId time channelId threadRoute guild
                                |> Result.withDefault guild
                        )
                        local.guilds
            }

        GuildOrDmId (GuildOrDmId_Dm otherUserId) ->
            { local
                | dmChannels =
                    SeqDict.updateIfExists
                        otherUserId
                        (\dmChannel ->
                            LocalState.memberIsEditTypingFrontendHelper time userId threadRoute dmChannel
                                |> Result.withDefault dmChannel
                        )
                        local.dmChannels
            }

        DiscordGuildOrDmId (DiscordGuildOrDmId_Guild currentDiscordUserId guildId channelId) ->
            { local
                | discordGuilds =
                    SeqDict.updateIfExists
                        guildId
                        (\guild ->
                            LocalState.memberIsEditTypingFrontend currentDiscordUserId time channelId threadRoute guild
                                |> Result.withDefault guild
                        )
                        local.discordGuilds
            }

        DiscordGuildOrDmId (DiscordGuildOrDmId_Dm { currentUserId, channelId }) ->
            case threadRoute of
                ViewThreadWithMessage _ _ ->
                    local

                NoThreadWithMessage messageId ->
                    { local
                        | discordDmChannels =
                            SeqDict.updateIfExists
                                channelId
                                (\dmChannel ->
                                    LocalState.memberIsEditTypingFrontendHelperNoThread time currentUserId messageId dmChannel
                                        |> Result.withDefault dmChannel
                                )
                                local.discordDmChannels
                    }


editMessage :
    Time.Posix
    -> Id UserId
    -> GuildOrDmId
    -> Nonempty (RichText (Id UserId))
    -> SeqDict (Id FileId) FileData
    -> ThreadRouteWithMessage
    -> LocalState
    -> LocalState
editMessage time userId guildOrDmId newContent attachedFiles threadRoute local =
    case guildOrDmId of
        GuildOrDmId_Guild guildId channelId ->
            { local
                | guilds =
                    SeqDict.updateIfExists
                        guildId
                        (LocalState.updateChannel
                            (\channel ->
                                LocalState.editMessageFrontendHelper
                                    time
                                    userId
                                    newContent
                                    (ChangeAttachments attachedFiles)
                                    threadRoute
                                    channel
                                    |> Result.withDefault channel
                            )
                            channelId
                        )
                        local.guilds
            }

        GuildOrDmId_Dm otherUserId ->
            { local
                | dmChannels =
                    SeqDict.updateIfExists
                        otherUserId
                        (\dmChannel ->
                            LocalState.editMessageFrontendHelper
                                time
                                userId
                                newContent
                                (ChangeAttachments attachedFiles)
                                threadRoute
                                dmChannel
                                |> Result.withDefault dmChannel
                        )
                        local.dmChannels
            }


deleteMessage : AnyGuildOrDmId -> ThreadRouteWithMessage -> LocalState -> LocalState
deleteMessage guildOrDmId threadRoute local =
    case guildOrDmId of
        GuildOrDmId (GuildOrDmId_Guild guildId channelId) ->
            { local
                | guilds =
                    SeqDict.updateIfExists
                        guildId
                        (LocalState.deleteMessageFrontend channelId threadRoute)
                        local.guilds
            }

        GuildOrDmId (GuildOrDmId_Dm otherUserId) ->
            { local
                | dmChannels =
                    SeqDict.updateIfExists
                        otherUserId
                        (LocalState.deleteMessageFrontendHelper threadRoute)
                        local.dmChannels
            }

        DiscordGuildOrDmId (DiscordGuildOrDmId_Guild _ guildId channelId) ->
            { local
                | discordGuilds =
                    SeqDict.updateIfExists
                        guildId
                        (LocalState.deleteMessageFrontend channelId threadRoute)
                        local.discordGuilds
            }

        DiscordGuildOrDmId (DiscordGuildOrDmId_Dm data) ->
            case threadRoute of
                NoThreadWithMessage messageId ->
                    { local
                        | discordDmChannels =
                            SeqDict.updateIfExists
                                data.channelId
                                (LocalState.deleteMessageFrontendNoThread messageId)
                                local.discordDmChannels
                    }

                ViewThreadWithMessage _ _ ->
                    local


loadOlderMessages :
    Id messageId
    -> ToBeFilledInByBackend (SeqDict (Id messageId) (Message messageId userId))
    -> { a | messages : Array (MessageState messageId userId), visibleMessages : VisibleMessages messageId }
    -> { a | messages : Array (MessageState messageId userId), visibleMessages : VisibleMessages messageId }
loadOlderMessages previousOldestVisibleMessage messagesLoaded channel =
    case messagesLoaded of
        FilledInByBackend messagesLoaded2 ->
            { channel
                | messages =
                    SeqDict.foldl
                        (\messageId message messages ->
                            DmChannel.setArray messageId (MessageLoaded message) messages
                        )
                        channel.messages
                        messagesLoaded2
                , visibleMessages = VisibleMessages.loadOlder previousOldestVisibleMessage channel.visibleMessages
            }

        EmptyPlaceholder ->
            channel


loadMessages :
    ToBeFilledInByBackend (SeqDict (Id messageId) (Message messageId userId))
    -> { a | messages : Array (MessageState messageId userId), visibleMessages : VisibleMessages messageId }
    -> { a | messages : Array (MessageState messageId userId), visibleMessages : VisibleMessages messageId }
loadMessages messagesLoaded channel =
    case messagesLoaded of
        FilledInByBackend messagesLoaded2 ->
            { channel
                | messages =
                    SeqDict.foldl
                        (\messageId message messages ->
                            DmChannel.setArray
                                messageId
                                (MessageLoaded message)
                                messages
                        )
                        channel.messages
                        messagesLoaded2
                , visibleMessages = VisibleMessages.firstLoad channel
            }

        EmptyPlaceholder ->
            channel


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
                        (LocalChange (Local.model loggedIn.localState).localUser.session.userId localChange)
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
                                    loadedInitHelper model.time model.timezone model.userAgent loginData model

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
                            (Local.model loggedIn.localState).localUser.session.userId

                        change : LocalMsg
                        change =
                            LocalChange userId localChange

                        localState : Local LocalMsg LocalState
                        localState =
                            Local.updateFromBackend changeUpdate (Just changeId) change loggedIn.localState

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
                                    routeReplace
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
                                    case routeToGuildOrDmId model.route of
                                        Just ( GuildOrDmId (GuildOrDmId_Guild guildIdRoute channelIdRoute), NoThread ) ->
                                            if guildId == guildIdRoute && channelId == channelIdRoute then
                                                scrollToBottomOfChannel

                                            else
                                                Command.none

                                        _ ->
                                            Command.none

                                ViewDm otherUserId _ ->
                                    case routeToGuildOrDmId model.route of
                                        Just ( GuildOrDmId (GuildOrDmId_Dm otherUserIdRoute), NoThread ) ->
                                            if otherUserId == otherUserIdRoute then
                                                scrollToBottomOfChannel

                                            else
                                                Command.none

                                        _ ->
                                            Command.none

                                ViewChannelThread guildId channelId threadId _ ->
                                    case routeToGuildOrDmId model.route of
                                        Just ( GuildOrDmId (GuildOrDmId_Guild guildIdRoute channelIdRoute), ViewThread threadIdRoute ) ->
                                            if guildId == guildIdRoute && channelId == channelIdRoute && threadId == threadIdRoute then
                                                scrollToBottomOfChannel

                                            else
                                                Command.none

                                        _ ->
                                            Command.none

                                ViewDmThread otherUserId threadId _ ->
                                    case routeToGuildOrDmId model.route of
                                        Just ( GuildOrDmId (GuildOrDmId_Dm otherUserIdRoute), ViewThread threadIdRoute ) ->
                                            if otherUserId == otherUserIdRoute && threadId == threadIdRoute then
                                                scrollToBottomOfChannel

                                            else
                                                Command.none

                                        _ ->
                                            Command.none

                                StopViewingChannel ->
                                    Command.none

                                ViewDiscordChannel guildId channelId userId2 _ ->
                                    case routeToGuildOrDmId model.route of
                                        Just ( DiscordGuildOrDmId (DiscordGuildOrDmId_Guild currentDiscordUserId guildIdRoute channelIdRoute), NoThread ) ->
                                            if userId2 == currentDiscordUserId && guildId == guildIdRoute && channelId == channelIdRoute then
                                                scrollToBottomOfChannel

                                            else
                                                Command.none

                                        _ ->
                                            Command.none

                                ViewDiscordChannelThread guildId channelId userId2 threadId _ ->
                                    case routeToGuildOrDmId model.route of
                                        Just ( DiscordGuildOrDmId (DiscordGuildOrDmId_Guild currentDiscordUserId guildIdRoute channelIdRoute), ViewThread threadIdRoute ) ->
                                            if userId2 == currentDiscordUserId && guildId == guildIdRoute && channelId == channelIdRoute && threadId == threadIdRoute then
                                                scrollToBottomOfChannel

                                            else
                                                Command.none

                                        _ ->
                                            Command.none

                                ViewDiscordDm _ channelId _ ->
                                    case routeToGuildOrDmId model.route of
                                        Just ( DiscordGuildOrDmId (DiscordGuildOrDmId_Dm data), NoThread ) ->
                                            if channelId == data.channelId then
                                                scrollToBottomOfChannel

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
                        ServerChange (Server_TextEditor _) ->
                            case SeqDict.get local.localUser.session.userId local.textEditor.cursorPosition of
                                Just range ->
                                    Ports.setCursorPosition TextEditor.inputId range

                                Nothing ->
                                    Command.none

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
                                                    (NoThreadWithFriends Nothing HideMembersTab)
                                                )
                                            )

                                    else
                                        Command.none

                                _ ->
                                    Command.none

                        ServerChange (Server_SendMessage senderId _ guildOrDmId content maybeRepliedTo _) ->
                            case guildOrDmId of
                                GuildOrDmId_Guild guildId channelId ->
                                    case LocalState.getGuildAndChannel guildId channelId local of
                                        Just ( _, channel ) ->
                                            Command.batch
                                                [ playNotificationSound
                                                    senderId
                                                    guildOrDmId
                                                    maybeRepliedTo
                                                    channel
                                                    local
                                                    content
                                                    model
                                                , case loggedIn.channelScrollPosition of
                                                    ScrolledToBottom ->
                                                        if MyUi.isMobile model then
                                                            smoothScrollToBottomOfChannel

                                                        else
                                                            scrollToBottomOfChannel

                                                    ScrolledToMiddle ->
                                                        Command.none

                                                    ScrolledToTop ->
                                                        Command.none
                                                ]

                                        Nothing ->
                                            Command.none

                                GuildOrDmId_Dm _ ->
                                    Command.none

                        ServerChange (Server_Discord_SendMessage _ guildOrDmId content maybeRepliedTo _) ->
                            case guildOrDmId of
                                DiscordGuildOrDmId_Guild senderId guildId channelId ->
                                    case LocalState.getDiscordGuildAndChannel guildId channelId local of
                                        Just ( _, channel ) ->
                                            Command.batch
                                                [ playNotificationSoundForDiscordMessage
                                                    senderId
                                                    guildOrDmId
                                                    maybeRepliedTo
                                                    channel
                                                    local
                                                    content
                                                    model
                                                , case loggedIn.channelScrollPosition of
                                                    ScrolledToBottom ->
                                                        if MyUi.isMobile model then
                                                            smoothScrollToBottomOfChannel

                                                        else
                                                            scrollToBottomOfChannel

                                                    ScrolledToMiddle ->
                                                        Command.none

                                                    ScrolledToTop ->
                                                        Command.none
                                                ]

                                        Nothing ->
                                            Command.none

                                DiscordGuildOrDmId_Dm data ->
                                    case SeqDict.get data.channelId local.discordDmChannels of
                                        Just channel ->
                                            Command.batch
                                                [ playNotificationSoundForDiscordMessage
                                                    data.currentUserId
                                                    guildOrDmId
                                                    maybeRepliedTo
                                                    { messages = channel.messages, threads = SeqDict.empty }
                                                    local
                                                    content
                                                    model
                                                , case loggedIn.channelScrollPosition of
                                                    ScrolledToBottom ->
                                                        if MyUi.isMobile model then
                                                            smoothScrollToBottomOfChannel

                                                        else
                                                            scrollToBottomOfChannel

                                                    ScrolledToMiddle ->
                                                        Command.none

                                                    ScrolledToTop ->
                                                        Command.none
                                                ]

                                        Nothing ->
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
                    ( { loggedIn | isReloading = True }
                    , Lamdera.sendToBackend (ReloadDataRequest (routeToGuildOrDmId model.route))
                    )
                )
                model

        ReloadDataResponse reloadData ->
            case reloadData of
                Ok loginData ->
                    updateLoggedIn
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
                    logout model

        LinkDiscordResponse result ->
            updateLoggedIn
                (\loggedIn ->
                    case ( model.route, loggedIn.userOptions ) of
                        ( LinkDiscord _, Nothing ) ->
                            case result of
                                Ok () ->
                                    ( loggedIn, routeReplace model HomePageRoute )

                                Err _ ->
                                    ( loggedIn, routeReplace model (LinkDiscord (Err LinkDiscordServerError)) )

                        _ ->
                            ( loggedIn, Command.none )
                )
                model

        ProfilePictureEditorToFrontend imageEditorToFrontend ->
            updateLoggedIn
                (\loggedIn ->
                    case imageEditorToFrontend of
                        ImageEditor.ChangeUserAvatarResponse ->
                            ( { loggedIn | profilePictureEditor = ImageEditor.init }, Command.none )
                )
                model

        ExportGuildResponse guildId guild ->
            let
                jsonString : String
                jsonString =
                    Codec.encodeToString 2 GuildExport.backendGuildCodec guild

                filename : String
                filename =
                    "guild-" ++ Id.toString guildId ++ "-export.json"
            in
            ( model, Effect.File.Download.string filename "application/json" jsonString )

        ExportDiscordGuildResponse export ->
            let
                jsonString : String
                jsonString =
                    Codec.encodeToString 2 GuildExport.discordExportCodec export

                filename : String
                filename =
                    "discord-guild-" ++ Discord.Id.toString export.guildId ++ "-export.json"
            in
            ( model, Effect.File.Download.string filename "application/json" jsonString )

        ImportGuildResponse result ->
            case result of
                Ok _ ->
                    updateLoggedIn
                        (\loggedIn ->
                            ( { loggedIn | newGuildForm = Nothing }
                            , Lamdera.sendToBackend (ReloadDataRequest Nothing)
                            )
                        )
                        model

                Err _ ->
                    ( model, Command.none )

        ImportDiscordGuildResponse result ->
            case result of
                Ok () ->
                    updateLoggedIn
                        (\loggedIn ->
                            ( { loggedIn | newGuildForm = Nothing }
                            , Lamdera.sendToBackend (ReloadDataRequest Nothing)
                            )
                        )
                        model

                Err _ ->
                    -- Could show error message to user
                    ( model, Command.none )


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
    Dom.setViewportOf Pages.Guild.conversationContainerId 0 9999999 |> Task.attempt (\_ -> SetScrollToBottom)


smoothScrollToBottomOfChannel : Command FrontendOnly toMsg FrontendMsg
smoothScrollToBottomOfChannel =
    Dom.getViewportOf Pages.Guild.conversationContainerId
        |> Task.andThen
            (\{ scene, viewport } ->
                smoothScrollToBottomOfChannelHelper viewport.y (scene.height - viewport.height) 0
            )
        |> Task.attempt (\_ -> SetScrollToBottom)


smoothScrollDuration : number
smoothScrollDuration =
    20


smoothScrollToBottomOfChannelHelper : Float -> Float -> Int -> Task FrontendOnly Dom.Error ()
smoothScrollToBottomOfChannelHelper startY endY count =
    if count <= smoothScrollDuration then
        let
            t =
                toFloat count / smoothScrollDuration

            y =
                t * (endY - startY) + startY |> Debug.log "t"
        in
        Dom.setViewportOf Pages.Guild.conversationContainerId 0 y
            |> Task.andThen (\() -> smoothScrollToBottomOfChannelHelper startY endY (count + 1))

    else
        Task.succeed ()


isViewing : AnyGuildOrDmId -> ThreadRoute -> LocalState -> Bool
isViewing guildOrDmId threadRoute local =
    let
        a =
            ( guildOrDmId, threadRoute ) |> Just
    in
    (local.localUser.session.currentlyViewing == a)
        || List.any
            (\otherSession -> otherSession.currentlyViewing == a)
            (SeqDict.values local.otherSessions)


playNotificationSound :
    Id UserId
    -> GuildOrDmId
    -> ThreadRouteWithMaybeMessage
    -> FrontendChannel
    -> LocalState
    -> Nonempty (RichText (Id UserId))
    -> LoadedFrontend
    -> Command FrontendOnly toMsg msg
playNotificationSound senderId guildOrDmId threadRouteWithRepliedTo channel local content model =
    case local.localUser.session.notificationMode of
        NoNotifications ->
            Command.none

        NotifyWhenRunning ->
            let
                alwaysNotify : Bool
                alwaysNotify =
                    case guildOrDmId of
                        GuildOrDmId_Guild guildId _ ->
                            SeqSet.member guildId local.localUser.user.notifyOnAllMessages

                        GuildOrDmId_Dm _ ->
                            False

                isMentionedOrRepliedTo =
                    LocalState.usersMentionedOrRepliedToFrontend threadRouteWithRepliedTo content channel
                        |> SeqSet.member local.localUser.session.userId
            in
            if not model.pageHasFocus && (alwaysNotify || isMentionedOrRepliedTo) then
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

        PushNotifications ->
            Command.none


playNotificationSoundForDiscordMessage :
    Discord.Id.Id Discord.Id.UserId
    -> DiscordGuildOrDmId
    -> ThreadRouteWithMaybeMessage
    ->
        { a
            | messages : Array (MessageState ChannelMessageId (Discord.Id.Id Discord.Id.UserId))
            , threads : SeqDict (Id ChannelMessageId) (FrontendGenericThread (Discord.Id.Id Discord.Id.UserId))
        }
    -> LocalState
    -> Nonempty (RichText (Discord.Id.Id Discord.Id.UserId))
    -> LoadedFrontend
    -> Command FrontendOnly toMsg msg
playNotificationSoundForDiscordMessage senderId guildOrDmId threadRouteWithRepliedTo channel local content model =
    case local.localUser.session.notificationMode of
        NoNotifications ->
            Command.none

        NotifyWhenRunning ->
            let
                alwaysNotify : Bool
                alwaysNotify =
                    case guildOrDmId of
                        DiscordGuildOrDmId_Guild _ guildId _ ->
                            SeqSet.member guildId local.localUser.user.discordNotifyOnAllMessages

                        DiscordGuildOrDmId_Dm _ ->
                            False

                isMentionedOrRepliedTo : Bool
                isMentionedOrRepliedTo =
                    LocalState.usersMentionedOrRepliedToFrontend threadRouteWithRepliedTo content channel
                        |> SeqSet.intersect (SeqDict.keys local.localUser.linkedDiscordUsers |> SeqSet.fromList)
                        |> SeqSet.isEmpty
                        |> not

                allUsers =
                    LocalState.allDiscordUsers2 local.localUser
            in
            if not model.pageHasFocus && (alwaysNotify || isMentionedOrRepliedTo) then
                Command.batch
                    [ Ports.playSound "pop"
                    , Ports.setFavicon "/favicon-red.ico"
                    , case model.notificationPermission of
                        Ports.Granted ->
                            Ports.showNotification
                                (User.toString senderId allUsers)
                                (RichText.toString allUsers content)

                        _ ->
                            Command.none
                    ]

            else
                Command.none

        PushNotifications ->
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

                Pages.Admin.SetPrivateVapidKey _ ->
                    "Set private vapid key"

                Pages.Admin.SetPublicVapidKey _ ->
                    "Set public vapid key"

                Pages.Admin.SetSlackClientSecret _ ->
                    "Set slack client secret"

                Pages.Admin.SetOpenRouterKey _ ->
                    "Set OpenRouter key"

                Pages.Admin.DeleteDiscordDmChannel _ ->
                    "Deleted Discord DM channel"

                Pages.Admin.DeleteDiscordGuild _ ->
                    "Deleted Discord guild"

                Pages.Admin.DeleteGuild _ ->
                    "Deleted guild"

        Local_SendMessage _ _ _ _ _ ->
            "Sent a message"

        Local_Discord_SendMessage _ _ _ _ _ ->
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

        Local_Discord_SendEditGuildMessage _ _ _ _ _ _ ->
            "Edit message"

        Local_Discord_SendEditDmMessage _ _ _ _ ->
            "Edit message"

        Local_MemberEditTyping _ _ _ ->
            "Editing message"

        Local_SetLastViewed _ _ ->
            "Viewed channel"

        Local_DeleteMessage _ _ ->
            "Delete message"

        Local_CurrentlyViewing _ ->
            "Change view"

        Local_SetName _ ->
            "Set display name"

        Local_LoadChannelMessages _ _ _ ->
            "Load channel messages"

        Local_LoadThreadMessages _ _ _ _ ->
            "Load thread messages"

        Local_Discord_LoadChannelMessages _ _ _ ->
            "Load channel messages"

        Local_Discord_LoadThreadMessages _ _ _ _ ->
            "Load thread messages"

        Local_SetGuildNotificationLevel _ notificationLevel ->
            case notificationLevel of
                NotifyOnEveryMessage ->
                    "Enabled notifications for all messages"

                NotifyOnMention ->
                    "Disabled notifications for all messages"

        Local_SetNotificationMode _ ->
            "Set notification mode"

        Local_RegisterPushSubscription _ ->
            "Register push subscription"

        Local_TextEditor _ ->
            "Text editor change"

        Local_UnlinkDiscordUser _ ->
            "Unlink Discord user"

        Local_StartReloadingDiscordUser _ _ ->
            "Reload Discord user"


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

                    maybeMessageId : Maybe ( AnyGuildOrDmId, ThreadRoute )
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
            :: Ui.id "elm-ui-root-id"
            :: Ui.height Ui.fill
            :: Ui.behindContent (Ui.html MyUi.css)
            --:: Ui.behindContent
            --    (Ui.html
            --        (Html.node
            --            "style"
            --            []
            --            [ Html.text
            --                ("body { height: "
            --                    ++ String.fromInt (Coord.yRaw model.windowSize)
            --                    ++ "px !important; }"
            --                )
            --            ]
            --        )
            --    )
            :: Ui.behindContent
                (Ui.html
                    (Html.node
                        "style"
                        []
                        [ Html.text "body { height:100vh !important; }" ]
                    )
                )
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
                (case loading.loginStatus of
                    LoadingData ->
                        [ Html.div [ Html.Attributes.id "loading" ] []
                        , MyUi.css
                        ]

                    LoadSuccess _ ->
                        case loading.time of
                            Just _ ->
                                -- Make sure all of these error messages are slightly different so we know which branch was reached
                                [ Html.text "Something went isn't working."
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
                                    loaded.userAgent
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
                                        NoDmChannelSelected
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
                                                LoginForm.view loaded.userAgent loginForm2 (MyUi.isMobile loaded) loaded.pwaStatus |> Ui.map LoginFormMsg

                                            Nothing ->
                                                Ui.Lazy.lazy Pages.Home.view windowWidth
                                        )
                            )

                    AdminRoute _ ->
                        requiresLogin
                            (\loggedIn local ->
                                case ( loggedIn.admin, local.adminData ) of
                                    ( Just admin, IsAdmin adminData ) ->
                                        case NonemptyDict.get local.localUser.session.userId adminData.users of
                                            Just user ->
                                                Pages.Admin.view
                                                    local
                                                    adminData
                                                    user
                                                    admin
                                                    |> Ui.map AdminPageMsg

                                            Nothing ->
                                                Ui.text "User not found"

                                    _ ->
                                        errorPage loaded "Admin access required to view this page"
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

                    DiscordGuildRoute data ->
                        requiresLogin (Pages.Guild.discordGuildView loaded data)

                    DmRoute otherUserId thread ->
                        requiresLogin
                            (Pages.Guild.homePageLoggedInView (SelectedDmChannel otherUserId thread) loaded)

                    SlackOAuthRedirect result ->
                        layout
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
                                    (MyUi.isMobile loaded)
                                    local.localUser.session.userId
                                    local.textEditor
                                    |> Ui.map TextEditorMsg
                            )

                    DiscordDmRoute routeData ->
                        requiresLogin
                            (Pages.Guild.homePageLoggedInView (SelectedDiscordDmChannel routeData) loaded)

                    LinkDiscord result ->
                        layout
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
                                            loaded.userAgent
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


guildOrDmIdToMessage :
    GuildOrDmId
    -> ThreadRouteWithMessage
    -> LocalState
    -> Maybe ( UserTextMessageDataNoReply (Id UserId), ThreadRouteWithMaybeMessage )
guildOrDmIdToMessage guildOrDmId threadRoute local =
    let
        helper :
            { a | messages : Array (MessageState ChannelMessageId (Id UserId)), threads : SeqDict (Id ChannelMessageId) FrontendThread }
            -> Maybe ( UserTextMessageDataNoReply (Id UserId), ThreadRouteWithMaybeMessage )
        helper channel =
            case threadRoute of
                ViewThreadWithMessage threadId messageId ->
                    case
                        SeqDict.get threadId channel.threads
                            |> Maybe.withDefault Thread.frontendInit
                            |> .messages
                            |> DmChannel.getArray messageId
                    of
                        Just (MessageLoaded (UserTextMessage data)) ->
                            ( { createdAt = data.createdAt
                              , createdBy = data.createdBy
                              , content = data.content
                              , reactions = data.reactions
                              , editedAt = data.editedAt
                              , attachedFiles = data.attachedFiles
                              }
                            , ViewThreadWithMaybeMessage threadId data.repliedTo
                            )
                                |> Just

                        _ ->
                            Nothing

                NoThreadWithMessage messageId ->
                    case DmChannel.getArray messageId channel.messages of
                        Just (MessageLoaded (UserTextMessage data)) ->
                            ( { createdAt = data.createdAt
                              , createdBy = data.createdBy
                              , content = data.content
                              , reactions = data.reactions
                              , editedAt = data.editedAt
                              , attachedFiles = data.attachedFiles
                              }
                            , NoThreadWithMaybeMessage data.repliedTo
                            )
                                |> Just

                        _ ->
                            Nothing
    in
    case guildOrDmId of
        GuildOrDmId_Guild guildId channelId ->
            case LocalState.getGuildAndChannel guildId channelId local of
                Just ( _, channel ) ->
                    helper channel

                Nothing ->
                    Nothing

        GuildOrDmId_Dm otherUserId ->
            case SeqDict.get otherUserId local.dmChannels of
                Just dmChannel ->
                    helper dmChannel

                Nothing ->
                    Nothing


discordGuildOrDmIdToMessage :
    DiscordGuildOrDmId
    -> ThreadRouteWithMessage
    -> LocalState
    -> Maybe ( UserTextMessageDataNoReply (Discord.Id.Id Discord.Id.UserId), ThreadRouteWithMaybeMessage )
discordGuildOrDmIdToMessage guildOrDmId threadRoute local =
    let
        helper messageId channel =
            case DmChannel.getArray messageId channel.messages of
                Just (MessageLoaded (UserTextMessage data)) ->
                    ( { createdAt = data.createdAt
                      , createdBy = data.createdBy
                      , content = data.content
                      , reactions = data.reactions
                      , editedAt = data.editedAt
                      , attachedFiles = data.attachedFiles
                      }
                    , NoThreadWithMaybeMessage data.repliedTo
                    )
                        |> Just

                _ ->
                    Nothing
    in
    case guildOrDmId of
        DiscordGuildOrDmId_Guild _ guildId channelId ->
            case LocalState.getDiscordGuildAndChannel guildId channelId local of
                Just ( _, channel ) ->
                    case threadRoute of
                        ViewThreadWithMessage threadId messageId ->
                            case
                                SeqDict.get threadId channel.threads
                                    |> Maybe.withDefault Thread.discordFrontendInit
                                    |> .messages
                                    |> DmChannel.getArray messageId
                            of
                                Just (MessageLoaded (UserTextMessage data)) ->
                                    ( { createdAt = data.createdAt
                                      , createdBy = data.createdBy
                                      , content = data.content
                                      , reactions = data.reactions
                                      , editedAt = data.editedAt
                                      , attachedFiles = data.attachedFiles
                                      }
                                    , ViewThreadWithMaybeMessage threadId data.repliedTo
                                    )
                                        |> Just

                                _ ->
                                    Nothing

                        NoThreadWithMessage messageId ->
                            helper messageId channel

                Nothing ->
                    Nothing

        DiscordGuildOrDmId_Dm data ->
            case ( SeqDict.get data.channelId local.discordDmChannels, threadRoute ) of
                ( Just channel, NoThreadWithMessage messageId ) ->
                    helper messageId channel

                _ ->
                    Nothing


guildOrDmIdToMessages : ( GuildOrDmId, ThreadRoute ) -> LocalState -> Maybe (Array (MessageStateNoReply (Id UserId)))
guildOrDmIdToMessages ( guildOrDmId, threadRoute ) local =
    let
        helper channel =
            case threadRoute of
                ViewThread threadMessageIndex ->
                    SeqDict.get threadMessageIndex channel.threads
                        |> Maybe.withDefault Thread.frontendInit
                        |> .messages
                        |> Array.map
                            (\messageState ->
                                case messageState of
                                    MessageLoaded message ->
                                        (case message of
                                            UserTextMessage data ->
                                                { createdAt = data.createdAt
                                                , createdBy = data.createdBy
                                                , content = data.content
                                                , reactions = data.reactions
                                                , editedAt = data.editedAt
                                                , attachedFiles = data.attachedFiles
                                                }
                                                    |> UserTextMessage_NoReply

                                            UserJoinedMessage time userId reactions ->
                                                UserJoinedMessage_NoReply time userId reactions

                                            DeletedMessage time ->
                                                DeletedMessage_NoReply time
                                        )
                                            |> MessageLoaded_NoReply

                                    MessageUnloaded ->
                                        MessageUnloaded_NoReply
                            )
                        |> Just

                NoThread ->
                    Array.map
                        (\messageState ->
                            case messageState of
                                MessageLoaded message ->
                                    (case message of
                                        UserTextMessage data ->
                                            { createdAt = data.createdAt
                                            , createdBy = data.createdBy
                                            , content = data.content
                                            , reactions = data.reactions
                                            , editedAt = data.editedAt
                                            , attachedFiles = data.attachedFiles
                                            }
                                                |> UserTextMessage_NoReply

                                        UserJoinedMessage time userId reactions ->
                                            UserJoinedMessage_NoReply time userId reactions

                                        DeletedMessage time ->
                                            DeletedMessage_NoReply time
                                    )
                                        |> MessageLoaded_NoReply

                                MessageUnloaded ->
                                    MessageUnloaded_NoReply
                        )
                        channel.messages
                        |> Just
    in
    case guildOrDmId of
        GuildOrDmId_Guild guildId channelId ->
            case LocalState.getGuildAndChannel guildId channelId local of
                Just ( _, channel ) ->
                    helper channel

                Nothing ->
                    Nothing

        GuildOrDmId_Dm otherUserId ->
            case SeqDict.get otherUserId local.dmChannels of
                Just dmChannel ->
                    helper dmChannel

                Nothing ->
                    Nothing


discordGuildOrDmIdToMessages : DiscordGuildOrDmId -> ThreadRoute -> LocalState -> Maybe (Array (MessageStateNoReply (Discord.Id.Id Discord.Id.UserId)))
discordGuildOrDmIdToMessages guildOrDmId threadRoute local =
    let
        helper2 : { a | messages : Array (MessageState messageId userId) } -> Maybe (Array (MessageStateNoReply userId))
        helper2 channel =
            Array.map
                (\messageState ->
                    case messageState of
                        MessageLoaded message ->
                            (case message of
                                UserTextMessage data ->
                                    { createdAt = data.createdAt
                                    , createdBy = data.createdBy
                                    , content = data.content
                                    , reactions = data.reactions
                                    , editedAt = data.editedAt
                                    , attachedFiles = data.attachedFiles
                                    }
                                        |> UserTextMessage_NoReply

                                UserJoinedMessage time userId reactions ->
                                    UserJoinedMessage_NoReply time userId reactions

                                DeletedMessage time ->
                                    DeletedMessage_NoReply time
                            )
                                |> MessageLoaded_NoReply

                        MessageUnloaded ->
                            MessageUnloaded_NoReply
                )
                channel.messages
                |> Just
    in
    case guildOrDmId of
        DiscordGuildOrDmId_Guild _ guildId channelId ->
            case LocalState.getDiscordGuildAndChannel guildId channelId local of
                Just ( _, channel ) ->
                    case threadRoute of
                        ViewThread threadMessageIndex ->
                            case SeqDict.get threadMessageIndex channel.threads of
                                Just thread ->
                                    helper2 thread

                                Nothing ->
                                    Nothing

                        NoThread ->
                            helper2 channel

                Nothing ->
                    Nothing

        DiscordGuildOrDmId_Dm data ->
            case SeqDict.get data.channelId local.discordDmChannels of
                Just dmChannel ->
                    helper2 dmChannel

                Nothing ->
                    Nothing


guildOrDmIdToMessagesCount : AnyGuildOrDmId -> ThreadRoute -> LocalState -> Maybe Int
guildOrDmIdToMessagesCount guildOrDmId threadRoute local =
    case guildOrDmId of
        GuildOrDmId (GuildOrDmId_Guild guildId channelId) ->
            case LocalState.getGuildAndChannel guildId channelId local of
                Just ( _, channel ) ->
                    case threadRoute of
                        ViewThread threadMessageIndex ->
                            SeqDict.get threadMessageIndex channel.threads
                                |> Maybe.withDefault Thread.frontendInit
                                |> .messages
                                |> Array.length
                                |> Just

                        NoThread ->
                            Just (Array.length channel.messages)

                Nothing ->
                    Nothing

        GuildOrDmId (GuildOrDmId_Dm otherUserId) ->
            case SeqDict.get otherUserId local.dmChannels of
                Just dmChannel ->
                    case threadRoute of
                        ViewThread threadMessageIndex ->
                            SeqDict.get threadMessageIndex dmChannel.threads
                                |> Maybe.withDefault Thread.frontendInit
                                |> .messages
                                |> Array.length
                                |> Just

                        NoThread ->
                            Just (Array.length dmChannel.messages)

                Nothing ->
                    Nothing

        DiscordGuildOrDmId (DiscordGuildOrDmId_Guild _ guildId channelId) ->
            case LocalState.getDiscordGuildAndChannel guildId channelId local of
                Just ( _, channel ) ->
                    case threadRoute of
                        ViewThread threadMessageIndex ->
                            SeqDict.get threadMessageIndex channel.threads
                                |> Maybe.withDefault Thread.discordFrontendInit
                                |> .messages
                                |> Array.length
                                |> Just

                        NoThread ->
                            Just (Array.length channel.messages)

                Nothing ->
                    Nothing

        DiscordGuildOrDmId (DiscordGuildOrDmId_Dm data) ->
            case SeqDict.get data.channelId local.discordDmChannels of
                Just dmChannel ->
                    Just (Array.length dmChannel.messages)

                Nothing ->
                    Nothing


routeToGuildOrDmId : Route -> Maybe ( AnyGuildOrDmId, ThreadRoute )
routeToGuildOrDmId route =
    case route of
        GuildRoute guildId (ChannelRoute channelId threadRoute) ->
            ( GuildOrDmId_Guild guildId channelId |> GuildOrDmId
            , case threadRoute of
                ViewThreadWithFriends threadMessageId _ _ ->
                    ViewThread threadMessageId

                NoThreadWithFriends _ _ ->
                    NoThread
            )
                |> Just

        DmRoute otherUserId threadRoute ->
            ( GuildOrDmId_Dm otherUserId |> GuildOrDmId
            , case threadRoute of
                ViewThreadWithFriends threadMessageId _ _ ->
                    ViewThread threadMessageId

                NoThreadWithFriends _ _ ->
                    NoThread
            )
                |> Just

        DiscordGuildRoute data ->
            case data.channelRoute of
                DiscordChannel_ChannelRoute channelId threadRoute ->
                    ( DiscordGuildOrDmId_Guild data.currentDiscordUserId data.guildId channelId |> DiscordGuildOrDmId
                    , case threadRoute of
                        ViewThreadWithFriends threadMessageId _ _ ->
                            ViewThread threadMessageId

                        NoThreadWithFriends _ _ ->
                            NoThread
                    )
                        |> Just

                _ ->
                    Nothing

        DiscordDmRoute data ->
            ( DiscordGuildOrDmId_Dm { currentUserId = data.currentDiscordUserId, channelId = data.channelId }
                |> DiscordGuildOrDmId
            , NoThread
            )
                |> Just

        _ ->
            Nothing
