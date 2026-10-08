module TetrominoSim exposing
    ( Debris
    , Input(..)
    , InputEvent
    , MatchState
    , Npc
    , Piece
    , PieceCycle(..)
    , PieceStatus(..)
    , Player
    , Point
    , Round
    , Snowball
    , cycleShape
    , debrisFrames
    , entityHeight
    , entityRadius
    , framesPerSecond
    , gridSize
    , init
    , isProtected
    , isSettled
    , keepInsideGrid
    , roundBreak
    , snowballRadius
    , step
    )

{-| The game itself. Every client runs this on the same inputs and has to land on exactly the
same state, so it sticks to arithmetic and `sqrt` (which every browser rounds the same way) and
stays away from trig, and all randomness comes from the seed in the state.
-}

import Dict exposing (Dict)
import Id exposing (Id, UserId)
import Random
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import Tetromino exposing (Orientation, Shape)


type alias Point =
    { x : Float, y : Float, z : Float }


type Input
    = Join
    | Leave
    | MoveTo Int Int
    | Drop { x : Int, y : Int, orientation : Orientation }
    | StopCycling


type alias InputEvent =
    { frame : Int, userId : Id UserId, input : Input }


type alias MatchState =
    { frame : Int
    , round : Round
    , players : SeqDict (Id UserId) Player
    , waitingPlayers : SeqSet (Id UserId)
    , npcs : List Npc
    , pieces : SeqDict Int Piece
    , occupied : Dict ( Int, Int, Int ) Int
    , snowballs : List Snowball
    , debris : List Debris
    , nextId : Int
    , seed : Random.Seed
    , nextNpcSpawn : Maybe Int
    }


{-| Before the first round `number` is 0. `nextRoundAt` is Nothing while there's nobody to play
in one.
-}
type alias Round =
    { number : Int
    , startedAt : Int
    , nextRoundAt : Maybe Int
    }


{-| Someone who has been in a round. A player who joins while a round is running waits in
`waitingPlayers` instead, and one knocked out sits the rest of the round out.
-}
type alias Player =
    { position : Point
    , velocityZ : Float
    , target : Maybe ( Int, Int )
    , knockedOutAt : Maybe Int
    , cycle : PieceCycle
    , -- Snowballs do nothing to a player until this frame, so that someone coming into a round
      -- isn't knocked straight back out.
      protectedUntil : Int
    }


type PieceCycle
    = Cycling { startFrame : Int, firstIndex : Int, steps : Int }
    | Ready Shape


type alias Npc =
    { id : Int
    , position : Point
    , velocityZ : Float
    , wanderOffset : { x : Float, y : Float }
    , nextWanderFrame : Int
    , nextThrowFrame : Int
    }


type alias Piece =
    { owner : Id UserId
    , shape : Shape
    , cells : List ( Int, Int, Int )
    , x : Int
    , y : Int
    , z : Float
    , status : PieceStatus
    }


{-| A falling piece's vertical speed, or the frame a settled one landed on.
-}
type PieceStatus
    = Falling Float
    | Settled Int


{-| A piece that has just been destroyed, kept for a moment so that it can be drawn breaking apart.
-}
type alias Debris =
    { piece : Piece, destroyedAt : Int }


type alias Snowball =
    { position : Point
    , velocity : Point
    , thrownAt : Int
    }


framesPerSecond : number
framesPerSecond =
    60


frameSeconds : Float
frameSeconds =
    1 / framesPerSecond


gridSize : Int
gridSize =
    64


roundLength : Int
roundLength =
    90 * framesPerSecond


{-| How long after everyone is knocked out (or after the first player joins) the next round
starts.
-}
roundBreak : Int
roundBreak =
    5 * framesPerSecond


{-| NPCs only start turning up a little while into a round, so there is time to build.
-}
npcDelay : Int
npcDelay =
    10 * framesPerSecond


spawnProtection : Int
spawnProtection =
    3 * framesPerSecond


gravity : Float
gravity =
    25


snowballGravity : Float
snowballGravity =
    6


jumpVelocity : Float
jumpVelocity =
    7.6


maxFallSpeed : Float
maxFallSpeed =
    28


playerSpeed : Float
playerSpeed =
    3


npcSpeed : Float
npcSpeed =
    1


entityRadius : Float
entityRadius =
    0.3


entityHeight : Float
entityHeight =
    0.8


snowballRadius : Float
snowballRadius =
    0.15


dropHeight : Float
dropHeight =
    18


npcLimit : Int
npcLimit =
    30


npcThrowRange : Float
npcThrowRange =
    10


npcKeepDistance : Float
npcKeepDistance =
    3


{-| How far off an NPC's aim can be, in cells along each axis.
-}
throwSpread : Float
throwSpread =
    0.7


