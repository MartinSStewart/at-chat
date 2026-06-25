module WordSpellingGameTests exposing (tests)

import Expect
import List.Nonempty exposing (Nonempty(..))
import SeqDict exposing (SeqDict)
import Set
import Test exposing (Test)
import WordSpellingGame exposing (Board, Letter(..), PlacedWord)


{-| Build a board from a list of plain (non-wildcard) tiles.
-}
board : List ( ( Int, Int ), Letter ) -> Board
board tiles =
    List.map (\( position, letter ) -> ( position, { letter = letter, isWildcard = False } )) tiles
        |> SeqDict.fromList


placedWord : ( Int, Int ) -> Bool -> Letter -> List Letter -> PlacedWord
placedWord start isVertical first rest =
    { start = start, isVertical = isVertical, letters = Nonempty first rest }


tests : Test
tests =
    Test.describe
        "WordSpellingGame"
        [ Test.describe "placeWord detects formed words and scores them"
            [ Test.test "a single horizontal word on plain cells" <|
                \_ ->
                    -- C(3) A(1) T(1) on plain cells, no multipliers.
                    WordSpellingGame.placeWord SeqDict.empty (placedWord ( 6, 4 ) False C [ A, T ])
                        |> Maybe.map (\result -> ( result.words, result.score ))
                        |> Expect.equal (Just ( [ "cat" ], 5 ))
            , Test.test "the main word plus every perpendicular cross word" <|
                \_ ->
                    -- Existing A A A along row 5, place C A T along row 4 above them. This forms
                    -- the main word "cat" and three cross words "ca", "aa", "ta".
                    let
                        existing : Board
                        existing =
                            board [ ( ( 6, 5 ), A ), ( ( 7, 5 ), A ), ( ( 8, 5 ), A ) ]
                    in
                    WordSpellingGame.placeWord existing (placedWord ( 6, 4 ) False C [ A, T ])
                        |> Maybe.map (\result -> ( result.words, result.score ))
                        -- main "cat" = 3+1+1 = 5, "ca" = 3+1 = 4, "aa" = 1+1 = 2, "ta" = 1+1 = 2
                        |> Expect.equal (Just ( [ "cat", "ca", "aa", "ta" ], 13 ))
            , Test.test "double-letter squares multiply only the placed letter" <|
                \_ ->
                    -- (6,2) and (8,2) are double-letter squares, (7,2) is plain.
                    WordSpellingGame.placeWord SeqDict.empty (placedWord ( 6, 2 ) False C [ A, T ])
                        |> Maybe.map (\result -> ( result.words, result.score ))
                        -- C 3*2 + A 1 + T 1*2 = 9
                        |> Expect.equal (Just ( [ "cat" ], 9 ))
            , Test.test "the centre square doubles the whole word" <|
                \_ ->
                    -- (7,7) is the centre square (double word).
                    WordSpellingGame.placeWord SeqDict.empty (placedWord ( 7, 7 ) False C [ A, T ])
                        |> Maybe.map (\result -> ( result.words, result.score ))
                        -- (3+1+1) * 2 = 10
                        |> Expect.equal (Just ( [ "cat" ], 10 ))
            , Test.test "letters laid out skip over existing tiles" <|
                \_ ->
                    -- An existing A sits at (7,4); placing C and T around it forms "cat".
                    let
                        existing : Board
                        existing =
                            board [ ( ( 7, 4 ), A ) ]
                    in
                    WordSpellingGame.placeWord existing (placedWord ( 6, 4 ) False C [ T ])
                        |> Maybe.map (\result -> ( result.words, result.score ))
                        -- C 3 (placed) + A 1 (existing) + T 1 (placed) = 5
                        |> Expect.equal (Just ( [ "cat" ], 5 ))
            , Test.test "running off the edge of the board is rejected" <|
                \_ ->
                    WordSpellingGame.placeWord SeqDict.empty (placedWord ( 14, 7 ) False A [ B ])
                        |> Expect.equal Nothing
            ]
        , Test.describe "validatePlacement checks formed words against the word list"
            [ Test.test "accepts a placement when the word exists" <|
                \_ ->
                    WordSpellingGame.validatePlacement
                        (Set.fromList [ "cat" ])
                        SeqDict.empty
                        (placedWord ( 6, 4 ) False C [ A, T ])
                        |> Result.map (\result -> ( result.words, result.score ))
                        |> Expect.equal (Ok ( [ "cat" ], 5 ))
            , Test.test "rejects a placement when the word does not exist" <|
                \_ ->
                    WordSpellingGame.validatePlacement
                        (Set.fromList [ "dog" ])
                        SeqDict.empty
                        (placedWord ( 6, 4 ) False C [ A, T ])
                        |> Expect.equal (Err ())
            , Test.test "accepts only when every cross word also exists" <|
                \_ ->
                    let
                        existing : Board
                        existing =
                            board [ ( ( 6, 5 ), A ), ( ( 7, 5 ), A ), ( ( 8, 5 ), A ) ]
                    in
                    WordSpellingGame.validatePlacement
                        (Set.fromList [ "cat", "ca", "aa", "ta" ])
                        existing
                        (placedWord ( 6, 4 ) False C [ A, T ])
                        |> Result.map (\result -> ( result.words, result.score ))
                        |> Expect.equal (Ok ( [ "cat", "ca", "aa", "ta" ], 13 ))
            , Test.test "rejects when a cross word does not exist even if the main word does" <|
                \_ ->
                    let
                        existing : Board
                        existing =
                            board [ ( ( 6, 5 ), A ), ( ( 7, 5 ), A ), ( ( 8, 5 ), A ) ]
                    in
                    WordSpellingGame.validatePlacement
                        -- "aa" is missing, so the placement is rejected.
                        (Set.fromList [ "cat", "ca", "ta" ])
                        existing
                        (placedWord ( 6, 4 ) False C [ A, T ])
                        |> Expect.equal (Err ())
            ]
        ]
