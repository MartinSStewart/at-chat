module TetrominoSim exposing
    ( Input(..)
    , InputEvent
    , MatchState
    , Npc
    , Piece
    , PieceCycle(..)
    , PieceStatus(..)
    , Player
    , Point
    , Snowball
    , cycleShape
    , entityHeight
    , entityRadius
    , framesPerSecond
    , gridSize
    , init
    , isOver
    , keepInsideGrid
    , maxHealth
    , pieceCells
    , snowballRadius
    , step
    , topOfColumn
    )

{-| The game itself. Every client runs this on the same inputs and has to land on exactly the
same state, so it sticks to arithmetic and `sqrt` (which every browser rounds the same way) and
stays away from trig, and all randomness comes from the seed in the state.
-}

import Dict exposing (Dict)
import Id exposing (Id, UserId)
import Random
import SeqDict exposing (SeqDict)
import Tetromino exposing (Orientation, Shape)


type alias Point =
    { x : Float, y : Float, z : Float }


type Input
    = Join
    | MoveTo Int Int
    | Drop { x : Int, y : Int, orientation : Orientation }
    | StopCycling


type alias InputEvent =
    { frame : Int, userId : Id UserId, input : Input }


type alias MatchState =
    { frame : Int
    , players : SeqDict (Id UserId) Player
    , npcs : List Npc
    , pieces : SeqDict Int Piece
    , occupied : Dict ( Int, Int, Int ) Int
    , snowballs : List Snowball
    , nextId : Int
    , seed : Random.Seed
    , nextNpcSpawn : Maybe Int
    }


