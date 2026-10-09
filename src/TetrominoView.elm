module TetrominoView exposing
    ( Camera
    , Cursor
    , camera
    , previewEntities
    , screenToCell
    , worldEntities
    )

import Color exposing (Color)
import Dict exposing (Dict)
import Effect.WebGL as WebGL exposing (Entity, Mesh, Shader)
import Effect.WebGL.Settings
import Effect.WebGL.Settings.Blend as Blend
import Effect.WebGL.Settings.DepthTest
import Id exposing (Id, UserId)
import Math.Matrix4 as Mat4 exposing (Mat4)
import Math.Vector2 as Vec2 exposing (Vec2)
import Math.Vector3 as Vec3 exposing (Vec3)
import SeqDict
import Tetromino exposing (Orientation, Shape)
import TetrominoSim exposing (Crystal, Debris, Giant, MatchState, NpcKind, Pickup, Piece, PieceStatus(..), Player, Point)


{-| The column the pointer is over, and the height of the surface there.
-}
type alias Cursor =
    { x : Int, y : Int, z : Int }


type alias Vertex =
    { position : Vec3, normal : Vec3, uv : Vec2 }


type alias Uniforms =
    { viewProjection : Mat4
    , offset : Vec3
    , scale : Vec3
    , color : Vec3
    , alpha : Float
    , edge : Float
    }


type alias Varyings =
    { vNormal : Vec3, vUv : Vec2 }


{-| What the camera looks at, and how far it's zoomed out from its closest.
-}
type alias Camera =
    { focus : Vec3, zoom : Float }


{-| Follows this client's player, or looks at the middle of the map while they haven't joined.
The higher up they stand the further it zooms out, going by their height averaged over the last
second (`recent`, newest first) so that hopping doesn't make it bob.
-}
camera : Id UserId -> List MatchState -> Camera
camera currentUserId recent =
    case recent of
        latest :: _ ->
            case SeqDict.get currentUserId latest.players of
                Just player ->
                    let
                        heights : List Float
                        heights =
                            List.take TetrominoSim.framesPerSecond recent
                                |> List.filterMap (\state -> SeqDict.get currentUserId state.players)
                                |> List.map (\earlier -> earlier.position.z)

                        height : Float
                        height =
                            List.sum heights / toFloat (max 1 (List.length heights))
                    in
                    { focus = Vec3.vec3 player.position.x player.position.y (height + 1)
                    , zoom = 1 + 0.1 * height
                    }

                Nothing ->
                    middleOfTheMap

        [] ->
            middleOfTheMap


middleOfTheMap : Camera
middleOfTheMap =
    { focus = Vec3.vec3 (toFloat TetrominoSim.gridSize / 2) (toFloat TetrominoSim.gridSize / 2) 1, zoom = 1 }


{-| Looking down at the focus from the side nearest x = 0, y = 0, a little steeper than the classic
isometric angle. It's a perspective view from far enough away, through a narrow enough lens, that
it still looks nearly isometric. Zooming out moves the camera further back.
-}
viewProjection : Int -> Int -> Camera -> Mat4
viewProjection width height { focus, zoom } =
    let
        aspect : Float
        aspect =
            toFloat (max 1 width) / toFloat (max 1 height)

        distance : Float
        distance =
            cameraDistance * zoom

        -- Half the height of what's in view at the focus.
        halfHeight : Float
        halfHeight =
            8.5 * zoom
    in
    Mat4.mul
        (Mat4.makePerspective (2 * atan (halfHeight / distance) * 180 / pi) aspect 1 1000)
        (Mat4.makeLookAt
            (Vec3.add focus (Vec3.scale distance (Vec3.normalize (Vec3.vec3 -40 -40 70))))
            focus
            (Vec3.vec3 0 0 1)
        )


{-| How far the camera is from what it's looking at, when it's zoomed in all the way.
-}
cameraDistance : Float
cameraDistance =
    45


{-| Which column is under a point on the canvas, given in CSS pixels from its top left corner.
-}
screenToCell : Int -> Int -> Camera -> { x : Float, y : Float } -> MatchState -> Maybe Cursor
screenToCell width height camera2 screenPosition state =
    case Mat4.inverse (viewProjection width height camera2) of
        Just inverse ->
            let
                ndcX : Float
                ndcX =
                    2 * screenPosition.x / toFloat (max 1 width) - 1

                ndcY : Float
                ndcY =
                    1 - 2 * screenPosition.y / toFloat (max 1 height)

                near : Vec3
                near =
                    Mat4.transform inverse (Vec3.vec3 ndcX ndcY -1)

                far : Vec3
                far =
                    Mat4.transform inverse (Vec3.vec3 ndcX ndcY 1)

                direction : Vec3
                direction =
                    Vec3.direction far near

                top : Float
                top =
                    40

                -- Nothing is ever higher than `top`, so the ray needn't start any higher.
                start : Vec3
                start =
                    if Vec3.getZ near > top then
                        Vec3.add near (Vec3.scale ((top - Vec3.getZ near) / Vec3.getZ direction) direction)

                    else
                        near
            in
            castRay state.blocks.occupied (Vec3.scale 0.02 direction) start 4000

        Nothing ->
            Nothing