{-| How much of the way an NPC aims towards where a walking player will be once the snowball
gets there.
-}
throwLead : Float
throwLead =
    0.6


{-| How far from a player an NPC turns up, in cells along each axis.
-}
npcSpawnDistance : Int
npcSpawnDistance =
    12


debrisFrames : Int
debrisFrames =
    30


epsilon : Float
epsilon =
    1.0e-9


{-| A new match, starting on the given frame.
-}
init : Int -> Int -> MatchState
init seed frame =
    { frame = frame
    , round = { number = 0, startedAt = frame, nextRoundAt = Nothing }
    , players = SeqDict.empty
    , waitingPlayers = SeqSet.empty
    , npcs = []
    , pieces = SeqDict.empty
    , occupied = Dict.empty
    , snowballs = []
    , debris = []
    , nextId = 0
    , seed = Random.initialSeed seed
    , nextNpcSpawn = Nothing
    }


{-| Advance by one frame, applying the inputs stamped with this frame first.
-}
step : List InputEvent -> MatchState -> MatchState
step inputs state =
    let
        state2 : MatchState
        state2 =
            List.sortBy (\event -> Id.toInt event.userId) inputs
                |> List.foldl applyInput state

        state3 : MatchState
        state3 =
            updateRound state2 |> updatePlayers |> updateNpcs |> spawnNpcs |> updateSnowballs

        ( state4, removedSettled ) =
            updatePieces state3 |> handleKnockouts

        state5 : MatchState
        state5 =
            if removedSettled then
                dropUnsupportedPieces state4

            else
                state4
    in
    { state5
        | frame = state5.frame + 1
        , debris = List.filter (\debris -> state5.frame - debris.destroyedAt < debrisFrames) state5.debris
    }



-- Inputs


applyInput : InputEvent -> MatchState -> MatchState
applyInput event state =
    case event.input of
        Join ->
            if SeqDict.member event.userId state.players then
                state

            else
                { state | waitingPlayers = SeqSet.insert event.userId state.waitingPlayers }

        Leave ->
            let
                ( state2, removedSettled ) =
                    removePiecesOf
                        [ event.userId ]
                        { state
                            | players = SeqDict.remove event.userId state.players
                            , waitingPlayers = SeqSet.remove event.userId state.waitingPlayers
                        }
            in
            if removedSettled then
                dropUnsupportedPieces state2

            else
                state2

        MoveTo x y ->
            updateAlivePlayer
                event.userId
                (\player -> { player | target = Just ( clamp 0 (gridSize - 1) x, clamp 0 (gridSize - 1) y ) })
                state

        StopCycling ->
            updateAlivePlayer
                event.userId
                (\player ->
                    case player.cycle of
                        Cycling cycle ->
                            { player | cycle = Ready (cycleShape state.frame cycle).shape }

                        Ready _ ->
                            player
                )
                state

        Drop drop ->
            case SeqDict.get event.userId state.players of
                Just player ->
                    case ( player.knockedOutAt, player.cycle ) of
                        ( Nothing, Ready shape ) ->
                            if Tetromino.isValidOrientation drop.orientation then
                                dropPiece event.userId shape drop player state

                            else
                                state

                        _ ->
                            state

                Nothing ->
                    state


updateAlivePlayer : Id UserId -> (Player -> Player) -> MatchState -> MatchState
updateAlivePlayer userId updateFunc state =
    { state
        | players =
            SeqDict.updateIfExists
                userId
                (\player ->
                    case player.knockedOutAt of
                        Just _ ->
                            player

                        Nothing ->
                            updateFunc player
                )
                state.players
    }


dropPiece : Id UserId -> Shape -> { x : Int, y : Int, orientation : Orientation } -> Player -> MatchState -> MatchState
dropPiece userId shape drop player state =
    let
        cells : List ( Int, Int, Int )
        cells =
            Tetromino.cells drop.orientation shape

        ( x, y ) =
            keepInsideGrid cells drop.x drop.y

        ( cycle, seed ) =
            startCycle state.frame state.seed
    in
    { state
        | pieces =
            SeqDict.insert
                state.nextId
                { owner = userId
                , shape = shape
                , cells = cells
                , x = x
                , y = y
                , z = dropHeight
                , status = Falling -4
                }
                state.pieces
        , nextId = state.nextId + 1
        , players = SeqDict.insert userId { player | cycle = cycle } state.players
        , seed = seed
    }


{-| Where a piece aimed at a column ends up, nudged so that none of it hangs off the grid.
-}
keepInsideGrid : List ( Int, Int, Int ) -> Int -> Int -> ( Int, Int )
keepInsideGrid cells column row =
    let
        fit : (( Int, Int, Int ) -> Int) -> Int -> Int
        fit getter position =
            let
                low : Int
                low =
                    List.map getter cells |> List.minimum |> Maybe.withDefault 0

                high : Int
                high =
                    List.map getter cells |> List.maximum |> Maybe.withDefault 0
            in
            clamp -low (gridSize - 1 - high) position
    in
    ( fit (\( cellX, _, _ ) -> cellX) column, fit (\( _, cellY, _ ) -> cellY) row )



