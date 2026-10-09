module TetrominoSim exposing
    ( Crystal
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
    , Round
    , Snowball
    , Tower
    , canDrop
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
    , isGameOver
    , isProtected
    , isSettled
    , keepInsideGrid
    , maxPieces
    , npcPositions
    , roundBreak
    , snowballGravity
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


type alias InputEvent =
    { frame : Int, userId : Id UserId, input : Input }


type alias MatchState =
    { frame : Int
    , round : Round
    , players : SeqDict (Id UserId) Player
    , waitingPlayers : SeqSet (Id UserId)
    , towers : List Tower
    , giants : List Giant
    , crystal : Crystal
    , pieces : SeqDict Int Piece
    , occupied : Dict ( Int, Int, Int ) Int
    , snowballs : List Snowball
    , debris : List Debris
    , pickups : List Pickup
    , nextId : Int
    , seed : Random.Seed
    , nextNpcSpawn : Maybe Int
    , nextGiantSpawn : Maybe Int
    , nextPickupSpawn : Maybe Int
    }


{-| What the NPCs are after. It stands in the middle of the map, two blocks wide and three high, and
the match is over once it has taken `crystalHealth` damage.
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
    , queue : PieceQueue
    , piecesLeft : Int
    , -- Dropping a piece makes the player wait a moment before they can drop another.
      nextDropAt : Int
    , -- Snowballs do nothing to a player until this frame, so that someone coming into a round
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


{-| Every kind heads for the crystal, unless a player is nearer than it is.
-}
type NpcKind
    = -- Heads straight for its target slower than a player walks, but can't hop on its own, so a
      -- wall one block high stops it. Knocks out a player it reaches.
      Chaser
      -- Keeps a few cells away from a player and throws snowballs.
    | Thrower
      -- Like a chaser, a little faster and hopping onto anything one block high.
    | Jumper


{-| NPCs that walk into each other stand on each other's heads. A tower goes wherever its bottom
NPC would, `position` is where that one stands, and each NPC in `above` stands on the one before
it. A lone NPC is a tower of one.
-}
type alias Tower =
    { position : Point
    , velocityZ : Float
    , wanderOffset : { x : Float, y : Float }
    , nextWanderFrame : Int
    , bottom : Npc
    , above : List Npc
    }


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


{-| The first round gives a whole minute to build before anything turns up.
-}
firstRoundNpcDelay : Int
firstRoundNpcDelay =
    60 * framesPerSecond


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


throwerSpeed : Float
throwerSpeed =
    0.8


chaserSpeed : Float
chaserSpeed =
    1.6


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


{-| A giant turns up this long into every round after the first.
-}
giantDelay : Int
giantDelay =
    15 * framesPerSecond


{-| How far from the crystal a giant turns up, in cells along each axis.
-}
giantSpawnDistance : Int
giantSpawnDistance =
    28


crystalHealth : Int
crystalHealth =
    3


{-| How much damage a giant reaching the crystal does.
-}
giantDamage : Int
giantDamage =
    3


{-| The crystal's blocks are in `occupied` like a piece's, under an id no piece has.
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


{-| How far from the crystal an NPC turns up, in cells along each axis.
-}
npcSpawnDistance : Int
npcSpawnDistance =
    20


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


{-| No pieces start this close to the middle of the map, where players come into a round.
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
    , round = { number = 0, startedAt = frame, nextRoundAt = Nothing }
    , players = SeqDict.empty
    , waitingPlayers = SeqSet.empty
    , towers = []
    , giants = []
    , crystal = { health = crystalHealth, lastHitAt = Nothing }
    , pieces = SeqDict.empty
    , occupied = List.foldl (\cell occupied -> Dict.insert cell crystalId occupied) Dict.empty crystalCells
    , snowballs = []
    , debris = []
    , pickups = []
    , nextId = 0
    , seed = Random.initialSeed seed
    , nextNpcSpawn = Nothing
    , nextGiantSpawn = Nothing
    , nextPickupSpawn = Nothing
    }
        |> scatterPieces sceneryPieces


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
                            (\( dx, dy ) -> Dict.member ( x + cellX + dx, y + cellY + dy, 0 ) state.occupied)
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
                        , occupied =
                            List.foldl
                                (\( cellX, cellY, cellZ ) occupied -> Dict.insert ( x + cellX, y + cellY, cellZ ) state.nextId occupied)
                                state.occupied
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
            updateRound state2
                |> updatePlayers
                |> collectPickups
                |> updateTowers
                |> hitCrystal
                |> catchPlayers
                |> updateGiants
                |> spawnNpcs
                |> spawnGiants
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

        Drop drop ->
            case SeqDict.get event.userId state.players of
                Just player ->
                    if canDrop state.frame player && Tetromino.isValidOrientation drop.orientation then
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
                , status = Falling -4
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
                        ( queue, seed3 ) =
                            Random.step randomQueue seed2

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
                                (\tower ->
                                    horizontalDistance tower.position { x = toFloat column + 0.5, y = toFloat row + 0.5, z = 0 }
                                        <= npcThrowRange
                                )
                                state.towers
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
                        , queue = queue
                        , piecesLeft = startingPieces
                        , nextDropAt = state.frame
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
        , nextNpcSpawn =
            if state.round.number == 0 then
                Just (state.frame + firstRoundNpcDelay)

            else
                Just (state.frame + npcDelay)
        , nextGiantSpawn =
            if state.round.number == 0 then
                Nothing

            else
                Just (state.frame + giantDelay)
        , nextPickupSpawn = Just (state.frame + firstPickupDelay)
    }


{-| Where around the crystal in the middle of the grid each player brought into a round appears,
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
                                state.occupied
                                player
                )
                state.players
    }


updateTowers : MatchState -> MatchState
updateTowers state =
    let
        alivePlayers : List Player
        alivePlayers =
            SeqDict.values state.players |> List.filter (\player -> player.knockedOutAt == Nothing)

        ( moved, seed ) =
            List.foldr
                (\tower ( towerList, seed2 ) ->
                    let
                        ( towers, seed3 ) =
                            moveTower state.frame alivePlayers state.occupied seed2 tower
                    in
                    ( towers ++ towerList, seed3 )
                )
                ( [], state.seed )
                state.towers

        ( thrown, snowballs, seed4 ) =
            List.foldr
                (\tower ( towerList, snowballList, seed2 ) ->
                    let
                        ( tower2, newSnowballs, seed3 ) =
                            throwFromTower state.frame alivePlayers seed2 tower
                    in
                    ( tower2 :: towerList, newSnowballs ++ snowballList, seed3 )
                )
                ( [], state.snowballs, seed )
                moved
    in
    { state | towers = mergeTowers state.occupied thrown, snowballs = snowballs, seed = seed4 }


{-| A tower walks the way its bottom NPC would on its own, except that a tower of two or more can
always hop. It can come out of this as two towers, if it walked into a wall the NPCs at the top
could step onto.
-}
moveTower : Int -> List Player -> Dict ( Int, Int, Int ) Int -> Random.Seed -> Tower -> ( List Tower, Random.Seed )
moveTower frame alivePlayers occupied seed tower =
    case tower.bottom.kind of
        Chaser ->
            if List.isEmpty tower.above then
                ( walkTowerWithoutHopping frame chaserSpeed (Just (chaseTarget tower.position alivePlayers)) occupied tower
                , seed
                )

            else
                ( walkTower frame chaserSpeed (Just (chaseTarget tower.position alivePlayers)) occupied tower, seed )

        Thrower ->
            let
                ( tower2, seed2 ) =
                    if frame >= tower.nextWanderFrame then
                        Random.step
                            (Random.map3
                                (\x y delay -> { tower | wanderOffset = { x = x, y = y }, nextWanderFrame = frame + delay })
                                (Random.float -2 2)
                                (Random.float -2 2)
                                (Random.int (2 * framesPerSecond) (4 * framesPerSecond))
                            )
                            seed

                    else
                        ( tower, seed )

                target : Maybe { x : Float, y : Float }
                target =
                    case nearestPlayer tower2.position alivePlayers of
                        Just ( player, distance ) ->
                            if distance >= distanceToCrystal tower2.position then
                                Just crystalCenter

                            else if distance > npcKeepDistance then
                                Just { x = player.position.x + tower2.wanderOffset.x, y = player.position.y + tower2.wanderOffset.y }

                            else
                                Nothing

                        Nothing ->
                            Just crystalCenter
            in
            ( walkTower frame throwerSpeed target occupied tower2, seed2 )

        Jumper ->
            ( walkTower frame jumperSpeed (Just (chaseTarget tower.position alivePlayers)) occupied tower, seed )


{-| Chasers and jumpers go for the nearest player, unless the crystal is nearer.
-}
chaseTarget : Point -> List Player -> { x : Float, y : Float }
chaseTarget position alivePlayers =
    case nearestPlayer position alivePlayers of
        Just ( player, distance ) ->
            if distance < distanceToCrystal position then
                { x = player.position.x, y = player.position.y }

            else
                crystalCenter

        Nothing ->
            crystalCenter


distanceToCrystal : Point -> Float
distanceToCrystal position =
    horizontalDistance position { x = crystalCenter.x, y = crystalCenter.y, z = 0 }


{-| Walk a tower towards a target, hopping onto anything one block high if the whole tower has
room to. Against a wall it can't hop, the NPCs high enough to clear it step onto it.
-}
walkTower : Int -> Float -> Maybe { x : Float, y : Float } -> Dict ( Int, Int, Int ) Int -> Tower -> List Tower
walkTower frame speed maybeTarget occupied tower =
    let
        height : Float
        height =
            towerHeight tower

        blockedStep : Maybe Point
        blockedStep =
            case Maybe.andThen (\target -> stepTowards speed target tower.position) maybeTarget of
                Just next ->
                    if entityCollides occupied height next && not (canHop occupied height tower.position next) then
                        Just next

                    else
                        Nothing

                Nothing ->
                    Nothing
    in
    case Maybe.andThen (\next -> splitAtWall frame occupied next tower) blockedStep of
        Just ( lower, upper ) ->
            [ moveEntity speed (towerHeight lower) maybeTarget occupied lower, upper ]

        Nothing ->
            [ moveEntity speed height maybeTarget occupied tower ]


{-| Like `walkTower`, except the tower never hops, so the NPCs high enough to clear anything in
the way step onto it.
-}
walkTowerWithoutHopping : Int -> Float -> Maybe { x : Float, y : Float } -> Dict ( Int, Int, Int ) Int -> Tower -> List Tower
walkTowerWithoutHopping frame speed maybeTarget occupied tower =
    let
        height : Float
        height =
            towerHeight tower

        blockedStep : Maybe Point
        blockedStep =
            case Maybe.andThen (\target -> stepTowards speed target tower.position) maybeTarget of
                Just next ->
                    if entityCollides occupied height next then
                        Just next

                    else
                        Nothing

                Nothing ->
                    Nothing
    in
    case Maybe.andThen (\next -> splitAtWall frame occupied next tower) blockedStep of
        Just ( lower, upper ) ->
            [ moveEntityWithoutHopping speed (towerHeight lower) maybeTarget occupied lower, upper ]

        Nothing ->
            [ moveEntityWithoutHopping speed height maybeTarget occupied tower ]


{-| The lowest NPC in a tower that fits at `next` along with everyone above it takes them all
there, as a tower of their own. Whatever is in the way is under them, so they come down on top
of it.
-}
splitAtWall : Int -> Dict ( Int, Int, Int ) Int -> Point -> Tower -> Maybe ( Tower, Tower )
splitAtWall frame occupied next tower =
    splitAtWallHelper frame occupied next tower [] tower.above


splitAtWallHelper : Int -> Dict ( Int, Int, Int ) Int -> Point -> Tower -> List Npc -> List Npc -> Maybe ( Tower, Tower )
splitAtWallHelper frame occupied next tower stayingTopFirst rest =
    case rest of
        npc :: higher ->
            let
                upper : Tower
                upper =
                    { position = heightInTower (List.length stayingTopFirst + 1) { next | z = tower.position.z }
                    , velocityZ = 0
                    , wanderOffset = { x = 0, y = 0 }
                    , nextWanderFrame = frame
                    , bottom = npc
                    , above = higher
                    }
            in
            if entityCollides occupied (towerHeight upper) upper.position then
                splitAtWallHelper frame occupied next tower (npc :: stayingTopFirst) higher

            else
                Just ( { tower | above = List.reverse stayingTopFirst }, upper )

        [] ->
            Nothing


{-| Towers that walk into each other become one, unless it wouldn't fit there.
-}
mergeTowers : Dict ( Int, Int, Int ) Int -> List Tower -> List Tower
mergeTowers occupied towers =
    case towers of
        tower :: rest ->
            case mergeWithFirstMet occupied tower [] rest of
                Just ( merged, rest2 ) ->
                    mergeTowers occupied (merged :: rest2)

                Nothing ->
                    tower :: mergeTowers occupied rest

        [] ->
            []


mergeWithFirstMet : Dict ( Int, Int, Int ) Int -> Tower -> List Tower -> List Tower -> Maybe ( Tower, List Tower )
mergeWithFirstMet occupied tower skipped rest =
    case rest of
        other :: rest2 ->
            if towersMeet tower other then
                let
                    merged : Tower
                    merged =
                        stack tower other
                in
                if entityCollides occupied (towerHeight merged) merged.position then
                    mergeWithFirstMet occupied tower (other :: skipped) rest2

                else
                    Just ( merged, List.reverse skipped ++ rest2 )

            else
                mergeWithFirstMet occupied tower (other :: skipped) rest2

        [] ->
            Nothing


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

        ( aboveTopFirst, snowballs, seed3 ) =
            List.foldl
                (\( index, npc ) ( npcList, snowballList, seed4 ) ->
                    let
                        ( npc2, snowball, seed5 ) =
                            npcThrow frame alivePlayers (heightInTower index tower.position) npc seed4
                    in
                    ( npc2 :: npcList, snowball :: snowballList, seed5 )
                )
                ( [], [ bottomSnowball ], seed2 )
                (List.indexedMap (\index npc -> ( index + 1, npc )) tower.above)
    in
    ( { tower | bottom = bottom, above = List.reverse aboveTopFirst }
    , List.filterMap identity snowballs
    , seed3
    )


npcThrow : Int -> List Player -> Point -> Npc -> Random.Seed -> ( Npc, Maybe Snowball, Random.Seed )
npcThrow frame alivePlayers position npc seed =
    case npc.kind of
        Chaser ->
            ( npc, Nothing, seed )

        Thrower ->
            case nearestPlayer position alivePlayers of
                Just ( player, distance ) ->
                    if distance <= npcThrowRange && frame >= npc.nextThrowFrame then
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


{-| Every NPC touching the crystal is gone, and does it a point of damage.
-}
hitCrystal : MatchState -> MatchState
hitCrystal state =
    let
        hits : Int
        hits =
            List.foldl
                (\tower count ->
                    count
                        + List.length
                            (List.filter
                                (\( _, position ) -> touchesCrystal entityRadius entityHeight position)
                                (npcPositions tower)
                            )
                )
                0
                state.towers
    in
    if hits > 0 then
        damageCrystal
            hits
            { state | towers = List.filterMap (removeNpcs (touchesCrystal entityRadius entityHeight)) state.towers }

    else
        state


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
player has only just come into the round.
-}
catchPlayers : MatchState -> MatchState
catchPlayers state =
    let
        catchers : List Point
        catchers =
            List.concatMap
                (\tower ->
                    List.filterMap
                        (\( npc, position ) ->
                            if catchesPlayers npc.kind then
                                Just position

                            else
                                Nothing
                        )
                        (npcPositions tower)
                )
                state.towers
    in
    { state
        | players =
            SeqDict.map
                (\_ player ->
                    if
                        (player.knockedOutAt == Nothing)
                            && not (isProtected state.frame player)
                            && List.any (\position -> entitiesTouch position player.position) catchers
                    then
                        { player | knockedOutAt = Just state.frame, target = Nothing }

                    else
                        player
                )
                state.players
    }


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


