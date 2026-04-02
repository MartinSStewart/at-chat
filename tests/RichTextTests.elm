module RichTextTests exposing (test)

import Expect
import Fuzz exposing (Fuzzer)
import Id
import List.Nonempty exposing (Nonempty(..))
import PersonName exposing (PersonName)
import RichText exposing (EscapedChar(..), RichText(..))
import RichTextOld
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


stringFuzzer : Fuzzer String
stringFuzzer =
    Fuzz.oneOfValues
        [ "*"
        , "|"
        , "b"
        , "h"
        , "~"
        , "_"
        , " "
        , "https://abc.com"
        , "http://abc.com"
        , "https://abc.com/"
        , "@"
        , "@a "
        , "@a1 "
        , "`"
        , "```"
        , "\n"
        , "\u{000D}"
        , "\\"
        , "["
        , "[!1]"
        ]


fuzzer : Fuzz.Fuzzer NonemptyString
fuzzer =
    Fuzz.list stringFuzzer
        |> Fuzz.map (\list -> String.concat list |> String.Nonempty.fromString |> Maybe.withDefault (NonemptyString ' ' ""))


test : Test
test =
    Test.describe
        "Rich text tests"
        [ Test.fuzz
            fuzzer
            "Check for regressions"
            (\text -> Expect.equal (RichTextOld.fromNonemptyString users text) (RichText.fromNonemptyString users text))
        , Test.test "text" <|
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
        , Test.test "mention3" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString ' ' "@a \\")
                    |> Expect.equal
                        (Nonempty (NormalText ' ' "") [ UserMention (Id.fromInt 123), NormalText ' ' "\\" ])
        , Test.test "attachment" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '[' "!1]\\")
                    |> Expect.equal
                        (Nonempty (AttachedFile (Id.fromInt 1)) [ NormalText '\\' "" ])
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
                            (EscapedChar EscapedBold)
                            [ NormalText 'B' "ullet point 1\n"
                            , EscapedChar EscapedBold
                            , NormalText 'B' "ullet point 2"
                            ]
                        )
        , Test.test "Escape characters 2" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '\\' "**Bullet point 1*\n\\*Bullet point 2")
                    |> Expect.equal
                        (Nonempty
                            (EscapedChar EscapedBold)
                            [ Bold (Nonempty (NormalText 'B' "ullet point 1") [])
                            , NormalText '\n' ""
                            , EscapedChar EscapedBold
                            , NormalText 'B' "ullet point 2"
                            ]
                        )
        , Test.test "inline code" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '`' "hello`")
                    |> Expect.equal (Nonempty (InlineCode 'h' "ello") [])
        , Test.test "inline code with surrounding text" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString 'a' " `code` b")
                    |> Expect.equal
                        (Nonempty (NormalText 'a' " ") [ InlineCode 'c' "ode", NormalText ' ' "b" ])
        , Test.test "empty inline code" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '`' "`")
                    |> Expect.equal (Nonempty (NormalText '`' "`") [])
        , Test.test "code block no language" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '`' "``hello```")
                    |> Expect.equal (Nonempty (CodeBlock RichText.NoLanguage "hello") [])
        , Test.test "code block with language" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '`' "``elm\nx = 1```")
                    |> Expect.equal
                        (Nonempty
                            (CodeBlock (RichText.Language (NonemptyString 'e' "lm")) "x = 1")
                            []
                        )
        , Test.test "empty code block" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '`' "`````")
                    |> Expect.equal (Nonempty (NormalText '`' "`````") [])
        , Test.test "spoiler" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '|' "|secret||")
                    |> Expect.equal
                        (Nonempty (Spoiler (Nonempty (NormalText 's' "ecret") [])) [])
        , Test.test "not spoiler - no closing" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '|' "|hello")
                    |> Expect.equal (Nonempty (NormalText '|' "|hello") [])
        , Test.test "underline" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '_' "_hello__")
                    |> Expect.equal
                        (Nonempty (Underline (Nonempty (NormalText 'h' "ello") [])) [])
        , Test.test "bold inside strikethrough" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '~' "~*abc*~~")
                    |> Expect.equal
                        (Nonempty
                            (Strikethrough (Nonempty (Bold (Nonempty (NormalText 'a' "bc") [])) []))
                            []
                        )
        , Test.test "mention at start" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '@' "a rest")
                    |> Expect.equal
                        (Nonempty (UserMention (Id.fromInt 123)) [ NormalText ' ' "rest" ])
        , Test.test "mention not matching any user" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '@' "zzz")
                    |> Expect.equal (Nonempty (NormalText '@' "zzz") [])
        , Test.test "mention longest match wins" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '@' "a1 end")
                    |> Expect.equal
                        (Nonempty (UserMention (Id.fromInt 1234)) [ NormalText ' ' "end" ])
        , Test.test "multiple mentions" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '@' "a @a1")
                    |> Expect.equal
                        (Nonempty (UserMention (Id.fromInt 123))
                            [ NormalText ' ' ""
                            , UserMention (Id.fromInt 1234)
                            ]
                        )
        , Test.test "url standalone" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString 'h' "ttps://example.com/")
                    |> Expect.equal
                        (Nonempty (Hyperlink (unsafeUrl "https://example.com/")) [])
        , Test.test "http url" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString 'h' "ttp://example.com/")
                    |> Expect.equal
                        (Nonempty (Hyperlink { protocol = Http, host = "example.com", path = "/", port_ = Nothing, fragment = Nothing, query = Nothing }) [])
        , Test.test "url with trailing comma" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString 'h' "ttps://abc.com/,")
                    |> Expect.equal
                        (Nonempty (Hyperlink (unsafeUrl "https://abc.com/")) [ NormalText ',' "" ])
        , Test.test "url with trailing paren" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString 'h' "ttps://abc.com/)")
                    |> Expect.equal
                        (Nonempty (Hyperlink (unsafeUrl "https://abc.com/")) [ NormalText ')' "" ])
        , Test.test "url with query and fragment" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString 'h' "ttps://abc.com/path?q=1#frag")
                    |> Expect.equal
                        (Nonempty
                            (Hyperlink
                                { protocol = Https
                                , host = "abc.com"
                                , path = "/path"
                                , port_ = Nothing
                                , fragment = Just "frag"
                                , query = Just "q=1"
                                }
                            )
                            []
                        )
        , Test.test "bold with mention inside" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '*' "@a*")
                    |> Expect.equal
                        (Nonempty (Bold (Nonempty (UserMention (Id.fromInt 123)) [])) [])
        , Test.test "escape backslash" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '\\' "\\hello")
                    |> Expect.equal
                        (Nonempty (EscapedChar EscapedBackslash) [ NormalText 'h' "ello" ])
        , Test.test "escape backtick" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '\\' "`hello")
                    |> Expect.equal
                        (Nonempty (EscapedChar EscapedBacktick) [ NormalText 'h' "ello" ])
        , Test.test "escape at symbol" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '\\' "@a rest")
                    |> Expect.equal
                        (Nonempty (EscapedChar EscapedAtSymbol) [ NormalText 'a' " rest" ])
        , Test.test "escape square bracket" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '\\' "[hello")
                    |> Expect.equal
                        (Nonempty (EscapedChar EscapedSquareBracket) [ NormalText 'h' "ello" ])
        , Test.test "escape italic" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '\\' "_hello")
                    |> Expect.equal
                        (Nonempty (EscapedChar EscapedItalic) [ NormalText 'h' "ello" ])
        , Test.test "escape strikethrough" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '\\' "~hello")
                    |> Expect.equal
                        (Nonempty (EscapedChar EscapedStrikethrough) [ NormalText 'h' "ello" ])
        , Test.test "backslash before non-special char" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '\\' "nhello")
                    |> Expect.equal
                        (Nonempty (NormalText '\\' "nhello") [])
        , Test.test "attached file with larger id" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '[' "!999]")
                    |> Expect.equal
                        (Nonempty (AttachedFile (Id.fromInt 999)) [])
        , Test.test "attached file with surrounding text" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString 'h' "i [!5] bye")
                    |> Expect.equal
                        (Nonempty (NormalText 'h' "i ") [ AttachedFile (Id.fromInt 5), NormalText ' ' "bye" ])
        , Test.test "just bold markers no content" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '*' "*")
                    |> Expect.equal (Nonempty (NormalText '*' "*") [])
        , Test.test "just italic markers no content" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '_' "_")
                    |> Expect.equal (Nonempty (NormalText '_' "_") [])
        , Test.test "nested bold inside italic inside strikethrough" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '~' "~_*abc*_~~")
                    |> Expect.equal
                        (Nonempty
                            (Strikethrough
                                (Nonempty
                                    (Italic
                                        (Nonempty
                                            (Bold (Nonempty (NormalText 'a' "bc") []))
                                            []
                                        )
                                    )
                                    []
                                )
                            )
                            []
                        )
        , Test.test "bold then italic separate" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '*' "a*_b_")
                    |> Expect.equal
                        (Nonempty (Bold (Nonempty (NormalText 'a' "") []))
                            [ Italic (Nonempty (NormalText 'b' "") []) ]
                        )
        , Test.test "newlines in text" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString 'a' "\nb\nc")
                    |> Expect.equal (Nonempty (NormalText 'a' "\nb\nc") [])
        , Test.test "bold across newline" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '*' "a\nb*")
                    |> Expect.equal
                        (Nonempty (Bold (Nonempty (NormalText 'a' "\nb") [])) [])
        , Test.test "inline code preserves special chars" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '`' "*bold* _italic_`")
                    |> Expect.equal (Nonempty (InlineCode '*' "bold* _italic_") [])
        , Test.test "multiple attached files" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '[' "!1][!2]")
                    |> Expect.equal
                        (Nonempty (AttachedFile (Id.fromInt 1)) [ AttachedFile (Id.fromInt 2) ])
        , Test.test "spoiler with bold inside" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '|' "|*abc*||")
                    |> Expect.equal
                        (Nonempty
                            (Spoiler (Nonempty (Bold (Nonempty (NormalText 'a' "bc") [])) []))
                            []
                        )
        , Test.test "single char bold" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '*' "a*")
                    |> Expect.equal (Nonempty (Bold (Nonempty (NormalText 'a' "") [])) [])
        , Test.test "single char italic" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '_' "a_")
                    |> Expect.equal (Nonempty (Italic (Nonempty (NormalText 'a' "") [])) [])
        , Test.test "url between text" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString 'a' " https://x.com/ b")
                    |> Expect.equal
                        (Nonempty (NormalText 'a' " ")
                            [ Hyperlink (unsafeUrl "https://x.com/")
                            , NormalText ' ' "b"
                            ]
                        )
        , Test.test "code block with multiline content" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '`' "``elm\nx = 1\ny = 2```")
                    |> Expect.equal
                        (Nonempty
                            (CodeBlock (RichText.Language (NonemptyString 'e' "lm")) "x = 1\ny = 2")
                            []
                        )
        , Test.test "escape prevents bold" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '\\' "*abc")
                    |> Expect.equal
                        (Nonempty (EscapedChar EscapedBold) [ NormalText 'a' "bc" ])
        , Test.test "multiple escapes in a row" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '\\' "*\\*")
                    |> Expect.equal
                        (Nonempty (EscapedChar EscapedBold)
                            [ EscapedChar EscapedBold ]
                        )
        , Test.test "bold with spaces inside" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '*' "a b c*")
                    |> Expect.equal
                        (Nonempty (Bold (Nonempty (NormalText 'a' " b c") [])) [])
        , Test.test "incomplete attached file syntax" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString '[' "!abc]")
                    |> Expect.equal (Nonempty (NormalText '[' "!abc]") [])
        , Test.test "url with multiple trailing dots" <|
            \_ ->
                RichText.fromNonemptyString users (NonemptyString 'h' "ttps://abc.com/...")
                    |> Expect.equal
                        (Nonempty (Hyperlink (unsafeUrl "https://abc.com/")) [ NormalText '.' ".." ])
        ]
