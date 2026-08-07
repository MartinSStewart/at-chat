module DiscordMarkdownTests exposing (test)

import CustomEmoji exposing (EmojiName)
import Discord
import Effect.Time as Time
import Expect
import Fuzz
import Id exposing (CustomEmojiId, Id)
import List.Nonempty exposing (Nonempty(..))
import OneToOne exposing (OneToOne)
import RichText exposing (DiscordCustomEmojiIdAndName, HasLeadingLineBreak(..), RichText(..))
import RichTextTests
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
        , escapingTests
        , roundTripTests

        --, codeTests
        --, edgeCaseTests
        --, fuzzTests
        ]


customEmojis : OneToOne DiscordCustomEmojiIdAndName (Id CustomEmojiId)
customEmojis =
    OneToOne.fromList
        [ ( { isAnimated = False, id = Unsafe.uint64 "543" |> Discord.idFromUInt64, name = Unsafe.emojiName "abc" }, Id.fromInt 999 )
        , ( { isAnimated = True, id = discordId, name = emojiName }, Id.fromInt 888 )
        ]


discordId : Discord.Id idType
discordId =
    Unsafe.uint64 "444" |> Discord.idFromUInt64


emojiName : EmojiName
emojiName =
    Unsafe.emojiName "z_"


fromDiscordHelper : String -> List (RichText (Discord.Id Discord.UserId))
fromDiscordHelper text =
    RichText.fromDiscord text SeqDict.empty Discord.Missing customEmojis [] Discord.Missing |> List.Nonempty.toList


{-| What Discord is sent when someone writes `source` in at-chat.
-}
toDiscordTest : String -> String -> Test
toDiscordTest source expected =
    Test.test
        (Debug.toString source ++ " is sent to Discord as " ++ Debug.toString expected)
        (\_ ->
            case String.Nonempty.fromString source of
                Just nonempty ->
                    RichText.fromNonemptyString SeqDict.empty nonempty
                        |> RichText.toDiscord customEmojis
                        |> Expect.equal (Ok expected)

                Nothing ->
                    Expect.fail "Empty source text"
        )


{-| Everything at-chat reads as plain text but Discord could read as formatting is hidden
behind a backslash. Discord takes the backslashes off again when it renders the message, and
`roundTripTests` covers at-chat doing the same.
-}
escapingTests : Test
escapingTests =
    Test.describe
        "Escaping text sent to Discord"
        [ toDiscordTest "_" "\\_"
        , toDiscordTest "a_b" "a\\_b"
        , toDiscordTest "5 * 3" "5 \\* 3"
        , toDiscordTest "a ` b" "a \\` b"
        , toDiscordTest "1 ~ 2" "1 \\~ 2"
        , toDiscordTest "a@b.com" "a\\@b.com"
        , toDiscordTest "2 > 1" "2 \\> 1"
        , -- A backslash needs escaping too, or Discord reads it as escaping what follows
          toDiscordTest "back\\slash" "back\\\\slash"
        , -- at-chat writes its own formatting out as Discord's
          toDiscordTest "*bold*" "**bold**"
        , toDiscordTest "_italic_" "*italic*"
        , toDiscordTest "`code`" "`code`"
        , toDiscordTest "__underline__" "__underline__"
        ]


