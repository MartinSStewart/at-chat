module RateLimit exposing
    ( checkAndUpdateRateLimit
    , shortWindowDuration
    , shortWindowMaxMessages
    )

import Array exposing (Array)
import Array.Extra
import Duration exposing (Duration)
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
                        ( ( Nothing, 0 ), longWindowMaxMessages, shortWindowMaxMessages )
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
