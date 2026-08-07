module RichTextTests exposing (simpleTest, test)

import Effect.Time as Time
import Expect
import Fuzz exposing (Fuzzer)
import Html
import Id exposing (Id)
import List.Nonempty exposing (Nonempty(..))
import MyUi
import PersonName exposing (PersonName)
import RichText exposing (EscapedChar(..), HasLeadingLineBreak(..), HeadingLevel(..), Language(..), RichText(..))
import SeqDict
import SeqSet
import String.Nonempty exposing (NonemptyString(..))
import Test exposing (Test)
import Test.Html.Query
import Test.Html.Selector
import TimeInMinutes exposing (TimeInMinutes)
import Unsafe
import Url exposing (Protocol(..), Url)


users : SeqDict.SeqDict (Id a) { name : PersonName }
users =
    SeqDict.fromList
        [ ( Id.fromInt 1234, { name = Unsafe.personName "a1" } )
        , ( Id.fromInt 123, { name = Unsafe.personName "a" } )
        , ( Id.fromInt 12345, { name = Unsafe.personName "aa" } )
        ]


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
        , ">"
        , "> "
        , "\n>"
        , "\n> "
        , "# "
        , "## "
        , "### "
        , "-# "
        , "\n# "
        , "\n## "
        , "\n### "
        , "\n-# "
        , "#"
        , "-"
        , "❓"
        , "\u{FEFF}"
        , "-"
        , "¯"
        , "¯\\_(ツ)_/¯"
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
        , fromNonemptyStringTest "*a\nb*" (Nonempty (NormalText '*' "a\nb*") [])
        , fromNonemptyStringTest "_a\na_" (Nonempty (NormalText '_' "a\na_") [])
        , fromNonemptyStringTest "`a\na`" (Nonempty (NormalText '`' "a\na`") [])
        , fromNonemptyStringTest "~~a\na~~" (Nonempty (NormalText '~' "~a\na~~") [])
        , fromNonemptyStringTest "_~~a\na~~_" (Nonempty (NormalText '_' "~~a\na~~_") [])
        , fromNonemptyStringTest "_~~a\na~~_a_" (Nonempty (NormalText '_' "~~a\na~~") [ Italic (Nonempty (NormalText 'a' "") []) ])
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
        , fromNonemptyStringTest "||test |||| |||| test||"
            (Nonempty
                (Spoiler (Nonempty (NormalText 't' "est ") []))
                [ Spoiler (Nonempty (NormalText ' ' "") [])
                , Spoiler (Nonempty (NormalText ' ' "test") [])
                ]
            )
        , fromNonemptyStringTest "~~test ~~~~ ~~~~ test~~"
            (Nonempty
                (Strikethrough (Nonempty (NormalText 't' "est ") []))
                [ Strikethrough (Nonempty (NormalText ' ' "") [])
                , Strikethrough (Nonempty (NormalText ' ' "test") [])
                ]
            )
        , fromNonemptyStringTest "\n> asdf"
            (Nonempty (BlockQuote HasLeadingLineBreak [ NormalText 'a' "sdf" ]) [])
        , fromNonemptyStringTest "\n> asdf\n>asdf"
            (Nonempty (BlockQuote HasLeadingLineBreak [ NormalText 'a' "sdf" ]) [ NormalText '\n' ">asdf" ])
        , fromNonemptyStringTest "\n> asdf\n> more"
            (Nonempty (BlockQuote HasLeadingLineBreak [ NormalText 'a' "sdf\nmore" ]) [])
        , fromNonemptyStringTest "> hello"
            (Nonempty (BlockQuote NoLeadingLineBreak [ NormalText 'h' "ello" ]) [])
        , fromNonemptyStringTest "> " (Nonempty (BlockQuote NoLeadingLineBreak []) [])
        , toStringTest (Nonempty (BlockQuote NoLeadingLineBreak [ NormalText ' ' "" ]) []) ">  "
        , fromNonemptyStringTest "foo\n> bar"
            (Nonempty (NormalText 'f' "oo") [ BlockQuote HasLeadingLineBreak [ NormalText 'b' "ar" ] ])
        , fromNonemptyStringTest "\n> *bold*"
            (Nonempty (BlockQuote HasLeadingLineBreak [ Bold (Nonempty (NormalText 'b' "old") []) ]) [])
        , fromNonemptyStringTest "\n> quote\nafter"
            (Nonempty
                (BlockQuote HasLeadingLineBreak [ NormalText 'q' "uote" ])
                [ NormalText '\n' "after" ]
            )
        , fromNonemptyStringTest "# hello"
            (Nonempty (Heading H1 NoLeadingLineBreak (Nonempty (NormalText 'h' "ello") [])) [])
        , fromNonemptyStringTest "## hello"
            (Nonempty (Heading H2 NoLeadingLineBreak (Nonempty (NormalText 'h' "ello") [])) [])
        , fromNonemptyStringTest "### hello"
            (Nonempty (Heading H3 NoLeadingLineBreak (Nonempty (NormalText 'h' "ello") [])) [])
        , fromNonemptyStringTest "-# small"
            (Nonempty (Heading Small NoLeadingLineBreak (Nonempty (NormalText 's' "mall") [])) [])
        , fromNonemptyStringTest "\n# heading"
            (Nonempty (Heading H1 HasLeadingLineBreak (Nonempty (NormalText 'h' "eading") [])) [])
        , fromNonemptyStringTest "\n## heading"
            (Nonempty (Heading H2 HasLeadingLineBreak (Nonempty (NormalText 'h' "eading") [])) [])
        , fromNonemptyStringTest "\n### heading"
            (Nonempty (Heading H3 HasLeadingLineBreak (Nonempty (NormalText 'h' "eading") [])) [])
        , fromNonemptyStringTest "\n-# tiny"
            (Nonempty (Heading Small HasLeadingLineBreak (Nonempty (NormalText 't' "iny") [])) [])
        , fromNonemptyStringTest "before\n# title"
            (Nonempty (NormalText 'b' "efore") [ Heading H1 HasLeadingLineBreak (Nonempty (NormalText 't' "itle") []) ])
        , fromNonemptyStringTest "# title\nafter"
            (Nonempty (Heading H1 NoLeadingLineBreak (Nonempty (NormalText 't' "itle") [])) [ NormalText '\n' "after" ])
        , fromNonemptyStringTest "# *bold heading*"
            (Nonempty (Heading H1 NoLeadingLineBreak (Nonempty (Bold (Nonempty (NormalText 'b' "old heading") [])) [])) [])
        , fromNonemptyStringTest "## " (Nonempty (NormalText '#' "# ") [])
        , fromNonemptyStringTest "#hello" (Nonempty (NormalText '#' "hello") [])
        , fromNonemptyStringTest "-#nope" (Nonempty (NormalText '-' "#nope") [])
        , fromNonemptyStringTest "# one\n## two\n### three\n-# small"
            (Nonempty
                (Heading H1 NoLeadingLineBreak (Nonempty (NormalText 'o' "ne") []))
                [ Heading H2 HasLeadingLineBreak (Nonempty (NormalText 't' "wo") [])
                , Heading H3 HasLeadingLineBreak (Nonempty (NormalText 't' "hree") [])
                , Heading Small HasLeadingLineBreak (Nonempty (NormalText 's' "mall") [])
                ]
            )
        , toStringTest
            (Nonempty (Heading H1 NoLeadingLineBreak (Nonempty (NormalText 'h' "i") [])) [])
            "# hi"
        , toStringTest
            (Nonempty (Heading Small HasLeadingLineBreak (Nonempty (NormalText 'a' "") [])) [])
            "\n-# a"
        , Test.test
            "Heading round trip"
            (\_ ->
                let
                    text =
                        NonemptyString '#' " hello\n## world"
                in
                RichText.fromNonemptyString Time.utc users text
                    |> RichText.toString Time.utc False users
                    |> Expect.equal (String.Nonempty.toString text)
            )
        , fromNonemptyStringTest "\n>no space" (Nonempty (NormalText '\n' ">no space") [])
        , fromNonemptyStringTest "> \n> " (Nonempty (BlockQuote NoLeadingLineBreak [ NormalText '\n' "" ]) [])
        , toStringTest (Nonempty (BlockQuote NoLeadingLineBreak [ NormalText '\n' "" ]) []) "> \n> "
        , fromNonemptyStringTest "> \n>" (Nonempty (BlockQuote NoLeadingLineBreak []) [ NormalText '\n' ">" ])
        , fromNonemptyStringTest
            "> test\n> asdf\n> \n> 123\n\n> 23"
            (Nonempty
                (BlockQuote NoLeadingLineBreak [ NormalText 't' "est\nasdf\n\n123" ])
                [ NormalText '\n' "", BlockQuote HasLeadingLineBreak [ NormalText '2' "3" ] ]
            )

        --, fromNonemptyStringTest "> asdf\n> f"
        , Test.test
            "Round trip2"
            (\_ ->
                let
                    text =
                        NonemptyString '>' " asdf\n> f"
                in
                RichText.fromNonemptyString Time.utc users text
                    |> RichText.toString Time.utc False users
                    |> Expect.equal (String.Nonempty.toString text)
            )

        --, fromNonemptyStringTest
        --    "\n\u{200B}\u{200C}\n\n"
        --    (Nonempty (Sticker (Id.fromInt 0)) [ NormalText '\u{200C}' "\u{200B}\n\n" ])
        , Test.fuzz
            fuzzer
            "Round trip"
            (\text ->
                RichText.fromNonemptyString Time.utc users text
                    |> RichText.toString Time.utc False users
                    |> Expect.equal (String.Nonempty.toString text)
            )
        , simpleTest
            "Unspoiler attachment"
            (Nonempty (Spoiler (Nonempty (AttachedFile (Id.fromInt 1)) [])) [])
            (Nonempty (AttachedFile (Id.fromInt 1)) [])
            (RichText.unspoilerAttachedFile (Id.fromInt 1))
        , simpleTest
            "Unspoiler attachment 2"
            (Nonempty (Spoiler (Nonempty (AttachedFile (Id.fromInt 1)) [ NormalText ' ' "test" ])) [])
            (Nonempty (AttachedFile (Id.fromInt 1)) [ Spoiler (Nonempty (NormalText ' ' "test") []) ])
            (RichText.unspoilerAttachedFile (Id.fromInt 1))
        , fromNonemptyStringTest "❓\u{200B}\u{FEFF}" (Nonempty (CustomEmoji (Id.fromInt 0)) [])
        , fromNonemptyStringTest "❓\u{2060}\u{FEFF}" (Nonempty (CustomEmoji (Id.fromInt 3)) [])
        , fromNonemptyStringTest "a❓\u{2060}\u{FEFF}" (Nonempty (NormalText 'a' "") [ CustomEmoji (Id.fromInt 3) ])
        , fromNonemptyStringTest "❓\u{2060}\u{2060}\u{FEFF}" (Nonempty (CustomEmoji (Id.fromInt 15)) [])
        , fromNonemptyStringTest "❓\u{200B}\u{2060}\u{FEFF}" (Nonempty (NormalText '❓' "\u{200B}\u{2060}\u{FEFF}") [])
        , fromNonemptyStringTest "❓\u{200B}\u{2060}" (Nonempty (NormalText '❓' "\u{200B}\u{2060}") [])
        , fromNonemptyStringTest "❓\u{200B}" (Nonempty (NormalText '❓' "\u{200B}") [])
        , fromNonemptyStringTest "❓\u{2060}" (Nonempty (NormalText '❓' "\u{2060}") [])
        , fromNonemptyStringTest "❓\u{2060}\u{FEFF}❓\u{2060}\u{FEFF}" (Nonempty (CustomEmoji (Id.fromInt 3)) [ CustomEmoji (Id.fromInt 3) ])
        , fromNonemptyStringTest "❓\u{2060}\u{200C}\u{FEFF}" (Nonempty (CustomEmoji (Id.fromInt 13)) [])
        , fromNonemptyStringTest "https://a.com/abc]" (Nonempty (Hyperlink (unsafeUrl "https://a.com/abc")) [ NormalText ']' "" ])
        , fromNonemptyStringTest "https://a.com/abc]d" (Nonempty (Hyperlink (unsafeUrl "https://a.com/abc]d")) [])
        , fromNonemptyStringTest "https://a.com/abc(123)" (Nonempty (Hyperlink (unsafeUrl "https://a.com/abc(123)")) [])
        , fromNonemptyStringTest "(https://a.com/abc(123)" (Nonempty (NormalText '(' "") [ Hyperlink (unsafeUrl "https://a.com/abc(123)") ])
        , fromNonemptyStringTest "(https://a.com/abc(123))" (Nonempty (NormalText '(' "") [ Hyperlink (unsafeUrl "https://a.com/abc(123)"), NormalText ')' "" ])
        , fromNonemptyStringTest "https://a.com/abc123)" (Nonempty (Hyperlink (unsafeUrl "https://a.com/abc123")) [ NormalText ')' "" ])
        , fromNonemptyStringTest "https://a.com/abc1(23))" (Nonempty (Hyperlink (unsafeUrl "https://a.com/abc1(23))")) [])
        , fromNonemptyStringTest "* a" (Nonempty (BulletPoint NoLeadingLineBreak (Nonempty [ NormalText 'a' "" ] [])) [])
        , fromNonemptyStringTest
            "* a\n"
            (Nonempty (BulletPoint NoLeadingLineBreak (Nonempty [ NormalText 'a' "" ] [])) [ NormalText '\n' "" ])
        , fromNonemptyStringTest
            "* a\n* "
            (Nonempty (BulletPoint NoLeadingLineBreak (Nonempty [ NormalText 'a' "" ] [])) [ NormalText '\n' "* " ])
        , fromNonemptyStringTest
            "abc\n* a"
            (Nonempty (NormalText 'a' "bc") [ BulletPoint HasLeadingLineBreak (Nonempty [ NormalText 'a' "" ] []) ])
        , fromNonemptyStringTest
            "* a\n* \n* b"
            (Nonempty
                (BulletPoint
                    NoLeadingLineBreak
                    (Nonempty [ NormalText 'a' "" ] [ [], [ NormalText 'b' "" ] ])
                )
                []
            )
        , fromNonemptyStringTest
            "* *abc*"
            (Nonempty
                (BulletPoint NoLeadingLineBreak (Nonempty [ Bold (Nonempty (NormalText 'a' "bc") []) ] []))
                []
            )
        , fromNonemptyStringTest "- a" (Nonempty (NormalText '-' " a") [])
        , fromNonemptyStringTest "- a\n" (Nonempty (NormalText '-' " a\n") [])
        , fromNonemptyStringTest "- *abc*" (Nonempty (NormalText '-' " ") [ Bold (Nonempty (NormalText 'a' "bc") []) ])
        , fromNonemptyStringTest
            "* a\n- \n- b"
            (Nonempty
                (BulletPoint NoLeadingLineBreak (Nonempty [ NormalText 'a' "" ] []))
                [ NormalText '\n' "- \n- b" ]
            )
        , fromNonemptyStringTest "¯\\_(ツ)_/¯" (Nonempty (NormalText '¯' "\\_(ツ)_/¯") [])
        , fromNonemptyStringTest
            "a ¯\\_(ツ)_/¯ b"
            (Nonempty (NormalText 'a' " ¯\\_(ツ)_/¯ b") [])
        , fromNonemptyStringTest
            "*¯\\_(ツ)_/¯*"
            (Nonempty (Bold (Nonempty (NormalText '¯' "\\_(ツ)_/¯") [])) [])
        , -- Not the shrug, so no special case and the backslash gets eaten as an escape like normal
          fromNonemptyStringTest "¯\\_(ツ)_/" (Nonempty (NormalText '¯' "") [ EscapedChar EscapedItalic, NormalText '(' "ツ)_/" ])
        , fromNonemptyStringTest "¯" (Nonempty (NormalText '¯' "") [])
        , fromNonemptyStringTest "https://a.comhttps://a.com" (Nonempty (NormalText 'h' "ttps://a.comhttps://a.com") [])
        , toStringTest
            (Nonempty
                (NormalText '¯' "")
                [ EscapedChar EscapedBackslash
                , EscapedChar EscapedItalic
                , NormalText '(' "ツ)"
                , EscapedChar EscapedItalic
                , NormalText '/' "¯"
                ]
            )
            "¯\\\\\\_(ツ)\\_/¯"
        , Test.describe
            "Timestamp parsing"
            [ fromNonemptyStringTest
                "August 6, 2026 at 10:50"
                (Nonempty (Timestamp (TimeInMinutes.fromMinutes 29766890)) [])
            , fromNonemptyStringTest
                "Starts at August 6, 2026 at 10:50, be there"
                (Nonempty
                    (NormalText 'S' "tarts at ")
                    [ Timestamp (TimeInMinutes.fromMinutes 29766890), NormalText ',' " be there" ]
                )
            , fromNonemptyStringTest
                "*August 6, 2026 at 10:50*"
                (Nonempty (Bold (Nonempty (Timestamp (TimeInMinutes.fromMinutes 29766890)) [])) [])
            , -- Two hours ahead of UTC, a clock reads 10:50 two hours before it does in UTC.
              fromNonemptyStringInZoneTest
                "two hours ahead of UTC"
                (Time.customZone 120 [])
                "August 6, 2026 at 10:50"
                (Nonempty (Timestamp (TimeInMinutes.fromMinutes 29766770)) [])
            , fromNonemptyStringInZoneTest
                "eight hours behind UTC"
                (Time.customZone -480 [])
                "August 6, 2026 at 10:50"
                (Nonempty (Timestamp (TimeInMinutes.fromMinutes 29767370)) [])
            , -- The hour the clocks skip over on the day they go forward isn't a time anything
              -- happens at, so there's nothing for this to mean.
              fromNonemptyStringInZoneTest
                "in the hour the clocks skip"
                springForward
                "March 29, 2026 at 02:30"
                (Nonempty (NormalText 'M' "arch 29, 2026 at 02:30") [])
            , fromNonemptyStringInZoneTest
                "after the clocks go forward"
                springForward
                "March 29, 2026 at 03:30"
                (Nonempty (Timestamp (TimeInMinutes.fromMinutes 29579130)) [])
            , fromNonemptyStringTest
                "February 31, 2026 at 10:50"
                (Nonempty (NormalText 'F' "ebruary 31, 2026 at 10:50") [])
            , fromNonemptyStringTest
                "August 6, 2026 at 25:50"
                (Nonempty (NormalText 'A' "ugust 6, 2026 at 25:50") [])
            , -- The day is written without a leading zero, so reading this one back would give
              -- text of a different length and shift everything after it along.
              fromNonemptyStringTest
                "August 06, 2026 at 10:50"
                (Nonempty (NormalText 'A' "ugust 06, 2026 at 10:50") [])
            , fromNonemptyStringTest
                "August 6, 2026 at 10:5"
                (Nonempty (NormalText 'A' "ugust 6, 2026 at 10:5") [])
            , fromNonemptyStringTest
                "August 6 2026 at 10:50"
                (Nonempty (NormalText 'A' "ugust 6 2026 at 10:50") [])
            , fromNonemptyStringTest
                "Augus 6, 2026 at 10:50"
                (Nonempty (NormalText 'A' "ugus 6, 2026 at 10:50") [])
            , fromNonemptyStringTest
                "March was cold and September is far off"
                (Nonempty (NormalText 'M' "arch was cold and September is far off") [])
            , -- Discord's syntax is still what arrives from Discord, so it's still read here.
              fromNonemptyStringTest
                "<t:1786013400:f>"
                (Nonempty (Timestamp (TimeInMinutes.fromMinutes 29766890)) [])
            , fromNonemptyStringTest
                "<t:1786013400>"
                (Nonempty (Timestamp (TimeInMinutes.fromMinutes 29766890)) [])
            , fromNonemptyStringTest
                "<t:1786013400:f"
                (Nonempty (NormalText '<' "t:1786013400:f") [])
            , fromNonemptyStringTest "<t::f>" (Nonempty (NormalText '<' "t::f>") [])
            , fromNonemptyStringTest
                "<x:1786013400>"
                (Nonempty (NormalText '<' "x:1786013400>") [])
            , fromNonemptyStringTest "a < b" (Nonempty (NormalText 'a' " < b") [])
            , roundTripTest "UTC" Time.utc
            , roundTripTest "two hours ahead of UTC" (Time.customZone 120 [])
            , roundTripTest "eight hours behind UTC" (Time.customZone -480 [])
            , roundTripTest "a timezone that puts its clocks forward" springForward
            ]
        , Test.describe
            "Timestamp display"
            [ timestampViewTest "Something later today counts down to it" 0 150 "02:30 (in 2\u{00A0}hours 30\u{00A0}minutes)"
            , timestampViewTest "A minute away is singular" 0 1 "00:01 (in 1\u{00A0}minute)"
            , timestampViewTest "Less than a minute away is now" 30000 0 "00:00 (now)"
            , timestampViewTest "Something earlier today counts up from it" 9000000 0 "00:00 (2\u{00A0}hours 30\u{00A0}minutes ago)"
            , timestampViewTest "A whole number of hours leaves the minutes out" 0 120 "02:00 (in 2\u{00A0}hours)"
            , timestampViewTest "Another day gets the date instead" 0 29766890 "August 6, 2026 at 10:50"
            ]
        , Test.describe "Selection highlight in the message input"
            [ selectionHighlightTest "abc||spoiler||def"
            , selectionHighlightTest "a*bold*c"
            , selectionHighlightTest "a__under__c"
            , selectionHighlightTest "a~~strike~~c"
            , selectionHighlightTest "a`code`c"
            , selectionHighlightTest "a\\*b"
            , selectionHighlightTest "> quoted"
            , selectionHighlightTest "> line1\n> line2\n> line3"
            , selectionHighlightTest "# Heading"
            , selectionHighlightTest "@a bc"
            , selectionHighlightTest "[!1]abc"
            , selectionHighlightTest "https://abc.com/x"
            , selectionHighlightTest "* bullet1\n* bullet2"
            , selectionHighlightTest "a||*b*||c"
            , selectionHighlightTest "a```elm\nfoo = 1\n```b"
            , selectionHighlightTest "a```\nplain\n```b"
            , selectionHighlightTest "a¯\\_(ツ)_/¯b"
            ]
        ]


