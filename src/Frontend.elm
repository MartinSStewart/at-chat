module Frontend exposing (app, app_)

import Array
import Browser exposing (UrlRequest(..))
import Browser.Navigation
import ChannelName
import CssPixels
import Diff
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
import GuildIcon
import GuildName
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Icons
import Id exposing (ChannelId, GuildId, Id, UserId)
import Json.Decode
import Lamdera as LamderaCore
import List.Extra
import List.Nonempty exposing (Nonempty)
import Local exposing (Local)
import LocalState exposing (AdminStatus(..), BackendChannel, BackendGuild, FrontendChannel, FrontendGuild, LocalState, Message(..))
import LoginForm
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
import SeqSet
import String.Nonempty exposing (NonemptyString)
import Types exposing (AdminStatusLoginData(..), EmojiSelector(..), FrontendModel(..), FrontendMsg(..), LoadStatus(..), LoadedFrontend, LoadingFrontend, LocalChange(..), LocalMsg(..), LoggedIn2, LoginData, LoginResult(..), LoginStatus(..), MessageId, NewChannelForm, ServerChange(..), ToBackend(..), ToBeFilledInByBackend(..), ToFrontend(..))
import Ui exposing (Element)
import Ui.Anim
import Ui.Events
import Ui.Font
import Ui.Input
import Ui.Lazy
import Ui.Prose
import Ui.Shadow
import Url exposing (Url)
import User exposing (FrontendUser)


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
        , Time.every Duration.second GotTime
        , Effect.Browser.Events.onKeyDown (Json.Decode.field "key" Json.Decode.string |> Json.Decode.map KeyDown)
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
            , textInputFocus = Nothing
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
            , typingDebouncer = True
            , pingUser = Nothing
            , messageHover = Nothing
            , showEmojiSelector = EmojiSelectorHidden
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
                                (Maybe.map Local_UserOverview maybeChange)
                                { loggedIn | userOverview = SeqDict.insert userId userOverview2 loggedIn.userOverview }
                                (Command.map UserOverviewToBackend UserOverviewMsg cmd)

                        _ ->
                            ( loggedIn, Command.none )
                )
                model

        TypedMessage guildId channelId text ->
            updateLoggedIn
                (\loggedIn ->
                    multilineUpdate
                        guildId
                        channelId
                        channelTextInputId
                        text
                        (case SeqDict.get ( guildId, channelId ) loggedIn.drafts of
                            Just nonempty ->
                                String.Nonempty.toString nonempty

                            Nothing ->
                                ""
                        )
                        loggedIn
                        model
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
                                    (RichText.fromNonemptyString
                                        (LocalState.allUsers local)
                                        nonempty
                                    )
                                    |> Just
                                )
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
                    handleLocalChange
                        model.time
                        (Local_DeleteChannel guildId channelId |> Just)
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
                    let
                        local : LocalState
                        local =
                            Local.model loggedIn.localState
                    in
                    case
                        ( loggedIn.pingUser
                        , userDropdownList guildId local
                            |> List.Extra.getAt index
                        )
                    of
                        ( Just { charIndex }, Just ( _, user ) ) ->
                            let
                                applyText : NonemptyString -> NonemptyString
                                applyText text =
                                    let
                                        name : String
                                        name =
                                            PersonName.toString user.name

                                        text2 =
                                            String.Nonempty.toString text

                                        followingText : String
                                        followingText =
                                            String.foldl
                                                (\char ( name2, chars ) ->
                                                    case name2 of
                                                        head :: rest ->
                                                            if Char.toLower head == Char.toLower char then
                                                                ( rest, chars )

                                                            else
                                                                ( [], char :: chars )

                                                        [] ->
                                                            ( [], char :: chars )
                                                )
                                                ( String.toList name, [] )
                                                (String.dropLeft (charIndex + 1) text2)
                                                |> Tuple.second
                                                |> List.reverse
                                                |> String.fromList
                                    in
                                    String.left (charIndex + 1) text2
                                        ++ name
                                        ++ followingText
                                        |> String.Nonempty.fromString
                                        |> Maybe.withDefault text
                            in
                            ( { loggedIn
                                | pingUser = Nothing
                                , drafts =
                                    SeqDict.updateIfExists
                                        ( guildId, channelId )
                                        applyText
                                        loggedIn.drafts
                              }
                            , Dom.focus channelTextInputId
                                |> Task.attempt (\_ -> SetFocus)
                            )

                        _ ->
                            ( { loggedIn | pingUser = Nothing }, Command.none )
                )
                model

        SetFocus ->
            ( model, Command.none )

        PressedArrowInDropdown guildId index ->
            updateLoggedIn
                (\loggedIn ->
                    ( case loggedIn.pingUser of
                        Just pingUser ->
                            let
                                local : LocalState
                                local =
                                    Local.model loggedIn.localState
                            in
                            { loggedIn
                                | pingUser =
                                    { pingUser
                                        | dropdownIndex =
                                            if index < 0 then
                                                List.length (userDropdownList guildId local) - 1

                                            else if index >= List.length (userDropdownList guildId local) then
                                                0

                                            else
                                                index
                                    }
                                        |> Just
                            }

                        Nothing ->
                            loggedIn
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
                                    , Dom.focus channelTextInputId |> Task.attempt (\_ -> SetFocus)
                                    )

                                Nothing ->
                                    ( { loggedIn | showEmojiSelector = EmojiSelectorHidden }, Command.none )
                        )
                        model

                _ ->
                    ( model, Command.none )

        RemovedFocus ->
            ( model, Command.none )

        MouseEnteredMessage messageId ->
            updateLoggedIn
                (\loggedIn -> ( { loggedIn | messageHover = Just messageId }, Command.none ))
                model

        MouseExitedMessage messageId ->
            updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn
                        | messageHover =
                            if Just messageId == loggedIn.messageHover then
                                Nothing

                            else
                                loggedIn.messageHover
                      }
                    , Command.none
                    )
                )
                model

        PressedShowReactionEmojiSelector messageId ->
            updateLoggedIn
                (\loggedIn ->
                    ( { loggedIn | showEmojiSelector = EmojiSelectorForReaction messageId }
                    , Command.none
                    )
                )
                model

        PressedEditMessage messageId ->
            updateLoggedIn
                (\loggedIn ->
                    ( loggedIn
                    , Command.none
                    )
                )
                model

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
                                loggedIn
                                Command.none

                        EmojiSelectorForMessage ->
                            Debug.todo ""
                )
                model

        PressedReactionEmoji_Add messageId emoji ->
            updateLoggedIn
                (\loggedIn ->
                    handleLocalChange
                        model.time
                        (Local_AddReactionEmoji messageId emoji |> Just)
                        loggedIn
                        Command.none
                )
                model

        PressedReactionEmoji_Remove messageId emoji ->
            updateLoggedIn
                (\loggedIn ->
                    handleLocalChange
                        model.time
                        (Local_RemoveReactionEmoji messageId emoji |> Just)
                        loggedIn
                        Command.none
                )
                model


