module RateLimit exposing
    ( SessionRateLimits
    , checkAndUpdateRateLimit
    , checkAndUpdateSessionRateLimit
    , longWindowDuration
    , longWindowMaxMessages
    , sessionRateLimitsInit
    , sessionShortWindowDuration
    , sessionShortWindowMaxRequests
    , shortWindowDuration
    , shortWindowMaxMessages
    )

import Array exposing (Array)
import Array.Extra
import Duration exposing (Duration)
import Effect.Lamdera exposing (SessionId)
import Effect.Time as Time
import Id exposing (Id, UserId)
import Quantity
import SeqDict exposing (SeqDict)


shortWindowMaxMessages : Int
shortWindowMaxMessages =
    10


longWindowMaxMessages : Int
longWindowMaxMessages =
    200


shortWindowDuration : Duration
shortWindowDuration =
    Duration.seconds 10


longWindowDuration : Duration
longWindowDuration =
    Duration.minutes 30


checkAndUpdateRateLimit :
    Time.Posix
    -> Id UserId
    -> SeqDict (Id UserId) (Array Time.Posix)
    -> Result () (SeqDict (Id UserId) (Array Time.Posix))
checkAndUpdateRateLimit now key limits =
    case SeqDict.get key limits of
        Just value ->
            let
                ( ( indexToDrop, _ ), longRemaining, shortRemaining ) =
                    Array.foldl
                        (\item ( ( indexToDrop2, index ), longRemaining2, shortRemaining2 ) ->
                            let
                                elapsed =
                                    Duration.from item now
                            in
                            if elapsed |> Quantity.lessThan shortWindowDuration then
                                ( ( indexToDrop2, index + 1 ), longRemaining2 - 1, shortRemaining2 - 1 )

                            else if elapsed |> Quantity.lessThan longWindowDuration then
                                ( ( indexToDrop2, index + 1 ), longRemaining2 - 1, shortRemaining2 )

                            else
                                ( ( Just index, index + 1 ), longRemaining2, shortRemaining2 )
                        )
                        ( ( Nothing, 1 ), longWindowMaxMessages, shortWindowMaxMessages )
                        value
            in
            if longRemaining > 0 && shortRemaining > 0 then
                case indexToDrop of
                    Just indexToDrop2 ->
                        Ok (SeqDict.insert key (Array.Extra.sliceFrom indexToDrop2 value |> Array.push now) limits)

                    Nothing ->
                        Ok (SeqDict.insert key (Array.push now value) limits)

            else
                Err ()

        Nothing ->
            Ok (SeqDict.insert key (Array.fromList [ now ]) limits)


type alias SessionRateLimits =
    { shortWindowStartedAt : Time.Posix
    , shortWindowCounts : SeqDict SessionId Int
    , longWindowStartedAt : Time.Posix
    , longWindowCounts : SeqDict SessionId Int
    }


sessionRateLimitsInit : SessionRateLimits
sessionRateLimitsInit =
    { shortWindowStartedAt = Time.millisToPosix 0
    , shortWindowCounts = SeqDict.empty
    , longWindowStartedAt = Time.millisToPosix 0
    , longWindowCounts = SeqDict.empty
    }


sessionShortWindowMaxRequests : Int
sessionShortWindowMaxRequests =
    150


sessionLongWindowMaxRequests : Int
sessionLongWindowMaxRequests =
    2000


sessionShortWindowDuration : Duration
sessionShortWindowDuration =
    Duration.seconds 10


sessionLongWindowDuration : Duration
sessionLongWindowDuration =
    Duration.minutes 5


checkAndUpdateSessionRateLimit : Time.Posix -> SessionId -> SessionRateLimits -> Result () SessionRateLimits
checkAndUpdateSessionRateLimit now sessionId rateLimits =
    let
        ( shortWindowStartedAt, shortWindowCounts ) =
            if Duration.from rateLimits.shortWindowStartedAt now |> Quantity.lessThan sessionShortWindowDuration then
                ( rateLimits.shortWindowStartedAt, rateLimits.shortWindowCounts )

            else
                ( now, SeqDict.empty )

        ( longWindowStartedAt, longWindowCounts ) =
            if Duration.from rateLimits.longWindowStartedAt now |> Quantity.lessThan sessionLongWindowDuration then
                ( rateLimits.longWindowStartedAt, rateLimits.longWindowCounts )

            else
                ( now, SeqDict.empty )

        shortCount : Int
        shortCount =
            SeqDict.get sessionId shortWindowCounts |> Maybe.withDefault 0

        longCount : Int
        longCount =
            SeqDict.get sessionId longWindowCounts |> Maybe.withDefault 0
    in
    if shortCount >= sessionShortWindowMaxRequests || longCount >= sessionLongWindowMaxRequests then
        Err ()

    else
        Ok
            { shortWindowStartedAt = shortWindowStartedAt
            , shortWindowCounts = SeqDict.insert sessionId (shortCount + 1) shortWindowCounts
            , longWindowStartedAt = longWindowStartedAt
            , longWindowCounts = SeqDict.insert sessionId (longCount + 1) longWindowCounts
            }