{-| Timestamps are rendered from the reader's point of view, so what they read depends on
what the time is when the message is drawn.
-}
timestampViewTest : String -> Int -> Int -> String -> Test
timestampViewTest name now minutes expected =
    Test.test
        name
        (\_ ->
            RichText.preview
                (\_ -> ())
                { domainWhitelist = SeqSet.empty
                , revealedSpoilers = SeqSet.empty
                , users = users
                , attachedFiles = SeqDict.empty
                , customEmojis = SeqDict.empty
                , timezone = Time.utc
                , time = Time.millisToPosix now
                }
                (Nonempty (Timestamp (TimeInMinutes.fromMinutes minutes)) [])
                |> Html.div []
                |> Test.Html.Query.fromHtml
                |> Test.Html.Query.has [ Test.Html.Selector.exactText expected ]
        )


{-| The message input draws the selection highlight itself (the textarea on top of the rich text has
a transparent one) so the highlight has to line up with the text the user typed. Selects each
character in turn and checks that it's the character that ends up highlighted.
-}
selectionHighlightTest : String -> Test
selectionHighlightTest source =
    Test.test
        ("Selection highlight lines up with " ++ Debug.toString source)
        (\_ ->
            case String.Nonempty.fromString source of
                Just nonempty ->
                    Expect.all
                        (List.filterMap
                            (\index ->
                                let
                                    char : String
                                    char =
                                        String.slice index (index + 1) source
                                in
                                if String.trim char == "" then
                                    -- Test.Html.Selector.exactText can't match whitespace
                                    Nothing

                                else
                                    Just (\() -> expectHighlighted nonempty index char)
                            )
                            (List.range 0 (String.length source - 1))
                        )
                        ()

                Nothing ->
                    Expect.fail "Empty source text"
        )


