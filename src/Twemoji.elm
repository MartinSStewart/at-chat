module Twemoji exposing (fileName, url, view)

{-| Draws unicode emoji as the Twemoji artwork served from `public/emoji`, so that an
emoji looks the same on every device instead of each one substituting its own set.

`scripts/fetch-twemoji.py` puts the art there.

-}

import Hex
import Html exposing (Html)
import Html.Attributes


zeroWidthJoiner : Int
zeroWidthJoiner =
    0x200D


variationSelector : Int
variationSelector =
    0xFE0F


{-| Twemoji names a file after the emoji's code points in hex, joined by `-`, and leaves
out the variation selector unless the sequence also contains a zero width joiner. A
sequence that reaches here without matching art would ask for a file that isn't
there, so `scripts/fetch-twemoji.py` checks every emoji in `public/emoji.json` against
the art it copies.
-}
fileName : String -> String
fileName emoji =
    let
        codePoints : List Int
        codePoints =
            String.toList emoji |> List.map Char.toCode
    in
    (if List.member zeroWidthJoiner codePoints then
        codePoints

     else
        List.filter (\codePoint -> codePoint /= variationSelector) codePoints
    )
        |> List.map Hex.toString
        |> String.join "-"


url : String -> String
url emoji =
    "/emoji/" ++ fileName emoji ++ ".svg"


{-| The alt text is the emoji itself so that copying a message out of the page still
yields the characters rather than nothing.
-}
view : String -> String -> Html msg
view size emoji =
    Html.img
        [ Html.Attributes.src (url emoji)
        , Html.Attributes.alt emoji
        , Html.Attributes.style "width" size
        , Html.Attributes.style "height" size
        , Html.Attributes.style "display" "inline-block"
        ]
        []