{-| The bug this is here for: at-chat escaped `_` on the way out but only took the backslash
off a handful of characters on the way back in, so `_` came home as `\_` and `__` as `\_\_`.

Sending and reading back can't line up exactly, because `_` and `\_` typed into at-chat are
different pieces of rich text (`NormalText` and `EscapedChar`) that Discord has only one way
to write. They show the same thing to a reader, so `withoutEscapedChars` treats them as equal.

-}
roundTripTests : Test
roundTripTests =
    Test.describe
        "A message survives being sent to Discord and read back"
        [ roundTripTest "_"
        , roundTripTest "__"
        , roundTripTest "___"
        , roundTripTest "\\_"
        , roundTripTest "a_b"
        , roundTripTest "5 * 3 and 2 * 2"
        , roundTripTest "a@b.com"
        , roundTripTest "2 > 1"
        , roundTripTest "back\\slash"
        , roundTripTest "C:\\Users\\me"
        , roundTripTest "¯\\_(ツ)_/¯"
        , roundTripTest "*bold* and _italic_ and `code`"
        , roundTripTest "https://abc.com"
        , -- A backslash in front of an address isn't escaping anything, so the address is
          -- still an address and the backslash is text in front of it
          roundTripTest "\\http://a.com"
        , -- Text that starts out looking like an address but isn't one stays text, and the
          -- escaping that carries it to Discord doesn't split it into an address and a piece
          -- of text on the way back
          roundTripTest "http://a.comhttp://a.com"
        , roundTripTest "http://a.com_http://a.com"
        , roundTripTest "http://a.com@|"
        , roundTripTest "two\nlines"
        , roundTripTest "> quoted"
        , roundTripTest "a\n> quoted"
        , roundTripTest "# heading"
        , roundTripTest "* bullet\n* points"
        , roundTripTest "a link https://abc.com/a_b in the middle"
        , Test.fuzz
            sourceTextFuzzer
            "Text at-chat reads as plain text comes home as the same plain text"
            (\source ->
                let
                    written : Nonempty (RichText (Discord.Id Discord.UserId))
                    written =
                        RichText.fromNonemptyString SeqDict.empty source
                in
                if List.Nonempty.all isPlainText written then
                    expectSurvivesDiscord source

                else
                    -- Text at-chat reads as formatting is left to the cases above. Escaping
                    -- is what this is here for, and that only ever applies to plain text.
                    Expect.pass
            )
        ]


roundTripTest : String -> Test
roundTripTest source =
    Test.test
        (Debug.toString source ++ " survives the trip")
        (\_ ->
            case String.Nonempty.fromString source of
                Just nonempty ->
                    expectSurvivesDiscord nonempty

                Nothing ->
                    Expect.fail "Empty source text"
        )


{-| Text someone might type into at-chat, built out of the pieces that decide how it gets
escaped on the way to Discord.

Addresses are left out. A backslash in front of a link stops at-chat making it a link, and
Discord has no way of writing that down — it makes a link of any address it sees — so
`\https://abc.com` can't come home as what it left as, however it's escaped.

-}
sourceTextFuzzer : Fuzz.Fuzzer NonemptyString
sourceTextFuzzer =
    Fuzz.list
        (Fuzz.oneOfValues
            [ "_"
            , "*"
            , "~"
            , "`"
            , "|"
            , "\\"
            , ">"
            , "<"
            , "@"
            , "#"
            , "["
            , "]"
            , "__"
            , "**"
            , "~~"
            , "||"
            , "```"
            , "a"
            , "t"
            , "h"
            , "http://a.com"
            , "/"
            , "1"
            , " "
            , "\n"
            , "\n> "
            , "@everyone"
            , "¯\\_(ツ)_/¯"
            ]
        )
        |> Fuzz.map
            (\list ->
                -- Discord has no message with nothing but whitespace in it, and trims what
                -- hangs off either end of the ones it does have, so text that only differs
                -- there isn't text this has to hold for
                String.concat list
                    |> String.trim
                    |> String.Nonempty.fromString
                    |> Maybe.withDefault (NonemptyString 'a' "")
            )


{-| Whether at-chat read this as text rather than as formatting. Only text is ever escaped.
-}
isPlainText : RichText userId -> Bool
isPlainText item =
    case item of
        NormalText _ _ ->
            True

        EscapedChar _ ->
            True

        _ ->
            False


expectSurvivesDiscord : NonemptyString -> Expect.Expectation
expectSurvivesDiscord source =
    let
        written : Nonempty (RichText (Discord.Id Discord.UserId))
        written =
            RichText.fromNonemptyString SeqDict.empty source
    in
    case RichText.toDiscord customEmojis written of
        Ok sent ->
            RichText.fromDiscord sent SeqDict.empty Discord.Missing customEmojis [] Discord.Missing
                |> List.Nonempty.toList
                |> withoutEscapedChars
                |> Expect.equal (withoutEscapedChars (List.Nonempty.toList written))
                |> Expect.onFail
                    ("Sent to Discord as "
                        ++ Debug.toString sent
                        ++ " which at-chat reads as "
                        ++ Debug.toString
                            (RichText.fromDiscord sent SeqDict.empty Discord.Missing customEmojis [] Discord.Missing
                                |> List.Nonempty.toList
                            )
                        ++ " instead of "
                        ++ Debug.toString (List.Nonempty.toList written)
                    )

        Err _ ->
            Expect.pass


