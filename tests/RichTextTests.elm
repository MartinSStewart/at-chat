module RichTextTests exposing (test)

import Expect
import Id
import List.Nonempty exposing (Nonempty(..))
import PersonName exposing (PersonName)
import RichText exposing (RichText(..))
import SeqDict
import String.Nonempty exposing (NonemptyString(..))
import Test exposing (Test)
import Unsafe


users : SeqDict.SeqDict (Id.Id a) { name : PersonName }
users =
    SeqDict.fromList [ ( Id.fromInt 123, { name = Unsafe.personName "a" } ) ]


test : Test
test =
    Test.describe
        "Rich text tests"
        [ Test.test "text" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString ' ' "abc ")
                    |> Expect.equal (Nonempty (NormalText ' ' "abc ") [])
        , Test.test "mention" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString ' ' "@a ")
                    |> Expect.equal
                        (Nonempty (NormalText ' ' "") [ UserMention (Id.fromInt 123), NormalText ' ' "" ])
        , Test.test "not bold" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString ' ' "* abc *")
                    |> Expect.equal (Nonempty (NormalText ' ' "* abc *") [])
        , Test.test "bold" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString ' ' "*abc *")
                    |> Expect.equal
                        (Nonempty
                            (NormalText ' ' "")
                            [ Bold (Nonempty (NormalText 'a' "bc ") []) ]
                        )
        , Test.test "*abc_123" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '*' "abc_123")
                    |> Expect.equal (Nonempty (NormalText '*' "abc_123") [])
        , Test.test "*a*b" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '*' "a*b")
                    |> Expect.equal (Nonempty (Bold (Nonempty (NormalText 'a' "") [])) [ NormalText 'b' "" ])
        , Test.test "_a*a_" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '_' "a*a_")
                    |> Expect.equal (Nonempty (Italic (Nonempty (NormalText 'a' "*a") [])) [])
        , Test.test "_*abc*_" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '_' "*abc*_")
                    |> Expect.equal
                        (Nonempty
                            (Italic
                                (Nonempty
                                    (Bold (Nonempty (NormalText 'a' "bc") []))
                                    []
                                )
                            )
                            []
                        )
        , Test.test "[!1]" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '[' "!1]")
                    |> Expect.equal
                        (Nonempty (AttachedFile (Id.fromInt 1)) [])
        , Test.test "👨\u{200D}👩\u{200D}👧\u{200D}👦_*abc*_" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '👨' "\u{200D}👩\u{200D}👧\u{200D}👦_*abc*_")
                    |> Expect.equal
                        (Nonempty
                            (NormalText '👨' "\u{200D}👩\u{200D}👧\u{200D}👦")
                            [ Italic
                                (Nonempty
                                    (Bold (Nonempty (NormalText 'a' "bc") []))
                                    []
                                )
                            ]
                        )
        , Test.test "strikethrough" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '~' "~abc~~")
                    |> Expect.equal
                        (Nonempty
                            (Strikethrough (Nonempty (NormalText 'a' "bc") []))
                            []
                        )
        , Test.test "not strikethrough" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '~' " abc ~")
                    |> Expect.equal (Nonempty (NormalText '~' " abc ~") [])
        , Test.test "~~a~~b" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '~' "~a~~b")
                    |> Expect.equal (Nonempty (Strikethrough (Nonempty (NormalText 'a' "") [])) [ NormalText 'b' "" ])
        , Test.test "_~~abc~~_" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '_' "~~abc~~_")
                    |> Expect.equal
                        (Nonempty
                            (Italic
                                (Nonempty
                                    (Strikethrough (Nonempty (NormalText 'a' "bc") []))
                                    []
                                )
                            )
                            []
                        )

        --, Test.test " ~~~~" <|
        --    \_ ->
        --        RichText.fromNonemptyString users (NonemptyString ' ' "~~~~")
        --            |> Expect.equal (Nonempty (NormalText ' ' "~~~~") [])
        --, Test.fuzz markdownStringFuzzer "Round trip" <|
        --    \text ->
        --        RichText.fromNonemptyString users text
        --            |> RichText.toString users
        --            |> Expect.equal (String.Nonempty.toString text)
        ]
