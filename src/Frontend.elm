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
import LocalState exposing (AdminStatus(..), BackendChannel, BackendGuild, FrontendChannel, FrontendGuild, LocalState, Message(..))
import LoginForm
import MyUi
import NonemptyDict
import Pages.Admin
import Pages.Home
import Pages.UserOverview
import Pagination
import PersonName
import Ports
import Quantity
import Route exposing (ChannelRoute(..), Route(..), UserOverviewRouteData(..))
import SeqDict
import String.Nonempty
import Types exposing (AdminStatusLoginData(..), FrontendModel(..), FrontendMsg(..), LoadStatus(..), LoadedFrontend, LoadingFrontend, LocalChange(..), LocalMsg(..), LoggedIn2, LoginData, LoginResult(..), LoginStatus(..), NewChannelForm, ServerChange(..), ToBackend(..), ToBeFilledInByBackend(..), ToFrontend(..))
import Ui exposing (Element)
import Ui.Anim
import Ui.Events
import Ui.Font
import Ui.Input
import Ui.Lazy
import Ui.Prose
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
            Route.decode url
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

                    IsNotAdminLoginData ->
                        IsNotAdmin
            , guilds = loginData.guilds
            , joinGuildError = Nothing
            , user = loginData.user
            , otherUsers = loginData.otherUsers
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
                            Pagination.init localState.user.lastLogPageViewed
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
                    (Just localState.user)
                    |> SeqDict.singleton loginData.userId
            , drafts = SeqDict.empty
            , newChannelForm = SeqDict.empty
            , editChannelForm = SeqDict.empty
            , channelNameHover = Nothing
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

        GuildRoute guildId channelRoute ->
            case channelRoute of
                ChannelRoute _ ->
                    ( model, Command.none )

                NewChannelRoute ->
                    ( model, Command.none )

                NoChannelRoute ->
                    ( model, Command.none )

                EditChannelRoute _ ->
                    ( model, Command.none )

                InviteLinkCreatorRoute ->
                    ( model, Command.none )

                JoinRoute inviteLinkId ->
                    case model.loginStatus of
                        NotLoggedIn notLoggedIn ->
                            ( { model
                                | loginStatus =
                                    { notLoggedIn | useInviteAfterLoggedIn = Just inviteLinkId }
                                        |> NotLoggedIn
                              }
                            , Route.replace model.navigationKey (GuildRoute guildId NoChannelRoute)
                            )

                        LoggedIn _ ->
                            ( model
                            , Command.batch
                                [ JoinGuildByInviteRequest guildId inviteLinkId |> Lamdera.sendToBackend
                                , Route.replace model.navigationKey (GuildRoute guildId NoChannelRoute)
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
                        route =
                            Route.decode url
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
                    Route.decode url

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

        PressedSendMessage guildId channelId ->
            updateLoggedIn
                (\loggedIn ->
                    case SeqDict.get ( guildId, channelId ) loggedIn.drafts of
                        Just nonempty ->
                            handleLocalChange
                                model.time
                                (SendMessageChange model.time guildId channelId nonempty |> Just)
                                { loggedIn
                                    | drafts =
                                        SeqDict.remove ( guildId, channelId ) loggedIn.drafts
                                }
                                Command.none

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
            updateLoggedIn
                (\loggedIn ->
                    case ChannelName.fromString newChannelForm.name of
                        Ok channelName ->
                            let
                                ( loggedIn2, cmd ) =
                                    handleLocalChange
                                        model.time
                                        (NewChannelChange model.time guildId channelName |> Just)
                                        { loggedIn
                                            | newChannelForm =
                                                SeqDict.remove guildId loggedIn.newChannelForm
                                        }
                                        Command.none

                                nextChannelId : Id ChannelId
                                nextChannelId =
                                    case SeqDict.get guildId (Local.model loggedIn.localState).guilds of
                                        Just guild ->
                                            Id.nextId guild.channels

                                        Nothing ->
                                            Id.fromInt 0
                            in
                            ( loggedIn2
                            , Command.batch
                                [ Route.push
                                    model.navigationKey
                                    (GuildRoute guildId (ChannelRoute nextChannelId))
                                , cmd
                                ]
                            )

                        Err _ ->
                            ( { loggedIn
                                | newChannelForm =
                                    SeqDict.insert
                                        guildId
                                        { newChannelForm | pressedSubmit = True }
                                        loggedIn.newChannelForm
                              }
                            , Command.none
                            )
                )
                model

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
            updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn
                        | editChannelForm =
                            SeqDict.remove ( guildId, channelId ) loggedIn.editChannelForm
                      }
                    , Route.push model.navigationKey (GuildRoute guildId (ChannelRoute channelId))
                    )
                )
                model

        PressedSubmitEditChannelChanges guildId channelId form ->
            updateLoggedIn
                (\loggedIn ->
                    case ChannelName.fromString form.name of
                        Ok channelName ->
                            handleLocalChange
                                model.time
                                (EditChannelChange guildId channelId channelName |> Just)
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
            updateLoggedIn
                (\loggedIn ->
                    handleLocalChange
                        model.time
                        (DeleteChannelChange guildId channelId |> Just)
                        { loggedIn
                            | drafts = SeqDict.remove ( guildId, channelId ) loggedIn.drafts
                            , editChannelForm =
                                SeqDict.remove ( guildId, channelId ) loggedIn.editChannelForm
                        }
                        (Route.push model.navigationKey (GuildRoute guildId NoChannelRoute))
                )
                model

        PressedCreateInviteLink guildId ->
            updateLoggedIn
                (\loggedIn ->
                    handleLocalChange
                        model.time
                        (NewInviteLinkChange model.time guildId EmptyPlaceholder |> Just)
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
            ( model
            , Command.none
            )


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
                    Just localState.user

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

                        IsNotAdmin ->
                            local

                UserOverviewChange userOverviewChange ->
                    case userOverviewChange of
                        Pages.UserOverview.EmailNotificationsChange emailNotifications ->
                            let
                                user =
                                    local.user
                            in
                            { local
                                | user = { user | emailNotifications = emailNotifications }
                            }

                SendMessageChange createdAt guildId channelId text ->
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
                                                                (UserTextMessage
                                                                    { createdAt = createdAt
                                                                    , createdBy = local.userId
                                                                    , content = text
                                                                    }
                                                                )
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

                NewChannelChange time guildId channelName ->
                    { local
                        | guilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.createChannelFrontend time local.userId channelName)
                                local.guilds
                    }

                EditChannelChange guildId channelId channelName ->
                    { local
                        | guilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.editChannel channelName channelId)
                                local.guilds
                    }

                DeleteChannelChange guildId channelId ->
                    { local
                        | guilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.deleteChannelFrontend channelId)
                                local.guilds
                    }

                NewInviteLinkChange time guildId inviteLinkId ->
                    case inviteLinkId of
                        EmptyPlaceholder ->
                            local

                        FilledInByBackend inviteLinkId2 ->
                            { local
                                | guilds =
                                    SeqDict.updateIfExists
                                        guildId
                                        (LocalState.addInvite inviteLinkId2 local.userId time)
                                        local.guilds
                            }

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
                                                                (UserTextMessage
                                                                    { createdAt = createdAt
                                                                    , createdBy = local.userId
                                                                    , content = text
                                                                    }
                                                                )
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

                Server_NewChannel time guildId channelName ->
                    { local
                        | guilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.createChannelFrontend time local.userId channelName)
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
                    { local
                        | guilds =
                            SeqDict.updateIfExists
                                guildId
                                (\guild -> LocalState.addMember time userId guild |> Result.withDefault guild)
                                local.guilds
                        , otherUsers = SeqDict.insert userId user local.otherUsers
                    }

                Server_YouJoinedGuildByInvite result ->
                    case result of
                        Ok ok ->
                            { local
                                | guilds =
                                    SeqDict.insert ok.guildId ok.guild local.guilds
                                , otherUsers =
                                    SeqDict.insert
                                        ok.guild.owner
                                        ok.owner
                                        local.otherUsers
                                        |> SeqDict.union ok.members
                            }

                        Err error ->
                            { local | joinGuildError = Just error }


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
            case model.loginStatus of
                NotLoggedIn notLoggedIn ->
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

                                    GuildRoute _ _ ->
                                        Command.none
                                , case ( model.route, notLoggedIn.useInviteAfterLoggedIn ) of
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

                LoggedIn _ ->
                    ( model, Command.none )

        LoggedOutSession ->
            case model.loginStatus of
                LoggedIn _ ->
                    ( { model
                        | loginStatus =
                            NotLoggedIn { loginForm = Nothing, useInviteAfterLoggedIn = Nothing }
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

        SendMessageChange _ _ _ _ ->
            "Sent a message"

        NewChannelChange posix id channelName ->
            "Created new channel"

        EditChannelChange id _ channelName ->
            "Edited channel"

        DeleteChannelChange _ id ->
            "Deleted channel"

        NewInviteLinkChange posix id toBeFilledInByBackend ->
            "Created invite link"


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
                            []
                            (case loaded.loginStatus of
                                LoggedIn loggedIn ->
                                    let
                                        local =
                                            Local.model loggedIn.localState
                                    in
                                    homePageLoggedInView loaded loggedIn local

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

                    GuildRoute guildId maybeChannelId ->
                        requiresLogin (guildView loaded guildId maybeChannelId)
        ]
    }


guildColumn : Route -> LoggedIn2 -> LocalState -> Element FrontendMsg
guildColumn route loggedIn local =
    Ui.column
        [ Ui.spacing 4
        , Ui.paddingXY 0 6
        , Ui.width Ui.shrink
        , Ui.height Ui.fill
        , Ui.background background1
        , Ui.borderColor border1
        , Ui.borderWith { left = 0, right = 1, bottom = 0, top = 0 }
        , Ui.scrollable
        ]
        (GuildIcon.showFriendsButton (route == HomePageRoute) (PressedLink HomePageRoute)
            :: List.map
                (\( guildId, guild ) ->
                    Ui.el
                        [ Ui.Input.button (PressedLink (GuildRoute guildId NoChannelRoute))
                        ]
                        (GuildIcon.view
                            (case route of
                                GuildRoute a _ ->
                                    a == guildId

                                _ ->
                                    False
                            )
                            guild
                        )
                )
                (SeqDict.toList local.guilds)
            ++ [ GuildIcon.addGuildButton False PressedCreateGuild ]
        )


homePageLoggedInView : LoadedFrontend -> LoggedIn2 -> LocalState -> Element FrontendMsg
homePageLoggedInView model loggedIn local =
    Ui.row
        [ Ui.height Ui.fill
        , Ui.background background3
        ]
        [ Ui.column
            [ Ui.height Ui.fill, Ui.width (Ui.px 300) ]
            [ Ui.row
                [ Ui.height Ui.fill ]
                [ guildColumn model.route loggedIn local
                , friendsColumn local
                ]
            , loggedInAsView local
            ]
        ]


loggedInAsView : LocalState -> Element FrontendMsg
loggedInAsView local =
    Ui.row
        [ Ui.paddingXY 4 4
        , Ui.Font.color font2
        , Ui.borderColor border1
        , Ui.borderWith { left = 0, bottom = 0, top = 1, right = 0 }
        , Ui.background background1
        ]
        [ Ui.text (PersonName.toString local.user.name)
        , Ui.el
            [ Ui.width (Ui.px 30)
            , Ui.paddingXY 4 0
            , Ui.alignRight
            , Ui.Input.button PressedLogOut
            ]
            (Ui.html Icons.signoutSvg)
        ]


guildView :
    LoadedFrontend
    -> Id GuildId
    -> ChannelRoute
    -> LoggedIn2
    -> LocalState
    -> Element FrontendMsg
guildView model guildId channelRoute loggedIn local =
    case SeqDict.get guildId local.guilds of
        Just guild ->
            Ui.row
                [ Ui.height Ui.fill, Ui.background background3 ]
                [ Ui.column
                    [ Ui.height Ui.fill, Ui.width (Ui.px 300) ]
                    [ Ui.row
                        [ Ui.height Ui.fill ]
                        [ guildColumn model.route loggedIn local
                        , channelColumn local guildId guild channelRoute loggedIn.channelNameHover
                        ]
                    , loggedInAsView local
                    ]
                , case channelRoute of
                    ChannelRoute channelId ->
                        case SeqDict.get channelId guild.channels of
                            Just channel ->
                                conversationView guildId channelId loggedIn local channel

                            Nothing ->
                                Ui.el
                                    [ Ui.centerY
                                    , Ui.Font.center
                                    , Ui.Font.color font1
                                    , Ui.Font.size 20
                                    ]
                                    (Ui.text "Channel does not exist")

                    NewChannelRoute ->
                        SeqDict.get guildId loggedIn.newChannelForm
                            |> Maybe.withDefault newChannelFormInit
                            |> newChannelFormView guildId

                    NoChannelRoute ->
                        case SeqDict.get guild.announcementChannel guild.channels of
                            Just channel ->
                                conversationView guildId guild.announcementChannel loggedIn local channel

                            Nothing ->
                                Ui.el
                                    [ Ui.centerY
                                    , Ui.Font.center
                                    , Ui.Font.color font1
                                    , Ui.Font.size 20
                                    ]
                                    (Ui.text "Channel does not exist")

                    EditChannelRoute channelId ->
                        case SeqDict.get channelId guild.channels of
                            Just channel ->
                                editChannelFormView
                                    guildId
                                    channelId
                                    channel
                                    (SeqDict.get ( guildId, channelId ) loggedIn.editChannelForm
                                        |> Maybe.withDefault (editChannelFormInit channel)
                                    )

                            Nothing ->
                                Ui.el
                                    [ Ui.centerY
                                    , Ui.Font.center
                                    , Ui.Font.color font1
                                    , Ui.Font.size 20
                                    ]
                                    (Ui.text "Channel does not exist")

                    InviteLinkCreatorRoute ->
                        inviteLinkCreatorForm model guildId guild

                    JoinRoute _ ->
                        Ui.none
                , memberColumn local guild
                ]

        Nothing ->
            homePageLoggedInView model loggedIn local


inviteLinkCreatorForm : LoadedFrontend -> Id GuildId -> FrontendGuild -> Element FrontendMsg
inviteLinkCreatorForm model guildId guild =
    Ui.el
        [ Ui.height Ui.fill ]
        (Ui.column
            [ Ui.Font.color font1
            , Ui.padding 16
            , Ui.alignTop
            , Ui.spacing 16
            , Ui.scrollable
            ]
            [ Ui.el [ Ui.Font.size 24 ] (Ui.text "Invite member to guild")
            , submitButton (PressedCreateInviteLink guildId) "Create invite link"
            , Ui.el [ Ui.Font.bold ] (Ui.text "Existing invites")
            , Ui.column
                [ Ui.spacing 8 ]
                (SeqDict.toList guild.invites
                    |> List.sortBy (\( _, data ) -> -(Time.posixToMillis data.createdAt))
                    |> List.map
                        (\( inviteId, data ) ->
                            let
                                url : String
                                url =
                                    Route.encode (GuildRoute guildId (JoinRoute inviteId))
                            in
                            Ui.row
                                [ Ui.spacing 16 ]
                                [ Ui.el [ Ui.widthMax 300 ] (copyableText (Env.domain ++ url) model)
                                , if Duration.from data.createdAt model.time |> Quantity.lessThan (Duration.minutes 5) then
                                    Ui.text "Created just now!"

                                  else
                                    Ui.none
                                ]
                        )
                )
            ]
        )


copyableText : String -> LoadedFrontend -> Element FrontendMsg
copyableText text model =
    let
        isCopied : Bool
        isCopied =
            case model.lastCopied of
                Just copied ->
                    (copied.copiedText == text)
                        && (Duration.from copied.copiedAt model.time
                                |> Quantity.lessThan (Duration.seconds 10)
                           )

                Nothing ->
                    False
    in
    Ui.row
        []
        [ Ui.Input.text
            [ Ui.roundedWith { topLeft = 4, bottomLeft = 4, topRight = 0, bottomRight = 0 }
            , Ui.border 1
            , Ui.borderColor inputBorder
            , Ui.paddingXY 4 4
            , Ui.background inputBackground
            ]
            { text = text
            , onChange = \_ -> FrontendNoOp
            , placeholder = Nothing
            , label = Ui.Input.labelHidden "Readonly text field"
            }
        , Ui.el
            [ Ui.Input.button (PressedCopyText text)
            , Ui.Font.color font2
            , Ui.roundedWith { topRight = 4, bottomRight = 4, topLeft = 0, bottomLeft = 0 }
            , Ui.borderWith { left = 0, right = 1, top = 1, bottom = 1 }
            , Ui.borderColor inputBorder
            , Ui.paddingXY 6 0
            , Ui.width Ui.shrink
            , Ui.height Ui.fill
            , Ui.contentCenterY
            , Ui.Font.size 14
            ]
            (if isCopied then
                Ui.text "Copied!"

             else
                Ui.el [ Ui.width (Ui.px 18) ] (Ui.html Icons.copyIcon)
            )
        ]


conversationView :
    Id GuildId
    -> Id ChannelId
    -> LoggedIn2
    -> LocalState
    -> FrontendChannel
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
        [ Ui.height Ui.fill ]
        [ Ui.column
            [ Ui.height Ui.fill, Ui.paddingXY 8 16, Ui.scrollable ]
            (Ui.el
                [ Ui.Font.color font2 ]
                (Ui.text ("This is the start of #" ++ ChannelName.toString channel.name))
                :: List.map
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
                                    Json.Decode.succeed ( PressedSendMessage guildId channelId, True )

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
    case message of
        UserTextMessage message2 ->
            Ui.Prose.paragraph
                [ Ui.Font.color font1
                , Ui.paddingXY 0 10
                ]
                [ Ui.el
                    [ Ui.Font.bold ]
                    (case LocalState.getUser message2.createdBy local of
                        Just user ->
                            Ui.text (PersonName.toString user.name)

                        Nothing ->
                            Ui.text "<missing> "
                    )
                , Ui.el
                    [ Html.Attributes.style "white-space" "pre-wrap" |> Ui.htmlAttribute ]
                    (Ui.text ("  " ++ String.Nonempty.toString message2.content))
                ]

        UserJoinedMessage _ userId ->
            Ui.Prose.paragraph
                [ Ui.Font.color font1
                , Ui.paddingXY 0 10
                ]
                [ Ui.el
                    [ Ui.Font.bold ]
                    (case LocalState.getUser userId local of
                        Just user ->
                            Ui.text (PersonName.toString user.name)

                        Nothing ->
                            Ui.text "<missing> "
                    )
                , Ui.el
                    []
                    (Ui.text " joined!")
                ]


channelColumn :
    LocalState
    -> Id GuildId
    -> FrontendGuild
    -> ChannelRoute
    -> Maybe ( Id GuildId, Id ChannelId )
    -> Element FrontendMsg
channelColumn local guildId guild channelRoute channelNameHover =
    Ui.column
        [ Ui.height Ui.fill
        , Ui.background background2
        ]
        [ Ui.row
            [ Ui.Font.bold
            , Ui.paddingWith { left = 8, right = 4, top = 0, bottom = 0 }
            , Ui.spacing 8
            , Ui.Font.color font1
            , Ui.borderWith { left = 0, right = 0, top = 0, bottom = 1 }
            , Ui.borderColor border1
            ]
            [ Ui.text (GuildName.toString guild.name)
            , Ui.el
                [ Ui.width Ui.shrink
                , Ui.Input.button (PressedLink (GuildRoute guildId InviteLinkCreatorRoute))
                , Ui.Font.color font2
                , Ui.width (Ui.px 40)
                , Ui.alignRight
                , Ui.paddingXY 8 8
                ]
                (Ui.html Icons.inviteUserIcon)
            ]
        , Ui.column
            [ Ui.paddingXY 0 8, Ui.scrollable ]
            (List.map
                (\( channelId, channel ) ->
                    let
                        isSelected : Bool
                        isSelected =
                            case channelRoute of
                                ChannelRoute a ->
                                    a == channelId

                                NoChannelRoute ->
                                    guild.announcementChannel == channelId

                                _ ->
                                    False

                        isHover =
                            channelNameHover == Just ( guildId, channelId )
                    in
                    Ui.row
                        [ if isSelected then
                            Ui.Font.color font1

                          else
                            Ui.Font.color font2
                        , Ui.attrIf isSelected (Ui.background (Ui.rgba 255 255 255 0.15))
                        , Ui.Events.onMouseEnter (MouseEnteredChannelName guildId channelId)
                        , Ui.Events.onMouseLeave (MouseExitedChannelName guildId channelId)
                        ]
                        [ Ui.el
                            [ Ui.Input.button (PressedLink (GuildRoute guildId (ChannelRoute channelId)))
                            , Ui.paddingWith
                                { left = 8
                                , right =
                                    if isHover then
                                        0

                                    else
                                        8
                                , top = 8
                                , bottom = 8
                                }
                            , Ui.clipWithEllipsis
                            , MyUi.hoverText (ChannelName.toString channel.name)
                            ]
                            (Ui.text ("# " ++ ChannelName.toString channel.name))
                        , if isHover then
                            Ui.el
                                [ Ui.alignRight
                                , Ui.width (Ui.px 26)
                                , Ui.contentCenterY
                                , Ui.height Ui.fill
                                , Ui.paddingXY 4 0
                                , Ui.Font.color font3
                                , Ui.Input.button
                                    (PressedLink (GuildRoute guildId (EditChannelRoute channelId)))
                                ]
                                (Ui.html Icons.gearIcon)

                          else
                            Ui.none
                        ]
                )
                (SeqDict.toList guild.channels)
                ++ [ if local.userId == guild.owner then
                        let
                            isSelected =
                                channelRoute == NewChannelRoute
                        in
                        Ui.row
                            [ Ui.paddingXY 4 8
                            , Ui.Font.color font3
                            , Ui.Input.button (PressedLink (GuildRoute guildId NewChannelRoute))
                            , Ui.attrIf isSelected (Ui.background (Ui.rgba 255 255 255 0.15))
                            , if isSelected then
                                Ui.Font.color font1

                              else
                                Ui.Font.color font3
                            ]
                            [ Ui.el [ Ui.width (Ui.px 22) ] (Ui.html Icons.plusIcon)
                            , Ui.text " Add new channel"
                            ]

                     else
                        Ui.none
                   ]
            )
        ]


friendsColumn : LocalState -> Element FrontendMsg
friendsColumn local =
    Ui.column
        [ Ui.height Ui.fill
        , Ui.background background2
        ]
        [ Ui.el
            [ Ui.Font.bold
            , Ui.paddingXY 8 8
            , Ui.spacing 8
            , Ui.Font.color font1
            , Ui.borderWith { left = 0, right = 0, top = 0, bottom = 1 }
            , Ui.borderColor border1
            ]
            (Ui.text "Direct messages")
        ]


memberColumn : LocalState -> FrontendGuild -> Element FrontendMsg
memberColumn local guild =
    Ui.column
        [ Ui.height Ui.fill
        , Ui.alignRight
        , Ui.background background2
        , Ui.Font.color font1
        ]
        [ Ui.column
            [ Ui.paddingXY 4 4 ]
            [ Ui.text "Owner"
            , memberLabel local guild.owner
            ]
        , Ui.column
            [ Ui.paddingXY 4 4 ]
            [ Ui.text "Members"
            , Ui.column
                [ Ui.height Ui.fill ]
                (List.map
                    (\( userId, _ ) ->
                        memberLabel local userId
                    )
                    (SeqDict.toList guild.members)
                )
            ]
        ]


memberLabel : LocalState -> Id UserId -> Element msg
memberLabel local userId =
    Ui.el
        [ Ui.paddingXY 4 4 ]
        (case LocalState.getUser userId local of
            Just user ->
                Ui.text (PersonName.toString user.name)

            Nothing ->
                Ui.none
        )


newChannelFormInit : NewChannelForm
newChannelFormInit =
    { name = "", pressedSubmit = False }


editChannelFormInit : FrontendChannel -> NewChannelForm
editChannelFormInit channel =
    { name = ChannelName.toString channel.name, pressedSubmit = False }


editChannelFormView : Id GuildId -> Id ChannelId -> FrontendChannel -> NewChannelForm -> Element FrontendMsg
editChannelFormView guildId channelId channel form =
    Ui.column
        [ Ui.Font.color font1, Ui.padding 16, Ui.alignTop, Ui.spacing 16 ]
        [ Ui.el [ Ui.Font.size 24 ] (Ui.text ("Edit #" ++ ChannelName.toString channel.name))
        , channelNameInput guildId form |> Ui.map (EditChannelFormChanged guildId channelId)
        , Ui.row
            [ Ui.spacing 16 ]
            [ Ui.el
                [ Ui.Input.button (PressedCancelEditChannelChanges guildId channelId)
                , Ui.paddingXY 16 8
                , Ui.background cancelButtonBackground
                , Ui.width Ui.shrink
                , Ui.rounded 8
                , Ui.Font.color buttonFontColor
                , Ui.Font.bold
                , Ui.borderColor buttonBorder
                , Ui.border 1
                ]
                (Ui.text "Cancel")
            , submitButton
                (PressedSubmitEditChannelChanges guildId channelId form)
                "Save changes"
            ]

        --, Ui.el [ Ui.height (Ui.px 1), Ui.background splitterColor ] Ui.none
        , Ui.el
            [ Ui.Input.button (PressedDeleteChannel guildId channelId)
            , Ui.paddingXY 16 8
            , Ui.background deleteButtonBackground
            , Ui.width Ui.shrink
            , Ui.rounded 8
            , Ui.Font.color deleteButtonFont
            , Ui.Font.bold
            , Ui.borderColor buttonBorder
            , Ui.border 1
            ]
            (Ui.text "Delete channel")
        ]


newChannelFormView : Id GuildId -> NewChannelForm -> Element FrontendMsg
newChannelFormView guildId form =
    Ui.column
        [ Ui.Font.color font1, Ui.padding 16, Ui.alignTop, Ui.spacing 16 ]
        [ Ui.el [ Ui.Font.size 24 ] (Ui.text "Create new channel")
        , channelNameInput guildId form |> Ui.map (NewChannelFormChanged guildId)
        , submitButton (PressedSubmitNewChannel guildId form) "Create channel"
        ]


submitButton : msg -> String -> Element msg
submitButton onPress text =
    Ui.el
        [ Ui.Input.button onPress
        , Ui.paddingXY 16 8
        , Ui.background buttonBackground
        , Ui.width Ui.shrink
        , Ui.rounded 8
        , Ui.Font.color buttonFontColor
        , Ui.Font.bold
        , Ui.borderColor buttonBorder
        , Ui.border 1
        ]
        (Ui.text text)


channelNameInput : Id GuildId -> NewChannelForm -> Element NewChannelForm
channelNameInput guildId form =
    let
        nameLabel =
            Ui.Input.label
                "newChannelName"
                [ Ui.Font.color font2, Ui.paddingXY 2 0 ]
                (Ui.text "Channel name")
    in
    Ui.column
        []
        [ nameLabel.element
        , Ui.Input.text
            [ Ui.padding 6
            , Ui.background inputBackground
            , Ui.borderColor inputBorder
            , Ui.widthMax 500
            ]
            { onChange = \text -> { form | name = text }
            , text = form.name
            , placeholder = Nothing
            , label = nameLabel.id
            }
        , case ( form.pressedSubmit, ChannelName.fromString form.name ) of
            ( True, Err error ) ->
                Ui.el [ Ui.paddingXY 2 0, Ui.Font.color errorColor ] (Ui.text error)

            _ ->
                Ui.none
        ]


splitterColor : Ui.Color
splitterColor =
    background1


buttonBackground : Ui.Color
buttonBackground =
    Ui.rgb 220 230 240


cancelButtonBackground : Ui.Color
cancelButtonBackground =
    Ui.rgb 196 200 204


deleteButtonBackground =
    Ui.rgb 255 240 250


deleteButtonFont =
    Ui.rgb 255 0 0


buttonBorder : Ui.Color
buttonBorder =
    Ui.rgb 10 20 30


buttonFontColor : Ui.Color
buttonFontColor =
    Ui.rgb 0 0 0


font1 : Ui.Color
font1 =
    Ui.rgb 255 255 255


font2 : Ui.Color
font2 =
    Ui.rgb 220 220 220


font3 : Ui.Color
font3 =
    Ui.rgb 200 200 200


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


inputBackground : Ui.Color
inputBackground =
    Ui.rgb 32 40 70


inputBorder =
    Ui.rgb 97 104 124


border1 : Ui.Color
border1 =
    Ui.rgb 60 70 100


errorColor =
    Ui.rgb 240 170 180
