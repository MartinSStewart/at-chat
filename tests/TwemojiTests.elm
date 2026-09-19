module TwemojiTests exposing (tests)

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
        ]


tests : Test
tests =
    Test.describe "Twemoji" [ fileNameTests ]
