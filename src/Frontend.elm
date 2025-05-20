module Frontend exposing (app, app_)

import Array
import Browser exposing (UrlRequest(..))
import Browser.Navigation
import ChannelName
import Duration
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Browser.Events
import Effect.Browser.Navigation as BrowserNavigation exposing (Key)
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Lamdera as Lamdera
import Effect.Process as Process
import Effect.Subscription as Subscription exposing (Subscription)
import Effect.Task as Task
import Effect.Time as Time
import EmailAddress
import Emoji exposing (Emoji)
import Env
import GuildIcon exposing (NotificationType(..))
import GuildName
import Html exposing (Html)
import Html.Attributes
import Icons
import Id exposing (ChannelId, GuildId, Id, UserId)
import Json.Decode
import Lamdera as LamderaCore
import List.Extra
import List.Nonempty exposing (Nonempty)
import Local exposing (Local)
import LocalState exposing (AdminStatus(..), BackendChannel, BackendGuild, FrontendChannel, FrontendGuild, LocalState, LocalUser, Message(..), UserTextMessageData)
import LoginForm
import Maybe.Extra
import MessageInput exposing (MentionUserDropdown, MsgConfig)
import MyUi
import NonemptyDict
import NonemptySet exposing (NonemptySet)
import Pages.Admin
import Pages.Home
import Pages.UserOverview
import Pagination
import PersonName exposing (PersonName)
import Ports
import Quantity
import RichText exposing (RichText(..))
import Route exposing (ChannelRoute(..), Route(..), UserOverviewRouteData(..))
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import String.Nonempty exposing (NonemptyString)
import Types exposing (AdminStatusLoginData(..), EditMessage, EmojiSelector(..), FrontendModel(..), FrontendMsg(..), LoadStatus(..), LoadedFrontend, LoadingFrontend, LocalChange(..), LocalMsg(..), LoggedIn2, LoginData, LoginResult(..), LoginStatus(..), MessageId, NewChannelForm, RevealedSpoilers, ServerChange(..), ToBackend(..), ToBeFilledInByBackend(..), ToFrontend(..))
import Ui exposing (Element)
import Ui.Anim
import Ui.Events
import Ui.Font
import Ui.Input
import Ui.Lazy
import Ui.Prose
import Url exposing (Url)
import User exposing (BackendUser, FrontendUser)


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
        , case model of
            Loading _ ->
                Subscription.none

            Loaded loaded ->
                case loaded.route of
                    GuildRoute _ (ChannelRoute _) ->
                        Effect.Browser.Events.onVisibilityChange VisibilityChanged

                    _ ->
                        Subscription.none
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
        , notificationPermission = Ports.Denied
        }
    , Command.batch
        [ Task.perform GotTime Time.now
        , BrowserNavigation.replaceUrl key (Route.encode route)
        , Task.perform (\{ viewport } -> GotWindowSize (round viewport.width) (round viewport.height)) Dom.getViewport
        , Lamdera.sendToBackend CheckLoginRequest
        , Ports.loadSounds
        , Ports.checkNotificationPermission
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
            , channelNameHover = Nothing
            , typingDebouncer = True
            , pingUser = Nothing
            , messageHover = Nothing
            , showEmojiSelector = EmojiSelectorHidden
            , editMessage = SeqDict.empty
            , replyTo = SeqDict.empty
            , revealedSpoilers = Nothing
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
                    ( Loading { loading | windowSize = ( width, height ) }, Command.none )

                CheckedNotificationPermission permission ->
                    ( Loading { loading | notificationPermission = permission }, Command.none )

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
                                |> .localUser
                                |> .userId
                                |> SpecificUserRoute
                                |> UserOverviewRoute
                                |> Route.encode
                                |> BrowserNavigation.replaceUrl model.navigationKey
                            )
                        )
                        model

        GuildRoute guildId channelRoute ->
            let
                model2 : LoadedFrontend
                model2 =
                    { model
                        | loginStatus =
                            case model.loginStatus of
                                LoggedIn loggedIn ->
                                    LoggedIn { loggedIn | revealedSpoilers = Nothing }

                                NotLoggedIn _ ->
                                    model.loginStatus
                    }
            in
            case channelRoute of
                ChannelRoute _ ->
                    ( model2, setFocus channelTextInputId )

                NewChannelRoute ->
                    ( model2, Command.none )

                EditChannelRoute _ ->
                    ( model2, Command.none )

                InviteLinkCreatorRoute ->
                    ( model2, Command.none )

                JoinRoute inviteLinkId ->
                    case model2.loginStatus of
                        NotLoggedIn notLoggedIn ->
                            ( { model2
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
                            ( model2
                            , Command.batch
                                [ JoinGuildByInviteRequest guildId inviteLinkId |> Lamdera.sendToBackend
                                , case SeqDict.get guildId local.guilds of
                                    Just guild ->
                                        Route.replace
                                            model2.navigationKey
                                            (GuildRoute guildId (ChannelRoute guild.announcementChannel))

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
            let
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
                [ BrowserNavigation.pushUrl model.navigationKey (Route.encode route)
                , notificationRequest
                ]
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
                                (messageInputConfig guildId channelId)
                                channelTextInputId
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
                                        (Local_NewChannel model.time guildId channelName |> Just)
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
            updateLoggedIn
                (\loggedIn ->
                    let
                        local : LocalState
                        local =
                            Local.model loggedIn.localState
                    in
                    handleLocalChange
                        model.time
                        (Local_DeleteChannel guildId channelId |> Just)
                        { loggedIn
                            | drafts = SeqDict.remove ( guildId, channelId ) loggedIn.drafts
                            , editChannelForm =
                                SeqDict.remove ( guildId, channelId ) loggedIn.editChannelForm
                        }
                        (case SeqDict.get guildId local.guilds of
                            Just guild ->
                                Route.push
                                    model.navigationKey
                                    (GuildRoute guildId (ChannelRoute guild.announcementChannel))

                            Nothing ->
                                Command.none
                        )
                )
                model

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
            ( model
            , Command.none
            )

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
                                        channelTextInputId
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
                (\loggedIn -> ( { loggedIn | pingUser = Nothing }, Command.none ))
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
                            case loggedIn.pingUser of
                                Just _ ->
                                    ( { loggedIn | pingUser = Nothing, showEmojiSelector = EmojiSelectorHidden }
                                    , setFocus channelTextInputId
                                    )

                                Nothing ->
                                    case loggedIn.showEmojiSelector of
                                        EmojiSelectorHidden ->
                                            case model.route of
                                                GuildRoute guildId (ChannelRoute channelId) ->
                                                    let
                                                        local =
                                                            Local.model loggedIn.localState
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
                                                        (if SeqDict.member ( guildId, channelId ) loggedIn.editMessage then
                                                            { loggedIn
                                                                | editMessage =
                                                                    SeqDict.remove ( guildId, channelId ) loggedIn.editMessage
                                                            }

                                                         else
                                                            { loggedIn
                                                                | replyTo =
                                                                    SeqDict.remove ( guildId, channelId ) loggedIn.replyTo
                                                            }
                                                        )
                                                        (setFocus channelTextInputId)

                                                _ ->
                                                    ( loggedIn, Command.none )

                                        _ ->
                                            ( { loggedIn | showEmojiSelector = EmojiSelectorHidden }, Command.none )
                        )
                        model

                _ ->
                    ( model, Command.none )

        RemovedFocus ->
            ( model, Command.none )

        MouseEnteredMessage messageIndex ->
            case model.route of
                GuildRoute guildId (ChannelRoute channelId) ->
                    updateLoggedIn
                        (\loggedIn ->
                            ( { loggedIn
                                | messageHover =
                                    Just { guildId = guildId, channelId = channelId, messageIndex = messageIndex }
                              }
                            , Command.none
                            )
                        )
                        model

                _ ->
                    ( model, Command.none )

        MouseExitedMessage messageIndex ->
            case model.route of
                GuildRoute guildId (ChannelRoute channelId) ->
                    updateLoggedIn
                        (\loggedIn ->
                            ( { loggedIn
                                | messageHover =
                                    if
                                        Just { guildId = guildId, channelId = channelId, messageIndex = messageIndex }
                                            == loggedIn.messageHover
                                    then
                                        Nothing

                                    else
                                        loggedIn.messageHover
                              }
                            , Command.none
                            )
                        )
                        model

                _ ->
                    ( model, Command.none )

        PressedShowReactionEmojiSelector messageIndex ->
            case model.route of
                GuildRoute guildId (ChannelRoute channelId) ->
                    updateLoggedIn
                        (\loggedIn ->
                            ( { loggedIn
                                | showEmojiSelector =
                                    EmojiSelectorForReaction
                                        { guildId = guildId, channelId = channelId, messageIndex = messageIndex }
                              }
                            , Command.none
                            )
                        )
                        model

                _ ->
                    ( model, Command.none )

        PressedEditMessage messageIndex ->
            case model.route of
                GuildRoute guildId (ChannelRoute channelId) ->
                    updateLoggedIn
                        (\loggedIn ->
                            let
                                local : LocalState
                                local =
                                    Local.model loggedIn.localState
                            in
                            ( case getGuildAndChannel guildId channelId local of
                                Just ( _, channel ) ->
                                    case Array.get messageIndex channel.messages of
                                        Just (UserTextMessage message) ->
                                            { loggedIn
                                                | editMessage =
                                                    SeqDict.insert
                                                        ( guildId, channelId )
                                                        { messageIndex = messageIndex
                                                        , text =
                                                            RichText.toString
                                                                (LocalState.allUsers local)
                                                                message.content
                                                        }
                                                        loggedIn.editMessage
                                            }

                                        _ ->
                                            loggedIn

                                Nothing ->
                                    loggedIn
                            , Command.none
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
                GuildRoute guildId (ChannelRoute channelId) ->
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
                GuildRoute guildId (ChannelRoute channelId) ->
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
                                        (messageInputConfig guildId channelId)
                                        editMessageTextInputId
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
                                (case String.Nonempty.fromString edit.text of
                                    Just nonempty ->
                                        Local_SendEditMessage
                                            model.time
                                            { guildId = guildId
                                            , channelId = channelId
                                            , messageIndex = edit.messageIndex
                                            }
                                            (RichText.fromNonemptyString
                                                (LocalState.allUsers local)
                                                nonempty
                                            )
                                            |> Just

                                    Nothing ->
                                        Nothing
                                )
                                { loggedIn
                                    | editMessage =
                                        SeqDict.remove ( guildId, channelId ) loggedIn.editMessage
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
                                                editMessageTextInputId
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
                    case getGuildAndChannel guildId channelId local of
                        Just ( guild, channel ) ->
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

                                                    UserJoinedMessage posix id seqDict ->
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
                                                    RichText.toString
                                                        (LocalState.allUsers local)
                                                        message
                                                }
                                                loggedIn.editMessage
                                      }
                                    , setFocus editMessageTextInputId
                                    )

                                Nothing ->
                                    ( loggedIn, Command.none )

                        Nothing ->
                            ( loggedIn, Command.none )
                )
                model

        PressedReply messageIndex ->
            case model.route of
                GuildRoute guildId (ChannelRoute channelId) ->
                    updateLoggedIn
                        (\loggedIn ->
                            ( { loggedIn
                                | replyTo = SeqDict.insert ( guildId, channelId ) messageIndex loggedIn.replyTo
                              }
                            , setFocus channelTextInputId
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
                    , setFocus channelTextInputId
                    )
                )
                model

        PressedSpoiler messageIndex spoilerIndex ->
            case model.route of
                GuildRoute guildId (ChannelRoute channelId) ->
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
                    ( model, setFocus channelTextInputId )

                Effect.Browser.Events.Hidden ->
                    ( model, Command.none )

        CheckedNotificationPermission notificationPermission ->
            ( { model | notificationPermission = notificationPermission }, Command.none )


setFocus : HtmlId -> Command FrontendOnly toMsg FrontendMsg
setFocus htmlId =
    Dom.focus htmlId |> Task.attempt (\_ -> SetFocus)


messageInputConfig : Id GuildId -> Id ChannelId -> MsgConfig FrontendMsg
messageInputConfig guildId channelId =
    { gotPingUserPosition = GotPingUserPosition
    , textInputGotFocus = TextInputGotFocus
    , textInputLostFocus = TextInputLostFocus
    , typedMessage = TypedMessage guildId channelId
    , pressedSendMessage = PressedSendMessage guildId channelId
    , pressedArrowInDropdown = PressedArrowInDropdown guildId
    , pressedArrowUpInEmptyInput = PressedArrowUpInEmptyInput guildId channelId
    , pressedPingUser = PressedPingUser guildId channelId
    }


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
                    case getGuildAndChannel guildId channelId local of
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

        ServerChange serverChange ->
            case serverChange of
                Server_SendMessage userId createdAt guildId channelId text repliedTo ->
                    case getGuildAndChannel guildId channelId local of
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
                            (Local.model loggedIn.localState).localUser.userId

                        change : LocalMsg
                        change =
                            LocalChange userId localChange

                        localState : Local LocalMsg LocalState
                        localState =
                            Local.updateFromBackend changeUpdate (Just changeId) change loggedIn.localState
                    in
                    ( { loggedIn | localState = localState }, Command.none )
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
                                        Route.replace model.navigationKey (GuildRoute guildId (ChannelRoute guild.announcementChannel))

                                    else
                                        Command.none

                                _ ->
                                    Command.none

                        ServerChange (Server_SendMessage userId _ guildId channelId content maybeRepliedTo) ->
                            case getGuildAndChannel guildId channelId local of
                                Just ( _, channel ) ->
                                    if
                                        ((repliedToUserId maybeRepliedTo channel /= Just userId)
                                            || RichText.mentionsUser userId content
                                        )
                                            && (userId /= local.localUser.userId)
                                    then
                                        Command.batch
                                            [ Ports.playSound "pop"
                                            , case model.notificationPermission of
                                                Ports.Granted ->
                                                    Ports.showNotification
                                                        (userToName userId (LocalState.allUsers local))
                                                        (RichText.toString (LocalState.allUsers local) content)

                                                _ ->
                                                    Command.none
                                            ]

                                    else
                                        Command.none

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


getGuildAndChannel : Id GuildId -> Id ChannelId -> LocalState -> Maybe ( FrontendGuild, FrontendChannel )
getGuildAndChannel guildId channelId local =
    case SeqDict.get guildId local.guilds of
        Just guild ->
            case SeqDict.get channelId guild.channels of
                Just channel ->
                    Just ( guild, channel )

                Nothing ->
                    Nothing

        Nothing ->
            Nothing


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

        Local_NewChannel posix id channelName ->
            "Created new channel"

        Local_EditChannel id _ channelName ->
            "Edited channel"

        Local_DeleteChannel _ id ->
            "Deleted channel"

        Local_NewInviteLink posix id toBeFilledInByBackend ->
            "Created invite link"

        Local_MemberTyping _ _ _ ->
            "Is typing notification"

        Local_AddReactionEmoji messageId emoji ->
            "Added reaction emoji"

        Local_RemoveReactionEmoji messageId emoji ->
            "Removed reaction emoji"

        Local_SendEditMessage posix messageId nonempty ->
            "Edit message"

        Local_MemberEditTyping posix messageId ->
            "Editing message"

        Local_SetLastViewed id _ int ->
            "Viewed channel"


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
            :: Ui.behindContent (Ui.html MyUi.css)
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
                                let
                                    local =
                                        Local.model loggedIn.localState
                                in
                                layout
                                    loaded
                                    [ case loaded.route of
                                        GuildRoute guildId (ChannelRoute channelId) ->
                                            case
                                                MessageInput.pingDropdownView
                                                    (messageInputConfig guildId channelId)
                                                    guildId
                                                    local
                                                    dropdownButtonId
                                                    loggedIn.pingUser
                                            of
                                                Just element ->
                                                    Ui.inFront element

                                                Nothing ->
                                                    Ui.noAttr

                                        _ ->
                                            Ui.noAttr
                                    ]
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
                                    homePageLoggedInView loaded local

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
                        requiresLogin (guildView loaded guildId maybeChannelId)
        ]
    }


