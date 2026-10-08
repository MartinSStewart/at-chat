module TetrominoView exposing
    ( Cursor
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
import TetrominoSim exposing (MatchState, Npc, Piece, PieceStatus(..), Player, Point)


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


{-| Looking down from the corner nearest x = 0, y = 0 at the classic isometric angle, and
zoomed out just far enough for the whole grid to fit.
-}
viewProjection : Int -> Int -> Mat4
viewProjection width height =
    let
        center : Float
        center =
            toFloat TetrominoSim.gridSize / 2

        aspect : Float
        aspect =
            toFloat (max 1 width) / toFloat (max 1 height)

        halfWidth : Float
        halfWidth =
            max (toFloat TetrominoSim.gridSize * 0.75) (toFloat TetrominoSim.gridSize * 0.5 * aspect)

        halfHeight : Float
        halfHeight =
            halfWidth / aspect
    in
    Mat4.mul
        (Mat4.makeOrtho -halfWidth halfWidth -halfHeight halfHeight -200 200)
        (Mat4.makeLookAt
            (Vec3.vec3 (center - 50) (center - 50) 50)
            (Vec3.vec3 center center 1)
            (Vec3.vec3 0 0 1)
        )


{-| Which column is under a point on the canvas, given in CSS pixels from its top left corner.
-}
screenToCell : Int -> Int -> { x : Float, y : Float } -> MatchState -> Maybe Cursor
screenToCell width height screenPosition state =
    case Mat4.inverse (viewProjection width height) of
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

                start : Vec3
                start =
                    Vec3.add near (Vec3.scale ((top - Vec3.getZ near) / Vec3.getZ direction) direction)
            in
            castRay state.occupied (Vec3.scale 0.02 direction) start 4000

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
    , frame : Int
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
            viewProjection config.width config.height

        columns : Columns
        columns =
            toColumns state.occupied

        alivePlayers : List ( Id UserId, Player )
        alivePlayers =
            SeqDict.toList state.players |> List.filter (\( _, player ) -> player.diedAt == Nothing)

        opaque : List Entity
        opaque =
            groundEntity vp
                :: List.concatMap (pieceEntities vp config.userColor) (SeqDict.values state.pieces)
                ++ List.concatMap (\( userId, player ) -> playerEntities vp config.frame (config.userColor userId) player) alivePlayers
                ++ List.concatMap (npcEntities vp) state.npcs
                ++ List.map
                    (\snowball -> sphereEntity vp snowball.position TetrominoSim.snowballRadius snowWhite)
                    state.snowballs

        shadows : List Entity
        shadows =
            List.concatMap (fallingPieceShadows vp columns) (SeqDict.values state.pieces)
                ++ List.map
                    (\( _, player ) -> discShadow vp columns player.position (TetrominoSim.entityRadius * 2))
                    alivePlayers
                ++ List.map (\npc -> discShadow vp columns npc.position (TetrominoSim.entityRadius * 2)) state.npcs
                ++ List.map
                    (\snowball -> discShadow vp columns snowball.position (TetrominoSim.snowballRadius * 2))
                    state.snowballs

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
                                    config.userColor config.currentUserId
                            in
                            List.map
                                (\( x, y, z ) ->
                                    translucentCube
                                        vp
                                        (Vec3.vec3 (toFloat (x0 + x)) (toFloat (y0 + y)) (toFloat (level + z)))
                                        color
                                        0.35
                                )
                                cells

                        Nothing ->
                            [ flatSquare vp (toFloat cursor.x) (toFloat cursor.y) (toFloat cursor.z) 1 (Vec3.vec3 1 1 1) 0.35 ]

                Nothing ->
                    []
    in
    opaque ++ shadows ++ overlays


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
            userColor piece.owner
    in
    List.map
        (\( x, y, z ) ->
            cubeEntity vp (Vec3.vec3 (toFloat (piece.x + x)) (toFloat (piece.y + y)) (piece.z + toFloat z)) color
        )
        piece.cells


fallingPieceShadows : Mat4 -> Columns -> Piece -> List Entity
fallingPieceShadows vp columns piece =
    case piece.status of
        Falling _ ->
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
                piece.cells
                |> Dict.toList
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
                            0.3
                    )

        Settled ->
            []


