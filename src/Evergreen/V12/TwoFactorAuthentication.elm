module Evergreen.V12.TwoFactorAuthentication exposing (..)

import Effect.Time
import Evergreen.V12.SecretId


type TwoFactorSecret
    = TwoFactorSecret Never


type alias TwoFactorAuthentication =
    { secret : Evergreen.V12.SecretId.SecretId TwoFactorSecret
    , finishedAt : Effect.Time.Posix
    }


type alias TwoFactorAuthenticationSetup =
    { secret : Evergreen.V12.SecretId.SecretId TwoFactorSecret
    , startedAt : Effect.Time.Posix
    }
