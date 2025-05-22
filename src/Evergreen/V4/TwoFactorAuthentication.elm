module Evergreen.V4.TwoFactorAuthentication exposing (..)

import Effect.Time
import Evergreen.V4.SecretId


type TwoFactorSecret
    = TwoFactorSecret Never


type alias TwoFactorAuthentication =
    { secret : Evergreen.V4.SecretId.SecretId TwoFactorSecret
    , finishedAt : Effect.Time.Posix
    }


type alias TwoFactorAuthenticationSetup =
    { secret : Evergreen.V4.SecretId.SecretId TwoFactorSecret
    , startedAt : Effect.Time.Posix
    }
