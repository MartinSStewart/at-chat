module DiscordMarkdownTests exposing (test)

import Discord.Id
import Discord.Markdown exposing (Markdown(..), parser)
import Expect
import Fuzz
import Test exposing (Test)
import UInt64


test : Test
test =
    Test.describe
        "Discord Markdown parser tests"
        [ basicFormattingTests
        , discordSpecificTests
        , codeTests
        , edgeCaseTests
        , fuzzTests
        ]


basicFormattingTests : Test
basicFormattingTests =
    Test.describe
        "Basic formatting"
        [ Test.test "plain text" <|
            \_ ->
                parser "Hello world"
                    |> Expect.equal [ Text "Hello world" ]
        , Test.test "bold text" <|
            \_ ->
                parser "**bold**"
                    |> Expect.equal [ Bold [ Text "bold" ] ]
        , Test.test "bold with surrounding text" <|
            \_ ->
                parser "Hello **world** test"
                    |> Expect.equal [ Text "Hello ", Bold [ Text "world" ], Text " test" ]
        , Test.test "italic text" <|
            \_ ->
                parser "_italic_"
                    |> Expect.equal [ Italic [ Text "italic" ] ]
        , Test.test "italic text 2" <|
            \_ ->
                parser "*italic*"
                    |> Expect.equal [ Italic [ Text "italic" ] ]
        , Test.test "underline text" <|
            \_ ->
                parser "__underline__"
                    |> Expect.equal [ Underline [ Text "underline" ] ]
        , Test.test "strikethrough text" <|
            \_ ->
                parser "~~strike~~"
                    |> Expect.equal [ Strikethrough [ Text "strike" ] ]
        , Test.test "spoiler text" <|
            \_ ->
                parser "||spoiler||"
                    |> Expect.equal [ Spoiler [ Text "spoiler" ] ]
        , Test.test "nested formatting" <|
            \_ ->
                parser "**_bold italic_**"
                    |> Expect.equal [ Bold [ Italic [ Text "bold italic" ] ] ]
        , Test.test "multiple formatting in sequence" <|
            \_ ->
                parser "**bold** _italic_ __underline__"
                    |> Expect.equal
                        [ Bold [ Text "bold" ]
                        , Text " "
                        , Italic [ Text "italic" ]
                        , Text " "
                        , Underline [ Text "underline" ]
                        ]
        ]


discordSpecificTests : Test
discordSpecificTests =
    Test.describe
        "Discord-specific features"
        [ Test.test "user ping" <|
            \_ ->
                parser "<@!123456789>"
                    |> Expect.equal [ Ping (Discord.Id.fromUInt64 (UInt64.fromString "123456789" |> Maybe.withDefault UInt64.zero)) ]
        , Test.test "user ping with text" <|
            \_ ->
                parser "Hello <@!123456789> how are you?"
                    |> Expect.equal
                        [ Text "Hello "
                        , Ping (Discord.Id.fromUInt64 (UInt64.fromString "123456789" |> Maybe.withDefault UInt64.zero))
                        , Text " how are you?"
                        ]
        , Test.test "custom emoji" <|
            \_ ->
                parser "<:smile:123456789>"
                    |> Expect.equal [ CustomEmoji "smile" (Discord.Id.fromUInt64 (UInt64.fromString "123456789" |> Maybe.withDefault UInt64.zero)) ]
        , Test.test "custom emoji with text" <|
            \_ ->
                parser "Hello <:wave:987654321> world"
                    |> Expect.equal
                        [ Text "Hello "
                        , CustomEmoji "wave" (Discord.Id.fromUInt64 (UInt64.fromString "987654321" |> Maybe.withDefault UInt64.zero))
                        , Text " world"
                        ]
        , Test.test "multiple pings" <|
            \_ ->
                parser "<@!123> and <@!456>"
                    |> Expect.equal
                        [ Ping (Discord.Id.fromUInt64 (UInt64.fromString "123" |> Maybe.withDefault UInt64.zero))
                        , Text " and "
                        , Ping (Discord.Id.fromUInt64 (UInt64.fromString "456" |> Maybe.withDefault UInt64.zero))
                        ]
        , Test.test "ping inside formatting" <|
            \_ ->
                parser "**Hello <@!123456789>**"
                    |> Expect.equal
                        [ Bold
                            [ Text "Hello "
                            , Ping (Discord.Id.fromUInt64 (UInt64.fromString "123456789" |> Maybe.withDefault UInt64.zero))
                            ]
                        ]
        ]


