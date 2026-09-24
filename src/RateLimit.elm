module RateLimit exposing
    ( Limits
    , checkAndUpdateRateLimit
    , dropExpired
    , sendMessageLimits
    , sessionRequestLimits
    )

import Array exposing (Array)
import Array.Extra
import Duration exposing (Duration)
import Effect.Time as Time
import Quantity
import SeqDict exposing (SeqDict)


type alias Limits =
    { shortWindow : Duration
    , shortWindowMax : Int
    , longWindow : Duration
    , longWindowMax : Int
    }


sendMessageLimits : Limits
sendMessageLimits =
    { shortWindow = Duration.seconds 10
    , shortWindowMax = 10
    , longWindow = Duration.minutes 30
    , longWindowMax = 200
    }


{-| Applies to every ToBackend a session sends, not just the expensive ones. A session is a
browser rather than a tab, so someone with several tabs open shares one budget, and clicking
around quickly in all of them should still stay well under this.
-}
sessionRequestLimits : Limits
sessionRequestLimits =
    { shortWindow = Duration.seconds 10
    , shortWindowMax = 150
    , longWindow = Duration.minutes 5
    , longWindowMax = 2000
    }


checkAndUpdateRateLimit :
    Limits
    -> Time.Posix
    -> key
    -> SeqDict key (Array Time.Posix)
    -> Result () (SeqDict key (Array Time.Posix))
checkAndUpdateRateLimit limits now key rateLimits =
    case SeqDict.get key rateLimits of
        Just value ->
            let
                ( ( indexToDrop, _ ), longRemaining, shortRemaining ) =
                    Array.foldl
                        (\item ( ( indexToDrop2, index ), longRemaining2, shortRemaining2 ) ->
                            let
                                elapsed =
                                    Duration.from item now
                            in
                            if elapsed |> Quantity.lessThan limits.shortWindow then
                                ( ( indexToDrop2, index + 1 ), longRemaining2 - 1, shortRemaining2 - 1 )

                            else if elapsed |> Quantity.lessThan limits.longWindow then
                                ( ( indexToDrop2, index + 1 ), longRemaining2 - 1, shortRemaining2 )

                            else
                                ( ( Just index, index + 1 ), longRemaining2, shortRemaining2 )
                        )
                        ( ( Nothing, 1 ), limits.longWindowMax, limits.shortWindowMax )
                        value
            in
            if longRemaining > 0 && shortRemaining > 0 then
                case indexToDrop of
                    Just indexToDrop2 ->
                        Ok (SeqDict.insert key (Array.Extra.sliceFrom indexToDrop2 value |> Array.push now) rateLimits)

                    Nothing ->
                        Ok (SeqDict.insert key (Array.push now value) rateLimits)

            else
                Err ()

        Nothing ->
            Ok (SeqDict.insert key (Array.fromList [ now ]) rateLimits)


{-| Nothing removes a key on its own, so without this the session rate limits would keep an
entry for every session that ever connected.
-}
dropExpired : Limits -> Time.Posix -> SeqDict key (Array Time.Posix) -> SeqDict key (Array Time.Posix)
dropExpired limits now rateLimits =
    SeqDict.filter
        (\_ value ->
            case Array.get (Array.length value - 1) value of
                Just latest ->
                    Duration.from latest now |> Quantity.lessThan limits.longWindow

                Nothing ->
                    False
        )
        rateLimits