repliedToUserId : Maybe Int -> FrontendChannel -> Maybe (Id UserId)
repliedToUserId maybeRepliedTo channel =
    case maybeRepliedTo of
        Just repliedTo ->
            case Array.get repliedTo channel.messages of
                Just (UserTextMessage repliedToData) ->
                    Just repliedToData.createdBy

                Just (UserJoinedMessage _ joinedUser _) ->
                    Just joinedUser

                Just DeletedMessage ->
                    Nothing

                Nothing ->
                    Nothing

        Nothing ->
            Nothing


channelHasNotifications :
    Id UserId
    -> BackendUser
    -> Id GuildId
    -> Id ChannelId
    -> FrontendChannel
    -> NotificationType
channelHasNotifications currentUserId currentUser guildId channelId channel =
    let
        lastViewed : Int
        lastViewed =
            SeqDict.get ( guildId, channelId ) currentUser.lastViewed |> Maybe.withDefault 0
    in
    Array.slice lastViewed (Array.length channel.messages) channel.messages
        |> Array.toList
        |> List.foldl
            (\message state ->
                case state of
                    NewMessageForUser ->
                        state

                    _ ->
                        case message of
                            UserTextMessage data ->
                                if data.createdBy == currentUserId then
                                    state

                                else if
                                    (repliedToUserId data.repliedTo channel == Just currentUserId)
                                        || RichText.mentionsUser currentUserId data.content
                                then
                                    NewMessageForUser

                                else
                                    NewMessage

                            UserJoinedMessage _ _ _ ->
                                NewMessage

                            DeletedMessage ->
                                state
            )
            NoNotification


