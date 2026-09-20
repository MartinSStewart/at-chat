module TwemojiTests exposing (tests)

import Dict
import Emoji exposing (EmojiCategory(..), TextOrEmoji(..))
import Expect
import Test exposing (Test)
import Twemoji


{-| Nothing type checks `Twemoji.fileName` against the art in `public/emoji`, so these pin
the cases where the name isn't simply every code point spelled out: a keycap drops its
variation selector, a zero width joiner sequence keeps them, and a flag is a pair of
regional indicators rather than one glyph.
-}
fileNameTests : Test
fileNameTests =
    Test.describe "fileName"
        [ Test.test "single code point" <|
            \_ -> Twemoji.fileName "😀" |> Expect.equal "1f600"
        , Test.test "skin tone modifier is kept" <|
            \_ -> Twemoji.fileName "👍🏽" |> Expect.equal "1f44d-1f3fd"
        , Test.test "variation selector is dropped" <|
            \_ -> Twemoji.fileName "⬇️" |> Expect.equal "2b07"
        , Test.test "keycap drops the variation selector but keeps the enclosing mark" <|
            \_ -> Twemoji.fileName "#️⃣" |> Expect.equal "23-20e3"
        , Test.test "variation selectors are kept in a zero width joiner sequence" <|
            \_ ->
                Twemoji.fileName "👩\u{200D}❤️\u{200D}👨"
                    |> Expect.equal "1f469-200d-2764-fe0f-200d-1f468"
        , Test.test "family is one file rather than four" <|
            \_ ->
                Twemoji.fileName "👨\u{200D}👩\u{200D}👧\u{200D}👦"
                    |> Expect.equal "1f468-200d-1f469-200d-1f467-200d-1f466"
        , Test.test "flag is a regional indicator pair" <|
            \_ -> Twemoji.fileName "🇸🇪" |> Expect.equal "1f1f8-1f1ea"
        , Test.test "a gendered sequence keeps the variation selector after the gender sign" <|
            \_ ->
                Twemoji.fileName "🧖\u{200D}♂️"
                    |> Expect.equal "1f9d6-200d-2642-fe0f"
        ]


{-| A handful of emoji in the shape the server sends them, enough to cover the cases the
splitter has to get right: one plain emoji, one that takes a skin tone, and one zero width
joiner sequence that begins with an emoji of its own.
-}
emojiData : Emoji.CachedEmojiData
emojiData =
    Emoji.fromResponse
        [ { emoji = "🎉", shortNames = [ "tada" ], category = Activities, skinVariations = Nothing }
        , { emoji = "👍"
          , shortNames = [ "+1" ]
          , category = PeopleAndBody
          , skinVariations = Just (Dict.fromList [ ( "1F3FB", "👍🏻" ) ])
          }
        , { emoji = "👨", shortNames = [ "man" ], category = PeopleAndBody, skinVariations = Nothing }
        , { emoji = "👩", shortNames = [ "woman" ], category = PeopleAndBody, skinVariations = Nothing }
        , { emoji = "👧", shortNames = [ "girl" ], category = PeopleAndBody, skinVariations = Nothing }
        , { emoji = "🧖", shortNames = [ "person_in_steamy_room" ], category = PeopleAndBody, skinVariations = Nothing }
        , { emoji = "🧖\u{200D}♂️"
          , shortNames = [ "man_in_steamy_room" ]
          , category = PeopleAndBody
          , skinVariations = Nothing
          }
        , { emoji = "👨\u{200D}👩\u{200D}👧"
          , shortNames = [ "family" ]
          , category = PeopleAndBody
          , skinVariations = Nothing
          }
        ]


{-| Text is searched for emoji character by character, so these pin what it finds: the
longest sequence rather than the emoji it begins with, a skin tone out of that tone's sprite
rather than the untoned one, and nothing at all where there's no artwork.
-}
splitOnEmojiTests : Test
splitOnEmojiTests =
    Test.describe "splitOnEmoji"
        [ Test.test "an emoji at the end of a sentence" <|
            \_ ->
                Emoji.splitOnEmoji emojiData "Party 🎉"
                    |> Expect.equal
                        [ PlainText "Party "
                        , EmojiArtwork { sequence = "🎉", sprite = "activities" }
                        ]
        , Test.test "text on both sides of it" <|
            \_ ->
                Emoji.splitOnEmoji emojiData "a🎉b"
                    |> Expect.equal
                        [ PlainText "a"
                        , EmojiArtwork { sequence = "🎉", sprite = "activities" }
                        , PlainText "b"
                        ]
        , Test.test "text with no emoji in it stays one piece" <|
            \_ -> Emoji.splitOnEmoji emojiData "nothing here" |> Expect.equal [ PlainText "nothing here" ]
        , Test.test "a skin tone comes out of that tone's sprite" <|
            \_ ->
                Emoji.splitOnEmoji emojiData "👍🏽"
                    |> Expect.equal [ EmojiArtwork { sequence = "👍🏽", sprite = "tone-3" } ]
        , Test.test "an untoned emoji comes out of its category's sprite" <|
            \_ ->
                Emoji.splitOnEmoji emojiData "👍"
                    |> Expect.equal [ EmojiArtwork { sequence = "👍", sprite = "people-body" } ]
        , Test.test "a joined sequence isn't mistaken for the emoji it begins with" <|
            \_ ->
                Emoji.splitOnEmoji emojiData "👨\u{200D}👩\u{200D}👧"
                    |> Expect.equal
                        [ EmojiArtwork
                            { sequence = "👨\u{200D}👩\u{200D}👧", sprite = "people-body" }
                        ]
        , Test.test "an emoji with no artwork is left as characters" <|
            \_ -> Emoji.splitOnEmoji emojiData "\u{1FAE9}" |> Expect.equal [ PlainText "\u{1FAE9}" ]
        , Test.test "a gendered sequence the font may draw as two glyphs is one piece of artwork" <|
            \_ ->
                Emoji.splitOnEmoji emojiData "🧖\u{200D}♂️"
                    |> Expect.equal
                        [ EmojiArtwork
                            { sequence = "🧖\u{200D}♂️", sprite = "people-body" }
                        ]
        , Test.test "two emoji in a row don't run together" <|
            \_ ->
                Emoji.splitOnEmoji emojiData "🎉👍"
                    |> Expect.equal
                        [ EmojiArtwork { sequence = "🎉", sprite = "activities" }
                        , EmojiArtwork { sequence = "👍", sprite = "people-body" }
                        ]
        ]


tests : Test
tests =
    Test.describe "Twemoji" [ fileNameTests, splitOnEmojiTests ]
