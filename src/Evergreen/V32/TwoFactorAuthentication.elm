module Evergreen.V32.TwoFactorAuthentication exposing (..)

import Effect.Time
import Evergreen.V32.SecretId


type TwoFactorSecret
    = TwoFactorSecret Never


type alias TwoFactorAuthentication =
    { secret : Evergreen.V32.SecretId.SecretId TwoFactorSecret
    , finishedAt : Effect.Time.Posix
    }


type alias TwoFactorAuthenticationSetup =
    { secret : Evergreen.V32.SecretId.SecretId TwoFactorSecret
    , startedAt : Effect.Time.Posix
    }
