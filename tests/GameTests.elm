module GameTests exposing (..)

import Coord exposing (Coord)
import Expect
import Game exposing (GridPos, Move(..), PlayerOrBox(..))
import List.Nonempty exposing (Nonempty(..))
import NonemptyDict
import RichTextTests
import Test exposing (Test)


tests : Test
tests =
    Test.describe
        "Sovler"
        [ solveTest "Basic" [ ( Coord.xy 0 0, Player ) ] [ ( Coord.xy 1 0, Player ) ] [ ( Coord.xy 0 0, Right ) ]
        , solveTest
            "Square"
            [ ( Coord.xy 0 0, Player ), ( Coord.xy 1 1, Player ) ]
            [ ( Coord.xy 1 0, Player ), ( Coord.xy 0 1, Player ) ]
            [ ( Coord.xy 0 0, Right ), ( Coord.xy 1 1, Left ) ]
        , solveTest
            "Square with box"
            [ ( Coord.xy 0 0, Player ), ( Coord.xy 1 1, Player ), ( Coord.xy 1 0, Block ) ]
            [ ( Coord.xy 1 0, Player ), ( Coord.xy 0 1, Player ), ( Coord.xy 1 -1, Block ) ]
            [ ( Coord.xy 0 0, Down ), ( Coord.xy 1 1, Up ) ]
        , solveTest
            "Conga line"
            [ ( Coord.xy 0 0, Player ), ( Coord.xy 1 0, Player ), ( Coord.xy 2 0, Player ) ]
            [ ( Coord.xy 1 0, Player ), ( Coord.xy 2 0, Player ), ( Coord.xy 3 0, Player ) ]
            [ ( Coord.xy 0 0, Right ), ( Coord.xy 1 0, Right ), ( Coord.xy 2 0, Right ) ]
        ]


solveTest : String -> List ( Coord GridPos, PlayerOrBox ) -> List ( Coord GridPos, PlayerOrBox ) -> List ( Coord GridPos, Move ) -> Test
solveTest name frame nextFrame expected =
    case ( NonemptyDict.fromList frame, NonemptyDict.fromList nextFrame, NonemptyDict.fromList expected ) of
        ( Just frame2, Just nextFrame2, Just expected2 ) ->
            Test.test name (\_ -> Game.solve frame2 nextFrame2 |> Expect.equal (Ok expected2))

        _ ->
            Debug.todo "Inputs must be nonempty"
