module WordSpellingGameTests exposing (tests)

import Expect
import List.Nonempty exposing (Nonempty(..))
import SeqDict exposing (SeqDict)
import Set
import Test exposing (Test)
import UserSession exposing (ToBeFilledInByBackend(..))
import WordSpellingGame exposing (IsValid(..), Letter(..), LetterOrWildcard(..), PlacedWord)


{-| Build a board from a list of plain (non-wildcard) tiles.
-}
board : List ( ( Int, Int ), Letter ) -> SeqDict ( Int, Int ) LetterOrWildcard
board tiles =
    List.map (\( position, letter ) -> ( position, Letter letter )) tiles
        |> SeqDict.fromList


{-| The letters of a word with no wildcards, for comparing against a placement's formed words.
-}
word : List Letter -> List LetterOrWildcard
word =
    List.map Letter


{-| A dictionary built from the given words, for passing to `validatePlacement`.
-}
dict : List String -> WordSpellingGame.Dictionary
dict words =
    WordSpellingGame.buildDictionary (Set.fromList words)


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
                        |> Expect.equal (Just ( [ word [ C, A, T ] ], 5 ))
            , Test.test "the main word plus every perpendicular cross word" <|
                \_ ->
                    -- Existing A A A along row 5, place C A T along row 4 above them. This forms
                    -- the main word "cat" and three cross words "ca", "aa", "ta".
                    let
                        existing : SeqDict ( Int, Int ) LetterOrWildcard
                        existing =
                            board [ ( ( 6, 5 ), A ), ( ( 7, 5 ), A ), ( ( 8, 5 ), A ) ]
                    in
                    WordSpellingGame.placeWord existing (placedWord ( 6, 4 ) False C [ A, T ])
                        |> Maybe.map (\result -> ( result.words, result.score ))
                        -- main "cat" = 3+1+1 = 5, "ca" = 3+1 = 4, "aa" = 1+1 = 2, "ta" = 1+1 = 2
                        |> Expect.equal (Just ( [ word [ C, A, T ], word [ C, A ], word [ A, A ], word [ T, A ] ], 13 ))
            , Test.test "double-letter squares multiply only the placed letter" <|
                \_ ->
                    -- (6,2) and (8,2) are double-letter squares, (7,2) is plain.
                    WordSpellingGame.placeWord SeqDict.empty (placedWord ( 6, 2 ) False C [ A, T ])
                        |> Maybe.map (\result -> ( result.words, result.score ))
                        -- C 3*2 + A 1 + T 1*2 = 9
                        |> Expect.equal (Just ( [ word [ C, A, T ] ], 9 ))
            , Test.test "the centre square doubles the whole word" <|
                \_ ->
                    -- (7,7) is the centre square (double word).
                    WordSpellingGame.placeWord SeqDict.empty (placedWord ( 7, 7 ) False C [ A, T ])
                        |> Maybe.map (\result -> ( result.words, result.score ))
                        -- (3+1+1) * 2 = 10
                        |> Expect.equal (Just ( [ word [ C, A, T ] ], 10 ))
            , Test.test "letters laid out skip over existing tiles" <|
                \_ ->
                    -- An existing A sits at (7,4); placing C and T around it forms "cat".
                    let
                        existing : SeqDict ( Int, Int ) LetterOrWildcard
                        existing =
                            board [ ( ( 7, 4 ), A ) ]
                    in
                    WordSpellingGame.placeWord existing (placedWord ( 6, 4 ) False C [ T ])
                        |> Maybe.map (\result -> ( result.words, result.score ))
                        -- C 3 (placed) + A 1 (existing) + T 1 (placed) = 5
                        |> Expect.equal (Just ( [ word [ C, A, T ] ], 5 ))
            , Test.test "running off the edge of the board is rejected" <|
                \_ ->
                    WordSpellingGame.placeWord SeqDict.empty (placedWord ( 14, 7 ) False A [ B ])
                        |> Expect.equal Nothing
            ]
        , Test.describe "validatePlacement checks formed words against the word list"
            [ Test.test "accepts a placement when the word exists" <|
                \_ ->
                    WordSpellingGame.validatePlacement
                        (dict [ "cat" ])
                        SeqDict.empty
                        (placedWord ( 6, 4 ) False C [ A, T ])
                        |> Result.map (\result -> ( result.words, result.score ))
                        |> Expect.equal (Ok ( [ word [ C, A, T ] ], 5 ))
            , Test.test "rejects a placement when the word does not exist" <|
                \_ ->
                    WordSpellingGame.validatePlacement
                        (dict [ "dog" ])
                        SeqDict.empty
                        (placedWord ( 6, 4 ) False C [ A, T ])
                        |> Expect.equal (Err ())
            , Test.test "accepts only when every cross word also exists" <|
                \_ ->
                    let
                        existing : SeqDict ( Int, Int ) LetterOrWildcard
                        existing =
                            board [ ( ( 6, 5 ), A ), ( ( 7, 5 ), A ), ( ( 8, 5 ), A ) ]
                    in
                    WordSpellingGame.validatePlacement
                        (dict [ "cat", "ca", "aa", "ta" ])
                        existing
                        (placedWord ( 6, 4 ) False C [ A, T ])
                        |> Result.map (\result -> ( result.words, result.score ))
                        |> Expect.equal (Ok ( [ word [ C, A, T ], word [ C, A ], word [ A, A ], word [ T, A ] ], 13 ))
            , Test.test "rejects when a cross word does not exist even if the main word does" <|
                \_ ->
                    let
                        existing : SeqDict ( Int, Int ) LetterOrWildcard
                        existing =
                            board [ ( ( 6, 5 ), A ), ( ( 7, 5 ), A ), ( ( 8, 5 ), A ) ]
                    in
                    WordSpellingGame.validatePlacement
                        -- "aa" is missing, so the placement is rejected.
                        (dict [ "cat", "ca", "ta" ])
                        existing
                        (placedWord ( 6, 4 ) False C [ A, T ])
                        |> Expect.equal (Err ())
            , Test.test "a wildcard can stand for the letter that completes a word" <|
                \_ ->
                    -- A wildcard sits at (7,4); placing C and T around it forms "c_t", which is
                    -- valid because the wildcard can be an A to spell "cat".
                    let
                        existing : SeqDict ( Int, Int ) LetterOrWildcard
                        existing =
                            SeqDict.fromList [ ( ( 7, 4 ), Wildcard ) ]
                    in
                    WordSpellingGame.validatePlacement
                        (dict [ "cat" ])
                        existing
                        (placedWord ( 6, 4 ) False C [ T ])
                        |> Result.map (\result -> result.words)
                        |> Expect.equal (Ok [ [ Letter C, Wildcard, Letter T ] ])
            , Test.test "a wildcard is rejected when no letter completes a word" <|
                \_ ->
                    -- "c_t" has no completion in a word list that only contains "dog".
                    let
                        existing : SeqDict ( Int, Int ) LetterOrWildcard
                        existing =
                            SeqDict.fromList [ ( ( 7, 4 ), Wildcard ) ]
                    in
                    WordSpellingGame.validatePlacement
                        (dict [ "dog" ])
                        existing
                        (placedWord ( 6, 4 ) False C [ T ])
                        |> Expect.equal (Err ())
            , Test.test "two wildcards in one word are each tried independently" <|
                \_ ->
                    -- Wildcards at (6,4) and (8,4) with a fixed A between them form "_a_", which the
                    -- word list accepts as "cat" (first wildcard C, second wildcard T).
                    let
                        existing : SeqDict ( Int, Int ) LetterOrWildcard
                        existing =
                            SeqDict.fromList [ ( ( 6, 4 ), Wildcard ), ( ( 8, 4 ), Wildcard ) ]
                    in
                    WordSpellingGame.validatePlacement
                        (dict [ "cat" ])
                        existing
                        (placedWord ( 7, 4 ) False A [])
                        |> Result.map (\result -> result.words)
                        |> Expect.equal (Ok [ [ Wildcard, Letter A, Wildcard ] ])
            , Test.test "a word with many wildcards is matched by scanning the dictionary" <|
                \_ ->
                    -- Four wildcards around a fixed A form "__a__" (too many to brute force), which
                    -- the dictionary accepts as "koala".
                    let
                        existing : SeqDict ( Int, Int ) LetterOrWildcard
                        existing =
                            SeqDict.fromList
                                [ ( ( 5, 4 ), Wildcard )
                                , ( ( 6, 4 ), Wildcard )
                                , ( ( 8, 4 ), Wildcard )
                                , ( ( 9, 4 ), Wildcard )
                                ]
                    in
                    WordSpellingGame.validatePlacement
                        (dict [ "koala" ])
                        existing
                        (placedWord ( 7, 4 ) False A [])
                        |> Result.map (\result -> result.words)
                        |> Expect.equal
                            (Ok [ [ Wildcard, Wildcard, Letter A, Wildcard, Wildcard ] ])
            , Test.test "a word with many wildcards is rejected when nothing of that length fits" <|
                \_ ->
                    -- "__a__" has no completion among the only same-length word "abcde" (whose third
                    -- letter is 'c', not 'a'), so the placement is rejected.
                    let
                        existing : SeqDict ( Int, Int ) LetterOrWildcard
                        existing =
                            SeqDict.fromList
                                [ ( ( 5, 4 ), Wildcard )
                                , ( ( 6, 4 ), Wildcard )
                                , ( ( 8, 4 ), Wildcard )
                                , ( ( 9, 4 ), Wildcard )
                                ]
                    in
                    WordSpellingGame.validatePlacement
                        (dict [ "abcde" ])
                        existing
                        (placedWord ( 7, 4 ) False A [])
                        |> Expect.equal (Err ())
            ]
        , Test.describe "animatedTilePlacement positions tiles from the start time"
            [ Test.test "an observer's tile starts at the top-left corner and slides to its cell" <|
                \_ ->
                    -- For a player who didn't place the tiles, at time 0 the first tile is at the
                    -- corner (progress 0); well after the slide it rests on its cell (progress 1).
                    ( WordSpellingGame.animatedTilePlacement False 0 EmptyPlaceholder 3 0
                    , WordSpellingGame.animatedTilePlacement False 1000 EmptyPlaceholder 3 0
                    )
                        |> Expect.equal
                            ( Just { progress = 0, red = False }
                            , Just { progress = 1, red = False }
                            )
            , Test.test "the player who placed the tiles sees them resting in place immediately" <|
                \_ ->
                    -- They placed the tiles locally, so there's no slide-in for them.
                    WordSpellingGame.animatedTilePlacement True 0 EmptyPlaceholder 3 0
                        |> Expect.equal (Just { progress = 1, red = False })
            , Test.test "later tiles are staggered, so they haven't started while an earlier one moves" <|
                \_ ->
                    -- 250ms in, tile 0 (launched at 0) has arrived but tile 2 (launches at 160)
                    -- has only just started, so it is still well short of its cell.
                    case
                        ( WordSpellingGame.animatedTilePlacement False 250 EmptyPlaceholder 3 0
                        , WordSpellingGame.animatedTilePlacement False 250 EmptyPlaceholder 3 2
                        )
                    of
                        ( Just first, Just third ) ->
                            ( first.progress, third.progress < first.progress, third.progress < 1 )
                                |> Expect.equal ( 1, True, True )

                        _ ->
                            Expect.fail "expected both tiles to be visible"
            , Test.test "a valid placement's tiles never disappear" <|
                \_ ->
                    WordSpellingGame.animatedTilePlacement False 100000 EmptyPlaceholder 3 0
                        |> Expect.equal (Just { progress = 1, red = False })
            , Test.test "a rejected tile turns red after landing" <|
                \_ ->
                    -- After the whole word has slid in and held briefly, the tile is resting on its
                    -- cell and drawn red before it leaves.
                    WordSpellingGame.animatedTilePlacement False 1500 (FilledInByBackend IsNotValid) 3 0
                        |> Expect.equal (Just { progress = 1, red = True })
            , Test.test "a rejected tile is gone once the animation has finished" <|
                \_ ->
                    WordSpellingGame.animatedTilePlacement False 100000 (FilledInByBackend IsNotValid) 3 0
                        |> Expect.equal Nothing
            ]
        ]