expectHighlighted : NonemptyString -> Int -> String -> Expect.Expectation
expectHighlighted source index char =
    RichText.textInputView
        Time.utc
        users
        SeqDict.empty
        SeqDict.empty
        SeqDict.empty
        (Just { start = index, end = index + 1 })
        (RichText.fromNonemptyString Time.utc users source)
        |> Html.div []
        |> Test.Html.Query.fromHtml
        |> Test.Html.Query.findAll
            [ Test.Html.Selector.style "background-color" (MyUi.colorToStyle MyUi.selectedTextBackground)
            , Test.Html.Selector.exactText char
            ]
        |> Test.Html.Query.count
            (Expect.equal 1
                >> Expect.onFail
                    ("Selecting index "
                        ++ String.fromInt index
                        ++ " should highlight "
                        ++ Debug.toString char
                    )
            )


simpleTest : String -> b -> c -> (b -> c) -> Test
simpleTest name input output function =
    Test.test name (\_ -> function input |> Expect.equal output)


fromNonemptyStringTest : String -> Nonempty (RichText (Id userId)) -> Test
fromNonemptyStringTest input expected =
    case String.Nonempty.fromString input of
        Just nonempty ->
            Test.test (Debug.toString input) (\_ -> RichText.fromNonemptyString Time.utc users nonempty |> Expect.equal expected)

        Nothing ->
            Debug.todo "Can't run a RichText parser on empty text"


