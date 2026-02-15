module DiscordMarkdownTests exposing (test)

import Discord.Id
import Expect
import Id
import List.Nonempty exposing (Nonempty(..))
import OneToOne exposing (OneToOne)
import RichText exposing (RichText(..))
import Test exposing (Test)
import UInt64
import Unsafe


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


users : OneToOne (Discord.Id.Id idType) (Id.Id a)
users =
    OneToOne.fromList
        [ ( case UInt64.fromString "137748026084163580" of
                Just uint ->
                    Discord.Id.fromUInt64 uint

                Nothing ->
                    Debug.todo "Invalid ID"
          , Id.fromInt 0
          )
        ]


fromDiscordHelper : String -> List (RichText (Discord.Id.Id Discord.Id.UserId))
fromDiscordHelper text =
    RichText.fromDiscord text |> List.Nonempty.toList


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
        ]


userId : Discord.Id.Id Discord.Id.UserId
userId =
    Unsafe.uint64 "137748026084163580" |> Discord.Id.fromUInt64


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
        --            |> Expect.equal [ CustomEmoji "smile" (Discord.Id.fromUInt64 (UInt64.fromString "123456789" |> Maybe.withDefault UInt64.zero)) ]
        --, Test.test "custom emoji with text" <|
        --    \_ ->
        --        fromDiscordHelper "Hello <:wave:987654321> world"
        --            |> Expect.equal
        --                [ NormalText "Hello "
        --                , CustomEmoji "wave" (Discord.Id.fromUInt64 (UInt64.fromString "987654321" |> Maybe.withDefault UInt64.zero))
        --                , NormalText " world"
        --                ]
        --, Test.test "multiple pings" <|
        --    \_ ->
        --        fromDiscordHelper "<@!123> and <@!456>"
        --            |> Expect.equal
        --                [ Ping (Discord.Id.fromUInt64 (UInt64.fromString "123" |> Maybe.withDefault UInt64.zero))
        --                , NormalText " and "
        --                , Ping (Discord.Id.fromUInt64 (UInt64.fromString "456" |> Maybe.withDefault UInt64.zero))
        --                ]
        --, Test.test "ping inside formatting" <|
        --    \_ ->
        --        fromDiscordHelper "**Hello <@!137748026084163580>**"
        --            |> Expect.equal
        --                [ Bold
        --                    [ NormalText "Hello "
        --                    , Ping (Discord.Id.fromUInt64 (UInt64.fromString "123456789" |> Maybe.withDefault UInt64.zero))
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
