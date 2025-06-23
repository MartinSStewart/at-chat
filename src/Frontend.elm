module Frontend exposing (app, app_)

import Array
import Browser exposing (UrlRequest(..))
import Browser.Navigation
import ChannelName
import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Duration exposing (Duration, Seconds)
import Ease
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Browser.Events
import Effect.Browser.Navigation as BrowserNavigation exposing (Key)
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Lamdera as Lamdera
import Effect.Process as Process
import Effect.Subscription as Subscription exposing (Subscription)
import Effect.Task as Task exposing (Task)
import Effect.Time as Time
import EmailAddress
import Env
import GuildName
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Id exposing (ChannelId, GuildId, Id, UserId)
import Json.Decode exposing (Decoder)
import Lamdera as LamderaCore
import List.Extra
import List.Nonempty exposing (Nonempty)
import Local exposing (Local)
import LocalState exposing (AdminStatus(..), FrontendChannel, FrontendGuild, LocalState, LocalUser, Message(..))
import LoginForm
import MessageInput
import MessageMenu
import MyUi
import NonemptyDict exposing (NonemptyDict)
import NonemptySet
import Pages.Admin
import Pages.Guild
import Pages.Home
import Pages.UserOverview
import Pagination
import Point2d
import Ports
import Quantity exposing (Quantity, Rate, Unitless)
import RichText exposing (RichText)
import Route exposing (ChannelRoute(..), Route(..), UserOverviewRouteData(..))
import SeqDict
import String.Nonempty
import Touch exposing (Touch)
import Types exposing (AdminStatusLoginData(..), ChannelSidebarMode(..), Drag(..), EmojiSelector(..), FrontendModel(..), FrontendMsg(..), LoadStatus(..), LoadedFrontend, LoadingFrontend, LocalChange(..), LocalMsg(..), LoggedIn2, LoginData, LoginResult(..), LoginStatus(..), MessageHover(..), MessageHoverMobileMode(..), MessageId, MessageMenuExtraOptions, RevealedSpoilers, ServerChange(..), ToBackend(..), ToBeFilledInByBackend(..), ToFrontend(..))
import Ui exposing (Element)
import Ui.Anim
import Ui.Font
import Ui.Lazy
import Url exposing (Url)
import User exposing (BackendUser)
import Vector2d exposing (Vector2d)


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
        , Time.every Duration.second GotTime
        , Effect.Browser.Events.onKeyDown (Json.Decode.field "key" Json.Decode.string |> Json.Decode.map KeyDown)
        , Ports.checkNotificationPermissionResponse CheckedNotificationPermission
        , Ports.checkPwaStatusResponse CheckedPwaStatus
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
                                [ case loggedIn.sidebarMode of
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

                                    MessageHover messageId ->
                                        Subscription.none

                                    MessageMenu messageMenuExtraOptions ->
                                        case messageMenuExtraOptions.mobileMode of
                                            MessageMenuClosing _ ->
                                                Effect.Browser.Events.onAnimationFrameDelta MessageMenuAnimated

                                            MessageMenuOpening record ->
                                                Effect.Browser.Events.onAnimationFrameDelta MessageMenuAnimated

                                            MessageMenuDragging record ->
                                                Subscription.none

                                            MessageMenuFixed record ->
                                                Subscription.none
                                ]

                        NotLoggedIn _ ->
                            Subscription.none
                    ]
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
        , loginStatus = LoadingData
        , notificationPermission = Ports.Denied
        , pwaStatus = Ports.BrowserView
        }
    , Command.batch
        [ Task.perform GotTime Time.now
        , BrowserNavigation.replaceUrl key (Route.encode route)
        , Task.perform (\{ viewport } -> GotWindowSize (round viewport.width) (round viewport.height)) Dom.getViewport
        , Lamdera.sendToBackend CheckLoginRequest
        , Ports.loadSounds
        , Ports.checkNotificationPermission
        , Ports.checkPwaStatus
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
                    loadedInitHelper time loginData loading |> Tuple.mapFirst LoggedIn

                Err () ->
                    ( NotLoggedIn
                        { loginForm = Nothing
                        , useInviteAfterLoggedIn = Nothing
                        }
                    , Command.none
                    )

        model : LoadedFrontend
        model =
            { navigationKey = loading.navigationKey
            , route = loading.route
            , time = time
            , windowSize = loading.windowSize
            , loginStatus = loginStatus
            , elmUiState = Ui.Anim.init
            , lastCopied = Nothing
            , textInputFocus = Nothing
            , notificationPermission = loading.notificationPermission
            , pwaStatus = loading.pwaStatus
            , drag = NoDrag
            , scrolledToBottomOfChannel = True
            }

        ( model2, cmdA ) =
            routeRequest Nothing model.route model
    in
    ( model2
    , Command.batch [ cmdB, cmdA ]
    )


loadedInitHelper :
    Time.Posix
    -> LoginData
    ->
        { a
            | windowSize : Coord CssPixels
            , navigationKey : Key
            , route : Route
        }
    -> ( LoggedIn2, Command FrontendOnly ToBackend FrontendMsg )
loadedInitHelper time loginData loading =
    let
        localState : LocalState
        localState =
            { adminData =
                case loginData.adminData of
                    IsAdminLoginData adminData ->
                        IsAdmin
                            { users = adminData.users
                            , emailNotificationsEnabled = adminData.emailNotificationsEnabled
                            , twoFactorAuthentication = adminData.twoFactorAuthentication
                            }

                    IsNotAdminLoginData ->
                        IsNotAdmin
            , guilds = loginData.guilds
            , joinGuildError = Nothing
            , localUser =
                { userId = loginData.userId
                , user = loginData.user
                , otherUsers = loginData.otherUsers
                }
            }

        localStateContainer : Local LocalMsg LocalState
        localStateContainer =
            Local.init localState

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
            { localState = localStateContainer
            , admin = Maybe.map (\( a, _, _ ) -> a) maybeAdmin
            , userOverview =
                Pages.UserOverview.init
                    loginData.twoFactorAuthenticationEnabled
                    (Just localState.localUser.user)
                    |> SeqDict.singleton loginData.userId
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

                _ ->
                    ( model, Command.none )

        Loaded loaded ->
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

        UserOverviewRoute maybeUserId ->
            case maybeUserId of
                SpecificUserRoute _ ->
                    ( model2, Command.none )

                PersonalRoute ->
                    updateLoggedIn
                        (\loggedIn ->
                            ( loggedIn
                            , Local.model loggedIn.localState
                                |> .localUser
                                |> .userId
                                |> SpecificUserRoute
                                |> UserOverviewRoute
                                |> Route.encode
                                |> BrowserNavigation.replaceUrl model2.navigationKey
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
                ChannelRoute _ maybeMessageIndex ->
                    updateLoggedIn
                        (\loggedIn ->
                            ( if sameGuild || previousRoute == Nothing then
                                startOpeningChannelSidebar loggedIn

                              else
                                loggedIn
                            , Command.batch
                                [ setFocus model3 Pages.Guild.channelTextInputId
                                , case maybeMessageIndex of
                                    Just messageIndex ->
                                        smoothScroll (Pages.Guild.messageHtmlId messageIndex)
                                            |> Task.attempt (\_ -> ScrolledToMessage)

                                    Nothing ->
                                        if sameChannel then
                                            Command.none

                                        else
                                            Process.sleep Duration.millisecond
                                                |> Task.andThen (\() -> Dom.setViewportOf Pages.Guild.conversationContainerId 0 9999999)
                                                |> Task.attempt (\_ -> ScrolledToBottom)
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
                                            (GuildRoute guildId (ChannelRoute guild.announcementChannel Nothing))

                                    Nothing ->
                                        Command.none
                                ]
                            )


routeRequiresLogin : Route -> Bool
routeRequiresLogin route =
    case route of
        HomePageRoute ->
            False

        AdminRoute _ ->
            True

        UserOverviewRoute _ ->
            True

        GuildRoute _ _ ->
            True


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

                        notificationRequest : Command FrontendOnly toMsg msg
                        notificationRequest =
                            case model.notificationPermission of
                                Ports.NotAsked ->
                                    Ports.requestNotificationPermission

                                _ ->
                                    Command.none
                    in
                    ( model
                    , Command.batch
                        [ if model.route == route then
                            BrowserNavigation.replaceUrl model.navigationKey (Route.encode route)

                          else
                            BrowserNavigation.pushUrl model.navigationKey (Route.encode route)
                        , notificationRequest
                        ]
                    )

                External url ->
                    ( model, BrowserNavigation.load url )

        UrlChanged url ->
            let
                _ =
                    Debug.log "" url
            in
            routeRequest (Just model.route) (Route.decode url) model

        GotTime time ->
            ( { model | time = time }, Command.none )

        GotWindowSize width height ->
            ( { model | windowSize = Coord.xy width height }
            , Command.none
            )

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
                            let
                                local : LocalState
                                local =
                                    Local.model loggedIn.localState
                            in
                            handleLocalChange
                                model.time
                                (case model.route of
                                    GuildRoute guildId (ChannelRoute channelId _) ->
                                        case LocalState.getGuildAndChannel guildId channelId local of
                                            Just ( _, channel ) ->
                                                Local_SetLastViewed
                                                    guildId
                                                    channelId
                                                    (Array.length channel.messages - 1)
                                                    |> Just

                                            Nothing ->
                                                Nothing

                                    _ ->
                                        Nothing
                                )
                                loggedIn
                                Command.none
                        )
                        model

                ( model3, routeCmd ) =
                    routePush model2 route
            in
            ( model3, Command.batch [ cmd, routeCmd, notificationRequest ] )

        UserOverviewMsg userOverviewMsg ->
            updateLoggedIn
                (\loggedIn ->
                    case model.route of
                        UserOverviewRoute userOverviewData ->
                            let
                                userId : Id UserId
                                userId =
                                    case userOverviewData of
                                        PersonalRoute ->
                                            (Local.model loggedIn.localState).localUser.userId

                                        SpecificUserRoute userId2 ->
                                            userId2

                                ( userOverview2, cmd ) =
                                    Pages.UserOverview.update userOverviewMsg (getUserOverview userId loggedIn)
                            in
                            ( { loggedIn | userOverview = SeqDict.insert userId userOverview2 loggedIn.userOverview }
                            , Command.map UserOverviewToBackend UserOverviewMsg cmd
                            )

                        _ ->
                            ( loggedIn, Command.none )
                )
                model

        TypedMessage guildId channelId text ->
            updateLoggedIn
                (\loggedIn ->
                    let
                        ( pingUser, cmd ) =
                            MessageInput.multilineUpdate
                                (Pages.Guild.messageInputConfig guildId channelId)
                                Pages.Guild.channelTextInputId
                                text
                                (case SeqDict.get ( guildId, channelId ) loggedIn.drafts of
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
                            Local_MemberTyping model.time guildId channelId |> Just

                         else
                            Nothing
                        )
                        { loggedIn
                            | pingUser = pingUser
                            , drafts =
                                case String.Nonempty.fromString text of
                                    Just nonempty ->
                                        SeqDict.insert ( guildId, channelId ) nonempty loggedIn.drafts

                                    Nothing ->
                                        SeqDict.remove ( guildId, channelId ) loggedIn.drafts
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

        PressedSendMessage guildId channelId ->
            updateLoggedIn
                (\loggedIn ->
                    case SeqDict.get ( guildId, channelId ) loggedIn.drafts of
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
                                    guildId
                                    channelId
                                    (RichText.fromNonemptyString (LocalState.allUsers local) nonempty)
                                    (SeqDict.get ( guildId, channelId ) loggedIn.replyTo)
                                    |> Just
                                )
                                { loggedIn
                                    | drafts = SeqDict.remove ( guildId, channelId ) loggedIn.drafts
                                    , replyTo = SeqDict.remove ( guildId, channelId ) loggedIn.replyTo
                                }
                                scrollToBottomOfChannel

                        Nothing ->
                            ( loggedIn, Command.none )
                )
                model

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
                                        (GuildRoute guildId (ChannelRoute nextChannelId Nothing))
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

        MouseEnteredChannelName guildId channelId ->
            updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn | channelNameHover = Just ( guildId, channelId ) }, Command.none )
                )
                model

        MouseExitedChannelName guildId channelId ->
            updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn
                        | channelNameHover =
                            if loggedIn.channelNameHover == Just ( guildId, channelId ) then
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
                        (GuildRoute guildId (ChannelRoute channelId Nothing))

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
                                            (ChannelRoute guild.announcementChannel Nothing)
                                        )

                                Nothing ->
                                    ( model, Command.none )

                        ( loggedIn2, cmd2 ) =
                            handleLocalChange
                                model2.time
                                (Local_DeleteChannel guildId channelId |> Just)
                                { loggedIn
                                    | drafts = SeqDict.remove ( guildId, channelId ) loggedIn.drafts
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

        PressedPingUser guildId channelId index ->
            updateLoggedIn
                (\loggedIn ->
                    case SeqDict.get ( guildId, channelId ) loggedIn.drafts of
                        Just text ->
                            let
                                ( pingUser, text2, cmd ) =
                                    MessageInput.pressedPingUser
                                        SetFocus
                                        guildId
                                        Pages.Guild.channelTextInputId
                                        index
                                        loggedIn.pingUser
                                        (Local.model loggedIn.localState)
                                        text
                            in
                            ( { loggedIn
                                | pingUser = pingUser
                                , drafts = SeqDict.insert ( guildId, channelId ) text2 loggedIn.drafts
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

        PressedArrowInDropdown guildId index ->
            updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn
                        | pingUser =
                            MessageInput.pressedArrowInDropdown
                                guildId
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
                                            case model.route of
                                                GuildRoute guildId (ChannelRoute channelId _) ->
                                                    let
                                                        local =
                                                            Local.model loggedIn2.localState
                                                    in
                                                    handleLocalChange
                                                        model.time
                                                        (case SeqDict.get guildId local.guilds of
                                                            Just guild ->
                                                                case SeqDict.get channelId guild.channels of
                                                                    Just channel ->
                                                                        Local_SetLastViewed
                                                                            guildId
                                                                            channelId
                                                                            (Array.length channel.messages - 1)
                                                                            |> Just

                                                                    Nothing ->
                                                                        Nothing

                                                            Nothing ->
                                                                Nothing
                                                        )
                                                        (if SeqDict.member ( guildId, channelId ) loggedIn2.editMessage then
                                                            { loggedIn2
                                                                | editMessage =
                                                                    SeqDict.remove ( guildId, channelId ) loggedIn2.editMessage
                                                            }

                                                         else
                                                            { loggedIn2
                                                                | replyTo =
                                                                    SeqDict.remove ( guildId, channelId ) loggedIn2.replyTo
                                                            }
                                                        )
                                                        (setFocus model Pages.Guild.channelTextInputId)

                                                _ ->
                                                    ( loggedIn2, Command.none )

                                        _ ->
                                            ( { loggedIn2 | showEmojiSelector = EmojiSelectorHidden }, Command.none )
                        )
                        model

                _ ->
                    ( model, Command.none )

        MouseEnteredMessage messageIndex ->
            if MyUi.isMobile model then
                ( model, Command.none )

            else
                updateLoggedIn
                    (\loggedIn ->
                        case ( model.route, loggedIn.messageHover ) of
                            ( _, MessageMenu _ ) ->
                                ( loggedIn, Command.none )

                            ( GuildRoute guildId (ChannelRoute channelId _), _ ) ->
                                ( { loggedIn
                                    | messageHover =
                                        MessageHover
                                            { guildId = guildId
                                            , channelId = channelId
                                            , messageIndex = messageIndex
                                            }
                                  }
                                , Command.none
                                )

                            _ ->
                                ( loggedIn, Command.none )
                    )
                    model

        MouseExitedMessage messageIndex ->
            case model.route of
                GuildRoute guildId (ChannelRoute channelId _) ->
                    updateLoggedIn
                        (\loggedIn ->
                            ( { loggedIn
                                | messageHover =
                                    if
                                        MessageHover
                                            { guildId = guildId
                                            , channelId = channelId
                                            , messageIndex = messageIndex
                                            }
                                            == loggedIn.messageHover
                                    then
                                        NoMessageHover

                                    else
                                        loggedIn.messageHover
                              }
                            , Command.none
                            )
                        )
                        model

                _ ->
                    ( model, Command.none )

        AltPressedMessage messageIndex clickedAt ->
            updateLoggedIn
                (\loggedIn -> ( handleAltPressedMessage messageIndex clickedAt loggedIn model, Command.none ))
                model

        MessageMenu_PressedShowReactionEmojiSelector messageIndex _ ->
            case model.route of
                GuildRoute guildId (ChannelRoute channelId _) ->
                    updateLoggedIn
                        (\loggedIn ->
                            ( { loggedIn
                                | showEmojiSelector =
                                    EmojiSelectorForReaction
                                        { guildId = guildId, channelId = channelId, messageIndex = messageIndex }
                                , messageHover =
                                    case loggedIn.messageHover of
                                        NoMessageHover ->
                                            loggedIn.messageHover

                                        MessageHover _ ->
                                            loggedIn.messageHover

                                        MessageMenu a ->
                                            MessageHover a.messageId
                              }
                            , Command.none
                            )
                        )
                        model

                _ ->
                    ( model, Command.none )

        MessageMenu_PressedEditMessage messageIndex ->
            case model.route of
                GuildRoute guildId (ChannelRoute channelId _) ->
                    updateLoggedIn
                        (\loggedIn ->
                            let
                                local : LocalState
                                local =
                                    Local.model loggedIn.localState
                            in
                            ( case LocalState.getGuildAndChannel guildId channelId local of
                                Just ( _, channel ) ->
                                    case Array.get messageIndex channel.messages of
                                        Just (UserTextMessage message) ->
                                            { loggedIn
                                                | editMessage =
                                                    SeqDict.insert
                                                        ( guildId, channelId )
                                                        { messageIndex = messageIndex
                                                        , text =
                                                            RichText.toString (LocalState.allUsers local) message.content
                                                        }
                                                        loggedIn.editMessage
                                            }

                                        _ ->
                                            loggedIn

                                Nothing ->
                                    loggedIn
                            , setFocus model MessageMenu.editMessageTextInputId
                            )
                        )
                        model

                _ ->
                    ( model, Command.none )

        PressedEmojiSelectorEmoji emoji ->
            updateLoggedIn
                (\loggedIn ->
                    case loggedIn.showEmojiSelector of
                        EmojiSelectorHidden ->
                            ( loggedIn, Command.none )

                        EmojiSelectorForReaction messageId ->
                            handleLocalChange
                                model.time
                                (Local_AddReactionEmoji messageId emoji |> Just)
                                { loggedIn | showEmojiSelector = EmojiSelectorHidden }
                                Command.none

                        EmojiSelectorForMessage ->
                            ( loggedIn, Command.none )
                )
                model

        PressedReactionEmoji_Add messageIndex emoji ->
            case model.route of
                GuildRoute guildId (ChannelRoute channelId _) ->
                    updateLoggedIn
                        (\loggedIn ->
                            handleLocalChange
                                model.time
                                (Local_AddReactionEmoji
                                    { guildId = guildId, channelId = channelId, messageIndex = messageIndex }
                                    emoji
                                    |> Just
                                )
                                loggedIn
                                Command.none
                        )
                        model

                _ ->
                    ( model, Command.none )

        PressedReactionEmoji_Remove messageIndex emoji ->
            case model.route of
                GuildRoute guildId (ChannelRoute channelId _) ->
                    updateLoggedIn
                        (\loggedIn ->
                            handleLocalChange
                                model.time
                                (Local_RemoveReactionEmoji
                                    { guildId = guildId, channelId = channelId, messageIndex = messageIndex }
                                    emoji
                                    |> Just
                                )
                                loggedIn
                                Command.none
                        )
                        model

                _ ->
                    ( model, Command.none )

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

        TypedEditMessage guildId channelId text ->
            updateLoggedIn
                (\loggedIn ->
                    case SeqDict.get ( guildId, channelId ) loggedIn.editMessage of
                        Just edit ->
                            let
                                ( pingUser, cmd ) =
                                    MessageInput.multilineUpdate
                                        (MessageMenu.editMessageTextInputConfig guildId channelId)
                                        MessageMenu.editMessageTextInputId
                                        text
                                        edit.text
                                        loggedIn.pingUser
                            in
                            handleLocalChange
                                model.time
                                (if loggedIn.typingDebouncer then
                                    Local_MemberEditTyping
                                        model.time
                                        { guildId = guildId
                                        , channelId = channelId
                                        , messageIndex = edit.messageIndex
                                        }
                                        |> Just

                                 else
                                    Nothing
                                )
                                { loggedIn
                                    | pingUser = pingUser
                                    , editMessage =
                                        SeqDict.insert
                                            ( guildId, channelId )
                                            { edit | text = text }
                                            loggedIn.editMessage
                                    , typingDebouncer = False
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

        PressedSendEditMessage guildId channelId ->
            updateLoggedIn
                (\loggedIn ->
                    case SeqDict.get ( guildId, channelId ) loggedIn.editMessage of
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
                                    , LocalState.getGuildAndChannel guildId channelId local
                                    )
                                 of
                                    ( Just nonempty, Just ( _, channel ) ) ->
                                        case Array.get edit.messageIndex channel.messages of
                                            Just (UserTextMessage message) ->
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
                                                    Local_SendEditMessage
                                                        model.time
                                                        { guildId = guildId
                                                        , channelId = channelId
                                                        , messageIndex = edit.messageIndex
                                                        }
                                                        richText
                                                        |> Just

                                            _ ->
                                                Nothing

                                    _ ->
                                        Nothing
                                )
                                { loggedIn
                                    | editMessage =
                                        SeqDict.remove ( guildId, channelId ) loggedIn.editMessage
                                    , messageHover = NoMessageHover
                                }
                                Command.none

                        Nothing ->
                            ( loggedIn, Command.none )
                )
                model

        PressedArrowInDropdownForEditMessage guildId index ->
            updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn
                        | pingUser =
                            MessageInput.pressedArrowInDropdown
                                guildId
                                index
                                loggedIn.pingUser
                                (Local.model loggedIn.localState)
                      }
                    , Command.none
                    )
                )
                model

        PressedPingUserForEditMessage guildId channelId dropdownIndex ->
            updateLoggedIn
                (\loggedIn ->
                    case SeqDict.get ( guildId, channelId ) loggedIn.editMessage of
                        Just edit ->
                            case String.Nonempty.fromString edit.text of
                                Just nonempty ->
                                    let
                                        ( pingUser, text2, cmd ) =
                                            MessageInput.pressedPingUser
                                                SetFocus
                                                guildId
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
                                                ( guildId, channelId )
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

        PressedArrowUpInEmptyInput guildId channelId ->
            updateLoggedIn
                (\loggedIn ->
                    let
                        local : LocalState
                        local =
                            Local.model loggedIn.localState
                    in
                    case LocalState.getGuildAndChannel guildId channelId local of
                        Just ( _, channel ) ->
                            let
                                messageCount : Int
                                messageCount =
                                    Array.length channel.messages

                                mostRecentMessage : Maybe ( Int, Nonempty RichText )
                                mostRecentMessage =
                                    (if messageCount < 5 then
                                        Array.toList channel.messages |> List.indexedMap Tuple.pair

                                     else
                                        Array.slice (messageCount - 5) messageCount channel.messages
                                            |> Array.toList
                                            |> List.indexedMap
                                                (\index message ->
                                                    ( messageCount + index - 5, message )
                                                )
                                    )
                                        |> List.reverse
                                        |> List.Extra.findMap
                                            (\( index, message ) ->
                                                case message of
                                                    UserTextMessage data ->
                                                        if local.localUser.userId == data.createdBy then
                                                            Just ( index, data.content )

                                                        else
                                                            Nothing

                                                    UserJoinedMessage _ _ _ ->
                                                        Nothing

                                                    DeletedMessage ->
                                                        Nothing
                                            )
                            in
                            case mostRecentMessage of
                                Just ( index, message ) ->
                                    ( { loggedIn
                                        | editMessage =
                                            SeqDict.insert
                                                ( guildId, channelId )
                                                { messageIndex = index
                                                , text =
                                                    RichText.toString (LocalState.allUsers local) message
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
            case model.route of
                GuildRoute guildId (ChannelRoute channelId _) ->
                    updateLoggedIn
                        (\loggedIn ->
                            ( MessageMenu.close
                                model
                                { loggedIn
                                    | replyTo =
                                        SeqDict.insert ( guildId, channelId ) messageIndex loggedIn.replyTo
                                }
                            , setFocus model Pages.Guild.channelTextInputId
                            )
                        )
                        model

                _ ->
                    ( model, Command.none )

        PressedCloseReplyTo guildId channelId ->
            updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn
                        | replyTo = SeqDict.remove ( guildId, channelId ) loggedIn.replyTo
                      }
                    , setFocus model Pages.Guild.channelTextInputId
                    )
                )
                model

        PressedSpoiler messageIndex spoilerIndex ->
            case model.route of
                GuildRoute guildId (ChannelRoute channelId _) ->
                    updateLoggedIn
                        (\loggedIn ->
                            let
                                revealedSpoilers : RevealedSpoilers
                                revealedSpoilers =
                                    case loggedIn.revealedSpoilers of
                                        Just a ->
                                            if a.guildId == guildId && a.channelId == channelId then
                                                a

                                            else
                                                { guildId = guildId
                                                , channelId = channelId
                                                , messages = SeqDict.empty
                                                }

                                        Nothing ->
                                            { guildId = guildId
                                            , channelId = channelId
                                            , messages = SeqDict.empty
                                            }
                            in
                            ( { loggedIn
                                | revealedSpoilers =
                                    Just
                                        { revealedSpoilers
                                            | messages =
                                                SeqDict.update
                                                    messageIndex
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
                              }
                            , Command.none
                            )
                        )
                        model

                _ ->
                    ( model, Command.none )

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

        TouchStart time touches ->
            case model.drag of
                NoDrag ->
                    ( { model | drag = DragStart time touches }
                    , case NonemptyDict.toList touches of
                        [ ( _, single ) ] ->
                            let
                                htmlId : String
                                htmlId =
                                    Dom.idToString single.target
                            in
                            if String.startsWith Pages.Guild.messageHtmlIdPrefix htmlId then
                                case String.dropLeft (String.length Pages.Guild.messageHtmlIdPrefix) htmlId |> String.toInt of
                                    Just messageIndex ->
                                        Process.sleep (Duration.seconds 0.5)
                                            |> Task.perform (\() -> CheckMessageAltPress time messageIndex)

                                    Nothing ->
                                        Command.none

                            else
                                Command.none

                        _ ->
                            Command.none
                    )

                DragStart posix nonemptyDict ->
                    ( model, Command.none )

                Dragging record ->
                    ( model, Command.none )

        TouchMoved time newTouches ->
            case model.drag of
                Dragging dragging ->
                    updateLoggedIn
                        (\loggedIn ->
                            ( if dragging.horizontalStart then
                                let
                                    averageMove : { x : Float, y : Float }
                                    averageMove =
                                        Touch.averageTouchMove dragging.touches newTouches |> Vector2d.unwrap

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
                        { model | drag = Dragging { dragging | touches = newTouches } }

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
                        { model | drag = Dragging { horizontalStart = horizontalStart, touches = startTouches } }

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

        MessageMenu_PressedShowFullMenu messageIndex clickedAt ->
            case model.route of
                GuildRoute guildId (ChannelRoute channelId _) ->
                    updateLoggedIn
                        (\loggedIn ->
                            ( { loggedIn
                                | messageHover =
                                    MessageMenu
                                        { position =
                                            Coord.plus
                                                (Coord.xy (-MessageMenu.width - 8) -8)
                                                clickedAt
                                        , messageId =
                                            { guildId = guildId
                                            , channelId = channelId
                                            , messageIndex = messageIndex
                                            }
                                        , mobileMode = MessageMenuOpening Quantity.zero
                                        }
                              }
                            , Command.none
                            )
                        )
                        model

                _ ->
                    ( model, Command.none )

        MessageMenu_PressedDeleteMessage messageId ->
            updateLoggedIn
                (\loggedIn ->
                    handleLocalChange
                        model.time
                        (Just (Local_DeleteMessage messageId))
                        (MessageMenu.close model loggedIn)
                        Command.none
                )
                model

        PressedReplyLink messageIndex ->
            case model.route of
                GuildRoute guildId (ChannelRoute channelId _) ->
                    routePush model (GuildRoute guildId (ChannelRoute channelId (Just messageIndex)))

                _ ->
                    ( model, Command.none )

        ScrolledToMessage ->
            ( model, Command.none )

        MessageMenu_PressedClose ->
            updateLoggedIn (\loggedIn -> ( MessageMenu.close model loggedIn, Command.none )) model

        MessageMenu_PressedContainer ->
            ( model, Command.none )

        PressedCancelMessageEdit guildId channelId ->
            updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn | editMessage = SeqDict.remove ( guildId, channelId ) loggedIn.editMessage }
                    , Command.none
                    )
                )
                model

        PressedPingDropdownContainer ->
            ( model, setFocus model Pages.Guild.channelTextInputId )

        PressedEditMessagePingDropdownContainer ->
            ( model, setFocus model MessageMenu.editMessageTextInputId )

        CheckMessageAltPress startTime messageIndex ->
            case model.drag of
                DragStart dragStart _ ->
                    if startTime == dragStart then
                        updateLoggedIn
                            (\loggedIn ->
                                ( handleAltPressedMessage messageIndex Coord.origin loggedIn model
                                , Ports.hapticFeedback
                                )
                            )
                            model

                    else
                        ( model, Command.none )

                NoDrag ->
                    ( model, Command.none )

                Dragging record ->
                    ( model, Command.none )

        MessageMenuAnimated elapsedTime ->
            updateLoggedIn
                (\loggedIn ->
                    let
                        local : LocalState
                        local =
                            Local.model loggedIn.localState
                    in
                    ( { loggedIn
                        | messageHover =
                            case loggedIn.messageHover of
                                NoMessageHover ->
                                    loggedIn.messageHover

                                MessageHover messageId ->
                                    loggedIn.messageHover

                                MessageMenu messageMenu ->
                                    case messageMenu.mobileMode of
                                        MessageMenuOpening offset ->
                                            let
                                                offsetRaw : Float
                                                offsetRaw =
                                                    CssPixels.inCssPixels offset

                                                targetOffset : Int
                                                targetOffset =
                                                    MessageMenu.mobileViewHeight messageMenu local model
                                            in
                                            { messageMenu
                                                | mobileMode =
                                                    if offsetRaw < toFloat targetOffset then
                                                        Quantity.plus (CssPixels.cssPixels 5) offset
                                                            |> MessageMenuOpening

                                                    else
                                                        CssPixels.cssPixels (toFloat targetOffset)
                                                            |> MessageMenuFixed
                                            }
                                                |> MessageMenu

                                        MessageMenuClosing offset ->
                                            let
                                                offsetRaw : Float
                                                offsetRaw =
                                                    CssPixels.inCssPixels offset
                                            in
                                            if offsetRaw <= 0 then
                                                NoMessageHover

                                            else
                                                { messageMenu
                                                    | mobileMode =
                                                        Quantity.plus (CssPixels.cssPixels -5) offset
                                                            |> MessageMenuClosing
                                                }
                                                    |> MessageMenu

                                        MessageMenuDragging record ->
                                            MessageMenu messageMenu

                                        MessageMenuFixed quantity ->
                                            MessageMenu messageMenu
                      }
                    , Command.none
                    )
                )
                model


handleAltPressedMessage : Int -> Coord CssPixels -> LoggedIn2 -> LoadedFrontend -> LoggedIn2
handleAltPressedMessage messageIndex clickedAt loggedIn model =
    case model.route of
        GuildRoute guildId (ChannelRoute channelId _) ->
            { loggedIn
                | messageHover =
                    MessageMenu
                        { messageId =
                            { guildId = guildId
                            , channelId = channelId
                            , messageIndex = messageIndex
                            }
                        , position = clickedAt
                        , mobileMode = MessageMenuOpening Quantity.zero
                        }
            }

        _ ->
            loggedIn


handleTouchEnd : Time.Posix -> LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg )
handleTouchEnd time model =
    updateLoggedIn
        (\loggedIn ->
            ( case loggedIn.sidebarMode of
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
            , Command.none
            )
        )
        { model | drag = NoDrag }


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


getUserOverview : Id UserId -> LoggedIn2 -> Pages.UserOverview.Model
getUserOverview userId loggedIn =
    case SeqDict.get userId loggedIn.userOverview of
        Just userOverview ->
            userOverview

        Nothing ->
            let
                localState =
                    Local.model loggedIn.localState
            in
            Pages.UserOverview.init
                Nothing
                (if userId == localState.localUser.userId then
                    Just localState.localUser.user

                 else
                    Nothing
                )


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
                            { local
                                | adminData =
                                    Pages.Admin.updateAdmin changedBy adminChange adminData |> IsAdmin
                            }

                        IsNotAdmin ->
                            local

                Local_SendMessage createdAt guildId channelId text repliedTo ->
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
                                                    (LocalState.createMessage
                                                        (UserTextMessage
                                                            { createdAt = createdAt
                                                            , createdBy = local.localUser.userId
                                                            , content = text
                                                            , reactions = SeqDict.empty
                                                            , editedAt = Nothing
                                                            , repliedTo = repliedTo
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
                                                        ( guildId, channelId )
                                                        (Array.length channel.messages)
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

                Local_MemberTyping time guildId channelId ->
                    { local
                        | guilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.memberIsTyping local.localUser.userId time channelId)
                                local.guilds
                    }

                Local_AddReactionEmoji messageId emoji ->
                    { local
                        | guilds =
                            SeqDict.updateIfExists
                                messageId.guildId
                                (LocalState.addReactionEmoji
                                    emoji
                                    local.localUser.userId
                                    messageId.channelId
                                    messageId.messageIndex
                                )
                                local.guilds
                    }

                Local_RemoveReactionEmoji messageId emoji ->
                    { local
                        | guilds =
                            SeqDict.updateIfExists
                                messageId.guildId
                                (LocalState.removeReactionEmoji
                                    emoji
                                    local.localUser.userId
                                    messageId.channelId
                                    messageId.messageIndex
                                )
                                local.guilds
                    }

                Local_SendEditMessage time messageId newContent ->
                    { local
                        | guilds =
                            SeqDict.updateIfExists
                                messageId.guildId
                                (\guild ->
                                    LocalState.editMessage
                                        local.localUser.userId
                                        time
                                        newContent
                                        messageId.channelId
                                        messageId.messageIndex
                                        guild
                                        |> Result.withDefault guild
                                )
                                local.guilds
                    }

                Local_MemberEditTyping time messageId ->
                    { local
                        | guilds =
                            SeqDict.updateIfExists
                                messageId.guildId
                                (\guild ->
                                    LocalState.memberIsEditTyping
                                        local.localUser.userId
                                        time
                                        messageId.channelId
                                        messageId.messageIndex
                                        guild
                                        |> Result.withDefault guild
                                )
                                local.guilds
                    }

                Local_SetLastViewed guildId channelId messageIndex ->
                    let
                        user =
                            local.localUser.user

                        localUser =
                            local.localUser
                    in
                    { local
                        | localUser =
                            { localUser
                                | user =
                                    { user
                                        | lastViewed =
                                            SeqDict.insert ( guildId, channelId ) messageIndex user.lastViewed
                                    }
                            }
                    }

                Local_DeleteMessage messageId ->
                    case SeqDict.get messageId.guildId local.guilds of
                        Just guild ->
                            case
                                LocalState.deleteMessage
                                    local.localUser.userId
                                    messageId.channelId
                                    messageId.messageIndex
                                    guild
                            of
                                Ok guild2 ->
                                    { local
                                        | guilds =
                                            SeqDict.insert messageId.guildId guild2 local.guilds
                                    }

                                Err () ->
                                    local

                        Nothing ->
                            local

        ServerChange serverChange ->
            case serverChange of
                Server_SendMessage userId createdAt guildId channelId text repliedTo ->
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
                                                    (LocalState.createMessage
                                                        (UserTextMessage
                                                            { createdAt = createdAt
                                                            , createdBy = userId
                                                            , content = text
                                                            , reactions = SeqDict.empty
                                                            , editedAt = Nothing
                                                            , repliedTo = repliedTo
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
                                                            ( guildId, channelId )
                                                            (Array.length channel.messages)
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

                Server_MemberTyping time userId guildId channelId ->
                    { local
                        | guilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.memberIsTyping userId time channelId)
                                local.guilds
                    }

                Server_AddReactionEmoji userId messageId emoji ->
                    { local
                        | guilds =
                            SeqDict.updateIfExists
                                messageId.guildId
                                (LocalState.addReactionEmoji emoji userId messageId.channelId messageId.messageIndex)
                                local.guilds
                    }

                Server_RemoveReactionEmoji userId messageId emoji ->
                    { local
                        | guilds =
                            SeqDict.updateIfExists
                                messageId.guildId
                                (LocalState.removeReactionEmoji
                                    emoji
                                    userId
                                    messageId.channelId
                                    messageId.messageIndex
                                )
                                local.guilds
                    }

                Server_SendEditMessage time userId messageId newContent ->
                    { local
                        | guilds =
                            SeqDict.updateIfExists
                                messageId.guildId
                                (\guild ->
                                    LocalState.editMessage
                                        userId
                                        time
                                        newContent
                                        messageId.channelId
                                        messageId.messageIndex
                                        guild
                                        |> Result.withDefault guild
                                )
                                local.guilds
                    }

                Server_MemberEditTyping time userId messageId ->
                    { local
                        | guilds =
                            SeqDict.updateIfExists
                                messageId.guildId
                                (\guild ->
                                    LocalState.memberIsEditTyping
                                        userId
                                        time
                                        messageId.channelId
                                        messageId.messageIndex
                                        guild
                                        |> Result.withDefault guild
                                )
                                local.guilds
                    }

                Server_DeleteMessage userId messageId ->
                    case SeqDict.get messageId.guildId local.guilds of
                        Just guild ->
                            case
                                LocalState.deleteMessage
                                    userId
                                    messageId.channelId
                                    messageId.messageIndex
                                    guild
                            of
                                Ok guild2 ->
                                    { local
                                        | guilds =
                                            SeqDict.insert messageId.guildId guild2 local.guilds
                                    }

                                Err () ->
                                    local

                        Nothing ->
                            local


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
                                    loadedInitHelper model.time loginData model

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
                                            (ChannelRoute guild.announcementChannel Nothing)
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
                                                (ChannelRoute guild.announcementChannel Nothing)
                                            )

                                    else
                                        Command.none

                                _ ->
                                    Command.none

                        ServerChange (Server_SendMessage senderId _ guildId channelId content maybeRepliedTo) ->
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

                        _ ->
                            Command.none
                    )
                )
                model

        UserOverviewToFrontend toFrontend2 ->
            updateLoggedIn
                (\loggedIn ->
                    case model.route of
                        UserOverviewRoute userOverviewData ->
                            let
                                userId : Id UserId
                                userId =
                                    case userOverviewData of
                                        PersonalRoute ->
                                            (Local.model loggedIn.localState).localUser.userId

                                        SpecificUserRoute userId2 ->
                                            userId2

                                userOverview2 : Pages.UserOverview.Model
                                userOverview2 =
                                    Pages.UserOverview.updateFromBackend
                                        toFrontend2
                                        (getUserOverview userId loggedIn)
                            in
                            ( { loggedIn
                                | userOverview =
                                    SeqDict.insert userId userOverview2 loggedIn.userOverview
                              }
                            , Command.none
                            )

                        _ ->
                            ( loggedIn, Command.none )
                )
                model


scrollToBottomOfChannel : Command FrontendOnly toMsg FrontendMsg
scrollToBottomOfChannel =
    Dom.setViewportOf Pages.Guild.conversationContainerId 0 9999 |> Task.attempt (\_ -> ScrolledToBottom)


playNotificationSound :
    Id UserId
    -> Maybe Int
    -> FrontendChannel
    -> LocalState
    -> Nonempty RichText
    -> LoadedFrontend
    -> Command FrontendOnly toMsg msg
playNotificationSound senderId maybeRepliedTo channel local content model =
    if
        (senderId /= local.localUser.userId)
            && ((Pages.Guild.repliedToUserId maybeRepliedTo channel == Just local.localUser.userId)
                    || RichText.mentionsUser local.localUser.userId content
               )
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

        Local_MemberTyping _ _ _ ->
            "Is typing notification"

        Local_AddReactionEmoji _ _ ->
            "Added reaction emoji"

        Local_RemoveReactionEmoji _ _ ->
            "Removed reaction emoji"

        Local_SendEditMessage _ _ _ ->
            "Edit message"

        Local_MemberEditTyping _ _ ->
            "Editing message"

        Local_SetLastViewed _ _ _ ->
            "Viewed channel"

        Local_DeleteMessage _ ->
            "Delete message"


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
                , case model.route of
                    GuildRoute guildId (ChannelRoute channelId _) ->
                        case loggedIn.pingUser of
                            Just pingUser ->
                                MessageInput.pingDropdownView
                                    (case pingUser.target of
                                        MessageInput.NewMessage ->
                                            Pages.Guild.messageInputConfig guildId channelId

                                        MessageInput.EditMessage ->
                                            MessageMenu.editMessageTextInputConfig guildId channelId
                                    )
                                    guildId
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

                    MessageHover _ ->
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
                    [ Html.Events.on "touchstart" (Touch.touchEventDecoder TouchStart) |> Ui.htmlAttribute
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
                    , Ui.htmlAttribute (Html.Attributes.style "user-select" "none")
                    , Ui.htmlAttribute (Html.Attributes.style "-webkit-user-select" "none")
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

                    requiresLogin : (LoggedIn2 -> LocalState -> Element FrontendMsg) -> Html FrontendMsg
                    requiresLogin page =
                        case loaded.loginStatus of
                            LoggedIn loggedIn ->
                                layout
                                    loaded
                                    []
                                    (page loggedIn (Local.model loggedIn.localState))

                            NotLoggedIn { loginForm } ->
                                LoginForm.view
                                    (Maybe.withDefault LoginForm.init loginForm)
                                    (MyUi.isMobile loaded)
                                    loaded.pwaStatus
                                    |> Ui.map LoginFormMsg
                                    |> layout loaded
                                        [ Ui.background MyUi.background3
                                        , Ui.inFront (Pages.Home.header loaded.loginStatus)
                                        ]
                in
                case loaded.route of
                    HomePageRoute ->
                        layout
                            loaded
                            [ Ui.background MyUi.background3 ]
                            (case loaded.loginStatus of
                                LoggedIn loggedIn ->
                                    Pages.Guild.homePageLoggedInView loaded loggedIn (Local.model loggedIn.localState)

                                NotLoggedIn { loginForm } ->
                                    Ui.el
                                        [ Ui.inFront (Pages.Home.header loaded.loginStatus)
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

                    UserOverviewRoute userOverviewData ->
                        requiresLogin
                            (\loggedIn local ->
                                let
                                    userId : Id UserId
                                    userId =
                                        case userOverviewData of
                                            PersonalRoute ->
                                                local.localUser.userId

                                            SpecificUserRoute userId2 ->
                                                userId2
                                in
                                Pages.UserOverview.view
                                    loaded
                                    userId
                                    local
                                    (getUserOverview userId loggedIn)
                                    |> Ui.map UserOverviewMsg
                            )

                    GuildRoute guildId maybeChannelId ->
                        requiresLogin (Pages.Guild.guildView loaded guildId maybeChannelId)
        ]
    }
