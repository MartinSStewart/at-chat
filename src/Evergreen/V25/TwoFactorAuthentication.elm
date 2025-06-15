module Evergreen.V25.TwoFactorAuthentication exposing (..)

import Effect.Time
import Evergreen.V25.SecretId


type TwoFactorSecret
    = TwoFactorSecret Never


type alias TwoFactorAuthentication =
    { secret : Evergreen.V25.SecretId.SecretId TwoFactorSecret
    , finishedAt : Effect.Time.Posix
    }


type alias TwoFactorAuthenticationSetup =
    { secret : Evergreen.V25.SecretId.SecretId TwoFactorSecret
    , startedAt : Effect.Time.Posix
    }
