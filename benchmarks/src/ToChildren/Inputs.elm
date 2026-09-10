module ToChildren.Inputs exposing
    ( children
    , hasNearbys
    , inheritance
    , keyedChildren
    , nearbyAttrs
    , noNearbys
    , sizes
    )

{-| The inputs the benchmarks time and the tests check against, in one place so both are
looking at the same thing.
-}

import Html
import Internal.BitField as BitField
import Internal.Bits.Analyze as AnalyzeBits
import Internal.Bits.Inheritance as Inheritance
import Internal.Model2 as Two exposing (Attribute, Element(..))


{-| Most elements hold a handful of children. The keyed columns holding the message list are
where the large ones come from.
-}
sizes : List Int
sizes =
    [ 1, 4, 32, 512 ]


{-| Each child hands back a value it already has, so what's measured is the walk over the
list rather than the cost of rendering an element.
-}
children : Int -> List (Element msg)
children count =
    List.map
        (\index ->
            let
                html : Html.Html msg
                html =
                    Html.text (String.fromInt index)
            in
            Element (\_ -> html)
        )
        (List.range 1 count)


keyedChildren : Int -> List ( String, Element msg )
keyedChildren count =
    List.map
        (\child -> ( "key", child ))
        (children count)


{-| Two behind, two in front, and a plain attribute in between them, which is about as many
as an element in the app carries.
-}
nearbyAttrs : List (Attribute msg)
nearbyAttrs =
    [ Two.nearby Two.Behind (leaf "behind1")
    , Two.nearby Two.InFront (leaf "front1")
    , Two.class "spacer"
    , Two.nearby Two.Behind (leaf "behind2")
    , Two.nearby Two.InFront (leaf "front2")
    ]


leaf : String -> Element msg
leaf name =
    Element (\_ -> Html.text name)


inheritance : Inheritance.Encoded
inheritance =
    BitField.init


noNearbys : AnalyzeBits.Encoded
noNearbys =
    BitField.init


hasNearbys : AnalyzeBits.Encoded
hasNearbys =
    BitField.flip AnalyzeBits.nearbys True BitField.init
