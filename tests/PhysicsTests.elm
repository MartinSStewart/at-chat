module PhysicsTests exposing (tests)

import Duration
import Expect
import Physics exposing (Circle)
import Test exposing (Test)


distance : Circle -> Circle -> Float
distance a b =
    sqrt ((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2)


{-| How much two circles overlap. Negative means a gap between them.
-}
overlap : Circle -> Circle -> Float
overlap a b =
    a.radius + b.radius - distance a b


{-| Whether a circle lies fully inside the bounding box (with a tiny tolerance
for floating point error).
-}
insideBounds : Circle -> Bool
insideBounds c =
    (c.x - c.radius >= Physics.bounds.min - 1.0e-6)
        && (c.x + c.radius <= Physics.bounds.max + 1.0e-6)
        && (c.y - c.radius >= Physics.bounds.min - 1.0e-6)
        && (c.y + c.radius <= Physics.bounds.max + 1.0e-6)


tests : Test
tests =
    Test.describe "Physics.simulate"
        [ Test.test "an empty world stays empty" <|
            \_ ->
                Physics.simulate 100 (Duration.seconds 1) []
                    |> Expect.equal []
        , Test.test "a lone circle at rest does not move" <|
            \_ ->
                let
                    circle : Circle
                    circle =
                        { x = 3, y = -2, vx = 0, vy = 0, radius = 1 }
                in
                Physics.simulate 100 (Duration.seconds 1) [ circle ]
                    |> Expect.equal [ circle ]
        , Test.test "circles at rest that don't touch are left alone" <|
            \_ ->
                let
                    world : List Circle
                    world =
                        [ { x = 0, y = 0, vx = 0, vy = 0, radius = 1 }
                        , { x = 5, y = 0, vx = 0, vy = 0, radius = 1 }
                        ]
                in
                Physics.simulate 100 (Duration.seconds 1) world
                    |> Expect.equal world
        , Test.test "zero steps is a no-op" <|
            \_ ->
                let
                    world : List Circle
                    world =
                        [ { x = -0.5, y = 0, vx = 0, vy = 0, radius = 1 }
                        , { x = 0.5, y = 0, vx = 0, vy = 0, radius = 1 }
                        ]
                in
                Physics.simulate 0 (Duration.seconds 1) world
                    |> Expect.equal world
        , Test.test "a moving circle travels in its direction of motion" <|
            \_ ->
                let
                    circle : Circle
                    circle =
                        { x = 0, y = 0, vx = 5, vy = 0, radius = 1 }
                in
                case Physics.simulate 100 (Duration.seconds 1) [ circle ] of
                    [ moved ] ->
                        Expect.all
                            [ \_ -> moved.x |> Expect.greaterThan 0.5
                            , \_ -> moved.y |> Expect.within (Expect.Absolute 1.0e-9) 0
                            , \_ -> insideBounds moved |> Expect.equal True
                            ]
                            ()

                    _ ->
                        Expect.fail "expected exactly one circle back"
        , Test.test "a circle bounces off the wall and stays inside the box" <|
            \_ ->
                let
                    circle : Circle
                    circle =
                        { x = 8, y = 0, vx = 5, vy = 0, radius = 1 }
                in
                case Physics.simulate 200 (Duration.seconds 2) [ circle ] of
                    [ bounced ] ->
                        Expect.all
                            [ \_ -> insideBounds bounced |> Expect.equal True
                            , \_ -> bounced.vx |> Expect.lessThan 0
                            ]
                            ()

                    _ ->
                        Expect.fail "expected exactly one circle back"
        , Test.test "circles never escape the bounding box" <|
            \_ ->
                let
                    world : List Circle
                    world =
                        [ { x = 9, y = 9, vx = 8, vy = 8, radius = 1 }
                        , { x = -9, y = 9, vx = -8, vy = 8, radius = 1 }
                        , { x = 0, y = -9, vx = 0, vy = -8, radius = 2 }
                        ]
                in
                Physics.simulate 400 (Duration.seconds 4) world
                    |> List.all insideBounds
                    |> Expect.equal True
        , Test.test "two overlapping circles are pushed apart" <|
            \_ ->
                let
                    world : List Circle
                    world =
                        [ { x = -0.5, y = 0, vx = 0, vy = 0, radius = 1 }
                        , { x = 0.5, y = 0, vx = 0, vy = 0, radius = 1 }
                        ]
                in
                case Physics.simulate 480 (Duration.seconds 4) world of
                    [ a, b ] ->
                        overlap a b
                            |> Expect.atMost 1.0e-2

                    _ ->
                        Expect.fail "expected exactly two circles back"
        , Test.test "radii and ordering are preserved" <|
            \_ ->
                let
                    world : List Circle
                    world =
                        [ { x = -0.5, y = 0, vx = 0, vy = 0, radius = 1 }
                        , { x = 0.5, y = 0, vx = 0, vy = 0, radius = 2 }
                        ]
                in
                Physics.simulate 480 (Duration.seconds 4) world
                    |> List.map .radius
                    |> Expect.equal [ 1, 2 ]
        , Test.test "equal mass collision conserves the center of mass" <|
            \_ ->
                let
                    world : List Circle
                    world =
                        [ { x = -0.5, y = 0, vx = 0, vy = 0, radius = 1 }
                        , { x = 0.5, y = 0, vx = 0, vy = 0, radius = 1 }
                        ]
                in
                case Physics.simulate 480 (Duration.seconds 4) world of
                    [ a, b ] ->
                        Expect.all
                            [ \_ -> (a.x + b.x) / 2 |> Expect.within (Expect.Absolute 1.0e-9) 0
                            , \_ -> (a.y + b.y) / 2 |> Expect.within (Expect.Absolute 1.0e-9) 0
                            ]
                            ()

                    _ ->
                        Expect.fail "expected exactly two circles back"
        , Test.test "a pile of three overlapping circles fully separates" <|
            \_ ->
                let
                    world : List Circle
                    world =
                        [ { x = 0, y = 0, vx = 0, vy = 0, radius = 1 }
                        , { x = 1, y = 0, vx = 0, vy = 0, radius = 1 }
                        , { x = 2, y = 0, vx = 0, vy = 0, radius = 1 }
                        ]
                in
                case Physics.simulate 600 (Duration.seconds 5) world of
                    [ a, b, c ] ->
                        Expect.all
                            [ \_ -> overlap a b |> Expect.atMost 1.0e-2
                            , \_ -> overlap b c |> Expect.atMost 1.0e-2
                            , \_ -> overlap a c |> Expect.atMost 1.0e-2
                            ]
                            ()

                    _ ->
                        Expect.fail "expected exactly three circles back"
        ]
