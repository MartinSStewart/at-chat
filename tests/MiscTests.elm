module MiscTests exposing (tests)

import Backend
import DiscordSync
import Effect.Time as Time
import Emoji exposing (EmojiOrCustomEmoji(..))
import Expect
import Id exposing (CustomEmojiId, Id)
import Pages.Guild exposing (HighlightMessage(..), IsHovered(..))
import SeqSet
import Test exposing (Test)
import User
import UserAgent


tests : Test
tests =
    Test.describe
        "Misc tests"
        [ Test.test "Round trip message view encoding" <|
            \_ ->
                let
                    input =
                        { isMobile = False
                        , containerWidth = 400
                        , isEditing = True
                        , highlight = MentionHighlight
                        , isHovered = IsHovered
                        , time = Time.millisToPosix 1786013400000
                        }
                in
                Pages.Guild.encodeMessageView input.isMobile input.isHovered input.containerWidth input.isEditing input.highlight input.time
                    |> Pages.Guild.decodeMessageView
                    |> Expect.equal input
        , Test.test "Round trip message view encoding 2" <|
            \_ ->
                let
                    input =
                        { isMobile = True
                        , containerWidth = 2000
                        , isEditing = False
                        , highlight = NoHighlight
                        , isHovered = IsHoveredButNoMenu
                        , -- Only whole minutes survive the round trip, which is all the
                          -- timestamps in a message need
                          time = Time.millisToPosix 1786013400000
                        }
                in
                Pages.Guild.encodeMessageView input.isMobile input.isHovered input.containerWidth input.isEditing input.highlight input.time
                    |> Pages.Guild.decodeMessageView
                    |> Expect.equal input
        , Test.test "Discord thread name is left as is when it's short enough" <|
            \_ ->
                DiscordSync.threadName "Hello world!"
                    |> Expect.equal "Hello world!"
        , Test.test "Discord thread name is shortened to 100 characters" <|
            \_ ->
                DiscordSync.threadName (String.repeat 50 "ab")
                    |> String.length
                    |> Expect.equal 100
        , Test.test "Discord thread name doesn't end with a partial word's trailing space" <|
            \_ ->
                DiscordSync.threadName (String.repeat 33 "abc ")
                    |> Expect.equal (String.repeat 24 "abc " ++ "abc")
        , Test.test "Discord thread name collapses whitespace onto a single line" <|
            \_ ->
                DiscordSync.threadName "  Hello\n\nworld!  "
                    |> Expect.equal "Hello world!"
        , Test.test "Discord thread name falls back to a placeholder when the message has no text" <|
            \_ ->
                DiscordSync.threadName "   "
                    |> Expect.equal "Thread"
        , Test.test "Commonly used emojis keeps a custom emoji the conversation can use" <|
            \_ ->
                User.commonlyUsedEmojis
                    (SeqSet.singleton usableCustomEmoji)
                    (User.addRecentlyUsedEmojis
                        (List.repeat 3 (EmojiOrCustomEmoji_CustomEmoji usableCustomEmoji))
                        Backend.adminUser
                    )
                    |> List.map Tuple.first
                    |> Expect.equal
                        [ EmojiOrCustomEmoji_CustomEmoji usableCustomEmoji
                        , EmojiOrCustomEmoji_Emoji Emoji.heart
                        , EmojiOrCustomEmoji_Emoji Emoji.thumbsUp
                        , EmojiOrCustomEmoji_Emoji Emoji.smiley
                        ]
        , Test.test "Commonly used emojis drops a custom emoji the conversation can't use" <|
            \_ ->
                User.commonlyUsedEmojis
                    (SeqSet.singleton usableCustomEmoji)
                    (User.addRecentlyUsedEmojis
                        (List.repeat 5 (EmojiOrCustomEmoji_CustomEmoji unusableCustomEmoji))
                        Backend.adminUser
                    )
                    |> List.map Tuple.first
                    |> Expect.equal
                        [ EmojiOrCustomEmoji_Emoji Emoji.heart
                        , EmojiOrCustomEmoji_Emoji Emoji.thumbsUp
                        , EmojiOrCustomEmoji_Emoji Emoji.smiley
                        ]
        , Test.describe
            "Parse device from user agent"
            (List.map
                (\( userAgentString, expected ) ->
                    Test.test (UserAgent.deviceToString expected ++ ": " ++ userAgentString) <|
                        \_ ->
                            UserAgent.parseUserAgent userAgentString
                                |> .device
                                |> Expect.equal expected
                )
                [ ( "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1"
                  , UserAgent.IPhone
                  )
                , ( "Mozilla/5.0 (iPad; CPU OS 12_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.1 Mobile/15E148 Safari/604.1"
                  , UserAgent.IPad
                  )
                , ( "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Mobile Safari/537.36"
                  , UserAgent.AndroidPhone
                  )
                , ( "Mozilla/5.0 (Linux; Android 13; SM-X200) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"
                  , UserAgent.AndroidTablet
                  )
                , ( "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:124.0) Gecko/20100101 Firefox/124.0"
                  , UserAgent.Windows
                  )
                , ( "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Safari/605.1.15"
                  , UserAgent.MacOS
                  )
                , ( "Mozilla/5.0 (X11; CrOS x86_64 14541.0.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"
                  , UserAgent.ChromeOS
                  )
                , ( "Mozilla/5.0 (X11; Linux x86_64; rv:124.0) Gecko/20100101 Firefox/124.0"
                  , UserAgent.Linux
                  )
                , ( "Mozilla/5.0 (Unknown; Mobile) SomeBrowser/1.0"
                  , UserAgent.Mobile
                  )
                , ( "Mozilla/5.0 (Unknown; Tablet) SomeBrowser/1.0"
                  , UserAgent.Tablet
                  )
                , ( "SomeBrowser/1.0"
                  , UserAgent.Desktop
                  )
                ]
            )
        ]


usableCustomEmoji : Id CustomEmojiId
usableCustomEmoji =
    Id.fromInt 1


unusableCustomEmoji : Id CustomEmojiId
unusableCustomEmoji =
    Id.fromInt 2
