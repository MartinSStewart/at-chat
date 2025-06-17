module Evergreen.V32.Pages.UserOverview exposing (..)

import Evergreen.V32.LoginForm
import Evergreen.V32.User
import SeqDict
import Time


type alias TwoFactorSetupData =
    { qrCodeUrl : String
    , code : String
    , attempts : SeqDict.SeqDict Int Evergreen.V32.LoginForm.CodeStatus
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
    = SelectedNotificationFrequency Evergreen.V32.User.EmailNotifications
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