{-| A character someone escaped in at-chat and the same character on its own say the same
thing to a reader, and Discord has one way of writing both, so the two are levelled out
before comparing. Adjacent pieces of text are joined up for the same reason: whether `a_b`
arrives as one piece or three isn't something a reader can tell.
-}
withoutEscapedChars : List (RichText userId) -> List (RichText userId)
withoutEscapedChars list =
    List.map
        (\item ->
            case item of
                EscapedChar char ->
                    RichText.escapedCharToString char |> plainText

                Bold nonempty ->
                    Bold (withoutEscapedCharsNonempty nonempty)

                Italic nonempty ->
                    Italic (withoutEscapedCharsNonempty nonempty)

                Underline nonempty ->
                    Underline (withoutEscapedCharsNonempty nonempty)

                Strikethrough nonempty ->
                    Strikethrough (withoutEscapedCharsNonempty nonempty)

                Spoiler nonempty ->
                    Spoiler (withoutEscapedCharsNonempty nonempty)

                BlockQuote a list2 ->
                    BlockQuote a (withoutEscapedChars list2)

                Heading level a nonempty ->
                    Heading level a (withoutEscapedCharsNonempty nonempty)

                BulletPoint a items ->
                    BulletPoint a (List.Nonempty.map withoutEscapedChars items)

                _ ->
                    item
        )
        list
        |> joinAdjacentText


withoutEscapedCharsNonempty : Nonempty (RichText userId) -> Nonempty (RichText userId)
withoutEscapedCharsNonempty nonempty =
    case withoutEscapedChars (List.Nonempty.toList nonempty) |> List.Nonempty.fromList of
        Just nonempty2 ->
            nonempty2

        Nothing ->
            nonempty


plainText : String -> RichText userId
plainText text =
    case String.Nonempty.fromString text of
        Just (NonemptyString char rest) ->
            NormalText char rest

        Nothing ->
            NormalText ' ' ""


