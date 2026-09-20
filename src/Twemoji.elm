module Twemoji exposing (fileName, overlaySpriteView, spriteView)

{-| Draws unicode emoji as the Twemoji artwork served from `public/emoji`, so that an
emoji looks the same on every device instead of each one substituting its own set.

The art ships as sprites rather than a file per emoji, since a file each costs a request
each and the selector puts around a hundred and fifty of them on screen at once.
`scripts/fetch-twemoji.py` writes them.

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


{-| Twemoji names its art after the emoji's code points in hex, joined by `-`, and leaves
out the variation selector unless the sequence also contains a zero width joiner. A
sequence that reaches here without matching art would ask for a symbol that isn't
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


spriteUrl : String -> String
spriteUrl sprite =
    "/cacheable/emoji/" ++ sprite ++ ".svg"


{-| What a `use` points at for one emoji.
-}
spriteReference : String -> String -> String
spriteReference sprite emoji =
    spriteUrl sprite ++ "#" ++ symbolId emoji


{-| An id can't begin with a digit and most of these would, so the names the sprites are
built with carry a prefix.
-}
symbolId : String -> String
symbolId emoji =
    "e" ++ fileName emoji


{-| The browser reads the sprite once however many of these point at it, so a grid of them
costs one request rather than one each. A `use` pointing at a symbol the browser hasn't
read yet starts drawing as soon as it arrives.

`yOffset` is how far down to nudge it, the same as `CustomEmoji.view` takes, since an emoji
sitting inline in a line of text wants to sit lower than the baseline puts it.

-}
spriteView : String -> String -> String -> String -> Html msg
spriteView size yOffset sprite emoji =
    Html.span
        [ Html.Attributes.style "display" "inline-block" ]
        [ Svg.svg
            [ Svg.Attributes.viewBox "0 0 36 36"
            , Html.Attributes.style "width" size
            , Html.Attributes.style "height" size
            , Html.Attributes.style "display" "inline-block"
            , Html.Attributes.style "transform" ("translateY(" ++ yOffset ++ ")")
            ]
            [ Svg.use
                [ Svg.Attributes.xlinkHref (spriteReference sprite emoji) ]
                []
            ]
        , -- Copying a message has to give back the emoji rather than a gap where the picture
          -- was, and a screen reader needs something to read out. A `use` carries no text of
          -- its own the way an `img` carries its alt, so the characters ride alongside it at
          -- no size: selected and copied, but taking up nothing and drawing nothing.
          Html.span
            [ Html.Attributes.style "font-size" "0" ]
            [ Html.text emoji ]
        ]


{-| Like `spriteView`, but for text drawn on top of a textarea. There the picture has to take up
exactly the room the font gives the characters, or the caret in the textarea below drifts away
from the text as soon as a line contains an emoji. How much room that is differs by device, since
a font without a glyph for a joined sequence draws its pieces side by side instead. So the
characters stay at full size and keep doing the layout, hidden rather than taken out, and the
artwork is drawn over the space they take, in the middle of it and at a size of its own.
-}
overlaySpriteView : String -> String -> String -> Html msg
overlaySpriteView size sprite emoji =
    Html.span
        [ Html.Attributes.style "position" "relative"
        , Html.Attributes.style "visibility" "hidden"
        ]
        [ Html.text emoji
        , Svg.svg
            [ Svg.Attributes.viewBox "0 0 36 36"
            , Svg.Attributes.preserveAspectRatio "xMidYMid meet"
            , Html.Attributes.style "visibility" "visible"
            , Html.Attributes.style "position" "absolute"
            , Html.Attributes.style "left" "50%"
            , Html.Attributes.style "top" "50%"
            , Html.Attributes.style "width" size
            , Html.Attributes.style "height" size
            , Html.Attributes.style "transform" "translate(-50%, -50%)"
            ]
            [ Svg.use
                [ Svg.Attributes.xlinkHref (spriteReference sprite emoji) ]
                []
            ]
        ]
