module WordSpellingGameTests exposing (tests)

import Duration
import Effect.Time as Time
import Expect
import Id
import List.Nonempty exposing (Nonempty(..))
import NonemptyDict
import OneOrGreater
import SeqDict exposing (SeqDict)
import Test exposing (Test)
import UserSession exposing (ToBeFilledInByBackend(..))
import WordSpellingGame exposing (IsValid(..), Letter(..), LetterOrWildcard(..), PlacedWord)
import WordSpellingGameEnglish


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


placedWord : ( Int, Int ) -> Bool -> Letter -> List Letter -> PlacedWord
placedWord start isVertical first rest =
    { start = start, isVertical = isVertical, letters = Nonempty (Letter first) (List.map Letter rest) }


{-| A validated setup with the given tray size and full-tray bonus, keeping every other option at
its default. Fails loudly (via the caller) if the defaults ever stop validating.
-}
validatedSetup : Int -> Int -> Result String WordSpellingGame.ValidatedSetup
validatedSetup traySize bonus =
    let
        base : WordSpellingGame.SetupModel
        base =
            WordSpellingGame.initSetup
    in
    WordSpellingGame.validateSetup
        (Id.fromInt 0)
        (Time.millisToPosix 0)
        { base | traySize = traySize, fullTrayBonus = bonus }


{-| The default setup, used by tests that need the standard letter values. The fallback branch is
unreachable since the default setup always validates; it just keeps this definition total.
-}
testSetup : WordSpellingGame.ValidatedSetup
testSetup =
    case validatedSetup 7 0 of
        Ok validated ->
            validated

        Err _ ->
            { timeControls = { mainTime = Duration.minutes 10, increment = Duration.seconds 5 }
            , traySize = OneOrGreater.seven
            , fullTrayBonus = 0
            , createdBy = Id.fromInt 0
            , seed = 0
            , letters =
                NonemptyDict.fromNonemptyList
                    (Nonempty ( Letter a, { count = OneOrGreater.seven, value = 1 } ) [])
            , language = WordSpellingGame.English
            , placeWordAttempts = OneOrGreater.one
            }


a : Letter
a =
    LetterChar 'A'


b : Letter
b =
    LetterChar 'B'


c : Letter
c =
    LetterChar 'C'


e : Letter
e =
    LetterChar 'E'


h : Letter
h =
    LetterChar 'H'


l : Letter
l =
    LetterChar 'L'


o : Letter
o =
    LetterChar 'O'


t : Letter
t =
    LetterChar 'T'


