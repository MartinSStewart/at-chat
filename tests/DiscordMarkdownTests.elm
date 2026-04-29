module DiscordMarkdownTests exposing (test)

import Discord
import Expect
import Id exposing (CustomEmojiId, Id)
import List.Nonempty exposing (Nonempty(..))
import OneToOne exposing (OneToOne)
import RichText exposing (DiscordCustomEmojiIdAndName, HasLeadingLineBreak(..), RichText(..))
import SeqDict
import String.Nonempty exposing (NonemptyString(..))
import Test exposing (Test)
import Unsafe
import Url exposing (Url)


test : Test
test =
    Test.describe
        "Discord Markdown parser tests"
        [ basicFormattingTests
        , discordSpecificTests

        --, codeTests
        --, edgeCaseTests
        --, fuzzTests
        ]


customEmojis : OneToOne DiscordCustomEmojiIdAndName (Id CustomEmojiId)
customEmojis =
    OneToOne.fromList
        [ ( { isAnimated = False, id = Unsafe.uint64 "543" |> Discord.idFromUInt64, name = Unsafe.emojiName "abc" }, Id.fromInt 999 )
        , ( { isAnimated = True, id = Unsafe.uint64 "444" |> Discord.idFromUInt64, name = Unsafe.emojiName "z_" }, Id.fromInt 888 )
        ]


fromDiscordHelper : String -> List (RichText (Discord.Id Discord.UserId))
fromDiscordHelper text =
    RichText.fromDiscord text SeqDict.empty Discord.Missing customEmojis [] Discord.Missing |> List.Nonempty.toList