type alias Player =
    { position : Point
    , velocityZ : Float
    , target : Maybe ( Int, Int )
    , health : Int
    , diedAt : Maybe Int
    , hitAt : Maybe Int
    , cycle : PieceCycle
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


type PieceStatus
    = Falling Float
    | Settled


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
    24


maxHealth : Int
maxHealth =
    3


gravity : Float
gravity =
    25


snowballGravity : Float
snowballGravity =
    12


jumpVelocity : Float
jumpVelocity =
    7.6


maxFallSpeed : Float
maxFallSpeed =
    28


playerSpeed : Float
playerSpeed =
    4


npcSpeed : Float
npcSpeed =
    1.3


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


epsilon : Float
epsilon =
    1.0e-9


init : Int -> MatchState
init seed =
    { frame = 0
    , players = SeqDict.empty
    , npcs = []
    , pieces = SeqDict.empty
    , occupied = Dict.empty
    , snowballs = []
    , nextId = 0
    , seed = Random.initialSeed seed
    , nextNpcSpawn = Nothing
    }


{-| A match is over once someone has played and everyone who played has died.
-}
isOver : MatchState -> Bool
isOver state =
    not (SeqDict.isEmpty state.players)
        && List.all (\player -> player.diedAt /= Nothing) (SeqDict.values state.players)


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
            updatePlayers state2 |> updateNpcs |> spawnNpcs |> updateSnowballs

        ( state4, removedSettled ) =
            updatePieces state3 |> handleDeaths

        state5 : MatchState
        state5 =
            if removedSettled then
                dropUnsupportedPieces state4

            else
                state4
    in
    { state5 | frame = state5.frame + 1 }



-- Inputs


applyInput : InputEvent -> MatchState -> MatchState
applyInput event state =
    case event.input of
        Join ->
            if SeqDict.member event.userId state.players then
                state

            else
                let
                    ( cycle, seed ) =
                        startCycle state.frame state.seed

                    center : Int
                    center =
                        gridSize // 2
                in
                { state
                    | players =
                        SeqDict.insert
                            event.userId
                            { position =
                                { x = toFloat center + 0.5
                                , y = toFloat center + 0.5
                                , z = toFloat (topOfColumn center center state)
                                }
                            , velocityZ = 0
                            , target = Nothing
                            , health = maxHealth
                            , diedAt = Nothing
                            , hitAt = Nothing
                            , cycle = cycle
                            }
                            state.players
                    , seed = seed
                    , nextNpcSpawn =
                        case state.nextNpcSpawn of
                            Just _ ->
                                state.nextNpcSpawn

                            Nothing ->
                                Just (state.frame + 4 * framesPerSecond)
                }

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
                    case ( player.diedAt, player.cycle ) of
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
                    case player.diedAt of
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
                    case player.diedAt of
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
            SeqDict.values state.players |> List.filter (\player -> player.diedAt == Nothing)

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
                    ( delay, seed3 ) =
                        Random.step (Random.int 100 200) seed2
                in
                ( { npc3 | nextThrowFrame = frame + delay }
                , Just (throwSnowball frame npc3.position player.position)
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
            0.5 + 0.07 * sqrt (dx * dx + dy * dy)
    in
    { position = start
    , velocity =
        { x = dx / flightTime
        , y = dy / flightTime
        , z = (dz + 0.5 * snowballGravity * flightTime * flightTime) / flightTime
        }
    , thrownAt = frame
    }


spawnNpcs : MatchState -> MatchState
spawnNpcs state =
    case state.nextNpcSpawn of
        Just spawnFrame ->
            if state.frame >= spawnFrame then
                let
                    ( ( side, along ), seed ) =
                        Random.step
                            (Random.pair (Random.int 0 3) (Random.int 0 (gridSize - 1)))
                            state.seed

                    ( x, y ) =
                        case side of
                            0 ->
                                ( along, 0 )

                            1 ->
                                ( along, gridSize - 1 )

                            2 ->
                                ( 0, along )

                            _ ->
                                ( gridSize - 1, along )

                    anyoneAlive : Bool
                    anyoneAlive =
                        List.any (\player -> player.diedAt == Nothing) (SeqDict.values state.players)
                in
                { state
                    | npcs =
                        if List.length state.npcs < npcLimit && anyoneAlive then
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
                    , nextId = state.nextId + 1
                    , seed = seed
                    , nextNpcSpawn = Just (state.frame + npcSpawnInterval state.frame)
                }

            else
                state

        Nothing ->
            state


npcSpawnInterval : Int -> Int
npcSpawnInterval frame =
    max (2 * framesPerSecond) (7 * framesPerSecond - frame // 20)


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
                                            if player.diedAt == Nothing && snowballHitsEntity position player.position then
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
                                (\player -> { player | health = player.health - 1, hitAt = Just state.frame })
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
                                (\player -> player.diedAt == Nothing && pieceOverlapsEntity piece finalZ player.position)
                                (SeqDict.values state2.players)
                    in
                    if not (List.isEmpty hitNpcs) then
                        { state2
                            | pieces = SeqDict.remove pieceId state2.pieces
                            , npcs = List.filter (\npc -> not (List.member npc hitNpcs)) state2.npcs
                        }

                    else if hitPlayer then
                        { state2 | pieces = SeqDict.remove pieceId state2.pieces }

                    else
                        case landing of
                            Just (Just level) ->
                                let
                                    piece2 : Piece
                                    piece2 =
                                        { piece | z = toFloat level, status = Settled }
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
                                { state2 | pieces = SeqDict.remove pieceId state2.pieces }

                            Nothing ->
                                { state2 | pieces = SeqDict.insert pieceId { piece | z = newZ, status = Falling velocity2 } state2.pieces }

                Settled ->
                    state2
        )
        state
        state.pieces


handleDeaths : MatchState -> ( MatchState, Bool )
handleDeaths state =
    let
        justDied : List (Id UserId)
        justDied =
            SeqDict.foldr
                (\userId player list ->
                    if player.health <= 0 && player.diedAt == Nothing then
                        userId :: list

                    else
                        list
                )
                []
                state.players
    in
    case justDied of
        [] ->
            ( state, False )

        _ ->
            let
                ( removed, kept ) =
                    SeqDict.partition (\_ piece -> List.member piece.owner justDied) state.pieces
            in
            ( { state
                | players =
                    SeqDict.map
                        (\userId player ->
                            if List.member userId justDied then
                                { player | diedAt = Just state.frame, target = Nothing }

                            else
                                player
                        )
                        state.players
                , pieces = kept
                , occupied = Dict.filter (\_ pieceId -> not (SeqDict.member pieceId removed)) state.occupied
              }
            , SeqDict.foldl (\_ piece anySettled -> anySettled || piece.status == Settled) False removed
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
                    if piece.status == Settled && not (isSupported pieceId piece state.occupied) then
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
