module MiscTests exposing (tests)

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
                        { containerWidth = 400, isEditing = True, highlight = MentionHighlight, isHovered = IsHovered }
                in
                Pages.Guild.messageViewEncode input.isHovered input.containerWidth input.isEditing input.highlight
                    |> Pages.Guild.messageViewDecode
                    |> Expect.equal input
        , Test.test "Round trip message view encoding 2" <|
            \_ ->
                let
                    input =
                        { containerWidth = 2000, isEditing = False, highlight = NoHighlight, isHovered = IsHoveredButNoMenu }
                in
                Pages.Guild.messageViewEncode input.isHovered input.containerWidth input.isEditing input.highlight
                    |> Pages.Guild.messageViewDecode
                    |> Expect.equal input
        ]
