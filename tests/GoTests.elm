module GoTests exposing (tests)

import Dict
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
                        , blackPlayer = Id.fromInt 0
                        , whitePlayer = Id.fromInt 1
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
        ]
