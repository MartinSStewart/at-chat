module EncoderDecoderNamingTest exposing (all)

import EncoderDecoderNaming
import Review.Test
import Test exposing (Test)


all : Test
all =
    Test.describe "EncoderDecoderNaming"
        [ Test.test "reports typeNameEncoder" <|
            \() ->
                """module A exposing (..)

userEncoder = ()
"""
                    |> String.replace "\u{000D}" ""
                    |> Review.Test.run EncoderDecoderNaming.rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "userEncoder should be named encodeUser"
                            , details = [ "Encoders should be named `encodeTypeName` instead of `typeNameEncoder` for consistency." ]
                            , under = "userEncoder"
                            }
                            |> Review.Test.whenFixed
                                """module A exposing (..)

encodeUser = ()
"""
                        ]
        , Test.test "reports typeNameDecoder" <|
            \() ->
                """module A exposing (..)

userDecoder = ()
"""
                    |> String.replace "\u{000D}" ""
                    |> Review.Test.run EncoderDecoderNaming.rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "userDecoder should be named decodeUser"
                            , details = [ "Decoders should be named `decodeTypeName` instead of `typeNameDecoder` for consistency." ]
                            , under = "userDecoder"
                            }
                            |> Review.Test.whenFixed
                                """module A exposing (..)

decodeUser = ()
"""
                        ]
        , Test.test "reports typeNameEncode" <|
            \() ->
                """module A exposing (..)

userEncode = ()
"""
                    |> String.replace "\u{000D}" ""
                    |> Review.Test.run EncoderDecoderNaming.rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "userEncode should be named encodeUser"
                            , details = [ "Encoders should be named `encodeTypeName` instead of `typeNameEncode` for consistency." ]
                            , under = "userEncode"
                            }
                            |> Review.Test.whenFixed
                                """module A exposing (..)

encodeUser = ()
"""
                        ]
        , Test.test "reports typeNameDecode" <|
            \() ->
                """module A exposing (..)

userDecode = ()
"""
                    |> String.replace "\u{000D}" ""
                    |> Review.Test.run EncoderDecoderNaming.rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "userDecode should be named decodeUser"
                            , details = [ "Decoders should be named `decodeTypeName` instead of `typeNameDecode` for consistency." ]
                            , under = "userDecode"
                            }
                            |> Review.Test.whenFixed
                                """module A exposing (..)

decodeUser = ()
"""
                        ]
        , Test.test "allows encodeTypeName" <|
            \() ->
                """module A exposing (..)

encodeUser = ()
"""
                    |> String.replace "\u{000D}" ""
                    |> Review.Test.run EncoderDecoderNaming.rule
                    |> Review.Test.expectNoErrors
        , Test.test "allows decodeTypeName" <|
            \() ->
                """module A exposing (..)

decodeUser = ()
"""
                    |> String.replace "\u{000D}" ""
                    |> Review.Test.run EncoderDecoderNaming.rule
                    |> Review.Test.expectNoErrors
        , Test.test "allows unrelated function names" <|
            \() ->
                """module A exposing (..)

someFunction = ()
"""
                    |> String.replace "\u{000D}" ""
                    |> Review.Test.run EncoderDecoderNaming.rule
                    |> Review.Test.expectNoErrors
        , Test.test "reports multi-word typeNameEncoder" <|
            \() ->
                """module A exposing (..)

chatMessageEncoder = ()
"""
                    |> String.replace "\u{000D}" ""
                    |> Review.Test.run EncoderDecoderNaming.rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "chatMessageEncoder should be named encodeChatMessage"
                            , details = [ "Encoders should be named `encodeTypeName` instead of `typeNameEncoder` for consistency." ]
                            , under = "chatMessageEncoder"
                            }
                            |> Review.Test.whenFixed
                                """module A exposing (..)

encodeChatMessage = ()
"""
                        ]
        , Test.test "fixes type signature along with declaration" <|
            \() ->
                """module A exposing (..)

quantityDecoder : Decoder (Quantity Float unit)
quantityDecoder = ()
"""
                    |> String.replace "\u{000D}" ""
                    |> Review.Test.run EncoderDecoderNaming.rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "quantityDecoder should be named decodeQuantity"
                            , details = [ "Decoders should be named `decodeTypeName` instead of `typeNameDecoder` for consistency." ]
                            , under = "quantityDecoder"
                            }
                            |> Review.Test.atExactly { start = { row = 4, column = 1 }, end = { row = 4, column = 16 } }
                            |> Review.Test.whenFixed
                                """module A exposing (..)

decodeQuantity : Decoder (Quantity Float unit)
decodeQuantity = ()
"""
                        ]
        , Test.test "fixes type signature for encoder" <|
            \() ->
                """module A exposing (..)

userEncoder : User -> Value
userEncoder = ()
"""
                    |> String.replace "\u{000D}" ""
                    |> Review.Test.run EncoderDecoderNaming.rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "userEncoder should be named encodeUser"
                            , details = [ "Encoders should be named `encodeTypeName` instead of `typeNameEncoder` for consistency." ]
                            , under = "userEncoder"
                            }
                            |> Review.Test.atExactly { start = { row = 4, column = 1 }, end = { row = 4, column = 12 } }
                            |> Review.Test.whenFixed
                                """module A exposing (..)

encodeUser : User -> Value
encodeUser = ()
"""
                        ]
        , Test.test "does not report bare Encoder or Decoder" <|
            \() ->
                """module A exposing (..)

encoder = ()
decoder = ()
"""
                    |> String.replace "\u{000D}" ""
                    |> Review.Test.run EncoderDecoderNaming.rule
                    |> Review.Test.expectNoErrors
        , Test.test "fixes same-module usage of renamed function" <|
            \() ->
                """module A exposing (..)

userEncoder = ()

foo = userEncoder
"""
                    |> String.replace "\u{000D}" ""
                    |> Review.Test.run EncoderDecoderNaming.rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "userEncoder should be named encodeUser"
                            , details = [ "Encoders should be named `encodeTypeName` instead of `typeNameEncoder` for consistency." ]
                            , under = "userEncoder"
                            }
                            |> Review.Test.atExactly { start = { row = 3, column = 1 }, end = { row = 3, column = 12 } }
                            |> Review.Test.whenFixed
                                """module A exposing (..)

encodeUser = ()

foo = encodeUser
"""
                        ]
        , Test.test "fixes cross-module usage of renamed function" <|
            \() ->
                [ """module A exposing (..)

userEncoder = ()
"""
                , """module B exposing (..)

import A

foo = A.userEncoder
"""
                ]
                    |> Review.Test.runOnModules EncoderDecoderNaming.rule
                    |> Review.Test.expectErrorsForModules
                        [ ( "A"
                          , [ Review.Test.error
                                { message = "userEncoder should be named encodeUser"
                                , details = [ "Encoders should be named `encodeTypeName` instead of `typeNameEncoder` for consistency." ]
                                , under = "userEncoder"
                                }
                                |> Review.Test.whenFixed
                                    """module A exposing (..)

encodeUser = ()
"""
                            ]
                          )
                        , ( "B"
                          , [ Review.Test.error
                                { message = "userEncoder should be named encodeUser"
                                , details = [ "Encoders should be named `encodeTypeName` instead of `typeNameEncoder` for consistency." ]
                                , under = "A.userEncoder"
                                }
                                |> Review.Test.whenFixed
                                    """module B exposing (..)

import A

foo = A.encodeUser
"""
                            ]
                          )
                        ]
        ]