-- Rounds


{-| Start the next round when it's due, bringing in everyone who was waiting or knocked out. A
round ends early once nobody in it is left standing.
-}
updateRound : MatchState -> MatchState
updateRound state =
    let
        round : Round
        round =
            state.round

        nobodyStanding : Bool
        nobodyStanding =
            List.all (\player -> player.knockedOutAt /= Nothing) (SeqDict.values state.players)

        anyoneToBringIn : Bool
        anyoneToBringIn =
            not (SeqSet.isEmpty state.waitingPlayers)
                || List.any (\player -> player.knockedOutAt /= Nothing) (SeqDict.values state.players)
    in
    case round.nextRoundAt of
        Just nextRoundAt ->
            if state.frame >= nextRoundAt then
                if anyoneToBringIn || not nobodyStanding then
                    startRound state

                else
                    { state | round = { round | nextRoundAt = Nothing } }

            else if nobodyStanding && nextRoundAt > state.frame + roundBreak then
                { state | round = { round | nextRoundAt = Just (state.frame + roundBreak) } }

            else
                state

        Nothing ->
            if anyoneToBringIn then
                { state | round = { round | nextRoundAt = Just (state.frame + roundBreak) } }

            else
                state


startRound : MatchState -> MatchState
startRound state =
    let
        broughtIn : List (Id UserId)
        broughtIn =
            SeqSet.toList state.waitingPlayers
                ++ List.filterMap
                    (\( userId, player ) ->
                        case player.knockedOutAt of
                            Just _ ->
                                Just userId

                            Nothing ->
                                Nothing
                    )
                    (SeqDict.toList state.players)
                |> List.sortBy Id.toInt

        ( players, seed ) =
            List.foldl
                (\( index, userId ) ( players2, seed2 ) ->
                    let
                        ( cycle, seed3 ) =
                            startCycle state.frame seed2

                        ( offsetX, offsetY ) =
                            spawnOffset index

                        column : Int
                        column =
                            gridSize // 2 + offsetX

                        row : Int
                        row =
                            gridSize // 2 + offsetY

                        -- Protection only matters with an NPC close enough to throw at the spot,
                        -- which in the first round there never is.
                        npcNearby : Bool
                        npcNearby =
                            List.any
                                (\npc ->
                                    horizontalDistance npc.position { x = toFloat column + 0.5, y = toFloat row + 0.5, z = 0 }
                                        <= npcThrowRange
                                )
                                state.npcs
                    in
                    ( SeqDict.insert
                        userId
                        { position =
                            { x = toFloat column + 0.5
                            , y = toFloat row + 0.5
                            , z = toFloat (topOfColumn column row state)
                            }
                        , velocityZ = 0
                        , target = Nothing
                        , knockedOutAt = Nothing
                        , cycle = cycle
                        , protectedUntil =
                            if npcNearby then
                                state.frame + spawnProtection

                            else
                                state.frame
                        }
                        players2
                    , seed3
                    )
                )
                ( state.players, state.seed )
                (List.indexedMap Tuple.pair broughtIn)
    in
    { state
        | round =
            { number = state.round.number + 1
            , startedAt = state.frame
            , nextRoundAt = Just (state.frame + roundLength)
            }
        , players = players
        , waitingPlayers = SeqSet.empty
        , seed = seed
        , nextNpcSpawn = Just (state.frame + npcDelay)
    }


{-| Where around the middle of the grid each player brought into a round appears, so that they
don't all start on top of each other.
-}
spawnOffset : Int -> ( Int, Int )
spawnOffset index =
    case List.drop (modBy 9 index) [ ( 0, 0 ), ( 1, 0 ), ( 0, 1 ), ( -1, 0 ), ( 0, -1 ), ( 1, 1 ), ( -1, -1 ), ( 1, -1 ), ( -1, 1 ) ] of
        offset :: _ ->
            offset

        [] ->
            ( 0, 0 )



-- Piece preview cycle


startCycle : Int -> Random.Seed -> ( PieceCycle, Random.Seed )
startCycle frame seed =
    Random.step
        (Random.map2
            (\firstIndex steps -> Cycling { startFrame = frame, firstIndex = firstIndex, steps = steps })
            (Random.int 0 (List.length Tetromino.all - 1))
            (Random.int 16 19)
        )
        seed


cycleStepFrames : Int -> Int
cycleStepFrames stepIndex =
    2 + (stepIndex * stepIndex) // 12


