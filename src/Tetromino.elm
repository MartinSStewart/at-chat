module Tetromino exposing
    ( Orientation
    , Shape(..)
    , Stance(..)
    , all
    , allOrientations
    , cells
    , identity
    , isValidOrientation
    , orientation
    )

{-| The seven pieces and the 24 ways a piece can be turned, all on whole grid cells.
-}


type Shape
    = I
    | O
    | T
    | S
    | Z
    | J
    | L


all : List Shape
all =
    [ I, O, T, S, Z, J, L ]


{-| A rotation of the grid, written as the matrix that maps a cell to its rotated position.
Only the 24 rotations of a cube can be built, starting from `identity`.
-}
type alias Orientation =
    { xx : Int
    , xy : Int
    , xz : Int
    , yx : Int
    , yy : Int
    , yz : Int
    , zx : Int
    , zy : Int
    , zz : Int
    }


identity : Orientation
identity =
    { xx = 1, xy = 0, xz = 0, yx = 0, yy = 1, yz = 0, zx = 0, zy = 0, zz = 1 }


aroundZ : Orientation
aroundZ =
    { xx = 0, xy = -1, xz = 0, yx = 1, yy = 0, yz = 0, zx = 0, zy = 0, zz = 1 }


aroundY : Orientation
aroundY =
    { xx = 0, xy = 0, xz = 1, yx = 0, yy = 1, yz = 0, zx = -1, zy = 0, zz = 0 }


multiply : Orientation -> Orientation -> Orientation
multiply a b =
    { xx = a.xx * b.xx + a.xy * b.yx + a.xz * b.zx
    , xy = a.xx * b.xy + a.xy * b.yy + a.xz * b.zy
    , xz = a.xx * b.xz + a.xy * b.yz + a.xz * b.zz
    , yx = a.yx * b.xx + a.yy * b.yx + a.yz * b.zx
    , yy = a.yx * b.xy + a.yy * b.yy + a.yz * b.zy
    , yz = a.yx * b.xz + a.yy * b.yz + a.yz * b.zz
    , zx = a.zx * b.xx + a.zy * b.yx + a.zz * b.zx
    , zy = a.zx * b.xy + a.zy * b.yy + a.zz * b.zy
    , zz = a.zx * b.xz + a.zy * b.yz + a.zz * b.zz
    }


{-| Whether a piece is dropped lying down, or stood on end with its long side upright.
-}
type Stance
    = Flat
    | Upright


{-| A piece in the given stance, then turned some number of quarter turns about the vertical axis.
-}
orientation : Stance -> Int -> Orientation
orientation stance quarterTurns =
    let
        stood : Orientation
        stood =
            case stance of
                Flat ->
                    identity

                Upright ->
                    aroundY
    in
    List.foldl (\_ turned -> rotateAroundZ turned) stood (List.range 1 (modBy 4 quarterTurns))


rotateAroundZ : Orientation -> Orientation
rotateAroundZ turned =
    multiply aroundZ turned


rotateAroundY : Orientation -> Orientation
rotateAroundY turned =
    multiply aroundY turned


allOrientations : List Orientation
allOrientations =
    allOrientationsHelper [ identity ] [ identity ]


allOrientationsHelper : List Orientation -> List Orientation -> List Orientation
allOrientationsHelper found toVisit =
    case toVisit of
        turned :: rest ->
            let
                next : List Orientation
                next =
                    List.filter
                        (\candidate -> not (List.member candidate found))
                        [ rotateAroundZ turned, rotateAroundY turned ]
            in
            allOrientationsHelper (found ++ next) (rest ++ next)

        [] ->
            found


isValidOrientation : Orientation -> Bool
isValidOrientation turned =
    List.member turned allOrientations


baseCells : Shape -> List ( Int, Int, Int )
baseCells shape =
    case shape of
        I ->
            [ ( 0, 0, 0 ), ( 1, 0, 0 ), ( 2, 0, 0 ), ( 3, 0, 0 ) ]

        O ->
            [ ( 0, 0, 0 ), ( 1, 0, 0 ), ( 0, 1, 0 ), ( 1, 1, 0 ) ]

        T ->
            [ ( 0, 0, 0 ), ( 1, 0, 0 ), ( 2, 0, 0 ), ( 1, 1, 0 ) ]

        S ->
            [ ( 1, 0, 0 ), ( 2, 0, 0 ), ( 0, 1, 0 ), ( 1, 1, 0 ) ]

        Z ->
            [ ( 0, 0, 0 ), ( 1, 0, 0 ), ( 1, 1, 0 ), ( 2, 1, 0 ) ]

        J ->
            [ ( 0, 0, 0 ), ( 0, 1, 0 ), ( 1, 1, 0 ), ( 2, 1, 0 ) ]

        L ->
            [ ( 2, 0, 0 ), ( 0, 1, 0 ), ( 1, 1, 0 ), ( 2, 1, 0 ) ]


{-| The cells a piece covers once turned. The lowest cells sit at z = 0 and the middle of the
piece (rounded down) is over x = 0, y = 0, so that a piece dropped on a cell lands centred on it.
-}
cells : Orientation -> Shape -> List ( Int, Int, Int )
cells o shape =
    let
        rotated : List ( Int, Int, Int )
        rotated =
            List.map
                (\( x, y, z ) ->
                    ( o.xx * x + o.xy * y + o.xz * z
                    , o.yx * x + o.yy * y + o.yz * z
                    , o.zx * x + o.zy * y + o.zz * z
                    )
                )
                (baseCells shape)

        minMax : (( Int, Int, Int ) -> Int) -> ( Int, Int )
        minMax getter =
            List.foldl
                (\cell ( low, high ) -> ( min low (getter cell), max high (getter cell) ))
                ( 999, -999 )
                rotated

        ( minX, maxX ) =
            minMax (\( x, _, _ ) -> x)

        ( minY, maxY ) =
            minMax (\( _, y, _ ) -> y)

        ( minZ, _ ) =
            minMax (\( _, _, z ) -> z)

        offsetX : Int
        offsetX =
            minX + (maxX - minX) // 2

        offsetY : Int
        offsetY =
            minY + (maxY - minY) // 2
    in
    List.map (\( x, y, z ) -> ( x - offsetX, y - offsetY, z - minZ )) rotated
