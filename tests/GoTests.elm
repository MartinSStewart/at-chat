module GoTests exposing (tests)

import Dict
import Expect
import Pages.Go exposing (Stone(..))
import Set
import Test exposing (Test)


tests : Test
tests =
    Test.describe
        "Go"
        [ Test.test "interior stones of a surrounded group are marked dead" <|
            \_ ->
                let
                    width : Int
                    width =
                        5

                    height : Int
                    height =
                        5

                    -- A plus-shape of 5 black stones in the centre. The
                    -- centre stone has only friendly neighbours, so the
                    -- previous per-stone check reported it as alive.
                    blackPositions : List ( Int, Int )
                    blackPositions =
                        [ ( 2, 2 ), ( 1, 2 ), ( 3, 2 ), ( 2, 1 ), ( 2, 3 ) ]

                    board : Dict.Dict ( Int, Int ) Stone
                    board =
                        Dict.fromList (List.map (\p -> ( p, Black )) blackPositions)

                    allCells : List ( Int, Int )
                    allCells =
                        List.range 0 (width - 1)
                            |> List.concatMap
                                (\x ->
                                    List.range 0 (height - 1)
                                        |> List.map (\y -> ( x, y ))
                                )

                    territoryMarks : Dict.Dict ( Int, Int ) Stone
                    territoryMarks =
                        allCells
                            |> List.filter (\p -> not (Dict.member p board))
                            |> List.map (\p -> ( p, White ))
                            |> Dict.fromList
                in
                Pages.Go.deadStones
                    { width = width
                    , height = height
                    , board = board
                    , territoryMarks = territoryMarks
                    }
                    |> Expect.equal (Set.fromList blackPositions)
        ]