basicFormattingTests : Test
basicFormattingTests =
    Test.describe
        "Basic formatting"
        [ Test.test "plain text" <|
            \_ ->
                fromDiscordHelper "Hello world"
                    |> Expect.equal [ NormalText 'H' "ello world" ]
        , Test.test "bold text" <|
            \_ ->
                fromDiscordHelper "**bold**"
                    |> Expect.equal [ Bold (Nonempty (NormalText 'b' "old") []) ]
        , Test.test "bold with surrounding text" <|
            \_ ->
                fromDiscordHelper "Hello **world** test"
                    |> Expect.equal
                        [ NormalText 'H' "ello "
                        , Bold (Nonempty (NormalText 'w' "orld") [])
                        , NormalText ' ' "test"
                        ]
        , Test.test "italic text" <|
            \_ ->
                fromDiscordHelper "_italic_"
                    |> Expect.equal [ Italic (Nonempty (NormalText 'i' "talic") []) ]

        --, Test.test "italic text 2" <|
        --    \_ ->
        --        fromDiscordHelper "*italic*"
        --            |> Expect.equal [ Italic [ NormalText "italic" ] ]
        , Test.test "underline text" <|
            \_ ->
                fromDiscordHelper "__underline__"
                    |> Expect.equal [ Underline (Nonempty (NormalText 'u' "nderline") []) ]
        , Test.test "strikethrough text" <|
            \_ ->
                fromDiscordHelper "~~strike~~"
                    |> Expect.equal [ Strikethrough (Nonempty (NormalText 's' "trike") []) ]
        , Test.test "spoiler text" <|
            \_ ->
                fromDiscordHelper "||spoiler||"
                    |> Expect.equal [ Spoiler (Nonempty (NormalText 's' "poiler") []) ]
        , Test.test "nested formatting" <|
            \_ ->
                fromDiscordHelper "**_bold italic_**"
                    |> Expect.equal
                        [ Bold
                            (Nonempty
                                (Italic
                                    (Nonempty
                                        (NormalText 'b' "old italic")
                                        []
                                    )
                                )
                                []
                            )
                        ]
        , Test.test "escaped characters" <|
            \_ ->
                fromDiscordHelper "\\*Bullet point 1\n\\*Bullet point 2"
                    |> Expect.equal [ NormalText '*' "Bullet point 1\n*Bullet point 2" ]
        , fromNonemptyStringTest "[link](https://abc.com/)" (Nonempty (MarkdownLink (NonemptyString 'l' "ink") (unsafeUrl "https://abc.com")) [])
        , fromNonemptyStringTest
            "[[link](https://abc.com/)"
            (Nonempty (NormalText '[' "") [ MarkdownLink (NonemptyString 'l' "ink") (unsafeUrl "https://abc.com") ])
        , fromNonemptyStringTest "_https://abc.com/_" (Nonempty (Italic (Nonempty (Hyperlink (unsafeUrl "https://abc.com")) [])) [])
        , fromNonemptyStringTest "https://abc.com/," (Nonempty (Hyperlink (unsafeUrl "https://abc.com")) [ NormalText ',' "" ])
        , fromNonemptyStringTest "https://abc.com/:" (Nonempty (Hyperlink (unsafeUrl "https://abc.com")) [ NormalText ':' "" ])
        , fromNonemptyStringTest "<https://abc.com/>" (Nonempty (Hyperlink (unsafeUrl "https://abc.com/")) [])
        , fromNonemptyStringTest "https://abc.com/>" (Nonempty (Hyperlink (unsafeUrl "https://abc.com/>")) [])
        , fromNonemptyStringTest "<https://abc.com/" (Nonempty (NormalText '<' "") [ Hyperlink (unsafeUrl "https://abc.com/") ])
        , fromNonemptyStringTest "<https://abc.com/,>" (Nonempty (Hyperlink (unsafeUrl "https://abc.com/,")) [])
        , fromNonemptyStringTest "https://abc.com/,>" (Nonempty (Hyperlink (unsafeUrl "https://abc.com/,>")) [])
        , fromNonemptyStringTest "<https://abc.com/,>," (Nonempty (Hyperlink (unsafeUrl "https://abc.com/,")) [ NormalText ',' "" ])
        , fromNonemptyStringTest "||||" (Nonempty (NormalText '|' "|||") [])
        , fromNonemptyStringTest "~~~~" (Nonempty (NormalText '~' "~~~") [])
        , fromNonemptyStringTest
            "] [a](http://a.com/)"
            (Nonempty (NormalText ']' " ") [ MarkdownLink (NonemptyString 'a' "") (unsafeUrl "http://a.com/") ])
        , fromNonemptyStringTest "*a\nb*" (Nonempty (NormalText '*' "a\nb*") [])
        , fromNonemptyStringTest "_a\na_" (Nonempty (NormalText '_' "a\na_") [])
        , fromNonemptyStringTest "~~a\na~~" (Nonempty (NormalText '~' "~a\na~~") [])
        , fromNonemptyStringTest "_~~a\na~~_" (Nonempty (NormalText '_' "~~a\na~~_") [])
        , fromNonemptyStringTest
            "_~~a\na~~_a_"
            (Nonempty (NormalText '_' "~~a\na~~") [ Italic (Nonempty (NormalText 'a' "") []) ])
        , fromNonemptyStringTest "\n> asdf" (Nonempty (BlockQuote HasLeadingLineBreak [ NormalText 'a' "sdf" ]) [])
        , fromNonemptyStringTest
            "\n> asdf\n>asdf"
            (Nonempty (BlockQuote HasLeadingLineBreak [ NormalText 'a' "sdf" ]) [ NormalText '\n' ">asdf" ])
        , fromNonemptyStringTest "> quoted" (Nonempty (BlockQuote NoLeadingLineBreak [ NormalText 'q' "uoted" ]) [])
        , fromNonemptyStringTest
            "foo\n> bar"
            (Nonempty (NormalText 'f' "oo") [ BlockQuote HasLeadingLineBreak [ NormalText 'b' "ar" ] ])
        , fromNonemptyStringTest
            "> test\n> asdf\n> \n> 123\n\n> 23"
            (Nonempty
                (BlockQuote NoLeadingLineBreak [ NormalText 't' "est\nasdf\n\n123" ])
                [ NormalText '\n' "", BlockQuote HasLeadingLineBreak [ NormalText '2' "3" ] ]
            )
        , fromNonemptyStringTest "`a\na`" (Nonempty (NormalText '`' "a\na`") [])
        , fromNonemptyStringTest "<:abc:543>" (Nonempty (CustomEmoji (Id.fromInt 999)) [])
        , fromNonemptyStringTest "<:abc:542>" (Nonempty (NormalText '<' ":abc:542>") [])
        , fromNonemptyStringTest "<:543>" (Nonempty (NormalText '<' ":543>") [])
        , fromNonemptyStringTest "<:http:543>" (Nonempty (NormalText '<' ":http:543>") [])
        , fromNonemptyStringTest "<a:abc:543>" (Nonempty (NormalText '<' "a:abc:543>") [])
        , fromNonemptyStringTest "<a:z_:444>" (Nonempty (CustomEmoji (Id.fromInt 888)) [])
        , fromNonemptyStringTest "<b:abc:543>" (Nonempty (NormalText '<' "b:abc:543>") [])
        ]


