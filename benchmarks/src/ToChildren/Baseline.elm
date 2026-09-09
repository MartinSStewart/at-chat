module ToChildren.Baseline exposing (toChildren, toChildrenKeyed)

{-| A verbatim copy of `Internal.Model2.toChildren` as it stands today, so the benchmark
compares against what the app actually runs.
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
        behind ++ List.map (\(Element toChild) -> toChild myBits) children ++ after

    else
        List.map (\(Element toChild) -> toChild myBits) children


toChildrenKeyed :
    Inheritance.Encoded
    -> AnalyzeBits.Encoded
    -> List (Attribute msg)
    -> List ( String, Element msg )
    -> List ( String, Html.Html msg )
toChildrenKeyed myBits analyzedBits attrs children =
    if BitField.has AnalyzeBits.nearbys analyzedBits then
        let
            behind =
                toBehindElements myBits [] attrs
                    |> List.map (Tuple.pair "behind")

            after =
                toNearbyElements myBits [] attrs
                    |> List.map (Tuple.pair "after")
        in
        behind
            ++ List.map (\( key, Element toChild ) -> ( key, toChild myBits )) children
            ++ after

    else
        List.map (\( key, Element toChild ) -> ( key, toChild myBits )) children
