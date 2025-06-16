module Evergreen.V29.TwoFactorAuthentication exposing (..)

import Effect.Time
import Evergreen.V29.SecretId


type TwoFactorSecret
    = TwoFactorSecret Never


type alias TwoFactorAuthentication =
    { secret : Evergreen.V29.SecretId.SecretId TwoFactorSecret
    , finishedAt : Effect.Time.Posix
    }


type alias TwoFactorAuthenticationSetup =
    { secret : Evergreen.V29.SecretId.SecretId TwoFactorSecret
    , startedAt : Effect.Time.Posix
    }