codeTests : Test
codeTests =
    Test.describe
        "Code formatting"
        [ Test.test "inline code" <|
            \_ ->
                parser "`code`"
                    |> Expect.equal [ Code "code" ]
        , Test.test "inline code with text" <|
            \_ ->
                parser "Here is `some code` in text"
                    |> Expect.equal
                        [ Text "Here is "
                        , Code "some code"
                        , Text " in text"
                        ]
        , Test.test "code block without language" <|
            \_ ->
                parser "```\nfunction test() {\n  return true;\n}```"
                    |> Expect.equal [ CodeBlock Nothing "function test() {\n  return true;\n}" ]
        , Test.test "code block with language" <|
            \_ ->
                parser "```javascript\nfunction test() {\n  return true;\n}```"
                    |> Expect.equal [ CodeBlock (Just "javascript") "function test() {\n  return true;\n}" ]
        , Test.test "single line code block" <|
            \_ ->
                parser "```console.log('hello')```"
                    |> Expect.equal [ CodeBlock Nothing "console.log('hello')" ]
        , Test.test "empty code block" <|
            \_ ->
                parser "``````"
                    |> Expect.equal [ CodeBlock Nothing "" ]
        , Test.test "code block with empty language line" <|
            \_ ->
                parser "```\n\nconst x = 1;```"
                    |> Expect.equal [ CodeBlock Nothing "\nconst x = 1;" ]
        ]


edgeCaseTests : Test
edgeCaseTests =
    Test.describe
        "Edge cases and error handling"
        [ Test.test "empty string" <|
            \_ ->
                parser ""
                    |> Expect.equal []
        , Test.test "unclosed bold" <|
            \_ ->
                parser "**unclosed"
                    |> Expect.equal [ Text "**", Text "unclosed" ]
        , Test.test "unclosed italic" <|
            \_ ->
                parser "_unclosed"
                    |> Expect.equal [ Text "_", Text "unclosed" ]
        , Test.test "unclosed code" <|
            \_ ->
                parser "`unclosed"
                    |> Expect.equal [ Text "`unclosed" ]
        , Test.test "unclosed code block" <|
            \_ ->
                parser "```unclosed"
                    |> Expect.equal [ Code "", Text "`unclosed" ]
        , Test.test "malformed ping (missing closing bracket)" <|
            \_ ->
                parser "<@!123456789"
                    |> Expect.equal [ Text "<@!123456789" ]
        , Test.test "malformed ping (missing exclamation)" <|
            \_ ->
                parser "<@123456789>"
                    |> Expect.equal [ Text "<@123456789>" ]
        , Test.test "malformed emoji (missing closing bracket)" <|
            \_ ->
                parser "<:smile:123456789"
                    |> Expect.equal [ Text "<:smile:123456789" ]
        , Test.test "malformed emoji (missing colon)" <|
            \_ ->
                parser "<smile:123456789>"
                    |> Expect.equal [ Text "<smile:123456789>" ]
        , Test.test "empty bold" <|
            \_ ->
                parser "****"
                    |> Expect.equal [ Italic [ Text "**" ] ]
        , Test.test "empty italic" <|
            \_ ->
                parser "__"
                    |> Expect.equal [ Text "__" ]
        , Test.test "invalid user ID in ping" <|
            \_ ->
                parser "<@!notanumber>"
                    |> Expect.equal [ Text "<@!notanumber>" ]
        , Test.test "invalid emoji ID" <|
            \_ ->
                parser "<:smile:notanumber>"
                    |> Expect.equal [ Text "<:smile:notanumber>" ]
        , Test.test "bold with trailing whitespace should work" <|
            \_ ->
                parser "** bold **"
                    |> Expect.equal [ Bold [ Text " bold " ] ]
        , Test.test "nested same formatting" <|
            \_ ->
                parser "**bold **nested** bold**"
                    |> Expect.equal [ Bold [ Text "bold " ], Text "nested", Bold [ Text " bold" ] ]
        ]


fuzzTests : Test
fuzzTests =
    Test.describe
        "Fuzz tests"
        [ Test.fuzz discordMarkdownFuzzer "Parser should not crash on random input" <|
            \input ->
                parser input
                    |> List.length
                    |> Expect.atLeast 0
        , Test.fuzz Fuzz.string "Any string should parse without error" <|
            \input ->
                parser input
                    |> (\result ->
                            case result of
                                [] ->
                                    if String.isEmpty input then
                                        Expect.pass

                                    else
                                        Expect.fail "Non-empty string should not result in empty parse"

                                _ ->
                                    Expect.pass
                       )
        ]


discordMarkdownFuzzer : Fuzz.Fuzzer String
discordMarkdownFuzzer =
    Fuzz.list
        (Fuzz.oneOfValues
            [ "a"
            , " "
            , "**"
            , "_"
            , "__"
            , "~~"
            , "||"
            , "`"
            , "```"
            , "<@!"
            , ">"
            , "<:"
            , ":"
            , "123456789"
            , "hello"
            , "\n"
            , "world"
            , "emoji"
            ]
        )
        |> Fuzz.map String.concat
