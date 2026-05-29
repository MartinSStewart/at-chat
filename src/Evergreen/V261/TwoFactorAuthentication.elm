module Evergreen.V261.TwoFactorAuthentication exposing (..)

import Effect.Time
import Evergreen.V261.LoginForm
import Evergreen.V261.SecretId
import SeqDict


type alias TwoFactorSetupData =
    { qrCodeUrl : String
    , code : String
    , attempts : SeqDict.SeqDict Int Evergreen.V261.LoginForm.CodeStatus
    }


type alias TwoFactorDisableData =
    { code : String
    , attempts : SeqDict.SeqDict Int Evergreen.V261.LoginForm.CodeStatus
    }


type TwoFactorState
    = TwoFactorNotStarted
    | TwoFactorLoading
    | TwoFactorSetup TwoFactorSetupData
    | TwoFactorComplete
    | TwoFactorAlreadyComplete Effect.Time.Posix
    | TwoFactorDisable Effect.Time.Posix TwoFactorDisableData


type ToFrontend
    = EnableTwoFactorAuthenticationResponse
        { qrCodeUrl : String
        }
    | ConfirmTwoFactorAuthenticationResponse Int Bool
    | DisableTwoFactorAuthenticationResponse Int Bool


type TwoFactorSecret
    = TwoFactorSecret Never


type alias TwoFactorAuthentication =
    { secret : Evergreen.V261.SecretId.SecretId TwoFactorSecret
    , finishedAt : Effect.Time.Posix
    }


type alias TwoFactorAuthenticationSetup =
    { secret : Evergreen.V261.SecretId.SecretId TwoFactorSecret
    , startedAt : Effect.Time.Posix
    }


type Msg
    = PressedStart2FaSetup
    | PressedCopy String
    | TypedTwoFactorCode String
    | PressedStartDisable2Fa
    | PressedCancelDisable2Fa
    | TypedDisableTwoFactorCode String


type ToBackend
    = EnableTwoFactorAuthenticationRequest
    | ConfirmTwoFactorAuthenticationRequest Int
    | DisableTwoFactorAuthenticationRequest Int
