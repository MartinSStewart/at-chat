module Evergreen.V7.Pages.UserOverview exposing (..)

import Evergreen.V7.LoginForm
import Evergreen.V7.User
import SeqDict
import Time


type alias TwoFactorSetupData =
    { qrCodeUrl : String
    , code : String
    , attempts : SeqDict.SeqDict Int Evergreen.V7.LoginForm.CodeStatus
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
    = SelectedNotificationFrequency Evergreen.V7.User.EmailNotifications
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
