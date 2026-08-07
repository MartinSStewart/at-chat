module MiscTests exposing (tests)

import Effect.Time as Time
import Expect
import Pages.Guild exposing (HighlightMessage(..), IsHovered(..))
import Test exposing (Test)


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
        ]
