module Evergreen.V22.TwoFactorAuthentication exposing (..)

import Effect.Time
import Evergreen.V22.SecretId


type TwoFactorSecret
    = TwoFactorSecret Never


type alias TwoFactorAuthentication =
    { secret : Evergreen.V22.SecretId.SecretId TwoFactorSecret
    , finishedAt : Effect.Time.Posix
    }


type alias TwoFactorAuthenticationSetup =
    { secret : Evergreen.V22.SecretId.SecretId TwoFactorSecret
    , startedAt : Effect.Time.Posix
    }
