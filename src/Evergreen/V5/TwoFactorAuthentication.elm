module Evergreen.V5.TwoFactorAuthentication exposing (..)

import Effect.Time
import Evergreen.V5.SecretId


type TwoFactorSecret
    = TwoFactorSecret Never


type alias TwoFactorAuthentication =
    { secret : Evergreen.V5.SecretId.SecretId TwoFactorSecret
    , finishedAt : Effect.Time.Posix
    }


type alias TwoFactorAuthenticationSetup =
    { secret : Evergreen.V5.SecretId.SecretId TwoFactorSecret
    , startedAt : Effect.Time.Posix
    }
