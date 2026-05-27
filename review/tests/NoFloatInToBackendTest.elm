module NoFloatInToBackendTest exposing (all)

import NoFloatInToBackend
import Review.Rule exposing (Rule)
import Review.Test
import Test exposing (Test, describe, test)


rule : Rule
rule =
    NoFloatInToBackend.rule []


message : String
message =
    "Found a Float referenced by ToBackend"


{-| Builds the expected error, filling in the path detail.
-}
floatError : String -> Review.Test.ExpectedError
floatError path =
    Review.Test.error
        { message = message
        , details =
            [ "Floats sent from the frontend can't be trusted and floating point serialization is lossy, so ToBackend shouldn't reference Float (even indirectly through other types)."
            , "Path: " ++ path
            ]
        , under = "ToBackend"
        }


all : Test
all =
    describe "NoFloatInToBackend"
        [ test "does not report when ToBackend has no Float" <|
            \() ->
                """module Types exposing (..)

type ToBackend
    = SendMessage String
    | SendNumber Int
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectNoErrors
        , test "does not report when there is no ToBackend type" <|
            \() ->
                """module Types exposing (..)

type Other
    = WithFloat Float
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectNoErrors
        , test "reports a Float referenced directly in ToBackend" <|
            \() ->
                """module Types exposing (..)

type ToBackend
    = SendCoord Float
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectErrors
                        [ floatError "ToBackend" ]
        , test "reports a Float nested inside another type in the same module" <|
            \() ->
                """module Types exposing (..)

type alias Coord =
    { x : Float, y : Float }

type ServerChange
    = Move Coord

type ToBackend
    = Change ServerChange
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectErrors
                        [ floatError "ToBackend -> ServerChange -> Coord" ]
        , test "reports a Float reached through type arguments" <|
            \() ->
                """module Types exposing (..)

type alias Coord =
    { x : Float }

type ToBackend
    = SendCoords (List Coord)
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectErrors
                        [ floatError "ToBackend -> Coord" ]
        , test "reports a Float used as a type argument directly" <|
            \() ->
                """module Types exposing (..)

type ToBackend
    = SendFloats (List Float)
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectErrors
                        [ floatError "ToBackend" ]
        , test "reports a Float through types in other modules" <|
            \() ->
                [ """module Geometry exposing (..)

type alias Coord =
    { x : Float, y : Float }
"""
                , """module Types exposing (..)
import Geometry exposing (Coord)

type ServerChange
    = Move Coord

type ToBackend
    = Change ServerChange
"""
                ]
                    |> Review.Test.runOnModules rule
                    |> Review.Test.expectErrorsForModules
                        [ ( "Types"
                          , [ floatError "ToBackend -> ServerChange -> Coord" ]
                          )
                        ]
        , test "does not report a Float referenced by a non-ToBackend type" <|
            \() ->
                """module Types exposing (..)

type ToBackend
    = SendMessage String

type FrontendModel
    = Model Float
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectNoErrors
        , test "reports the shortest path when several lead to Float" <|
            \() ->
                """module Types exposing (..)

type alias Coord =
    { x : Float }

type ToBackend
    = Direct Coord
    | Indirect (List Coord)
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectErrors
                        [ floatError "ToBackend -> Coord" ]
        , test "handles recursive types without looping" <|
            \() ->
                """module Types exposing (..)

type Tree
    = Leaf
    | Node Tree Tree

type ToBackend
    = SendTree Tree
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectNoErrors
        , test "does not report a user defined type also named Float" <|
            \() ->
                """module Types exposing (..)

type Float
    = MyFloat

type ToBackend
    = SendFloat Float
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectNoErrors
        , describe "exemptions"
            [ test "does not report when the type holding the Float is exempt" <|
                \() ->
                    """module Types exposing (..)

type alias Coord =
    { x : Float }

type ToBackend
    = SendCoord Coord
"""
                        |> Review.Test.run (NoFloatInToBackend.rule [ ( [ "Types" ], "Coord" ) ])
                        |> Review.Test.expectNoErrors
            , test "does not report when an intermediate type is exempt" <|
                \() ->
                    """module Types exposing (..)

type alias Coord =
    { x : Float }

type ServerChange
    = Move Coord

type ToBackend
    = Change ServerChange
"""
                        |> Review.Test.run (NoFloatInToBackend.rule [ ( [ "Types" ], "ServerChange" ) ])
                        |> Review.Test.expectNoErrors
            , test "still reports when an unrelated type is exempt" <|
                \() ->
                    """module Types exposing (..)

type alias Coord =
    { x : Float }

type ToBackend
    = SendCoord Coord
"""
                        |> Review.Test.run (NoFloatInToBackend.rule [ ( [ "Types" ], "SomethingElse" ) ])
                        |> Review.Test.expectErrors
                            [ floatError "ToBackend -> Coord" ]
            , test "exemption is module qualified" <|
                \() ->
                    [ """module Geometry exposing (..)

type alias Coord =
    { x : Float }
"""
                    , """module Types exposing (..)
import Geometry exposing (Coord)

type ToBackend
    = SendCoord Coord
"""
                    ]
                        |> Review.Test.runOnModules (NoFloatInToBackend.rule [ ( [ "Geometry" ], "Coord" ) ])
                        |> Review.Test.expectNoErrors
            ]
        ]
