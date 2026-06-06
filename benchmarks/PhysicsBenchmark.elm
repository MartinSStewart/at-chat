port module PhysicsBenchmark exposing (main)

{-| Headless benchmark for `Physics.simulate`.

Compile with:

    npx lamdera make benchmarks / PhysicsBenchmark.elm --output=benchmarks/main.js

then run with:

    node benchmarks / run.js

It prints a single line like

    simulate 8 16.6ms [67 bodies]: 1000 samples = 4321.0 ms total (4.32 ms/call)

so before/after numbers can be compared directly.

-}

import Benchmark.LowLevel as LowLevel
import Duration
import Physics exposing (Body)
import Task


port output : String -> Cmd msg


type Msg
    = Done (Result LowLevel.Error Float)


{-| A representative pile: 67 circles in a grid that fits the 60x160 box, in
roughly the size distribution the viewer uses (30 small + 25 medium + 12
large). They all start at rest so the very first substep does the most work
(arm push, gravity-like settling, pairwise contact resolution).
-}
benchmarkBodies : List Body
benchmarkBodies =
    List.range 0 66
        |> List.map
            (\i ->
                { x = toFloat (modBy 6 i) * 10 + 5
                , y = toFloat (i // 6) * 8 + 5
                , vx = 0
                , vy = 0
                , radius =
                    if i - 30 < 0 then
                        4

                    else if i - 55 < 0 then
                        5

                    else
                        6
                }
            )


op : LowLevel.Operation
op =
    LowLevel.operation
        (\_ -> Physics.simulate 8 (Duration.milliseconds 16.6) benchmarkBodies)


sampleCount : Int
sampleCount =
    5000


main : Program () () Msg
main =
    Platform.worker
        { init =
            \_ ->
                ( ()
                , Task.attempt Done
                    (LowLevel.warmup op
                        |> Task.andThen (\_ -> LowLevel.sample sampleCount op)
                    )
                )
        , update =
            \msg _ ->
                case msg of
                    Done (Ok totalMs) ->
                        let
                            perCall : Float
                            perCall =
                                totalMs / toFloat sampleCount
                        in
                        ( ()
                        , output
                            ("simulate 8 16.6ms ["
                                ++ String.fromInt (List.length benchmarkBodies)
                                ++ " bodies]: "
                                ++ String.fromInt sampleCount
                                ++ " samples = "
                                ++ String.fromFloat totalMs
                                ++ " ms total ("
                                ++ String.fromFloat perCall
                                ++ " ms/call)"
                            )
                        )

                    Done (Err _) ->
                        ( (), output "Error during benchmark run" )
        , subscriptions = \_ -> Sub.none
        }
