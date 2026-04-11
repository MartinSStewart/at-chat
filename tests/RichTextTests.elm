module RichTextTests exposing (test)

import Expect
import Fuzz exposing (Fuzzer)
import Id exposing (Id)
import List.Nonempty exposing (Nonempty(..))
import PersonName exposing (PersonName)
import RichText exposing (EscapedChar(..), Language(..), RichText(..))
import SeqDict
import String.Nonempty exposing (NonemptyString(..))
import Test exposing (Test)
import Unsafe
import Url exposing (Protocol(..), Url)


users : SeqDict.SeqDict (Id a) { name : PersonName }
users =
    SeqDict.fromList [ ( Id.fromInt 1234, { name = Unsafe.personName "a1" } ), ( Id.fromInt 123, { name = Unsafe.personName "a" } ), ( Id.fromInt 12345, { name = Unsafe.personName "aa" } ) ]


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
        , "https://"
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
        , "\u{200B}"
        , "\u{200C}"
        , "\u{200D}"
        , "\u{2060}"
        , "\n\u{200C}\u{200B}\n\n"
        , "\n\u{200B}"
        , "]("
        , ")"
        , "[link](https://abc.com/)"
        , "[link](https://abc.com)"
        ]


fuzzer : Fuzzer NonemptyString
fuzzer =
    Fuzz.list stringFuzzer
        |> Fuzz.map (\list -> String.concat list |> String.Nonempty.fromString |> Maybe.withDefault (NonemptyString ' ' ""))


