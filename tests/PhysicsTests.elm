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


tests : Test
tests =
    Test.describe "Physics.simulate"
        [ Test.test "an empty world stays empty" <|
            \_ ->
                Physics.simulate 100 (Duration.seconds 1) []
                    |> Expect.equal []
        , Test.test "a lone circle does not move" <|
            \_ ->
                let
                    circle : Circle
                    circle =
                        { x = 3, y = -2, radius = 1 }
                in
                Physics.simulate 100 (Duration.seconds 1) [ circle ]
                    |> Expect.equal [ circle ]
        , Test.test "circles that don't touch are left alone" <|
            \_ ->
                let
                    world : List Circle
                    world =
                        [ { x = 0, y = 0, radius = 1 }
                        , { x = 10, y = 0, radius = 1 }
                        ]
                in
                Physics.simulate 100 (Duration.seconds 1) world
                    |> Expect.equal world
        , Test.test "zero steps is a no-op" <|
            \_ ->
                let
                    world : List Circle
                    world =
                        [ { x = -0.5, y = 0, radius = 1 }
                        , { x = 0.5, y = 0, radius = 1 }
                        ]
                in
                Physics.simulate 0 (Duration.seconds 1) world
                    |> Expect.equal world
        , Test.test "two overlapping circles are pushed apart" <|
            \_ ->
                let
                    world : List Circle
                    world =
                        [ { x = -0.5, y = 0, radius = 1 }
                        , { x = 0.5, y = 0, radius = 1 }
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
                        [ { x = -0.5, y = 0, radius = 1 }
                        , { x = 0.5, y = 0, radius = 2 }
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
                        [ { x = -0.5, y = 0, radius = 1 }
                        , { x = 0.5, y = 0, radius = 1 }
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
                        [ { x = 0, y = 0, radius = 1 }
                        , { x = 1, y = 0, radius = 1 }
                        , { x = 2, y = 0, radius = 1 }
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
