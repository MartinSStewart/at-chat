module Evergreen.V7.TwoFactorAuthentication exposing (..)

import Effect.Time
import Evergreen.V7.SecretId


type TwoFactorSecret
    = TwoFactorSecret Never


type alias TwoFactorAuthentication =
    { secret : Evergreen.V7.SecretId.SecretId TwoFactorSecret
    , finishedAt : Effect.Time.Posix
    }


type alias TwoFactorAuthenticationSetup =
    { secret : Evergreen.V7.SecretId.SecretId TwoFactorSecret
    , startedAt : Effect.Time.Posix
    }
