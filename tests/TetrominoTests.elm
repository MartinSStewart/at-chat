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
import TetrominoSim exposing (Input(..), InputEvent, MatchState, NpcKind(..))
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
    [ { frame = frame, userId = userId, input = Drop { x = x, y = y, orientation = Tetromino.identity } } ]


{-| The first frame of the first round, for players who joined on frame 0.
-}
firstRound : Int
firstRound =
    TetrominoSim.roundBreak + 1


{-| A match where the given players joined at the start and the first round has begun.
-}
inFirstRound : List (Id UserId) -> MatchState
inFirstRound userIds =
    runUntil firstRound (List.map (join 0) userIds) (emptyMatch 1 0)


{-| A new match without the pieces a match starts with lying around, so a test only sees the
pieces it drops.
-}
emptyMatch : Int -> Int -> MatchState
emptyMatch seed frame =
    let
        state : MatchState
        state =
            TetrominoSim.init seed frame
    in
    { state | pieces = SeqDict.empty, occupied = Dict.empty }


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
    TetrominoGame.updateGame (Time.millisToPosix 1000) setup (Coord.xy 1000 800) 1 userA TetrominoGame.PressedJoin model


waitingAt : Int -> TetrominoGame.GameModel -> Maybe (List (Id UserId))
waitingAt frame model =
    TetrominoGame.matchStateAt frame model |> Maybe.map (\state -> SeqSet.toList state.waitingPlayers)


{-| A thrower on its own, standing still, that won't wander off or throw anything for a good
while.
-}
npcAt : Float -> Float -> MatchState -> TetrominoSim.Tower
npcAt x y state =
    towerAt x y (npc 1000 Thrower state) [] state


{-| A tower whose NPCs won't throw anything for a good while, and that won't wander off if it's a
thrower at the bottom.
-}
towerAt : Float -> Float -> TetrominoSim.Npc -> List TetrominoSim.Npc -> MatchState -> TetrominoSim.Tower
towerAt x y bottom above state =
    { position = { x = x, y = y, z = 0 }
    , velocityZ = 0
    , wanderOffset = { x = 0, y = 0 }
    , nextWanderFrame = state.frame + 1000
    , bottom = bottom
    , above = above
    }


npc : Int -> NpcKind -> MatchState -> TetrominoSim.Npc
npc id kind state =
    { id = id, kind = kind, nextThrowFrame = state.frame + 1000 }