fromNonemptyStringTest : String -> Nonempty (RichText (Discord.Id Discord.UserId)) -> Test
fromNonemptyStringTest input expected =
    Test.test
        (Debug.toString input)
        (\_ ->
            RichText.fromDiscord input
                SeqDict.empty
                Discord.Missing
                customEmojis
                []
                Discord.Missing
                |> Expect.equal expected
        )


unsafeUrl : String -> Url
unsafeUrl url =
    case Url.fromString url of
        Just url2 ->
            url2

        Nothing ->
            Debug.todo "Invalid url"


userId : Discord.Id Discord.UserId
userId =
    Unsafe.uint64 "137748026084163580" |> Discord.idFromUInt64


discordSpecificTests : Test
discordSpecificTests =
    Test.describe
        "Discord-specific features"
        [ Test.test "user ping" <|
            \_ ->
                fromDiscordHelper "<@!137748026084163580>"
                    |> Expect.equal [ UserMention userId ]
        , Test.test "user ping with text" <|
            \_ ->
                fromDiscordHelper "Hello <@!137748026084163580> how are you?"
                    |> Expect.equal
                        [ NormalText 'H' "ello "
                        , UserMention userId
                        , NormalText ' ' "how are you?"
                        ]

        --, Test.test "custom emoji" <|
        --    \_ ->
        --        fromDiscordHelper "<:smile:123456789>"
        --            |> Expect.equal [ CustomEmoji "smile" (Discord.fromUInt64 (UInt64.fromString "123456789" |> Maybe.withDefault UInt64.zero)) ]
        --, Test.test "custom emoji with text" <|
        --    \_ ->
        --        fromDiscordHelper "Hello <:wave:987654321> world"
        --            |> Expect.equal
        --                [ NormalText "Hello "
        --                , CustomEmoji "wave" (Discord.fromUInt64 (UInt64.fromString "987654321" |> Maybe.withDefault UInt64.zero))
        --                , NormalText " world"
        --                ]
        --, Test.test "multiple pings" <|
        --    \_ ->
        --        fromDiscordHelper "<@!123> and <@!456>"
        --            |> Expect.equal
        --                [ Ping (Discord.fromUInt64 (UInt64.fromString "123" |> Maybe.withDefault UInt64.zero))
        --                , NormalText " and "
        --                , Ping (Discord.fromUInt64 (UInt64.fromString "456" |> Maybe.withDefault UInt64.zero))
        --                ]
        --, Test.test "ping inside formatting" <|
        --    \_ ->
        --        fromDiscordHelper "**Hello <@!137748026084163580>**"
        --            |> Expect.equal
        --                [ Bold
        --                    [ NormalText "Hello "
        --                    , Ping (Discord.fromUInt64 (UInt64.fromString "123456789" |> Maybe.withDefault UInt64.zero))
        --                    ]
        --                ]
        ]