guildHasNotifications : Id UserId -> BackendUser -> Id GuildId -> FrontendGuild -> NotificationType
guildHasNotifications currentUserId currentUser guildId guild =
    List.foldl
        (\( channelId, channel ) state ->
            case state of
                NewMessageForUser ->
                    state

                _ ->
                    case channelHasNotifications currentUserId currentUser guildId channelId channel of
                        NoNotification ->
                            state

                        notification ->
                            notification
        )
        NoNotification
        (SeqDict.toList guild.channels)


guildColumn : Route -> Id UserId -> BackendUser -> SeqDict (Id GuildId) FrontendGuild -> Element FrontendMsg
guildColumn route currentUserId currentUser guilds =
    Ui.column
        [ Ui.spacing 4
        , Ui.paddingXY 0 6
        , Ui.width Ui.shrink
        , Ui.height Ui.fill
        , Ui.background MyUi.background1
        , Ui.borderColor MyUi.border1
        , Ui.borderWith { left = 0, right = 1, bottom = 0, top = 0 }
        , Ui.scrollable
        , Ui.htmlAttribute (Html.Attributes.class "disable-scrollbars")
        ]
        (GuildIcon.showFriendsButton (route == HomePageRoute) (PressedLink HomePageRoute)
            :: List.map
                (\( guildId, guild ) ->
                    Ui.el
                        [ Ui.Input.button (PressedLink (GuildRoute guildId (ChannelRoute guild.announcementChannel)))
                        ]
                        (GuildIcon.view
                            (case route of
                                GuildRoute a _ ->
                                    if a == guildId then
                                        GuildIcon.IsSelected

                                    else
                                        guildHasNotifications currentUserId currentUser guildId guild
                                            |> GuildIcon.Normal

                                _ ->
                                    guildHasNotifications currentUserId currentUser guildId guild |> GuildIcon.Normal
                            )
                            guild
                        )
                )
                (SeqDict.toList guilds)
            ++ [ GuildIcon.addGuildButton False PressedCreateGuild ]
        )


homePageLoggedInView : LoadedFrontend -> LocalState -> Element FrontendMsg
homePageLoggedInView model local =
    Ui.row
        [ Ui.height Ui.fill
        , Ui.background MyUi.background3
        ]
        [ Ui.column
            [ Ui.height Ui.fill, Ui.width (Ui.px 300) ]
            [ Ui.row
                [ Ui.height Ui.fill, Ui.heightMin 0 ]
                [ Ui.Lazy.lazy4 guildColumn model.route local.localUser.userId local.localUser.user local.guilds
                , friendsColumn local
                ]
            , loggedInAsView local
            ]
        ]


