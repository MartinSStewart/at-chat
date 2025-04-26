module Dicts.NonemptySet exposing (fuzz)

import Expect
import Fuzz exposing (Fuzzer)
import List.Nonempty exposing (Nonempty(..))
import NonemptySet exposing (NonemptySet)
import SeqSet exposing (SeqSet)
import Test exposing (Test)


fuzz : Test
fuzz =
    Test.describe "NonemptySet tests"
        [ Test.test "Round trip stable" <|
            \_ ->
                let
                    nonempty : Nonempty ( number, number )
                    nonempty =
                        Nonempty ( 1, 1 ) [ ( 2, 2 ), ( 3, 3 ) ]
                in
                NonemptySet.fromNonemptyList nonempty
                    |> NonemptySet.toNonemptyList
                    |> Expect.equal nonempty
        , Test.test "Simple test" <|
            \_ ->
                Expect.equal
                    (SeqSet.singleton 1
                        |> SeqSet.insert 2
                        |> SeqSet.insert 3
                        |> SeqSet.toList
                    )
                    (NonemptySet.singleton 1
                        |> NonemptySet.insert 2
                        |> NonemptySet.insert 3
                        |> NonemptySet.toList
                    )
        , Test.fuzz setFuzzer "Make sure NonemptySet works the same way as SeqSet" <|
            \changes ->
                List.foldl
                    (\( _, a, b ) ( setA, setB ) -> ( a setA, b setB ))
                    ( NonemptySet.singleton 1, SeqSet.singleton 1 )
                    changes
                    |> (\( a, b ) -> Expect.equal (NonemptySet.toList a) (SeqSet.toList b))
        ]


setFuzzer :
    Fuzzer
        (List
            ( String
            , NonemptySet Int -> NonemptySet Int
            , SeqSet Int -> SeqSet Int
            )
        )
setFuzzer =
    Fuzz.list
        (Fuzz.oneOf
            [ Fuzz.intRange 0 5
                |> Fuzz.map
                    (\a ->
                        ( "insert " ++ String.fromInt a
                        , NonemptySet.insert a
                        , SeqSet.insert a
                        )
                    )
            ]
        )
