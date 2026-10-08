module TetrominoTests exposing (tests)

import Coord
import Dict
import Effect.Time as Time
import Expect
import Id exposing (Id, UserId)
import SeqDict
import SeqSet
import Set
import Test exposing (Test, describe, test)
import Tetromino
import TetrominoGame
import TetrominoSim exposing (Input(..), InputEvent, MatchState)
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


center : Int
center =
    TetrominoSim.gridSize // 2


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


setup : TetrominoGame.ValidatedSetup
setup =
    { createdBy = userA, startedAt = Time.millisToPosix 0 }


{-| A client that has just opened a brand new match, one second (60 frames) after it began.
-}
openedMatch : TetrominoGame.GameModel
openedMatch =
    TetrominoGame.updateFromBackend
        (Time.millisToPosix 1000)
        setup
        (TetrominoGame.JoinedMatch
            { frame = 60, startingState = TetrominoGame.FreshMatch, inputs = [], serverTime = Time.millisToPosix 1000 }
        )
        TetrominoGame.initGame
        |> Tuple.first


pressJoin : TetrominoGame.GameModel -> ( TetrominoGame.GameModel, Maybe TetrominoGame.ToBackend )
pressJoin model =
    TetrominoGame.updateGame (Time.millisToPosix 1000) setup (Coord.xy 1000 800) userA TetrominoGame.PressedJoin model


waitingAt : Int -> TetrominoGame.GameModel -> Maybe (List (Id UserId))
waitingAt frame model =
    TetrominoGame.matchStateAt frame model |> Maybe.map (\state -> SeqSet.toList state.waitingPlayers)


{-| An NPC standing still, that won't wander off or throw anything for a good while.
-}
npcAt : Float -> Float -> MatchState -> TetrominoSim.Npc
npcAt x y state =
    { id = 1000
    , position = { x = x, y = y, z = 0 }
    , velocityZ = 0
    , wanderOffset = { x = 0, y = 0 }
    , nextWanderFrame = state.frame + 1000
    , nextThrowFrame = state.frame + 1000
    }


{-| Put a snowball right on userA and see what it does.
-}
hitBySnowball : MatchState -> MatchState
hitBySnowball state =
    case SeqDict.get userA state.players of
        Just player ->
            TetrominoSim.step
                []
                { state
                    | snowballs =
                        [ { position = { x = player.position.x, y = player.position.y, z = player.position.z + 0.4 }
                          , velocity = { x = 0, y = 0, z = 0 }
                          , thrownAt = state.frame
                          }
                        ]
                }

        Nothing ->
            state


