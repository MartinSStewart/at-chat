module Evergreen.V385.RateLimit exposing (..)

import Effect.Lamdera
import Effect.Time
import SeqDict


type alias SessionRateLimits =
    { shortWindowStartedAt : Effect.Time.Posix
    , shortWindowCounts : SeqDict.SeqDict Effect.Lamdera.SessionId Int
    , longWindowStartedAt : Effect.Time.Posix
    , longWindowCounts : SeqDict.SeqDict Effect.Lamdera.SessionId Int
    }