tests : Test
tests =
    Test.describe
        "WordSpellingGame"
        [ Test.describe "placeWord detects formed words and scores them"
            [ Test.test "a single horizontal word on plain cells" <|
                \_ ->
                    -- C(3) A(1) T(1) on plain cells, no multipliers.
                    WordSpellingGame.placeWord testSetup SeqDict.empty (placedWord ( 6, 4 ) False c [ a, t ])
                        |> Maybe.map (\result -> ( List.map .letters result.words, result.score ))
                        |> Expect.equal (Just ( [ word [ c, a, t ] ], 5 ))
            , Test.test "the main word plus every perpendicular cross word" <|
                \_ ->
                    -- Existing A A A along row 5, place C A T along row 4 above them. This forms
                    -- the main word "CAT" and three cross words "CA", "AA", "TA".
                    let
                        existing : SeqDict ( Int, Int ) LetterOrWildcard
                        existing =
                            board [ ( ( 6, 5 ), a ), ( ( 7, 5 ), a ), ( ( 8, 5 ), a ) ]
                    in
                    WordSpellingGame.placeWord testSetup existing (placedWord ( 6, 4 ) False c [ a, t ])
                        |> Maybe.map (\result -> ( List.map .letters result.words, result.score ))
                        -- main "CAT" = 3+1+1 = 5, "CA" = 3+1 = 4, "AA" = 1+1 = 2, "TA" = 1+1 = 2
                        |> Expect.equal (Just ( [ word [ c, a, t ], word [ c, a ], word [ a, a ], word [ t, a ] ], 13 ))
            , Test.test "double-letter squares multiply only the placed letter" <|
                \_ ->
                    -- (6,2) and (8,2) are double-letter squares, (7,2) is plain.
                    WordSpellingGame.placeWord testSetup SeqDict.empty (placedWord ( 6, 2 ) False c [ a, t ])
                        |> Maybe.map (\result -> ( List.map .letters result.words, result.score ))
                        -- C 3*2 + A 1 + T 1*2 = 9
                        |> Expect.equal (Just ( [ word [ c, a, t ] ], 9 ))
            , Test.test "the centre square doubles the whole word" <|
                \_ ->
                    -- (7,7) is the centre square (double word).
                    WordSpellingGame.placeWord testSetup SeqDict.empty (placedWord ( 7, 7 ) False c [ a, t ])
                        |> Maybe.map (\result -> ( List.map .letters result.words, result.score ))
                        -- (3+1+1) * 2 = 10
                        |> Expect.equal (Just ( [ word [ c, a, t ] ], 10 ))
            , Test.test "letters laid out skip over existing tiles" <|
                \_ ->
                    -- An existing A sits at (7,4); placing C and T around it forms "CAT".
                    let
                        existing : SeqDict ( Int, Int ) LetterOrWildcard
                        existing =
                            board [ ( ( 7, 4 ), a ) ]
                    in
                    WordSpellingGame.placeWord testSetup existing (placedWord ( 6, 4 ) False c [ t ])
                        |> Maybe.map (\result -> ( List.map .letters result.words, result.score ))
                        -- C 3 (placed) + A 1 (existing) + T 1 (placed) = 5
                        |> Expect.equal (Just ( [ word [ c, a, t ] ], 5 ))
            , Test.test "running off the edge of the board is rejected" <|
                \_ ->
                    WordSpellingGame.placeWord testSetup SeqDict.empty (placedWord ( 14, 7 ) False a [ b ])
                        |> Expect.equal Nothing
            , Test.test "each formed word reports how many of the newly placed tiles it uses" <|
                \_ ->
                    -- Existing "HELLO" runs along row 4. Placing T then O vertically at column 10
                    -- forms the short main word "TO" (both tiles newly placed) and extends the
                    -- existing row into the long cross word "HELLOO" (only the trailing O is new).
                    -- The headline word is chosen by newly placed tiles, so "TO" wins over the
                    -- longer "HELLOO".
                    let
                        existing : SeqDict ( Int, Int ) LetterOrWildcard
                        existing =
                            board
                                [ ( ( 5, 4 ), h )
                                , ( ( 6, 4 ), e )
                                , ( ( 7, 4 ), l )
                                , ( ( 8, 4 ), l )
                                , ( ( 9, 4 ), o )
                                ]
                    in
                    WordSpellingGame.placeWord testSetup existing (placedWord ( 10, 3 ) True t [ o ])
                        |> Maybe.map .words
                        |> Expect.equal
                            (Just
                                [ { letters = word [ t, o ], placedCount = 2 }
                                , { letters = word [ h, e, l, l, o, o ], placedCount = 1 }
                                ]
                            )
            ]
        , Test.describe "validatePlacement checks formed words against the word list"
            [ Test.test "accepts a placement when the word exists" <|
                \_ ->
                    WordSpellingGame.validatePlacementEnglish
                        (WordSpellingGameEnglish.buildDictionary [ "CAT" ])
                        testSetup
                        SeqDict.empty
                        (placedWord ( 6, 4 ) False c [ a, t ])
                        |> Result.map (\result -> ( List.map .letters result.words, result.score ))
                        |> Expect.equal (Ok ( [ word [ c, a, t ] ], 5 ))
            , Test.test "rejects a placement when the word does not exist" <|
                \_ ->
                    WordSpellingGame.validatePlacementEnglish
                        (WordSpellingGameEnglish.buildDictionary [ "DOG" ])
                        testSetup
                        SeqDict.empty
                        (placedWord ( 6, 4 ) False c [ a, t ])
                        |> Expect.equal (Err ())
            , Test.test "accepts only when every cross word also exists" <|
                \_ ->
                    let
                        existing : SeqDict ( Int, Int ) LetterOrWildcard
                        existing =
                            board [ ( ( 6, 5 ), a ), ( ( 7, 5 ), a ), ( ( 8, 5 ), a ) ]
                    in
                    WordSpellingGame.validatePlacementEnglish
                        (WordSpellingGameEnglish.buildDictionary [ "CAT", "CA", "AA", "TA" ])
                        testSetup
                        existing
                        (placedWord ( 6, 4 ) False c [ a, t ])
                        |> Result.map (\result -> ( List.map .letters result.words, result.score ))
                        |> Expect.equal (Ok ( [ word [ c, a, t ], word [ c, a ], word [ a, a ], word [ t, a ] ], 13 ))
            , Test.test "rejects when a cross word does not exist even if the main word does" <|
                \_ ->
                    let
                        existing : SeqDict ( Int, Int ) LetterOrWildcard
                        existing =
                            board [ ( ( 6, 5 ), a ), ( ( 7, 5 ), a ), ( ( 8, 5 ), a ) ]
                    in
                    WordSpellingGame.validatePlacementEnglish
                        -- "AA" is missing, so the placement is rejected.
                        (WordSpellingGameEnglish.buildDictionary [ "CAT", "CA", "TA" ])
                        testSetup
                        existing
                        (placedWord ( 6, 4 ) False c [ a, t ])
                        |> Expect.equal (Err ())
            , Test.test "a wildcard can stand for the letter that completes a word" <|
                \_ ->
                    -- A wildcard sits at (7,4); placing C and T around it forms "c_t", which is
                    -- valid because the wildcard can be an A to spell "CAT".
                    let
                        existing : SeqDict ( Int, Int ) LetterOrWildcard
                        existing =
                            SeqDict.fromList [ ( ( 7, 4 ), Wildcard ) ]
                    in
                    WordSpellingGame.validatePlacementEnglish
                        (WordSpellingGameEnglish.buildDictionary [ "CAT" ])
                        testSetup
                        existing
                        (placedWord ( 6, 4 ) False c [ t ])
                        |> Result.map (\result -> List.map .letters result.words)
                        |> Expect.equal (Ok [ [ Letter c, Wildcard, Letter t ] ])
            , Test.test "a wildcard is rejected when no letter completes a word" <|
                \_ ->
                    -- "c_t" has no completion in a word list that only contains "DOG".
                    let
                        existing : SeqDict ( Int, Int ) LetterOrWildcard
                        existing =
                            SeqDict.fromList [ ( ( 7, 4 ), Wildcard ) ]
                    in
                    WordSpellingGame.validatePlacementEnglish
                        (WordSpellingGameEnglish.buildDictionary [ "DOG" ])
                        testSetup
                        existing
                        (placedWord ( 6, 4 ) False c [ t ])
                        |> Expect.equal (Err ())
            , Test.test "two wildcards in one word are each tried independently" <|
                \_ ->
                    -- Wildcards at (6,4) and (8,4) with a fixed A between them form "_a_", which the
                    -- word list accepts as "CAT" (first wildcard C, second wildcard T).
                    let
                        existing : SeqDict ( Int, Int ) LetterOrWildcard
                        existing =
                            SeqDict.fromList [ ( ( 6, 4 ), Wildcard ), ( ( 8, 4 ), Wildcard ) ]
                    in
                    WordSpellingGame.validatePlacementEnglish
                        (WordSpellingGameEnglish.buildDictionary [ "CAT" ])
                        testSetup
                        existing
                        (placedWord ( 7, 4 ) False a [])
                        |> Result.map (\result -> List.map .letters result.words)
                        |> Expect.equal (Ok [ [ Wildcard, Letter a, Wildcard ] ])
            , Test.test "a word with many wildcards is matched by scanning the dictionary" <|
                \_ ->
                    -- Four wildcards around a fixed A form "__a__" (too many to brute force), which
                    -- the dictionary accepts as "KOALA".
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
                    WordSpellingGame.validatePlacementEnglish
                        (WordSpellingGameEnglish.buildDictionary [ "KOALA" ])
                        testSetup
                        existing
                        (placedWord ( 7, 4 ) False a [])
                        |> Result.map (\result -> List.map .letters result.words)
                        |> Expect.equal
                            (Ok [ [ Wildcard, Wildcard, Letter a, Wildcard, Wildcard ] ])
            , Test.test "a word with many wildcards is rejected when nothing of that length fits" <|
                \_ ->
                    -- "__a__" has no completion among the only same-length word "ABCDE" (whose third
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
                    WordSpellingGame.validatePlacementEnglish
                        (WordSpellingGameEnglish.buildDictionary [ "ABCDE" ])
                        testSetup
                        existing
                        (placedWord ( 7, 4 ) False a [])
                        |> Expect.equal (Err ())
            ]
        , Test.describe "validateSetup reads the letter distribution and values"
            [ Test.test "letters score the value chosen in the setup, whatever the alphabet" <|
                \_ ->
                    let
                        base : WordSpellingGame.SetupModel
                        base =
                            WordSpellingGame.initSetup
                    in
                    case
                        WordSpellingGame.validateSetup
                            (Id.fromInt 0)
                            (Time.millisToPosix 0)
                            { base
                                | letters = "ÅÅÅ"
                                , letterValues = SeqDict.fromList [ ( 'Å', "7" ) ]
                            }
                    of
                        Ok validated ->
                            -- Two 7-point letters on plain cells.
                            WordSpellingGame.placeWord
                                validated
                                SeqDict.empty
                                (placedWord ( 6, 4 ) False (LetterChar 'Å') [ LetterChar 'Å' ])
                                |> Maybe.map .score
                                |> Expect.equal (Just 14)

                        Err error ->
                            Expect.fail error
            , Test.test "a letter value that isn't a whole number is rejected" <|
                \_ ->
                    let
                        base : WordSpellingGame.SetupModel
                        base =
                            WordSpellingGame.initSetup
                    in
                    WordSpellingGame.validateSetup
                        (Id.fromInt 0)
                        (Time.millisToPosix 0)
                        { base | letterValues = SeqDict.fromList [ ( 'A', "not a number" ) ] }
                        |> Expect.err
            ]
        , Test.describe "the full-tray bonus rewards emptying a full tray in one move"
            [ Test.test "placing a word that uses every tile of the tray earns the configured bonus" <|
                \_ ->
                    case validatedSetup 5 40 of
                        Ok setup ->
                            -- Five placed letters with a tray size of five: the whole tray was used.
                            WordSpellingGame.fullTrayBonusScore setup (placedWord ( 5, 7 ) False h [ e, l, l, o ])
                                |> Expect.equal 40

                        Err error ->
                            Expect.fail error
            , Test.test "placing a shorter word earns no bonus" <|
                \_ ->
                    case validatedSetup 5 40 of
                        Ok setup ->
                            WordSpellingGame.fullTrayBonusScore setup (placedWord ( 6, 7 ) False c [ a, t ])
                                |> Expect.equal 0

                        Err error ->
                            Expect.fail error
            , Test.test "a zero bonus adds nothing even for a full-tray word" <|
                \_ ->
                    case validatedSetup 3 0 of
                        Ok setup ->
                            WordSpellingGame.fullTrayBonusScore setup (placedWord ( 6, 7 ) False c [ a, t ])
                                |> Expect.equal 0

                        Err error ->
                            Expect.fail error
            ]
        , Test.describe "placementConnects keeps words from floating in empty space"
            [ Test.test "the first word must cover the centre square" <|
                \_ ->
                    WordSpellingGame.placementConnects SeqDict.empty [ ( 7, 7 ), ( 8, 7 ) ]
                        |> Expect.equal True
            , Test.test "the first word is rejected if it misses the centre square" <|
                \_ ->
                    WordSpellingGame.placementConnects SeqDict.empty [ ( 0, 0 ), ( 1, 0 ) ]
                        |> Expect.equal False
            , Test.test "a later word must touch a tile already on the board" <|
                \_ ->
                    -- An existing tile at (7,7); a word placed orthogonally next to it connects.
                    WordSpellingGame.placementConnects
                        (board [ ( ( 7, 7 ), a ) ])
                        [ ( 7, 8 ), ( 7, 9 ) ]
                        |> Expect.equal True
            , Test.test "a later word floating away from every existing tile is rejected" <|
                \_ ->
                    WordSpellingGame.placementConnects
                        (board [ ( ( 7, 7 ), a ) ])
                        [ ( 0, 0 ), ( 1, 0 ) ]
                        |> Expect.equal False
            ]
        , Test.describe "trayDropSlot snaps a dropped tile to the slot nearest the cursor"
            -- The dragged tile is drawn centred on the cursor. With 50px tiles laid out from x=0
            -- (4px spacing, so a 54px pitch), slot n's centre sits at n*54 + 25.
            [ Test.test "a tile dropped on a slot's centre lands in that slot" <|
                \_ ->
                    -- Slot 3's centre is 3*54 + 25 = 187.
                    WordSpellingGame.trayDropSlot 50 0 187 7
                        |> Expect.equal 3
            , Test.test "a tile dropped just right of a slot's centre stays in that slot" <|
                \_ ->
                    -- Dropped centred at 195: still clearly over slot 3, so it must land in slot 3.
                    -- (The old off-by-one snapped this a whole slot too far, to slot 4.)
                    WordSpellingGame.trayDropSlot 50 0 195 7
                        |> Expect.equal 3
            , Test.test "a tile dropped just left of a slot's centre stays in that slot" <|
                \_ ->
                    -- Slot 4's centre is 4*54 + 25 = 241; dropped centred at 233 it lands in slot 4.
                    WordSpellingGame.trayDropSlot 50 0 233 7
                        |> Expect.equal 4
            , Test.test "dropping past the last slot clamps to the tray" <|
                \_ ->
                    WordSpellingGame.trayDropSlot 50 0 100000 7
                        |> Expect.equal 6
            , Test.test "dropping left of the tray clamps to the first slot" <|
                \_ ->
                    WordSpellingGame.trayDropSlot 50 0 -100 7
                        |> Expect.equal 0
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
