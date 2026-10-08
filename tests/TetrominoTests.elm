module TetrominoTests exposing (tests)

import Array
import Dict
import Expect
import Id exposing (Id, UserId)
import SeqDict
import Set
import Test exposing (Test, describe, test)
import Tetromino
import TetrominoSim exposing (Input(..), InputEvent, MatchState, PieceStatus(..))
import TetrominoTimeline


userA : Id UserId
userA =
    Id.fromInt 1


userB : Id UserId
userB =
    Id.fromInt 2


{-| Run the simulation until the given frame, applying the inputs on the frames they're stamped
with.
-}
runUntil : Int -> List InputEvent -> MatchState -> MatchState
runUntil endFrame inputs state =
    if state.frame >= endFrame then
        state

    else
        runUntil
            endFrame
            inputs
            (TetrominoSim.step (List.filter (\event -> event.frame == state.frame) inputs) state)


join : Int -> Id UserId -> InputEvent
join frame userId =
    { frame = frame, userId = userId, input = Join }


dropAt : Int -> Id UserId -> Int -> Int -> List InputEvent
dropAt frame userId x y =
    [ { frame = frame, userId = userId, input = StopCycling }
    , { frame = frame + 1, userId = userId, input = Drop { x = x, y = y, orientation = Tetromino.identity } }
    ]


occupiedCells : MatchState -> List ( Int, Int, Int )
occupiedCells state =
    Dict.keys state.occupied


{-| Puts a block wherever a cell is listed, owned by nobody who is playing, without dropping
anything.
-}
withBlocks : List ( Int, Int, Int ) -> MatchState -> MatchState
withBlocks cells state =
    { state
        | occupied = List.foldl (\cell occupied -> Dict.insert cell -1 occupied) state.occupied cells
    }