loggedInAsView : LocalState -> Element FrontendMsg
loggedInAsView local =
    Ui.row
        [ Ui.paddingXY 4 4
        , Ui.Font.color MyUi.font2
        , Ui.borderColor MyUi.border1
        , Ui.borderWith { left = 0, bottom = 0, top = 1, right = 0 }
        , Ui.background MyUi.background1
        ]
        [ Ui.text (PersonName.toString local.localUser.user.name)
        , Ui.el
            [ Ui.width (Ui.px 30)
            , Ui.paddingXY 4 0
            , Ui.alignRight
            , Ui.Input.button PressedLogOut
            ]
            (Ui.html Icons.signoutSvg)
        ]


guildView : LoadedFrontend -> Id GuildId -> ChannelRoute -> LoggedIn2 -> LocalState -> Element FrontendMsg
guildView model guildId channelRoute loggedIn local =
    case SeqDict.get guildId local.guilds of
        Just guild ->
            Ui.row
                [ Ui.height Ui.fill, Ui.background MyUi.background3 ]
                [ Ui.column
                    [ Ui.height Ui.fill, Ui.width (Ui.px 300) ]
                    [ Ui.row
                        [ Ui.height Ui.fill, Ui.heightMin 0 ]
                        [ Ui.Lazy.lazy4 guildColumn model.route local.localUser.userId local.localUser.user local.guilds
                        , Ui.Lazy.lazy6
                            channelColumn
                            local.localUser.userId
                            local.localUser.user
                            guildId
                            guild
                            channelRoute
                            loggedIn.channelNameHover
                        ]
                    , loggedInAsView local
                    ]
                , case channelRoute of
                    ChannelRoute channelId ->
                        case SeqDict.get channelId guild.channels of
                            Just channel ->
                                conversationView guildId channelId loggedIn model local channel

                            Nothing ->
                                Ui.el
                                    [ Ui.centerY
                                    , Ui.Font.center
                                    , Ui.Font.color MyUi.font1
                                    , Ui.Font.size 20
                                    ]
                                    (Ui.text "Channel does not exist")

                    NewChannelRoute ->
                        SeqDict.get guildId loggedIn.newChannelForm
                            |> Maybe.withDefault newChannelFormInit
                            |> newChannelFormView guildId

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
                                    , Ui.Font.color MyUi.font1
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
            homePageLoggedInView model local


inviteLinkCreatorForm : LoadedFrontend -> Id GuildId -> FrontendGuild -> Element FrontendMsg
inviteLinkCreatorForm model guildId guild =
    Ui.el
        [ Ui.height Ui.fill ]
        (Ui.column
            [ Ui.Font.color MyUi.font1
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
            , Ui.borderColor MyUi.inputBorder
            , Ui.paddingXY 4 4
            , Ui.background MyUi.inputBackground
            ]
            { text = text
            , onChange = \_ -> FrontendNoOp
            , placeholder = Nothing
            , label = Ui.Input.labelHidden "Readonly text field"
            }
        , Ui.el
            [ Ui.Input.button (PressedCopyText text)
            , Ui.Font.color MyUi.font2
            , Ui.roundedWith { topRight = 4, bottomRight = 4, topLeft = 0, bottomLeft = 0 }
            , Ui.borderWith { left = 0, right = 1, top = 1, bottom = 1 }
            , Ui.borderColor MyUi.inputBorder
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


channelTextInputId : HtmlId
channelTextInputId =
    "channel_textinput" |> Dom.id


emojiSelector : Element FrontendMsg
emojiSelector =
    Ui.column
        [ Ui.width (Ui.px (8 * 32 + 21))
        , Ui.height (Ui.px 400)
        , Ui.scrollable
        , Ui.background MyUi.background1
        , Ui.border 1
        , Ui.borderColor MyUi.border1
        , Ui.Font.size 24
        ]
        (List.map
            (\emojiRow ->
                Ui.row
                    [ Ui.height (Ui.px 34) ]
                    (List.map
                        (\emoji ->
                            Ui.el
                                [ Ui.width (Ui.px 32)
                                , Ui.contentCenterX
                                , Ui.Input.button (PressedEmojiSelectorEmoji emoji)
                                ]
                                (Ui.text (Emoji.toString emoji))
                        )
                        emojiRow
                    )
            )
            (List.Extra.greedyGroupsOf 8 Emoji.emojis)
        )
        |> Ui.el [ Ui.alignBottom, Ui.paddingXY 8 0, Ui.width Ui.shrink ]


conversationViewHelper :
    Id GuildId
    -> Id ChannelId
    -> FrontendChannel
    -> LoggedIn2
    -> LocalState
    -> LoadedFrontend
    -> List (Element FrontendMsg)
conversationViewHelper guildId channelId channel loggedIn local model =
    let
        maybeEditing : Maybe EditMessage
        maybeEditing =
            SeqDict.get ( guildId, channelId ) loggedIn.editMessage

        othersEditing : SeqSet Int
        othersEditing =
            SeqDict.remove local.localUser.userId channel.lastTypedAt
                |> SeqDict.values
                |> List.filterMap
                    (\a ->
                        if Duration.from a.time model.time |> Quantity.lessThan (Duration.seconds 3) then
                            a.messageIndex

                        else
                            Nothing
                    )
                |> SeqSet.fromList

        replyToIndex : Maybe Int
        replyToIndex =
            SeqDict.get ( guildId, channelId ) loggedIn.replyTo

        messageHoverIndex : Maybe Int
        messageHoverIndex =
            case loggedIn.messageHover of
                Just messageHover ->
                    if messageHover.guildId == guildId && messageHover.channelId == channelId then
                        Just messageHover.messageIndex

                    else
                        Nothing

                Nothing ->
                    Nothing

        revealedSpoilers : SeqDict Int (NonemptySet Int)
        revealedSpoilers =
            case loggedIn.revealedSpoilers of
                Just revealed ->
                    if revealed.guildId == guildId && revealed.channelId == channelId then
                        revealed.messages

                    else
                        SeqDict.empty

                Nothing ->
                    SeqDict.empty

        lastViewedIndex : Int
        lastViewedIndex =
            SeqDict.get ( guildId, channelId ) local.localUser.user.lastViewed |> Maybe.withDefault -1

        allUsers : SeqDict (Id UserId) FrontendUser
        allUsers =
            LocalState.allUsers local
    in
    Array.foldr
        (\message ( index, list ) ->
            let
                otherUserIsEditing : Bool
                otherUserIsEditing =
                    SeqSet.member index othersEditing

                isEditing : Maybe EditMessage
                isEditing =
                    case maybeEditing of
                        Just editing ->
                            if editing.messageIndex == index then
                                Just editing

                            else
                                Nothing

                        Nothing ->
                            Nothing

                highlight : HighlightMessage
                highlight =
                    if replyToIndex == Just index then
                        ReplyToHighlight

                    else
                        NoHighlight

                newLine : List (Element msg)
                newLine =
                    if lastViewedIndex == index - 1 then
                        [ Ui.el
                            [ Ui.borderWith { left = 0, right = 0, top = 1, bottom = 0 }
                            , Ui.borderColor MyUi.alertColor
                            , Ui.inFront
                                (Ui.el
                                    [ Ui.Font.color MyUi.font1
                                    , Ui.background MyUi.alertColor
                                    , Ui.width Ui.shrink
                                    , Ui.paddingXY 4 0
                                    , Ui.alignRight
                                    , Ui.Font.size 12
                                    , Ui.Font.bold
                                    , Ui.height (Ui.px 15)
                                    , Ui.roundedWith
                                        { bottomLeft = 4, bottomRight = 0, topLeft = 0, topRight = 0 }
                                    ]
                                    (Ui.text "New")
                                )
                            ]
                            Ui.none
                        ]

                    else
                        []

                maybeRepliedTo : Maybe ( Int, Message )
                maybeRepliedTo =
                    case message of
                        UserTextMessage data ->
                            case data.repliedTo of
                                Just repliedToIndex ->
                                    case Array.get repliedToIndex channel.messages of
                                        Just message2 ->
                                            Just ( repliedToIndex, message2 )

                                        Nothing ->
                                            Nothing

                                Nothing ->
                                    Nothing

                        UserJoinedMessage posix id seqDict ->
                            Nothing

                        DeletedMessage ->
                            Nothing
            in
            ( index - 1
            , newLine
                ++ (case isEditing of
                        Just editing ->
                            messageEditingView
                                { guildId = guildId, channelId = channelId, messageIndex = index }
                                message
                                maybeRepliedTo
                                revealedSpoilers
                                editing
                                loggedIn.pingUser
                                local

                        Nothing ->
                            if messageHoverIndex == Just index then
                                case highlight of
                                    NoHighlight ->
                                        case maybeRepliedTo of
                                            Just _ ->
                                                messageView
                                                    revealedSpoilers
                                                    highlight
                                                    True
                                                    otherUserIsEditing
                                                    local.localUser
                                                    maybeRepliedTo
                                                    index
                                                    message

                                            Nothing ->
                                                Ui.Lazy.lazy5
                                                    messageViewHovered
                                                    otherUserIsEditing
                                                    revealedSpoilers
                                                    local.localUser
                                                    index
                                                    message

                                    _ ->
                                        messageView
                                            revealedSpoilers
                                            highlight
                                            True
                                            otherUserIsEditing
                                            local.localUser
                                            maybeRepliedTo
                                            index
                                            message

                            else
                                case highlight of
                                    NoHighlight ->
                                        case maybeRepliedTo of
                                            Just _ ->
                                                messageView
                                                    revealedSpoilers
                                                    highlight
                                                    False
                                                    otherUserIsEditing
                                                    local.localUser
                                                    maybeRepliedTo
                                                    index
                                                    message

                                            Nothing ->
                                                Ui.Lazy.lazy5
                                                    messageViewNotHovered
                                                    otherUserIsEditing
                                                    revealedSpoilers
                                                    local.localUser
                                                    index
                                                    message

                                    _ ->
                                        messageView
                                            revealedSpoilers
                                            highlight
                                            False
                                            otherUserIsEditing
                                            local.localUser
                                            maybeRepliedTo
                                            index
                                            message
                   )
                :: list
            )
        )
        ( Array.length channel.messages - 1, [] )
        channel.messages
        |> Tuple.second


conversationView :
    Id GuildId
    -> Id ChannelId
    -> LoggedIn2
    -> LoadedFrontend
    -> LocalState
    -> FrontendChannel
    -> Element FrontendMsg
conversationView guildId channelId loggedIn model local channel =
    let
        allUsers : SeqDict (Id UserId) FrontendUser
        allUsers =
            LocalState.allUsers local
    in
    Ui.column
        [ Ui.height Ui.fill ]
        [ Ui.el
            [ case loggedIn.showEmojiSelector of
                EmojiSelectorHidden ->
                    Ui.noAttr

                EmojiSelectorForReaction _ ->
                    Ui.inFront emojiSelector

                EmojiSelectorForMessage ->
                    Ui.inFront emojiSelector
            , Ui.heightMin 0
            , Ui.height Ui.fill
            ]
            (Ui.column
                [ Ui.height Ui.fill, Ui.paddingXY 0 16, Ui.scrollable ]
                (Ui.el
                    [ Ui.Font.color MyUi.font2, Ui.paddingXY 8 4 ]
                    (Ui.text ("This is the start of #" ++ ChannelName.toString channel.name))
                    :: conversationViewHelper guildId channelId channel loggedIn local model
                )
            )
        , Ui.column
            [ Ui.paddingXY 5 0 ]
            [ case SeqDict.get ( guildId, channelId ) loggedIn.replyTo of
                Just messageIndex ->
                    case Array.get messageIndex channel.messages of
                        Just (UserTextMessage data) ->
                            replyToHeader guildId channelId data.createdBy local

                        Just (UserJoinedMessage _ userId _) ->
                            replyToHeader guildId channelId userId local

                        Just DeletedMessage ->
                            Ui.none

                        Nothing ->
                            Ui.none

                Nothing ->
                    Ui.none
            , MessageInput.view
                (messageInputConfig guildId channelId)
                channelTextInputId
                ("Write a message in #" ++ ChannelName.toString channel.name)
                (case SeqDict.get ( guildId, channelId ) loggedIn.drafts of
                    Just text ->
                        String.Nonempty.toString text

                    Nothing ->
                        ""
                )
                loggedIn.pingUser
                local
            ]
        , (case
            SeqDict.filter
                (\_ a ->
                    (Duration.from a.time model.time |> Quantity.lessThan (Duration.seconds 3))
                        && (a.messageIndex == Nothing)
                )
                (SeqDict.remove local.localUser.userId channel.lastTypedAt)
                |> SeqDict.keys
           of
            [] ->
                ""

            [ single ] ->
                userToName single allUsers ++ " is typing..."

            [ one, two ] ->
                userToName one allUsers ++ " and " ++ userToName two allUsers ++ " are typing..."

            [ one, two, three ] ->
                userToName one allUsers
                    ++ ", "
                    ++ userToName two allUsers
                    ++ ", and "
                    ++ userToName three allUsers
                    ++ " are typing..."

            _ :: _ :: _ :: _ ->
                "Several people are typing..."
          )
            |> Ui.text
            |> Ui.el
                [ Ui.Font.bold
                , Ui.Font.size 13
                , Ui.Font.color MyUi.font3
                , Ui.height (Ui.px 18)
                , Ui.contentCenterY
                , Ui.paddingXY 12 0
                ]
        ]


replyToHeader : Id GuildId -> Id ChannelId -> Id UserId -> LocalState -> Element FrontendMsg
replyToHeader guildId channelId userId local =
    Ui.Prose.paragraph
        [ Ui.Font.color MyUi.font2
        , Ui.background MyUi.background2
        , Ui.paddingXY 32 10
        , Ui.roundedWith { topLeft = 8, topRight = 8, bottomLeft = 0, bottomRight = 0 }
        , Ui.border 1
        , Ui.borderColor MyUi.border1
        , Ui.inFront
            (Ui.el
                [ Ui.Input.button (PressedCloseReplyTo guildId channelId)
                , Ui.width (Ui.px 32)
                , Ui.paddingWith { left = 4, right = 4, top = 4, bottom = 0 }
                , Ui.alignRight
                ]
                (Ui.html Icons.x)
            )
        , Ui.inFront
            (Ui.el [ Ui.width (Ui.px 18), Ui.move { x = 10, y = 8, z = 0 } ] (Ui.html Icons.reply))
        ]
        [ Ui.text "Reply to "
        , Ui.el [ Ui.Font.bold ] (Ui.text (userToName userId (LocalState.allUsers local)))
        ]
        |> Ui.el [ Ui.paddingXY 3 0, Ui.move { x = 0, y = 4, z = 0 } ]


dropdownButtonId : Int -> HtmlId
dropdownButtonId index =
    Dom.id ("dropdown_button" ++ String.fromInt index)


messageHoverButton : msg -> Html msg -> Element msg
messageHoverButton onPress svg =
    Ui.el
        [ Ui.width (Ui.px 32)
        , Ui.paddingXY 4 3
        , Ui.height Ui.fill
        , Ui.Input.button onPress
        ]
        (Ui.html svg)


reactionEmojiView : Int -> Id UserId -> SeqDict Emoji (NonemptySet (Id UserId)) -> Maybe (Element FrontendMsg)
reactionEmojiView messageIndex currentUserId reactions =
    if SeqDict.isEmpty reactions then
        Nothing

    else
        Ui.row
            [ Ui.wrap, Ui.spacing 4 ]
            (List.map
                (\( emoji, users ) ->
                    let
                        hasReactedTo : Bool
                        hasReactedTo =
                            NonemptySet.member currentUserId users
                    in
                    Ui.row
                        [ Ui.rounded 8
                        , Ui.background MyUi.background1
                        , Ui.paddingWith { left = 1, right = 4, top = 0, bottom = 0 }
                        , Ui.borderColor
                            (if hasReactedTo then
                                MyUi.highlightedBorder

                             else
                                MyUi.border1
                            )
                        , Ui.Font.color
                            (if hasReactedTo then
                                MyUi.highlightedBorder

                             else
                                MyUi.font2
                            )
                        , Ui.border 1
                        , Ui.width Ui.shrink
                        , Ui.Font.bold
                        , Ui.Input.button
                            (if hasReactedTo then
                                PressedReactionEmoji_Remove messageIndex emoji

                             else
                                PressedReactionEmoji_Add messageIndex emoji
                            )
                        ]
                        [ Emoji.view emoji, Ui.text (String.fromInt (NonemptySet.size users)) ]
                )
                (SeqDict.toList reactions)
            )
            |> Just


messageEditingView :
    MessageId
    -> Message
    -> Maybe ( Int, Message )
    -> SeqDict Int (NonemptySet Int)
    -> EditMessage
    -> Maybe MentionUserDropdown
    -> LocalState
    -> Element FrontendMsg
messageEditingView messageId message maybeRepliedTo revealedSpoilers editing pingUser local =
    case message of
        UserTextMessage data ->
            let
                maybeReactions =
                    reactionEmojiView messageId.messageIndex local.localUser.userId data.reactions
            in
            Ui.column
                [ Ui.Font.color MyUi.font1
                , Ui.background MyUi.hoverHighlight
                , Ui.paddingWith
                    { left = 0
                    , right = 0
                    , top = 4
                    , bottom =
                        if maybeReactions == Nothing then
                            8

                        else
                            4
                    }
                , Ui.spacing 4
                ]
                [ repliedToMessage maybeRepliedTo revealedSpoilers (LocalState.allUsers local)
                    |> Ui.el [ Ui.paddingXY 8 0 ]
                , userToName data.createdBy (LocalState.allUsers local)
                    ++ " "
                    |> Ui.text
                    |> Ui.el [ Ui.Font.bold, Ui.paddingXY 8 0 ]
                , MessageInput.view
                    (editMessageTextInputConfig messageId.guildId messageId.channelId)
                    editMessageTextInputId
                    ""
                    editing.text
                    pingUser
                    local
                    |> Ui.el [ Ui.paddingXY 5 0 ]
                , case maybeReactions of
                    Just reactionView ->
                        Ui.el [ Ui.paddingXY 8 0 ] reactionView

                    Nothing ->
                        Ui.none
                ]

        UserJoinedMessage _ _ _ ->
            Ui.none

        DeletedMessage ->
            Ui.none


editMessageTextInputConfig : Id GuildId -> Id ChannelId -> MsgConfig FrontendMsg
editMessageTextInputConfig guildId channelId =
    { gotPingUserPosition = GotPingUserPositionForEditMessage
    , textInputGotFocus = TextInputGotFocus
    , textInputLostFocus = TextInputLostFocus
    , typedMessage = TypedEditMessage guildId channelId
    , pressedSendMessage = PressedSendEditMessage guildId channelId
    , pressedArrowInDropdown = PressedArrowInDropdownForEditMessage guildId
    , pressedArrowUpInEmptyInput = FrontendNoOp
    , pressedPingUser = PressedPingUserForEditMessage guildId channelId
    }


editMessageTextInputId : HtmlId
editMessageTextInputId =
    Dom.id "editMessageTextInput"


messageViewHovered :
    Bool
    -> SeqDict Int (NonemptySet Int)
    -> LocalUser
    -> Int
    -> Message
    -> Element FrontendMsg
messageViewHovered isEditing revealedSpoilers localUser messageIndex message =
    messageView
        revealedSpoilers
        NoHighlight
        True
        isEditing
        localUser
        Nothing
        messageIndex
        message


messageViewNotHovered :
    Bool
    -> SeqDict Int (NonemptySet Int)
    -> LocalUser
    -> Int
    -> Message
    -> Element FrontendMsg
messageViewNotHovered isEditing revealedSpoilers localUser messageIndex message =
    messageView
        revealedSpoilers
        NoHighlight
        False
        isEditing
        localUser
        Nothing
        messageIndex
        message


type HighlightMessage
    = NoHighlight
    | ReplyToHighlight
    | MentionHighlight


messageView :
    SeqDict Int (NonemptySet Int)
    -> HighlightMessage
    -> Bool
    -> Bool
    -> LocalUser
    -> Maybe ( Int, Message )
    -> Int
    -> Message
    -> Element FrontendMsg
messageView revealedSpoilers highlight isHovered isBeingEdited localUser maybeRepliedTo messageIndex message =
    let
        --_ =
        --    Debug.log "changed" messageIndex
        allUsers : SeqDict (Id UserId) FrontendUser
        allUsers =
            LocalState.allUsers2 localUser
    in
    case message of
        UserTextMessage message2 ->
            messageContainer
                (case highlight of
                    NoHighlight ->
                        if RichText.mentionsUser localUser.userId message2.content then
                            MentionHighlight

                        else
                            highlight

                    _ ->
                        highlight
                )
                messageIndex
                (localUser.userId == message2.createdBy)
                localUser.userId
                message2.reactions
                isHovered
                [ repliedToMessage maybeRepliedTo revealedSpoilers allUsers
                , userToName message2.createdBy allUsers
                    ++ " "
                    |> Ui.text
                    |> Ui.el [ Ui.Font.bold ]
                , Html.div
                    [ Html.Attributes.style "white-space" "pre-wrap" ]
                    (RichText.view
                        (PressedSpoiler messageIndex)
                        (case SeqDict.get messageIndex revealedSpoilers of
                            Just nonempty ->
                                NonemptySet.toSeqSet nonempty

                            Nothing ->
                                SeqSet.empty
                        )
                        allUsers
                        message2.content
                        ++ (if isBeingEdited then
                                [ Html.span
                                    [ Html.Attributes.style "color" "rgb(200,200,200)"
                                    , Html.Attributes.style "font-size" "12px"
                                    ]
                                    [ Html.text " (editing...)" ]
                                ]

                            else
                                case message2.editedAt of
                                    Just editedAt ->
                                        [ Html.span
                                            [ Html.Attributes.style "color" "rgb(200,200,200)"
                                            , Html.Attributes.style "font-size" "12px"
                                            , MyUi.datestamp editedAt |> Html.Attributes.title
                                            ]
                                            [ Html.text " (edited)" ]
                                        ]

                                    Nothing ->
                                        []
                           )
                    )
                    |> Ui.html
                ]

        UserJoinedMessage _ userId reactions ->
            messageContainer
                highlight
                messageIndex
                False
                localUser.userId
                reactions
                isHovered
                [ userJoinedContent userId allUsers ]

        DeletedMessage ->
            Ui.el [ Ui.Font.color MyUi.font3, Ui.Font.italic ] (Ui.text "Message deleted")


repliedToMessage :
    Maybe ( Int, Message )
    -> SeqDict Int (NonemptySet Int)
    -> SeqDict (Id UserId) FrontendUser
    -> Element FrontendMsg
repliedToMessage maybeRepliedTo revealedSpoilers allUsers =
    case maybeRepliedTo of
        Just ( repliedToIndex, UserTextMessage repliedToData ) ->
            repliedToHeaderHelper
                (Html.div
                    [ Html.Attributes.style "white-space" "nowrap"
                    , Html.Attributes.style "overflow" "hidden"
                    , Html.Attributes.style "text-overflow" "ellipsis"
                    ]
                    (Html.span
                        [ Html.Attributes.style "color" "rgb(200,200,200)"
                        , Html.Attributes.style "padding" "0 6px 0 2px"
                        ]
                        [ Html.text (userToName repliedToData.createdBy allUsers) ]
                        :: RichText.view
                            (\_ -> FrontendNoOp)
                            (case SeqDict.get repliedToIndex revealedSpoilers of
                                Just set ->
                                    NonemptySet.toSeqSet set

                                Nothing ->
                                    SeqSet.empty
                            )
                            allUsers
                            repliedToData.content
                    )
                    |> Ui.html
                )

        Just ( _, UserJoinedMessage _ userId _ ) ->
            repliedToHeaderHelper (userJoinedContent userId allUsers)

        Just ( _, DeletedMessage ) ->
            Ui.none

        Nothing ->
            Ui.none


repliedToHeaderHelper : Element msg -> Element msg
repliedToHeaderHelper content =
    Ui.row
        [ Ui.Font.color MyUi.font1
        , Ui.Font.size 14
        , Ui.paddingWith { left = 0, right = 8, top = 2, bottom = 0 }
        ]
        [ Ui.el
            [ Ui.width (Ui.px 18)
            , Ui.move { x = 0, y = 3, z = 0 }
            ]
            (Ui.html Icons.reply)
        , content
        ]


userJoinedContent : Id UserId -> SeqDict (Id UserId) FrontendUser -> Element msg
userJoinedContent userId allUsers =
    Ui.Prose.paragraph
        [ Ui.paddingXY 0 4 ]
        [ userToName userId allUsers
            |> Ui.text
            |> Ui.el [ Ui.Font.bold ]
        , Ui.el
            []
            (Ui.text " joined!")
        ]


userToName : Id UserId -> SeqDict (Id UserId) FrontendUser -> String
userToName userId allUsers =
    case SeqDict.get userId allUsers of
        Just user ->
            PersonName.toString user.name

        Nothing ->
            "<missing>"


messageContainer :
    HighlightMessage
    -> Int
    -> Bool
    -> Id UserId
    -> SeqDict Emoji (NonemptySet (Id UserId))
    -> Bool
    -> List (Element FrontendMsg)
    -> Element FrontendMsg
messageContainer highlight messageIndex canEdit currentUserId reactions isHovered messageContent =
    let
        maybeReactions =
            reactionEmojiView messageIndex currentUserId reactions
    in
    Ui.column
        ([ Ui.Font.color MyUi.font1
         , Ui.Events.onMouseEnter (MouseEnteredMessage messageIndex)
         , Ui.Events.onMouseLeave (MouseExitedMessage messageIndex)
         , Ui.paddingWith
            { left = 8
            , right = 8
            , top = 4
            , bottom =
                if maybeReactions == Nothing then
                    8

                else
                    4
            }
         , Ui.spacing 4
         ]
            ++ (if isHovered then
                    [ case highlight of
                        NoHighlight ->
                            Ui.background MyUi.hoverHighlight

                        ReplyToHighlight ->
                            Ui.background MyUi.hoverAndReplyToColor

                        MentionHighlight ->
                            Ui.background MyUi.hoverAndMentionColor
                    , Ui.row
                        [ Ui.alignRight
                        , Ui.background MyUi.background1
                        , Ui.rounded 4
                        , Ui.borderColor MyUi.border1
                        , Ui.border 1
                        , Ui.move { x = -8, y = -16, z = 0 }
                        , Ui.height (Ui.px 32)
                        ]
                        [ messageHoverButton (PressedShowReactionEmojiSelector messageIndex) Icons.smile
                        , if canEdit then
                            messageHoverButton (PressedEditMessage messageIndex) Icons.pencil

                          else
                            Ui.none
                        , messageHoverButton (PressedReply messageIndex) Icons.reply
                        ]
                        |> Ui.inFront
                    ]

                else
                    case highlight of
                        NoHighlight ->
                            []

                        ReplyToHighlight ->
                            [ Ui.background MyUi.replyToColor ]

                        MentionHighlight ->
                            [ Ui.background MyUi.mentionColor ]
               )
        )
        (messageContent ++ Maybe.Extra.toList maybeReactions)


channelColumn :
    Id UserId
    -> BackendUser
    -> Id GuildId
    -> FrontendGuild
    -> ChannelRoute
    -> Maybe ( Id GuildId, Id ChannelId )
    -> Element FrontendMsg
channelColumn currentUserId currentUser guildId guild channelRoute channelNameHover =
    Ui.column
        [ Ui.height Ui.fill
        , Ui.background MyUi.background2
        ]
        [ Ui.row
            [ Ui.Font.bold
            , Ui.paddingWith { left = 8, right = 4, top = 0, bottom = 0 }
            , Ui.spacing 8
            , Ui.Font.color MyUi.font1
            , Ui.borderWith { left = 0, right = 0, top = 0, bottom = 1 }
            , Ui.borderColor MyUi.border1
            ]
            [ Ui.text (GuildName.toString guild.name)
            , Ui.el
                [ Ui.width Ui.shrink
                , Ui.Input.button (PressedLink (GuildRoute guildId InviteLinkCreatorRoute))
                , Ui.Font.color MyUi.font2
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

                                _ ->
                                    False

                        isHover : Bool
                        isHover =
                            channelNameHover == Just ( guildId, channelId )
                    in
                    Ui.row
                        [ if isSelected then
                            Ui.Font.color MyUi.font1

                          else
                            Ui.Font.color MyUi.font2
                        , Ui.attrIf isSelected (Ui.background (Ui.rgba 255 255 255 0.15))
                        , Ui.Events.onMouseEnter (MouseEnteredChannelName guildId channelId)
                        , Ui.Events.onMouseLeave (MouseExitedChannelName guildId channelId)
                        ]
                        [ Ui.row
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
                            [ Ui.el
                                [ channelHasNotifications currentUserId currentUser guildId channelId channel
                                    |> GuildIcon.notificationView MyUi.background2
                                , Ui.width (Ui.px 20)
                                , Ui.paddingWith { left = 0, right = 4, top = 0, bottom = 0 }
                                ]
                                (Ui.html Icons.hashtag)
                            , Ui.text (ChannelName.toString channel.name)
                            ]
                        , if isHover then
                            Ui.el
                                [ Ui.alignRight
                                , Ui.width (Ui.px 26)
                                , Ui.contentCenterY
                                , Ui.height Ui.fill
                                , Ui.paddingXY 4 0
                                , Ui.Font.color MyUi.font3
                                , Ui.Input.button
                                    (PressedLink (GuildRoute guildId (EditChannelRoute channelId)))
                                ]
                                (Ui.html Icons.gearIcon)

                          else
                            Ui.none
                        ]
                )
                (SeqDict.toList guild.channels)
                ++ [ if currentUserId == guild.owner then
                        let
                            isSelected =
                                channelRoute == NewChannelRoute
                        in
                        Ui.row
                            [ Ui.paddingXY 4 8
                            , Ui.Font.color MyUi.font3
                            , Ui.Input.button (PressedLink (GuildRoute guildId NewChannelRoute))
                            , Ui.attrIf isSelected (Ui.background (Ui.rgba 255 255 255 0.15))
                            , if isSelected then
                                Ui.Font.color MyUi.font1

                              else
                                Ui.Font.color MyUi.font3
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
        , Ui.background MyUi.background2
        ]
        [ Ui.el
            [ Ui.Font.bold
            , Ui.paddingXY 8 8
            , Ui.spacing 8
            , Ui.Font.color MyUi.font1
            , Ui.borderWith { left = 0, right = 0, top = 0, bottom = 1 }
            , Ui.borderColor MyUi.border1
            ]
            (Ui.text "Direct messages")
        ]


memberColumn : LocalState -> FrontendGuild -> Element FrontendMsg
memberColumn local guild =
    Ui.column
        [ Ui.height Ui.fill
        , Ui.alignRight
        , Ui.background MyUi.background2
        , Ui.Font.color MyUi.font1
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
        [ Ui.Font.color MyUi.font1, Ui.padding 16, Ui.alignTop, Ui.spacing 16 ]
        [ Ui.el [ Ui.Font.size 24 ] (Ui.text ("Edit #" ++ ChannelName.toString channel.name))
        , channelNameInput guildId form |> Ui.map (EditChannelFormChanged guildId channelId)
        , Ui.row
            [ Ui.spacing 16 ]
            [ Ui.el
                [ Ui.Input.button (PressedCancelEditChannelChanges guildId channelId)
                , Ui.paddingXY 16 8
                , Ui.background MyUi.cancelButtonBackground
                , Ui.width Ui.shrink
                , Ui.rounded 8
                , Ui.Font.color MyUi.buttonFontColor
                , Ui.Font.bold
                , Ui.borderColor MyUi.buttonBorder
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
            , Ui.background MyUi.deleteButtonBackground
            , Ui.width Ui.shrink
            , Ui.rounded 8
            , Ui.Font.color MyUi.deleteButtonFont
            , Ui.Font.bold
            , Ui.borderColor MyUi.buttonBorder
            , Ui.border 1
            ]
            (Ui.text "Delete channel")
        ]


newChannelFormView : Id GuildId -> NewChannelForm -> Element FrontendMsg
newChannelFormView guildId form =
    Ui.column
        [ Ui.Font.color MyUi.font1, Ui.padding 16, Ui.alignTop, Ui.spacing 16 ]
        [ Ui.el [ Ui.Font.size 24 ] (Ui.text "Create new channel")
        , channelNameInput guildId form |> Ui.map (NewChannelFormChanged guildId)
        , submitButton (PressedSubmitNewChannel guildId form) "Create channel"
        ]


submitButton : msg -> String -> Element msg
submitButton onPress text =
    Ui.el
        [ Ui.Input.button onPress
        , Ui.paddingXY 16 8
        , Ui.background MyUi.buttonBackground
        , Ui.width Ui.shrink
        , Ui.rounded 8
        , Ui.Font.color MyUi.buttonFontColor
        , Ui.Font.bold
        , Ui.borderColor MyUi.buttonBorder
        , Ui.border 1
        ]
        (Ui.text text)


channelNameInput : Id GuildId -> NewChannelForm -> Element NewChannelForm
channelNameInput guildId form =
    let
        nameLabel =
            Ui.Input.label
                "newChannelName"
                [ Ui.Font.color MyUi.font2, Ui.paddingXY 2 0 ]
                (Ui.text "Channel name")
    in
    Ui.column
        []
        [ nameLabel.element
        , Ui.Input.text
            [ Ui.padding 6
            , Ui.background MyUi.inputBackground
            , Ui.borderColor MyUi.inputBorder
            , Ui.widthMax 500
            ]
            { onChange = \text -> { form | name = text }
            , text = form.name
            , placeholder = Nothing
            , label = nameLabel.id
            }
        , case ( form.pressedSubmit, ChannelName.fromString form.name ) of
            ( True, Err error ) ->
                Ui.el [ Ui.paddingXY 2 0, Ui.Font.color MyUi.errorColor ] (Ui.text error)

            _ ->
                Ui.none
        ]
