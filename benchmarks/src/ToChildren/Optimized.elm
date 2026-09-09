module ToChildren.Optimized exposing (toChildren, toChildrenKeyed)

{-| The candidate: two tail recursive loops instead of `List.map`, and the nearby elements
threaded through as the head and tail of the same list rather than appended afterwards.
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
        -- `toBehindElements` prepends each element it finds onto what it was handed, so
        -- passing the children in is the same list `behind ++ children ++ after` builds.
        toBehindElements
            myBits
            (unwrapChildren myBits (toNearbyElements myBits [] attrs) children)
            attrs

    else
        unwrapChildren myBits [] children


{-| Every child rendered in order, followed by `rest`.
-}
unwrapChildren :
    Inheritance.Encoded
    -> List (Html.Html msg)
    -> List (Element msg)
    -> List (Html.Html msg)
unwrapChildren inheritance rest children =
    prependReversed rest (unwrapChildrenHelp inheritance [] children)


unwrapChildrenHelp :
    Inheritance.Encoded
    -> List (Html.Html msg)
    -> List (Element msg)
    -> List (Html.Html msg)
unwrapChildrenHelp inheritance rendered children =
    case children of
        [] ->
            rendered

        (Element toChild) :: remain ->
            unwrapChildrenHelp inheritance (toChild inheritance :: rendered) remain


prependReversed : List a -> List a -> List a
prependReversed rest reversed =
    case reversed of
        [] ->
            rest

        first :: remain ->
            prependReversed (first :: rest) remain


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
        behind ++ unwrapKeyedChildren myBits after children

    else
        unwrapKeyedChildren myBits [] children


unwrapKeyedChildren :
    Inheritance.Encoded
    -> List ( String, Html.Html msg )
    -> List ( String, Element msg )
    -> List ( String, Html.Html msg )
unwrapKeyedChildren inheritance rest children =
    prependReversed rest (unwrapKeyedChildrenHelp inheritance [] children)


unwrapKeyedChildrenHelp :
    Inheritance.Encoded
    -> List ( String, Html.Html msg )
    -> List ( String, Element msg )
    -> List ( String, Html.Html msg )
unwrapKeyedChildrenHelp inheritance rendered children =
    case children of
        [] ->
            rendered

        ( key, Element toChild ) :: remain ->
            unwrapKeyedChildrenHelp inheritance (( key, toChild inheritance ) :: rendered) remain
