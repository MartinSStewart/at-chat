module ExposeAllRecordFieldsTest exposing (all)

import ExposeAllRecordFields exposing (rule)
import Review.Test
import Test exposing (Test, describe, test)


all : Test
all =
    describe "ExposeAllRecordFields"
        [ test "should not report an error when function doesn't use record destructuring" <|
            \() ->
                """module A exposing (..)
type alias Person = { name : String, age : Int }
greet : Person -> String
greet person = "Hello " ++ person.name
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectNoErrors
        , test "should not report an error when all record fields are destructured" <|
            \() ->
                """module A exposing (..)
type alias Person = { name : String, age : Int }
greet : Person -> String
greet {name, age} = "Hello " ++ name
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectNoErrors
        , test "should report an error when only some record fields are destructured" <|
            \() ->
                """module A exposing (..)
type alias Person = { name : String, age : Int }
greet : Person -> String
greet {name} = "Hello " ++ name
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "Record destructuring should include all fields"
                            , details =
                                [ "This function parameter destructures some but not all record fields."
                                , "Consider destructuring all fields: age, name"
                                , "Missing fields: age"
                                ]
                            , under = "{name}"
                            }
                        ]
        , test "should report an error for anonymous record" <|
            \() ->
                """module A exposing (..)

greet : { name : String, age : Int } -> String
greet {name} = "Hello " ++ name
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "Record destructuring should include all fields"
                            , details =
                                [ "This function parameter destructures some but not all record fields."
                                , "Consider destructuring all fields: age, name"
                                , "Missing fields: age"
                                ]
                            , under = "{name}"
                            }
                        ]
        , test "should report an error for extensible record" <|
            \() ->
                """module A exposing (..)

greet : { a | name : String, age : Int } -> String
greet {name} = "Hello " ++ name
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "Record destructuring should include all fields"
                            , details =
                                [ "This function parameter destructures some but not all record fields."
                                , "Consider destructuring all fields: age, name"
                                , "Missing fields: age"
                                ]
                            , under = "{name}"
                            }
                        ]
        , test "should not report an error when function has no type annotation" <|
            \() ->
                """module A exposing (..)
greet {name} = "Hello " ++ name
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectNoErrors
        , test "should handle cross-module type resolution" <|
            \() ->
                [ """module Types exposing (Person)
type alias Person = { name : String, age : Int, email : String }
"""
                , """module Main exposing (greet)
import Types exposing (Person)
greet : Person -> String
greet {name} = "Hello " ++ name
"""
                ]
                    |> Review.Test.runOnModules rule
                    |> Review.Test.expectErrorsForModules
                        [ ( "Main"
                          , [ Review.Test.error
                                { message = "Record destructuring should include all fields"
                                , details =
                                    [ "This function parameter destructures some but not all record fields."
                                    , "Consider destructuring all fields: age, email, name"
                                    , "Missing fields: age, email"
                                    ]
                                , under = "{name}"
                                }
                            ]
                          )
                        ]
        , test "should handle cross-module type resolution with aliasing" <|
            \() ->
                [ """module Types exposing (Person)
type alias Person = { name : String, age : Int, email : String }
"""
                , """module Main exposing (greet)
import Types as T
greet : T.Person -> String
greet {name} = "Hello " ++ name
"""
                ]
                    |> Review.Test.runOnModules rule
                    |> Review.Test.expectErrorsForModules
                        [ ( "Main"
                          , [ Review.Test.error
                                { message = "Record destructuring should include all fields"
                                , details =
                                    [ "This function parameter destructures some but not all record fields."
                                    , "Consider destructuring all fields: age, email, name"
                                    , "Missing fields: age, email"
                                    ]
                                , under = "{name}"
                                }
                            ]
                          )
                        ]
        , test "should not report error when all cross-module fields are destructured" <|
            \() ->
                [ """module Types exposing (Person)
type alias Person = { name : String, age : Int }
"""
                , """module Main exposing (greet)
import Types exposing (Person)
greet : Person -> String
greet {name, age} = "Hello " ++ name
"""
                ]
                    |> Review.Test.runOnModules rule
                    |> Review.Test.expectNoErrors
        ]
