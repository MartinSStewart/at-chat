module DiscordGatewayTests exposing (tests)

import Discord
import Duration
import Expect
import Test exposing (Test)


{-| The delays a connection would wait for if every reconnect attempt in a row failed, in seconds.
-}
delaySchedule : Int -> Int -> List Float
delaySchedule seed attempts =
    List.foldl
        (\_ ( delays, model ) ->
            let
                ( delay, nextModel ) =
                    Discord.nextReconnectDelay model
            in
            ( Duration.inSeconds delay :: delays, nextModel )
        )
        ( [], Discord.init seed )
        (List.range 1 attempts)
        |> Tuple.first
        |> List.reverse


tests : Test
tests =
    Test.describe "Discord gateway reconnect backoff"
        [ Test.test "The first reconnect after a healthy connection happens immediately" <|
            \_ ->
                delaySchedule 0 1 |> Expect.equal [ 0 ]
        , Test.test "Each consecutive failure waits about twice as long as the one before it" <|
            \_ ->
                -- Without jitter the delays would be 0, 1, 3, 7, 15, 31, 60, 60, 60, 60. Jitter
                -- only ever shortens a delay, and never by more than half.
                List.map2
                    (\delay unjittered -> ( delay >= unjittered / 2, delay <= unjittered ))
                    (delaySchedule 123 10)
                    [ 0, 1, 3, 7, 15, 31, 60, 60, 60, 60 ]
                    |> Expect.equal (List.repeat 10 ( True, True ))
        , Test.test "The delay stays capped at a minute no matter how many attempts have failed" <|
            \_ ->
                delaySchedule 456 40
                    |> List.drop 39
                    |> List.map (\delay -> ( delay >= 30, delay <= 60 ))
                    |> Expect.equal [ ( True, True ) ]
        , Test.test "Connections that dropped at the same time don't all come back at the same instant" <|
            \_ ->
                Expect.notEqual (delaySchedule 1 8) (delaySchedule 2 8)
        ]
