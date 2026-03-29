module NoOpaqueInToBackendTest exposing (all)

import NoOpaqueInToBackend exposing (rule)
import Review.Test
import Test exposing (Test, describe, test)


all : Test
all =
    describe "NoOpaqueInToBackend"
        [ test "should not report errors when ToBackend has no opaque types" <|
            \() ->
                [ """module Types exposing (..)

type ToBackend
    = SendMessage String
    | SendNumber Int
"""
                ]
                    |> Review.Test.runOnModules rule
                    |> Review.Test.expectNoErrors
        , test "should report error when opaque type is used directly in ToBackend (same module)" <|
            \() ->
                """module MyModule exposing (..)

{-| OpaqueVariants
-}
type Email
    = Email String

type ToBackend
    = SendEmail Email
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "Email is an opaque type and must be wrapped in Untrusted when used in ToBackend."
                            , details = [ "Opaque types sent from the frontend could be tampered with. Wrap this type in Untrusted to ensure it gets validated on the backend." ]
                            , under = "Email"
                            }
                            |> Review.Test.atExactly { start = { row = 9, column = 17 }, end = { row = 9, column = 22 } }
                        ]
        , test "should not report error when opaque type is wrapped in Untrusted" <|
            \() ->
                """module MyModule exposing (..)

{-| OpaqueVariants
-}
type Email
    = Email String

type Untrusted a
    = Untrusted a

type ToBackend
    = SendEmail (Untrusted Email)
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectNoErrors
        , test "should report error for opaque type alias used in ToBackend" <|
            \() ->
                """module MyModule exposing (..)

{-| Opaque
-}
type alias MyRecord =
    { name : String }

type ToBackend
    = SendRecord MyRecord
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "MyRecord is an opaque type and must be wrapped in Untrusted when used in ToBackend."
                            , details = [ "Opaque types sent from the frontend could be tampered with. Wrap this type in Untrusted to ensure it gets validated on the backend." ]
                            , under = "MyRecord"
                            }
                            |> Review.Test.atExactly { start = { row = 9, column = 18 }, end = { row = 9, column = 26 } }
                        ]
        , test "should report error for opaque type from imported module" <|
            \() ->
                [ """module OtherModule exposing (..)

{-| OpaqueVariants
-}
type Email
    = Email String
"""
                , """module Types exposing (..)
import OtherModule exposing (Email)

type ToBackend
    = SendEmail Email
"""
                ]
                    |> Review.Test.runOnModules rule
                    |> Review.Test.expectErrorsForModules
                        [ ( "Types"
                          , [ Review.Test.error
                                { message = "Email is an opaque type and must be wrapped in Untrusted when used in ToBackend."
                                , details = [ "Opaque types sent from the frontend could be tampered with. Wrap this type in Untrusted to ensure it gets validated on the backend." ]
                                , under = "Email"
                                }
                                |> Review.Test.atExactly { start = { row = 5, column = 17 }, end = { row = 5, column = 22 } }
                            ]
                          )
                        ]
        , test "should report error for opaque type nested inside other types in ToBackend" <|
            \() ->
                """module MyModule exposing (..)

{-| OpaqueVariants
-}
type Email
    = Email String

type ToBackend
    = SendEmails (List Email)
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "Email is an opaque type and must be wrapped in Untrusted when used in ToBackend."
                            , details = [ "Opaque types sent from the frontend could be tampered with. Wrap this type in Untrusted to ensure it gets validated on the backend." ]
                            , under = "Email"
                            }
                            |> Review.Test.atExactly { start = { row = 9, column = 24 }, end = { row = 9, column = 29 } }
                        ]
        , test "should not report errors for non-ToBackend types using opaque types" <|
            \() ->
                """module MyModule exposing (..)

{-| OpaqueVariants
-}
type Email
    = Email String

type Msg
    = GotEmail Email
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectNoErrors
        ]
