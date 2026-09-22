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


spriteReference : String -> String -> String
spriteReference sprite emoji =
    "/cacheable/emoji/" ++ sprite ++ ".svg#e" ++ fileName emoji


spriteView : String -> String -> String -> String -> Html msg
spriteView size yOffset sprite emoji =
    Html.span
        [ Html.Attributes.style "display" "inline-block" ]
        [ Svg.svg
            [ Svg.Attributes.viewBox "0 0 36 36"
            , Html.Attributes.style "width" size
            , Html.Attributes.style "height" size
            , Html.Attributes.style "display" "inline-block"
            , Html.Attributes.style "transform" "translateY(yOffset)"
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