knockedOut : MatchState -> Maybe Bool
knockedOut state =
    SeqDict.get userA state.players |> Maybe.map (\player -> player.knockedOutAt /= Nothing)


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
        , test "Four quarter turns come back to the start" <|
            \_ ->
                ( Tetromino.orientation Tetromino.Flat 4, Tetromino.orientation Tetromino.Upright 4 )
                    |> Expect.equal ( Tetromino.orientation Tetromino.Flat 0, Tetromino.orientation Tetromino.Upright 0 )
        , test "An upright I piece stands on end, and turning it doesn't change that" <|
            \_ ->
                List.map
                    (\quarterTurns ->
                        Tetromino.cells (Tetromino.orientation Tetromino.Upright quarterTurns) Tetromino.I |> List.sort
                    )
                    [ 0, 1, 2, 3 ]
                    |> Expect.equal (List.repeat 4 [ ( 0, 0, 0 ), ( 0, 0, 1 ), ( 0, 0, 2 ), ( 0, 0, 3 ) ])
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
                    everyoneOut =
                        inFirstRound [ userA ] |> knockOut userA

                    nextRound =
                        runUntil (everyoneOut.frame + TetrominoSim.roundBreak + 2) [] everyoneOut
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
                            |> List.map (\piece -> ( piece.z, TetrominoSim.isSettled piece.status ))
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
                , SeqDict.values afterKnockout.pieces |> List.map (\piece -> ( piece.owner, piece.z, TetrominoSim.isSettled piece.status ))
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
                        inFirstRound [ userA ] |> withBlocks [ ( center + 2, center, 0 ) ]
                in
                runUntil (firstRound + 120) [ { frame = firstRound, userId = userA, input = MoveTo (center + 2) center } ] state
                    |> .players
                    |> SeqDict.get userA
                    |> Maybe.map (\player -> ( abs (player.position.x - toFloat center - 2.5) < 0.01, player.position.z ))
                    |> Expect.equal (Just ( True, 1 ))
        , test "A player can't get past a wall two high" <|
            \_ ->
                let
                    state =
                        inFirstRound [ userA ]
                            |> withBlocks
                                (List.concatMap
                                    (\y -> [ ( center + 2, y, 0 ), ( center + 2, y, 1 ) ])
                                    (List.range 0 (TetrominoSim.gridSize - 1))
                                )
                in
                runUntil (firstRound + 200) [ { frame = firstRound, userId = userA, input = MoveTo (center + 4) center } ] state
                    |> .players
                    |> SeqDict.get userA
                    |> Maybe.map (\player -> player.position.x < toFloat (center + 2) && player.position.z == 0)
                    |> Expect.equal (Just True)
        , test "A player brought into a round near an NPC shrugs off snowballs for a moment" <|
            \_ ->
                let
                    withNpcNearby : MatchState
                    withNpcNearby =
                        runUntil (firstRound - 1) [ join 0 userA ] (TetrominoSim.init 1 0)
                            |> (\state -> { state | npcs = [ npcAt (toFloat center + 5) (toFloat center) state ] })
                in
                ( runUntil firstRound [] withNpcNearby |> hitBySnowball |> knockedOut
                , runUntil (firstRound + 4 * TetrominoSim.framesPerSecond) [] withNpcNearby |> hitBySnowball |> knockedOut
                )
                    |> Expect.equal ( Just False, Just True )
        , test "With no NPCs about, as in the first round, a player is brought in unprotected" <|
            \_ ->
                inFirstRound [ userA ] |> hitBySnowball |> knockedOut |> Expect.equal (Just True)
        , test "An NPC aims ahead of a player who is walking" <|
            \_ ->
                let
                    walking : MatchState
                    walking =
                        runUntil
                            (firstRound + 30)
                            [ { frame = firstRound, userId = userA, input = MoveTo center (center + 20) } ]
                            (inFirstRound [ userA ])

                    throwing : MatchState
                    throwing =
                        case SeqDict.get userA walking.players of
                            Just player ->
                                TetrominoSim.step
                                    []
                                    { walking
                                        | npcs =
                                            [ npcAt (player.position.x + 6) player.position.y walking
                                                |> (\npc -> { npc | nextThrowFrame = walking.frame })
                                            ]
                                    }

                            Nothing ->
                                walking
                in
                List.map (\snowball -> snowball.velocity.y > 1) throwing.snowballs
                    |> Expect.equal [ True ]
        , test "A destroyed piece leaves its cubes behind for a moment" <|
            \_ ->
                let
                    built =
                        runUntil (firstRound + 200) (dropAt (firstRound + 10) userA 3 3) (inFirstRound [ userA ])

                    afterKnockout =
                        knockOut userA built |> runUntil (built.frame + 1) []
                in
                ( List.map (\debris -> debris.piece.owner) afterKnockout.debris
                , runUntil (afterKnockout.frame + TetrominoSim.debrisFrames) [] afterKnockout |> .debris |> List.length
                )
                    |> Expect.equal ( [ userA ], 0 )
        , test "NPCs turn up near a player, however big the map is" <|
            \_ ->
                let
                    state =
                        runUntil (firstRound + 11 * TetrominoSim.framesPerSecond) [] (inFirstRound [ userA ])
                in
                case state.npcs of
                    [] ->
                        Expect.fail "Expected an NPC by now"

                    npcs ->
                        List.all
                            (\npc -> abs (npc.position.x - toFloat center) < 14 && abs (npc.position.y - toFloat center) < 14)
                            npcs
                            |> Expect.equal True
        , test "NPCs chasing the same player spread out instead of bunching up" <|
            \_ ->
                let
                    start : MatchState
                    start =
                        inFirstRound [ userA ]

                    bunched : MatchState
                    bunched =
                        { start
                            | npcs =
                                List.map
                                    (\id -> npcAt (toFloat center + 15) (toFloat center) start |> (\npc -> { npc | id = id }))
                                    (List.range 1000 1004)
                        }

                    later : MatchState
                    later =
                        runUntil (bunched.frame + 8 * TetrominoSim.framesPerSecond) [] bunched

                    closestPair : Float
                    closestPair =
                        List.concatMap
                            (\npc ->
                                List.filterMap
                                    (\other ->
                                        if npc.id < other.id then
                                            Just (sqrt ((npc.position.x - other.position.x) ^ 2 + (npc.position.y - other.position.y) ^ 2))

                                        else
                                            Nothing
                                    )
                                    later.npcs
                            )
                            later.npcs
                            |> List.minimum
                            |> Maybe.withDefault 0
                in
                ( closestPair > 1.2
                , List.all (\npc -> npc.position.x < toFloat center + 12) later.npcs
                )
                    |> Expect.equal ( True, True )
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
        , test "Taking back a guessed input gives the same state as if it had never been played" <|
            \_ ->
                let
                    inputs =
                        [ join 0 userA, { frame = firstRound + 30, userId = userA, input = MoveTo 2 20 } ]

                    guess =
                        { frame = firstRound + 50, userId = userA, input = MoveTo 30 30 }

                    timeline =
                        List.foldl TetrominoTimeline.addInput (TetrominoTimeline.init (TetrominoSim.init 7 0)) (guess :: inputs)
                            |> TetrominoTimeline.advance (firstRound + 80)
                            |> TetrominoTimeline.removeInput guess
                            |> TetrominoTimeline.advance (firstRound + 100)
                in
                TetrominoTimeline.latest timeline
                    |> Expect.equal (runUntil (firstRound + 100) inputs (TetrominoSim.init 7 0))
        , test "Your own input is played straight away, before the backend answers" <|
            \_ ->
                let
                    ( joined, toBackend ) =
                        pressJoin openedMatch
                in
                ( TetrominoGame.animationFrame (Time.millisToPosix 1100) setup joined
                    |> TetrominoGame.matchState
                    |> Maybe.map (\state -> SeqSet.toList state.waitingPlayers)
                , toBackend
                )
                    |> Expect.equal ( Just [ userA ], Just (TetrominoGame.SendInput 0 (Time.millisToPosix 1000) Join) )
        , test "When the backend moves your input to a later frame, the guess is taken back" <|
            \_ ->
                let
                    accepted =
                        pressJoin openedMatch
                            |> Tuple.first
                            |> TetrominoGame.updateFromBackend
                                (Time.millisToPosix 1250)
                                setup
                                (TetrominoGame.InputAccepted 0 { userId = userA, time = Time.millisToPosix 1200, input = Join })
                            |> Tuple.first
                            |> TetrominoGame.animationFrame (Time.millisToPosix 1500) setup
                in
                ( waitingAt 70 accepted, waitingAt 80 accepted )
                    |> Expect.equal ( Just [], Just [ userA ] )
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
