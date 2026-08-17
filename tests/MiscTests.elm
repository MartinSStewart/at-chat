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
        ]


usableCustomEmoji : Id CustomEmojiId
usableCustomEmoji =
    Id.fromInt 1


unusableCustomEmoji : Id CustomEmojiId
unusableCustomEmoji =
    Id.fromInt 2