castRay : Dict ( Int, Int, Int ) Int -> Vec3 -> Vec3 -> Int -> Maybe Cursor
castRay occupied stepVector position stepsLeft =
    let
        x : Int
        x =
            floor (Vec3.getX position)

        y : Int
        y =
            floor (Vec3.getY position)

        z : Int
        z =
            floor (Vec3.getZ position)
    in
    if stepsLeft <= 0 then
        Nothing

    else if z < 0 then
        if x >= 0 && y >= 0 && x < TetrominoSim.gridSize && y < TetrominoSim.gridSize then
            Just { x = x, y = y, z = 0 }

        else
            Nothing

    else if Dict.member ( x, y, z ) occupied then
        Just { x = x, y = y, z = firstFreeAbove occupied x y z }

    else
        castRay occupied stepVector (Vec3.add position stepVector) (stepsLeft - 1)


firstFreeAbove : Dict ( Int, Int, Int ) Int -> Int -> Int -> Int -> Int
firstFreeAbove occupied x y z =
    if Dict.member ( x, y, z ) occupied && z < 100 then
        firstFreeAbove occupied x y (z + 1)

    else
        z


{-| The occupied heights in each column, so that finding what's under something doesn't mean
looking through every block.
-}
type alias Columns =
    Dict ( Int, Int ) (List Int)


toColumns : Dict ( Int, Int, Int ) Int -> Columns
toColumns occupied =
    Dict.foldl
        (\( x, y, z ) _ columns ->
            Dict.update ( x, y ) (\maybe -> Just (z :: Maybe.withDefault [] maybe)) columns
        )
        Dict.empty
        occupied


{-| The height a piece would come to rest at if dropped on this column right now.
-}
landingLevel : Columns -> List ( Int, Int, Int ) -> Int -> Int -> Int
landingLevel columns cells column row =
    List.foldl
        (\( offsetX, offsetY, offsetZ ) level ->
            max level (surfaceBelow columns (column + offsetX) (row + offsetY) 1000 - offsetZ)
        )
        0
        cells


surfaceBelow : Columns -> Int -> Int -> Float -> Int
surfaceBelow columns column row below =
    case Dict.get ( column, row ) columns of
        Just levels ->
            List.foldl
                (\level top ->
                    if toFloat level < below then
                        max top (level + 1)

                    else
                        top
                )
                0
                levels

        Nothing ->
            0


worldEntities :
    { width : Int
    , height : Int
    , camera : Camera
    , currentUserId : Id UserId
    , userColor : Id UserId -> Color
    , cursor : Maybe Cursor
    , ghost : Maybe { shape : Shape, orientation : Orientation }
    }
    -> MatchState
    -> List Entity
worldEntities config state =
    let
        vp : Mat4
        vp =
            viewProjection
                config.width
                config.height
                { focus = Vec3.add config.camera.focus (screenShake config.camera.focus state), zoom = config.camera.zoom }

        columns : Columns
        columns =
            toColumns state.blocks.occupied

        alivePlayers : List ( Id UserId, Player )
        alivePlayers =
            SeqDict.toList state.players |> List.filter (\( _, player ) -> player.knockedOutAt == Nothing)

        npcs : List ( TetrominoSim.Npc, Point )
        npcs =
            List.concatMap TetrominoSim.npcPositions state.towers

        groundAndPieces : List Entity
        groundAndPieces =
            groundEntity vp :: List.concatMap (pieceEntities vp config.userColor) (SeqDict.values state.pieces)

        -- Drawn while the depth buffer only holds the ground and the pieces, so what passes the
        -- depth test is exactly the part hidden behind a piece.
        silhouettes : List Entity
        silhouettes =
            List.concatMap
                (\( _, player ) ->
                    let
                        parts : { body : Part, head : Part }
                        parts =
                            playerParts player.position
                    in
                    [ silhouetteEntity vp playerSilhouetteColor parts.body
                    , silhouetteEntity vp playerSilhouetteColor parts.head
                    ]
                )
                alivePlayers
                ++ List.concatMap
                    (\( npc, position ) ->
                        List.map (\( part, _ ) -> silhouetteEntity vp npcSilhouetteColor part) (npcParts npc.kind position)
                    )
                    npcs
                ++ List.concatMap
                    (\giant -> List.map (\( part, _ ) -> silhouetteEntity vp npcSilhouetteColor part) (giantParts giant))
                    state.giants

        everythingElse : List Entity
        everythingElse =
            List.concatMap
                (\( userId, player ) -> playerEntities vp state.frame (config.userColor userId) player)
                alivePlayers
                ++ List.concatMap (\( npc, position ) -> npcEntities vp npc.kind position) npcs
                ++ List.map
                    (\snowball -> sphereEntity vp snowball.position TetrominoSim.snowballRadius snowWhite)
                    state.snowballs
                ++ List.concatMap (debrisEntities vp config.userColor state.frame) state.debris
                ++ List.concatMap (pickupEntities vp state.frame) state.pickups
                ++ List.concatMap (\giant -> List.map (\( part, color ) -> partEntity vp color part) (giantParts giant)) state.giants
                ++ [ crystalEntity vp state.frame state.crystal ]

        shadows : List Entity
        shadows =
            List.concatMap (fallingPieceShadows vp columns) (SeqDict.values state.pieces)
                ++ overhangShadows vp columns state.blocks.occupied
                ++ List.map
                    (\( _, player ) -> discShadow vp columns player.position (TetrominoSim.entityRadius * 2))
                    alivePlayers
                ++ List.map (\tower -> discShadow vp columns tower.position (TetrominoSim.entityRadius * 2)) state.towers
                ++ List.map (\giant -> discShadow vp columns giant.position (TetrominoSim.giantRadius * 2.2)) state.giants
                ++ List.map
                    (\snowball -> discShadow vp columns snowball.position (TetrominoSim.snowballRadius * 2))
                    state.snowballs
                ++ List.map
                    (\pickup ->
                        discShadow
                            vp
                            columns
                            { x = toFloat pickup.x + 0.5, y = toFloat pickup.y + 0.5, z = toFloat pickup.z }
                            0.6
                    )
                    state.pickups

        walkTarget : List Entity
        walkTarget =
            case SeqDict.get config.currentUserId state.players of
                Just player ->
                    case ( player.knockedOutAt, player.target ) of
                        ( Nothing, Just ( x, y ) ) ->
                            if
                                horizontalDistance
                                    player.position
                                    { x = toFloat x + 0.5, y = toFloat y + 0.5, z = player.position.z }
                                    < 0.05
                            then
                                []

                            else
                                [ walkTargetEntity vp (toFloat x) (toFloat y) (toFloat (surfaceBelow columns x y 1000)) ]

                        _ ->
                            []

                Nothing ->
                    []

        overlays : List Entity
        overlays =
            case config.cursor of
                Just cursor ->
                    case config.ghost of
                        Just ghost ->
                            let
                                cells : List ( Int, Int, Int )
                                cells =
                                    Tetromino.cells ghost.orientation ghost.shape

                                ( x0, y0 ) =
                                    TetrominoSim.keepInsideGrid cells cursor.x cursor.y

                                level : Int
                                level =
                                    landingLevel columns cells x0 y0

                                color : Color
                                color =
                                    if TetrominoSim.coversCrystal cells x0 y0 then
                                        Color.rgb 1 0.2 0.15

                                    else
                                        config.userColor config.currentUserId
                            in
                            List.map
                                (\( x, y, z ) ->
                                    ditheredCube
                                        vp
                                        (Vec3.vec3 (toFloat (x0 + x)) (toFloat (y0 + y)) (toFloat (level + z)))
                                        (lighterHigherUp (toFloat (level + z)) color)
                                )
                                cells

                        Nothing ->
                            [ flatSquare vp (toFloat cursor.x) (toFloat cursor.y) (toFloat cursor.z) 1 (Vec3.vec3 1 1 1) 0.7 ]

                Nothing ->
                    []
    in
    groundAndPieces ++ silhouettes ++ everythingElse ++ shadows ++ walkTarget ++ overlays