{-| Which piece a spinning preview shows on the given frame, and whether it has come to rest.
-}
cycleShape : Int -> { startFrame : Int, firstIndex : Int, steps : Int } -> { shape : Shape, finished : Bool }
cycleShape frame cycle =
    let
        stepIndex : Int
        stepIndex =
            cycleShapeHelper (frame - cycle.startFrame) cycle.steps 0
    in
    { shape = shapeAt (cycle.firstIndex + stepIndex)
    , finished = stepIndex >= cycle.steps - 1
    }


cycleShapeHelper : Int -> Int -> Int -> Int
cycleShapeHelper framesLeft steps stepIndex =
    if stepIndex >= steps - 1 || framesLeft < cycleStepFrames stepIndex then
        stepIndex

    else
        cycleShapeHelper (framesLeft - cycleStepFrames stepIndex) steps (stepIndex + 1)


shapeAt : Int -> Shape
shapeAt index =
    case List.drop (modBy (List.length Tetromino.all) index) Tetromino.all of
        shape :: _ ->
            shape

        [] ->
            Tetromino.I



-- Players and NPCs


updatePlayers : MatchState -> MatchState
updatePlayers state =
    { state
        | players =
            SeqDict.map
                (\_ player ->
                    case player.knockedOutAt of
                        Just _ ->
                            player

                        Nothing ->
                            let
                                player2 : Player
                                player2 =
                                    case player.cycle of
                                        Cycling cycle ->
                                            let
                                                shown : { shape : Shape, finished : Bool }
                                                shown =
                                                    cycleShape state.frame cycle
                                            in
                                            if shown.finished then
                                                { player | cycle = Ready shown.shape }

                                            else
                                                player

                                        Ready _ ->
                                            player
                            in
                            moveEntity
                                playerSpeed
                                (Maybe.map
                                    (\( x, y ) -> { x = toFloat x + 0.5, y = toFloat y + 0.5 })
                                    player2.target
                                )
                                state.occupied
                                player2
                )
                state.players
    }


updateNpcs : MatchState -> MatchState
updateNpcs state =
    let
        alivePlayers : List Player
        alivePlayers =
            SeqDict.values state.players |> List.filter (\player -> player.knockedOutAt == Nothing)

        ( npcs, snowballs, seed ) =
            List.foldr
                (\npc ( npcList, snowballList, seed2 ) ->
                    let
                        ( npc2, maybeSnowball, seed3 ) =
                            updateNpc state.frame alivePlayers state.occupied seed2 npc
                    in
                    ( npc2 :: npcList
                    , case maybeSnowball of
                        Just snowball ->
                            snowball :: snowballList

                        Nothing ->
                            snowballList
                    , seed3
                    )
                )
                ( [], state.snowballs, state.seed )
                state.npcs
    in
    { state | npcs = npcs, snowballs = snowballs, seed = seed }


updateNpc : Int -> List Player -> Dict ( Int, Int, Int ) Int -> Random.Seed -> Npc -> ( Npc, Maybe Snowball, Random.Seed )
updateNpc frame alivePlayers occupied seed npc =
    let
        ( npc2, seed2 ) =
            if frame >= npc.nextWanderFrame then
                Random.step
                    (Random.map3
                        (\x y delay -> { npc | wanderOffset = { x = x, y = y }, nextWanderFrame = frame + delay })
                        (Random.float -2 2)
                        (Random.float -2 2)
                        (Random.int (2 * framesPerSecond) (4 * framesPerSecond))
                    )
                    seed

            else
                ( npc, seed )
    in
    case nearestPlayer npc2.position alivePlayers of
        Just ( player, distance ) ->
            let
                npc3 : Npc
                npc3 =
                    moveEntity
                        npcSpeed
                        (if distance > npcKeepDistance then
                            Just { x = player.position.x + npc2.wanderOffset.x, y = player.position.y + npc2.wanderOffset.y }

                         else
                            Nothing
                        )
                        occupied
                        npc2
            in
            if distance <= npcThrowRange && frame >= npc3.nextThrowFrame then
                let
                    ( ( delay, missX, missY ), seed3 ) =
                        Random.step
                            (Random.map3
                                (\a b c -> ( a, b, c ))
                                (Random.int 100 200)
                                (Random.float -throwSpread throwSpread)
                                (Random.float -throwSpread throwSpread)
                            )
                            seed2

                    lead : { x : Float, y : Float }
                    lead =
                        walkingLead (snowballFlightTime distance * throwLead) player

                    aim : Point
                    aim =
                        { x = player.position.x + lead.x + missX
                        , y = player.position.y + lead.y + missY
                        , z = player.position.z
                        }
                in
                ( { npc3 | nextThrowFrame = frame + delay }
                , Just (throwSnowball frame npc3.position aim)
                , seed3
                )

            else
                ( npc3, Nothing, seed2 )

        Nothing ->
            ( moveEntity npcSpeed Nothing occupied npc2, Nothing, seed2 )


