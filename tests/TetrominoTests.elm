module TetrominoTests exposing (tests)

import Dict
import Expect
import Id exposing (Id, UserId)
import SeqDict
import SeqSet
import Set
import Test exposing (Test, describe, test)
import Tetromino
import TetrominoSim exposing (Input(..), InputEvent, MatchState, PieceStatus(..))
import TetrominoTimeline
import TetrominoWire


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


{-| The first frame of the first round, for players who joined on frame 0.
-}
firstRound : Int
firstRound =
    TetrominoSim.roundBreak + 1


{-| A match where the given players joined at the start and the first round has begun.
-}
inFirstRound : List (Id UserId) -> MatchState
inFirstRound userIds =
    runUntil firstRound (List.map (join 0) userIds) (TetrominoSim.init 1 0)


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


knockOut : Id UserId -> MatchState -> MatchState
knockOut userId state =
    { state | players = SeqDict.updateIfExists userId (\player -> { player | knockedOutAt = Just state.frame }) state.players }


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
        , test "Players who join wait for the round to start" <|
            \_ ->
                let
                    beforeRound =
                        runUntil (firstRound - 2) [ join 0 userA ] (TetrominoSim.init 1 0)
                in
                ( ( SeqDict.keys beforeRound.players, SeqSet.toList beforeRound.waitingPlayers )
                , runUntil firstRound [] beforeRound |> (\state -> ( SeqDict.keys state.players, state.round.number ))
                )
                    |> Expect.equal ( ( [], [ userA ] ), ( [ userA ], 1 ) )
        , test "A player who joins during a round waits for the next one" <|
            \_ ->
                let
                    state =
                        runUntil (firstRound + 60) [ join (firstRound + 30) userB ] (inFirstRound [ userA ])
                in
                ( SeqDict.keys state.players, SeqSet.toList state.waitingPlayers )
                    |> Expect.equal ( [ userA ], [ userB ] )
        , test "Once everyone is knocked out the next round brings them back" <|
            \_ ->
                let
                    knockedOut =
                        inFirstRound [ userA ] |> knockOut userA

                    nextRound =
                        runUntil (knockedOut.frame + TetrominoSim.roundBreak + 2) [] knockedOut
                in
                ( nextRound.round.number
                , SeqDict.get userA nextRound.players |> Maybe.map .knockedOutAt
                )
                    |> Expect.equal ( 2, Just Nothing )
        , test "A dropped piece lands on the ground" <|
            \_ ->
                runUntil (firstRound + 200) (dropAt (firstRound + 10) userA 3 3) (inFirstRound [ userA ])
                    |> occupiedCells
                    |> List.map (\( _, _, z ) -> z)
                    |> Expect.equal [ 0, 0, 0, 0 ]
        , test "A piece dropped on another stacks on top of it" <|
            \_ ->
                let
                    state =
                        runUntil
                            (firstRound + 400)
                            (dropAt (firstRound + 10) userA 3 3 ++ dropAt (firstRound + 200) userA 3 3)
                            (inFirstRound [ userA ])

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
        , test "When a player is knocked out their pieces go, and pieces resting on them fall" <|
            \_ ->
                let
                    built =
                        runUntil
                            (firstRound + 200)
                            (dropAt (firstRound + 10) userA 3 3 ++ dropAt (firstRound + 100) userB 3 3)
                            (inFirstRound [ userA, userB ])

                    afterKnockout =
                        knockOut userA built |> runUntil (built.frame + 100) []
                in
                ( SeqDict.values built.pieces |> List.map .owner
                , SeqDict.values afterKnockout.pieces |> List.map (\piece -> ( piece.owner, piece.z, piece.status == Settled ))
                )
                    |> Expect.equal ( [ userA, userB ], [ ( userB, 0, True ) ] )
        , test "A player who leaves takes their pieces with them" <|
            \_ ->
                let
                    built =
                        runUntil (firstRound + 200) (dropAt (firstRound + 10) userA 3 3) (inFirstRound [ userA, userB ])

                    afterLeaving =
                        runUntil (built.frame + 1) [ { frame = built.frame, userId = userA, input = Leave } ] built
                in
                ( SeqDict.keys afterLeaving.players, SeqDict.size afterLeaving.pieces )
                    |> Expect.equal ( [ userB ], 0 )
        , test "A player hops onto a block one high" <|
            \_ ->
                let
                    state =
                        inFirstRound [ userA ] |> withBlocks [ ( 14, 12, 0 ) ]
                in
                runUntil (firstRound + 120) [ { frame = firstRound, userId = userA, input = MoveTo 14 12 } ] state
                    |> .players
                    |> SeqDict.get userA
                    |> Maybe.map (\player -> ( abs (player.position.x - 14.5) < 0.01, player.position.z ))
                    |> Expect.equal (Just ( True, 1 ))
        , test "A player can't get past a wall two high" <|
            \_ ->
                let
                    state =
                        inFirstRound [ userA ]
                            |> withBlocks
                                (List.concatMap (\y -> [ ( 14, y, 0 ), ( 14, y, 1 ) ]) (List.range 0 (TetrominoSim.gridSize - 1)))
                in
                runUntil (firstRound + 200) [ { frame = firstRound, userId = userA, input = MoveTo 16 12 } ] state
                    |> .players
                    |> SeqDict.get userA
                    |> Maybe.map (\player -> player.position.x < 14 && player.position.z == 0)
                    |> Expect.equal (Just True)
        , test "The same inputs always give the same state" <|
            \_ ->
                let
                    inputs =
                        [ join 0 userA, join 5 userB, { frame = firstRound + 30, userId = userA, input = MoveTo 2 20 } ]
                            ++ dropAt (firstRound + 50) userB 6 6
                            ++ dropAt (firstRound + 400) userA 2 19
                in
                runUntil 1500 inputs (TetrominoSim.init 7 0)
                    |> Expect.equal (runUntil 1500 inputs (TetrominoSim.init 7 0))
        , test "An input arriving late gives the same state as if it had been there all along" <|
            \_ ->
                let
                    early =
                        [ join 0 userA, join 5 userB, { frame = firstRound + 30, userId = userA, input = MoveTo 2 20 } ]

                    late =
                        dropAt (firstRound + 380) userB 6 6

                    timeline =
                        List.foldl TetrominoTimeline.addInput (TetrominoTimeline.init (TetrominoSim.init 7 0)) early
                            |> TetrominoTimeline.advance (firstRound + 300)
                            |> TetrominoTimeline.advance (firstRound + 400)
                            |> (\timeline2 -> List.foldl TetrominoTimeline.addInput timeline2 late)
                            |> TetrominoTimeline.advance (firstRound + 420)
                            |> TetrominoTimeline.advance (firstRound + 600)
                in
                TetrominoTimeline.latest timeline
                    |> Expect.equal (runUntil (firstRound + 600) (early ++ late) (TetrominoSim.init 7 0))
        , test "A match carries on the same after being sent to another player" <|
            \_ ->
                let
                    inputs =
                        { frame = firstRound + 30, userId = userA, input = MoveTo 2 20 }
                            :: dropAt (firstRound + 50) userB 6 6

                    halfway =
                        runUntil (firstRound + 300) inputs (inFirstRound [ userA, userB ])
                in
                case TetrominoWire.encodeMatchState halfway |> TetrominoWire.decodeMatchState of
                    Just received ->
                        runUntil (firstRound + 900) inputs received
                            |> Expect.equal (runUntil (firstRound + 900) inputs halfway)

                    Nothing ->
                        Expect.fail "The state didn't decode"
        ]
