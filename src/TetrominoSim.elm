module TetrominoSim exposing
    ( Behaviour(..)
    , Blocks
    , Crystal
    , Debris
    , Giant
    , Input(..)
    , InputEvent
    , MatchState
    , Npc
    , NpcKind(..)
    , Pickup
    , Piece
    , PieceQueue
    , PieceStatus(..)
    , Player
    , Point
    , Snowball
    , Tower
    , Walk
    , WallFollow
    , WallSide(..)
    , blocksOf
    , canDrop
    , coversCrystal
    , crystalCenter
    , crystalHealth
    , crystalHeight
    , debrisFrames
    , entityHeight
    , entityRadius
    , framesPerSecond
    , giantHeight
    , giantRadius
    , gridSize
    , init
    , insertBlock
    , isGameOver
    , isProtected
    , isSettled
    , keepInsideGrid
    , maxPieces
    , npcCount
    , npcPositions
    , respawnDelay
    , snowballGravity
    , snowballRadius
    , step
    )

{-| The game itself. Every client runs this on the same inputs and has to land on exactly the
same state, so it sticks to arithmetic and `sqrt` (which every browser rounds the same way) and
stays away from trig, and all randomness comes from the seed in the state.
-}

import Array exposing (Array)
import Bitwise
import Dict exposing (Dict)
import Id exposing (Id, UserId)
import Random
import SeqDict exposing (SeqDict)
import Tetromino exposing (Orientation, Shape)


type alias Point =
    { x : Float, y : Float, z : Float }


type Input
    = Join
    | Leave
    | MoveTo Int Int
    | Drop { x : Int, y : Int, orientation : Orientation }


type alias InputEvent =
    { frame : Int, userId : Id UserId, input : Input }


type alias MatchState =
    { frame : Int
    , players : SeqDict (Id UserId) Player
    , towers : List Tower
    , giants : List Giant
    , crystal : Crystal
    , pieces : SeqDict Int Piece
    , blocks : Blocks
    , snowballs : List Snowball
    , debris : List Debris
    , pickups : List Pickup
    , nextId : Int
    , seed : Random.Seed
    , nextPickupSpawn : Maybe Int
    }


{-| It stands in the middle of the map, two blocks wide and three high, and the match is over once
it has taken `crystalHealth` damage. Only giants go for it, and none turn up for now.
-}
type alias Crystal =
    { health : Int, lastHitAt : Maybe Int }


{-| Two blocks tall and very slow. It pays no attention to players and walks straight for the
crystal, breaking any block in its way after standing against it for a moment.
-}
type alias Giant =
    { id : Int
    , position : Point
    , velocityZ : Float
    , blockedSince : Maybe Int
    }


{-| Someone who has joined the match. One who is knocked out comes back `respawnDelay` later.
-}
type alias Player =
    { position : Point
    , velocityZ : Float
    , target : Maybe ( Int, Int )
    , knockedOutAt : Maybe Int
    , queue : PieceQueue
    , piecesLeft : Int
    , -- Dropping a piece makes the player wait a moment before they can drop another.
      nextDropAt : Int
    , -- Snowballs do nothing to a player until this frame, so that someone coming into the match
      -- isn't knocked straight back out.
      protectedUntil : Int
    }


{-| The piece a player drops next, and the two after it.
-}
type alias PieceQueue =
    { current : Shape, next : Shape, afterNext : Shape }


{-| Touching one gives every player more pieces. It sits on top of whatever is in its column.
-}
type alias Pickup =
    { id : Int, x : Int, y : Int, z : Int }


{-| See `Behaviour` for where each kind goes.
-}
type NpcKind
    = -- Twice as fast as a player, and knocks out a player it reaches.
      Chaser
      -- Keeps a few cells away from the player it's after and throws snowballs.
    | Thrower
      -- Like a chaser, only slower. None turn up for now.
    | Jumper


{-| NPCs that walk into each other stand on each other's heads, except chasers, which always go
alone. A tower goes wherever its bottom NPC would, `position` is where that one stands, and each
NPC in `above` stands on the one before it. A lone NPC is a tower of one. Nothing hops for now.
-}
type alias Tower =
    { position : Point
    , velocityZ : Float
    , behaviour : Behaviour
    , wallFollow : Maybe WallFollow
    , bottom : Npc
    , above : List Npc
    }


{-| An NPC wanders between random spots on the map, resting for a moment at each, until a player
comes within `aggroRange`. Then it goes after them until they're knocked out or further away than
`leashRange`. One that has gone `cantReachTime` without getting a cell nearer them (`closest`
being the nearest it has got, at `closestSince`) gives up and walks off somewhere random for a
while, paying no attention to players.
-}
type Behaviour
    = Wandering Walk
    | Resting Int
    | Chasing { userId : Id UserId, closest : Float, closestSince : Int }
    | GivingUp Walk


{-| Walking to `point` until getting there or `until`.
-}
type alias Walk =
    { point : { x : Float, y : Float }, until : Int }


{-| A tower that runs into a wall it can't get over picks a side to keep the wall on and walks
along it, cell by cell, in case that gets it around. It gives up at `until`, or sooner once it's
nearer its target than `stuckDistance` (where it got stuck) with nothing in the way. `goal` is the
cell it's walking to the middle of, and `heading` the way it went to get there.
-}
type alias WallFollow =
    { side : WallSide
    , heading : ( Int, Int )
    , goal : ( Int, Int )
    , stuckDistance : Float
    , until : Int
    }


type WallSide
    = WallOnLeft
    | WallOnRight


type alias Npc =
    { id : Int
    , kind : NpcKind
    , nextThrowFrame : Int
    }


