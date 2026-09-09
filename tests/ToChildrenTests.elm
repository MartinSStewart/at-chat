module ToChildrenTests exposing (rewritesMatchTheOriginal)

{-| `Internal.Model2.toChildren` was rewritten for speed (see benchmarks/src/BenchmarkRunner.elm). The
numbers only mean something if the rewrite builds the same list as the version it replaced,
which is what these check.
-}

import Expect
import Internal.Model2 exposing (Element)
import Test exposing (Test)
import ToChildren.Baseline as Baseline
import ToChildren.Foldl as Foldl
import ToChildren.Inputs as Inputs
import ToChildren.Optimized as Optimized


rewritesMatchTheOriginal : Test
rewritesMatchTheOriginal =
    Test.describe
        "toChildren rewrites build the same list as the version they replaced"
        (List.concatMap checks (0 :: Inputs.sizes))


checks : Int -> List Test
checks count =
    let
        list : List (Element ())
        list =
            Inputs.children count

        keyed : List ( String, Element () )
        keyed =
            Inputs.keyedChildren count

        name : String -> String
        name suffix =
            String.fromInt count ++ " children, " ++ suffix
    in
    [ Test.test (name "toChildren, tail recursive") <|
        \_ ->
            Optimized.toChildren Inputs.inheritance Inputs.noNearbys [] list
                |> Expect.equal (Baseline.toChildren Inputs.inheritance Inputs.noNearbys [] list)
    , Test.test (name "toChildren, List.foldl") <|
        \_ ->
            Foldl.toChildren Inputs.inheritance Inputs.noNearbys [] list
                |> Expect.equal (Baseline.toChildren Inputs.inheritance Inputs.noNearbys [] list)
    , Test.test (name "toChildren with nearby elements, tail recursive") <|
        \_ ->
            Optimized.toChildren Inputs.inheritance Inputs.hasNearbys Inputs.nearbyAttrs list
                |> Expect.equal
                    (Baseline.toChildren Inputs.inheritance Inputs.hasNearbys Inputs.nearbyAttrs list)
    , Test.test (name "toChildren with nearby elements, List.foldl") <|
        \_ ->
            Foldl.toChildren Inputs.inheritance Inputs.hasNearbys Inputs.nearbyAttrs list
                |> Expect.equal
                    (Baseline.toChildren Inputs.inheritance Inputs.hasNearbys Inputs.nearbyAttrs list)
    , Test.test (name "toChildrenKeyed, tail recursive") <|
        \_ ->
            Optimized.toChildrenKeyed Inputs.inheritance Inputs.noNearbys [] keyed
                |> Expect.equal (Baseline.toChildrenKeyed Inputs.inheritance Inputs.noNearbys [] keyed)
    , Test.test (name "toChildrenKeyed with nearby elements, tail recursive") <|
        \_ ->
            Optimized.toChildrenKeyed Inputs.inheritance Inputs.hasNearbys Inputs.nearbyAttrs keyed
                |> Expect.equal
                    (Baseline.toChildrenKeyed Inputs.inheritance Inputs.hasNearbys Inputs.nearbyAttrs keyed)
    ]
