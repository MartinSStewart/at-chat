module GameTests exposing (..)

import Coord exposing (Coord)
import Expect
import Game exposing (GridPos, Level, Move(..), PlayerOrBox(..), WallOrTimePortal(..))
import List.Nonempty exposing (Nonempty(..))
import NonemptyDict
import RichTextTests
import SeqDict
import Test exposing (Test)


tests : Test
tests =
    Test.describe
        "Move solver"
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


level1 : Level
level1 =
    { horizontalWalls =
        SeqDict.fromList
            [ ( Coord.xy 1 2, Wall )
            , ( Coord.xy 3 1, TimePortal 5 )
            , ( Coord.xy 5 4, Wall )
            , ( Coord.xy 0 3, Wall )
            ]
    , verticalWalls = SeqDict.fromList [ ( Coord.xy 3 0, Wall ), ( Coord.xy 3 2, TimePortal 5 ) ] -- SeqSet.fromList [ Coord.xy 2 1, Coord.xy 4 3, Coord.xy 1 5, Coord.xy 3 0 ]
    , start = Coord.xy 1 1
    , exit = Coord.xy 2 4
    }


solveTest : String -> List ( Coord GridPos, PlayerOrBox ) -> List ( Coord GridPos, PlayerOrBox ) -> List ( Coord GridPos, Move ) -> Test
solveTest name frame nextFrame expected =
    case ( NonemptyDict.fromList frame, NonemptyDict.fromList nextFrame, NonemptyDict.fromList expected ) of
        ( Just frame2, Just nextFrame2, Just expected2 ) ->
            Test.test name (\_ -> Game.findNextMove level1 frame2 nextFrame2 |> Expect.equal (Ok expected2))

        _ ->
            Debug.todo "Inputs must be nonempty"
