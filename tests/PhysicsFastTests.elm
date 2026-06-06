module PhysicsFastTests exposing (tests)

import Duration
import Expect
import Physics
import PhysicsFast exposing (Body)
import Test exposing (Test)


distance : Body -> Body -> Float
distance a b =
    sqrt ((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2)


overlap : Body -> Body -> Float
overlap a b =
    a.radius + b.radius - distance a b


insideBounds : Body -> Bool
insideBounds c =
    (c.x - c.radius >= PhysicsFast.bounds.min - 1.0e-6)
        && (c.x + c.radius <= PhysicsFast.bounds.max + 1.0e-6)
        && (c.y - c.radius >= PhysicsFast.bounds.min - 1.0e-6)
        && (c.y + c.radius <= PhysicsFast.bounds.max + 1.0e-6)


{-| Build a Body with the same mass formula `Physics` uses internally, so a
shared input list compares fairly against both modules.
-}
body : Float -> Float -> Float -> Float -> Float -> Body
body x y vx vy radius =
    { x = x
    , y = y
    , vx = vx
    , vy = vy
    , radius = radius
    , mass = max radius 1.0e-6 ^ 2
    }


{-| Project a Body down to the Circle shape `Physics` uses, for cross-module
comparison.
-}
toCircle : Body -> Physics.Circle
toCircle b =
    { x = b.x, y = b.y, vx = b.vx, vy = b.vy, radius = b.radius }


tests : Test
tests =
    Test.describe "PhysicsFast.simulate"
        [ Test.test "an empty world stays empty" <|
            \_ ->
                PhysicsFast.simulate 100 (Duration.seconds 1) []
                    |> Expect.equal []
        , Test.test "a lone body at rest does not move" <|
            \_ ->
                let
                    b : Body
                    b =
                        body 3 -2 0 0 1
                in
                PhysicsFast.simulate 100 (Duration.seconds 1) [ b ]
                    |> Expect.equal [ b ]
        , Test.test "zero steps is a no-op" <|
            \_ ->
                let
                    world : List Body
                    world =
                        [ body -0.5 0 0 0 1, body 0.5 0 0 0 1 ]
                in
                PhysicsFast.simulate 0 (Duration.seconds 1) world
                    |> Expect.equal world
        , Test.test "a moving body travels in its direction of motion" <|
            \_ ->
                case PhysicsFast.simulate 100 (Duration.seconds 1) [ body 0 0 5 0 1 ] of
                    [ moved ] ->
                        Expect.all
                            [ \_ -> moved.x |> Expect.greaterThan 0.5
                            , \_ -> moved.y |> Expect.within (Expect.Absolute 1.0e-9) 0
                            , \_ -> insideBounds moved |> Expect.equal True
                            ]
                            ()

                    _ ->
                        Expect.fail "expected exactly one body back"
        , Test.test "a body bounces off the wall and stays inside the box" <|
            \_ ->
                case PhysicsFast.simulate 200 (Duration.seconds 2) [ body 8 0 5 0 1 ] of
                    [ bounced ] ->
                        Expect.all
                            [ \_ -> insideBounds bounced |> Expect.equal True
                            , \_ -> bounced.vx |> Expect.lessThan 0
                            ]
                            ()

                    _ ->
                        Expect.fail "expected exactly one body back"
        , Test.test "bodies never escape the bounding box" <|
            \_ ->
                let
                    world : List Body
                    world =
                        [ body 9 9 8 8 1
                        , body -9 9 -8 8 1
                        , body 0 -9 0 -8 2
                        ]
                in
                PhysicsFast.simulate 400 (Duration.seconds 4) world
                    |> List.all insideBounds
                    |> Expect.equal True
        , Test.test "two overlapping bodies are pushed apart" <|
            \_ ->
                case PhysicsFast.simulate 480 (Duration.seconds 4) [ body -0.5 0 0 0 1, body 0.5 0 0 0 1 ] of
                    [ a, b ] ->
                        overlap a b |> Expect.atMost 1.0e-2

                    _ ->
                        Expect.fail "expected exactly two bodies back"
        , Test.test "equal mass collision conserves the center of mass" <|
            \_ ->
                case PhysicsFast.simulate 480 (Duration.seconds 4) [ body -0.5 0 0 0 1, body 0.5 0 0 0 1 ] of
                    [ a, b ] ->
                        Expect.all
                            [ \_ -> (a.x + b.x) / 2 |> Expect.within (Expect.Absolute 1.0e-9) 0
                            , \_ -> (a.y + b.y) / 2 |> Expect.within (Expect.Absolute 1.0e-9) 0
                            ]
                            ()

                    _ ->
                        Expect.fail "expected exactly two bodies back"
        , Test.test "a pile of three overlapping bodies fully separates" <|
            \_ ->
                case PhysicsFast.simulate 600 (Duration.seconds 5) [ body 0 0 0 0 1, body 1 0 0 0 1, body 2 0 0 0 1 ] of
                    [ a, b, c ] ->
                        Expect.all
                            [ \_ -> overlap a b |> Expect.atMost 1.0e-2
                            , \_ -> overlap b c |> Expect.atMost 1.0e-2
                            , \_ -> overlap a c |> Expect.atMost 1.0e-2
                            ]
                            ()

                    _ ->
                        Expect.fail "expected exactly three bodies back"
        , Test.test "Physics and PhysicsFast produce bitwise identical results" <|
            \_ ->
                let
                    bodies : List Body
                    bodies =
                        [ body -0.5 0 0 0 1
                        , body 0.5 0 0 0 1
                        , body 8 3 4 -2 1
                        , body -3 -3 1 5 2
                        ]

                    steps : Int
                    steps =
                        300

                    duration : Duration.Duration
                    duration =
                        Duration.seconds 3

                    fromFast : List Physics.Circle
                    fromFast =
                        PhysicsFast.simulate steps duration bodies |> List.map toCircle

                    fromOld : List Physics.Circle
                    fromOld =
                        Physics.simulate steps duration (List.map toCircle bodies)
                in
                fromFast |> Expect.equal fromOld
        ]
