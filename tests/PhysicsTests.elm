module PhysicsTests exposing (tests)

import Duration
import Expect
import Physics exposing (Body)
import Test exposing (Test)


distance : Body -> Body -> Float
distance a b =
    sqrt ((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2)


overlap : Body -> Body -> Float
overlap a b =
    a.radius + b.radius - distance a b


insideBounds : Body -> Bool
insideBounds c =
    (c.x - c.radius >= Physics.bounds.min - 1.0e-6)
        && (c.x + c.radius <= Physics.bounds.max + 1.0e-6)
        && (c.y - c.radius >= Physics.bounds.min - 1.0e-6)
        && (c.y + c.radius <= Physics.bounds.max + 1.0e-6)


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
    Test.describe "Physics.simulate"
        [ Test.test "an empty world stays empty" <|
            \_ ->
                Physics.simulate 100 (Duration.milliseconds 100) []
                    |> Expect.equal []
        , Test.test "a lone body at rest does not move" <|
            \_ ->
                let
                    b : Body
                    b =
                        body 50 50 0 0 1
                in
                Physics.simulate 100 (Duration.milliseconds 100) [ b ]
                    |> Expect.equal [ b ]
        , Test.test "bodies at rest that don't touch are left alone" <|
            \_ ->
                let
                    world : List Body
                    world =
                        [ body 30 50 0 0 1, body 70 50 0 0 1 ]
                in
                Physics.simulate 100 (Duration.milliseconds 100) world
                    |> Expect.equal world
        , Test.test "zero steps is a no-op" <|
            \_ ->
                let
                    world : List Body
                    world =
                        [ body 49.5 50 0 0 1, body 50.5 50 0 0 1 ]
                in
                Physics.simulate 0 (Duration.milliseconds 100) world
                    |> Expect.equal world
        , Test.test "a moving body travels in its direction of motion" <|
            \_ ->
                case Physics.simulate 500 (Duration.milliseconds 50) [ body 50 50 200 0 1 ] of
                    [ moved ] ->
                        Expect.all
                            [ \_ -> moved.x |> Expect.greaterThan 50.5
                            , \_ -> moved.y |> Expect.within (Expect.Absolute 1.0e-9) 50
                            , \_ -> insideBounds moved |> Expect.equal True
                            ]
                            ()

                    _ ->
                        Expect.fail "expected exactly one body back"
        , Test.test "a body bounces off the wall and stays inside the box" <|
            \_ ->
                case Physics.simulate 2000 (Duration.milliseconds 200) [ body 80 50 200 0 1 ] of
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
                        [ body 95 95 200 200 1
                        , body 5 95 -200 200 1
                        , body 50 5 0 -200 2
                        ]
                in
                Physics.simulate 1000 (Duration.milliseconds 100) world
                    |> List.all insideBounds
                    |> Expect.equal True
        , Test.test "two overlapping bodies are pushed apart" <|
            \_ ->
                case Physics.simulate 1000 (Duration.milliseconds 50) [ body 49.5 50 0 0 1, body 50.5 50 0 0 1 ] of
                    [ a, b ] ->
                        overlap a b |> Expect.atMost 1.0e-2

                    _ ->
                        Expect.fail "expected exactly two bodies back"
        , Test.test "radii and ordering are preserved" <|
            \_ ->
                Physics.simulate 1000 (Duration.milliseconds 50) [ body 49.5 50 0 0 1, body 50.5 50 0 0 2 ]
                    |> List.map .radius
                    |> Expect.equal [ 1, 2 ]
        , Test.test "equal mass collision conserves the center of mass" <|
            \_ ->
                case Physics.simulate 1000 (Duration.milliseconds 50) [ body 49.5 50 0 0 1, body 50.5 50 0 0 1 ] of
                    [ a, b ] ->
                        Expect.all
                            [ \_ -> (a.x + b.x) / 2 |> Expect.within (Expect.Absolute 1.0e-9) 50
                            , \_ -> (a.y + b.y) / 2 |> Expect.within (Expect.Absolute 1.0e-9) 50
                            ]
                            ()

                    _ ->
                        Expect.fail "expected exactly two bodies back"
        , Test.test "a pile of three overlapping bodies fully separates" <|
            \_ ->
                case Physics.simulate 500 (Duration.milliseconds 5) [ body 49 50 0 0 1, body 50 50 0 0 1, body 51 50 0 0 1 ] of
                    [ a, b, c ] ->
                        Expect.all
                            [ \_ -> overlap a b |> Expect.atMost 1.0e-2
                            , \_ -> overlap b c |> Expect.atMost 1.0e-2
                            , \_ -> overlap a c |> Expect.atMost 1.0e-2
                            ]
                            ()

                    _ ->
                        Expect.fail "expected exactly three bodies back"
        ]
