module Benchmarks exposing (suite)

import Bench exposing (Benchmark)
import Html
import Internal.BitField as BitField
import Internal.Bits.Analyze as AnalyzeBits
import Internal.Bits.Inheritance as Inheritance
import Internal.Model2 as Two exposing (Attribute, Element(..))
import ToChildren.Baseline as Baseline
import ToChildren.Foldl as Foldl
import ToChildren.Optimized as Optimized


suite : Benchmark
suite =
    Bench.describe "Internal.Model2"
        [ Bench.scale "toChildren without nearby elements"
            sizes
            children
            [ ( "current (List.map)"
              , \list -> Baseline.toChildren inheritance noNearbys [] list
              )
            , ( "List.foldl"
              , \list -> Foldl.toChildren inheritance noNearbys [] list
              )
            , ( "tail recursive"
              , \list -> Optimized.toChildren inheritance noNearbys [] list
              )
            ]
        , Bench.scale "toChildren with nearby elements"
            sizes
            children
            [ ( "current (List.map)"
              , \list -> Baseline.toChildren inheritance hasNearbys nearbyAttrs list
              )
            , ( "List.foldl"
              , \list -> Foldl.toChildren inheritance hasNearbys nearbyAttrs list
              )
            , ( "tail recursive"
              , \list -> Optimized.toChildren inheritance hasNearbys nearbyAttrs list
              )
            ]
        , Bench.scale "toChildrenKeyed without nearby elements"
            sizes
            keyedChildren
            [ ( "current (List.map)"
              , \list -> Baseline.toChildrenKeyed inheritance noNearbys [] list
              )
            , ( "tail recursive"
              , \list -> Optimized.toChildrenKeyed inheritance noNearbys [] list
              )
            ]
        , Bench.scale "toChildrenKeyed with nearby elements"
            sizes
            keyedChildren
            [ ( "current (List.map)"
              , \list -> Baseline.toChildrenKeyed inheritance hasNearbys nearbyAttrs list
              )
            , ( "tail recursive"
              , \list -> Optimized.toChildrenKeyed inheritance hasNearbys nearbyAttrs list
              )
            ]
        ]


{-| Most elements in the app hold a handful of children, so the small sizes are the ones
that matter. The large ones are there to show which way the curves go.
-}
sizes : List Int
sizes =
    [ 1, 2, 4, 8, 32, 128, 512 ]


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
