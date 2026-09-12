module Evergreen.V379.TwoFactorAuthentication exposing (..)

import Effect.Time
import Evergreen.V379.LoginForm
import Evergreen.V379.SecretId
import SeqDict


type Msg
    = PressedStart2FaSetup
    | PressedCopy String
    | TypedTwoFactorCode String
    | PressedStartDisable2Fa
    | PressedCancelDisable2Fa
    | TypedDisableTwoFactorCode String


type alias TwoFactorSetupData =
    { qrCodeUrl : String
    , code : String
    , attempts : SeqDict.SeqDict Int Evergreen.V379.LoginForm.CodeStatus
    }


type alias TwoFactorDisableData =
    { code : String
    , attempts : SeqDict.SeqDict Int Evergreen.V379.LoginForm.CodeStatus
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
    { secret : Evergreen.V379.SecretId.SecretId TwoFactorSecret
    , finishedAt : Effect.Time.Posix
    }


type alias TwoFactorAuthenticationSetup =
    { secret : Evergreen.V379.SecretId.SecretId TwoFactorSecret
    , startedAt : Effect.Time.Posix
    }


type ToBackend
    = EnableTwoFactorAuthenticationRequest
    | ConfirmTwoFactorAuthenticationRequest Int
    | DisableTwoFactorAuthenticationRequest Int