horizontalDistance : Point -> Point -> Float
horizontalDistance a b =
    sqrt ((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2)


{-| A green ring lying on top of the column the player is walking to.
-}
walkTargetEntity : Mat4 -> Float -> Float -> Float -> Entity
walkTargetEntity vp x y z =
    WebGL.entity
        vertexShader
        ringFragmentShader
        squareMesh
        { viewProjection = vp
        , offset = Vec3.vec3 (x + 0.05) (y + 0.05) (z + 0.02)
        , scale = Vec3.vec3 0.9 0.9 1
        , color = Vec3.vec3 0.2 0.85 0.3
        , alpha = 1
        , edge = 0
        }


{-| Only every other pixel of a shadow is drawn, so this is twice as dark as the shadow looks.
-}
shadowAlpha : Float
shadowAlpha =
    0.6


{-| A small jolt of the camera for a moment after a piece lands nearby, fading with distance.
-}
screenShake : Vec3 -> MatchState -> Vec3
screenShake focus state =
    let
        shakeFrames : Int
        shakeFrames =
            12

        strength : Float
        strength =
            SeqDict.foldl
                (\_ piece total ->
                    case piece.status of
                        Settled landedAt ->
                            let
                                age : Int
                                age =
                                    state.frame - landedAt

                                distance : Float
                                distance =
                                    sqrt ((toFloat piece.x - Vec3.getX focus) ^ 2 + (toFloat piece.y - Vec3.getY focus) ^ 2)
                            in
                            if age < shakeFrames then
                                total + (1 - toFloat age / toFloat shakeFrames) * max 0 (1 - distance / 24)

                            else
                                total

                        Falling _ ->
                            total
                )
                0
                state.pieces
                |> min 1

        frame : Float
        frame =
            toFloat state.frame
    in
    Vec3.vec3 (0.06 * strength * sin (frame * 3.3)) (-0.06 * strength * sin (frame * 3.3)) (0.16 * strength * cos (frame * 2.1))


previewEntities : Int -> Int -> Color -> Orientation -> Shape -> List Entity
previewEntities width height color orientation shape =
    let
        cells : List ( Int, Int, Int )
        cells =
            Tetromino.cells orientation shape

        aspect : Float
        aspect =
            toFloat (max 1 width) / toFloat (max 1 height)

        middle : (( Int, Int, Int ) -> Int) -> Float
        middle getter =
            let
                values : List Int
                values =
                    List.map getter cells
            in
            toFloat (Maybe.withDefault 0 (List.minimum values) + Maybe.withDefault 0 (List.maximum values) + 1) / 2

        center : Vec3
        center =
            Vec3.vec3 (middle (\( x, _, _ ) -> x)) (middle (\( _, y, _ ) -> y)) (middle (\( _, _, z ) -> z))

        vp : Mat4
        vp =
            Mat4.mul
                (Mat4.makeOrtho (-2.6 * aspect) (2.6 * aspect) -2.6 2.6 -100 100)
                (Mat4.makeLookAt (Vec3.add center (Vec3.vec3 -20 -20 20)) center (Vec3.vec3 0 0 1))
    in
    List.map
        (\( x, y, z ) -> cubeEntity vp (Vec3.vec3 (toFloat x) (toFloat y) (toFloat z)) color)
        cells


pieceEntities : Mat4 -> (Id UserId -> Color) -> Piece -> List Entity
pieceEntities vp userColor piece =
    let
        color : Color
        color =
            pieceColor userColor piece
    in
    List.map
        (\( x, y, z ) ->
            cubeEntity
                vp
                (Vec3.vec3 (toFloat (piece.x + x)) (toFloat (piece.y + y)) (piece.z + toFloat z))
                (lighterHigherUp (piece.z + toFloat z) color)
        )
        piece.cells


{-| Blocks fade towards white the higher they are, to make it easier to tell how tall something is.
-}
lighterHigherUp : Float -> Color -> Color
lighterHigherUp z color =
    mix color (Color.rgb 1 1 1) (clamp 0 0.75 (z * 0.08))


{-| The pieces a match starts with lying around belong to nobody, so they're a neutral grey.
-}
pieceColor : (Id UserId -> Color) -> Piece -> Color
pieceColor userColor piece =
    case piece.owner of
        Just owner ->
            userColor owner

        Nothing ->
            Color.rgb 0.6 0.64 0.72


{-| A destroyed piece flying apart into its cubes, each shrinking away to nothing.
-}
debrisEntities : Mat4 -> (Id UserId -> Color) -> Int -> Debris -> List Entity
debrisEntities vp userColor frame debris =
    let
        piece : Piece
        piece =
            debris.piece

        progress : Float
        progress =
            toFloat (frame - debris.destroyedAt) / toFloat TetrominoSim.debrisFrames

        seconds : Float
        seconds =
            toFloat (frame - debris.destroyedAt) / TetrominoSim.framesPerSecond

        cellCount : Float
        cellCount =
            toFloat (max 1 (List.length piece.cells))

        middle : Vec3
        middle =
            List.foldl
                (\( x, y, z ) sum -> Vec3.add sum (Vec3.vec3 (toFloat x) (toFloat y) (toFloat z)))
                (Vec3.vec3 0 0 0)
                piece.cells
                |> Vec3.scale (1 / cellCount)

        size : Float
        size =
            max 0 (1 - progress * progress)

        color : Color
        color =
            pieceColor userColor piece
    in
    List.map
        (\( x, y, z ) ->
            let
                cell : Vec3
                cell =
                    Vec3.vec3 (toFloat x) (toFloat y) (toFloat z)

                outwards : Vec3
                outwards =
                    Vec3.add (Vec3.scale 4 (Vec3.sub cell middle)) (Vec3.vec3 0 0 3)

                center : Vec3
                center =
                    Vec3.vec3 (toFloat piece.x + 0.5) (toFloat piece.y + 0.5) (piece.z + 0.5)
                        |> Vec3.add cell
                        |> Vec3.add (Vec3.scale seconds outwards)
                        |> Vec3.add (Vec3.vec3 0 0 (-6 * seconds * seconds))
            in
            WebGL.entity
                vertexShader
                fragmentShader
                cubeMesh
                { viewProjection = vp
                , offset = Vec3.sub center (Vec3.vec3 (size / 2) (size / 2) (size / 2))
                , scale = Vec3.vec3 size size size
                , color = colorToVec3 (lighterHigherUp (Vec3.getZ center - 0.5) color)
                , alpha = 1
                , edge = 1
                }
        )
        piece.cells


fallingPieceShadows : Mat4 -> Columns -> Piece -> List Entity
fallingPieceShadows vp columns piece =
    case piece.status of
        Falling _ ->
            footprint piece.cells
                |> List.map
                    (\( ( offsetX, offsetY ), offsetZ ) ->
                        let
                            cellX : Int
                            cellX =
                                piece.x + offsetX

                            cellY : Int
                            cellY =
                                piece.y + offsetY
                        in
                        flatSquare
                            vp
                            (toFloat cellX)
                            (toFloat cellY)
                            (toFloat (surfaceBelow columns cellX cellY (piece.z + toFloat offsetZ)))
                            1
                            (Vec3.vec3 0 0 0)
                            shadowAlpha
                    )

        Settled _ ->
            []


{-| The columns a piece covers, each with the height of its lowest cell there.
-}
footprint : List ( Int, Int, Int ) -> List ( ( Int, Int ), Int )
footprint cells =
    List.foldl
        (\( offsetX, offsetY, offsetZ ) lowest ->
            Dict.update
                ( offsetX, offsetY )
                (\maybe ->
                    case maybe of
                        Just lowestSoFar ->
                            Just (min offsetZ lowestSoFar)

                        Nothing ->
                            Just offsetZ
                )
                lowest
        )
        Dict.empty
        cells
        |> Dict.toList


{-| Every block with nothing under it casts a shadow straight down onto whatever is below.
-}
overhangShadows : Mat4 -> Columns -> Dict ( Int, Int, Int ) Int -> List Entity
overhangShadows vp columns occupied =
    Dict.foldl
        (\( x, y, z ) _ shadows ->
            if z > 0 && not (Dict.member ( x, y, z - 1 ) occupied) then
                flatSquare
                    vp
                    (toFloat x)
                    (toFloat y)
                    (toFloat (surfaceBelow columns x y (toFloat z)))
                    1
                    (Vec3.vec3 0 0 0)
                    shadowAlpha
                    :: shadows

            else
                shadows
        )
        []
        occupied


discShadow : Mat4 -> Columns -> Point -> Float -> Entity
discShadow vp columns position size =
    WebGL.entityWith
        ditheredSettings
        vertexShader
        ditheredDiscFragmentShader
        squareMesh
        { viewProjection = vp
        , offset =
            Vec3.vec3
                (position.x - size / 2)
                (position.y - size / 2)
                (toFloat (surfaceBelow columns (floor position.x) (floor position.y) (position.z + 0.01)) + 0.01)
        , scale = Vec3.vec3 size size 1
        , color = Vec3.vec3 0 0 0
        , alpha = shadowAlpha
        , edge = 0
        }


playerEntities : Mat4 -> Int -> Color -> Player -> List Entity
playerEntities vp frame userColor player =
    let
        color : Color
        color =
            if TetrominoSim.isProtected frame player then
                let
                    pulse : Float
                    pulse =
                        0.5 + 0.5 * sin (toFloat frame * 0.35)
                in
                mix (Color.rgb 1 0.8 0.15) (Color.rgb 1 1 1) pulse

            else
                userColor

        parts : { body : Part, head : Part }
        parts =
            playerParts player.position
    in
    [ partEntity vp color parts.body, partEntity vp color parts.head ]


npcEntities : Mat4 -> NpcKind -> Point -> List Entity
npcEntities vp kind position =
    List.map (\( part, color ) -> partEntity vp color part) (npcParts kind position)


{-| A little gold T-piece bobbing over its column.
-}
pickupEntities : Mat4 -> Int -> Pickup -> List Entity
pickupEntities vp frame pickup =
    let
        size : Float
        size =
            0.2

        bob : Float
        bob =
            0.08 * sin (toFloat (frame + pickup.id * 17) * 0.1)

        corner : Vec3
        corner =
            Vec3.vec3
                (toFloat pickup.x + 0.5 - size * 1.5)
                (toFloat pickup.y + 0.5 - size)
                (toFloat pickup.z + 0.3 + bob)
    in
    List.map
        (\( x, y ) ->
            partEntity
                vp
                (Color.rgb 1 0.8 0.2)
                { mesh = cubeMesh
                , offset = Vec3.add corner (Vec3.vec3 (toFloat x * size) (toFloat y * size) 0)
                , scale = Vec3.vec3 size size size
                }
        )
        [ ( 0, 0 ), ( 1, 0 ), ( 2, 0 ), ( 1, 1 ) ]


{-| A gem filling the crystal's blocks. It flashes red for a moment after it's
hit, and goes dark once destroyed.
-}
crystalEntity : Mat4 -> Int -> Crystal -> Entity
crystalEntity vp frame crystal =
    let
        healthy : Color
        healthy =
            mix (Color.rgb 0.7 0.35 1) (Color.rgb 0.88 0.7 1) (0.5 + 0.5 * sin (toFloat frame * 0.05))

        color : Color
        color =
            if crystal.health <= 0 then
                Color.rgb 0.25 0.27 0.32

            else
                case crystal.lastHitAt of
                    Just hitAt ->
                        if frame - hitAt < 40 then
                            mix (Color.rgb 1 0.2 0.15) healthy (toFloat (frame - hitAt) / 40)

                        else
                            healthy

                    Nothing ->
                        healthy
    in
    partEntity
        vp
        color
        { mesh = crystalMesh
        , offset = Vec3.vec3 (TetrominoSim.crystalCenter.x - 1) (TetrominoSim.crystalCenter.y - 1) 0
        , scale = Vec3.vec3 2 2 (toFloat TetrominoSim.crystalHeight)
        }


{-| A hulking block of ice with a smaller one for a head, as tall as two blocks.
-}
giantParts : Giant -> List ( Part, Color )
giantParts giant =
    let
        position : Point
        position =
            giant.position

        width : Float
        width =
            TetrominoSim.giantRadius * 2

        bodyHeight : Float
        bodyHeight =
            TetrominoSim.giantHeight - 0.55
    in
    [ ( { mesh = cubeMesh
        , offset = Vec3.vec3 (position.x - width / 2) (position.y - width / 2) position.z
        , scale = Vec3.vec3 width width bodyHeight
        }
      , Color.rgb 0.5 0.62 0.8
      )
    , ( { mesh = cubeMesh
        , offset = Vec3.vec3 (position.x - 0.28) (position.y - 0.28) (position.z + bodyHeight)
        , scale = Vec3.vec3 0.56 0.56 0.55
        }
      , Color.rgb 0.62 0.74 0.9
      )
    ]


{-| One shape of a model, placed in the world.
-}
type alias Part =
    { mesh : Mesh Vertex, offset : Vec3, scale : Vec3 }


playerParts : Point -> { body : Part, head : Part }
playerParts position =
    let
        bodyHeight : Float
        bodyHeight =
            TetrominoSim.entityHeight - 0.3
    in
    { body =
        { mesh = cubeMesh
        , offset = Vec3.vec3 (position.x - 0.25) (position.y - 0.25) position.z
        , scale = Vec3.vec3 0.5 0.5 bodyHeight
        }
    , head =
        { mesh = sphereMesh
        , offset = Vec3.vec3 position.x position.y (position.z + bodyHeight + 0.15)
        , scale = Vec3.vec3 0.18 0.18 0.18
        }
    }


{-| Chasers are a single big icy snowball, throwers a snowman in a black hat, and jumpers a smaller
snowman in a red hat.
-}
npcParts : NpcKind -> Point -> List ( Part, Color )
npcParts kind position =
    case kind of
        TetrominoSim.Chaser ->
            [ ( { mesh = sphereMesh
                , offset = Vec3.vec3 position.x position.y (position.z + 0.36)
                , scale = Vec3.vec3 0.36 0.36 0.36
                }
              , Color.rgb 0.72 0.86 1
              )
            ]

        TetrominoSim.Thrower ->
            [ ( { mesh = sphereMesh
                , offset = Vec3.vec3 position.x position.y (position.z + 0.27)
                , scale = Vec3.vec3 0.27 0.27 0.27
                }
              , snowWhite
              )
            , ( { mesh = sphereMesh
                , offset = Vec3.vec3 position.x position.y (position.z + 0.62)
                , scale = Vec3.vec3 0.18 0.18 0.18
                }
              , snowWhite
              )
            , ( { mesh = cubeMesh
                , offset = Vec3.vec3 (position.x - 0.13) (position.y - 0.13) (position.z + 0.74)
                , scale = Vec3.vec3 0.26 0.26 0.16
                }
              , Color.rgb 0.15 0.15 0.18
              )
            ]

        TetrominoSim.Jumper ->
            [ ( { mesh = sphereMesh
                , offset = Vec3.vec3 position.x position.y (position.z + 0.2)
                , scale = Vec3.vec3 0.2 0.2 0.2
                }
              , snowWhite
              )
            , ( { mesh = sphereMesh
                , offset = Vec3.vec3 position.x position.y (position.z + 0.46)
                , scale = Vec3.vec3 0.13 0.13 0.13
                }
              , snowWhite
              )
            , ( { mesh = cubeMesh
                , offset = Vec3.vec3 (position.x - 0.1) (position.y - 0.1) (position.z + 0.55)
                , scale = Vec3.vec3 0.2 0.2 0.14
                }
              , Color.rgb 0.85 0.15 0.12
              )
            ]


playerSilhouetteColor : Color
playerSilhouetteColor =
    Color.rgb 0.6 1 0.6


npcSilhouetteColor : Color
npcSilhouetteColor =
    Color.rgb 1 0.6 0.6


snowWhite : Color
snowWhite =
    Color.rgb 0.95 0.97 1


mix : Color -> Color -> Float -> Color
mix from to amount =
    let
        a : { red : Float, green : Float, blue : Float, alpha : Float }
        a =
            Color.toRgba from

        b : { red : Float, green : Float, blue : Float, alpha : Float }
        b =
            Color.toRgba to
    in
    Color.rgb
        (a.red + (b.red - a.red) * amount)
        (a.green + (b.green - a.green) * amount)
        (a.blue + (b.blue - a.blue) * amount)


colorToVec3 : Color -> Vec3
colorToVec3 color =
    let
        { red, green, blue } =
            Color.toRgba color
    in
    Vec3.vec3 red green blue


groundEntity : Mat4 -> Entity
groundEntity vp =
    WebGL.entity
        groundVertexShader
        groundFragmentShader
        groundMesh
        { viewProjection = vp }


cubeEntity : Mat4 -> Vec3 -> Color -> Entity
cubeEntity vp offset color =
    WebGL.entity
        vertexShader
        fragmentShader
        cubeMesh
        { viewProjection = vp
        , offset = offset
        , scale = Vec3.vec3 1 1 1
        , color = colorToVec3 color
        , alpha = 1
        , edge = 1
        }


partEntity : Mat4 -> Color -> Part -> Entity
partEntity vp color part =
    WebGL.entity
        vertexShader
        fragmentShader
        part.mesh
        { viewProjection = vp
        , offset = part.offset
        , scale = part.scale
        , color = colorToVec3 color
        , alpha = 1
        , edge = 0
        }


{-| The part of a model that's hidden behind something already drawn, in a flat colour on every
other pixel.
-}
silhouetteEntity : Mat4 -> Color -> Part -> Entity
silhouetteEntity vp color part =
    WebGL.entityWith
        [ Effect.WebGL.Settings.DepthTest.greater { write = False, near = 0, far = 1 } ]
        vertexShader
        silhouetteFragmentShader
        part.mesh
        { viewProjection = vp
        , offset = part.offset
        , scale = part.scale
        , color = colorToVec3 color
        , alpha = 1
        , edge = 0
        }


sphereEntity : Mat4 -> Point -> Float -> Color -> Entity
sphereEntity vp position radius color =
    WebGL.entity
        vertexShader
        fragmentShader
        sphereMesh
        { viewProjection = vp
        , offset = Vec3.vec3 position.x position.y position.z
        , scale = Vec3.vec3 radius radius radius
        , color = colorToVec3 color
        , alpha = 1
        , edge = 0
        }


ditheredCube : Mat4 -> Vec3 -> Color -> Entity
ditheredCube vp offset color =
    WebGL.entityWith
        ditheredSettings
        vertexShader
        ditheredFragmentShader
        cubeMesh
        { viewProjection = vp
        , offset = offset
        , scale = Vec3.vec3 1 1 1
        , color = colorToVec3 color
        , alpha = 1
        , edge = 1
        }


flatSquare : Mat4 -> Float -> Float -> Float -> Float -> Vec3 -> Float -> Entity
flatSquare vp x y z size color alpha =
    WebGL.entityWith
        ditheredSettings
        vertexShader
        ditheredFragmentShader
        squareMesh
        { viewProjection = vp
        , offset = Vec3.vec3 x y (z + 0.01)
        , scale = Vec3.vec3 size size 1
        , color = color
        , alpha = alpha
        , edge = 0
        }


{-| See-through things draw every other pixel and write depth like anything solid, so it doesn't
matter what order they're drawn in, and two shadows on the same spot don't darken it twice.
-}
ditheredSettings : List Effect.WebGL.Settings.Setting
ditheredSettings =
    [ Blend.add Blend.srcAlpha Blend.oneMinusSrcAlpha
    , Effect.WebGL.Settings.DepthTest.less { write = True, near = 0, far = 1 }
    ]



-- Meshes


cubeMesh : Mesh Vertex
cubeMesh =
    let
        face : Vec3 -> Vec3 -> Vec3 -> Vec3 -> List ( Vertex, Vertex, Vertex )
        face normal origin u v =
            let
                vertex : Float -> Float -> Vertex
                vertex a b =
                    { position = Vec3.add origin (Vec3.add (Vec3.scale a u) (Vec3.scale b v))
                    , normal = normal
                    , uv = Vec2.vec2 a b
                    }
            in
            [ ( vertex 0 0, vertex 1 0, vertex 1 1 ), ( vertex 0 0, vertex 1 1, vertex 0 1 ) ]
    in
    face (Vec3.vec3 0 0 1) (Vec3.vec3 0 0 1) (Vec3.vec3 1 0 0) (Vec3.vec3 0 1 0)
        ++ face (Vec3.vec3 0 0 -1) (Vec3.vec3 0 0 0) (Vec3.vec3 0 1 0) (Vec3.vec3 1 0 0)
        ++ face (Vec3.vec3 -1 0 0) (Vec3.vec3 0 0 0) (Vec3.vec3 0 0 1) (Vec3.vec3 0 1 0)
        ++ face (Vec3.vec3 1 0 0) (Vec3.vec3 1 0 0) (Vec3.vec3 0 1 0) (Vec3.vec3 0 0 1)
        ++ face (Vec3.vec3 0 -1 0) (Vec3.vec3 0 0 0) (Vec3.vec3 1 0 0) (Vec3.vec3 0 0 1)
        ++ face (Vec3.vec3 0 1 0) (Vec3.vec3 0 1 0) (Vec3.vec3 0 0 1) (Vec3.vec3 1 0 0)
        |> WebGL.triangles


{-| A gem standing in the unit cube: narrow at the bottom, widest a third of the way up, and coming
to a point at the top, with a flat normal for each face.
-}
crystalMesh : Mesh Vertex
crystalMesh =
    let
        top : Vec3
        top =
            Vec3.vec3 0.5 0.5 1

        corners : List ( Float, Float )
        corners =
            [ ( 0.15, 0.15 ), ( 0.85, 0.15 ), ( 0.85, 0.85 ), ( 0.15, 0.85 ) ]

        face : Vec3 -> Vec3 -> Vec3 -> ( Vertex, Vertex, Vertex )
        face a b c =
            let
                normal : Vec3
                normal =
                    Vec3.cross (Vec3.sub b a) (Vec3.sub c a) |> Vec3.normalize

                vertex : Vec3 -> Vertex
                vertex position =
                    { position = position, normal = normal, uv = Vec2.vec2 0.5 0.5 }
            in
            ( vertex a, vertex b, vertex c )

        inset : Float -> Float
        inset a =
            0.5 + (a - 0.5) * 0.4
    in
    List.map2
        (\( x, y ) ( nextX, nextY ) ->
            let
                bottom : Vec3
                bottom =
                    Vec3.vec3 (inset x) (inset y) 0

                nextBottom : Vec3
                nextBottom =
                    Vec3.vec3 (inset nextX) (inset nextY) 0

                middle : Vec3
                middle =
                    Vec3.vec3 x y 0.35

                nextMiddle : Vec3
                nextMiddle =
                    Vec3.vec3 nextX nextY 0.35
            in
            [ face bottom nextBottom nextMiddle, face bottom nextMiddle middle, face middle nextMiddle top ]
        )
        corners
        (List.drop 1 corners ++ List.take 1 corners)
        |> List.concat
        |> WebGL.triangles


squareMesh : Mesh Vertex
squareMesh =
    let
        vertex : Float -> Float -> Vertex
        vertex a b =
            { position = Vec3.vec3 a b 0, normal = Vec3.vec3 0 0 1, uv = Vec2.vec2 a b }
    in
    WebGL.triangles [ ( vertex 0 0, vertex 1 0, vertex 1 1 ), ( vertex 0 0, vertex 1 1, vertex 0 1 ) ]


sphereMesh : Mesh Vertex
sphereMesh =
    let
        rings : Int
        rings =
            6

        segments : Int
        segments =
            10

        point : Int -> Int -> Vertex
        point ring segment =
            let
                theta : Float
                theta =
                    pi * toFloat ring / toFloat rings

                phi : Float
                phi =
                    2 * pi * toFloat segment / toFloat segments

                normal : Vec3
                normal =
                    Vec3.vec3 (sin theta * cos phi) (sin theta * sin phi) (cos theta)
            in
            { position = normal, normal = normal, uv = Vec2.vec2 0.5 0.5 }
    in
    List.range 0 (rings - 1)
        |> List.concatMap
            (\ring ->
                List.range 0 (segments - 1)
                    |> List.concatMap
                        (\segment ->
                            [ ( point ring segment, point (ring + 1) segment, point (ring + 1) (segment + 1) )
                            , ( point ring segment, point (ring + 1) (segment + 1), point ring (segment + 1) )
                            ]
                        )
            )
        |> WebGL.triangles


groundMesh : Mesh { position : Vec3 }
groundMesh =
    let
        size : Float
        size =
            toFloat TetrominoSim.gridSize
    in
    WebGL.triangles
        [ ( { position = Vec3.vec3 0 0 0 }, { position = Vec3.vec3 size 0 0 }, { position = Vec3.vec3 size size 0 } )
        , ( { position = Vec3.vec3 0 0 0 }, { position = Vec3.vec3 size size 0 }, { position = Vec3.vec3 0 size 0 } )
        , ( { position = Vec3.vec3 0 0 0 }, { position = Vec3.vec3 0 size 0 }, { position = Vec3.vec3 0 size -0.6 } )
        , ( { position = Vec3.vec3 0 0 0 }, { position = Vec3.vec3 0 size -0.6 }, { position = Vec3.vec3 0 0 -0.6 } )
        , ( { position = Vec3.vec3 0 0 0 }, { position = Vec3.vec3 size 0 -0.6 }, { position = Vec3.vec3 size 0 0 } )
        , ( { position = Vec3.vec3 0 0 0 }, { position = Vec3.vec3 0 0 -0.6 }, { position = Vec3.vec3 size 0 -0.6 } )
        ]



-- Shaders


vertexShader : Shader Vertex Uniforms Varyings
vertexShader =
    [glsl|
attribute vec3 position;
attribute vec3 normal;
attribute vec2 uv;
uniform mat4 viewProjection;
uniform vec3 offset;
uniform vec3 scale;
varying vec3 vNormal;
varying vec2 vUv;

void main () {
    gl_Position = viewProjection * vec4(position * scale + offset, 1.0);
    vNormal = normal;
    vUv = uv;
}
|]


fragmentShader : Shader {} Uniforms Varyings
fragmentShader =
    [glsl|
precision mediump float;
uniform vec3 color;
uniform float alpha;
uniform float edge;
varying vec3 vNormal;
varying vec2 vUv;

void main () {
    vec3 light = normalize(vec3(-0.2, -0.35, 1.0));
    float shade = 0.5 + 0.5 * max(0.0, dot(normalize(vNormal), light));
    float distanceToEdge = min(min(vUv.x, 1.0 - vUv.x), min(vUv.y, 1.0 - vUv.y));
    float outline = edge * (1.0 - smoothstep(0.03, 0.06, distanceToEdge));
    gl_FragColor = vec4(color * shade * (1.0 - 0.35 * outline), alpha);
}
|]


ditheredFragmentShader : Shader {} Uniforms Varyings
ditheredFragmentShader =
    [glsl|
precision mediump float;
uniform vec3 color;
uniform float alpha;
uniform float edge;
varying vec3 vNormal;
varying vec2 vUv;

void main () {
    if (mod(floor(gl_FragCoord.x) + floor(gl_FragCoord.y), 2.0) > 0.5) {
        discard;
    }
    vec3 light = normalize(vec3(-0.2, -0.35, 1.0));
    float shade = 0.5 + 0.5 * max(0.0, dot(normalize(vNormal), light));
    float distanceToEdge = min(min(vUv.x, 1.0 - vUv.x), min(vUv.y, 1.0 - vUv.y));
    float outline = edge * (1.0 - smoothstep(0.03, 0.06, distanceToEdge));
    gl_FragColor = vec4(color * shade * (1.0 - 0.35 * outline), alpha);
}
|]


ditheredDiscFragmentShader : Shader {} Uniforms Varyings
ditheredDiscFragmentShader =
    [glsl|
precision mediump float;
uniform vec3 color;
uniform float alpha;
varying vec3 vNormal;
varying vec2 vUv;

void main () {
    if (mod(floor(gl_FragCoord.x) + floor(gl_FragCoord.y), 2.0) > 0.5) {
        discard;
    }
    float distanceFromCenter = length(vUv - vec2(0.5, 0.5));
    if (distanceFromCenter > 0.5) {
        discard;
    }
    gl_FragColor = vec4(color, alpha);
}
|]


ringFragmentShader : Shader {} Uniforms Varyings
ringFragmentShader =
    [glsl|
precision mediump float;
uniform vec3 color;
varying vec3 vNormal;
varying vec2 vUv;

void main () {
    float distanceFromCenter = length(vUv - vec2(0.5, 0.5));
    if (distanceFromCenter > 0.5 || distanceFromCenter < 0.36) {
        discard;
    }
    gl_FragColor = vec4(color, 1.0);
}
|]


{-| Uses the other half of the checkerboard from the see-through things, so a silhouette behind a
shadow or the ghost piece still shows.
-}
silhouetteFragmentShader : Shader {} Uniforms Varyings
silhouetteFragmentShader =
    [glsl|
precision mediump float;
uniform vec3 color;
varying vec3 vNormal;
varying vec2 vUv;

void main () {
    if (mod(floor(gl_FragCoord.x) + floor(gl_FragCoord.y), 2.0) < 0.5) {
        discard;
    }
    gl_FragColor = vec4(color, 1.0);
}
|]


groundVertexShader : Shader { position : Vec3 } { viewProjection : Mat4 } { worldPosition : Vec3 }
groundVertexShader =
    [glsl|
attribute vec3 position;
uniform mat4 viewProjection;
varying vec3 worldPosition;

void main () {
    gl_Position = viewProjection * vec4(position, 1.0);
    worldPosition = position;
}
|]


groundFragmentShader : Shader {} { viewProjection : Mat4 } { worldPosition : Vec3 }
groundFragmentShader =
    [glsl|
precision mediump float;
varying vec3 worldPosition;

void main () {
    if (worldPosition.z < -0.01) {
        gl_FragColor = vec4(0.62, 0.68, 0.78, 1.0);
    } else {
        float checker = mod(floor(worldPosition.x) + floor(worldPosition.y), 2.0);
        vec3 color = mix(vec3(0.93, 0.95, 0.99), vec3(0.86, 0.90, 0.97), checker);
        gl_FragColor = vec4(color, 1.0);
    }
}
|]
