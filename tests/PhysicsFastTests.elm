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


body : Float -> Float -> Float -> Float -> Float -> Body
body x y vx vy radius =
    { x = x
    , y = y
    , vx = vx
    , vy = vy
    , radius = radius
    , mass = max radius 1.0e-6 ^ 2
    }


tests : Test
tests =
    Test.describe "PhysicsFast.simulate"
        [ Test.test "an empty world stays empty" <|
            \_ ->
                PhysicsFast.simulate 100 (Duration.milliseconds 100) []
                    |> Expect.equal []
        , Test.test "a lone body at rest does not move" <|
            \_ ->
                let
                    b : Body
                    b =
                        body 50 50 0 0 1
                in
                PhysicsFast.simulate 100 (Duration.milliseconds 100) [ b ]
                    |> Expect.equal [ b ]
        , Test.test "zero steps is a no-op" <|
            \_ ->
                let
                    world : List Body
                    world =
                        [ body 49.5 50 0 0 1, body 50.5 50 0 0 1 ]
                in
                PhysicsFast.simulate 0 (Duration.milliseconds 100) world
                    |> Expect.equal world
        , Test.test "a body bounces off the wall and stays inside the box" <|
            \_ ->
                case PhysicsFast.simulate 2000 (Duration.milliseconds 200) [ body 80 50 200 0 1 ] of
                    [ bounced ] ->
                        Expect.all
                            [ \_ -> insideBounds bounced |> Expect.equal True
                            , \_ -> bounced.vx |> Expect.lessThan 0
                            ]
                            ()

                    _ ->
                        Expect.fail "expected exactly one body back"
        , Test.test "two overlapping bodies are pushed apart" <|
            \_ ->
                case PhysicsFast.simulate 1000 (Duration.milliseconds 50) [ body 49.5 50 0 0 1, body 50.5 50 0 0 1 ] of
                    [ a, b ] ->
                        overlap a b |> Expect.atMost 1.0e-2

                    _ ->
                        Expect.fail "expected exactly two bodies back"
        , Test.test "Physics and PhysicsFast produce bitwise identical results" <|
            \_ ->
                let
                    world : List Body
                    world =
                        [ body 49.5 50 0 0 1
                        , body 50.5 50 0 0 1
                        , body 80 60 200 -100 1
                        , body 20 30 100 200 2
                        ]
                in
                PhysicsFast.simulate 1000 (Duration.milliseconds 50) world
                    |> Expect.equal (Physics.simulate 1000 (Duration.milliseconds 50) world)
        ]
