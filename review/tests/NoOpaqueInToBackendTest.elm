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
        , test "should report error when opaque type is used directly in ToBackend" <|
            \() ->
                [ """module MyModule exposing (..)

{-| OpaqueVariants
-}
type Email
    = Email String

type ToBackend
    = SendEmail Email
"""
                ]
                    |> Review.Test.runOnModules rule
                    |> Review.Test.expectErrorsForModules
                        [ ( "MyModule"
                          , [ Review.Test.error
                                { message = "Email is an opaque type and must be wrapped in Untrusted when used in ToBackend."
                                , details = [ "Opaque types sent from the frontend could be tampered with. Wrap this type in Untrusted to ensure it gets validated on the backend." ]
                                , under = "Email"
                                }
                                |> Review.Test.atExactly { start = { row = 9, column = 17 }, end = { row = 9, column = 22 } }
                            ]
                          )
                        ]
        , test "should not report error when opaque type is wrapped in Untrusted" <|
            \() ->
                [ """module MyModule exposing (..)

{-| OpaqueVariants
-}
type Email
    = Email String

type Untrusted a
    = Untrusted a

type ToBackend
    = SendEmail (Untrusted Email)
"""
                ]
                    |> Review.Test.runOnModules rule
                    |> Review.Test.expectNoErrors
        , test "should report error for opaque type alias used in ToBackend" <|
            \() ->
                [ """module MyModule exposing (..)

{-| Opaque
-}
type alias MyRecord =
    { name : String }

type ToBackend
    = SendRecord MyRecord
"""
                ]
                    |> Review.Test.runOnModules rule
                    |> Review.Test.expectErrorsForModules
                        [ ( "MyModule"
                          , [ Review.Test.error
                                { message = "MyRecord is an opaque type and must be wrapped in Untrusted when used in ToBackend."
                                , details = [ "Opaque types sent from the frontend could be tampered with. Wrap this type in Untrusted to ensure it gets validated on the backend." ]
                                , under = "MyRecord"
                                }
                                |> Review.Test.atExactly { start = { row = 9, column = 18 }, end = { row = 9, column = 26 } }
                            ]
                          )
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
                [ """module MyModule exposing (..)

{-| OpaqueVariants
-}
type Email
    = Email String

type ToBackend
    = SendEmails (List Email)
"""
                ]
                    |> Review.Test.runOnModules rule
                    |> Review.Test.expectErrorsForModules
                        [ ( "MyModule"
                          , [ Review.Test.error
                                { message = "Email is an opaque type and must be wrapped in Untrusted when used in ToBackend."
                                , details = [ "Opaque types sent from the frontend could be tampered with. Wrap this type in Untrusted to ensure it gets validated on the backend." ]
                                , under = "Email"
                                }
                                |> Review.Test.atExactly { start = { row = 9, column = 24 }, end = { row = 9, column = 29 } }
                            ]
                          )
                        ]
        , test "should not report errors for non-ToBackend types using opaque types" <|
            \() ->
                [ """module MyModule exposing (..)

{-| OpaqueVariants
-}
type Email
    = Email String

type Msg
    = GotEmail Email
"""
                ]
                    |> Review.Test.runOnModules rule
                    |> Review.Test.expectNoErrors
        , test "should allow opaque types in phantom type parameter positions" <|
            \() ->
                [ """module MyModule exposing (..)

{-| OpaqueVariants
-}
type PageId
    = PageId Never

type Id a
    = Id Int

type ToBackend
    = GetPage (Id PageId)
"""
                ]
                    |> Review.Test.runOnModules rule
                    |> Review.Test.expectNoErrors
        , test "should report opaque types in non-phantom type parameter positions" <|
            \() ->
                [ """module MyModule exposing (..)

{-| OpaqueVariants
-}
type Email
    = Email String

type Wrapper a
    = Wrapper a

type ToBackend
    = SendWrapped (Wrapper Email)
"""
                ]
                    |> Review.Test.runOnModules rule
                    |> Review.Test.expectErrorsForModules
                        [ ( "MyModule"
                          , [ Review.Test.error
                                { message = "Email is an opaque type and must be wrapped in Untrusted when used in ToBackend."
                                , details = [ "Opaque types sent from the frontend could be tampered with. Wrap this type in Untrusted to ensure it gets validated on the backend." ]
                                , under = "Email"
                                }
                                |> Review.Test.atExactly { start = { row = 12, column = 28 }, end = { row = 12, column = 33 } }
                            ]
                          )
                        ]
        , test "should allow opaque type in phantom position but report in non-phantom position" <|
            \() ->
                [ """module MyModule exposing (..)

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
                ]
                    |> Review.Test.runOnModules rule
                    |> Review.Test.expectErrorsForModules
                        [ ( "MyModule"
                          , [ Review.Test.error
                                { message = "Email is an opaque type and must be wrapped in Untrusted when used in ToBackend."
                                , details = [ "Opaque types sent from the frontend could be tampered with. Wrap this type in Untrusted to ensure it gets validated on the backend." ]
                                , under = "Email"
                                }
                                |> Review.Test.atExactly { start = { row = 17, column = 31 }, end = { row = 17, column = 36 } }
                            ]
                          )
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
                    |> Review.Test.runOnModules rule
                    |> Review.Test.expectNoErrors
        , test "should recursively check types referenced from ToBackend" <|
            \() ->
                [ """module MyModule exposing (..)

{-| OpaqueVariants
-}
type Email
    = Email String

type MyRequest
    = SendEmail Email

type ToBackend
    = DoRequest MyRequest
"""
                ]
                    |> Review.Test.runOnModules rule
                    |> Review.Test.expectErrorsForModules
                        [ ( "MyModule"
                          , [ Review.Test.error
                                { message = "Email is an opaque type and must be wrapped in Untrusted when used in ToBackend."
                                , details = [ "Opaque types sent from the frontend could be tampered with. Wrap this type in Untrusted to ensure it gets validated on the backend." ]
                                , under = "Email"
                                }
                                |> Review.Test.atExactly { start = { row = 9, column = 17 }, end = { row = 9, column = 22 } }
                            ]
                          )
                        ]
        , test "should recursively check types across modules" <|
            \() ->
                [ """module FileStatus exposing (..)

{-| OpaqueVariants
-}
type FileHash
    = FileHash String
"""
                , """module ImageEditor exposing (..)
import FileStatus exposing (FileHash)

type ToBackend
    = ChangeUserAvatarRequest FileHash
"""
                , """module Types exposing (..)
import ImageEditor

type ToBackend
    = ProfilePictureEditorToBackend ImageEditor.ToBackend
"""
                ]
                    |> Review.Test.runOnModules rule
                    |> Review.Test.expectErrorsForModules
                        [ ( "ImageEditor"
                          , [ Review.Test.error
                                { message = "FileHash is an opaque type and must be wrapped in Untrusted when used in ToBackend."
                                , details = [ "Opaque types sent from the frontend could be tampered with. Wrap this type in Untrusted to ensure it gets validated on the backend." ]
                                , under = "FileHash"
                                }
                                |> Review.Test.atExactly { start = { row = 5, column = 31 }, end = { row = 5, column = 39 } }
                            ]
                          )
                        ]
        , test "should recursively check non-ToBackend types for opaque contents" <|
            \() ->
                [ """module FileStatus exposing (..)

{-| OpaqueVariants
-}
type FileHash
    = FileHash String
"""
                , """module Types exposing (..)
import FileStatus exposing (FileHash)

type MyData
    = MyData FileHash

type ToBackend
    = SendData MyData
"""
                ]
                    |> Review.Test.runOnModules rule
                    |> Review.Test.expectErrorsForModules
                        [ ( "Types"
                          , [ Review.Test.error
                                { message = "FileHash is an opaque type and must be wrapped in Untrusted when used in ToBackend."
                                , details = [ "Opaque types sent from the frontend could be tampered with. Wrap this type in Untrusted to ensure it gets validated on the backend." ]
                                , under = "FileHash"
                                }
                                |> Review.Test.atExactly { start = { row = 5, column = 14 }, end = { row = 5, column = 22 } }
                            ]
                          )
                        ]
        , test "should not infinitely recurse on recursive types" <|
            \() ->
                [ """module MyModule exposing (..)

type Tree
    = Leaf String
    | Branch Tree Tree

type ToBackend
    = SendTree Tree
"""
                ]
                    |> Review.Test.runOnModules rule
                    |> Review.Test.expectNoErrors
        ]
