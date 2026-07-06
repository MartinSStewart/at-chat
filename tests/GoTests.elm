module GoTests exposing (tests)

import Array
import Dict
import Duration
import Effect.Time as Time
import Expect
import Go exposing (KomiHalfPoints(..), Stone(..), ValidatedSetup)
import Id
import Set
import Test exposing (Test)


tests : Test
tests =
    Test.describe
        "Go"
        [ Test.test "interior stones of a surrounded group are marked dead" <|
            \_ ->
                let
                    setup : ValidatedSetup
                    setup =
                        { width = Go.boardSize9
                        , height = Go.boardSize9
                        , handicap = 0
                        , komiHalfPoints = KomiHalfPoints 0
                        , timeControl = Nothing
                        , createdBy = Id.fromInt 0
                        , gameCreatorPlayingAs = Black
                        }

                    -- A plus-shape of 5 black stones. The centre stone
                    -- has only friendly neighbours, so the previous
                    -- per-stone check reported it as alive.
                    blackPositions : List ( Int, Int )
                    blackPositions =
                        [ ( 4, 4 ), ( 3, 4 ), ( 5, 4 ), ( 4, 3 ), ( 4, 5 ) ]

                    board : Dict.Dict ( Int, Int ) Stone
                    board =
                        Dict.fromList (List.map (\p -> ( p, Black )) blackPositions)

                    allCells : List ( Int, Int )
                    allCells =
                        List.range 0 8
                            |> List.concatMap
                                (\x ->
                                    List.range 0 8
                                        |> List.map (\y -> ( x, y ))
                                )

                    territoryMarks : Dict.Dict ( Int, Int ) Stone
                    territoryMarks =
                        allCells
                            |> List.filter (\p -> not (Dict.member p board))
                            |> List.map (\p -> ( p, White ))
                            |> Dict.fromList
                in
                Go.deadStones
                    { setup = setup
                    , board = board
                    , territoryMarks = territoryMarks
                    }
                    |> Expect.equal (Set.fromList blackPositions)
        , Test.test "clocks don't run until both players have made a move" <|
            \_ ->
                let
                    -- White takes 5 minutes (well over the 1 minute main time) to join and make
                    -- their first move. The clocks only start after that move, so no time is lost
                    -- and the move is accepted.
                    shared =
                        Go.foldActions
                            timedSetup
                            (Array.fromList
                                [ { time = Time.millisToPosix 0, change = Go.PlaceStone 4 4 }
                                , { time = minutesToPosix 5, change = Go.Joined (Id.fromInt 1) }
                                , { time = minutesToPosix 5, change = Go.PlaceStone 5 4 }
                                ]
                            )
                in
                Expect.equal
                    { stoneWasPlaced = True, timeLeft = Just { white = Duration.minutes 1, black = Duration.minutes 1 } }
                    { stoneWasPlaced = Dict.member ( 5, 4 ) shared.board, timeLeft = shared.timeLeft }
        , Test.test "clocks run once both players have made a move" <|
            \_ ->
                let
                    -- After White's first move the clocks are live: Black thinks for 15 seconds,
                    -- which comes off Black's clock.
                    shared =
                        Go.foldActions
                            timedSetup
                            (Array.fromList
                                [ { time = Time.millisToPosix 0, change = Go.PlaceStone 4 4 }
                                , { time = Time.millisToPosix 0, change = Go.Joined (Id.fromInt 1) }
                                , { time = Time.millisToPosix 10000, change = Go.PlaceStone 5 4 }
                                , { time = Time.millisToPosix 25000, change = Go.PlaceStone 4 5 }
                                ]
                            )
                in
                Expect.equal (Just { white = Duration.minutes 1, black = Duration.seconds 45 }) shared.timeLeft
        , Test.test "a player who runs out of time can't move" <|
            \_ ->
                let
                    -- Both players have moved so the clocks are live. White then takes 2 minutes
                    -- (over the 1 minute main time), so their move is rejected.
                    shared =
                        Go.foldActions
                            timedSetup
                            (Array.fromList
                                [ { time = Time.millisToPosix 0, change = Go.PlaceStone 4 4 }
                                , { time = Time.millisToPosix 0, change = Go.Joined (Id.fromInt 1) }
                                , { time = Time.millisToPosix 0, change = Go.PlaceStone 5 4 }
                                , { time = Time.millisToPosix 0, change = Go.PlaceStone 4 5 }
                                , { time = minutesToPosix 2, change = Go.PlaceStone 5 5 }
                                ]
                            )
                in
                Expect.equal False (Dict.member ( 5, 5 ) shared.board)
        ]


minutesToPosix : Float -> Time.Posix
minutesToPosix minutes =
    Duration.minutes minutes |> Duration.inMilliseconds |> round |> Time.millisToPosix


timedSetup : ValidatedSetup
timedSetup =
    { width = Go.boardSize9
    , height = Go.boardSize9
    , handicap = 0
    , komiHalfPoints = KomiHalfPoints 0
    , timeControl = Just { mainTime = Duration.minutes 1, increment = Duration.seconds 0 }
    , createdBy = Id.fromInt 0
    , gameCreatorPlayingAs = Black
    }
