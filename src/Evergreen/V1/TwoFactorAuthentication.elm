module Evergreen.V1.TwoFactorAuthentication exposing (..)

import Effect.Time
import Evergreen.V1.SecretId


type TwoFactorSecret
    = TwoFactorSecret Never


type alias TwoFactorAuthentication =
    { secret : Evergreen.V1.SecretId.SecretId TwoFactorSecret
    , finishedAt : Effect.Time.Posix
    }


type alias TwoFactorAuthenticationSetup =
    { secret : Evergreen.V1.SecretId.SecretId TwoFactorSecret
    , startedAt : Effect.Time.Posix
    }
