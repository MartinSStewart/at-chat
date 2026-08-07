module TimeInMinutes exposing (TimeInMinutes, fromMinutes, toSeconds, toTime)

import Effect.Time as Time


type TimeInMinutes
    = TimeInMinutes Int


toTime : TimeInMinutes -> Time.Posix
toTime (TimeInMinutes int) =
    int * 60 * 1000 |> Time.millisToPosix


toSeconds : TimeInMinutes -> Int
toSeconds (TimeInMinutes int) =
    int * 60


fromMinutes : Int -> TimeInMinutes
fromMinutes =
    TimeInMinutes
