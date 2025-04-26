module Frontend exposing (app, app_)

import Array
import Browser exposing (UrlRequest(..))
import Browser.Navigation
import ChannelName
import Duration
import Effect.Browser.Dom as Dom
import Effect.Browser.Events
import Effect.Browser.Navigation as BrowserNavigation exposing (Key)
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Lamdera as Lamdera
import Effect.Subscription as Subscription exposing (Subscription)
import Effect.Task as Task
import Effect.Time as Time
import EmailAddress
import Env
import GuildIcon
import GuildName
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Icons
import Id exposing (ChannelId, GuildId, Id, UserId)
import Json.Decode
import Lamdera as LamderaCore
import Local exposing (Local)
import LocalState exposing (AdminStatus(..), Channel, Guild, LocalState, Message)
import LoginForm
import MyUi
import NonemptyDict
import Pages.Admin
import Pages.Home
import Pages.UserOverview
import Pagination
import PersonName
import Route exposing (Route(..), UserOverviewRouteData(..))
import SeqDict
import String.Nonempty
import Types exposing (AdminStatusLoginData(..), FrontendModel(..), FrontendMsg(..), LoadStatus(..), LoadedFrontend, LoadingFrontend, LocalChange(..), LocalMsg(..), LoggedIn2, LoginData, LoginResult(..), LoginStatus(..), ServerChange(..), ToBackend(..), ToFrontend(..))
import Ui exposing (Element)
import Ui.Anim
import Ui.Events
import Ui.Font
import Ui.Input
import Ui.Lazy
import Ui.Prose
import Ui.Shadow
import Url exposing (Url)


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
subscriptions _ =
    Subscription.batch
        [ Effect.Browser.Events.onResize GotWindowSize
        , if Env.isProduction then
            Time.every Duration.second GotTime

          else
            Time.every (Duration.seconds 10) GotTime
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
            Route.decode url |> Maybe.withDefault HomePageRoute
    in
    ( Loading
        { navigationKey = key
        , route = route
        , windowSize = ( 1920, 1080 )
        , time = Nothing
        , loginStatus = LoadingData
        }
    , Command.batch
        [ Task.perform GotTime Time.now
        , BrowserNavigation.replaceUrl key (Route.encode route)
        , Task.perform (\{ viewport } -> GotWindowSize (round viewport.width) (round viewport.height)) Dom.getViewport
        , Lamdera.sendToBackend CheckLoginRequest
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
            }

        ( model2, cmdA ) =
            routeRequest model
    in
    ( model2
    , Command.batch [ cmdB, cmdA ]
    )


loadedInitHelper :
    Time.Posix
    -> LoginData
    ->
        { a
            | windowSize : ( Int, Int )
            , navigationKey : Key
            , route : Route
        }
    -> ( LoggedIn2, Command FrontendOnly ToBackend FrontendMsg )
loadedInitHelper time loginData loading =
    let
        localState : LocalState
        localState =
            { userId = loginData.userId
            , adminData =
                case loginData.adminData of
                    IsAdminLoginData adminData ->
                        IsAdmin
                            { users = adminData.users
                            , emailNotificationsEnabled = adminData.emailNotificationsEnabled
                            , twoFactorAuthentication = adminData.twoFactorAuthentication
                            }

                    IsNotAdminLoginData data ->
                        IsNotAdmin data
            , guilds = loginData.guilds
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
                            Pagination.init (LocalState.currentUser localState).lastLogPageViewed
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

                IsNotAdminLoginData _ ->
                    Nothing

        loggedIn : LoggedIn2
        loggedIn =
            { localState = localStateContainer
            , admin = Maybe.map (\( a, _, _ ) -> a) maybeAdmin
            , userOverview =
                Pages.UserOverview.init
                    loginData.twoFactorAuthenticationEnabled
                    (LocalState.currentUser localState |> Just)
                    |> SeqDict.singleton loginData.userId
            , drafts = SeqDict.empty
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
                AdminChange adminChange |> Just

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
                    ( Loading { loading | windowSize = ( width, height ) }, Command.none )

                _ ->
                    ( model, Command.none )

        Loaded loaded ->
            updateLoaded msg loaded |> Tuple.mapFirst Loaded


routeRequest : LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg )
routeRequest model =
    case model.route of
        HomePageRoute ->
            ( { model
                | loginStatus =
                    case model.loginStatus of
                        NotLoggedIn notLoggedIn ->
                            NotLoggedIn { notLoggedIn | loginForm = Nothing }

                        LoggedIn _ ->
                            model.loginStatus
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
                model

        UserOverviewRoute maybeUserId ->
            case maybeUserId of
                SpecificUserRoute _ ->
                    ( model, Command.none )

                PersonalRoute ->
                    updateLoggedIn
                        (\loggedIn ->
                            ( loggedIn
                            , Local.model loggedIn.localState
                                |> .userId
                                |> SpecificUserRoute
                                |> UserOverviewRoute
                                |> Route.encode
                                |> BrowserNavigation.replaceUrl model.navigationKey
                            )
                        )
                        model

        GuildRoute _ ->
            ( model, Command.none )

        ChannelRoute _ _ ->
            ( model, Command.none )


routeRequiresLogin : Route -> Bool
routeRequiresLogin route =
    case route of
        HomePageRoute ->
            False

        AdminRoute _ ->
            True

        UserOverviewRoute _ ->
            True

        GuildRoute _ ->
            True

        ChannelRoute _ _ ->
            True


updateLoaded : FrontendMsg -> LoadedFrontend -> ( LoadedFrontend, Command FrontendOnly ToBackend FrontendMsg )
updateLoaded msg model =
    case msg of
        UrlClicked urlRequest ->
            case urlRequest of
                Internal url ->
                    let
                        route =
                            Route.decode url |> Maybe.withDefault HomePageRoute
                    in
                    ( model
                    , if model.route == route then
                        BrowserNavigation.replaceUrl model.navigationKey (Route.encode route)

                      else
                        BrowserNavigation.pushUrl model.navigationKey (Route.encode route)
                    )

                External url ->
                    ( model, BrowserNavigation.load url )

        UrlChanged url ->
            let
                route : Route
                route =
                    Route.decode url |> Maybe.withDefault HomePageRoute

                ( model2, cmd ) =
                    routeRequest { model | route = route }
            in
            ( model2
            , cmd
            )

        GotTime time ->
            ( { model | time = time }, Command.none )

        GotWindowSize width height ->
            ( { model | windowSize = ( width, height ) }
            , Command.none
            )

        ScrolledToTop ->
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
                                (Maybe.map AdminChange maybeLocalChange)
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
                            ( { model | loginStatus = NotLoggedIn { notLoggedIn | loginForm = Nothing } }
                            , if routeRequiresLogin model.route then
                                BrowserNavigation.pushUrl model.navigationKey (Route.encode HomePageRoute)

                              else
                                Command.none
                            )

        PressedLogOut ->
            ( model, Lamdera.sendToBackend LogOutRequest )

        ScrolledToLogSection ->
            ( model, Command.none )

        ElmUiMsg elmUiMsg ->
            ( { model | elmUiState = Ui.Anim.update ElmUiMsg elmUiMsg model.elmUiState }, Command.none )

        PressedLink route ->
            ( model
            , BrowserNavigation.pushUrl model.navigationKey (Route.encode route)
            )

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
                                            (Local.model loggedIn.localState).userId

                                        SpecificUserRoute userId2 ->
                                            userId2

                                ( userOverview2, maybeChange, cmd ) =
                                    Pages.UserOverview.update userOverviewMsg (getUserOverview userId loggedIn)
                            in
                            handleLocalChange
                                model.time
                                (Maybe.map UserOverviewChange maybeChange)
                                { loggedIn | userOverview = SeqDict.insert userId userOverview2 loggedIn.userOverview }
                                (Command.map UserOverviewToBackend UserOverviewMsg cmd)

                        _ ->
                            ( loggedIn, Command.none )
                )
                model

        PressedGuildIcon guildId ->
            ( model
            , BrowserNavigation.pushUrl model.navigationKey (Route.encode (GuildRoute guildId))
            )

        PressedChannelName guildId channelId ->
            ( model
            , BrowserNavigation.pushUrl model.navigationKey (Route.encode (ChannelRoute guildId channelId))
            )

        TypedMessage guildId channelId text ->
            updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn
                        | drafts =
                            case String.Nonempty.fromString text of
                                Just nonempty ->
                                    SeqDict.insert ( guildId, channelId ) nonempty loggedIn.drafts

                                Nothing ->
                                    SeqDict.remove ( guildId, channelId ) loggedIn.drafts
                      }
                    , Command.none
                    )
                )
                model

        PressedSendMessage guildId channelId text ->
            updateLoggedIn
                (\loggedIn ->
                    handleLocalChange
                        model.time
                        (SendMessage model.time guildId channelId text |> Just)
                        { loggedIn
                            | drafts =
                                SeqDict.remove ( guildId, channelId ) loggedIn.drafts
                        }
                        Command.none
                )
                model


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
                (if userId == localState.userId then
                    LocalState.currentUser localState |> Just

                 else
                    Nothing
                )


changeUpdate : LocalMsg -> LocalState -> LocalState
changeUpdate localMsg local =
    case localMsg of
        LocalChange changedBy localChange ->
            case localChange of
                InvalidChange ->
                    local

                AdminChange adminChange ->
                    case local.adminData of
                        IsAdmin adminData ->
                            { local
                                | adminData =
                                    Pages.Admin.updateAdmin changedBy adminChange adminData |> IsAdmin
                            }

                        IsNotAdmin _ ->
                            local

                UserOverviewChange userOverviewChange ->
                    case userOverviewChange of
                        Pages.UserOverview.EmailNotificationsChange emailNotifications ->
                            LocalState.updateUser
                                changedBy
                                (\user -> { user | emailNotifications = emailNotifications })
                                local

                SendMessage createdAt guildId channelId text ->
                    case SeqDict.get guildId local.guilds of
                        Just guild ->
                            case SeqDict.get channelId guild.channels of
                                Just channel ->
                                    { local
                                        | guilds =
                                            SeqDict.insert
                                                guildId
                                                { guild
                                                    | channels =
                                                        SeqDict.insert
                                                            channelId
                                                            (LocalState.createMessage
                                                                createdAt
                                                                local.userId
                                                                text
                                                                channel
                                                            )
                                                            guild.channels
                                                }
                                                local.guilds
                                    }

                                Nothing ->
                                    local

                        Nothing ->
                            local

        ServerChange serverChange ->
            case serverChange of
                Server_SendMessage userId createdAt guildId channelId text ->
                    case SeqDict.get guildId local.guilds of
                        Just guild ->
                            case SeqDict.get channelId guild.channels of
                                Just channel ->
                                    { local
                                        | guilds =
                                            SeqDict.insert
                                                guildId
                                                { guild
                                                    | channels =
                                                        SeqDict.insert
                                                            channelId
                                                            (LocalState.createMessage
                                                                createdAt
                                                                userId
                                                                text
                                                                channel
                                                            )
                                                            guild.channels
                                                }
                                                local.guilds
                                    }

                                Nothing ->
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
                        (LocalChange (Local.model loggedIn.localState).userId localChange)
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
            case result of
                LoginSuccess loginData ->
                    let
                        ( loggedIn, cmdA ) =
                            loadedInitHelper model.time loginData model

                        ( model2, cmdB ) =
                            routeRequest { model | loginStatus = LoggedIn loggedIn }
                    in
                    ( model2
                    , Command.batch
                        [ cmdA
                        , cmdB
                        , case model2.route of
                            HomePageRoute ->
                                Command.none

                            AdminRoute _ ->
                                Command.none

                            UserOverviewRoute _ ->
                                Command.none

                            GuildRoute _ ->
                                Command.none

                            ChannelRoute _ _ ->
                                Command.none
                        ]
                    )

                LoginTokenInvalid loginCode ->
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
                                                        LoginForm.invalidCode loginCode loginForm |> Just

                                                    Nothing ->
                                                        Nothing
                                        }
                              }
                            , Command.none
                            )

                NeedsTwoFactorToken ->
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
                                                        LoginForm.needsTwoFactor loginForm |> Just

                                                    Nothing ->
                                                        Nothing
                                        }
                              }
                            , Command.none
                            )

        LoggedOutSession ->
            case model.loginStatus of
                LoggedIn _ ->
                    ( { model
                        | loginStatus = NotLoggedIn { loginForm = Nothing }
                      }
                    , if routeRequiresLogin model.route then
                        BrowserNavigation.pushUrl model.navigationKey (Route.encode HomePageRoute)

                      else
                        Command.none
                    )

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
                            (Local.model loggedIn.localState).userId

                        change : LocalMsg
                        change =
                            LocalChange userId localChange

                        localState : Local LocalMsg LocalState
                        localState =
                            Local.updateFromBackend changeUpdate (Just changeId) change loggedIn.localState
                    in
                    ( { loggedIn
                        | localState = localState
                      }
                    , Command.none
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
                    in
                    ( { loggedIn
                        | localState = localState
                      }
                    , Command.none
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
                                            (Local.model loggedIn.localState).userId

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


pendingChangesText : LocalChange -> String
pendingChangesText localChange =
    case localChange of
        InvalidChange ->
            -- We should never have a invalid change in the local msg queue
            "InvalidChange"

        AdminChange adminChange ->
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

        UserOverviewChange _ ->
            "Changed user profile"

        SendMessage _ _ _ _ ->
            "Sent a message"


layout : LoadedFrontend -> List (Ui.Attribute FrontendMsg) -> Element FrontendMsg -> Html FrontendMsg
layout model attributes child =
    Ui.Anim.layout
        { options = []
        , toMsg = ElmUiMsg
        , breakpoints = Nothing
        }
        model.elmUiState
        (Ui.inFront
            (case model.loginStatus of
                LoggedIn loggedIn ->
                    Local.networkError
                        (\change ->
                            case change of
                                LocalChange _ localChange ->
                                    pendingChangesText localChange

                                ServerChange serverChange ->
                                    ""
                        )
                        model.time
                        loggedIn.localState

                NotLoggedIn _ ->
                    Ui.none
            )
            :: Ui.Font.family [ Ui.Font.sansSerif ]
            :: Ui.height Ui.fill
            :: Ui.behindContent (Ui.html MyUi.fontCss)
            :: Ui.Font.size 16
            :: Ui.background (Ui.rgb 255 255 255)
            :: attributes
        )
        child


view : FrontendModel -> Browser.Document FrontendMsg
view model =
    { title = Env.companyName
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
                        Tuple.first loaded.windowSize

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
                                    |> Ui.map LoginFormMsg
                                    |> layout loaded []
                in
                case loaded.route of
                    HomePageRoute ->
                        layout
                            loaded
                            [ Ui.background background2 ]
                            (case loaded.loginStatus of
                                LoggedIn loggedIn ->
                                    let
                                        local =
                                            Local.model loggedIn.localState
                                    in
                                    homePageLoggedInView loggedIn local

                                NotLoggedIn { loginForm } ->
                                    Ui.el
                                        [ Ui.inFront (Pages.Home.header windowWidth loaded.loginStatus)
                                        , Ui.height Ui.fill
                                        ]
                                        (case loginForm of
                                            Just loginForm2 ->
                                                LoginForm.view loginForm2 |> Ui.map LoginFormMsg

                                            Nothing ->
                                                Ui.Lazy.lazy Pages.Home.view windowWidth
                                        )
                            )

                    AdminRoute _ ->
                        requiresLogin
                            (\loggedIn local ->
                                case ( loggedIn.admin, local.adminData ) of
                                    ( Just admin, IsAdmin adminData ) ->
                                        case NonemptyDict.get local.userId adminData.users of
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
                                                local.userId

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

                    GuildRoute guildId ->
                        requiresLogin (guildView guildId)

                    ChannelRoute guildId channelId ->
                        requiresLogin
                            (channelView guildId channelId)
        ]
    }


guildColumn : LoggedIn2 -> LocalState -> Element FrontendMsg
guildColumn _ local =
    Ui.column
        [ Ui.spacing 4
        , Ui.padding 6
        , Ui.width Ui.shrink
        , Ui.height Ui.fill
        , Ui.background background1
        , Ui.borderColor border1
        , Ui.borderWith { left = 0, right = 1, bottom = 0, top = 0 }
        ]
        (List.map
            (\( guildId, guild ) ->
                Ui.el
                    [ Ui.Input.button (PressedGuildIcon guildId)
                    ]
                    (GuildIcon.view guild)
            )
            (SeqDict.toList local.guilds)
        )


homePageLoggedInView : LoggedIn2 -> LocalState -> Element FrontendMsg
homePageLoggedInView loggedIn local =
    Ui.row
        [ Ui.height Ui.fill
        ]
        [ guildColumn loggedIn local
        ]


guildView : Id GuildId -> LoggedIn2 -> LocalState -> Element FrontendMsg
guildView guildId loggedIn local =
    case SeqDict.get guildId local.guilds of
        Just guild ->
            Ui.row
                [ Ui.height Ui.fill ]
                [ guildColumn loggedIn local
                , channelColumn guildId guild
                ]

        Nothing ->
            homePageLoggedInView loggedIn local


channelView : Id GuildId -> Id ChannelId -> LoggedIn2 -> LocalState -> Element FrontendMsg
channelView guildId channelId loggedIn local =
    case SeqDict.get guildId local.guilds of
        Just guild ->
            case SeqDict.get channelId guild.channels of
                Just channel ->
                    Ui.row
                        [ Ui.height Ui.fill ]
                        [ guildColumn loggedIn local
                        , channelColumn guildId guild
                        , conversationView guildId channelId loggedIn local channel
                        ]

                Nothing ->
                    Ui.text "Channel does not exist"

        Nothing ->
            guildView guildId loggedIn local


conversationView :
    Id GuildId
    -> Id ChannelId
    -> LoggedIn2
    -> LocalState
    -> Channel
    -> Element FrontendMsg
conversationView guildId channelId loggedIn local channel =
    let
        text : String
        text =
            case SeqDict.get ( guildId, channelId ) loggedIn.drafts of
                Just nonempty ->
                    String.Nonempty.toString nonempty

                Nothing ->
                    ""
    in
    Ui.column
        [ Ui.height Ui.fill, Ui.background background3 ]
        [ Ui.column
            [ Ui.height Ui.fill, Ui.paddingXY 8 16 ]
            (List.map
                (messageView local)
                (Array.toList channel.messages)
            )
        , Ui.el
            [ Ui.paddingWith { left = 8, right = 8, top = 0, bottom = 8 } ]
            (Ui.Input.multiline
                [ Ui.Font.color
                    (if text == "" then
                        placeholderFont

                     else
                        font1
                    )
                , Ui.background background2
                , Ui.borderColor border1
                , Html.Events.preventDefaultOn
                    "keydown"
                    (Json.Decode.map2 Tuple.pair
                        (Json.Decode.field "shiftKey" Json.Decode.bool)
                        (Json.Decode.field "key" Json.Decode.string)
                        |> Json.Decode.andThen
                            (\( shiftHeld, key ) ->
                                if key == "Enter" && not shiftHeld then
                                    case String.Nonempty.fromString text of
                                        Just nonempty ->
                                            Json.Decode.succeed ( PressedSendMessage guildId channelId nonempty, True )

                                        Nothing ->
                                            Json.Decode.fail ""

                                else
                                    Json.Decode.fail ""
                            )
                    )
                    |> Ui.htmlAttribute
                ]
                { onChange = TypedMessage guildId channelId
                , text = text
                , placeholder =
                    "Write a message in #"
                        ++ ChannelName.toString channel.name
                        |> Just
                , label = Ui.Input.labelHidden "Message input field"
                , spellcheck = True
                }
            )
        ]


messageView : LocalState -> Message -> Element FrontendMsg
messageView local message =
    Ui.Prose.paragraph
        [ Ui.Font.color font1
        , Ui.paddingXY 0 10
        ]
        [ Ui.el
            [ Ui.Font.bold ]
            (case LocalState.getUser message.createdBy local of
                Just user ->
                    Ui.text (PersonName.toString user.name ++ " ")

                Nothing ->
                    Ui.text "<missing> "
            )
        , Ui.el
            [ Html.Attributes.style "white-space" "pre-wrap" |> Ui.htmlAttribute ]
            (Ui.text (String.Nonempty.toString message.content))
        ]


channelColumn : Id GuildId -> Guild -> Element FrontendMsg
channelColumn guildId guild =
    Ui.column
        [ Ui.height Ui.fill
        , Ui.background background2
        , Ui.width Ui.shrink
        , Ui.widthMin 200
        , Ui.widthMax 300
        ]
        [ Ui.el
            [ Ui.Font.bold
            , Ui.paddingXY 8 16
            , Ui.Font.color font1
            , Ui.borderWith { left = 0, right = 0, top = 0, bottom = 1 }
            , Ui.borderColor border1
            ]
            (Ui.text (GuildName.toString guild.name))
        , Ui.column
            [ Ui.paddingXY 0 8 ]
            (List.map
                (\( channelId, channel ) ->
                    Ui.el
                        [ Ui.paddingXY 8 8
                        , Ui.Font.color font2
                        , Ui.Input.button (PressedChannelName guildId channelId)
                        ]
                        (Ui.text ("# " ++ ChannelName.toString channel.name))
                )
                (SeqDict.toList guild.channels)
            )
        ]


font1 : Ui.Color
font1 =
    Ui.rgb 255 255 255


font2 : Ui.Color
font2 =
    Ui.rgb 220 220 220


placeholderFont : Ui.Color
placeholderFont =
    Ui.rgb 180 180 180


background1 : Ui.Color
background1 =
    Ui.rgb 14 20 40


background2 : Ui.Color
background2 =
    Ui.rgb 32 40 70


background3 : Ui.Color
background3 =
    Ui.rgb 50 60 90


border1 : Ui.Color
border1 =
    Ui.rgb 60 70 100