{-| While anyone is standing in the round, NPCs turn up on a ring around the crystal and make for
it.
-}
spawnNpcs : MatchState -> MatchState
spawnNpcs state =
    case state.nextNpcSpawn of
        Just spawnFrame ->
            if state.frame >= spawnFrame then
                let
                    anyoneStanding : Bool
                    anyoneStanding =
                        List.any (\player -> player.knockedOutAt == Nothing) (SeqDict.values state.players)

                    ( roll, seed ) =
                        Random.step
                            (Random.map3
                                (\side along kindRoll -> { side = side, along = along, kindRoll = kindRoll })
                                (Random.int 0 3)
                                (Random.int -npcSpawnDistance npcSpawnDistance)
                                (Random.int 0 3)
                            )
                            state.seed

                    kind : NpcKind
                    kind =
                        if state.round.number <= 1 then
                            Chaser

                        else
                            case roll.kindRoll of
                                0 ->
                                    Thrower

                                1 ->
                                    Jumper

                                _ ->
                                    Chaser

                    ( offsetX, offsetY ) =
                        case roll.side of
                            0 ->
                                ( roll.along, -npcSpawnDistance )

                            1 ->
                                ( roll.along, npcSpawnDistance )

                            2 ->
                                ( -npcSpawnDistance, roll.along )

                            _ ->
                                ( npcSpawnDistance, roll.along )

                    towers : List Tower
                    towers =
                        if anyoneStanding && npcCount state.towers < npcLimit then
                            let
                                x : Int
                                x =
                                    clamp 0 (gridSize - 1) (gridSize // 2 + offsetX)

                                y : Int
                                y =
                                    clamp 0 (gridSize - 1) (gridSize // 2 + offsetY)
                            in
                            state.towers
                                ++ [ { position = { x = toFloat x + 0.5, y = toFloat y + 0.5, z = toFloat (topOfColumn x y state) }
                                     , velocityZ = 0
                                     , wanderOffset = { x = 0, y = 0 }
                                     , nextWanderFrame = state.frame
                                     , bottom = { id = state.nextId, kind = kind, nextThrowFrame = state.frame + 3 * framesPerSecond }
                                     , above = []
                                     }
                                   ]

                        else
                            state.towers
                in
                { state
                    | towers = towers
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
    max (6 * framesPerSecond) (12 * framesPerSecond - framesIntoRound // 15)



-- Giants


{-| A giant turns up on a ring far out from the crystal, once in every round after the first.
-}
spawnGiants : MatchState -> MatchState
spawnGiants state =
    case state.nextGiantSpawn of
        Just spawnFrame ->
            if state.frame >= spawnFrame then
                let
                    ( ( side, along ), seed ) =
                        Random.step
                            (Random.pair (Random.int 0 3) (Random.int -giantSpawnDistance giantSpawnDistance))
                            state.seed

                    ( offsetX, offsetY ) =
                        case side of
                            0 ->
                                ( along, -giantSpawnDistance )

                            1 ->
                                ( along, giantSpawnDistance )

                            2 ->
                                ( -giantSpawnDistance, along )

                            _ ->
                                ( giantSpawnDistance, along )

                    x : Int
                    x =
                        clamp 0 (gridSize - 1) (gridSize // 2 + offsetX)

                    y : Int
                    y =
                        clamp 0 (gridSize - 1) (gridSize // 2 + offsetY)
                in
                { state
                    | giants =
                        state.giants
                            ++ [ { id = state.nextId
                                 , position = { x = toFloat x + 0.5, y = toFloat y + 0.5, z = toFloat (topOfColumn x y state) }
                                 , velocityZ = 0
                                 , blockedSince = Nothing
                                 }
                               ]
                    , nextId = state.nextId + 1
                    , seed = seed
                    , nextGiantSpawn = Nothing
                }

            else
                state

        Nothing ->
            state


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
                case giantBlockedBy state.occupied next of
                    [] ->
                        { state | giants = fallGiant state.occupied { giant | position = next, blockedSince = Nothing } :: state.giants }

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
                                    { state | giants = fallGiant state.occupied giant :: state.giants }

                            Nothing ->
                                { state | giants = fallGiant state.occupied { giant | blockedSince = Just state.frame } :: state.giants }

            Nothing ->
                { state | giants = fallGiant state.occupied giant :: state.giants }


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


giantCollides : Dict ( Int, Int, Int ) Int -> Point -> Bool
giantCollides occupied position =
    (position.z < 0)
        || boxCollides
            occupied
            (floor (position.x - giantRadius))
            (floor (position.x + giantRadius - epsilon))
            (floor (position.y - giantRadius))
            (floor (position.y + giantRadius - epsilon))
            (floor position.z)
            (floor (position.z + giantHeight - epsilon))


fallGiant : Dict ( Int, Int, Int ) Int -> Giant -> Giant
fallGiant occupied giant =
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
    if giantCollides occupied { position | z = newZ } then
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
    case Dict.get cell state.occupied of
        Just pieceId ->
            let
                state2 : MatchState
                state2 =
                    { state | occupied = Dict.remove cell state.occupied }
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


{-| A player standing in the round who touches a pickup takes it, and everyone gets more pieces.
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
moveEntity : Float -> Float -> Maybe { x : Float, y : Float } -> Dict ( Int, Int, Int ) Int -> { a | position : Point, velocityZ : Float } -> { a | position : Point, velocityZ : Float }
moveEntity speed height maybeTarget occupied entity =
    let
        position : Point
        position =
            unstuck occupied entity.position

        walked : { position : Point, couldHop : Bool }
        walked =
            walk speed height maybeTarget occupied position

        velocityZ : Float
        velocityZ =
            if walked.couldHop && entityCollides occupied height { position | z = position.z - 0.01 } then
                jumpVelocity

            else
                fallingVelocity entity
    in
    moveVertically occupied height velocityZ walked.position entity


{-| Like `moveEntity`, except it never hops, so anything in the way stops it.
-}
moveEntityWithoutHopping : Float -> Float -> Maybe { x : Float, y : Float } -> Dict ( Int, Int, Int ) Int -> { a | position : Point, velocityZ : Float } -> { a | position : Point, velocityZ : Float }
moveEntityWithoutHopping speed height maybeTarget occupied entity =
    let
        walked : { position : Point, couldHop : Bool }
        walked =
            walk speed height maybeTarget occupied (unstuck occupied entity.position)
    in
    moveVertically occupied height (fallingVelocity entity) walked.position entity


{-| Something that ends up inside a block, like a player a piece landed next to, is lifted on top
of it.
-}
unstuck : Dict ( Int, Int, Int ) Int -> Point -> Point
unstuck occupied position =
    if entityCollides occupied entityHeight position then
        { position | z = toFloat (floor position.z + 1) }

    else
        position


{-| A step towards the target that doesn't go into any block, sliding along a wall if it can, and
whether there was something in the way it could have hopped onto.
-}
walk : Float -> Float -> Maybe { x : Float, y : Float } -> Dict ( Int, Int, Int ) Int -> Point -> { position : Point, couldHop : Bool }
walk speed height maybeTarget occupied position =
    case Maybe.andThen (\target -> stepTowards speed target position) maybeTarget of
        Just next ->
            let
                ( afterX, blockedX ) =
                    tryMove occupied height { position | x = next.x } position

                ( afterY, blockedY ) =
                    tryMove occupied height { afterX | y = next.y } afterX
            in
            { position = afterY
            , couldHop =
                (blockedX && canHop occupied height position { position | x = next.x })
                    || (blockedY && canHop occupied height afterX { afterX | y = next.y })
            }

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
        Just { position | x = target.x, y = target.y }

    else
        Just
            { position
                | x = position.x + dx / distance * speed * frameSeconds
                , y = position.y + dy / distance * speed * frameSeconds
            }


fallingVelocity : { a | velocityZ : Float } -> Float
fallingVelocity entity =
    max -maxFallSpeed (entity.velocityZ - gravity * frameSeconds)


moveVertically : Dict ( Int, Int, Int ) Int -> Float -> Float -> Point -> { a | position : Point, velocityZ : Float } -> { a | position : Point, velocityZ : Float }
moveVertically occupied height velocityZ afterWalk entity =
    let
        newZ : Float
        newZ =
            afterWalk.z + velocityZ * frameSeconds
    in
    if velocityZ <= 0 then
        if entityCollides occupied height { afterWalk | z = newZ } then
            { entity | position = { afterWalk | z = max 0 (toFloat (floor newZ + 1)) }, velocityZ = 0 }

        else
            { entity | position = { afterWalk | z = newZ }, velocityZ = velocityZ }

    else if entityCollides occupied height { afterWalk | z = newZ } then
        { entity | position = afterWalk, velocityZ = 0 }

    else
        { entity | position = { afterWalk | z = newZ }, velocityZ = velocityZ }


tryMove : Dict ( Int, Int, Int ) Int -> Float -> Point -> Point -> ( Point, Bool )
tryMove occupied height candidate current =
    if entityCollides occupied height candidate then
        ( current, True )

    else
        ( candidate, False )


canHop : Dict ( Int, Int, Int ) Int -> Float -> Point -> Point -> Bool
canHop occupied height current candidate =
    not (entityCollides occupied height { current | z = current.z + 1.05 })
        && not (entityCollides occupied height { candidate | z = candidate.z + 1.05 })


{-| Whether something this tall standing here would be inside a block or off the map.
-}
entityCollides : Dict ( Int, Int, Int ) Int -> Float -> Point -> Bool
entityCollides occupied height position =
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
            (floor (position.z + height - epsilon))


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

                        hitPlayer : Bool
                        hitPlayer =
                            List.any
                                (\player -> player.knockedOutAt == Nothing && pieceOverlapsEntity piece finalZ player.position)
                                (SeqDict.values state2.players)

                        -- NPCs and giants it falls on are squashed, and the piece carries on down.
                        state3 : MatchState
                        state3 =
                            { state2
                                | towers = List.filterMap (squash piece finalZ) state2.towers
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
                                    , occupied =
                                        List.foldl
                                            (\cell occupied -> Dict.insert cell pieceId occupied)
                                            state3.occupied
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
squash : Piece -> Float -> Tower -> Maybe Tower
squash piece level tower =
    removeNpcs (pieceOverlapsEntity piece level) tower


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