tests : Test
tests =
    describe "Tetromino game"
        [ test "There are 24 distinct orientations" <|
            \_ ->
                Tetromino.allOrientations
                    |> List.foldl
                        (\orientation distinct ->
                            if List.member orientation distinct then
                                distinct

                            else
                                orientation :: distinct
                        )
                        []
                    |> List.length
                    |> Expect.equal 24
        , test "Every orientation of every piece is four cells starting at the ground" <|
            \_ ->
                List.concatMap
                    (\shape ->
                        List.map
                            (\orientation ->
                                let
                                    cells =
                                        Tetromino.cells orientation shape
                                in
                                ( Set.size (Set.fromList cells)
                                , List.map (\( _, _, z ) -> z) cells |> List.minimum
                                )
                            )
                            Tetromino.allOrientations
                    )
                    Tetromino.all
                    |> List.all (\result -> result == ( 4, Just 0 ))
                    |> Expect.equal True
        , test "Four turns about the same axis come back to the start" <|
            \_ ->
                ( Tetromino.identity |> Tetromino.rotateAroundZ |> Tetromino.rotateAroundZ |> Tetromino.rotateAroundZ |> Tetromino.rotateAroundZ
                , Tetromino.identity |> Tetromino.rotateAroundY |> Tetromino.rotateAroundY |> Tetromino.rotateAroundY |> Tetromino.rotateAroundY
                )
                    |> Expect.equal ( Tetromino.identity, Tetromino.identity )
        , test "A dropped piece lands on the ground" <|
            \_ ->
                runUntil 200 (join 0 userA :: dropAt 10 userA 3 3) (TetrominoSim.init 1)
                    |> occupiedCells
                    |> List.map (\( _, _, z ) -> z)
                    |> Expect.equal [ 0, 0, 0, 0 ]
        , test "A piece dropped on another stacks on top of it" <|
            \_ ->
                let
                    state =
                        runUntil 400 (join 0 userA :: dropAt 10 userA 3 3 ++ dropAt 200 userA 3 3) (TetrominoSim.init 1)

                    shapes =
                        SeqDict.values state.pieces |> List.map .shape
                in
                case shapes of
                    [ first, second ] ->
                        let
                            expectedHeight =
                                List.map
                                    (\( x, y, _ ) ->
                                        if List.member ( x, y, 0 ) (Tetromino.cells Tetromino.identity first) then
                                            1

                                        else
                                            0
                                    )
                                    (Tetromino.cells Tetromino.identity second)
                                    |> List.maximum
                                    |> Maybe.withDefault 0
                        in
                        SeqDict.values state.pieces
                            |> List.map (\piece -> ( piece.z, piece.status == Settled ))
                            |> Expect.equal [ ( 0, True ), ( toFloat expectedHeight, True ) ]

                    _ ->
                        Expect.fail "Expected two pieces"
        , test "When a player dies their pieces go, and pieces resting on them fall" <|
            \_ ->
                let
                    built =
                        runUntil
                            200
                            [ join 0 userA
                            , join 0 userB
                            , { frame = 10, userId = userA, input = StopCycling }
                            , { frame = 11, userId = userA, input = Drop { x = 3, y = 3, orientation = Tetromino.identity } }
                            , { frame = 100, userId = userB, input = StopCycling }
                            , { frame = 101, userId = userB, input = Drop { x = 3, y = 3, orientation = Tetromino.identity } }
                            ]
                            (TetrominoSim.init 1)

                    killed =
                        { built | players = SeqDict.updateIfExists userA (\player -> { player | health = 0 }) built.players }
                            |> runUntil 300 []
                in
                ( SeqDict.values built.pieces |> List.map .owner
                , SeqDict.values killed.pieces |> List.map (\piece -> ( piece.owner, piece.z, piece.status == Settled ))
                )
                    |> Expect.equal ( [ userA, userB ], [ ( userB, 0, True ) ] )
        , test "A player hops onto a block one high" <|
            \_ ->
                let
                    state =
                        TetrominoSim.init 1 |> runUntil 1 [ join 0 userA ] |> withBlocks [ ( 14, 12, 0 ) ]
                in
                runUntil 120 [ { frame = 1, userId = userA, input = MoveTo 14 12 } ] state
                    |> .players
                    |> SeqDict.get userA
                    |> Maybe.map (\player -> ( abs (player.position.x - 14.5) < 0.01, player.position.z ))
                    |> Expect.equal (Just ( True, 1 ))
        , test "A player can't get past a wall two high" <|
            \_ ->
                let
                    state =
                        TetrominoSim.init 1
                            |> runUntil 1 [ join 0 userA ]
                            |> withBlocks
                                (List.concatMap (\y -> [ ( 14, y, 0 ), ( 14, y, 1 ) ]) (List.range 0 (TetrominoSim.gridSize - 1)))
                in
                runUntil 200 [ { frame = 1, userId = userA, input = MoveTo 16 12 } ] state
                    |> .players
                    |> SeqDict.get userA
                    |> Maybe.map (\player -> player.position.x < 14 && player.position.z == 0)
                    |> Expect.equal (Just True)
        , test "The same inputs always give the same state" <|
            \_ ->
                let
                    inputs =
                        [ join 0 userA, join 5 userB, { frame = 30, userId = userA, input = MoveTo 2 20 } ]
                            ++ dropAt 50 userB 6 6
                            ++ dropAt 400 userA 2 19
                in
                runUntil 900 inputs (TetrominoSim.init 7)
                    |> Expect.equal (runUntil 900 inputs (TetrominoSim.init 7))
        , test "An input arriving late gives the same state as if it had been there all along" <|
            \_ ->
                let
                    early =
                        [ join 0 userA, join 5 userB, { frame = 30, userId = userA, input = MoveTo 2 20 } ]

                    late =
                        dropAt 380 userB 6 6

                    timeline =
                        TetrominoTimeline.init 7
                            |> TetrominoTimeline.update 300 (Array.fromList early)
                            |> TetrominoTimeline.update 400 (Array.fromList early)
                            |> TetrominoTimeline.update 420 (Array.fromList (early ++ late))
                            |> TetrominoTimeline.update 600 (Array.fromList (early ++ late))
                in
                TetrominoTimeline.latest timeline
                    |> Expect.equal (runUntil 600 (early ++ late) (TetrominoSim.init 7))
        ]