userDropdownList : Id GuildId -> LocalState -> List ( Id UserId, FrontendUser )
userDropdownList guildId local =
    case SeqDict.get guildId local.guilds of
        Just guild ->
            let
                allUsers : SeqDict (Id UserId) FrontendUser
                allUsers =
                    LocalState.allUsers local
            in
            guild.owner
                :: SeqDict.keys guild.members
                |> List.filterMap
                    (\userId ->
                        case SeqDict.get userId allUsers of
                            Just user ->
                                Just ( userId, user )

                            Nothing ->
                                Nothing
                    )
                |> List.sortBy (\( _, user ) -> PersonName.toString user.name)

        Nothing ->
            []


multilineUpdate :
    Id GuildId
    -> Id ChannelId
    -> HtmlId
    -> String
    -> String
    -> LoggedIn2
    -> LoadedFrontend
    -> ( LoggedIn2, Command FrontendOnly ToBackend FrontendMsg )
multilineUpdate guildId channelId multilineId text oldText loggedIn model =
    let
        oldAtCount : Int
        oldAtCount =
            List.length (String.indexes "@" oldText)

        atCount : Int
        atCount =
            List.length (String.indexes "@" text)

        typedAtSymbol : Maybe Int
        typedAtSymbol =
            if
                (atCount > oldAtCount)
                    && -- Detect if the user is pasting in text and if they are, abort the @mention dropdown
                       (String.length text - String.length oldText < 3)
            then
                case newAtSymbol oldText text of
                    Just { index } ->
                        let
                            previous =
                                String.slice (index - 1) index text
                        in
                        if index == 0 || previous == " " || previous == "\n" then
                            Just index

                        else
                            Nothing

                    Nothing ->
                        Nothing

            else
                Nothing
    in
    handleLocalChange
        model.time
        (if loggedIn.typingDebouncer then
            Local_MemberTyping model.time guildId channelId |> Just

         else
            Nothing
        )
        { loggedIn
            | pingUser =
                if oldAtCount > atCount then
                    Nothing

                else
                    loggedIn.pingUser
            , drafts =
                case String.Nonempty.fromString text of
                    Just nonempty ->
                        SeqDict.insert ( guildId, channelId ) nonempty loggedIn.drafts

                    Nothing ->
                        SeqDict.remove ( guildId, channelId ) loggedIn.drafts
            , typingDebouncer = False
        }
        (Command.batch
            [ case typedAtSymbol of
                Just index ->
                    Dom.getElement multilineId
                        |> Task.map
                            (\{ element } ->
                                { dropdownIndex = 0
                                , charIndex = index
                                , inputElement = element
                                }
                            )
                        |> Task.attempt GotPingUserPosition

                Nothing ->
                    Command.none
            , Process.sleep (Duration.seconds 1)
                |> Task.perform (\() -> DebouncedTyping)
            ]
        )



