module Types exposing
    ( AdminStatusLoginData(..)
    , BackendModel
    , BackendMsg(..)
    , FrontendModel(..)
    , FrontendMsg(..)
    , LastRequest(..)
    , LoadStatus(..)
    , LoadedFrontend
    , LoadingFrontend
    , LocalChange(..)
    , LocalMsg(..)
    , LoggedIn2
    , LoginData
    , LoginResult(..)
    , LoginStatus(..)
    , LoginTokenData(..)
    , ToBackend(..)
    , ToFrontend(..)
    )

import Array exposing (Array)
import Browser exposing (UrlRequest)
import Effect.Browser.Navigation exposing (Key)
import Effect.Lamdera exposing (ClientId, SessionId)
import Effect.Time as Time
import EmailAddress exposing (EmailAddress)
import Id exposing (Id, UserId)
import Local exposing (ChangeId, Local)
import LocalState exposing (LocalState)
import Log exposing (Log)
import LoginForm exposing (LoginForm)
import NonemptyDict exposing (NonemptyDict)
import Pages.Admin exposing (AdminChange, InitAdminData)
import Pages.UserOverview
import Postmark
import Route exposing (Route)
import SeqDict exposing (SeqDict)
import TwoFactorAuthentication exposing (TwoFactorAuthentication, TwoFactorAuthenticationSetup)
import Ui.Anim
import Url exposing (Url)
import User exposing (BackendUser)


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias LoadingFrontend =
    { navigationKey : Key
    , route : Route
    , windowSize : ( Int, Int )
    , time : Maybe Time.Posix
    , loginStatus : LoadStatus
    }


type LoadStatus
    = LoadingData
    | LoadSuccess LoginData
    | LoadError


type alias LoadedFrontend =
    { navigationKey : Key
    , route : Route
    , time : Time.Posix
    , windowSize : ( Int, Int )
    , loginStatus : LoginStatus
    , elmUiState : Ui.Anim.State
    , showMobileToolbar : Bool
    }


type LoginStatus
    = LoggedIn LoggedIn2
    | NotLoggedIn { loginForm : Maybe LoginForm }


type alias LoggedIn2 =
    { localState : Local LocalMsg LocalState
    , admin : Maybe Pages.Admin.Model
    , userOverview : SeqDict (Id UserId) Pages.UserOverview.Model
    }


type alias BackendModel =
    { users : NonemptyDict (Id UserId) BackendUser
    , sessions : SeqDict SessionId (Id UserId)
    , connections : SeqDict SessionId (NonemptyDict ClientId LastRequest)
    , secretCounter : Int
    , pendingLogins : SeqDict SessionId LoginTokenData
    , logs : Array { time : Time.Posix, log : Log }
    , emailNotificationsEnabled : Bool
    , lastErrorLogEmail : Time.Posix
    , -- This could be part of BackendUser but having it separate reduces the chances of leaking 2FA secrets to other users. We could also just derive a secret key from `Env.secretKey ++ Id.toString userId` but this would cause problems if we ever changed Env.secretKey for some reason.
      twoFactorAuthentication : SeqDict (Id UserId) TwoFactorAuthentication
    , twoFactorAuthenticationSetup : SeqDict (Id UserId) TwoFactorAuthenticationSetup
    }


type LastRequest
    = NoRequestsMade
    | LastRequest Time.Posix


type LoginTokenData
    = WaitingForLoginToken
        { creationTime : Time.Posix
        , userId : Id UserId
        , loginAttempts : Int
        , loginCode : Int
        }
    | WaitingForTwoFactorToken
        { creationTime : Time.Posix
        , userId : Id UserId
        , loginAttempts : Int
        }


type FrontendMsg
    = UrlClicked UrlRequest
    | UrlChanged Url
    | GotTime Time.Posix
    | GotWindowSize Int Int
    | ScrolledToTop
    | LoginFormMsg LoginForm.Msg
    | PressedShowLogin
    | AdminPageMsg Pages.Admin.Msg
    | PressedLogOut
    | ElmUiMsg Ui.Anim.Msg
    | ScrolledToLogSection
    | PressedLink Route
    | UserOverviewMsg Pages.UserOverview.Msg
    | PressedCollapseToolbar
    | PressedExpandToolbar


type ToBackend
    = CheckLoginRequest
    | LoginWithTokenRequest Int
    | LoginWithTwoFactorRequest Int
    | GetLoginTokenRequest EmailAddress
    | AdminToBackend Pages.Admin.ToBackend
    | LogOutRequest
    | LocalModelChangeRequest ChangeId LocalChange
    | UserOverviewToBackend Pages.UserOverview.ToBackend


type BackendMsg
    = SentLoginEmail Time.Posix EmailAddress (Result Postmark.SendEmailError ())
    | Connected SessionId ClientId
    | Disconnected SessionId ClientId
    | BackendGotTime SessionId ClientId ToBackend Time.Posix
    | SentLogErrorEmail Time.Posix EmailAddress (Result Postmark.SendEmailError ())


type LoginResult
    = LoginSuccess LoginData
    | LoginTokenInvalid Int
    | NeedsTwoFactorToken


type ToFrontend
    = CheckLoginResponse (Result () LoginData)
    | LoginWithTokenResponse LoginResult
    | GetLoginTokenRateLimited
    | LoggedOutSession
    | AdminToFrontend Pages.Admin.ToFrontend
    | LocalChangeResponse ChangeId LocalChange
    | ChangeBroadcast LocalMsg
    | UserOverviewToFrontend Pages.UserOverview.ToFrontend


type alias LoginData =
    { userId : Id UserId
    , adminData : AdminStatusLoginData
    , twoFactorAuthenticationEnabled : Maybe Time.Posix
    }


type AdminStatusLoginData
    = IsAdminLoginData InitAdminData
    | IsNotAdminLoginData LocalState.NotAdminData


type LocalMsg
    = LocalChange (Id UserId) LocalChange


type LocalChange
    = InvalidChange
    | AdminChange AdminChange
    | UserOverviewChange Pages.UserOverview.Change