{-| The ids of the NPCs in each tower, bottom first.
-}
towerIds : MatchState -> List (List Int)
towerIds state =
    List.map (\tower -> List.map .id (tower.bottom :: tower.above)) state.towers


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
                    |> Expect.equal ( [ Just userA, Just userB ], [ ( Just userB, 0, True ) ] )
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
                            |> (\state -> { state | towers = [ npcAt (toFloat center + 5) (toFloat center) state ] })
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
                                        | towers =
                                            [ towerAt
                                                (player.position.x + 6)
                                                player.position.y
                                                { id = 1000, kind = Thrower, nextThrowFrame = walking.frame }
                                                []
                                                walking
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
                    |> Expect.equal ( [ Just userA ], 0 )
        , test "NPCs turn up near a player, however big the map is" <|
            \_ ->
                let
                    state =
                        runUntil (firstRound + 11 * TetrominoSim.framesPerSecond) [] (inFirstRound [ userA ])
                in
                case state.towers of
                    [] ->
                        Expect.fail "Expected an NPC by now"

                    towers ->
                        List.all
                            (\tower -> abs (tower.position.x - toFloat center) < 14 && abs (tower.position.y - toFloat center) < 14)
                            towers
                            |> Expect.equal True
        , test "Two NPCs that walk into each other become a tower" <|
            \_ ->
                let
                    start : MatchState
                    start =
                        inFirstRound [ userA ]
                in
                { start
                    | towers =
                        [ towerAt (toFloat center + 6) (toFloat center + 0.5) (npc 1 Thrower start) [] start
                        , towerAt (toFloat center + 9) (toFloat center + 0.5) (npc 2 Chaser start) [] start
                        ]
                }
                    |> runUntil (start.frame + 3 * TetrominoSim.framesPerSecond) []
                    |> towerIds
                    |> Expect.equal [ [ 1, 2 ] ]
        , test "An NPC that walks into a tower goes underneath it" <|
            \_ ->
                let
                    start : MatchState
                    start =
                        inFirstRound [ userA ]
                in
                { start
                    | towers =
                        [ towerAt (toFloat center + 6) (toFloat center + 0.5) (npc 1 Thrower start) [ npc 2 Thrower start ] start
                        , towerAt (toFloat center + 9) (toFloat center + 0.5) (npc 3 Chaser start) [] start
                        ]
                }
                    |> runUntil (start.frame + 3 * TetrominoSim.framesPerSecond) []
                    |> towerIds
                    |> Expect.equal [ [ 3, 1, 2 ] ]
        , test "When two towers meet, the smaller one goes underneath" <|
            \_ ->
                let
                    start : MatchState
                    start =
                        inFirstRound [ userA ]
                in
                { start
                    | towers =
                        [ towerAt (toFloat center + 6) (toFloat center + 0.5) (npc 1 Thrower start) [ npc 2 Thrower start ] start
                        , towerAt
                            (toFloat center + 9)
                            (toFloat center + 0.5)
                            (npc 3 Chaser start)
                            [ npc 4 Jumper start, npc 5 Jumper start ]
                            start
                        ]
                }
                    |> runUntil (start.frame + 3 * TetrominoSim.framesPerSecond) []
                    |> towerIds
                    |> Expect.equal [ [ 1, 2, 3, 4, 5 ] ]
        , test "NPCs high enough to clear a wall their tower can't get over carry on over it without the rest" <|
            \_ ->
                let
                    start : MatchState
                    start =
                        inFirstRound [ userA ]
                            |> withBlocks (List.map (\y -> ( center + 2, y, 0 )) (List.range (center - 12) (center + 12)))

                    after : MatchState
                    after =
                        { start
                            | towers =
                                [ towerAt
                                    (toFloat center + 6)
                                    (toFloat center + 0.5)
                                    (npc 1 Chaser start)
                                    [ npc 2 Chaser start, npc 3 Chaser start ]
                                    start
                                ]
                        }
                            |> runUntil (start.frame + 4 * TetrominoSim.framesPerSecond) []
                in
                ( knockedOut after
                , List.map
                    (\tower -> ( List.map .id (tower.bottom :: tower.above), tower.position.x > toFloat center + 3 ))
                    after.towers
                )
                    |> Expect.equal ( Just True, [ ( [ 1, 2 ], True ), ( [ 3 ], False ) ] )
        , test "A thrower throws from wherever it is in a tower" <|
            \_ ->
                let
                    start : MatchState
                    start =
                        inFirstRound [ userA ]

                    throwing : MatchState
                    throwing =
                        TetrominoSim.step
                            []
                            { start
                                | towers =
                                    [ towerAt
                                        (toFloat center + 6.5)
                                        (toFloat center + 0.5)
                                        (npc 1 Chaser start)
                                        [ npc 2 Chaser start, { id = 3, kind = Thrower, nextThrowFrame = start.frame } ]
                                        start
                                    ]
                            }
                in
                List.map (\snowball -> snowball.position.z > 2 * TetrominoSim.entityHeight) throwing.snowballs
                    |> Expect.equal [ True ]
        , test "The canvas covers a whole number of device pixels, whatever the device pixel ratio" <|
            \_ ->
                List.concatMap
                    (\devicePixelRatio ->
                        List.map
                            (\windowWidth ->
                                let
                                    canvas : TetrominoGame.CanvasSize
                                    canvas =
                                        TetrominoGame.canvasSize (Coord.xy windowWidth 800) devicePixelRatio
                                in
                                ( abs (toFloat canvas.width * devicePixelRatio - toFloat canvas.deviceWidth) < 0.001
                                , abs (toFloat canvas.height * devicePixelRatio - toFloat canvas.deviceHeight) < 0.001
                                )
                            )
                            (List.range 700 720)
                    )
                    -- Chrome's ratios at 110%, 133% and 90% zoom, then a few phones and laptops.
                    [ 1, 1.100000023841858, 1.3333333730697632, 0.8999999761581421, 1.25, 1.5, 2, 2.625, 2.75, 3 ]
                    |> List.all (\fits -> fits == ( True, True ))
                    |> Expect.equal True
        , test "The first round only has chasers, later rounds mix in throwers and jumpers" <|
            \_ ->
                let
                    kindsBy : Int -> MatchState -> List NpcKind
                    kindsBy seconds start =
                        let
                            untouchable : MatchState
                            untouchable =
                                { start | players = SeqDict.map (\_ player -> { player | protectedUntil = 1000000 }) start.players }
                        in
                        runUntil (start.frame + seconds * TetrominoSim.framesPerSecond) [] untouchable
                            |> .towers
                            |> List.concatMap TetrominoSim.npcPositions
                            |> List.map (\( npc2, _ ) -> npc2.kind)

                    firstRoundKinds : List NpcKind
                    firstRoundKinds =
                        kindsBy 60 (inFirstRound [ userA ])

                    laterRoundKinds : List NpcKind
                    laterRoundKinds =
                        inFirstRound [ userA ]
                            |> (\state -> { state | round = { number = 2, startedAt = state.frame, nextRoundAt = Nothing } })
                            |> kindsBy 60
                in
                ( List.all (\kind -> kind == Chaser) firstRoundKinds && not (List.isEmpty firstRoundKinds)
                , List.map (\kind -> List.member kind laterRoundKinds) [ Chaser, Thrower, Jumper ]
                )
                    |> Expect.equal ( True, [ True, True, True ] )
        , test "A chaser that reaches a player knocks them out" <|
            \_ ->
                let
                    start : MatchState
                    start =
                        inFirstRound [ userA ]
                in
                { start | towers = [ towerAt (toFloat center + 3) (toFloat center + 0.5) (npc 1000 Chaser start) [] start ] }
                    |> runUntil (start.frame + 2 * TetrominoSim.framesPerSecond) []
                    |> knockedOut
                    |> Expect.equal (Just True)
        , test "A wall one block high stops a chaser, but a jumper hops it" <|
            \_ ->
                let
                    start : MatchState
                    start =
                        inFirstRound [ userA ]
                            |> withBlocks (List.map (\y -> ( center + 2, y, 0 )) (List.range (center - 12) (center + 12)))

                    after : NpcKind -> MatchState
                    after kind =
                        { start | towers = [ towerAt (toFloat center + 6) (toFloat center + 0.5) (npc 1000 kind start) [] start ] }
                            |> runUntil (start.frame + 4 * TetrominoSim.framesPerSecond) []
                in
                ( after Chaser |> knockedOut
                , List.map (\tower -> tower.position.x > toFloat center + 3) (after Chaser).towers
                , after Jumper |> knockedOut
                )
                    |> Expect.equal ( Just False, [ True ], Just True )
        , test "A match starts with pieces lying around, with room to stand in the middle" <|
            \_ ->
                let
                    pieces : List TetrominoSim.Piece
                    pieces =
                        SeqDict.values (TetrominoSim.init 1 0).pieces
                in
                ( List.length pieces > 20
                , List.all (\piece -> piece.owner == Nothing && piece.z == 0 && TetrominoSim.isSettled piece.status) pieces
                , List.any
                    (\piece ->
                        List.any
                            (\( x, y, _ ) -> abs (piece.x + x - center) <= 4 && abs (piece.y + y - center) <= 4)
                            piece.cells
                    )
                    pieces
                )
                    |> Expect.equal ( True, True, False )
        , test "A player has 10 pieces and has to wait a second between drops" <|
            \_ ->
                let
                    start : MatchState
                    start =
                        inFirstRound [ userA ]

                    after : MatchState
                    after =
                        runUntil
                            (firstRound + 200)
                            (dropAt (firstRound + 10) userA 3 3
                                ++ dropAt (firstRound + 40) userA 10 3
                                ++ dropAt (firstRound + 71) userA 17 3
                            )
                            start
                in
                ( SeqDict.get userA start.players |> Maybe.map .piecesLeft
                , SeqDict.get userA after.players |> Maybe.map .piecesLeft
                , SeqDict.size after.pieces
                )
                    |> Expect.equal ( Just 10, Just 8, 2 )
        , test "With no pieces left, dropping does nothing" <|
            \_ ->
                let
                    start : MatchState
                    start =
                        inFirstRound [ userA ]
                in
                { start | players = SeqDict.map (\_ player -> { player | piecesLeft = 0 }) start.players }
                    |> runUntil (firstRound + 100) (dropAt (firstRound + 10) userA 3 3)
                    |> .pieces
                    |> SeqDict.size
                    |> Expect.equal 0
        , test "Dropping takes the piece at the front of the queue and moves the rest up" <|
            \_ ->
                let
                    start : MatchState
                    start =
                        inFirstRound [ userA ]

                    after : MatchState
                    after =
                        runUntil (firstRound + 20) (dropAt (firstRound + 10) userA 3 3) start
                in
                case ( SeqDict.get userA start.players, SeqDict.get userA after.players ) of
                    ( Just before, Just player ) ->
                        ( SeqDict.values after.pieces |> List.map .shape
                        , [ player.queue.current, player.queue.next ]
                        )
                            |> Expect.equal ( [ before.queue.current ], [ before.queue.next, before.queue.afterNext ] )

                    _ ->
                        Expect.fail "Expected the player to be in the round"
        , test "Touching a pickup gives every player two more pieces, up to 15" <|
            \_ ->
                let
                    start : MatchState
                    start =
                        inFirstRound [ userA, userB ]

                    withPickup : MatchState
                    withPickup =
                        case SeqDict.get userA start.players of
                            Just player ->
                                { start
                                    | pickups = [ { id = 1000, x = floor player.position.x, y = floor player.position.y, z = 0 } ]
                                    , players = SeqDict.updateIfExists userB (\playerB -> { playerB | piecesLeft = 14 }) start.players
                                }

                            Nothing ->
                                start

                    after : MatchState
                    after =
                        runUntil (start.frame + 1) [] withPickup
                in
                ( SeqDict.values after.players |> List.map .piecesLeft
                , List.length after.pickups
                )
                    |> Expect.equal ( [ 12, 15 ], 0 )
        , test "Pickups turn up during a round" <|
            \_ ->
                let
                    start : MatchState
                    start =
                        inFirstRound [ userA ]
                in
                { start | players = SeqDict.map (\_ player -> { player | protectedUntil = 1000000 }) start.players }
                    |> runUntil (firstRound + 30 * TetrominoSim.framesPerSecond) []
                    |> .pickups
                    |> List.length
                    |> (\count -> count > 0 && count <= 3)
                    |> Expect.equal True
        , test "A piece that lands on a tower squashes every NPC in it and stays" <|
            \_ ->
                let
                    start : MatchState
                    start =
                        inFirstRound [ userA ]

                    falling : MatchState
                    falling =
                        { start
                            | towers =
                                [ towerAt
                                    (toFloat center + 6.5)
                                    (toFloat center + 0.5)
                                    (npc 1 Thrower start)
                                    [ npc 2 Chaser start, npc 3 Jumper start ]
                                    start
                                ]
                            , pieces =
                                SeqDict.singleton
                                    500
                                    { owner = Just userA
                                    , shape = Tetromino.O
                                    , cells = Tetromino.cells Tetromino.identity Tetromino.O
                                    , x = center + 6
                                    , y = center
                                    , z = 1.5
                                    , status = TetrominoSim.Falling -4
                                    }
                        }

                    after : MatchState
                    after =
                        runUntil (falling.frame + 60) [] falling
                in
                ( List.length after.towers
                , SeqDict.values after.pieces |> List.map (\piece -> ( piece.z, TetrominoSim.isSettled piece.status ))
                )
                    |> Expect.equal ( 0, [ ( 0, True ) ] )
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
