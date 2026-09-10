module ToChildren.Foldl exposing (toChildren)

{-| The same thing with `List.foldl` and `List.reverse` in place of `List.map`, kept as a
middle point between the current version and the hand written loops.
-}

import Html
import Internal.BitField as BitField
import Internal.Bits.Analyze as AnalyzeBits
import Internal.Bits.Inheritance as Inheritance
import Internal.Model2 exposing (Attribute, Element(..), toBehindElements, toNearbyElements)


toChildren :
    Inheritance.Encoded
    -> AnalyzeBits.Encoded
    -> List (Attribute msg)
    -> List (Element msg)
    -> List (Html.Html msg)
toChildren myBits analyzedBits attrs children =
    if BitField.has AnalyzeBits.nearbys analyzedBits then
        let
            behind =
                toBehindElements myBits [] attrs

            after =
                toNearbyElements myBits [] attrs
        in
        behind ++ unwrapChildren myBits after children

    else
        unwrapChildren myBits [] children


unwrapChildren :
    Inheritance.Encoded
    -> List (Html.Html msg)
    -> List (Element msg)
    -> List (Html.Html msg)
unwrapChildren inheritance rest children =
    List.foldl
        (\(Element toChild) rendered -> toChild inheritance :: rendered)
        []
        children
        |> List.foldl (::) rest
