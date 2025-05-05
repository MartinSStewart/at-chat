module RichTextTests exposing (..)

import Expect
import Fuzz
import Id
import List.Nonempty exposing (Nonempty(..))
import PersonName exposing (PersonName)
import RichText exposing (RichText(..))
import SeqDict
import String.Nonempty exposing (NonemptyString(..))
import Test
import Unsafe


users : SeqDict.SeqDict (Id.Id a) { name : PersonName }
users =
    SeqDict.fromList [ ( Id.fromInt 123, { name = Unsafe.personName "a" } ) ]


test =
    Test.describe
        "Rich text tests"
        [ Test.test "text" <|
            \_ ->
                RichText.fromString users (NonemptyString ' ' "abc ")
                    |> Expect.equal (Nonempty (NormalText ' ' "abc ") [])
        , Test.test "mention" <|
            \_ ->
                RichText.fromString users (NonemptyString ' ' "@a ")
                    |> Expect.equal
                        (Nonempty (NormalText ' ' "") [ UserMention (Id.fromInt 123), NormalText ' ' "" ])
        , Test.test "not bold" <|
            \_ ->
                RichText.fromString users (NonemptyString ' ' "* abc *")
                    |> Expect.equal (Nonempty (NormalText ' ' "* abc *") [])
        , Test.test "bold" <|
            \_ ->
                RichText.fromString users (NonemptyString ' ' "*abc *")
                    |> Expect.equal
                        (Nonempty
                            (NormalText ' ' "")
                            [ Bold (Nonempty (NormalText 'a' "bc ") []) ]
                        )
        , Test.test "*abc_123" <|
            \_ ->
                RichText.fromString users (NonemptyString '*' "abc_123")
                    |> Expect.equal (Nonempty (NormalText '*' "abc_123") [])
        , Test.test "*a*b" <|
            \_ ->
                RichText.fromString users (NonemptyString '*' "a*b")
                    |> Expect.equal (Nonempty (Bold (Nonempty (NormalText 'a' "") [])) [ NormalText 'b' "" ])
        , Test.test "_a*a_" <|
            \_ ->
                RichText.fromString users (NonemptyString '_' "a*a_")
                    |> Expect.equal (Nonempty (Italic (Nonempty (NormalText 'a' "*a") [])) [])
        , Test.fuzz markdownStringFuzzer "Round trip" <|
            \text ->
                RichText.fromString users text
                    |> RichText.toString users
                    |> Expect.equal (String.Nonempty.toString text)
        ]


markdownStringFuzzer : Fuzz.Fuzzer NonemptyString
markdownStringFuzzer =
    Fuzz.list
        (Fuzz.oneOfValues
            [ "a"
            , " "
            , "*"
            , "@"
            , "_"
            , "__"
            ]
        )
        |> Fuzz.map
            (\list ->
                case String.concat list |> String.Nonempty.fromString of
                    Just nonempty ->
                        nonempty

                    Nothing ->
                        NonemptyString ' ' ""
            )
