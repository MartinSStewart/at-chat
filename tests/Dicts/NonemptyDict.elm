module Dicts.NonemptyDict exposing (fuzz)

import Expect
import Fuzz exposing (Fuzzer)
import List.Nonempty exposing (Nonempty(..))
import NonemptyDict exposing (NonemptyDict)
import SeqDict exposing (SeqDict)
import Test exposing (Test)


fuzz : Test
fuzz =
    Test.describe "NonemptyDict tests"
        [ Test.test "Round trip stable" <|
            \_ ->
                let
                    nonempty : Nonempty ( number, number )
                    nonempty =
                        Nonempty ( 1, 1 ) [ ( 2, 2 ), ( 3, 3 ) ]
                in
                NonemptyDict.fromNonemptyList nonempty
                    |> NonemptyDict.toNonemptyList
                    |> Expect.equal nonempty
        , Test.test "Simple test" <|
            \_ ->
                Expect.equal
                    (SeqDict.singleton 1 1
                        |> SeqDict.insert 2 2
                        |> SeqDict.insert 3 3
                        |> SeqDict.toList
                    )
                    (NonemptyDict.singleton 1 1
                        |> NonemptyDict.insert 2 2
                        |> NonemptyDict.insert 3 3
                        |> NonemptyDict.toList
                    )
        , Test.fuzz dictFuzzer "Make sure NonemptyDict works the same way as SeqDict" <|
            \changes ->
                List.foldl
                    (\( _, a, b ) ( dictA, dictB ) -> ( a dictA, b dictB ))
                    ( NonemptyDict.singleton 1 1, SeqDict.singleton 1 1 )
                    changes
                    |> (\( a, b ) -> Expect.equal (NonemptyDict.toList a) (SeqDict.toList b))
        ]


dictFuzzer :
    Fuzzer
        (List
            ( String
            , NonemptyDict Int Int -> NonemptyDict Int Int
            , SeqDict Int Int -> SeqDict Int Int
            )
        )
dictFuzzer =
    Fuzz.list
        (Fuzz.oneOf
            [ Fuzz.intRange 0 5
                |> Fuzz.map
                    (\a ->
                        ( "insert " ++ String.fromInt a
                        , NonemptyDict.insert a a
                        , SeqDict.insert a a
                        )
                    )
            , Fuzz.intRange 0 5
                |> Fuzz.map
                    (\a ->
                        ( "updateIfExists " ++ String.fromInt a
                        , NonemptyDict.updateIfExists a (\v -> v + 1)
                        , SeqDict.updateIfExists a (\v -> v + 1)
                        )
                    )
            ]
        )