nearestPlayer : Point -> List Player -> Maybe ( Player, Float )
nearestPlayer position players =
    List.foldl
        (\player nearest ->
            let
                distance : Float
                distance =
                    horizontalDistance position player.position
            in
            case nearest of
                Just ( _, nearestDistance ) ->
                    if distance < nearestDistance then
                        Just ( player, distance )

                    else
                        nearest

                Nothing ->
                    Just ( player, distance )
        )
        Nothing
        players


horizontalDistance : Point -> Point -> Float
horizontalDistance a b =
    sqrt ((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y))


{-| How far a player will have walked in the given time, stopping where they're headed.
-}
walkingLead : Float -> Player -> { x : Float, y : Float }
walkingLead seconds player =
    case player.target of
        Just ( column, row ) ->
            let
                dx : Float
                dx =
                    toFloat column + 0.5 - player.position.x

                dy : Float
                dy =
                    toFloat row + 0.5 - player.position.y

                distance : Float
                distance =
                    sqrt (dx * dx + dy * dy)

                walked : Float
                walked =
                    min distance (playerSpeed * seconds)
            in
            if distance < 0.01 then
                { x = 0, y = 0 }

            else
                { x = dx / distance * walked, y = dy / distance * walked }

        Nothing ->
            { x = 0, y = 0 }


snowballFlightTime : Float -> Float
snowballFlightTime distance =
    0.7 + 0.1 * distance


throwSnowball : Int -> Point -> Point -> Snowball
throwSnowball frame from to =
    let
        start : Point
        start =
            { from | z = from.z + entityHeight + 0.1 }

        dx : Float
        dx =
            to.x - start.x

        dy : Float
        dy =
            to.y - start.y

        dz : Float
        dz =
            to.z + entityHeight / 2 - start.z

        flightTime : Float
        flightTime =
            snowballFlightTime (sqrt (dx * dx + dy * dy))
    in
    { position = start
    , velocity =
        { x = dx / flightTime
        , y = dy / flightTime
        , z = (dz + 0.5 * snowballGravity * flightTime * flightTime) / flightTime
        }
    , thrownAt = frame
    }


{-| NPCs turn up a little way off from one of the players still standing, so that how soon they
arrive doesn't depend on where on the map everyone is.
-}
spawnNpcs : MatchState -> MatchState
spawnNpcs state =
    case state.nextNpcSpawn of
        Just spawnFrame ->
            if state.frame >= spawnFrame then
                let
                    alivePlayers : List Player
                    alivePlayers =
                        SeqDict.values state.players |> List.filter (\player -> player.knockedOutAt == Nothing)

                    ( ( playerIndex, side, along ), seed ) =
                        Random.step
                            (Random.map3
                                (\a b c -> ( a, b, c ))
                                (Random.int 0 (max 0 (List.length alivePlayers - 1)))
                                (Random.int 0 3)
                                (Random.int -npcSpawnDistance npcSpawnDistance)
                            )
                            state.seed

                    ( offsetX, offsetY ) =
                        case side of
                            0 ->
                                ( along, -npcSpawnDistance )

                            1 ->
                                ( along, npcSpawnDistance )

                            2 ->
                                ( -npcSpawnDistance, along )

                            _ ->
                                ( npcSpawnDistance, along )

                    npcs : List Npc
                    npcs =
                        case List.drop playerIndex alivePlayers of
                            player :: _ ->
                                if List.length state.npcs < npcLimit then
                                    let
                                        x : Int
                                        x =
                                            clamp 0 (gridSize - 1) (floor player.position.x + offsetX)

                                        y : Int
                                        y =
                                            clamp 0 (gridSize - 1) (floor player.position.y + offsetY)
                                    in
                                    state.npcs
                                        ++ [ { id = state.nextId
                                             , position = { x = toFloat x + 0.5, y = toFloat y + 0.5, z = toFloat (topOfColumn x y state) }
                                             , velocityZ = 0
                                             , wanderOffset = { x = 0, y = 0 }
                                             , nextWanderFrame = state.frame
                                             , nextThrowFrame = state.frame + 2 * framesPerSecond
                                             }
                                           ]

                                else
                                    state.npcs

                            [] ->
                                state.npcs
                in
                { state
                    | npcs = npcs
                    , nextId = state.nextId + 1
                    , seed = seed
                    , nextNpcSpawn = Just (state.frame + npcSpawnInterval (state.frame - state.round.startedAt))
                }

            else
                state

        Nothing ->
            state


