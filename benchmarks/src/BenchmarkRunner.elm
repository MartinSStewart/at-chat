module BenchmarkRunner exposing (main)

{-| Compiled to a page you open in a browser:

    npm run benchmarks

The whole suite takes a few minutes to settle. Each comparison holds its input list outside
the thunks, so what's timed is `toChildren` rather than building the list it walks.

-}

import Benchmark exposing (Benchmark)
import Benchmark.Runner exposing (BenchmarkProgram)
import Internal.Model2 exposing (Element)
import ToChildren.Baseline as Baseline
import ToChildren.Foldl as Foldl
import ToChildren.Inputs as Inputs
import ToChildren.Optimized as Optimized


main : BenchmarkProgram
main =
    Benchmark.Runner.program suite


suite : Benchmark
suite =
    Benchmark.describe "Internal.Model2"
        [ Benchmark.describe "toChildren without nearby elements"
            (List.map withoutNearby Inputs.sizes)
        , Benchmark.describe "toChildren with nearby elements"
            (List.map withNearby Inputs.sizes)
        , Benchmark.describe "toChildrenKeyed without nearby elements"
            (List.map keyedWithoutNearby Inputs.sizes)
        , Benchmark.describe "toChildrenKeyed with nearby elements"
            (List.map keyedWithNearby Inputs.sizes)
        , Benchmark.describe "toChildren, List.foldl against the loops"
            (List.map foldlWithoutNearby Inputs.sizes)
        ]


withoutNearby : Int -> Benchmark
withoutNearby count =
    let
        list : List (Element ())
        list =
            Inputs.children count
    in
    Benchmark.compare
        (label count)
        "current (List.map)"
        (\() -> Baseline.toChildren Inputs.inheritance Inputs.noNearbys [] list)
        "tail recursive"
        (\() -> Optimized.toChildren Inputs.inheritance Inputs.noNearbys [] list)


withNearby : Int -> Benchmark
withNearby count =
    let
        list : List (Element ())
        list =
            Inputs.children count
    in
    Benchmark.compare
        (label count)
        "current (List.map)"
        (\() -> Baseline.toChildren Inputs.inheritance Inputs.hasNearbys Inputs.nearbyAttrs list)
        "tail recursive"
        (\() -> Optimized.toChildren Inputs.inheritance Inputs.hasNearbys Inputs.nearbyAttrs list)


keyedWithoutNearby : Int -> Benchmark
keyedWithoutNearby count =
    let
        list : List ( String, Element () )
        list =
            Inputs.keyedChildren count
    in
    Benchmark.compare
        (label count)
        "current (List.map)"
        (\() -> Baseline.toChildrenKeyed Inputs.inheritance Inputs.noNearbys [] list)
        "tail recursive"
        (\() -> Optimized.toChildrenKeyed Inputs.inheritance Inputs.noNearbys [] list)


keyedWithNearby : Int -> Benchmark
keyedWithNearby count =
    let
        list : List ( String, Element () )
        list =
            Inputs.keyedChildren count
    in
    Benchmark.compare
        (label count)
        "current (List.map)"
        (\() -> Baseline.toChildrenKeyed Inputs.inheritance Inputs.hasNearbys Inputs.nearbyAttrs list)
        "tail recursive"
        (\() -> Optimized.toChildrenKeyed Inputs.inheritance Inputs.hasNearbys Inputs.nearbyAttrs list)


foldlWithoutNearby : Int -> Benchmark
foldlWithoutNearby count =
    let
        list : List (Element ())
        list =
            Inputs.children count
    in
    Benchmark.compare
        (label count)
        "List.foldl"
        (\() -> Foldl.toChildren Inputs.inheritance Inputs.noNearbys [] list)
        "tail recursive"
        (\() -> Optimized.toChildren Inputs.inheritance Inputs.noNearbys [] list)


label : Int -> String
label count =
    if count == 1 then
        "1 child"

    else
        String.fromInt count ++ " children"