test : Test
test =
    Test.describe
        "Rich text tests"
        [ --Test.fuzz
          --    fuzzer
          --    "Check for regressions"
          --    (\text -> Expect.equal (RichTextOld.fromNonemptyString users text) (RichText.fromNonemptyString users text))
          fromNonemptyStringTest "https://abc.com|\\" (Nonempty (Hyperlink { fragment = Nothing, host = "abc.com", path = "", port_ = Nothing, protocol = Https, query = Nothing }) [ NormalText '|' "\\" ])
        , fromNonemptyStringTest " abc " (Nonempty (NormalText ' ' "abc ") [])
        , fromNonemptyStringTest
            " @a "
            (Nonempty (NormalText ' ' "") [ UserMention (Id.fromInt 123), NormalText ' ' "" ])
        , fromNonemptyStringTest
            " @a1 "
            (Nonempty (NormalText ' ' "") [ UserMention (Id.fromInt 1234), NormalText ' ' "" ])
        , fromNonemptyStringTest
            " @a \\"
            (Nonempty (NormalText ' ' "") [ UserMention (Id.fromInt 123), NormalText ' ' "\\" ])
        , fromNonemptyStringTest "[!1]\\" (Nonempty (AttachedFile (Id.fromInt 1)) [ NormalText '\\' "" ])
        , fromNonemptyStringTest " * abc *" (Nonempty (NormalText ' ' "* abc *") [])
        , fromNonemptyStringTest " *abc *" (Nonempty (NormalText ' ' "") [ Bold (Nonempty (NormalText 'a' "bc ") []) ])
        , fromNonemptyStringTest "*abc_123" (Nonempty (NormalText '*' "abc_123") [])
        , fromNonemptyStringTest "*a*b" (Nonempty (Bold (Nonempty (NormalText 'a' "") [])) [ NormalText 'b' "" ])
        , fromNonemptyStringTest "_a*a_" (Nonempty (Italic (Nonempty (NormalText 'a' "*a") [])) [])
        , fromNonemptyStringTest
            "_*abc*_"
            (Nonempty (Italic (Nonempty (Bold (Nonempty (NormalText 'a' "bc") [])) [])) [])
        , fromNonemptyStringTest "[!1]" (Nonempty (AttachedFile (Id.fromInt 1)) [])
        , fromNonemptyStringTest "👨\u{200D}👩\u{200D}👧\u{200D}👦_*abc*_"
            (Nonempty
                (NormalText '👨' "\u{200D}👩\u{200D}👧\u{200D}👦")
                [ Italic (Nonempty (Bold (Nonempty (NormalText 'a' "bc") [])) []) ]
            )
        , fromNonemptyStringTest
            "~~abc~~"
            (Nonempty
                (Strikethrough (Nonempty (NormalText 'a' "bc") []))
                []
            )
        , fromNonemptyStringTest "~ abc ~" (Nonempty (NormalText '~' " abc ~") [])
        , fromNonemptyStringTest "~~a~~b" (Nonempty (Strikethrough (Nonempty (NormalText 'a' "") [])) [ NormalText 'b' "" ])
        , fromNonemptyStringTest
            "_~~abc~~_"
            (Nonempty (Italic (Nonempty (Strikethrough (Nonempty (NormalText 'a' "bc") [])) [])) [])
        , fromNonemptyStringTest
            "Go to https://abc.com/. Click on the sign up."
            (Nonempty
                (NormalText 'G' "o to ")
                [ Hyperlink (unsafeUrl "https://abc.com/")
                , NormalText '.' " Click on the sign up."
                ]
            )
        , fromNonemptyStringTest
            "Go to https://abc.com?a=4. Click on the sign up."
            (Nonempty
                (NormalText 'G' "o to ")
                [ Hyperlink { protocol = Https, host = "abc.com", path = "", port_ = Nothing, fragment = Nothing, query = Just "a=4" }
                , NormalText '.' " Click on the sign up."
                ]
            )
        , fromNonemptyStringTest
            "Go to https://abc.com. Click on the sign up."
            (Nonempty
                (NormalText 'G' "o to ")
                [ Hyperlink { protocol = Https, host = "abc.com", path = "", port_ = Nothing, fragment = Nothing, query = Nothing }
                , NormalText '.' " Click on the sign up."
                ]
            )
        , fromNonemptyStringTest
            "Go to ||https://abc.com/||. Click on the sign up."
            (Nonempty
                (NormalText 'G' "o to ")
                [ Spoiler (Nonempty (Hyperlink (unsafeUrl "https://abc.com/")) [])
                , NormalText '.' " Click on the sign up."
                ]
            )
        , fromNonemptyStringTest
            "\\*Bullet point 1\n\\*Bullet point 2"
            (Nonempty
                (EscapedChar EscapedBold)
                [ NormalText 'B' "ullet point 1\n"
                , EscapedChar EscapedBold
                , NormalText 'B' "ullet point 2"
                ]
            )
        , fromNonemptyStringTest
            "\\**Bullet point 1*\n\\*Bullet point 2"
            (Nonempty
                (EscapedChar EscapedBold)
                [ Bold (Nonempty (NormalText 'B' "ullet point 1") [])
                , NormalText '\n' ""
                , EscapedChar EscapedBold
                , NormalText 'B' "ullet point 2"
                ]
            )
        , fromNonemptyStringTest "`hello`" (Nonempty (InlineCode 'h' "ello") [])
        , fromNonemptyStringTest
            "a `code` b"
            (Nonempty (NormalText 'a' " ") [ InlineCode 'c' "ode", NormalText ' ' "b" ])
        , fromNonemptyStringTest "``" (Nonempty (NormalText '`' "`") [])
        , fromNonemptyStringTest "```hello```" (Nonempty (CodeBlock RichText.NoLanguage "hello") [])
        , fromNonemptyStringTest
            "```elm\nx = 1```"
            (Nonempty (CodeBlock (RichText.Language (NonemptyString 'e' "lm")) "x = 1") [])
        , fromNonemptyStringTest "``````" (Nonempty (NormalText '`' "`````") [])
        , fromNonemptyStringTest "||secret||" (Nonempty (Spoiler (Nonempty (NormalText 's' "ecret") [])) [])
        , fromNonemptyStringTest "||hello" (Nonempty (NormalText '|' "|hello") [])
        , fromNonemptyStringTest "__hello__"
            (Nonempty (Underline (Nonempty (NormalText 'h' "ello") [])) [])
        , fromNonemptyStringTest
            "~~*abc*~~"
            (Nonempty (Strikethrough (Nonempty (Bold (Nonempty (NormalText 'a' "bc") [])) [])) [])
        , fromNonemptyStringTest "@a rest" (Nonempty (UserMention (Id.fromInt 123)) [ NormalText ' ' "rest" ])
        , fromNonemptyStringTest "@zzz" (Nonempty (NormalText '@' "zzz") [])
        , fromNonemptyStringTest "@a1 end" (Nonempty (UserMention (Id.fromInt 1234)) [ NormalText ' ' "end" ])
        , fromNonemptyStringTest
            "@a @a1"
            (Nonempty (UserMention (Id.fromInt 123)) [ NormalText ' ' "", UserMention (Id.fromInt 1234) ])
        , fromNonemptyStringTest "https://example.com/" (Nonempty (Hyperlink (unsafeUrl "https://example.com/")) [])
        , fromNonemptyStringTest "ahttps://example.com/" (Nonempty (NormalText 'a' "") [ Hyperlink (unsafeUrl "https://example.com/") ])
        , fromNonemptyStringTest
            "_https://example.com/_"
            (Nonempty (Italic (Nonempty (Hyperlink (unsafeUrl "https://example.com/")) [])) [])
        , fromNonemptyStringTest "https://example.com/_" (Nonempty (Hyperlink (unsafeUrl "https://example.com/_")) [])
        , fromNonemptyStringTest
            "http://example.com/"
            (Nonempty
                (Hyperlink
                    { protocol = Http
                    , host = "example.com"
                    , path = "/"
                    , port_ = Nothing
                    , fragment = Nothing
                    , query = Nothing
                    }
                )
                []
            )
        , fromNonemptyStringTest
            "https://abc.com/,"
            (Nonempty (Hyperlink (unsafeUrl "https://abc.com/")) [ NormalText ',' "" ])
        , fromNonemptyStringTest
            "https://abc.com/)"
            (Nonempty (Hyperlink (unsafeUrl "https://abc.com/")) [ NormalText ')' "" ])
        , fromNonemptyStringTest
            "https://abc.com/path?q=1#frag"
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
        , fromNonemptyStringTest "*@a*" (Nonempty (Bold (Nonempty (UserMention (Id.fromInt 123)) [])) [])
        , fromNonemptyStringTest "\\\\hello" (Nonempty (EscapedChar EscapedBackslash) [ NormalText 'h' "ello" ])
        , fromNonemptyStringTest "\\`hello" (Nonempty (EscapedChar EscapedBacktick) [ NormalText 'h' "ello" ])
        , fromNonemptyStringTest "\\@a rest" (Nonempty (EscapedChar EscapedAtSymbol) [ NormalText 'a' " rest" ])
        , fromNonemptyStringTest "\\[hello" (Nonempty (EscapedChar EscapedSquareBracket) [ NormalText 'h' "ello" ])
        , fromNonemptyStringTest "\\_hello" (Nonempty (EscapedChar EscapedItalic) [ NormalText 'h' "ello" ])
        , fromNonemptyStringTest "\\~hello" (Nonempty (EscapedChar EscapedStrikethrough) [ NormalText 'h' "ello" ])
        , fromNonemptyStringTest "\\nhello" (Nonempty (NormalText '\\' "nhello") [])
        , fromNonemptyStringTest "[!999]" (Nonempty (AttachedFile (Id.fromInt 999)) [])
        , fromNonemptyStringTest
            "hi [!5] bye"
            (Nonempty (NormalText 'h' "i ") [ AttachedFile (Id.fromInt 5), NormalText ' ' "bye" ])
        , fromNonemptyStringTest "**" (Nonempty (NormalText '*' "*") [])
        , fromNonemptyStringTest "__" (Nonempty (NormalText '_' "_") [])
        , fromNonemptyStringTest
            "~~_*abc*_~~"
            (Nonempty (Strikethrough (Nonempty (Italic (Nonempty (Bold (Nonempty (NormalText 'a' "bc") [])) [])) [])) [])
        , fromNonemptyStringTest
            "*a*_b_"
            (Nonempty (Bold (Nonempty (NormalText 'a' "") [])) [ Italic (Nonempty (NormalText 'b' "") []) ])
        , fromNonemptyStringTest "a\nb\nc" (Nonempty (NormalText 'a' "\nb\nc") [])
        , fromNonemptyStringTest "*a\nb*" (Nonempty (Bold (Nonempty (NormalText 'a' "\nb") [])) [])
        , fromNonemptyStringTest "`*bold* _italic_`" (Nonempty (InlineCode '*' "bold* _italic_") [])
        , fromNonemptyStringTest "[!1][!2]" (Nonempty (AttachedFile (Id.fromInt 1)) [ AttachedFile (Id.fromInt 2) ])
        , fromNonemptyStringTest
            "||*abc*||"
            (Nonempty (Spoiler (Nonempty (Bold (Nonempty (NormalText 'a' "bc") [])) [])) [])
        , fromNonemptyStringTest "*a*" (Nonempty (Bold (Nonempty (NormalText 'a' "") [])) [])
        , fromNonemptyStringTest "_a_" (Nonempty (Italic (Nonempty (NormalText 'a' "") [])) [])
        , fromNonemptyStringTest
            "a https://x.com/ b"
            (Nonempty (NormalText 'a' " ") [ Hyperlink (unsafeUrl "https://x.com/"), NormalText ' ' "b" ])
        , fromNonemptyStringTest
            "```elm\nx = 1\ny = 2```"
            (Nonempty (CodeBlock (RichText.Language (NonemptyString 'e' "lm")) "x = 1\ny = 2") [])
        , fromNonemptyStringTest "\\*abc" (Nonempty (EscapedChar EscapedBold) [ NormalText 'a' "bc" ])
        , fromNonemptyStringTest "\\*\\*" (Nonempty (EscapedChar EscapedBold) [ EscapedChar EscapedBold ])
        , fromNonemptyStringTest "*a b c*" (Nonempty (Bold (Nonempty (NormalText 'a' " b c") [])) [])
        , fromNonemptyStringTest "[!abc]" (Nonempty (NormalText '[' "!abc]") [])
        , fromNonemptyStringTest
            "https://abc.com/..."
            (Nonempty (Hyperlink (unsafeUrl "https://abc.com/")) [ NormalText '.' ".." ])
        , fromNonemptyStringTest "```a\n```" (Nonempty (CodeBlock NoLanguage "a\n") [])
        , fromNonemptyStringTest "````\n```" (Nonempty (CodeBlock NoLanguage "`\n") [])
        , fromNonemptyStringTest "```*\n```" (Nonempty (CodeBlock NoLanguage "*\n") [])
        , fromNonemptyStringTest "||||" (Nonempty (NormalText '|' "|||") [])
        , fromNonemptyStringTest "~~~~" (Nonempty (NormalText '~' "~~~") [])
        , fromNonemptyStringTest "____" (Nonempty (NormalText '_' "___") [])
        , fromNonemptyStringTest
            "[click here](https://example.com/)"
            (Nonempty (MarkdownLink (NonemptyString 'c' "lick here") (unsafeUrl "https://example.com/")) [])
        , fromNonemptyStringTest
            "go to [my site](https://abc.com/) now"
            (Nonempty (NormalText 'g' "o to ")
                [ MarkdownLink (NonemptyString 'm' "y site") { protocol = Https, host = "abc.com", path = "/", port_ = Nothing, fragment = Nothing, query = Nothing }
                , NormalText ' ' "now"
                ]
            )
        , fromNonemptyStringTest
            "[docs](http://example.com/path?q=1#frag)"
            (Nonempty
                (MarkdownLink (NonemptyString 'd' "ocs")
                    { protocol = Http
                    , host = "example.com"
                    , path = "/path"
                    , port_ = Nothing
                    , fragment = Just "frag"
                    , query = Just "q=1"
                    }
                )
                []
            )
        , fromNonemptyStringTest
            "[](https://example.com/)"
            (Nonempty (NormalText '[' "](")
                [ Hyperlink (unsafeUrl "https://example.com/")
                , NormalText ')' ""
                ]
            )
        , fromNonemptyStringTest "[alias](notaurl)" (Nonempty (NormalText '[' "alias](notaurl)") [])
        , fromNonemptyStringTest
            "[alias](https://example.com/"
            (Nonempty (NormalText '[' "alias](")
                [ Hyperlink { protocol = Https, host = "example.com", path = "/", port_ = Nothing, fragment = Nothing, query = Nothing }
                ]
            )
        , fromNonemptyStringTest "[alias" (Nonempty (NormalText '[' "alias") [])
        , fromNonemptyStringTest
            "*[link](https://abc.com/)*"
            (Nonempty (Bold (Nonempty (MarkdownLink (NonemptyString 'l' "ink") { protocol = Https, host = "abc.com", path = "/", port_ = Nothing, fragment = Nothing, query = Nothing }) [])) [])
        , fromNonemptyStringTest
            "\\[not a link](https://abc.com/)"
            (Nonempty (EscapedChar EscapedSquareBracket)
                [ NormalText 'n' "ot a link]("
                , Hyperlink { protocol = Https, host = "abc.com", path = "/", port_ = Nothing, fragment = Nothing, query = Nothing }
                , NormalText ')' ""
                ]
            )
        , fromNonemptyStringTest
            "[link](https://abc.com)"
            (Nonempty
                (MarkdownLink
                    (NonemptyString 'l' "ink")
                    { protocol = Https
                    , host = "abc.com"
                    , path = ""
                    , port_ = Nothing
                    , fragment = Nothing
                    , query = Nothing
                    }
                )
                []
            )
        , fromNonemptyStringTest "\n\u{200C}\u{200B}\n\n" (Nonempty (Sticker (Id.fromInt 4)) [])
        , toStringTest
            (Nonempty (Sticker (Id.fromInt 0)) [ NormalText '\u{200C}' "\u{200B}\n\n" ])
            "\n\u{200B}\n\n\u{200C}\u{200B}\n\n"
        , toStringTest (Nonempty (Sticker (Id.fromInt 4)) []) "\n\u{200C}\u{200B}\n\n"
        , fromNonemptyStringTest "\n\u{200B}\n\n" (Nonempty (Sticker (Id.fromInt 0)) [])

        --, fromNonemptyStringTest
        --    "\n\u{200B}\u{200C}\n\n"
        --    (Nonempty (Sticker (Id.fromInt 0)) [ NormalText '\u{200C}' "\u{200B}\n\n" ])
        , Test.fuzz
            fuzzer
            "Round trip"
            (\text ->
                RichText.fromNonemptyString users text
                    |> RichText.toString False users
                    |> Expect.equal (String.Nonempty.toString text)
            )
        ]


fromNonemptyStringTest : String -> Nonempty (RichText (Id userId)) -> Test
fromNonemptyStringTest input expected =
    case String.Nonempty.fromString input of
        Just nonempty ->
            Test.test (Debug.toString input) (\_ -> RichText.fromNonemptyString users nonempty |> Expect.equal expected)

        Nothing ->
            Debug.todo "Can't run a RichText parser on empty text"


toStringTest : Nonempty (RichText (Id userId)) -> String -> Test
toStringTest input expected =
    Test.test
        (Debug.toString ("RichText.toString: " ++ expected))
        (\_ -> RichText.toString False users input |> Expect.equal expected)