joinAdjacentText : List (RichText userId) -> List (RichText userId)
joinAdjacentText list =
    List.foldr
        (\item acc ->
            case ( item, acc ) of
                ( NormalText charA restA, (NormalText charB restB) :: rest ) ->
                    NormalText charA (restA ++ String.cons charB restB) :: rest

                _ ->
                    item :: acc
        )
        []
        list


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
        , RichTextTests.simpleTest
            "Extract discord emojis"
            "<:z_:444>"
            [ { isAnimated = False, id = discordId, name = emojiName } ]
            RichText.customEmojisFromDiscord
        , RichTextTests.simpleTest
            "Extract animated discord emojis"
            "Animated! <a:z_:444>"
            [ { isAnimated = True, id = discordId, name = emojiName } ]
            RichText.customEmojisFromDiscord
        , fromNonemptyStringTest
            "[url has leading space]( https://example.com/)"
            (Nonempty (MarkdownLink (NonemptyString 'u' "rl has leading space") (unsafeUrl "https://example.com/")) [])
        , fromNonemptyStringTest
            "[url has leading line break](\nhttps://example.com/)"
            (Nonempty (MarkdownLink (NonemptyString 'u' "rl has leading line break") (unsafeUrl "https://example.com/")) [])
        , fromNonemptyStringTest "https://a.com/abc]" (Nonempty (Hyperlink (unsafeUrl "https://a.com/abc")) [ NormalText ']' "" ])
        , fromNonemptyStringTest "https://a.com/abc]d" (Nonempty (Hyperlink (unsafeUrl "https://a.com/abc]d")) [])
        , fromNonemptyStringTest "https://a.com/abc(123)" (Nonempty (Hyperlink (unsafeUrl "https://a.com/abc(123)")) [])
        , fromNonemptyStringTest "(https://a.com/abc(123)" (Nonempty (NormalText '(' "") [ Hyperlink (unsafeUrl "https://a.com/abc(123)") ])
        , fromNonemptyStringTest "(https://a.com/abc(123))" (Nonempty (NormalText '(' "") [ Hyperlink (unsafeUrl "https://a.com/abc(123)"), NormalText ')' "" ])
        , fromNonemptyStringTest "https://a.com/abc123)" (Nonempty (Hyperlink (unsafeUrl "https://a.com/abc123")) [ NormalText ')' "" ])
        , fromNonemptyStringTest "https://a.com/abc1(23))" (Nonempty (Hyperlink (unsafeUrl "https://a.com/abc1(23))")) [])
        , fromNonemptyStringTest "* a" (Nonempty (BulletPoint NoLeadingLineBreak (Nonempty [ NormalText 'a' "" ] [])) [])
        , fromNonemptyStringTest
            -- Discord trims trailing whitespace from messages, so the trailing line break is removed
            "* a\n"
            (Nonempty (BulletPoint NoLeadingLineBreak (Nonempty [ NormalText 'a' "" ] [])) [])
        , fromNonemptyStringTest
            -- Discord trims trailing whitespace, so "* a\n* " becomes "* a\n*"
            "* a\n* "
            (Nonempty (BulletPoint NoLeadingLineBreak (Nonempty [ NormalText 'a' "" ] [])) [ NormalText '\n' "*" ])
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
                (BulletPoint
                    NoLeadingLineBreak
                    (Nonempty [ Italic (Nonempty (NormalText 'a' "bc") []) ] [])
                )
                []
            )
        , fromNonemptyStringTest "- a" (Nonempty (BulletPoint NoLeadingLineBreak (Nonempty [ NormalText 'a' "" ] [])) [])
        , fromNonemptyStringTest
            -- Discord trims trailing whitespace from messages, so the trailing line break is removed
            "- a\n"
            (Nonempty (BulletPoint NoLeadingLineBreak (Nonempty [ NormalText 'a' "" ] [])) [])
        , fromNonemptyStringTest
            -- Discord trims trailing whitespace, so "- a\n- " becomes "- a\n-"
            "- a\n- "
            (Nonempty (BulletPoint NoLeadingLineBreak (Nonempty [ NormalText 'a' "" ] [])) [ NormalText '\n' "-" ])
        , fromNonemptyStringTest
            "abc\n- a"
            (Nonempty (NormalText 'a' "bc") [ BulletPoint HasLeadingLineBreak (Nonempty [ NormalText 'a' "" ] []) ])
        , fromNonemptyStringTest
            "- a\n- \n- b"
            (Nonempty
                (BulletPoint
                    NoLeadingLineBreak
                    (Nonempty [ NormalText 'a' "" ] [ [], [ NormalText 'b' "" ] ])
                )
                []
            )
        , fromNonemptyStringTest
            "- *abc*"
            (Nonempty
                (BulletPoint
                    NoLeadingLineBreak
                    (Nonempty [ Italic (Nonempty (NormalText 'a' "bc") []) ] [])
                )
                []
            )
        , fromNonemptyStringTest
            "* a\n- \n- b"
            (Nonempty
                (BulletPoint
                    NoLeadingLineBreak
                    (Nonempty [ NormalText 'a' "" ] [ [], [ NormalText 'b' "" ] ])
                )
                []
            )
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
        , Test.test "timestamp with a format hint" <|
            \_ ->
                fromDiscordHelper "<t:1786013400:s>"
                    |> Expect.equal [ Timestamp (Time.millisToPosix 1786013400000) ]
        , Test.test "timestamp without a format hint" <|
            \_ ->
                fromDiscordHelper "<t:1786013400>"
                    |> Expect.equal [ Timestamp (Time.millisToPosix 1786013400000) ]
        , Test.test "timestamp with text around it" <|
            \_ ->
                fromDiscordHelper "Starts at <t:1786013400:f>, be there"
                    |> Expect.equal
                        [ NormalText 'S' "tarts at "
                        , Timestamp (Time.millisToPosix 1786013400000)
                        , NormalText ',' " be there"
                        ]
        , Test.test "a timestamp missing its closing bracket stays text" <|
            \_ ->
                fromDiscordHelper "<t:1786013400:f"
                    |> Expect.equal [ NormalText '<' "t:1786013400:f" ]
        , Test.test "a timestamp without a time stays text" <|
            \_ ->
                fromDiscordHelper "<t::f>"
                    |> Expect.equal [ NormalText '<' "t::f>" ]

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
