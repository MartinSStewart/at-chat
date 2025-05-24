module Evergreen.V12.Pages.UserOverview exposing (..)

import Evergreen.V12.LoginForm
import Evergreen.V12.User
import SeqDict
import Time


type alias TwoFactorSetupData =
    { qrCodeUrl : String
    , code : String
    , attempts : SeqDict.SeqDict Int Evergreen.V12.LoginForm.CodeStatus
    }


type TwoFactorState
    = TwoFactorNotStarted
    | TwoFactorLoading
    | TwoFactorSetup TwoFactorSetupData
    | TwoFactorComplete
    | TwoFactorAlreadyComplete Time.Posix


type alias PersonalViewData =
    { twoFactorStatus : TwoFactorState
    }


type Model
    = PublicView
    | PersonalView PersonalViewData


type Msg
    = SelectedNotificationFrequency Evergreen.V12.User.EmailNotifications
    | PressedStart2FaSetup
    | PressedCopyError String
    | TypedTwoFactorCode String


type ToBackend
    = EnableTwoFactorAuthenticationRequest
    | ConfirmTwoFactorAuthenticationRequest Int


type ToFrontend
    = EnableTwoFactorAuthenticationResponse
        { qrCodeUrl : String
        }
    | ConfirmTwoFactorAuthenticationResponse Int Bool