npcSpawnInterval : Int -> Int
npcSpawnInterval framesIntoRound =
    max (3 * framesPerSecond) (8 * framesPerSecond - framesIntoRound // 30)


{-| Walk towards a target, hopping onto anything one cell high, and fall under gravity.
-}
moveEntity : Float -> Maybe { x : Float, y : Float } -> Dict ( Int, Int, Int ) Int -> { a | position : Point, velocityZ : Float } -> { a | position : Point, velocityZ : Float }
moveEntity speed maybeTarget occupied entity =
    let
        position : Point
        position =
            if entityCollides occupied entity.position then
                { x = entity.position.x, y = entity.position.y, z = toFloat (floor entity.position.z + 1) }

            else
                entity.position

        grounded : Bool
        grounded =
            entityCollides occupied { position | z = position.z - 0.01 }

        ( afterWalk, wantsToJump ) =
            case maybeTarget of
                Just target ->
                    let
                        dx : Float
                        dx =
                            target.x - position.x

                        dy : Float
                        dy =
                            target.y - position.y

                        distance : Float
                        distance =
                            sqrt (dx * dx + dy * dy)
                    in
                    if distance < 0.001 then
                        ( position, False )

                    else
                        let
                            ( nextX, nextY ) =
                                if distance <= speed * frameSeconds then
                                    ( target.x, target.y )

                                else
                                    ( position.x + dx / distance * speed * frameSeconds
                                    , position.y + dy / distance * speed * frameSeconds
                                    )

                            ( afterX, blockedX ) =
                                tryMove occupied { position | x = nextX } position

                            ( afterY, blockedY ) =
                                tryMove occupied { afterX | y = nextY } afterX
                        in
                        ( afterY
                        , (blockedX && canHop occupied position { position | x = nextX })
                            || (blockedY && canHop occupied afterX { afterX | y = nextY })
                        )

                Nothing ->
                    ( position, False )

        velocityZ : Float
        velocityZ =
            if grounded && wantsToJump then
                jumpVelocity

            else
                max -maxFallSpeed (entity.velocityZ - gravity * frameSeconds)

        newZ : Float
        newZ =
            afterWalk.z + velocityZ * frameSeconds
    in
    if velocityZ <= 0 then
        if entityCollides occupied { afterWalk | z = newZ } then
            { entity | position = { afterWalk | z = max 0 (toFloat (floor newZ + 1)) }, velocityZ = 0 }

        else
            { entity | position = { afterWalk | z = newZ }, velocityZ = velocityZ }

    else if entityCollides occupied { afterWalk | z = newZ } then
        { entity | position = afterWalk, velocityZ = 0 }

    else
        { entity | position = { afterWalk | z = newZ }, velocityZ = velocityZ }


tryMove : Dict ( Int, Int, Int ) Int -> Point -> Point -> ( Point, Bool )
tryMove occupied candidate current =
    if entityCollides occupied candidate then
        ( current, True )

    else
        ( candidate, False )


canHop : Dict ( Int, Int, Int ) Int -> Point -> Point -> Bool
canHop occupied current candidate =
    not (entityCollides occupied { current | z = current.z + 1.05 })
        && not (entityCollides occupied { candidate | z = candidate.z + 1.05 })


entityCollides : Dict ( Int, Int, Int ) Int -> Point -> Bool
entityCollides occupied position =
    if
        (position.z < 0)
            || (position.x - entityRadius < 0)
            || (position.y - entityRadius < 0)
            || (position.x + entityRadius > toFloat gridSize)
            || (position.y + entityRadius > toFloat gridSize)
    then
        True

    else
        boxCollides
            occupied
            (floor (position.x - entityRadius))
            (floor (position.x + entityRadius - epsilon))
            (floor (position.y - entityRadius))
            (floor (position.y + entityRadius - epsilon))
            (floor position.z)
            (floor (position.z + entityHeight - epsilon))


boxCollides : Dict ( Int, Int, Int ) Int -> Int -> Int -> Int -> Int -> Int -> Int -> Bool
boxCollides occupied minX maxX minY maxY minZ maxZ =
    List.any
        (\cellX ->
            List.any
                (\cellY -> List.any (\cellZ -> Dict.member ( cellX, cellY, cellZ ) occupied) (List.range minZ maxZ))
                (List.range minY maxY)
        )
        (List.range minX maxX)


{-| The height of the first free cell in a column, counting up from the top block.
-}
topOfColumn : Int -> Int -> MatchState -> Int
topOfColumn column row state =
    Dict.foldl
        (\( cellX, cellY, cellZ ) _ top ->
            if cellX == column && cellY == row then
                max top (cellZ + 1)

            else
                top
        )
        0
        state.occupied



-- Snowballs


updateSnowballs : MatchState -> MatchState
updateSnowballs state =
    let
        ( snowballs, players ) =
            List.foldr
                (\snowball ( kept, players2 ) ->
                    let
                        velocity : Point
                        velocity =
                            snowball.velocity

                        velocity2 : Point
                        velocity2 =
                            { velocity | z = velocity.z - snowballGravity * frameSeconds }

                        position : Point
                        position =
                            { x = snowball.position.x + velocity2.x * frameSeconds
                            , y = snowball.position.y + velocity2.y * frameSeconds
                            , z = snowball.position.z + velocity2.z * frameSeconds
                            }

                        hitPlayer : Maybe (Id UserId)
                        hitPlayer =
                            SeqDict.foldl
                                (\userId player found ->
                                    case found of
                                        Just _ ->
                                            found

                                        Nothing ->
                                            if player.knockedOutAt == Nothing && snowballHitsEntity position player.position then
                                                Just userId

                                            else
                                                Nothing
                                )
                                Nothing
                                players2
                    in
                    case hitPlayer of
                        Just userId ->
                            ( kept
                            , SeqDict.updateIfExists
                                userId
                                (\player ->
                                    if isProtected state.frame player then
                                        player

                                    else
                                        { player | knockedOutAt = Just state.frame, target = Nothing }
                                )
                                players2
                            )

                        Nothing ->
                            if
                                (position.z <= 0)
                                    || (state.frame - snowball.thrownAt > 6 * framesPerSecond)
                                    || Dict.member ( floor position.x, floor position.y, floor position.z ) state.occupied
                            then
                                ( kept, players2 )

                            else
                                ( { snowball | position = position, velocity = velocity2 } :: kept, players2 )
                )
                ( [], state.players )
                state.snowballs
    in
    { state | snowballs = snowballs, players = players }


isProtected : Int -> Player -> Bool
isProtected frame player =
    frame < player.protectedUntil


snowballHitsEntity : Point -> Point -> Bool
snowballHitsEntity snowball entity =
    (snowball.x > entity.x - entityRadius - snowballRadius)
        && (snowball.x < entity.x + entityRadius + snowballRadius)
        && (snowball.y > entity.y - entityRadius - snowballRadius)
        && (snowball.y < entity.y + entityRadius + snowballRadius)
        && (snowball.z > entity.z - snowballRadius)
        && (snowball.z < entity.z + entityHeight + snowballRadius)



-- Pieces


pieceCells : Piece -> List ( Int, Int, Int )
pieceCells piece =
    let
        level : Int
        level =
            floor piece.z
    in
    List.map (\( offsetX, offsetY, offsetZ ) -> ( piece.x + offsetX, piece.y + offsetY, level + offsetZ )) piece.cells


fitsAt : Int -> Piece -> Dict ( Int, Int, Int ) Int -> Bool
fitsAt level piece occupied =
    List.all
        (\( offsetX, offsetY, offsetZ ) ->
            level + offsetZ >= 0 && not (Dict.member ( piece.x + offsetX, piece.y + offsetY, level + offsetZ ) occupied)
        )
        piece.cells


firstFreeLevel : Int -> Int -> Piece -> Dict ( Int, Int, Int ) Int -> Maybe Int
firstFreeLevel level triesLeft piece occupied =
    if triesLeft <= 0 then
        Nothing

    else if fitsAt level piece occupied then
        Just level

    else
        firstFreeLevel (level + 1) (triesLeft - 1) piece occupied


pieceOverlapsEntity : Piece -> Float -> Point -> Bool
pieceOverlapsEntity piece level entity =
    List.any
        (\( offsetX, offsetY, offsetZ ) ->
            let
                cellX : Float
                cellX =
                    toFloat (piece.x + offsetX)

                cellY : Float
                cellY =
                    toFloat (piece.y + offsetY)

                cellZ : Float
                cellZ =
                    level + toFloat offsetZ
            in
            (entity.x + entityRadius > cellX)
                && (entity.x - entityRadius < cellX + 1)
                && (entity.y + entityRadius > cellY)
                && (entity.y - entityRadius < cellY + 1)
                && (entity.z + entityHeight > cellZ)
                && (entity.z < cellZ + 1)
        )
        piece.cells


{-| Move every falling piece down. A piece that comes down on an NPC takes the NPC with it, and
one that comes down on a player is lost.
-}
updatePieces : MatchState -> MatchState
updatePieces state =
    SeqDict.foldl
        (\pieceId piece state2 ->
            case piece.status of
                Falling velocity ->
                    let
                        velocity2 : Float
                        velocity2 =
                            max -maxFallSpeed (velocity - gravity * frameSeconds)

                        newZ : Float
                        newZ =
                            piece.z + velocity2 * frameSeconds

                        landing : Maybe (Maybe Int)
                        landing =
                            if fitsAt (floor newZ) piece state2.occupied then
                                Nothing

                            else
                                Just (firstFreeLevel (floor newZ + 1) 40 piece state2.occupied)

                        finalZ : Float
                        finalZ =
                            case landing of
                                Just (Just level) ->
                                    toFloat level

                                _ ->
                                    newZ

                        hitNpcs : List Npc
                        hitNpcs =
                            List.filter (\npc -> pieceOverlapsEntity piece finalZ npc.position) state2.npcs

                        hitPlayer : Bool
                        hitPlayer =
                            List.any
                                (\player -> player.knockedOutAt == Nothing && pieceOverlapsEntity piece finalZ player.position)
                                (SeqDict.values state2.players)
                    in
                    if not (List.isEmpty hitNpcs) then
                        { state2
                            | pieces = SeqDict.remove pieceId state2.pieces
                            , npcs = List.filter (\npc -> not (List.member npc hitNpcs)) state2.npcs
                            , debris = { piece = { piece | z = finalZ }, destroyedAt = state2.frame } :: state2.debris
                        }

                    else if hitPlayer then
                        { state2
                            | pieces = SeqDict.remove pieceId state2.pieces
                            , debris = { piece = { piece | z = finalZ }, destroyedAt = state2.frame } :: state2.debris
                        }

                    else
                        case landing of
                            Just (Just level) ->
                                let
                                    piece2 : Piece
                                    piece2 =
                                        { piece | z = toFloat level, status = Settled state2.frame }
                                in
                                { state2
                                    | pieces = SeqDict.insert pieceId piece2 state2.pieces
                                    , occupied =
                                        List.foldl
                                            (\cell occupied -> Dict.insert cell pieceId occupied)
                                            state2.occupied
                                            (pieceCells piece2)
                                }

                            Just Nothing ->
                                { state2
                                    | pieces = SeqDict.remove pieceId state2.pieces
                                    , debris = { piece = { piece | z = newZ }, destroyedAt = state2.frame } :: state2.debris
                                }

                            Nothing ->
                                { state2 | pieces = SeqDict.insert pieceId { piece | z = newZ, status = Falling velocity2 } state2.pieces }

                Settled _ ->
                    state2
        )
        state
        state.pieces


{-| A player knocked out this frame takes all their pieces with them. The Bool says whether any
of those had settled, since that can leave others hanging in the air.
-}
handleKnockouts : MatchState -> ( MatchState, Bool )
handleKnockouts state =
    let
        justKnockedOut : List (Id UserId)
        justKnockedOut =
            SeqDict.foldr
                (\userId player list ->
                    if player.knockedOutAt == Just state.frame then
                        userId :: list

                    else
                        list
                )
                []
                state.players
    in
    case justKnockedOut of
        [] ->
            ( state, False )

        _ ->
            removePiecesOf justKnockedOut state


removePiecesOf : List (Id UserId) -> MatchState -> ( MatchState, Bool )
removePiecesOf owners state =
    let
        ( removed, kept ) =
            SeqDict.partition (\_ piece -> List.member piece.owner owners) state.pieces
    in
    ( { state
        | pieces = kept
        , occupied = Dict.filter (\_ pieceId -> not (SeqDict.member pieceId removed)) state.occupied
        , debris =
            SeqDict.foldl (\_ piece debris -> { piece = piece, destroyedAt = state.frame } :: debris) state.debris removed
      }
    , SeqDict.foldl (\_ piece anySettled -> anySettled || isSettled piece.status) False removed
    )


{-| Let go of every settled piece that has nothing under it any more. Letting go of one can
leave others without support, so this repeats until nothing changes.
-}
dropUnsupportedPieces : MatchState -> MatchState
dropUnsupportedPieces state =
    let
        unsupported : List Int
        unsupported =
            SeqDict.foldr
                (\pieceId piece list ->
                    if isSettled piece.status && not (isSupported pieceId piece state.occupied) then
                        pieceId :: list

                    else
                        list
                )
                []
                state.pieces
    in
    case unsupported of
        [] ->
            state

        _ ->
            dropUnsupportedPieces
                { state
                    | pieces =
                        SeqDict.map
                            (\pieceId piece ->
                                if List.member pieceId unsupported then
                                    { piece | status = Falling 0 }

                                else
                                    piece
                            )
                            state.pieces
                    , occupied = Dict.filter (\_ pieceId -> not (List.member pieceId unsupported)) state.occupied
                }


isSettled : PieceStatus -> Bool
isSettled status =
    case status of
        Falling _ ->
            False

        Settled _ ->
            True


isSupported : Int -> Piece -> Dict ( Int, Int, Int ) Int -> Bool
isSupported pieceId piece occupied =
    List.any
        (\( x, y, z ) ->
            z
                == 0
                || (case Dict.get ( x, y, z - 1 ) occupied of
                        Just below ->
                            below /= pieceId

                        Nothing ->
                            False
                   )
        )
        (pieceCells piece)
