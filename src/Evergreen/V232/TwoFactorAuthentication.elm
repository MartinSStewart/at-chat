module Evergreen.V232.TwoFactorAuthentication exposing (..)

import Effect.Time
import Evergreen.V232.LoginForm
import Evergreen.V232.SecretId
import SeqDict


type alias TwoFactorSetupData =
    { qrCodeUrl : String
    , code : String
    , attempts : SeqDict.SeqDict Int Evergreen.V232.LoginForm.CodeStatus
    }


type TwoFactorState
    = TwoFactorNotStarted
    | TwoFactorLoading
    | TwoFactorSetup TwoFactorSetupData
    | TwoFactorComplete
    | TwoFactorAlreadyComplete Effect.Time.Posix


type ToFrontend
    = EnableTwoFactorAuthenticationResponse
        { qrCodeUrl : String
        }
    | ConfirmTwoFactorAuthenticationResponse Int Bool


type TwoFactorSecret
    = TwoFactorSecret Never


type alias TwoFactorAuthentication =
    { secret : Evergreen.V232.SecretId.SecretId TwoFactorSecret
    , finishedAt : Effect.Time.Posix
    }


type alias TwoFactorAuthenticationSetup =
    { secret : Evergreen.V232.SecretId.SecretId TwoFactorSecret
    , startedAt : Effect.Time.Posix
    }


type Msg
    = PressedStart2FaSetup
    | PressedCopy String
    | TypedTwoFactorCode String


type ToBackend
    = EnableTwoFactorAuthenticationRequest
    | ConfirmTwoFactorAuthenticationRequest Int
