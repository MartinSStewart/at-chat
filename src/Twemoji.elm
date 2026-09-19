module Twemoji exposing (fileName, spriteUrl, spriteView, url, view)

{-| Draws unicode emoji as the Twemoji artwork served from `public/emoji`, so that an
emoji looks the same on every device instead of each one substituting its own set.

`view` draws one emoji from its own file and `spriteView` draws one out of a sprite holding
a whole category. A few emoji in a row are cheaper as their own files; a grid of them is
cheaper as a sprite, since a file each costs a request each.

`scripts/fetch-twemoji.py` puts both there.

-}

import Hex
import Html exposing (Html)
import Html.Attributes
import Svg
import Svg.Attributes


zeroWidthJoiner : Int
zeroWidthJoiner =
    0x200D


variationSelector : Int
variationSelector =
    0xFE0F


{-| Twemoji names a file after the emoji's code points in hex, joined by `-`, and leaves
out the variation selector unless the sequence also contains a zero width joiner. A
sequence that reaches here without matching art would ask for a file that isn't
there, so `scripts/fetch-twemoji.py` checks every emoji in `public/compact-emoji.json`
against the art it copies.
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


spriteUrl : String -> String
spriteUrl sprite =
    "/emoji/sprites/" ++ sprite ++ ".svg"


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


{-| An id can't begin with a digit and most of these would, so the names the sprites are
built with carry a prefix.
-}
symbolId : String -> String
symbolId emoji =
    "e" ++ fileName emoji


{-| The browser reads the sprite once however many of these point at it, so a grid of them
costs one request rather than one each.

Unlike `view` there's no alt text to give: a `use` is a reference to a shape rather than an
image of its own. Anywhere emoji are copied out of, `view` is what draws them.

-}
spriteView : String -> String -> String -> Html msg
spriteView size sprite emoji =
    Svg.svg
        [ Svg.Attributes.viewBox "0 0 36 36"
        , Html.Attributes.style "width" size
        , Html.Attributes.style "height" size
        , Html.Attributes.style "display" "inline-block"
        ]
        [ Svg.use
            [ Svg.Attributes.xlinkHref (spriteUrl sprite ++ "#" ++ symbolId emoji) ]
            []
        ]
