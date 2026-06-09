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
    (c.x - c.radius >= -1.0e-6)
        && (c.x + c.radius <= Physics.boundsX + 1.0e-6)
        && (c.y - c.radius >= -1.0e-6)
        && (c.y + c.radius <= Physics.boundsY + 1.0e-6)


body : Float -> Float -> Float -> Float -> Float -> Body
body x y vx vy radius =
    { x = x, y = y, vx = vx, vy = vy, radius = radius }


tests : Test
tests =
    Test.describe "Physics.simulate"
        [ Test.test "an empty world stays empty" <|
            \_ ->
                Physics.simulate 4 (Duration.milliseconds 100) []
                    |> Expect.equal []
        , Test.test "zero steps is a no-op" <|
            \_ ->
                let
                    world : List Body
                    world =
                        [ body 49.5 50 0 0 1, body 50.5 50 0 0 1 ]
                in
                Physics.simulate 0 (Duration.milliseconds 100) world
                    |> Expect.equal world
        , Test.test "the spring arm pushes a lone body downward" <|
            \_ ->
                case Physics.simulate 4 (Duration.milliseconds 100) [ body 50 50 0 0 1 ] of
                    [ moved ] ->
                        Expect.all
                            [ \_ -> moved.y |> Expect.greaterThan 51
                            , \_ -> moved.vy |> Expect.greaterThan 0
                            , \_ -> insideBounds moved |> Expect.equal True
                            ]
                            ()

                    _ ->
                        Expect.fail "expected exactly one body back"
        , Test.test "the arm targets the topmost body and leaves bodies below it alone" <|
            \_ ->
                case Physics.simulate 4 (Duration.milliseconds 100) [ body 50 20 0 0 1, body 50 80 0 0 1 ] of
                    [ top, bottom ] ->
                        Expect.all
                            [ \_ -> top.y - 20 |> Expect.greaterThan 0.5
                            , \_ -> abs (bottom.y - 80) |> Expect.atMost 1.0e-3
                            , \_ -> abs bottom.vy |> Expect.atMost 1.0e-3
                            ]
                            ()

                    _ ->
                        Expect.fail "expected exactly two bodies back"
        , Test.test "the arm force falls off rapidly with height difference" <|
            \_ ->
                case Physics.simulate 1 (Duration.milliseconds 1) [ body 50 50 0 0 1, body 70 51 0 0 1 ] of
                    [ top, oneBelow ] ->
                        -- One unit of separation is enough to drop the force
                        -- by e^5 ≈ 150x.
                        top.vy / oneBelow.vy |> Expect.greaterThan 100

                    _ ->
                        Expect.fail "expected exactly two bodies back"
        , Test.test "a moving body travels in its direction of motion" <|
            \_ ->
                case Physics.simulate 4 (Duration.milliseconds 100) [ body 50 50 20 0 1 ] of
                    [ moved ] ->
                        Expect.all
                            [ \_ -> moved.x |> Expect.greaterThan 50.5
                            , \_ -> insideBounds moved |> Expect.equal True
                            ]
                            ()

                    _ ->
                        Expect.fail "expected exactly one body back"
        , Test.test "a body that runs into a wall ends up resting against it" <|
            \_ ->
                case Physics.simulate 4 (Duration.milliseconds 200) [ body 40 50 200 0 1 ] of
                    [ stopped ] ->
                        Expect.all
                            [ \_ -> insideBounds stopped |> Expect.equal True
                            , \_ -> stopped.x |> Expect.within (Expect.Absolute 1.0e-6) (Physics.boundsX - stopped.radius)
                            , \_ -> stopped.vx |> Expect.within (Expect.Absolute 1.0e-6) 0
                            ]
                            ()

                    _ ->
                        Expect.fail "expected exactly one body back"
        , Test.test "bodies never escape the bounding box" <|
            \_ ->
                let
                    world : List Body
                    world =
                        [ body 55 150 200 200 1
                        , body 5 150 -200 200 1
                        , body 30 5 0 -200 2
                        ]
                in
                Physics.simulate 4 (Duration.milliseconds 100) world
                    |> List.all insideBounds
                    |> Expect.equal True
        , Test.test "two overlapping bodies are pushed apart in a single substep" <|
            \_ ->
                case Physics.simulate 1 (Duration.milliseconds 16.6) [ body 49.5 50 0 0 1, body 50.5 50 0 0 1 ] of
                    [ a, b ] ->
                        overlap a b |> Expect.atMost 1.0e-6

                    _ ->
                        Expect.fail "expected exactly two bodies back"
        , Test.test "radii and ordering are preserved" <|
            \_ ->
                Physics.simulate 4 (Duration.milliseconds 100) [ body 49 50 0 0 1, body 51 50 0 0 2 ]
                    |> List.map .radius
                    |> Expect.equal [ 1, 2 ]
        , Test.test "a symmetric horizontal collision preserves the horizontal center of mass" <|
            \_ ->
                case Physics.simulate 4 (Duration.milliseconds 100) [ body 49.5 50 0 0 1, body 50.5 50 0 0 1 ] of
                    [ a, b ] ->
                        (a.x + b.x) / 2 |> Expect.within (Expect.Absolute 1.0e-9) 50

                    _ ->
                        Expect.fail "expected exactly two bodies back"
        , Test.test "distant bodies are left alone even after several substeps" <|
            \_ ->
                -- These two are 50+ units apart at every substep so they
                -- never end up on each other's neighbor list; the test is
                -- really checking that the neighbor pruning doesn't
                -- introduce phantom interactions either.
                let
                    world : List Body
                    world =
                        [ body 5 80 0 0 1, body 55 80 0 0 1 ]
                in
                case Physics.simulate 4 (Duration.milliseconds 100) world of
                    [ left, right ] ->
                        Expect.all
                            [ \_ -> abs (left.x - 5) |> Expect.atMost 1.0e-9
                            , \_ -> abs (right.x - 55) |> Expect.atMost 1.0e-9
                            ]
                            ()

                    _ ->
                        Expect.fail "expected exactly two bodies back"
        , Test.test "a pile of three overlapping bodies fully separates" <|
            \_ ->
                case Physics.simulate 4 (Duration.milliseconds 100) [ body 49 50 0 0 1, body 50 50 0 0 1, body 51 50 0 0 1 ] of
                    [ a, b, c ] ->
                        Expect.all
                            [ \_ -> overlap a b |> Expect.atMost 1.0e-3
                            , \_ -> overlap b c |> Expect.atMost 1.0e-3
                            , \_ -> overlap a c |> Expect.atMost 1.0e-3
                            ]
                            ()

                    _ ->
                        Expect.fail "expected exactly three bodies back"
        , Test.test "floor friction holds a slowly sliding body nearly in place" <|
            \_ ->
                -- Resting on the floor (the large-y wall the arm pushes toward)
                -- with a gentle sideways nudge. Static friction should cancel
                -- almost all of the would-be 0.5 unit slide.
                case Physics.simulate 8 (Duration.milliseconds 100) [ body 30 154 5 0 6 ] of
                    [ moved ] ->
                        abs (moved.x - 30) |> Expect.atMost 0.1

                    _ ->
                        Expect.fail "expected exactly one body back"
        , Test.test "a hard sideways shove overcomes friction and still slides" <|
            \_ ->
                case Physics.simulate 8 (Duration.milliseconds 100) [ body 30 154 200 0 6 ] of
                    [ moved ] ->
                        moved.x - 30 |> Expect.greaterThan 2

                    _ ->
                        Expect.fail "expected exactly one body back"
        , Test.test "friction does not interfere with a head-on (purely normal) separation" <|
            \_ ->
                -- Overlapping along x with no tangential motion: friction has
                -- nothing to resist, so they still separate symmetrically.
                case Physics.simulate 4 (Duration.milliseconds 100) [ body 29.5 80 0 0 1, body 30.5 80 0 0 1 ] of
                    [ a, b ] ->
                        Expect.all
                            [ \_ -> overlap a b |> Expect.atMost 1.0e-3
                            , \_ -> (a.x + b.x) / 2 |> Expect.within (Expect.Absolute 1.0e-9) 30
                            ]
                            ()

                    _ ->
                        Expect.fail "expected exactly two bodies back"
        ]