discShadow : Mat4 -> Columns -> Point -> Float -> Entity
discShadow vp columns position size =
    WebGL.entityWith
        translucentSettings
        vertexShader
        discFragmentShader
        squareMesh
        { viewProjection = vp
        , offset =
            Vec3.vec3
                (position.x - size / 2)
                (position.y - size / 2)
                (toFloat (surfaceBelow columns (floor position.x) (floor position.y) (position.z + 0.01)) + 0.01)
        , scale = Vec3.vec3 size size 1
        , color = Vec3.vec3 0 0 0
        , alpha = 0.3
        , edge = 0
        }


playerEntities : Mat4 -> Int -> Color -> Player -> List Entity
playerEntities vp frame color player =
    let
        color2 : Color
        color2 =
            case player.hitAt of
                Just hitAt ->
                    if frame - hitAt < 12 then
                        Color.rgb 1 1 1

                    else
                        color

                Nothing ->
                    color

        position : Point
        position =
            player.position

        bodyHeight : Float
        bodyHeight =
            TetrominoSim.entityHeight - 0.3
    in
    [ boxEntity
        vp
        (Vec3.vec3 (position.x - 0.25) (position.y - 0.25) position.z)
        (Vec3.vec3 0.5 0.5 bodyHeight)
        color2
    , sphereEntity vp { position | z = position.z + bodyHeight + 0.15 } 0.18 color2
    ]


npcEntities : Mat4 -> Npc -> List Entity
npcEntities vp npc =
    let
        position : Point
        position =
            npc.position
    in
    [ sphereEntity vp { position | z = position.z + 0.27 } 0.27 snowWhite
    , sphereEntity vp { position | z = position.z + 0.62 } 0.18 snowWhite
    , boxEntity vp (Vec3.vec3 (position.x - 0.13) (position.y - 0.13) (position.z + 0.74)) (Vec3.vec3 0.26 0.26 0.16) (Color.rgb 0.15 0.15 0.18)
    ]


snowWhite : Color
snowWhite =
    Color.rgb 0.95 0.97 1


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


boxEntity : Mat4 -> Vec3 -> Vec3 -> Color -> Entity
boxEntity vp offset scale color =
    WebGL.entity
        vertexShader
        fragmentShader
        cubeMesh
        { viewProjection = vp
        , offset = offset
        , scale = scale
        , color = colorToVec3 color
        , alpha = 1
        , edge = 0
        }


translucentCube : Mat4 -> Vec3 -> Color -> Float -> Entity
translucentCube vp offset color alpha =
    WebGL.entityWith
        translucentSettings
        vertexShader
        fragmentShader
        cubeMesh
        { viewProjection = vp
        , offset = offset
        , scale = Vec3.vec3 1 1 1
        , color = colorToVec3 color
        , alpha = alpha
        , edge = 1
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


flatSquare : Mat4 -> Float -> Float -> Float -> Float -> Vec3 -> Float -> Entity
flatSquare vp x y z size color alpha =
    WebGL.entityWith
        translucentSettings
        vertexShader
        fragmentShader
        squareMesh
        { viewProjection = vp
        , offset = Vec3.vec3 x y (z + 0.01)
        , scale = Vec3.vec3 size size 1
        , color = color
        , alpha = alpha
        , edge = 0
        }


translucentSettings : List Effect.WebGL.Settings.Setting
translucentSettings =
    [ Blend.add Blend.srcAlpha Blend.oneMinusSrcAlpha
    , Effect.WebGL.Settings.DepthTest.lessOrEqual { write = False, near = 0, far = 1 }
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


discFragmentShader : Shader {} Uniforms Varyings
discFragmentShader =
    [glsl|
precision mediump float;
uniform vec3 color;
uniform float alpha;
varying vec3 vNormal;
varying vec2 vUv;

void main () {
    float distanceFromCenter = length(vUv - vec2(0.5, 0.5));
    if (distanceFromCenter > 0.5) {
        discard;
    }
    gl_FragColor = vec4(color, alpha);
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
