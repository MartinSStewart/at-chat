module Evergreen.V27.TwoFactorAuthentication exposing (..)

import Effect.Time
import Evergreen.V27.SecretId


type TwoFactorSecret
    = TwoFactorSecret Never


type alias TwoFactorAuthentication =
    { secret : Evergreen.V27.SecretId.SecretId TwoFactorSecret
    , finishedAt : Effect.Time.Posix
    }


type alias TwoFactorAuthenticationSetup =
    { secret : Evergreen.V27.SecretId.SecretId TwoFactorSecret
    , startedAt : Effect.Time.Posix
    }
