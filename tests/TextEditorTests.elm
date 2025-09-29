module TextEditorTests exposing (tests)

import Expect
import Fuzz exposing (Fuzzer)
import RichText exposing (Range)
import Test exposing (Test)
import TextEditor


tests : Test
tests =
    Test.describe
        "TextEditor tests"
        [ Test.fuzz3
            (Fuzz.intRange 0 100)
            rangeFuzzer
            rangeFuzzer
            "insertTextHelperInverse is the inverse of insertTextHelper"
            (\insertCount removeRange inputRange ->
                let
                    output =
                        TextEditor.insertTextHelper insertCount removeRange inputRange

                    recovered =
                        TextEditor.insertTextHelperInverse insertCount removeRange output
                in
                Expect.equal inputRange recovered
            )
        ]


rangeFuzzer : Fuzzer Range
rangeFuzzer =
    Fuzz.map2
        (\a b ->
            { start = min a b
            , end = max a b
            }
        )
        (Fuzz.intRange 0 100)
        (Fuzz.intRange 0 100)