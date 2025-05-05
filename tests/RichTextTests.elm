module RichTextTests exposing (..)

import Expect
import Fuzz
import List.Nonempty exposing (Nonempty(..))
import Parser
import RichText exposing (RichText(..))
import SeqDict
import String.Nonempty exposing (NonemptyString(..))
import Test


test =
    Test.describe
        "Rich text tests"
        [ Test.test "text" <|
            \_ ->
                RichText.fromString (NonemptyString ' ' "abc ")
                    |> Expect.equal
                        (Nonempty (NormalText (NonemptyString ' ' "abc ")) [])
        , Test.test "not bold" <|
            \_ ->
                RichText.fromString (NonemptyString ' ' "* abc *")
                    |> Expect.equal
                        (Nonempty (NormalText (NonemptyString ' ' "* abc *")) [])
        , Test.test "bold" <|
            \_ ->
                RichText.fromString (NonemptyString ' ' "*abc *")
                    |> Expect.equal
                        (Nonempty
                            (NormalText (NonemptyString ' ' ""))
                            [ Bold (Nonempty (NormalText (NonemptyString 'a' "bc ")) []) ]
                        )
        , Test.test "*abc_123" <|
            \_ ->
                RichText.fromString (NonemptyString '*' "abc_123")
                    |> Expect.equal
                        (Nonempty
                            (NormalText (NonemptyString '*' "abc_123"))
                            []
                        )
        , Test.test "*a*b" <|
            \_ ->
                RichText.fromString (NonemptyString '*' "a*b")
                    |> Expect.equal
                        (Nonempty
                            (Bold (Nonempty (NormalText (NonemptyString 'a' "")) []))
                            [ NormalText (NonemptyString 'b' "") ]
                        )

        --, Test.fuzz markdownStringFuzzer "Round trip" <|
        --    \text ->
        --        RichText.fromString text
        --            |> RichText.toString SeqDict.empty
        --            |> Expect.equal (String.Nonempty.toString text)
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
