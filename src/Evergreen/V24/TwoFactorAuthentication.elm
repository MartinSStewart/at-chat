module Evergreen.V24.TwoFactorAuthentication exposing (..)

import Effect.Time
import Evergreen.V24.SecretId


type TwoFactorSecret
    = TwoFactorSecret Never


type alias TwoFactorAuthentication =
    { secret : Evergreen.V24.SecretId.SecretId TwoFactorSecret
    , finishedAt : Effect.Time.Posix
    }


type alias TwoFactorAuthenticationSetup =
    { secret : Evergreen.V24.SecretId.SecretId TwoFactorSecret
    , startedAt : Effect.Time.Posix
    }