--codeTests : Test
--codeTests =
--    Test.describe
--        "Code formatting"
--        [ Test.test "inline code" <|
--            \_ ->
--                fromDiscordHelper "`code`"
--                    |> Expect.equal [ Code "code" ]
--        , Test.test "inline code with text" <|
--            \_ ->
--                fromDiscordHelper "Here is `some code` in text"
--                    |> Expect.equal
--                        [ NormalText "Here is "
--                        , Code "some code"
--                        , NormalText " in text"
--                        ]
--        , Test.test "code block without language" <|
--            \_ ->
--                fromDiscordHelper "```\nfunction test() {\n  return true;\n}```"
--                    |> Expect.equal [ CodeBlock Nothing "function test() {\n  return true;\n}" ]
--        , Test.test "code block with language" <|
--            \_ ->
--                fromDiscordHelper "```javascript\nfunction test() {\n  return true;\n}```"
--                    |> Expect.equal [ CodeBlock (Language (NonemptyString 'j' "avascript")) "function test() {\n  return true;\n}" ]
--        , Test.test "single line code block" <|
--            \_ ->
--                fromDiscordHelper "```console.log('hello')```"
--                    |> Expect.equal [ CodeBlock NoLanguage "console.log('hello')" ]
--        , Test.test "empty code block" <|
--            \_ ->
--                fromDiscordHelper "``````"
--                    |> Expect.equal [ CodeBlock NoLanguage "" ]
--        , Test.test "code block with empty language line" <|
--            \_ ->
--                fromDiscordHelper "```\n\nconst x = 1;```"
--                    |> Expect.equal [ CodeBlock NoLanguage "\nconst x = 1;" ]
--        ]
--
--
--edgeCaseTests : Test
--edgeCaseTests =
--    Test.describe
--        "Edge cases and error handling"
--        [ Test.test "empty string" <|
--            \_ ->
--                fromDiscordHelper ""
--                    |> Expect.equal []
--        , Test.test "unclosed bold" <|
--            \_ ->
--                fromDiscordHelper "**unclosed"
--                    |> Expect.equal [ NormalText '*' "*", NormalText '*' "nclosed" ]
--        , Test.test "unclosed italic" <|
--            \_ ->
--                fromDiscordHelper "_unclosed"
--                    |> Expect.equal [ NormalText '_' "", NormalText "unclosed" ]
--        , Test.test "unclosed code" <|
--            \_ ->
--                fromDiscordHelper "`unclosed"
--                    |> Expect.equal [ NormalText '`' "``unclosed" ]
--        , Test.test "unclosed code block" <|
--            \_ ->
--                fromDiscordHelper "```unclosed"
--                    |> Expect.equal [ NormalText '`' "``unclosed" ]
--        , Test.test "malformed ping (missing closing bracket)" <|
--            \_ ->
--                fromDiscordHelper "<@!123456789"
--                    |> Expect.equal [ NormalText "<@!123456789" ]
--        , Test.test "malformed ping (missing exclamation)" <|
--            \_ ->
--                fromDiscordHelper "<@123456789>"
--                    |> Expect.equal [ NormalText "<@123456789>" ]
--        , Test.test "malformed emoji (missing closing bracket)" <|
--            \_ ->
--                fromDiscordHelper "<:smile:123456789"
--                    |> Expect.equal [ NormalText "<:smile:123456789" ]
--        , Test.test "malformed emoji (missing colon)" <|
--            \_ ->
--                fromDiscordHelper "<smile:123456789>"
--                    |> Expect.equal [ NormalText "<smile:123456789>" ]
--
--        --, Test.test "empty bold" <|
--        --    \_ ->
--        --        fromDiscordHelper "****"
--        --            |> Expect.equal [ Italic [ NormalText "**" ] ]
--        , Test.test "empty italic" <|
--            \_ ->
--                fromDiscordHelper "__"
--                    |> Expect.equal [ NormalText "__" ]
--        , Test.test "invalid user ID in ping" <|
--            \_ ->
--                fromDiscordHelper "<@!notanumber>"
--                    |> Expect.equal [ NormalText "<@!notanumber>" ]
--        , Test.test "invalid emoji ID" <|
--            \_ ->
--                fromDiscordHelper "<:smile:notanumber>"
--                    |> Expect.equal [ NormalText "<:smile:notanumber>" ]
--        , Test.test "bold with trailing whitespace should work" <|
--            \_ ->
--                fromDiscordHelper "** bold **"
--                    |> Expect.equal [ Bold [ NormalText " bold " ] ]
--        , Test.test "nested same formatting" <|
--            \_ ->
--                fromDiscordHelper "**bold **nested** bold**"
--                    |> Expect.equal [ Bold [ NormalText "bold " ], NormalText "nested", Bold [ NormalText " bold" ] ]
--        ]
--
--
--fuzzTests : Test
--fuzzTests =
--    Test.describe
--        "Fuzz tests"
--        [ Test.fuzz discordMarkdownFuzzer "Parser should not crash on random input" <|
--            \input ->
--                fromDiscordHelper input
--                    |> List.length
--                    |> Expect.atLeast 0
--        , Test.fuzz Fuzz.string "Any string should parse without error" <|
--            \input ->
--                fromDiscordHelper input
--                    |> (\result ->
--                            case result of
--                                [] ->
--                                    if String.isEmpty input then
--                                        Expect.pass
--
--                                    else
--                                        Expect.fail "Non-empty string should not result in empty parse"
--
--                                _ ->
--                                    Expect.pass
--                       )
--        ]