{-| A timestamp is written as the date and time a clock in the reader's timezone shows, so
what a piece of text means depends on which timezone it's read in.
-}
fromNonemptyStringInZoneTest : String -> Time.Zone -> String -> Nonempty (RichText (Id userId)) -> Test
fromNonemptyStringInZoneTest name timezone input expected =
    case String.Nonempty.fromString input of
        Just nonempty ->
            Test.test
                (Debug.toString input ++ " read " ++ name)
                (\_ -> RichText.fromNonemptyString timezone users nonempty |> Expect.equal expected)

        Nothing ->
            Debug.todo "Can't run a RichText parser on empty text"


{-| A timezone that puts its clocks forward an hour at 01:00 UTC on March 29th 2026, so that
the hour after 02:00 that morning is one its clocks never show.
-}
springForward : Time.Zone
springForward =
    Time.customZone 60 [ { start = 29579100, offset = 120 } ]


{-| Editing a message turns it back into text and parses the result, so a timestamp only
survives being edited if writing it out and reading it back is the identity.
-}
roundTripTest : String -> Time.Zone -> Test
roundTripTest name timezone =
    Test.test
        ("A timestamp survives being written out as text and read back in " ++ name)
        (\_ ->
            List.map
                (\minutes ->
                    let
                        original : Nonempty (RichText (Id ()))
                        original =
                            Nonempty
                                (NormalText 'S' "tarts at ")
                                [ Timestamp (TimeInMinutes.fromMinutes minutes)
                                , NormalText ',' " be there"
                                ]
                    in
                    ( RichText.toString timezone False users original
                        |> String.Nonempty.fromString
                        |> Maybe.map (RichText.fromNonemptyString timezone users)
                    , Just original
                    )
                )
                -- Either side of the morning the clocks go forward, and a date well away from it.
                [ 29579099, 29579100, 29579101, 29579160, 29766890 ]
                |> List.map (\( actual, expected ) -> ( actual == expected, actual, expected ))
                |> List.filter (\( matched, _, _ ) -> not matched)
                |> Expect.equalLists []
        )


toStringTest : Nonempty (RichText (Id userId)) -> String -> Test
toStringTest input expected =
    Test.test
        (Debug.toString ("RichText.toString: " ++ expected))
        (\_ -> RichText.toString Time.utc False users input |> Expect.equal expected)
