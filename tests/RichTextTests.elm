module RichTextTests exposing (test)

import Expect
import Id
import List.Nonempty exposing (Nonempty(..))
import PersonName exposing (PersonName)
import RichText exposing (EscapedChar(..), Modifiers(..), RichText(..))
import SeqDict
import String.Nonempty exposing (NonemptyString(..))
import Test exposing (Test)
import Unsafe
import Url exposing (Protocol(..), Url)


users : SeqDict.SeqDict (Id.Id a) { name : PersonName }
users =
    SeqDict.fromList [ ( Id.fromInt 123, { name = Unsafe.personName "a" } ), ( Id.fromInt 1234, { name = Unsafe.personName "a1" } ) ]


unsafeUrl : String -> Url
unsafeUrl url =
    case Url.fromString url of
        Just url2 ->
            url2

        Nothing ->
            Debug.todo "Invalid url"


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
        , Test.test "mention2" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString ' ' "@a1 ")
                    |> Expect.equal
                        (Nonempty (NormalText ' ' "") [ UserMention (Id.fromInt 1234), NormalText ' ' "" ])
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
        , Test.test "Parser url with trailing punctuation" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString 'G' "o to https://abc.com/. Click on the sign up.")
                    |> Expect.equal
                        (Nonempty
                            (NormalText 'G' "o to ")
                            [ Hyperlink (unsafeUrl "https://abc.com/")
                            , NormalText '.' " Click on the sign up."
                            ]
                        )
        , Test.test "Parser slightly malformed url with trailing punctuation" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString 'G' "o to https://abc.com?a=4. Click on the sign up.")
                    |> Expect.equal
                        (Nonempty
                            (NormalText 'G' "o to ")
                            [ Hyperlink { protocol = Https, host = "abc.com", path = "", port_ = Nothing, fragment = Nothing, query = Just "a=4" }
                            , NormalText '.' " Click on the sign up."
                            ]
                        )
        , Test.test "Parser url with trailing punctuation and no slash" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString 'G' "o to https://abc.com. Click on the sign up.")
                    |> Expect.equal
                        (Nonempty
                            (NormalText 'G' "o to ")
                            [ Hyperlink { protocol = Https, host = "abc.com", path = "", port_ = Nothing, fragment = Nothing, query = Nothing }
                            , NormalText '.' " Click on the sign up."
                            ]
                        )
        , Test.test "Parser spoilered url" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString 'G' "o to ||https://abc.com/||. Click on the sign up.")
                    |> Expect.equal
                        (Nonempty
                            (NormalText 'G' "o to ")
                            [ Spoiler (Nonempty (Hyperlink (unsafeUrl "https://abc.com/")) [])
                            , NormalText '.' " Click on the sign up."
                            ]
                        )
        , Test.test "Escape characters" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '\\' "*Bullet point 1\n\\*Bullet point 2")
                    |> Expect.equal
                        (Nonempty
                            (EscapedChar (EscapedModifier IsBold))
                            [ NormalText 'B' "ullet point 1\n"
                            , EscapedChar (EscapedModifier IsBold)
                            , NormalText 'B' "ullet point 2"
                            ]
                        )
        , Test.test "Escape characters 2" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '\\' "**Bullet point 1*\n\\*Bullet point 2")
                    |> Expect.equal
                        (Nonempty
                            (EscapedChar (EscapedModifier IsBold))
                            [ Bold (Nonempty (NormalText 'B' "ullet point 1") [])
                            , NormalText '\n' ""
                            , EscapedChar (EscapedModifier IsBold)
                            , NormalText 'B' "ullet point 2"
                            ]
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