{-| `owner` is Nothing for the pieces a match starts with lying around the map.
-}
type alias Piece =
    { owner : Maybe (Id UserId)
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


{-| How long a knocked out player waits to come back.
-}
respawnDelay : Int
respawnDelay =
    5 * framesPerSecond


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
    2


throwerSpeed : Float
throwerSpeed =
    0.8


chaserSpeed : Float
chaserSpeed =
    2 * playerSpeed


jumperSpeed : Float
jumperSpeed =
    1.9


giantSpeed : Float
giantSpeed =
    0.35


giantRadius : Float
giantRadius =
    0.45


giantHeight : Float
giantHeight =
    2


{-| How long a giant stands against blocks before breaking them.
-}
giantBreakTime : Int
giantBreakTime =
    framesPerSecond


crystalHealth : Int
crystalHealth =
    3


{-| How much damage a giant reaching the crystal does.
-}
giantDamage : Int
giantDamage =
    3


{-| The crystal's blocks are in `blocks` like a piece's, under an id no piece has.
-}
crystalId : Int
crystalId =
    -1


crystalHeight : Int
crystalHeight =
    3


crystalCells : List ( Int, Int, Int )
crystalCells =
    List.concatMap
        (\x ->
            List.concatMap
                (\y -> List.map (\z -> ( x, y, z )) (List.range 0 (crystalHeight - 1)))
                [ gridSize // 2 - 1, gridSize // 2 ]
        )
        [ gridSize // 2 - 1, gridSize // 2 ]


{-| Whether a piece with these cells, dropped on this column and row, would have any of it over
the crystal. Nothing can be put on top of it.
-}
coversCrystal : List ( Int, Int, Int ) -> Int -> Int -> Bool
coversCrystal cells column row =
    List.any
        (\( offsetX, offsetY, _ ) ->
            let
                x : Int
                x =
                    column + offsetX

                y : Int
                y =
                    row + offsetY
            in
            (x >= gridSize // 2 - 1) && (x <= gridSize // 2) && (y >= gridSize // 2 - 1) && (y <= gridSize // 2)
        )
        cells


crystalCenter : { x : Float, y : Float }
crystalCenter =
    { x = toFloat (gridSize // 2), y = toFloat (gridSize // 2) }


{-| How close to the crystal's surface counts as touching it.
-}
crystalReach : Float
crystalReach =
    0.1


entityRadius : Float
entityRadius =
    0.3


entityHeight : Float
entityHeight =
    0.8


snowballRadius : Float
snowballRadius =
    0.15


{-| How fast a dropped piece speeds up as it falls, slower than anything else so that it takes about
two seconds to come down.
-}
pieceGravity : Float
pieceGravity =
    9


{-| How long an NPC goes without getting any nearer the player it's after before it gives up.
-}
cantReachTime : Int
cantReachTime =
    10 * framesPerSecond


dropHeight : Float
dropHeight =
    18


{-| How many NPCs a match starts with, spread along the edge of the map.
-}
startingNpcs : Int
startingNpcs =
    200


{-| How close a player has to come for an NPC to go after them.
-}
aggroRange : Float
aggroRange =
    10


{-| How far a player has to get from an NPC going after them to lose it.
-}
leashRange : Float
leashRange =
    15


{-| How long an NPC rests between walks while wandering.
-}
restTime : Int
restTime =
    framesPerSecond


{-| Wandering NPCs, and ones that have given up on a player, walk at this much of their full speed.
-}
wanderPace : Float
wanderPace =
    0.5


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


startingPieces : Int
startingPieces =
    10


maxPieces : Int
maxPieces =
    15


dropCooldown : Int
dropCooldown =
    framesPerSecond


{-| How many pieces every player gets when anyone touches a pickup.
-}
piecesPerPickup : Int
piecesPerPickup =
    2


maxPickups : Int
maxPickups =
    3


{-| How many pieces a match starts with lying around the map. Some don't fit where they're rolled
and are left out.
-}
sceneryPieces : Int
sceneryPieces =
    60


{-| No pieces start this close to the middle of the map, where players come into the match.
-}
sceneryClearance : Int
sceneryClearance =
    4


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
    , players = SeqDict.empty
    , towers = []
    , giants = []
    , crystal = { health = crystalHealth, lastHitAt = Nothing }
    , pieces = SeqDict.empty
    , blocks = List.foldl (\cell blocks -> insertBlock cell crystalId blocks) noBlocks crystalCells
    , snowballs = []
    , debris = []
    , pickups = []
    , nextId = 0
    , seed = Random.initialSeed seed
    , nextPickupSpawn = Just (frame + firstPickupDelay)
    }
        |> scatterPieces sceneryPieces
        |> placeNpcsAroundEdge


{-| Spread `startingNpcs` evenly along the edge of the map, two chasers to every thrower, resting
for different lengths of time so that they don't all set off at once.
-}
placeNpcsAroundEdge : MatchState -> MatchState
placeNpcsAroundEdge state =
    let
        side : Int
        side =
            gridSize - 1

        edgeCell : Int -> ( Int, Int )
        edgeCell index =
            if index < side then
                ( index, 0 )

            else if index < 2 * side then
                ( side, index - side )

            else if index < 3 * side then
                ( side - (index - 2 * side), side )

            else
                ( 0, side - (index - 3 * side) )

        ( towers, seed ) =
            List.foldl
                (\npcIndex ( towerList, seed2 ) ->
                    let
                        ( ( kindRoll, restingFor ), seed3 ) =
                            Random.step (Random.pair (Random.int 0 2) (Random.int 0 (2 * framesPerSecond))) seed2

                        ( x, y ) =
                            edgeCell (npcIndex * 4 * side // startingNpcs)
                    in
                    ( { position = { x = toFloat x + 0.5, y = toFloat y + 0.5, z = toFloat (topOfColumn x y state) }
                      , velocityZ = 0
                      , behaviour = Resting (state.frame + restingFor)
                      , wallFollow = Nothing
                      , bottom =
                            { id = state.nextId + npcIndex
                            , kind =
                                if kindRoll == 0 then
                                    Thrower

                                else
                                    Chaser
                            , nextThrowFrame = state.frame
                            }
                      , above = []
                      }
                        :: towerList
                    , seed3
                    )
                )
                ( [], state.seed )
                (List.range 0 (startingNpcs - 1))
    in
    { state | towers = List.reverse towers, nextId = state.nextId + startingNpcs, seed = seed }


{-| Lay pieces around the map, on the ground and not touching each other.
-}
scatterPieces : Int -> MatchState -> MatchState
scatterPieces count state =
    if count <= 0 then
        state

    else
        let
            ( roll, seed ) =
                Random.step
                    (Random.map5
                        (\shape stood quarterTurns column row -> { shape = shape, stood = stood, quarterTurns = quarterTurns, x = column, y = row })
                        randomShape
                        (Random.int 0 2)
                        (Random.int 0 3)
                        (Random.int 0 (gridSize - 1))
                        (Random.int 0 (gridSize - 1))
                    )
                    state.seed

            cells : List ( Int, Int, Int )
            cells =
                Tetromino.cells
                    (Tetromino.orientation
                        -- Mostly lying flat, since a field of pillars is hard to walk through.
                        (if roll.stood == 0 then
                            Tetromino.Upright

                         else
                            Tetromino.Flat
                        )
                        roll.quarterTurns
                    )
                    roll.shape

            ( x, y ) =
                keepInsideGrid cells roll.x roll.y

            nearTheMiddle : Bool
            nearTheMiddle =
                List.any
                    (\( cellX, cellY, _ ) ->
                        (abs (x + cellX - gridSize // 2) <= sceneryClearance)
                            && (abs (y + cellY - gridSize // 2) <= sceneryClearance)
                    )
                    cells

            -- Leaving a gap around each piece keeps them from merging into walls that box things in.
            crowded : Bool
            crowded =
                List.any
                    (\( cellX, cellY, _ ) ->
                        List.any
                            (\( dx, dy ) -> Dict.member ( x + cellX + dx, y + cellY + dy, 0 ) state.blocks.occupied)
                            [ ( 0, 0 ), ( 1, 0 ), ( -1, 0 ), ( 0, 1 ), ( 0, -1 ) ]
                    )
                    cells

            state2 : MatchState
            state2 =
                if nearTheMiddle || crowded then
                    { state | seed = seed }

                else
                    { state
                        | pieces =
                            SeqDict.insert
                                state.nextId
                                { owner = Nothing
                                , shape = roll.shape
                                , cells = cells
                                , x = x
                                , y = y
                                , z = 0
                                , status = Settled state.frame
                                }
                                state.pieces
                        , blocks =
                            List.foldl
                                (\( cellX, cellY, cellZ ) blocks -> insertBlock ( x + cellX, y + cellY, cellZ ) state.nextId blocks)
                                state.blocks
                                cells
                        , nextId = state.nextId + 1
                        , seed = seed
                    }
        in
        scatterPieces (count - 1) state2


{-| Advance by one frame, applying the inputs stamped with this frame first. Once the crystal is
destroyed everything stands still.
-}
step : List InputEvent -> MatchState -> MatchState
step inputs state =
    if isGameOver state then
        { state
            | frame = state.frame + 1
            , debris = List.filter (\debris -> state.frame - debris.destroyedAt < debrisFrames) state.debris
        }

    else
        stepPlaying inputs state


isGameOver : MatchState -> Bool
isGameOver state =
    state.crystal.health <= 0


stepPlaying : List InputEvent -> MatchState -> MatchState
stepPlaying inputs state =
    let
        state2 : MatchState
        state2 =
            List.sortBy (\event -> Id.toInt event.userId) inputs
                |> List.foldl applyInput state

        state3 : MatchState
        state3 =
            respawnPlayers state2
                |> updatePlayers
                |> collectPickups
                |> updateTowers
                |> catchPlayers
                |> updateGiants
                |> spawnPickups
                |> updateSnowballs

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
        , pickups = List.map (\pickup -> { pickup | z = topOfColumn pickup.x pickup.y state5 }) state5.pickups
    }



-- Inputs


applyInput : InputEvent -> MatchState -> MatchState
applyInput event state =
    case event.input of
        Join ->
            if SeqDict.member event.userId state.players then
                state

            else
                let
                    ( queue, seed ) =
                        Random.step randomQueue state.seed
                in
                bringIn event.userId queue { state | seed = seed }

        Leave ->
            let
                ( state2, removedSettled ) =
                    removePiecesOf
                        [ event.userId ]
                        { state | players = SeqDict.remove event.userId state.players }
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

        Drop drop ->
            case SeqDict.get event.userId state.players of
                Just player ->
                    let
                        cells : List ( Int, Int, Int )
                        cells =
                            Tetromino.cells drop.orientation player.queue.current

                        ( x, y ) =
                            keepInsideGrid cells drop.x drop.y
                    in
                    if
                        canDrop state.frame player
                            && Tetromino.isValidOrientation drop.orientation
                            && not (coversCrystal cells x y)
                    then
                        dropPiece event.userId drop player state

                    else
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


{-| Whether a player standing in the round has a piece and isn't waiting after their last drop.
-}
canDrop : Int -> Player -> Bool
canDrop frame player =
    (player.knockedOutAt == Nothing) && (player.piecesLeft > 0) && (frame >= player.nextDropAt)


dropPiece : Id UserId -> { x : Int, y : Int, orientation : Orientation } -> Player -> MatchState -> MatchState
dropPiece userId drop player state =
    let
        queue : PieceQueue
        queue =
            player.queue

        cells : List ( Int, Int, Int )
        cells =
            Tetromino.cells drop.orientation queue.current

        ( x, y ) =
            keepInsideGrid cells drop.x drop.y

        ( newShape, seed ) =
            Random.step randomShape state.seed
    in
    { state
        | pieces =
            SeqDict.insert
                state.nextId
                { owner = Just userId
                , shape = queue.current
                , cells = cells
                , x = x
                , y = y
                , z = dropHeight
                , status = Falling 0
                }
                state.pieces
        , nextId = state.nextId + 1
        , players =
            SeqDict.insert
                userId
                { player
                    | queue = { current = queue.next, next = queue.afterNext, afterNext = newShape }
                    , piecesLeft = player.piecesLeft - 1
                    , nextDropAt = state.frame + dropCooldown
                }
                state.players
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



-- Coming into the match


{-| Bring back everyone who was knocked out `respawnDelay` ago.
-}
respawnPlayers : MatchState -> MatchState
respawnPlayers state =
    SeqDict.foldl
        (\userId player state2 ->
            case player.knockedOutAt of
                Just knockedOutAt ->
                    if state2.frame >= knockedOutAt + respawnDelay then
                        bringIn userId player.queue state2

                    else
                        state2

                Nothing ->
                    state2
        )
        state
        state.players


{-| Put a player by the crystal with a full set of pieces, next to whoever else is standing there.
-}
bringIn : Id UserId -> PieceQueue -> MatchState -> MatchState
bringIn userId queue state =
    let
        ( offsetX, offsetY ) =
            spawnOffset (SeqDict.size (SeqDict.filter (\_ player -> player.knockedOutAt == Nothing) state.players))

        column : Int
        column =
            gridSize // 2 + offsetX

        row : Int
        row =
            gridSize // 2 + offsetY

        -- Protection only matters with an NPC close enough to throw at the spot.
        npcNearby : Bool
        npcNearby =
            List.any
                (\tower ->
                    horizontalDistance tower.position { x = toFloat column + 0.5, y = toFloat row + 0.5, z = 0 }
                        <= npcThrowRange
                )
                state.towers
    in
    { state
        | players =
            SeqDict.insert
                userId
                { position =
                    { x = toFloat column + 0.5
                    , y = toFloat row + 0.5
                    , z = toFloat (topOfColumn column row state)
                    }
                , velocityZ = 0
                , target = Nothing
                , knockedOutAt = Nothing
                , queue = queue
                , piecesLeft = startingPieces
                , nextDropAt = state.frame
                , protectedUntil =
                    if npcNearby then
                        state.frame + spawnProtection

                    else
                        state.frame
                }
                state.players
    }


{-| Where around the crystal in the middle of the grid each player brought into the match appears,
so that they don't all start on top of each other. The crystal covers the two columns either side
of the middle line, so these leave a one cell gap around it.
-}
spawnOffset : Int -> ( Int, Int )
spawnOffset index =
    case List.drop (modBy 8 index) [ ( 2, 0 ), ( -3, -1 ), ( -1, 2 ), ( 0, -3 ), ( 2, 2 ), ( -3, -3 ), ( 2, -3 ), ( -3, 2 ) ] of
        offset :: _ ->
            offset

        [] ->
            ( 0, 0 )



-- Piece queue


randomShape : Random.Generator Shape
randomShape =
    Random.uniform Tetromino.I [ Tetromino.O, Tetromino.T, Tetromino.S, Tetromino.Z, Tetromino.J, Tetromino.L ]


randomQueue : Random.Generator PieceQueue
randomQueue =
    Random.map3 PieceQueue randomShape randomShape randomShape



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
                            moveEntity
                                playerSpeed
                                entityHeight
                                (Maybe.map
                                    (\( x, y ) -> { x = toFloat x + 0.5, y = toFloat y + 0.5 })
                                    player.target
                                )
                                state.blocks
                                player
                )
                state.players
    }


{-| Every tower moves and then every tower throws, both times starting from the last tower in the
list, which decides which random numbers each one gets.
-}
updateTowers : MatchState -> MatchState
updateTowers state =
    let
        alivePlayers : SeqDict (Id UserId) Player
        alivePlayers =
            SeqDict.filter (\_ player -> player.knockedOutAt == Nothing) state.players

        ( moved, seed ) =
            moveTowers state.frame alivePlayers (SeqDict.toList alivePlayers) state.blocks (List.reverse state.towers) [] state.seed

        ( thrown, snowballs, seed2 ) =
            throwFromTowers state.frame (SeqDict.values alivePlayers) (List.reverse moved) [] state.snowballs seed
    in
    { state | towers = mergeTowers state.blocks thrown, snowballs = snowballs, seed = seed2 }


moveTowers :
    Int
    -> SeqDict (Id UserId) Player
    -> List ( Id UserId, Player )
    -> Blocks
    -> List Tower
    -> List Tower
    -> Random.Seed
    -> ( List Tower, Random.Seed )
moveTowers frame alivePlayers alivePlayerList blocks towersLastFirst moved seed =
    case towersLastFirst of
        tower :: rest ->
            let
                ( towers, seed2 ) =
                    moveTower frame alivePlayers alivePlayerList blocks seed tower
            in
            moveTowers frame alivePlayers alivePlayerList blocks rest (towers ++ moved) seed2

        [] ->
            ( moved, seed )


throwFromTowers : Int -> List Player -> List Tower -> List Tower -> List Snowball -> Random.Seed -> ( List Tower, List Snowball, Random.Seed )
throwFromTowers frame alivePlayers towersLastFirst thrown snowballs seed =
    case towersLastFirst of
        tower :: rest ->
            let
                ( tower2, newSnowballs, seed2 ) =
                    throwFromTower frame alivePlayers seed tower
            in
            throwFromTowers frame alivePlayers rest (tower2 :: thrown) (newSnowballs ++ snowballs) seed2

        [] ->
            ( thrown, snowballs, seed )


{-| A tower walks wherever its behaviour takes it. It can come out of this as two towers, if it
walked into a wall the NPCs at the top could step onto.
-}
moveTower : Int -> SeqDict (Id UserId) Player -> List ( Id UserId, Player ) -> Blocks -> Random.Seed -> Tower -> ( List Tower, Random.Seed )
moveTower frame alivePlayers alivePlayerList blocks seed tower =
    let
        ( tower2, seed2 ) =
            updateBehaviour frame alivePlayers alivePlayerList seed tower
    in
    case tower2.behaviour of
        Wandering walking ->
            walkTower frame (npcSpeed tower2.bottom.kind * wanderPace) (Just walking.point) blocks seed2 tower2

        Resting _ ->
            walkTower frame 0 Nothing blocks seed2 tower2

        Chasing chasing ->
            walkTower frame (npcSpeed tower2.bottom.kind) (chasingTarget alivePlayers chasing.userId tower2) blocks seed2 tower2

        GivingUp walking ->
            walkTower frame (npcSpeed tower2.bottom.kind * wanderPace) (Just walking.point) blocks seed2 tower2


updateBehaviour : Int -> SeqDict (Id UserId) Player -> List ( Id UserId, Player ) -> Random.Seed -> Tower -> ( Tower, Random.Seed )
updateBehaviour frame alivePlayers alivePlayerList seed tower =
    let
        rest : ( Tower, Random.Seed )
        rest =
            ( { tower | behaviour = Resting (frame + restTime), wallFollow = Nothing }, seed )
    in
    case tower.behaviour of
        Wandering walking ->
            case nearbyPlayer frame tower.position alivePlayerList Nothing of
                Just chasing ->
                    ( { tower | behaviour = Chasing chasing, wallFollow = Nothing }, seed )

                Nothing ->
                    if frame >= walking.until || isAt walking.point tower.position then
                        rest

                    else
                        ( tower, seed )

        Resting until ->
            case nearbyPlayer frame tower.position alivePlayerList Nothing of
                Just chasing ->
                    ( { tower | behaviour = Chasing chasing, wallFollow = Nothing }, seed )

                Nothing ->
                    if frame >= until then
                        Random.step (randomWalk frame (2 * framesPerSecond) (4 * framesPerSecond)) seed
                            |> Tuple.mapFirst (\walking -> { tower | behaviour = Wandering walking, wallFollow = Nothing })

                    else
                        ( tower, seed )

        Chasing chasing ->
            case SeqDict.get chasing.userId alivePlayers of
                Just player ->
                    let
                        distance : Float
                        distance =
                            horizontalDistance tower.position player.position
                    in
                    if distance > leashRange then
                        rest

                    else if distance < chasing.closest - 1 || chasingTarget alivePlayers chasing.userId tower == Nothing then
                        ( { tower | behaviour = Chasing { chasing | closest = distance, closestSince = frame } }, seed )

                    else if frame - chasing.closestSince >= cantReachTime then
                        Random.step (randomWalk frame (4 * framesPerSecond) (8 * framesPerSecond)) seed
                            |> Tuple.mapFirst (\walking -> { tower | behaviour = GivingUp walking, wallFollow = Nothing })

                    else
                        ( tower, seed )

                Nothing ->
                    rest

        GivingUp walking ->
            if frame >= walking.until || isAt walking.point tower.position then
                rest

            else
                ( tower, seed )


{-| The nearest standing player within `aggroRange`, if there is one, for an NPC to go after.
-}
nearbyPlayer :
    Int
    -> Point
    -> List ( Id UserId, Player )
    -> Maybe { userId : Id UserId, closest : Float, closestSince : Int }
    -> Maybe { userId : Id UserId, closest : Float, closestSince : Int }
nearbyPlayer frame position alivePlayers nearest =
    case alivePlayers of
        ( userId, player ) :: rest ->
            let
                distance : Float
                distance =
                    horizontalDistance position player.position

                isNearer : Bool
                isNearer =
                    case nearest of
                        Just other ->
                            distance < other.closest

                        Nothing ->
                            True
            in
            if distance <= aggroRange && isNearer then
                nearbyPlayer frame position rest (Just { userId = userId, closest = distance, closestSince = frame })

            else
                nearbyPlayer frame position rest nearest

        [] ->
            nearest


{-| Somewhere random on the map to walk to, for between `shortest` and `longest` frames.
-}
randomWalk : Int -> Int -> Int -> Random.Generator Walk
randomWalk frame shortest longest =
    Random.map3
        (\x y duration -> { point = { x = toFloat x + 0.5, y = toFloat y + 0.5 }, until = frame + duration })
        (Random.int 0 (gridSize - 1))
        (Random.int 0 (gridSize - 1))
        (Random.int shortest longest)


isAt : { x : Float, y : Float } -> Point -> Bool
isAt point position =
    sqrt ((position.x - point.x) * (position.x - point.x) + (position.y - point.y) * (position.y - point.y)) < 0.5


{-| Throwers stop a few cells short of the player they're after, to throw from there.
-}
chasingTarget : SeqDict (Id UserId) Player -> Id UserId -> Tower -> Maybe { x : Float, y : Float }
chasingTarget alivePlayers userId tower =
    case SeqDict.get userId alivePlayers of
        Just player ->
            case tower.bottom.kind of
                Chaser ->
                    Just { x = player.position.x, y = player.position.y }

                Thrower ->
                    if horizontalDistance tower.position player.position <= npcKeepDistance then
                        Nothing

                    else
                        Just { x = player.position.x, y = player.position.y }

                Jumper ->
                    Just { x = player.position.x, y = player.position.y }

        Nothing ->
            Nothing


npcSpeed : NpcKind -> Float
npcSpeed kind =
    case kind of
        Chaser ->
            chaserSpeed

        Thrower ->
            throwerSpeed

        Jumper ->
            jumperSpeed


{-| Walk a tower towards a target without hopping. Against a wall, the NPCs high enough to clear
it step onto it, and the rest follow the wall for a while in case that gets them around.
-}
walkTower : Int -> Float -> Maybe { x : Float, y : Float } -> Blocks -> Random.Seed -> Tower -> ( List Tower, Random.Seed )
walkTower frame speed maybeTarget blocks seed tower =
    case maybeTarget of
        Just target ->
            case stepTowards speed target tower.position of
                Just next ->
                    if entityCollides blocks (towerHeight tower) next then
                        case splitAtWall blocks next tower of
                            Just ( lower, upper ) ->
                                ( [ moveEntityWithoutHopping speed (towerHeight lower) maybeTarget blocks lower, upper ], seed )

                            Nothing ->
                                walkAlongWalls frame speed target True blocks seed tower

                    else
                        walkAlongWalls frame speed target False blocks seed tower

                Nothing ->
                    walkAlongWalls frame speed target False blocks seed tower

        Nothing ->
            ( [ moveEntityWithoutHopping speed (towerHeight tower) Nothing blocks tower ], seed )


{-| Head straight for the target until a wall stops the tower, and then follow the wall for a
while, keeping it on whichever side it picked. `blockedAhead` is whether the next step straight for
the target would take the tower into a block.
-}
walkAlongWalls : Int -> Float -> { x : Float, y : Float } -> Bool -> Blocks -> Random.Seed -> Tower -> ( List Tower, Random.Seed )
walkAlongWalls frame speed target blockedAhead blocks seed tower =
    let
        height : Float
        height =
            towerHeight tower
    in
    case tower.wallFollow of
        Just wallFollow ->
            let
                isAround : Bool
                isAround =
                    (horizontalDistance tower.position { x = target.x, y = target.y, z = 0 } < wallFollow.stuckDistance - 0.5)
                        && not blockedAhead
            in
            if frame >= wallFollow.until || isAround then
                walkAlongWalls frame speed target blockedAhead blocks seed { tower | wallFollow = Nothing }

            else
                ( [ followWall blocks speed height wallFollow tower ], seed )

        Nothing ->
            let
                moved : Tower
                moved =
                    moveEntityWithoutHopping speed height (Just target) blocks tower

                stopped : Bool
                stopped =
                    blockedAhead
                        && (horizontalDistance moved.position tower.position < speed * frameSeconds / 2)
            in
            if stopped then
                let
                    ( wallFollow, seed2 ) =
                        Random.step
                            (Random.map2
                                (startFollowingWall frame target tower.position)
                                (Random.uniform WallOnLeft [ WallOnRight ])
                                (Random.int (2 * framesPerSecond) (4 * framesPerSecond))
                            )
                            seed
                in
                ( [ { moved | wallFollow = Just wallFollow } ], seed2 )

            else
                ( [ moved ], seed )


{-| Turn from facing the wall, the way that puts it on the chosen side, and start by going to the
middle of the cell the tower is in.
-}
startFollowingWall : Int -> { x : Float, y : Float } -> Point -> WallSide -> Int -> WallFollow
startFollowingWall frame target position side duration =
    let
        dx : Float
        dx =
            target.x - position.x

        dy : Float
        dy =
            target.y - position.y

        towardsWall : ( Int, Int )
        towardsWall =
            if abs dx >= abs dy then
                ( sign dx, 0 )

            else
                ( 0, sign dy )
    in
    { side = side
    , heading = turnAwayFrom side towardsWall
    , goal = ( floor position.x, floor position.y )
    , stuckDistance = sqrt (dx * dx + dy * dy)
    , until = frame + duration
    }


sign : Float -> Int
sign value =
    if value < 0 then
        -1

    else
        1


{-| Walk to the middle of the goal cell. Close enough to it, pick the next cell the way someone
keeping a hand on the wall would: round the corner if the wall stops, straight on if it doesn't,
turning away from it or going back the way it came only when it has to.
-}
followWall : Blocks -> Float -> Float -> WallFollow -> Tower -> Tower
followWall blocks speed height wallFollow tower =
    let
        ( goalX, goalY ) =
            wallFollow.goal

        isFree : ( Int, Int ) -> Bool
        isFree ( dx, dy ) =
            not
                (entityCollides
                    blocks
                    height
                    { x = toFloat (goalX + dx) + 0.5, y = toFloat (goalY + dy) + 0.5, z = tower.position.z }
                )

        wallFollow2 : WallFollow
        wallFollow2 =
            if horizontalDistance tower.position (cellMiddle wallFollow.goal tower.position.z) <= speed * frameSeconds then
                case
                    List.filter
                        isFree
                        [ turnTowards wallFollow.side wallFollow.heading
                        , wallFollow.heading
                        , turnAwayFrom wallFollow.side wallFollow.heading
                        , turnAround wallFollow.heading
                        ]
                of
                    ( dx, dy ) :: _ ->
                        { wallFollow | heading = ( dx, dy ), goal = ( goalX + dx, goalY + dy ) }

                    [] ->
                        wallFollow

            else
                wallFollow

        goal : Point
        goal =
            cellMiddle wallFollow2.goal tower.position.z
    in
    moveEntityWithoutHopping
        speed
        height
        (Just { x = goal.x, y = goal.y })
        blocks
        { tower | wallFollow = Just wallFollow2 }


cellMiddle : ( Int, Int ) -> Float -> Point
cellMiddle ( x, y ) z =
    { x = toFloat x + 0.5, y = toFloat y + 0.5, z = z }


{-| A quarter turn towards the side the wall is on.
-}
turnTowards : WallSide -> ( Int, Int ) -> ( Int, Int )
turnTowards side ( dx, dy ) =
    case side of
        WallOnLeft ->
            ( -dy, dx )

        WallOnRight ->
            ( dy, -dx )


turnAwayFrom : WallSide -> ( Int, Int ) -> ( Int, Int )
turnAwayFrom side ( dx, dy ) =
    case side of
        WallOnLeft ->
            ( dy, -dx )

        WallOnRight ->
            ( -dy, dx )


turnAround : ( Int, Int ) -> ( Int, Int )
turnAround ( dx, dy ) =
    ( -dx, -dy )


{-| The lowest NPC in a tower that fits at `next` along with everyone above it takes them all
there, as a tower of their own. Whatever is in the way is under them, so they come down on top
of it.
-}
splitAtWall : Blocks -> Point -> Tower -> Maybe ( Tower, Tower )
splitAtWall blocks next tower =
    splitAtWallHelper blocks next tower [] tower.above


splitAtWallHelper : Blocks -> Point -> Tower -> List Npc -> List Npc -> Maybe ( Tower, Tower )
splitAtWallHelper blocks next tower stayingTopFirst rest =
    case rest of
        npc :: higher ->
            let
                upper : Tower
                upper =
                    { position = heightInTower (List.length stayingTopFirst + 1) { next | z = tower.position.z }
                    , velocityZ = 0
                    , behaviour = tower.behaviour
                    , wallFollow = Nothing
                    , bottom = npc
                    , above = higher
                    }
            in
            if entityCollides blocks (towerHeight upper) upper.position then
                splitAtWallHelper blocks next tower (npc :: stayingTopFirst) higher

            else
                Just ( { tower | above = List.reverse stayingTopFirst }, upper )

        [] ->
            Nothing


{-| Towers that walk into each other become one, unless it wouldn't fit there. Only some kinds of
NPC stack, and most frames none of those towers meet, which is quick to rule out.
-}
mergeTowers : Blocks -> List Tower -> List Tower
mergeTowers blocks towers =
    if anyMeet (stackable towers []) then
        mergeMeetingTowers blocks [] towers

    else
        towers


{-| The towers that can stack, in any order.
-}
stackable : List Tower -> List Tower -> List Tower
stackable towers found =
    case towers of
        tower :: rest ->
            if canStack tower then
                stackable rest (tower :: found)

            else
                stackable rest found

        [] ->
            found


anyMeet : List Tower -> Bool
anyMeet towers =
    case towers of
        tower :: rest ->
            if meetsAny tower rest then
                True

            else
                anyMeet rest

        [] ->
            False


meetsAny : Tower -> List Tower -> Bool
meetsAny tower others =
    case others of
        other :: rest ->
            if towersMeet tower other then
                True

            else
                meetsAny tower rest

        [] ->
            False


mergeMeetingTowers : Blocks -> List Tower -> List Tower -> List Tower
mergeMeetingTowers blocks doneLastFirst towers =
    case towers of
        tower :: rest ->
            if canStack tower then
                case mergeWithFirstMet blocks tower 0 rest of
                    Just ( merged, index ) ->
                        mergeMeetingTowers blocks doneLastFirst (merged :: List.take index rest ++ List.drop (index + 1) rest)

                    Nothing ->
                        mergeMeetingTowers blocks (tower :: doneLastFirst) rest

            else
                mergeMeetingTowers blocks (tower :: doneLastFirst) rest

        [] ->
            List.reverse doneLastFirst


{-| The first of `others` that `tower` meets and fits on top of or under, the two stacked, and
where that one is in `others`.
-}
mergeWithFirstMet : Blocks -> Tower -> Int -> List Tower -> Maybe ( Tower, Int )
mergeWithFirstMet blocks tower index others =
    case others of
        other :: rest ->
            if canStack other && towersMeet tower other then
                let
                    merged : Tower
                    merged =
                        stack tower other
                in
                if entityCollides blocks (towerHeight merged) merged.position then
                    mergeWithFirstMet blocks tower (index + 1) rest

                else
                    Just ( merged, index )

            else
                mergeWithFirstMet blocks tower (index + 1) rest

        [] ->
            Nothing


canStack : Tower -> Bool
canStack tower =
    case tower.bottom.kind of
        Chaser ->
            False

        Thrower ->
            True

        Jumper ->
            True


{-| Only towers standing at about the same level meet, so that NPCs who have just stepped off a
tower onto a wall don't climb straight back on.
-}
towersMeet : Tower -> Tower -> Bool
towersMeet a b =
    (abs (a.position.x - b.position.x) < 2 * entityRadius)
        && (abs (a.position.y - b.position.y) < 2 * entityRadius)
        && (abs (a.position.z - b.position.z) < entityHeight / 2)


{-| The smaller tower goes underneath, and stays where it is with the bigger one on top. Between
two the same size, the one whose bottom NPC turned up first goes underneath.
-}
stack : Tower -> Tower -> Tower
stack a b =
    let
        sizeA : Int
        sizeA =
            List.length a.above

        sizeB : Int
        sizeB =
            List.length b.above
    in
    if sizeA < sizeB || (sizeA == sizeB && a.bottom.id < b.bottom.id) then
        { a | above = a.above ++ b.bottom :: b.above }

    else
        { b | above = b.above ++ a.bottom :: a.above }


towerHeight : Tower -> Float
towerHeight tower =
    toFloat (List.length tower.above + 1) * entityHeight


{-| Where the NPC this many places up a tower stands.
-}
heightInTower : Int -> Point -> Point
heightInTower index position =
    { position | z = position.z + toFloat index * entityHeight }


{-| Every NPC in a tower, bottom first, with where it stands.
-}
npcPositions : Tower -> List ( Npc, Point )
npcPositions tower =
    List.indexedMap (\index npc -> ( npc, heightInTower index tower.position )) (tower.bottom :: tower.above)


npcCount : List Tower -> Int
npcCount towers =
    List.foldl (\tower count -> count + 1 + List.length tower.above) 0 towers


{-| Every thrower in a tower throws from wherever in it they stand.
-}
throwFromTower : Int -> List Player -> Random.Seed -> Tower -> ( Tower, List Snowball, Random.Seed )
throwFromTower frame alivePlayers seed tower =
    let
        ( bottom, bottomSnowball, seed2 ) =
            npcThrow frame alivePlayers tower.position tower.bottom seed
    in
    case tower.above of
        [] ->
            case bottomSnowball of
                Just snowball ->
                    ( { tower | bottom = bottom }, [ snowball ], seed2 )

                Nothing ->
                    ( tower, [], seed2 )

        _ :: _ ->
            let
                bottomSnowballs : List Snowball
                bottomSnowballs =
                    case bottomSnowball of
                        Just snowball ->
                            [ snowball ]

                        Nothing ->
                            []

                ( above, snowballs, seed3 ) =
                    throwFromAbove frame alivePlayers tower.position 1 tower.above [] bottomSnowballs seed2
            in
            ( { tower | bottom = bottom, above = above }, snowballs, seed3 )


{-| The NPCs higher up a tower throw in turn, lowest first, the snowballs of the higher ones
ahead of the lower ones'.
-}
throwFromAbove : Int -> List Player -> Point -> Int -> List Npc -> List Npc -> List Snowball -> Random.Seed -> ( List Npc, List Snowball, Random.Seed )
throwFromAbove frame alivePlayers position index above thrownTopFirst snowballs seed =
    case above of
        npc :: higher ->
            let
                ( npc2, snowball, seed2 ) =
                    npcThrow frame alivePlayers (heightInTower index position) npc seed

                snowballs2 : List Snowball
                snowballs2 =
                    case snowball of
                        Just thrown ->
                            thrown :: snowballs

                        Nothing ->
                            snowballs
            in
            throwFromAbove frame alivePlayers position (index + 1) higher (npc2 :: thrownTopFirst) snowballs2 seed2

        [] ->
            ( List.reverse thrownTopFirst, snowballs, seed )


npcThrow : Int -> List Player -> Point -> Npc -> Random.Seed -> ( Npc, Maybe Snowball, Random.Seed )
npcThrow frame alivePlayers position npc seed =
    case npc.kind of
        Chaser ->
            ( npc, Nothing, seed )

        Thrower ->
            if frame < npc.nextThrowFrame then
                ( npc, Nothing, seed )

            else
                case nearestPlayer position alivePlayers of
                    Just ( player, distance ) ->
                        if distance <= npcThrowRange then
                            let
                                ( ( delay, missX, missY ), seed2 ) =
                                    Random.step
                                        (Random.map3
                                            (\a b c -> ( a, b, c ))
                                            (Random.int (3 * framesPerSecond) (5 * framesPerSecond))
                                            (Random.float -throwSpread throwSpread)
                                            (Random.float -throwSpread throwSpread)
                                        )
                                        seed

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
                            ( { npc | nextThrowFrame = frame + delay }
                            , Just (throwSnowball frame position aim)
                            , seed2
                            )

                        else
                            ( npc, Nothing, seed )

                    Nothing ->
                        ( npc, Nothing, seed )

        Jumper ->
            ( npc, Nothing, seed )


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


damageCrystal : Int -> MatchState -> MatchState
damageCrystal damage state =
    { state | crystal = { health = max 0 (state.crystal.health - damage), lastHitAt = Just state.frame } }


{-| Whether something this wide and tall standing here touches the crystal, from the side or from
on top of it.
-}
touchesCrystal : Float -> Float -> Point -> Bool
touchesCrystal radius height position =
    let
        low : Float
        low =
            toFloat (gridSize // 2 - 1)

        high : Float
        high =
            toFloat (gridSize // 2 + 1)

        reach : Float
        reach =
            radius + crystalReach
    in
    (position.x + reach > low)
        && (position.x - reach < high)
        && (position.y + reach > low)
        && (position.y - reach < high)
        && (position.z < toFloat crystalHeight + crystalReach)
        && (position.z + height > 0)


{-| Chasers and jumpers knock out any player they reach, from anywhere in a tower, unless that
player has only just come into the match.
-}
catchPlayers : MatchState -> MatchState
catchPlayers state =
    { state
        | players =
            SeqDict.map
                (\_ player ->
                    if
                        (player.knockedOutAt == Nothing)
                            && not (isProtected state.frame player)
                            && towersCatch player.position state.towers
                    then
                        { player | knockedOutAt = Just state.frame, target = Nothing }

                    else
                        player
                )
                state.players
    }


towersCatch : Point -> List Tower -> Bool
towersCatch position towers =
    case towers of
        tower :: rest ->
            if
                (abs (tower.position.x - position.x) < 2 * entityRadius)
                    && (abs (tower.position.y - position.y) < 2 * entityRadius)
                    && npcsCatch position tower.position 0 (tower.bottom :: tower.above)
            then
                True

            else
                towersCatch position rest

        [] ->
            False


{-| Whether one of the NPCs in a tower, from `index` places up it, catches someone standing at
`position`.
-}
npcsCatch : Point -> Point -> Int -> List Npc -> Bool
npcsCatch position towerPosition index npcs =
    case npcs of
        npc :: higher ->
            if catchesPlayers npc.kind && entitiesTouch (heightInTower index towerPosition) position then
                True

            else
                npcsCatch position towerPosition (index + 1) higher

        [] ->
            False


catchesPlayers : NpcKind -> Bool
catchesPlayers kind =
    case kind of
        Chaser ->
            True

        Thrower ->
            False

        Jumper ->
            True


entitiesTouch : Point -> Point -> Bool
entitiesTouch a b =
    (abs (a.x - b.x) < 2 * entityRadius)
        && (abs (a.y - b.y) < 2 * entityRadius)
        && (abs (a.z - b.z) < entityHeight)



-- Giants


updateGiants : MatchState -> MatchState
updateGiants state =
    let
        state2 : MatchState
        state2 =
            List.foldl updateGiant { state | giants = [] } state.giants
    in
    { state2 | giants = List.reverse state2.giants }


{-| A giant that reaches the crystal does it a lot of damage and is gone. Otherwise it walks
straight for the crystal, and when blocks are in the way it stands against them for a moment and
then breaks them. Giants collected so far are in `state.giants`, newest first.
-}
updateGiant : Giant -> MatchState -> MatchState
updateGiant giant state =
    if touchesCrystal giantRadius giantHeight giant.position then
        damageCrystal giantDamage state

    else
        case stepTowards giantSpeed crystalCenter giant.position of
            Just next ->
                case giantBlockedBy state.blocks.occupied next of
                    [] ->
                        { state | giants = fallGiant state.blocks { giant | position = next, blockedSince = Nothing } :: state.giants }

                    blocks ->
                        case giant.blockedSince of
                            Just since ->
                                if state.frame - since >= giantBreakTime then
                                    let
                                        state2 : MatchState
                                        state2 =
                                            breakBlocks blocks state
                                    in
                                    { state2 | giants = { giant | blockedSince = Nothing } :: state2.giants }

                                else
                                    { state | giants = fallGiant state.blocks giant :: state.giants }

                            Nothing ->
                                { state | giants = fallGiant state.blocks { giant | blockedSince = Just state.frame } :: state.giants }

            Nothing ->
                { state | giants = fallGiant state.blocks giant :: state.giants }


{-| The blocks a giant standing here would be inside of, apart from the crystal's.
-}
giantBlockedBy : Dict ( Int, Int, Int ) Int -> Point -> List ( Int, Int, Int )
giantBlockedBy occupied position =
    List.concatMap
        (\cellX ->
            List.concatMap
                (\cellY ->
                    List.filterMap
                        (\cellZ ->
                            case Dict.get ( cellX, cellY, cellZ ) occupied of
                                Just pieceId ->
                                    if pieceId == crystalId then
                                        Nothing

                                    else
                                        Just ( cellX, cellY, cellZ )

                                Nothing ->
                                    Nothing
                        )
                        (List.range (floor position.z) (floor (position.z + giantHeight - epsilon)))
                )
                (List.range (floor (position.y - giantRadius)) (floor (position.y + giantRadius - epsilon)))
        )
        (List.range (floor (position.x - giantRadius)) (floor (position.x + giantRadius - epsilon)))


giantCollides : Blocks -> Point -> Bool
giantCollides blocks position =
    (position.z < 0)
        || boxCollides
            blocks
            (floor (position.x - giantRadius))
            (floor (position.x + giantRadius - epsilon))
            (floor (position.y - giantRadius))
            (floor (position.y + giantRadius - epsilon))
            (floor position.z)
            (floor (position.z + giantHeight - epsilon))


fallGiant : Blocks -> Giant -> Giant
fallGiant blocks giant =
    let
        velocityZ : Float
        velocityZ =
            fallingVelocity giant

        position : Point
        position =
            giant.position

        newZ : Float
        newZ =
            position.z + velocityZ * frameSeconds
    in
    if giantCollides blocks { position | z = newZ } then
        { giant | position = { position | z = max 0 (toFloat (floor newZ + 1)) }, velocityZ = 0 }

    else
        { giant | position = { position | z = newZ }, velocityZ = velocityZ }


{-| Knock individual blocks out of whatever pieces they belong to, leaving the rest of each piece,
and let go of anything left without support.
-}
breakBlocks : List ( Int, Int, Int ) -> MatchState -> MatchState
breakBlocks cells state =
    List.foldl breakBlock state cells |> dropUnsupportedPieces


breakBlock : ( Int, Int, Int ) -> MatchState -> MatchState
breakBlock (( x, y, z ) as cell) state =
    case Dict.get cell state.blocks.occupied of
        Just pieceId ->
            let
                state2 : MatchState
                state2 =
                    { state | blocks = blocksOf (Dict.remove cell state.blocks.occupied) }
            in
            case SeqDict.get pieceId state2.pieces of
                Just piece ->
                    let
                        offset : ( Int, Int, Int )
                        offset =
                            ( x - piece.x, y - piece.y, z - floor piece.z )

                        remaining : List ( Int, Int, Int )
                        remaining =
                            List.filter (\other -> other /= offset) piece.cells
                    in
                    { state2
                        | pieces =
                            if List.isEmpty remaining then
                                SeqDict.remove pieceId state2.pieces

                            else
                                SeqDict.insert pieceId { piece | cells = remaining } state2.pieces
                        , debris = { piece = { piece | cells = [ offset ] }, destroyedAt = state2.frame } :: state2.debris
                    }

                Nothing ->
                    state2

        Nothing ->
            state



-- Pickups


firstPickupDelay : Int
firstPickupDelay =
    5 * framesPerSecond


{-| Pickups turn up every so often a few cells from one of the players still standing, up to
`maxPickups` at a time.
-}
spawnPickups : MatchState -> MatchState
spawnPickups state =
    case state.nextPickupSpawn of
        Just spawnFrame ->
            if state.frame >= spawnFrame then
                let
                    alivePlayers : List Player
                    alivePlayers =
                        SeqDict.values state.players |> List.filter (\player -> player.knockedOutAt == Nothing)

                    ( roll, seed ) =
                        Random.step
                            (Random.map5
                                (\playerIndex side along distance delay ->
                                    { playerIndex = playerIndex, side = side, along = along, distance = distance, delay = delay }
                                )
                                (Random.int 0 (max 0 (List.length alivePlayers - 1)))
                                (Random.int 0 3)
                                (Random.int -10 10)
                                (Random.int 4 10)
                                (Random.int (6 * framesPerSecond) (12 * framesPerSecond))
                            )
                            state.seed

                    ( offsetX, offsetY ) =
                        case roll.side of
                            0 ->
                                ( roll.along, -roll.distance )

                            1 ->
                                ( roll.along, roll.distance )

                            2 ->
                                ( -roll.distance, roll.along )

                            _ ->
                                ( roll.distance, roll.along )

                    pickups : List Pickup
                    pickups =
                        case List.drop roll.playerIndex alivePlayers of
                            player :: _ ->
                                if List.length state.pickups < maxPickups && not (onCrystal (floor player.position.x + offsetX) (floor player.position.y + offsetY)) then
                                    let
                                        x : Int
                                        x =
                                            clamp 0 (gridSize - 1) (floor player.position.x + offsetX)

                                        y : Int
                                        y =
                                            clamp 0 (gridSize - 1) (floor player.position.y + offsetY)
                                    in
                                    state.pickups ++ [ { id = state.nextId, x = x, y = y, z = topOfColumn x y state } ]

                                else
                                    state.pickups

                            [] ->
                                state.pickups
                in
                { state
                    | pickups = pickups
                    , nextId = state.nextId + 1
                    , seed = seed
                    , nextPickupSpawn = Just (state.frame + roll.delay)
                }

            else
                state

        Nothing ->
            state


onCrystal : Int -> Int -> Bool
onCrystal column row =
    List.member ( column, row, 0 ) crystalCells


{-| A standing player who touches a pickup takes it, and everyone gets more pieces.
-}
collectPickups : MatchState -> MatchState
collectPickups state =
    let
        ( taken, left ) =
            List.partition
                (\pickup ->
                    List.any
                        (\player ->
                            (player.knockedOutAt == Nothing)
                                && entitiesTouch
                                    { x = toFloat pickup.x + 0.5, y = toFloat pickup.y + 0.5, z = toFloat pickup.z }
                                    player.position
                        )
                        (SeqDict.values state.players)
                )
                state.pickups

        gained : Int
        gained =
            piecesPerPickup * List.length taken
    in
    if gained > 0 then
        { state
            | pickups = left
            , players =
                SeqDict.map
                    (\_ player -> { player | piecesLeft = min maxPieces (player.piecesLeft + gained) })
                    state.players
        }

    else
        state


{-| Walk towards a target, hopping onto anything one cell high, and fall under gravity.
-}
moveEntity : Float -> Float -> Maybe { x : Float, y : Float } -> Blocks -> { a | position : Point, velocityZ : Float } -> { a | position : Point, velocityZ : Float }
moveEntity speed height maybeTarget blocks entity =
    let
        position : Point
        position =
            unstuck blocks entity.position

        walked : { position : Point, couldHop : Bool }
        walked =
            walk speed height maybeTarget blocks position

        velocityZ : Float
        velocityZ =
            if walked.couldHop && entityCollides blocks height { position | z = position.z - 0.01 } then
                jumpVelocity

            else
                fallingVelocity entity

        ( position2, velocityZ2 ) =
            moveVertically blocks height velocityZ walked.position
    in
    { entity | position = position2, velocityZ = velocityZ2 }


{-| How a tower walks: like `moveEntity`, except it never hops, so anything in the way stops it.
-}
moveEntityWithoutHopping : Float -> Float -> Maybe { x : Float, y : Float } -> Blocks -> Tower -> Tower
moveEntityWithoutHopping speed height maybeTarget blocks tower =
    let
        position : Point
        position =
            unstuck blocks tower.position

        walked : Point
        walked =
            case maybeTarget of
                Just target ->
                    case stepTowards speed target position of
                        Just next ->
                            let
                                alongX : Point
                                alongX =
                                    { x = next.x, y = position.y, z = position.z }

                                afterX : Point
                                afterX =
                                    if entityCollides blocks height alongX then
                                        position

                                    else
                                        alongX

                                alongY : Point
                                alongY =
                                    { x = afterX.x, y = next.y, z = afterX.z }
                            in
                            if entityCollides blocks height alongY then
                                afterX

                            else
                                alongY

                        Nothing ->
                            position

                Nothing ->
                    position

        ( position2, velocityZ ) =
            moveVertically blocks height (fallingVelocity tower) walked
    in
    { position = position2
    , velocityZ = velocityZ
    , behaviour = tower.behaviour
    , wallFollow = tower.wallFollow
    , bottom = tower.bottom
    , above = tower.above
    }


{-| Something that ends up inside a block, like a player a piece landed next to, is lifted on top
of it.
-}
unstuck : Blocks -> Point -> Point
unstuck blocks position =
    if entityCollides blocks entityHeight position then
        { position | z = toFloat (floor position.z + 1) }

    else
        position


{-| A step towards the target that doesn't go into any block, sliding along a wall if it can, and
whether there was something in the way it could have hopped onto.
-}
walk : Float -> Float -> Maybe { x : Float, y : Float } -> Blocks -> Point -> { position : Point, couldHop : Bool }
walk speed height maybeTarget blocks position =
    case maybeTarget of
        Just target ->
            case stepTowards speed target position of
                Just next ->
                    let
                        ( afterX, blockedX ) =
                            tryMove blocks height { x = next.x, y = position.y, z = position.z } position

                        ( afterY, blockedY ) =
                            tryMove blocks height { x = afterX.x, y = next.y, z = afterX.z } afterX
                    in
                    { position = afterY
                    , couldHop =
                        (blockedX && canHop blocks height position { x = next.x, y = position.y, z = position.z })
                            || (blockedY && canHop blocks height afterX { x = afterX.x, y = next.y, z = afterX.z })
                    }

                Nothing ->
                    { position = position, couldHop = False }

        Nothing ->
            { position = position, couldHop = False }


{-| Where one frame's walk towards the target gets to if nothing is in the way, or Nothing if
already there.
-}
stepTowards : Float -> { x : Float, y : Float } -> Point -> Maybe Point
stepTowards speed target position =
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
        Nothing

    else if distance <= speed * frameSeconds then
        Just { x = target.x, y = target.y, z = position.z }

    else
        Just
            { x = position.x + dx / distance * speed * frameSeconds
            , y = position.y + dy / distance * speed * frameSeconds
            , z = position.z
            }


fallingVelocity : { a | velocityZ : Float } -> Float
fallingVelocity entity =
    max -maxFallSpeed (entity.velocityZ - gravity * frameSeconds)


{-| Where something falling or jumping at `velocityZ` ends up, and how fast it's going after.
-}
moveVertically : Blocks -> Float -> Float -> Point -> ( Point, Float )
moveVertically blocks height velocityZ afterWalk =
    let
        moved : Point
        moved =
            { x = afterWalk.x, y = afterWalk.y, z = afterWalk.z + velocityZ * frameSeconds }
    in
    if velocityZ <= 0 then
        if entityCollides blocks height moved then
            ( { x = afterWalk.x, y = afterWalk.y, z = max 0 (toFloat (floor moved.z + 1)) }, 0 )

        else
            ( moved, velocityZ )

    else if entityCollides blocks height moved then
        ( afterWalk, 0 )

    else
        ( moved, velocityZ )


tryMove : Blocks -> Float -> Point -> Point -> ( Point, Bool )
tryMove blocks height candidate current =
    if entityCollides blocks height candidate then
        ( current, True )

    else
        ( candidate, False )


canHop : Blocks -> Float -> Point -> Point -> Bool
canHop blocks height current candidate =
    not (entityCollides blocks height { current | z = current.z + 1.05 })
        && not (entityCollides blocks height { candidate | z = candidate.z + 1.05 })


{-| Whether something this tall standing here would be inside a block or off the map.
-}
entityCollides : Blocks -> Float -> Point -> Bool
entityCollides blocks height position =
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
            blocks
            (floor (position.x - entityRadius))
            (floor (position.x + entityRadius - epsilon))
            (floor (position.y - entityRadius))
            (floor (position.y + entityRadius - epsilon))
            (floor position.z)
            (floor (position.z + height - epsilon))


boxCollides : Blocks -> Int -> Int -> Int -> Int -> Int -> Int -> Bool
boxCollides blocks minX maxX minY maxY minZ maxZ =
    if minZ >= 0 && maxZ < lowLevels then
        columnsCollide
            blocks.columns
            (Bitwise.shiftLeftBy minZ (Bitwise.shiftLeftBy (maxZ - minZ + 1) 1 - 1))
            minX
            maxX
            minY
            minY
            maxY

    else
        List.any
            (\cellX ->
                List.any
                    (\cellY -> List.any (\cellZ -> Dict.member ( cellX, cellY, cellZ ) blocks.occupied) (List.range minZ maxZ))
                    (List.range minY maxY)
            )
            (List.range minX maxX)


columnsCollide : Array Int -> Int -> Int -> Int -> Int -> Int -> Int -> Bool
columnsCollide columns levels x maxX y minY maxY =
    if x > maxX then
        False

    else if y > maxY then
        columnsCollide columns levels (x + 1) maxX minY minY maxY

    else if
        (x >= 0)
            && (x < gridSize)
            && (y >= 0)
            && (y < gridSize)
            && (Bitwise.and levels (Array.get (x * gridSize + y) columns |> Maybe.withDefault 0) /= 0)
    then
        True

    else
        columnsCollide columns levels x maxX (y + 1) minY maxY


{-| Every block, with the id of the piece it's part of (`occupied`), and the same again in a form
that's much quicker to check a box against. Every NPC looks for walls several times a frame, which
with a couple of hundred of them was most of the time a frame took. `columns` has a bit for each of
the bottom `lowLevels` levels of each column of the grid (column x, y at x \* gridSize + y), set if
there's a block there. Anything higher up is only looked up in `occupied`. `insertBlock` and
`blocksOf` keep the two the same.
-}
type alias Blocks =
    { columns : Array Int, occupied : Dict ( Int, Int, Int ) Int }


noBlocks : Blocks
noBlocks =
    { columns = Array.repeat (gridSize * gridSize) 0, occupied = Dict.empty }


insertBlock : ( Int, Int, Int ) -> Int -> Blocks -> Blocks
insertBlock (( x, y, z ) as cell) pieceId blocks =
    { columns =
        if z >= 0 && z < lowLevels && x >= 0 && x < gridSize && y >= 0 && y < gridSize then
            let
                index : Int
                index =
                    x * gridSize + y
            in
            Array.set
                index
                (Bitwise.or (Bitwise.shiftLeftBy z 1) (Array.get index blocks.columns |> Maybe.withDefault 0))
                blocks.columns

        else
            blocks.columns
    , occupied = Dict.insert cell pieceId blocks.occupied
    }


lowLevels : Int
lowLevels =
    30


blocksOf : Dict ( Int, Int, Int ) Int -> Blocks
blocksOf occupied =
    { columns =
        Dict.foldl
            (\( x, y, z ) _ columns ->
                if z >= 0 && z < lowLevels && x >= 0 && x < gridSize && y >= 0 && y < gridSize then
                    let
                        index : Int
                        index =
                            x * gridSize + y
                    in
                    case columns of
                        ( previousIndex, levels ) :: rest ->
                            if previousIndex == index then
                                ( index, Bitwise.or levels (Bitwise.shiftLeftBy z 1) ) :: rest

                            else
                                ( index, Bitwise.shiftLeftBy z 1 ) :: columns

                        [] ->
                            [ ( index, Bitwise.shiftLeftBy z 1 ) ]

                else
                    columns
            )
            []
            occupied
            |> fillColumns (gridSize * gridSize - 1) []
            |> Array.fromList
    , occupied = occupied
    }


{-| Every column from `index` down to 0, given the ones with blocks in them, highest index first.
-}
fillColumns : Int -> List Int -> List ( Int, Int ) -> List Int
fillColumns index filled withBlocks =
    if index < 0 then
        filled

    else
        case withBlocks of
            ( columnIndex, levels ) :: rest ->
                if columnIndex == index then
                    fillColumns (index - 1) (levels :: filled) rest

                else
                    fillColumns (index - 1) (0 :: filled) withBlocks

            [] ->
                fillColumns (index - 1) (0 :: filled) []


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
        state.blocks.occupied



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
                                    || Dict.member ( floor position.x, floor position.y, floor position.z ) state.blocks.occupied
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
    pieceOverlapsBox piece level entityRadius entityHeight entity


pieceOverlapsGiant : Piece -> Float -> Point -> Bool
pieceOverlapsGiant piece level giant =
    pieceOverlapsBox piece level giantRadius giantHeight giant


pieceOverlapsBox : Piece -> Float -> Float -> Float -> Point -> Bool
pieceOverlapsBox piece level radius height entity =
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
            (entity.x + radius > cellX)
                && (entity.x - radius < cellX + 1)
                && (entity.y + radius > cellY)
                && (entity.y - radius < cellY + 1)
                && (entity.z + height > cellZ)
                && (entity.z < cellZ + 1)
        )
        piece.cells


{-| Move every falling piece down. A piece that comes down on an NPC or a giant takes it with it,
and one that comes down on a player is lost.
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
                            max -maxFallSpeed (velocity - pieceGravity * frameSeconds)

                        newZ : Float
                        newZ =
                            piece.z + velocity2 * frameSeconds

                        landing : Maybe (Maybe Int)
                        landing =
                            if fitsAt (floor newZ) piece state2.blocks.occupied then
                                Nothing

                            else
                                Just (firstFreeLevel (floor newZ + 1) 40 piece state2.blocks.occupied)

                        finalZ : Float
                        finalZ =
                            case landing of
                                Just (Just level) ->
                                    toFloat level

                                _ ->
                                    newZ

                        hitPlayer : Bool
                        hitPlayer =
                            List.any
                                (\player -> player.knockedOutAt == Nothing && pieceOverlapsEntity piece finalZ player.position)
                                (SeqDict.values state2.players)

                        -- NPCs and giants it falls on are squashed, and the piece carries on down.
                        state3 : MatchState
                        state3 =
                            { state2
                                | towers = squashTowers piece finalZ state2.towers
                                , giants = List.filter (\giant -> not (pieceOverlapsGiant piece finalZ giant.position)) state2.giants
                            }
                    in
                    if hitPlayer then
                        { state3
                            | pieces = SeqDict.remove pieceId state3.pieces
                            , debris = { piece = { piece | z = finalZ }, destroyedAt = state3.frame } :: state3.debris
                        }

                    else
                        case landing of
                            Just (Just level) ->
                                let
                                    piece2 : Piece
                                    piece2 =
                                        { piece | z = toFloat level, status = Settled state3.frame }
                                in
                                { state3
                                    | pieces = SeqDict.insert pieceId piece2 state3.pieces
                                    , blocks =
                                        List.foldl
                                            (\cell blocks -> insertBlock cell pieceId blocks)
                                            state3.blocks
                                            (pieceCells piece2)
                                }

                            Just Nothing ->
                                { state3
                                    | pieces = SeqDict.remove pieceId state3.pieces
                                    , debris = { piece = { piece | z = newZ }, destroyedAt = state3.frame } :: state3.debris
                                }

                            Nothing ->
                                { state3 | pieces = SeqDict.insert pieceId { piece | z = newZ, status = Falling velocity2 } state3.pieces }

                Settled _ ->
                    state2
        )
        state
        state.pieces


{-| Take out the NPCs in a tower that a piece at this level overlaps.
-}
squashTowers : Piece -> Float -> List Tower -> List Tower
squashTowers piece level towers =
    if List.any (\tower -> pieceOverColumn piece entityRadius tower.position) towers then
        List.filterMap (squash piece level) towers

    else
        towers


squash : Piece -> Float -> Tower -> Maybe Tower
squash piece level tower =
    if pieceOverColumn piece entityRadius tower.position then
        removeNpcs (pieceOverlapsEntity piece level) tower

    else
        Just tower


{-| Whether a piece is over or under any part of something standing at `position`, at any height.
-}
pieceOverColumn : Piece -> Float -> Point -> Bool
pieceOverColumn piece radius position =
    List.any
        (\( offsetX, offsetY, _ ) ->
            let
                cellX : Float
                cellX =
                    toFloat (piece.x + offsetX)

                cellY : Float
                cellY =
                    toFloat (piece.y + offsetY)
            in
            (position.x + radius > cellX)
                && (position.x - radius < cellX + 1)
                && (position.y + radius > cellY)
                && (position.y - radius < cellY + 1)
        )
        piece.cells


{-| Take out the NPCs in a tower standing where `isGone` says. Whoever is left stays standing where
they were, and falls if there's nothing under them any more.
-}
removeNpcs : (Point -> Bool) -> Tower -> Maybe Tower
removeNpcs isGone tower =
    case List.filter (\( _, position ) -> not (isGone position)) (npcPositions tower) of
        ( lowest, position ) :: higher ->
            Just { tower | position = position, bottom = lowest, above = List.map Tuple.first higher }

        [] ->
            Nothing


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
            SeqDict.partition
                (\_ piece ->
                    case piece.owner of
                        Just owner ->
                            List.member owner owners

                        Nothing ->
                            False
                )
                state.pieces
    in
    ( { state
        | pieces = kept
        , blocks = blocksOf (Dict.filter (\_ pieceId -> not (SeqDict.member pieceId removed)) state.blocks.occupied)
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
                    if isSettled piece.status && not (isSupported pieceId piece state.blocks.occupied) then
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
                    , blocks = blocksOf (Dict.filter (\_ pieceId -> not (List.member pieceId unsupported)) state.blocks.occupied)
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
