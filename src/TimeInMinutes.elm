module TimeInMinutes exposing
    ( DateAndTime
    , TimeInMinutes
    , fromDateAndTime
    , fromMinutes
    , toSeconds
    , toTime
    )

import Date
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


type alias DateAndTime =
    { year : Int, month : Time.Month, day : Int, hour : Int, minute : Int }


toDateAndTime : Time.Zone -> TimeInMinutes -> DateAndTime
toDateAndTime timezone time =
    let
        time2 : Time.Posix
        time2 =
            toTime time
    in
    { year = Time.toYear timezone time2
    , month = Time.toMonth timezone time2
    , day = Time.toDay timezone time2
    , hour = Time.toHour timezone time2
    , minute = Time.toMinute timezone time2
    }


{-| The moment a clock in `timezone` reads the given date and time.

elm/time only converts the other way, so the offset the zone was using has to be found by
trying: read the date and time as if it were UTC, ask the zone how far from UTC it is around
then, and step back by that much. The second step is what gets daylight saving right, since
the first guess can land on the wrong side of a transition and pick up the neighbouring
offset.

Two moments share the same date and time on the day the clocks go back. This picks one of
them.

-}
fromDateAndTime : Time.Zone -> DateAndTime -> TimeInMinutes
fromDateAndTime timezone dateAndTime =
    let
        readAsUtc : Int
        readAsUtc =
            minutesFromDateAndTime dateAndTime

        firstGuess : Int
        firstGuess =
            readAsUtc - offsetMinutes timezone (TimeInMinutes readAsUtc)
    in
    readAsUtc - offsetMinutes timezone (TimeInMinutes firstGuess) |> TimeInMinutes


{-| How far ahead of UTC `timezone` is at the given moment, in minutes.
-}
offsetMinutes : Time.Zone -> TimeInMinutes -> Int
offsetMinutes timezone ((TimeInMinutes minutes) as time) =
    minutesFromDateAndTime (toDateAndTime timezone time) - minutes


{-| Minutes from the epoch to the given date and time, read as if it were UTC.
-}
minutesFromDateAndTime : DateAndTime -> Int
minutesFromDateAndTime { year, month, day, hour, minute } =
    (Date.toRataDie (Date.fromCalendarDate year month day) - rataDieEpoch)
        * minutesPerDay
        + hour
        * 60
        + minute


{-| The rata die day number of 1970-01-01, which is where `Time.Posix` starts counting.
-}
rataDieEpoch : number
rataDieEpoch =
    719163


minutesPerDay : number
minutesPerDay =
    1440
