module NoOpaqueInToBackendTest exposing (all)

import NoOpaqueInToBackend
import Review.Test
import Test exposing (Test, describe, test)


defaultRule =
    NoOpaqueInToBackend.rule { exemptions = [] }


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
                    |> Review.Test.runOnModules defaultRule
                    |> Review.Test.expectNoErrors
        , test "should report error when opaque type is used directly in ToBackend (same module)" <|
            \() ->
                """module Types exposing (..)

{-| OpaqueVariants
-}
type Email
    = Email String

type ToBackend
    = SendEmail Email
"""
                    |> Review.Test.run defaultRule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "Email is an opaque type and must be wrapped in Untrusted when used in ToBackend."
                            , details = [ "Opaque types sent from the frontend could be tampered with. Wrap this type in Untrusted to ensure it gets validated on the backend. Referenced via ToBackend -> Email" ]
                            , under = "Email"
                            }
                            |> Review.Test.atExactly { start = { row = 9, column = 17 }, end = { row = 9, column = 22 } }
                        ]
        , test "should not report error when opaque type is wrapped in Untrusted" <|
            \() ->
                """module Types exposing (..)

{-| OpaqueVariants
-}
type Email
    = Email String

type Untrusted a
    = Untrusted a

type ToBackend
    = SendEmail (Untrusted Email)
"""
                    |> Review.Test.run defaultRule
                    |> Review.Test.expectNoErrors
        , test "should report error for opaque type alias used in ToBackend" <|
            \() ->
                """module Types exposing (..)

{-| Opaque
-}
type alias MyRecord =
    { name : String }

type ToBackend
    = SendRecord MyRecord
"""
                    |> Review.Test.run defaultRule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "MyRecord is an opaque type and must be wrapped in Untrusted when used in ToBackend."
                            , details = [ "Opaque types sent from the frontend could be tampered with. Wrap this type in Untrusted to ensure it gets validated on the backend. Referenced via ToBackend -> MyRecord" ]
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
                    |> Review.Test.runOnModules defaultRule
                    |> Review.Test.expectErrorsForModules
                        [ ( "Types"
                          , [ Review.Test.error
                                { message = "Email is an opaque type and must be wrapped in Untrusted when used in ToBackend."
                                , details = [ "Opaque types sent from the frontend could be tampered with. Wrap this type in Untrusted to ensure it gets validated on the backend. Referenced via ToBackend -> Email" ]
                                , under = "Email"
                                }
                                |> Review.Test.atExactly { start = { row = 5, column = 17 }, end = { row = 5, column = 22 } }
                            ]
                          )
                        ]
        , test "should report error for opaque type nested inside other types in ToBackend" <|
            \() ->
                """module Types exposing (..)

{-| OpaqueVariants
-}
type Email
    = Email String

type ToBackend
    = SendEmails (List Email)
"""
                    |> Review.Test.run defaultRule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "Email is an opaque type and must be wrapped in Untrusted when used in ToBackend."
                            , details = [ "Opaque types sent from the frontend could be tampered with. Wrap this type in Untrusted to ensure it gets validated on the backend. Referenced via ToBackend -> Email" ]
                            , under = "Email"
                            }
                            |> Review.Test.atExactly { start = { row = 9, column = 24 }, end = { row = 9, column = 29 } }
                        ]
        , test "should not report errors for non-ToBackend types using opaque types" <|
            \() ->
                """module Types exposing (..)

{-| OpaqueVariants
-}
type Email
    = Email String

type Msg
    = GotEmail Email
"""
                    |> Review.Test.run defaultRule
                    |> Review.Test.expectNoErrors
        , test "should allow opaque types in phantom type parameter positions" <|
            \() ->
                """module Types exposing (..)

{-| OpaqueVariants
-}
type PageId
    = PageId Never

type Id a
    = Id Int

type ToBackend
    = GetPage (Id PageId)
"""
                    |> Review.Test.run defaultRule
                    |> Review.Test.expectNoErrors
        , test "should report opaque types in non-phantom type parameter positions" <|
            \() ->
                """module Types exposing (..)

{-| OpaqueVariants
-}
type Email
    = Email String

type Wrapper a
    = Wrapper a

type ToBackend
    = SendWrapped (Wrapper Email)
"""
                    |> Review.Test.run defaultRule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "Email is an opaque type and must be wrapped in Untrusted when used in ToBackend."
                            , details = [ "Opaque types sent from the frontend could be tampered with. Wrap this type in Untrusted to ensure it gets validated on the backend. Referenced via ToBackend -> Email" ]
                            , under = "Email"
                            }
                            |> Review.Test.atExactly { start = { row = 12, column = 28 }, end = { row = 12, column = 33 } }
                        ]
        , test "should allow opaque type in phantom position but report in non-phantom position" <|
            \() ->
                """module Types exposing (..)

{-| OpaqueVariants
-}
type PageId
    = PageId Never

{-| OpaqueVariants
-}
type Email
    = Email String

type Mixed phantom real
    = Mixed real

type ToBackend
    = SendMixed (Mixed PageId Email)
"""
                    |> Review.Test.run defaultRule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "Email is an opaque type and must be wrapped in Untrusted when used in ToBackend."
                            , details = [ "Opaque types sent from the frontend could be tampered with. Wrap this type in Untrusted to ensure it gets validated on the backend. Referenced via ToBackend -> Email" ]
                            , under = "Email"
                            }
                            |> Review.Test.atExactly { start = { row = 17, column = 31 }, end = { row = 17, column = 36 } }
                        ]
        , test "should allow phantom type params from imported module" <|
            \() ->
                [ """module Id exposing (..)

type Id a
    = Id Int
"""
                , """module Types exposing (..)
import Id exposing (Id)

{-| OpaqueVariants
-}
type PageId
    = PageId Never

type ToBackend
    = GetPage (Id PageId)
"""
                ]
                    |> Review.Test.runOnModules defaultRule
                    |> Review.Test.expectNoErrors
        , test "should recursively check types referenced by Types.ToBackend" <|
            \() ->
                [ """module Admin exposing (..)

{-| OpaqueVariants
-}
type Email
    = Email String

type ToBackend
    = DoSomething Email
"""
                , """module Types exposing (..)
import Admin

type ToBackend
    = AdminToBackend Admin.ToBackend
"""
                ]
                    |> Review.Test.runOnModules defaultRule
                    |> Review.Test.expectErrorsForModules
                        [ ( "Admin"
                          , [ Review.Test.error
                                { message = "Email is an opaque type and must be wrapped in Untrusted when used in ToBackend."
                                , details = [ "Opaque types sent from the frontend could be tampered with. Wrap this type in Untrusted to ensure it gets validated on the backend. Referenced via ToBackend -> ToBackend -> Email" ]
                                , under = "Email"
                                }
                                |> Review.Test.atExactly { start = { row = 9, column = 19 }, end = { row = 9, column = 24 } }
                            ]
                          )
                        ]
        , test "should not report types not referenced from ToBackend" <|
            \() ->
                [ """module Admin exposing (..)

{-| OpaqueVariants
-}
type Email
    = Email String

type ToBackend
    = DoSomething
    
type Msg
    = CreatedEmail Email
    | Abc ToBackend

type alias Record =
    { email : Email
    }
"""
                , """module Types exposing (..)
import Admin

type ToBackend
    = AdminToBackend Admin.ToBackend

type Logs
    = FailedToSendEmail Email
"""
                ]
                    |> Review.Test.runOnModules defaultRule
                    |> Review.Test.expectErrorsForModules
                        []
        , test "should not report errors for ToBackend in non-Types module" <|
            \() ->
                """module Admin exposing (..)

{-| OpaqueVariants
-}
type Email
    = Email String

type ToBackend
    = SendEmail Email
"""
                    |> Review.Test.run defaultRule
                    |> Review.Test.expectNoErrors
        , test "should recursively check nested type references" <|
            \() ->
                [ """module Deep exposing (..)

{-| OpaqueVariants
-}
type Secret
    = Secret String
"""
                , """module Middle exposing (..)
import Deep exposing (Secret)

type Data
    = Data Secret
"""
                , """module Types exposing (..)
import Middle

type ToBackend
    = SendData Middle.Data
"""
                ]
                    |> Review.Test.runOnModules defaultRule
                    |> Review.Test.expectErrorsForModules
                        [ ( "Middle"
                          , [ Review.Test.error
                                { message = "Secret is an opaque type and must be wrapped in Untrusted when used in ToBackend."
                                , details = [ "Opaque types sent from the frontend could be tampered with. Wrap this type in Untrusted to ensure it gets validated on the backend. Referenced via ToBackend -> Data -> Secret" ]
                                , under = "Secret"
                                }
                                |> Review.Test.atExactly { start = { row = 5, column = 12 }, end = { row = 5, column = 18 } }
                            ]
                          )
                        ]
        , test "should not recurse into Untrusted-wrapped types" <|
            \() ->
                [ """module Other exposing (..)

{-| OpaqueVariants
-}
type Email
    = Email String

type Untrusted a
    = Untrusted a

type Data
    = Data (Untrusted Email)
"""
                , """module Types exposing (..)
import Other

type ToBackend
    = SendData Other.Data
"""
                ]
                    |> Review.Test.runOnModules defaultRule
                    |> Review.Test.expectNoErrors
        ]