--handleLocalChange
--model.time
--(if loggedIn.typingDebouncer then
--    Local_MemberTyping model.time guildId channelId |> Just
--
-- else
--    Nothing
--)
--{ loggedIn
--    | drafts =
--        case String.Nonempty.fromString text of
--            Just nonempty ->
--                SeqDict.insert ( guildId, channelId ) nonempty loggedIn.drafts
--
--            Nothing ->
--                SeqDict.remove ( guildId, channelId ) loggedIn.drafts
--    , typingDebouncer = False
--}


newAtSymbol : String -> String -> Maybe { index : Int }
newAtSymbol oldText text =
    List.foldl
        (\change state ->
            case change of
                Diff.Added char ->
                    if char == '@' then
                        { index = state.index + 1
                        , foundAtSymbol = Just { index = state.index }
                        }

                    else
                        case state.foundAtSymbol of
                            Just found ->
                                { index = state.index + 1
                                , foundAtSymbol = Just { index = found.index }
                                }

                            Nothing ->
                                { index = state.index + 1
                                , foundAtSymbol = state.foundAtSymbol
                                }

                _ ->
                    { index = state.index + 1
                    , foundAtSymbol = state.foundAtSymbol
                    }
        )
        { index = 0, foundAtSymbol = Nothing }
        (Diff.diff (String.toList oldText) (String.toList text))
        |> .foundAtSymbol


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

                Local_UserOverview userOverviewChange ->
                    case userOverviewChange of
                        Pages.UserOverview.EmailNotificationsChange emailNotifications ->
                            let
                                user =
                                    local.user
                            in
                            { local
                                | user = { user | emailNotifications = emailNotifications }
                            }

                Local_SendMessage createdAt guildId channelId text ->
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
                                                                    , reactions = SeqDict.empty
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

                Local_NewChannel time guildId channelName ->
                    { local
                        | guilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.createChannelFrontend time local.userId channelName)
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
                                        (LocalState.addInvite inviteLinkId2 local.userId time)
                                        local.guilds
                            }

                Local_MemberTyping time guildId channelId ->
                    { local
                        | guilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.memberIsTyping local.userId time channelId)
                                local.guilds
                    }

                Local_AddReactionEmoji messageId emoji ->
                    { local
                        | guilds =
                            SeqDict.updateIfExists
                                messageId.guildId
                                (LocalState.addReactionEmoji
                                    emoji
                                    local.userId
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
                                    local.userId
                                    messageId.channelId
                                    messageId.messageIndex
                                )
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
                                                                    , createdBy = userId
                                                                    , content = text
                                                                    , reactions = SeqDict.empty
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

        Local_UserOverview _ ->
            "Changed user profile"

        Local_SendMessage _ _ _ _ ->
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
                                        GuildRoute guildId NoChannelRoute ->
                                            case SeqDict.get guildId local.guilds of
                                                Just guild ->
                                                    case pingDropdown guildId guild.announcementChannel local loggedIn of
                                                        Just element ->
                                                            Ui.inFront element

                                                        Nothing ->
                                                            Ui.noAttr

                                                Nothing ->
                                                    Ui.noAttr

                                        GuildRoute guildId (ChannelRoute channelId) ->
                                            case pingDropdown guildId channelId local loggedIn of
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
                                conversationView guildId channelId loggedIn model local channel

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
                                conversationView
                                    guildId
                                    guild.announcementChannel
                                    loggedIn
                                    model
                                    local
                                    channel

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


channelTextInputId : HtmlId
channelTextInputId =
    Dom.id "channel_textinput"


emojiSelector : Element FrontendMsg
emojiSelector =
    Ui.column
        [ Ui.width (Ui.px (8 * 32 + 21))
        , Ui.height (Ui.px 400)
        , Ui.scrollable
        , Ui.background background1
        , Ui.border 1
        , Ui.borderColor border1
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
        |> Ui.el [ Ui.alignBottom, Ui.paddingXY 8 0 ]


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
        userIdToName : Id UserId -> String
        userIdToName userId =
            case SeqDict.get userId local.otherUsers of
                Just user ->
                    PersonName.toString user.name

                Nothing ->
                    "<missing>"
    in
    Ui.column
        [ Ui.height Ui.fill ]
        [ Ui.el
            [ Ui.height Ui.fill
            , Ui.scrollable
            , case loggedIn.showEmojiSelector of
                EmojiSelectorHidden ->
                    Ui.noAttr

                EmojiSelectorForReaction _ ->
                    Ui.inFront emojiSelector

                EmojiSelectorForMessage ->
                    Ui.inFront emojiSelector
            ]
            (Ui.column
                [ Ui.height Ui.fill, Ui.paddingXY 0 16, Ui.scrollable ]
                (Ui.el
                    [ Ui.Font.color font2, Ui.paddingXY 8 4 ]
                    (Ui.text ("This is the start of #" ++ ChannelName.toString channel.name))
                    :: List.indexedMap
                        (\index message ->
                            case loggedIn.messageHover of
                                Just messageHover ->
                                    let
                                        messageId : MessageId
                                        messageId =
                                            { guildId = guildId
                                            , channelId = channelId
                                            , messageIndex = index
                                            }
                                    in
                                    if messageId == messageHover then
                                        Ui.Lazy.lazy5
                                            messageViewHovered
                                            guildId
                                            channelId
                                            local
                                            index
                                            message

                                    else
                                        Ui.Lazy.lazy5
                                            messageViewNotHovered
                                            guildId
                                            channelId
                                            local
                                            index
                                            message

                                Nothing ->
                                    Ui.Lazy.lazy5
                                        messageViewNotHovered
                                        guildId
                                        channelId
                                        local
                                        index
                                        message
                        )
                        (Array.toList channel.messages)
                )
            )
        , channelTextInput guildId channelId channel loggedIn local
            |> Ui.el [ Ui.paddingXY 8 0 ]
        , (case
            SeqDict.filter
                (\_ time ->
                    Duration.from time model.time |> Quantity.lessThan (Duration.seconds 3)
                )
                (SeqDict.remove local.userId channel.lastTypedAt)
                |> SeqDict.keys
           of
            [] ->
                ""

            [ single ] ->
                userIdToName single ++ " is typing..."

            [ one, two ] ->
                userIdToName one ++ " and " ++ userIdToName two ++ " are typing..."

            [ one, two, three ] ->
                userIdToName one
                    ++ ", "
                    ++ userIdToName two
                    ++ ", and "
                    ++ userIdToName three
                    ++ " are typing..."

            _ :: _ :: _ :: _ ->
                "Several people are typing..."
          )
            |> Ui.text
            |> Ui.el
                [ Ui.Font.bold
                , Ui.Font.size 13
                , Ui.Font.color font3
                , Ui.height (Ui.px 18)
                , Ui.contentCenterY
                , Ui.paddingXY 12 0
                ]
        ]


channelTextInput : Id GuildId -> Id ChannelId -> FrontendChannel -> LoggedIn2 -> LocalState -> Element FrontendMsg
channelTextInput guildId channelId channel loggedIn local =
    let
        text : String
        text =
            case SeqDict.get ( guildId, channelId ) loggedIn.drafts of
                Just nonempty ->
                    String.Nonempty.toString nonempty

                Nothing ->
                    ""
    in
    Html.div
        [ Html.Attributes.style "display" "flex"
        , Html.Attributes.style "position" "relative"
        , Html.Attributes.style "min-height" "min-content"
        , Html.Attributes.style "width" "100%"
        ]
        [ Html.textarea
            [ Html.Attributes.style "color" "rgba(255,0,0,1)"
            , Html.Attributes.style "position" "absolute"
            , Html.Attributes.style "font-size" "inherit"
            , Html.Attributes.style "font-family" "inherit"
            , Html.Attributes.style "line-height" "inherit"
            , Html.Attributes.style "width" "calc(100% - 18px)"
            , Html.Attributes.style "height" "calc(100% - 2px)"
            , Dom.idToAttribute channelTextInputId
            , Html.Attributes.style "background-color" "rgb(32,40,70)"
            , Html.Attributes.style "border" "solid 1px rgb(60,70,100)"
            , Html.Attributes.style "border-radius" "4px"
            , Html.Attributes.style "resize" "none"
            , Html.Attributes.style "overflow" "hidden"
            , Html.Attributes.style "caret-color" "white"
            , Html.Attributes.style "padding" "8px"
            , Html.Events.onFocus (TextInputGotFocus channelTextInputId)
            , Html.Events.onBlur (TextInputLostFocus channelTextInputId)
            , case loggedIn.pingUser of
                Just { dropdownIndex } ->
                    Html.Events.preventDefaultOn
                        "keydown"
                        (Json.Decode.andThen
                            (\key ->
                                case key of
                                    "ArrowDown" ->
                                        Json.Decode.succeed ( PressedArrowInDropdown guildId (dropdownIndex + 1), True )

                                    "ArrowUp" ->
                                        Json.Decode.succeed ( PressedArrowInDropdown guildId (dropdownIndex - 1), True )

                                    "Enter" ->
                                        Json.Decode.succeed
                                            ( PressedPingUser guildId channelId dropdownIndex, True )

                                    _ ->
                                        Json.Decode.fail ""
                            )
                            (Json.Decode.field "key" Json.Decode.string)
                        )

                Nothing ->
                    Html.Events.preventDefaultOn
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
            , Html.Events.onInput (TypedMessage guildId channelId)
            , Html.Attributes.value text
            ]
            []
        , Html.div
            [ Html.Attributes.style "pointer-events" "none"
            , Html.Attributes.style "padding" "0 9px 0 9px"
            , Html.Attributes.style "transform" "translateY(9px)"
            , Html.Attributes.style "white-space" "pre-wrap"
            , Html.Attributes.style "color"
                (if text == "" then
                    "rgb(180,180,180)"

                 else
                    "rgb(255,255,255)"
                )
            ]
            (case String.Nonempty.fromString text of
                Just nonempty ->
                    let
                        users =
                            LocalState.allUsers local
                    in
                    RichText.textInputView users (RichText.fromNonemptyString users nonempty)
                        ++ [ Html.text "\n" ]

                Nothing ->
                    [ "Write a message in #"
                        ++ ChannelName.toString channel.name
                        |> Html.text
                    ]
            )
        ]
        |> Ui.html


dropdownButtonId : Int -> HtmlId
dropdownButtonId index =
    Dom.id ("dropdown_button" ++ String.fromInt index)


pingDropdown : Id GuildId -> Id ChannelId -> LocalState -> LoggedIn2 -> Maybe (Element FrontendMsg)
pingDropdown guildId channelId localState model =
    case model.pingUser of
        Just { dropdownIndex, inputElement } ->
            Ui.column
                [ Ui.background background2
                , Ui.borderColor border1
                , Ui.border 1
                , Ui.Font.color font2
                , Ui.move
                    { x = round inputElement.x
                    , y = round (inputElement.y - 400 + 1)
                    , z = 0
                    }
                , Ui.width (Ui.px (round inputElement.width))
                , Ui.height (Ui.px 400)
                , Ui.clip
                , Ui.roundedWith { topLeft = 8, topRight = 8, bottomLeft = 0, bottomRight = 0 }

                --, Ui.Shadow.shadows [ { x = 0, y = 1, size = 0, blur = 4, color = Ui.rgba 0 0 0 0.2 } ]
                ]
                [ Ui.el [ Ui.Font.size 14, Ui.Font.bold, Ui.paddingXY 8 2 ] (Ui.text "Mention a user:")
                , Ui.column
                    []
                    (List.indexedMap
                        (\index ( _, user ) ->
                            Ui.el
                                [ Ui.Input.button (PressedPingUser guildId channelId index)
                                , Ui.Events.onMouseDown (PressedPingUser guildId channelId index)
                                , MyUi.touchPress (PressedPingUser guildId channelId index)
                                , Ui.id (Dom.idToString (dropdownButtonId index))
                                , Ui.paddingXY 8 4
                                , Ui.Anim.focused (Ui.Anim.ms 100) [ Ui.Anim.backgroundColor background3 ]
                                , if dropdownIndex == index then
                                    Ui.background background3

                                  else
                                    Ui.noAttr
                                , Html.Events.on
                                    "keydown"
                                    (Json.Decode.field "key" Json.Decode.string
                                        |> Json.Decode.andThen
                                            (\key ->
                                                if key == "ArrowDown" then
                                                    Json.Decode.succeed (PressedArrowInDropdown guildId (index + 1))

                                                else if key == "ArrowUp" then
                                                    Json.Decode.succeed (PressedArrowInDropdown guildId (index - 1))

                                                else
                                                    Json.Decode.fail ""
                                            )
                                    )
                                    |> Ui.htmlAttribute
                                ]
                                (Ui.text (PersonName.toString user.name))
                        )
                        (userDropdownList guildId localState)
                    )
                ]
                |> Just

        Nothing ->
            Nothing


messageHoverButton : msg -> Html msg -> Element msg
messageHoverButton onPress svg =
    Ui.el
        [ Ui.width (Ui.px 32)
        , Ui.paddingXY 4 3
        , Ui.height Ui.fill
        , Ui.Input.button onPress
        ]
        (Ui.html svg)


reactionEmojiView : MessageId -> Id UserId -> SeqDict Emoji (NonemptySet (Id UserId)) -> Element FrontendMsg
reactionEmojiView messageId currentUserId reactions =
    if SeqDict.isEmpty reactions then
        Ui.none

    else
        Ui.row
            [ Ui.paddingWith { left = 16, right = 16, top = 0, bottom = 4 }, Ui.wrap, Ui.spacing 4 ]
            (List.map
                (\( emoji, users ) ->
                    let
                        hasReactedTo : Bool
                        hasReactedTo =
                            NonemptySet.member currentUserId users
                    in
                    Ui.row
                        [ Ui.rounded 8
                        , Ui.background background1
                        , Ui.paddingWith { left = 1, right = 4, top = 0, bottom = 0 }
                        , Ui.borderColor
                            (if hasReactedTo then
                                highlightedBorder

                             else
                                border1
                            )
                        , Ui.Font.color
                            (if hasReactedTo then
                                highlightedBorder

                             else
                                font2
                            )
                        , Ui.border 1
                        , Ui.width Ui.shrink
                        , Ui.Font.bold
                        , Ui.Input.button
                            (if hasReactedTo then
                                PressedReactionEmoji_Remove messageId emoji

                             else
                                PressedReactionEmoji_Add messageId emoji
                            )
                        ]
                        [ Emoji.view emoji, Ui.text (String.fromInt (NonemptySet.size users)) ]
                )
                (SeqDict.toList reactions)
            )


messageViewHovered : Id GuildId -> Id ChannelId -> LocalState -> Int -> Message -> Element FrontendMsg
messageViewHovered guildId channelId local messageIndex message =
    messageView guildId channelId True local messageIndex message


messageViewNotHovered : Id GuildId -> Id ChannelId -> LocalState -> Int -> Message -> Element FrontendMsg
messageViewNotHovered guildId channelId local messageIndex message =
    messageView guildId channelId False local messageIndex message


messageView :
    Id GuildId
    -> Id ChannelId
    -> Bool
    -> LocalState
    -> Int
    -> Message
    -> Element FrontendMsg
messageView guildId channelId isHovered local messageIndex message =
    let
        _ =
            Debug.log "changed" messageIndex
    in
    case message of
        UserTextMessage message2 ->
            messageContainer
                guildId
                channelId
                messageIndex
                (local.userId == message2.createdBy)
                local.userId
                message2.reactions
                isHovered
                (Ui.Prose.paragraph
                    [ Ui.paddingXY 8 10 ]
                    (Ui.el
                        [ Ui.Font.bold ]
                        (case LocalState.getUser message2.createdBy local of
                            Just user ->
                                Ui.text (PersonName.toString user.name ++ " ")

                            Nothing ->
                                Ui.text "<missing> "
                        )
                        :: RichText.richTextView (LocalState.allUsers local) message2.content
                    )
                )

        UserJoinedMessage _ userId reactions ->
            messageContainer
                guildId
                channelId
                messageIndex
                False
                local.userId
                reactions
                isHovered
                (Ui.Prose.paragraph
                    [ Ui.paddingXY 8 10 ]
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
                )

        DeletedMessage ->
            Ui.el [ Ui.Font.color font3, Ui.Font.italic ] (Ui.text "Message deleted")


messageContainer :
    Id GuildId
    -> Id ChannelId
    -> Int
    -> Bool
    -> Id UserId
    -> SeqDict Emoji (NonemptySet (Id UserId))
    -> Bool
    -> Element FrontendMsg
    -> Element FrontendMsg
messageContainer guildId channelId messageIndex canEdit currentUserId reactions isHovered messageContent =
    let
        messageId : MessageId
        messageId =
            { guildId = guildId
            , channelId = channelId
            , messageIndex = messageIndex
            }
    in
    Ui.column
        ([ Ui.Font.color font1
         , Ui.Events.onMouseEnter (MouseEnteredMessage messageId)
         , Ui.Events.onMouseLeave (MouseExitedMessage messageId)
         ]
            ++ (if isHovered then
                    [ Ui.background (Ui.rgba 255 255 255 0.1)
                    , Ui.row
                        [ Ui.alignRight
                        , Ui.background background1
                        , Ui.rounded 4
                        , Ui.borderColor border1
                        , Ui.border 1
                        , Ui.move { x = -8, y = -16, z = 0 }
                        , Ui.height (Ui.px 32)
                        ]
                        [ messageHoverButton (PressedShowReactionEmojiSelector messageId) Icons.smile
                        , if canEdit then
                            messageHoverButton (PressedEditMessage messageId) Icons.pencil

                          else
                            Ui.none
                        ]
                        |> Ui.inFront
                    ]

                else
                    []
               )
        )
        [ messageContent
        , reactionEmojiView messageId currentUserId reactions
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


highlightedBorder : Ui.Color
highlightedBorder =
    Ui.rgb 12 140 200


errorColor =
    Ui.rgb 240 170 180
