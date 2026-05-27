module NoInvalidTypesInToBackendTest exposing (all)

import NoInvalidTypesInToBackend
import Review.Rule exposing (Rule)
import Review.Test
import Test exposing (Test, describe, test)


{-| The default configuration used by most tests: disallow `Float`.
-}
rule : Rule
rule =
    NoInvalidTypesInToBackend.rule
        { disallowed = [ ( [ "Basics" ], "Float" ) ]
        , unlessWrappedIn = []
        }


message : String
message =
    "Found a disallowed type referenced by ToBackend"


{-| Builds the expected error, filling in the path detail.
-}
pathError : String -> Review.Test.ExpectedError
pathError path =
    Review.Test.error
        { message = message
        , details =
            [ "ToBackend references a type that this rule disallows, either directly or indirectly through other types."
            , "Path: " ++ path
            ]
        , under = "ToBackend"
        }


all : Test
all =
    describe "NoInvalidTypesInToBackend"
        [ test "does not report when ToBackend has no disallowed type" <|
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
                        [ pathError "ToBackend -> Float" ]
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
                        [ pathError "ToBackend -> ServerChange -> Coord -> Float" ]
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
                        [ pathError "ToBackend -> Coord -> Float" ]
        , test "reports a Float used as a type argument directly" <|
            \() ->
                """module Types exposing (..)

type ToBackend
    = SendFloats (List Float)
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectErrors
                        [ pathError "ToBackend -> Float" ]
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
                          , [ pathError "ToBackend -> ServerChange -> Coord -> Float" ]
                          )
                        ]
        , test "does not report a disallowed type referenced by a non-ToBackend type" <|
            \() ->
                """module Types exposing (..)

type ToBackend
    = SendMessage String

type FrontendModel
    = Model Float
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectNoErrors
        , test "reports the shortest path when several lead to the disallowed type" <|
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
                        [ pathError "ToBackend -> Coord -> Float" ]
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
        , describe "user provided disallowed types"
            [ test "reports a disallowed project type reached indirectly" <|
                \() ->
                    [ """module Money exposing (..)

type Money
    = Money Int
"""
                    , """module Types exposing (..)
import Money exposing (Money)

type Transaction
    = Transaction Money

type ToBackend
    = Pay Transaction
"""
                    ]
                        |> Review.Test.runOnModules
                            (NoInvalidTypesInToBackend.rule
                                { disallowed = [ ( [ "Money" ], "Money" ) ]
                                , unlessWrappedIn = []
                                }
                            )
                        |> Review.Test.expectErrorsForModules
                            [ ( "Types"
                              , [ pathError "ToBackend -> Transaction -> Money" ]
                              )
                            ]
            , test "does not report a type that is not in the disallowed list" <|
                \() ->
                    """module Types exposing (..)

type ToBackend
    = SendFloat Float
"""
                        |> Review.Test.run
                            (NoInvalidTypesInToBackend.rule
                                { disallowed = [ ( [ "Time" ], "Posix" ) ]
                                , unlessWrappedIn = []
                                }
                            )
                        |> Review.Test.expectNoErrors
            , test "reports the disallowed type that is reached" <|
                \() ->
                    """module Types exposing (..)

type ToBackend
    = SendTime Float
"""
                        |> Review.Test.run
                            (NoInvalidTypesInToBackend.rule
                                { disallowed =
                                    [ ( [ "Basics" ], "Float" )
                                    , ( [ "Basics" ], "Int" )
                                    ]
                                , unlessWrappedIn = []
                                }
                            )
                        |> Review.Test.expectErrors
                            [ pathError "ToBackend -> Float" ]
            ]
        , describe "exemptions"
            [ test "does not report when the type holding the Float is exempt" <|
                \() ->
                    """module Types exposing (..)

type alias Coord =
    { x : Float }

type ToBackend
    = SendCoord Coord
"""
                        |> Review.Test.run
                            (NoInvalidTypesInToBackend.rule
                                { disallowed = [ ( [ "Basics" ], "Float" ) ]
                                , unlessWrappedIn = [ ( [ "Types" ], "Coord" ) ]
                                }
                            )
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
                        |> Review.Test.run
                            (NoInvalidTypesInToBackend.rule
                                { disallowed = [ ( [ "Basics" ], "Float" ) ]
                                , unlessWrappedIn = [ ( [ "Types" ], "ServerChange" ) ]
                                }
                            )
                        |> Review.Test.expectNoErrors
            , test "still reports when an unrelated type is exempt" <|
                \() ->
                    """module Types exposing (..)

type alias Coord =
    { x : Float }

type ToBackend
    = SendCoord Coord
"""
                        |> Review.Test.run
                            (NoInvalidTypesInToBackend.rule
                                { disallowed = [ ( [ "Basics" ], "Float" ) ]
                                , unlessWrappedIn = [ ( [ "Types" ], "SomethingElse" ) ]
                                }
                            )
                        |> Review.Test.expectErrors
                            [ pathError "ToBackend -> Coord -> Float" ]
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
                        |> Review.Test.runOnModules
                            (NoInvalidTypesInToBackend.rule
                                { disallowed = [ ( [ "Basics" ], "Float" ) ]
                                , unlessWrappedIn = [ ( [ "Geometry" ], "Coord" ) ]
                                }
                            )
                        |> Review.Test.expectNoErrors
            , test "exempting the disallowed type itself silences the check" <|
                \() ->
                    """module Types exposing (..)

type ToBackend
    = SendFloat Float
"""
                        |> Review.Test.run
                            (NoInvalidTypesInToBackend.rule
                                { disallowed = [ ( [ "Basics" ], "Float" ) ]
                                , unlessWrappedIn = [ ( [ "Basics" ], "Float" ) ]
                                }
                            )
                        |> Review.Test.expectNoErrors
            ]
        ]
