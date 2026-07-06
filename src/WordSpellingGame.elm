module WordSpellingGame exposing
    ( Action(..)
    , ActionWithTime
    , AnimatedPlacement
    , Drag(..)
    , GameData
    , GameMsg(..)
    , IsValid(..)
    , Letter(..)
    , LetterId
    , LetterOrWildcard(..)
    , LocalChange(..)
    , PlacedWord
    , PlacementResult
    , Player
    , SetupModel
    , SetupMsg(..)
    , SetupOrGame(..)
    , Shared
    , Tile
    , TilePosition(..)
    , TrayIndex(..)
    , UserStatus(..)
    , ValidatedSetup
    , ZoomAnimation
    , ZoomState
    , animatedTilePlacement
    , anyTileAnimating
    , audio
    , boardTouchCoord
    , boardY
    , dragEnd
    , dragStart
    , fullTrayBonusScore
    , gameView
    , initGame
    , initSetup
    , initShared
    , insideBoard
    , isAnimating
    , isPlayerTurn
    , isZoomAnimating
    , placeWord
    , placementConnects
    , pressedKey
    , setupView
    , trayDropSlot
    , trayTouchCoord
    , updateAction
    , updateGame
    , updateSetup
    , validatePlacement
    , validateSetup
    )

{-| Were calling it this to avoid the Scrabble trademark
-}

import Array exposing (Array)
import Array.Extra
import Audio exposing (Audio)
import Char
import Color.Manipulate
import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Dict exposing (Dict)
import Duration exposing (Duration)
import Effect.Browser.Dom as Dom
import Effect.Time as Time
import Go exposing (TimeControl)
import Html
import Html.Attributes
import Html.Events
import Icons
import Id exposing (Id, UserId)
import IdArray exposing (IdArray)
import List.Extra
import List.Nonempty exposing (Nonempty(..))
import MyUi
import NonemptyDict exposing (NonemptyDict)
import NonemptyExtra
import OneOrGreater exposing (OneOrGreater)
import PersonName
import Quantity
import Random
import SeqDict exposing (SeqDict)
import SeqDictHelper
import Set exposing (Set)
import Touch exposing (Touch)
import Ui exposing (Element)
import Ui.Font
import Ui.Lazy
import User exposing (LocalUser)
import UserSession exposing (ToBeFilledInByBackend(..))
import WordSpellingGameList exposing (Dictionary)


{-| OpaqueVariants
-}
type Drag
    = Dragging Int
    | NotDragging


type alias GameData =
    { selectedCell : Maybe ( Int, Int )
    , tiles : Array Tile
    , dragging : Drag
    , zoomAnimation : ZoomAnimation
    , -- When a word placement arrived from the server (someone else's move, or ours from another
      -- device), along with how many letters it had. Drives the staggered pop sounds that match the
      -- word's slide-in animation (see `audio`); the local player's own moves pop via the tile
      -- times instead.
      lastWordPlaced : Maybe { time : Time.Posix, letterCount : Int }
    }


type alias ZoomAnimation =
    { start : Time.Posix, from : ZoomState }


{-| A resolution-independent description of the board zoom: `amount` runs 0 (no zoom, whole board
visible) to 1 (fully zoomed in), and `focusX`/`focusY` are the point the zoom centres on as a
fraction (0 to 1) of the board. Storing it this way (rather than in pixels) keeps it correct across
window resizes and lets the same value drive both the drawn board and touch hit-testing.
-}
type alias ZoomState =
    { amount : Float, focusX : Float, focusY : Float }


type alias Tile =
    { position : TilePosition, createdAt : Time.Posix }


{-| OpaqueVariants
-}
type TilePosition
    = -- The `Maybe ( Time.Posix, Int )` records, when the tile was shifted to make room for an
      -- inserted tile, the moment the shift started and the slot it shifted from, so the view can
      -- animate it sliding from its old slot to this one.
      TileInTray TrayIndex (Maybe ( Time.Posix, Int ))
    | TileOnBoard ( Int, Int ) Time.Posix


{-| Opaque
-}
type TrayIndex
    = TrayIndex Int


{-| OpaqueVariants
-}
type SetupMsg
    = ChangedMainTimeInput String
    | ChangedIncrementInput String
    | ChangedTraySizeInput String
    | ChangedFullTrayBonusInput String
    | ChangedLettersInput String
    | ChangedLetterValue Char String
    | PressedResetLetters
    | PressedStartGame


{-| OpaqueVariants
-}
type GameMsg
    = PressedSubmitWord PlacedWord
    | PressedJoinGame
    | PressedReplaceTrayOrPass
    | PressedClearBoard


type alias SetupModel =
    { mainTimeInput : String
    , incrementInput : String
    , traySize : Int
    , fullTrayBonus : Int
    , error : Maybe String
    , letters : String

    -- The value input for each letter in the distribution, keyed by the letter's character.
    -- Letters without an entry fall back to `defaultLetterValue`.
    , letterValues : SeqDict Char String
    }


type alias ValidatedSetup =
    { timeControls : TimeControl
    , traySize : OneOrGreater
    , fullTrayBonus : Int
    , createdBy : Id UserId
    , seed : Int
    , letters : NonemptyDict LetterOrWildcard { count : OneOrGreater, value : Int }
    }


type Letter
    = LetterChar Char


initSetup : SetupModel
initSetup =
    { mainTimeInput = "10"
    , incrementInput = "5"
    , traySize = 7
    , fullTrayBonus = defaultFullTrayBonus
    , error = Nothing
    , letters = defaultLetters
    , letterValues = SeqDict.empty
    }


{-| The default points awarded for placing a word that uses every tile in a full tray (the
"bingo" bonus). Configurable per game in the setup view.
-}
defaultFullTrayBonus : number
defaultFullTrayBonus =
    50


pressedKey : GameData -> GameData
pressedKey model =
    model


initGame : Time.Posix -> ValidatedSetup -> GameData
initGame time setup =
    let
        list =
            List.range 0 (OneOrGreater.toInt setup.traySize - 1)
    in
    { selectedCell = Nothing
    , tiles =
        List.map
            (\index ->
                { position = TileInTray (TrayIndex index) Nothing
                , createdAt = Duration.addTo time (Duration.seconds (0.2 * toFloat index))
                }
            )
            list
            |> Array.fromList
    , dragging = NotDragging
    , zoomAnimation = { start = time, from = zoomedOutState }
    , lastWordPlaced = Nothing
    }


type LocalChange
    = StartMatch Time.Posix ValidatedSetup
    | Action ActionWithTime


type Action
    = PlaceWord PlacedWord (ToBeFilledInByBackend IsValid)
    | ReplaceTrayOrPass
    | JoinGame


type IsValid
    = IsValid
    | IsNotValid


type alias PlacedWord =
    { start : ( Int, Int )
    , isVertical : Bool
    , letters : Nonempty LetterOrWildcard
    }


type alias ActionWithTime =
    { userId : Id UserId, time : Time.Posix, change : Action }


type alias Shared =
    { board : SeqDict ( Int, Int ) LetterOrWildcard
    , players : Nonempty Player
    , turnCount : Int
    , passingStartedAt : Maybe Int
    , lastPlacement : Maybe AnimatedPlacement
    }


{-| The most recent placement, kept so the freshly placed tiles can be animated sliding onto the
board. This is derived from the action list (the start time comes from the `ActionWithTime`), so
the animated tiles themselves aren't tracked in the model; their on-screen positions are computed
purely from the current time (see `animatedTilePlacement`).
-}
type alias AnimatedPlacement =
    { startTime : Time.Posix
    , cells : List ( ( Int, Int ), LetterOrWildcard )
    , isValid : ToBeFilledInByBackend IsValid
    }


type alias Player =
    { userId : Id UserId
    , tray : IdArray LetterId LetterOrWildcard
    , score : Int
    }


gridSize : number
gridSize =
    15


type LetterId
    = LetterId Never


type LetterOrWildcard
    = Letter Letter
    | Wildcard


initShared : ValidatedSetup -> Shared
initShared setup =
    let
        initialBoard : SeqDict ( Int, Int ) LetterOrWildcard
        initialBoard =
            SeqDict.empty
    in
    { board = initialBoard
    , players = Nonempty (initPlayer setup.createdBy initialBoard setup []) []
    , turnCount = 0
    , lastPlacement = Nothing
    , passingStartedAt = Nothing
    }


remainingLettersInBagCount : ValidatedSetup -> SeqDict ( Int, Int ) LetterOrWildcard -> List Player -> Int
remainingLettersInBagCount setup board players =
    SeqDict.foldl
        (\_ a total -> OneOrGreater.toInt a + total)
        0
        (remainingLettersInBag setup board players)


remainingLettersInBag :
    ValidatedSetup
    -> SeqDict ( Int, Int ) LetterOrWildcard
    -> List Player
    -> SeqDict LetterOrWildcard OneOrGreater
remainingLettersInBag setup board players =
    let
        remainingLetters : SeqDict LetterOrWildcard OneOrGreater
        remainingLetters =
            SeqDict.foldl
                (\_ letter startingLetters2 -> SeqDictHelper.decrement letter startingLetters2)
                (NonemptyDict.toSeqDict setup.letters |> SeqDict.map (\_ a -> a.count))
                board
    in
    List.foldl
        (\player remainingLetters2 -> IdArray.foldl SeqDictHelper.decrement remainingLetters2 player.tray)
        remainingLetters
        players


getLetters :
    OneOrGreater
    -> ValidatedSetup
    -> SeqDict ( Int, Int ) LetterOrWildcard
    -> List Player
    -> Int
    -> List LetterOrWildcard
getLetters count setup board players turnCount =
    Random.step
        (SeqDict.foldl
            (\letter count2 list -> List.repeat (OneOrGreater.toInt count2) letter ++ list)
            []
            (remainingLettersInBag setup board players)
            |> shuffle
        )
        (Random.initialSeed (setup.seed + turnCount))
        |> Tuple.first
        |> List.take (OneOrGreater.toInt count)


{-| Shuffle the list. Takes O(_n_ log _n_) time and no extra space. Original code found here <https://github.com/elm-community/random-extra/blob/d52055975644ad401709c2aff14dab9ca93e44a0/src/Random/List.elm#L88>
-}
shuffle : List a -> Random.Generator (List a)
shuffle list =
    Random.map
        (\independentSeed ->
            list
                |> List.foldl
                    (\item ( acc, seed ) ->
                        let
                            ( tag, nextSeed ) =
                                Random.step (Random.int Random.minInt Random.maxInt) seed
                        in
                        ( ( item, tag ) :: acc, nextSeed )
                    )
                    ( [], independentSeed )
                |> Tuple.first
                |> List.sortBy Tuple.second
                |> List.map Tuple.first
        )
        Random.independentSeed


{-| The game is over either when every player has passed in turn, or as soon as any player has no
letters left. An empty tray means the bag is empty too: trays are refilled from the bag after every
placement, so a tray can only end up empty once there was nothing left to draw.
-}
getWinner : Shared -> Maybe (Nonempty (Id UserId))
getWinner shared =
    let
        everyonePassed : Bool
        everyonePassed =
            case shared.passingStartedAt of
                Just passingStartedAt ->
                    List.Nonempty.length shared.players <= shared.turnCount - passingStartedAt

                Nothing ->
                    False

        someoneOutOfLetters : Bool
        someoneOutOfLetters =
            List.Nonempty.any (\player -> IdArray.isEmpty player.tray) shared.players
    in
    if everyonePassed || someoneOutOfLetters then
        let
            player =
                NonemptyExtra.maximumBy .score shared.players
        in
        List.Nonempty.filter (\a -> a.score == player.score) player shared.players
            |> List.Nonempty.map .userId
            |> Just

    else
        Nothing


{-| The extra points awarded for placing a word that empties a full tray in one move (a "bingo").
A placement can only draw from the player's tray, which never holds more than `traySize` tiles, so
placing exactly `traySize` letters means every tile of a full tray was used. Returns 0 otherwise.
-}
fullTrayBonusScore : ValidatedSetup -> PlacedWord -> Int
fullTrayBonusScore setup placedWord =
    if List.Nonempty.length placedWord.letters == OneOrGreater.toInt setup.traySize then
        setup.fullTrayBonus

    else
        0


updateAction : ValidatedSetup -> ActionWithTime -> Shared -> Shared
updateAction setup action shared =
    case action.change of
        PlaceWord placedWord isValid ->
            case ( getWinner shared, getPlayer action.userId shared ) of
                ( Nothing, Just player ) ->
                    case placeWord setup shared.board placedWord of
                        Just result ->
                            let
                                animatedPlacement : Maybe AnimatedPlacement
                                animatedPlacement =
                                    Just { startTime = action.time, cells = result.placedCells, isValid = isValid }

                                remainingTray : List LetterOrWildcard
                                remainingTray =
                                    List.foldl
                                        removeFromTray
                                        (IdArray.toList player.tray)
                                        (List.Nonempty.toList placedWord.letters)

                                tray : IdArray LetterId LetterOrWildcard
                                tray =
                                    case isValid of
                                        FilledInByBackend IsNotValid ->
                                            -- The placed letters return to the player's tray instead
                                            -- of going back in the bag, and nothing new is drawn.
                                            -- They're appended after the kept letters so they land in
                                            -- the tray slots the placement freed up (the local tile
                                            -- model refilled those slots on submit).
                                            remainingTray
                                                ++ List.Nonempty.toList placedWord.letters
                                                |> IdArray.fromList

                                        _ ->
                                            let
                                                drawn : List LetterOrWildcard
                                                drawn =
                                                    case OneOrGreater.fromInt (OneOrGreater.toInt setup.traySize - List.length remainingTray) of
                                                        Just drawCount ->
                                                            getLetters
                                                                drawCount
                                                                setup
                                                                result.board
                                                                (NonemptyExtra.set shared.turnCount { player | tray = IdArray.fromList remainingTray } shared.players
                                                                    |> List.Nonempty.toList
                                                                )
                                                                shared.turnCount

                                                        Nothing ->
                                                            []
                                            in
                                            remainingTray ++ drawn |> IdArray.fromList
                            in
                            { shared
                                | board =
                                    case isValid of
                                        FilledInByBackend IsNotValid ->
                                            shared.board

                                        _ ->
                                            result.board
                                , players =
                                    NonemptyExtra.set
                                        shared.turnCount
                                        { player
                                            | tray = tray
                                            , score =
                                                case isValid of
                                                    FilledInByBackend IsNotValid ->
                                                        player.score

                                                    _ ->
                                                        player.score + result.score + fullTrayBonusScore setup placedWord
                                        }
                                        shared.players
                                , turnCount = shared.turnCount + 1
                                , lastPlacement = animatedPlacement
                                , passingStartedAt =
                                    if tray == IdArray.empty then
                                        case shared.passingStartedAt of
                                            Nothing ->
                                                Just shared.turnCount

                                            Just _ ->
                                                shared.passingStartedAt

                                    else
                                        Nothing
                            }

                        Nothing ->
                            shared

                _ ->
                    shared

        ReplaceTrayOrPass ->
            case ( getWinner shared, getPlayer action.userId shared ) of
                ( Nothing, Just player ) ->
                    case passBehavior setup shared of
                        ShouldReplaceTray ->
                            { shared
                                | players =
                                    NonemptyExtra.set
                                        shared.turnCount
                                        { player
                                            | tray =
                                                getLetters
                                                    setup.traySize
                                                    setup
                                                    shared.board
                                                    (NonemptyExtra.set shared.turnCount { player | tray = IdArray.empty } shared.players
                                                        |> List.Nonempty.toList
                                                    )
                                                    shared.turnCount
                                                    |> IdArray.fromList
                                        }
                                        shared.players
                                , turnCount = shared.turnCount + 1
                                , passingStartedAt = Nothing
                            }

                        ShouldPass ->
                            { shared
                                | passingStartedAt =
                                    case shared.passingStartedAt of
                                        Nothing ->
                                            Just shared.turnCount

                                        Just _ ->
                                            shared.passingStartedAt
                                , turnCount = shared.turnCount + 1
                            }

                        ShouldEndGame ->
                            { shared | turnCount = shared.turnCount + 1 }

                _ ->
                    shared

        JoinGame ->
            if canJoin shared then
                { shared
                    | players =
                        List.Nonempty.append
                            shared.players
                            (Nonempty
                                (initPlayer action.userId shared.board setup (List.Nonempty.toList shared.players))
                                []
                            )
                }

            else
                shared


canJoin : Shared -> Bool
canJoin shared =
    shared.turnCount <= List.Nonempty.length shared.players


initPlayer : Id UserId -> SeqDict ( Int, Int ) LetterOrWildcard -> ValidatedSetup -> List Player -> Player
initPlayer userId board setup existingPlayers =
    { userId = userId
    , tray = getLetters setup.traySize setup board existingPlayers 0 |> IdArray.fromList
    , score = 0
    }


type alias PlacementResult =
    { board : SeqDict ( Int, Int ) LetterOrWildcard
    , words : List (List LetterOrWildcard)
    , score : Int
    , placedCells : List ( ( Int, Int ), LetterOrWildcard )
    }


{-| Lay a word's new letters out along the placement direction starting from `start`, stepping
over any tiles already on the board (which aren't placed again), then work out every word that
the placement forms: the main word along the placement direction, plus any perpendicular
cross-word that runs through a newly-placed tile. Returns `Nothing` if the letters run off the
edge of the board.

The returned `words` are the formed words' tiles in order (upper case, like the word list), and
`score` is the combined Scrabble score of all the formed words (letter and word multipliers only
apply to the squares the new tiles land on; wildcards score zero).

-}
placeWord : ValidatedSetup -> SeqDict ( Int, Int ) LetterOrWildcard -> PlacedWord -> Maybe PlacementResult
placeWord setup board placedWord =
    let
        ( dx, dy ) =
            if placedWord.isVertical then
                ( 0, 1 )

            else
                ( 1, 0 )

        -- Lay out the new tiles, stepping over tiles already committed to the board.
        layout : ( Int, Int ) -> List LetterOrWildcard -> List ( ( Int, Int ), LetterOrWildcard ) -> Maybe (List ( ( Int, Int ), LetterOrWildcard ))
        layout ( cx, cy ) remaining acc =
            case remaining of
                [] ->
                    Just (List.reverse acc)

                letterOrWildcard :: rest ->
                    if cx < 0 || cy < 0 || cx >= gridSize || cy >= gridSize then
                        Nothing

                    else
                        case SeqDict.get ( cx, cy ) board of
                            Just _ ->
                                layout ( cx + dx, cy + dy ) remaining acc

                            Nothing ->
                                layout ( cx + dx, cy + dy ) rest (( ( cx, cy ), letterOrWildcard ) :: acc)
    in
    case layout placedWord.start (List.Nonempty.toList placedWord.letters) [] of
        Just placedCells ->
            let
                newBoard : SeqDict ( Int, Int ) LetterOrWildcard
                newBoard =
                    List.foldl
                        (\( cell, letterOrWildcard ) acc -> SeqDict.insert cell letterOrWildcard acc)
                        board
                        placedCells

                placedCoords : List ( Int, Int )
                placedCoords =
                    List.map Tuple.first placedCells

                placedSet : Set ( Int, Int )
                placedSet =
                    Set.fromList placedCoords

                -- The main word runs along the placement direction through the first placed tile.
                mainWord : List ( Int, Int )
                mainWord =
                    case placedCoords of
                        first :: _ ->
                            lineWord newBoard ( dx, dy ) first

                        [] ->
                            []

                -- A cross word runs perpendicular to the placement direction through a placed tile.
                crossWords : List (List ( Int, Int ))
                crossWords =
                    List.filterMap
                        (\cell ->
                            let
                                word : List ( Int, Int )
                                word =
                                    lineWord newBoard ( dy, dx ) cell
                            in
                            if List.length word >= 2 then
                                Just word

                            else
                                Nothing
                        )
                        placedCoords

                allWords : List (List ( Int, Int ))
                allWords =
                    (if List.length mainWord >= 2 then
                        [ mainWord ]

                     else
                        []
                    )
                        ++ crossWords
            in
            Just
                { board = newBoard
                , words = List.map (wordString newBoard) allWords
                , score = List.sum (List.map (wordScore setup newBoard placedSet) allWords)
                , placedCells = placedCells
                }

        Nothing ->
            Nothing


{-| The maximal contiguous run of tiles through `cell` in the direction `( dirX, dirY )`.
-}
lineWord : SeqDict ( Int, Int ) LetterOrWildcard -> ( Int, Int ) -> ( Int, Int ) -> List ( Int, Int )
lineWord board ( dirX, dirY ) cell =
    let
        walkBack : ( Int, Int ) -> ( Int, Int )
        walkBack ( cx, cy ) =
            let
                prev : ( Int, Int )
                prev =
                    ( cx - dirX, cy - dirY )
            in
            if SeqDict.member prev board then
                walkBack prev

            else
                ( cx, cy )

        walkForward : ( Int, Int ) -> List ( Int, Int ) -> List ( Int, Int )
        walkForward ( cx, cy ) acc =
            if SeqDict.member ( cx, cy ) board then
                walkForward ( cx + dirX, cy + dirY ) (( cx, cy ) :: acc)

            else
                List.reverse acc
    in
    walkForward (walkBack cell) []


{-| The tiles (letters and wildcards) forming the word at the given cells, in order. Wildcards are
kept as `Wildcard` rather than resolved to a letter, since the tile on the board doesn't record
which letter the player meant; `wordIsValid` tries every letter for them when checking the word.
-}
wordString : SeqDict ( Int, Int ) LetterOrWildcard -> List ( Int, Int ) -> List LetterOrWildcard
wordString board cells =
    List.filterMap (\cell -> SeqDict.get cell board) cells


{-| The Scrabble score of a single word. Letter and word multipliers only apply to the squares
that the newly-placed tiles (`placedSet`) land on; wildcards always score zero.
-}
wordScore : ValidatedSetup -> SeqDict ( Int, Int ) LetterOrWildcard -> Set ( Int, Int ) -> List ( Int, Int ) -> Int
wordScore setup board placedSet cells =
    let
        letterSum : Int
        letterSum =
            List.map
                (\cell ->
                    case SeqDict.get cell board of
                        Just (Letter letter) ->
                            if Set.member cell placedSet then
                                letterValue setup letter * letterScoreMultiplier cell

                            else
                                letterValue setup letter

                        Just Wildcard ->
                            0

                        Nothing ->
                            0
                )
                cells
                |> List.sum

        wordMultiplier : Int
        wordMultiplier =
            List.map
                (\cell ->
                    if Set.member cell placedSet then
                        wordScoreMultiplier cell

                    else
                        1
                )
                cells
                |> List.product
    in
    letterSum * wordMultiplier


{-| Like `placeWord`, but only succeeds if at least one word is formed and every formed word
exists in the dictionary (see `wordIsValid` for how words containing wildcards are handled).
-}
validatePlacement : Dictionary -> ValidatedSetup -> SeqDict ( Int, Int ) LetterOrWildcard -> PlacedWord -> Result () PlacementResult
validatePlacement dictionary setup board placedWord =
    case placeWord setup board placedWord of
        Just result ->
            if List.isEmpty result.words then
                Err ()

            else if List.all (wordIsValid dictionary setup) result.words then
                Ok result

            else
                Err ()

        Nothing ->
            Err ()


{-| The most wildcards we'll resolve by trying every letter combination. With `k` wildcards that's
26^k dictionary lookups, so we only do it while that stays cheap (26^2 = 676); beyond it we scan
instead, which keeps the work bounded no matter how many wildcards a word has.
-}
maxBruteForceWildcards : Int
maxBruteForceWildcards =
    2


{-| Whether a formed word is in the dictionary. A wildcard tile can stand for any letter, but the
board doesn't record which letter the player meant, so a word containing wildcards is valid if
_some_ assignment of letters to its wildcards spells a word in the dictionary.

There are two ways to check this, and we pick whichever is bounded by the smaller amount of work:

  - With few wildcards, try every letter in the game's distribution for them (`bruteForceMatch`):
    at most n^k lookups for n distinct letters.
  - With many wildcards, n^k explodes (e.g. 26 letters and 4 wildcards is ~457k), so instead scan
    the dictionary words of this length and keep any that agree with the fixed letters
    (`scanForMatch`). That's one pass over a single length bucket — at most ~30k words for this
    dictionary — regardless of how many wildcards there are. This is what stops a word like
    "3 letters + 4 wildcards" locking up the server.

-}
wordIsValid : Dictionary -> ValidatedSetup -> List LetterOrWildcard -> Bool
wordIsValid dictionary setup word =
    if List.Extra.count (\cell -> cell == Wildcard) word <= maxBruteForceWildcards then
        bruteForceMatch (distributionLetters setup) dictionary.all word

    else
        scanForMatch dictionary.byLength word


{-| The distinct letters present in the game's letter distribution: the only letters a wildcard
can stand for.
-}
distributionLetters : ValidatedSetup -> List Letter
distributionLetters setup =
    List.filterMap
        (\letterOrWildcard ->
            case letterOrWildcard of
                Letter letter ->
                    Just letter

                Wildcard ->
                    Nothing
        )
        (NonemptyDict.keys setup.letters |> List.Nonempty.toList)


{-| Try every letter for each wildcard, building the candidate string from left to right and
stopping as soon as one is in the word list. With no wildcards this is a single `Set.member` lookup.
Only used when there are few wildcards (see `maxBruteForceWildcards`), so this does at most n^k
lookups for small `k`.
-}
bruteForceMatch : List Letter -> Set String -> List LetterOrWildcard -> Bool
bruteForceMatch candidateLetters wordList word =
    let
        search : List LetterOrWildcard -> String -> Bool
        search remaining prefix =
            case remaining of
                [] ->
                    Set.member prefix wordList

                (Letter (LetterChar letter)) :: rest ->
                    search rest (prefix ++ String.fromChar letter)

                Wildcard :: rest ->
                    List.any (\(LetterChar letter) -> search rest (prefix ++ String.fromChar letter)) candidateLetters
    in
    search word ""


{-| Whether any dictionary word of the same length agrees with the word's fixed (non-wildcard)
letters; the wildcards then stand for whatever letters that dictionary word has in their place. This
costs a single pass over the words of that length, which is bounded however many wildcards there are.
-}
scanForMatch : Dict Int (Array String) -> List LetterOrWildcard -> Bool
scanForMatch byLength word =
    let
        pattern : List (Maybe Char)
        pattern =
            List.map
                (\cell ->
                    case cell of
                        Letter (LetterChar letter) ->
                            Just letter

                        Wildcard ->
                            Nothing
                )
                word
    in
    case Dict.get (List.length word) byLength of
        Just candidates ->
            Array.Extra.any (matchesPattern pattern) candidates

        Nothing ->
            False


{-| Whether a dictionary word agrees with a pattern: each fixed position (`Just char`) must equal
the word's character there, and wildcard positions (`Nothing`) match anything. The word and pattern
are the same length, since the candidates come from the matching length bucket.
-}
matchesPattern : List (Maybe Char) -> String -> Bool
matchesPattern pattern candidate =
    List.map2
        (\patternChar candidateChar ->
            case patternChar of
                Just fixed ->
                    fixed == candidateChar

                Nothing ->
                    True
        )
        pattern
        (String.toList candidate)
        |> List.all identity


letterScoreMultiplier : ( Int, Int ) -> Int
letterScoreMultiplier position =
    case SeqDict.get position bonusCells of
        Just DoubleLetter ->
            2

        Just TripleLetter ->
            3

        _ ->
            1


wordScoreMultiplier : ( Int, Int ) -> Int
wordScoreMultiplier position =
    case SeqDict.get position bonusCells of
        Just DoubleWord ->
            2

        Just TripleWord ->
            3

        Just CenterCell ->
            2

        _ ->
            1


{-| Remove one matching tile from the tray. If the exact letter isn't held a wildcard must have
been used in its place, so remove a wildcard instead.
-}
removeFromTray : LetterOrWildcard -> List LetterOrWildcard -> List LetterOrWildcard
removeFromTray letterOrWildcard tray =
    if List.member letterOrWildcard tray then
        List.Extra.remove letterOrWildcard tray

    else
        List.Extra.remove Wildcard tray


type SetupOrGame
    = Setup SetupModel
    | Game GameData


updateSetup :
    Time.Posix
    -> Id UserId
    -> SetupMsg
    -> SetupModel
    -> ( SetupOrGame, Maybe ValidatedSetup )
updateSetup time currentUserId msg setup =
    case msg of
        ChangedMainTimeInput input ->
            ( Setup { setup | mainTimeInput = input, error = Nothing }, Nothing )

        ChangedIncrementInput input ->
            ( Setup { setup | incrementInput = input, error = Nothing }, Nothing )

        ChangedTraySizeInput input ->
            ( { setup
                | traySize = String.toInt (String.trim input) |> Maybe.withDefault setup.traySize
                , error = Nothing
              }
                |> Setup
            , Nothing
            )

        ChangedFullTrayBonusInput input ->
            ( { setup
                | fullTrayBonus = String.toInt (String.trim input) |> Maybe.withDefault setup.fullTrayBonus
                , error = Nothing
              }
                |> Setup
            , Nothing
            )

        ChangedLettersInput input ->
            ( Setup { setup | letters = input, error = Nothing }, Nothing )

        ChangedLetterValue char input ->
            ( Setup { setup | letterValues = SeqDict.insert char input setup.letterValues, error = Nothing }
            , Nothing
            )

        PressedResetLetters ->
            ( Setup { setup | letters = defaultLetters, letterValues = SeqDict.empty, error = Nothing }, Nothing )

        PressedStartGame ->
            case validateSetup currentUserId time setup of
                Ok validated ->
                    ( initGame time validated |> Game, Just validated )

                Err error ->
                    ( Setup { setup | error = Just error }, Nothing )


updateGame : Time.Posix -> Id UserId -> ValidatedSetup -> Shared -> GameMsg -> GameData -> ( GameData, Maybe ActionWithTime )
updateGame time currentUserId setup shared msg model =
    case msg of
        PressedSubmitWord placement ->
            case placeWord setup shared.board placement of
                Just result ->
                    let
                        -- The board cells this line actually consumes (its newly placed tiles).
                        lineCells : Set ( Int, Int )
                        lineCells =
                            List.map Tuple.first result.placedCells |> Set.fromList

                        -- Keep the tiles still in the tray as-is, and send any tiles the player left
                        -- on the board that aren't part of this line (stray letters) back to the
                        -- tray. The line's own tiles are consumed and replaced by freshly drawn ones.
                        kept : Array Tile
                        kept =
                            Array.foldl
                                (\tile acc ->
                                    case tile.position of
                                        TileInTray _ _ ->
                                            Array.push tile acc

                                        TileOnBoard cell _ ->
                                            if Set.member cell lineCells then
                                                acc

                                            else
                                                Array.push
                                                    { tile | position = TileInTray (firstOpenTrayIndex Nothing acc) Nothing }
                                                    acc
                                )
                                Array.empty
                                model.tiles

                        newTileCount : Int
                        newTileCount =
                            OneOrGreater.toInt setup.traySize - Array.length kept
                    in
                    ( withZoomAnimation time
                        model
                        { model
                            | dragging = NotDragging
                            , tiles =
                                List.foldl
                                    (\index tray ->
                                        Array.push
                                            { position = TileInTray (firstOpenTrayIndex Nothing tray) Nothing
                                            , createdAt =
                                                Duration.addTo
                                                    time
                                                    (Quantity.sum
                                                        [ Duration.seconds (0.1 * toFloat index)
                                                        , placementAnimationDuration (FilledInByBackend IsNotValid) newTileCount
                                                        ]
                                                    )
                                            }
                                            tray
                                    )
                                    kept
                                    (List.range 0 (newTileCount - 1))
                        }
                    , Just { userId = currentUserId, change = PlaceWord placement EmptyPlaceholder, time = time }
                    )

                Nothing ->
                    ( model, Nothing )

        PressedJoinGame ->
            ( model, Just { userId = currentUserId, change = JoinGame, time = time } )

        PressedReplaceTrayOrPass ->
            let
                lettersLeftIncludingTray =
                    remainingLettersInBagCount
                        setup
                        shared.board
                        (List.Nonempty.toList shared.players
                            |> List.filter (\player -> player.userId == currentUserId)
                        )
                        |> min (OneOrGreater.toInt setup.traySize)

                list =
                    List.range 0 (lettersLeftIncludingTray - 1)
            in
            ( { model
                | tiles =
                    List.map
                        (\index ->
                            { position = TileInTray (TrayIndex index) Nothing
                            , createdAt = Duration.addTo time (Duration.seconds (0.2 * toFloat index))
                            }
                        )
                        list
                        |> Array.fromList
              }
            , Just { userId = currentUserId, change = ReplaceTrayOrPass, time = time }
            )

        PressedClearBoard ->
            -- Send every tile the player has resting on the board back to the tray, keeping the tiles
            -- already in the tray where they are and filling the freed slots (mirrors how `dragEnd`
            -- returns a single tile). The order of `model.tiles` is preserved since it's index-aligned
            -- with the player's tray letters (see `placedTiles`).
            ( { model
                | dragging = NotDragging
                , tiles =
                    Array.foldl
                        (\tile ( acc, taken ) ->
                            case tile.position of
                                TileInTray _ _ ->
                                    ( Array.push tile acc, taken )

                                TileOnBoard _ _ ->
                                    let
                                        index : Int
                                        index =
                                            lowestFreeTrayIndex 0 taken
                                    in
                                    ( Array.push { tile | position = TileInTray (TrayIndex index) Nothing } acc
                                    , Set.insert index taken
                                    )
                        )
                        ( Array.empty, trayIndicesInUse model.tiles )
                        model.tiles
                        |> Tuple.first
              }
            , Nothing
            )


{-| The tiles the local player has dragged onto the board this turn, paired with the letter each
holds (their tray is index-aligned with `GameData.tiles`; see `boardView`).
-}
placedTiles : Id UserId -> Shared -> GameData -> List ( ( Int, Int ), LetterOrWildcard )
placedTiles currentUserId shared model =
    case getPlayer currentUserId shared of
        Just player ->
            List.map2 Tuple.pair (Array.toList model.tiles) (IdArray.toList player.tray)
                |> List.filterMap
                    (\( tile, letter ) ->
                        case tile.position of
                            TileOnBoard cell _ ->
                                Just ( cell, letter )

                            TileInTray _ _ ->
                                Nothing
                    )

        Nothing ->
            []


{-| Every word the player could submit from the tiles they've placed on the board this turn. Each
straight run of the player's placed tiles (two or more collinear tiles, bridged by any committed
tiles between them, or a lone tile that extends an existing word) that forms a valid placement
becomes one entry, along with the board cell next to which its submit button is drawn.

A player can end up with several placed runs at once (e.g. tiles that cross, or a stray tile left
elsewhere); each valid run gets its own button, and submitting one returns the other placed tiles to
the tray (see `updateGame`). Whether the formed words are real dictionary words is still decided on
the backend (see `wordIsValid`).

-}
submittableLines : Id UserId -> Shared -> GameData -> List { placedWord : PlacedWord, buttonCell : ( Int, Int ) }
submittableLines currentUserId shared model =
    let
        placed : List ( ( Int, Int ), LetterOrWildcard )
        placed =
            placedTiles currentUserId shared model

        placedCells : Set ( Int, Int )
        placedCells =
            List.map Tuple.first placed |> Set.fromList

        runsFor : Bool -> List ( Bool, List ( ( Int, Int ), LetterOrWildcard ) )
        runsFor isVertical =
            lineRuns isVertical shared.board placed
                |> List.filter (\run -> List.length run >= 2)
                |> List.map (\run -> ( isVertical, run ))

        bigRuns : List ( Bool, List ( ( Int, Int ), LetterOrWildcard ) )
        bigRuns =
            runsFor False ++ runsFor True

        inBigRun : Set ( Int, Int )
        inBigRun =
            List.concatMap (\( _, run ) -> List.map Tuple.first run) bigRuns |> Set.fromList

        -- A placed tile that isn't part of any two-tile run is on its own; it can still be a valid
        -- play if it extends a committed word.
        loneRuns : List ( Bool, List ( ( Int, Int ), LetterOrWildcard ) )
        loneRuns =
            placed
                |> List.filter (\( cell, _ ) -> not (Set.member cell inBigRun))
                |> List.map (\tile -> ( False, [ tile ] ))
    in
    (bigRuns ++ loneRuns)
        |> List.filterMap
            (\( isVertical, run ) ->
                case buildPlacedWord isVertical shared run of
                    Ok placedWord ->
                        Just
                            { placedWord = placedWord
                            , buttonCell = submitButtonCell isVertical (List.map Tuple.first run) placedCells shared.board
                            }

                    Err () ->
                        Nothing
            )


{-| Split the placed tiles into maximal straight runs along one axis. Two placed tiles are in the
same run when they share the line (same row for horizontal, same column for vertical) and every cell
between them is filled, either by another placed tile or a committed one.
-}
lineRuns : Bool -> SeqDict ( Int, Int ) LetterOrWildcard -> List ( ( Int, Int ), LetterOrWildcard ) -> List (List ( ( Int, Int ), LetterOrWildcard ))
lineRuns isVertical board placed =
    let
        lineKey : ( Int, Int ) -> Int
        lineKey ( x, y ) =
            if isVertical then
                x

            else
                y

        linePos : ( Int, Int ) -> Int
        linePos ( x, y ) =
            if isVertical then
                y

            else
                x

        cellAt : Int -> Int -> ( Int, Int )
        cellAt key pos =
            if isVertical then
                ( key, pos )

            else
                ( pos, key )

        bridged : Int -> Int -> Int -> Bool
        bridged key from to =
            List.range (from + 1) (to - 1)
                |> List.all (\pos -> SeqDict.member (cellAt key pos) board)

        groups : List (List ( ( Int, Int ), LetterOrWildcard ))
        groups =
            List.foldr
                (\item dict -> Dict.update (lineKey (Tuple.first item)) (\m -> Just (item :: Maybe.withDefault [] m)) dict)
                Dict.empty
                placed
                |> Dict.values
    in
    List.concatMap
        (\group ->
            let
                key : Int
                key =
                    case group of
                        ( cell, _ ) :: _ ->
                            lineKey cell

                        [] ->
                            0

                sorted : List ( ( Int, Int ), LetterOrWildcard )
                sorted =
                    List.sortBy (\( cell, _ ) -> linePos cell) group
            in
            List.foldl
                (\item runs ->
                    case runs of
                        currentRun :: doneRuns ->
                            case currentRun of
                                ( lastCell, _ ) :: _ ->
                                    if bridged key (linePos lastCell) (linePos (Tuple.first item)) then
                                        (item :: currentRun) :: doneRuns

                                    else
                                        [ item ] :: currentRun :: doneRuns

                                [] ->
                                    [ item ] :: doneRuns

                        [] ->
                            [ [ item ] ]
                )
                []
                sorted
                |> List.map List.reverse
        )
        groups


{-| The board cell next to which a line's submit button is drawn: the cell just past the end of the
line, or just before its start, preferring whichever is on the board and unoccupied.
-}
submitButtonCell : Bool -> List ( Int, Int ) -> Set ( Int, Int ) -> SeqDict ( Int, Int ) LetterOrWildcard -> ( Int, Int )
submitButtonCell isVertical runCells placedCells board =
    let
        linePos : ( Int, Int ) -> Int
        linePos ( x, y ) =
            if isVertical then
                y

            else
                x

        sorted : List ( Int, Int )
        sorted =
            List.sortBy linePos runCells

        ( dx, dy ) =
            if isVertical then
                ( 0, 1 )

            else
                ( 1, 0 )

        onBoard : ( Int, Int ) -> Bool
        onBoard ( x, y ) =
            x >= 0 && y >= 0 && x < gridSize && y < gridSize

        vacant : ( Int, Int ) -> Bool
        vacant cell =
            not (SeqDict.member cell board) && not (Set.member cell placedCells)

        afterEnd : ( Int, Int )
        afterEnd =
            case List.Extra.last sorted of
                Just ( x, y ) ->
                    ( x + dx, y + dy )

                Nothing ->
                    ( 0, 0 )

        beforeStart : ( Int, Int )
        beforeStart =
            case List.head sorted of
                Just ( x, y ) ->
                    ( x - dx, y - dy )

                Nothing ->
                    ( 0, 0 )
    in
    if onBoard afterEnd && vacant afterEnd then
        afterEnd

    else if onBoard beforeStart && vacant beforeStart then
        beforeStart

    else if onBoard afterEnd then
        afterEnd

    else
        beforeStart


buildPlacedWord : Bool -> Shared -> List ( ( Int, Int ), LetterOrWildcard ) -> Result () PlacedWord
buildPlacedWord isVertical shared placed =
    let
        lineCoord : ( Int, Int ) -> Int
        lineCoord ( x, y ) =
            if isVertical then
                y

            else
                x

        sorted : List ( ( Int, Int ), LetterOrWildcard )
        sorted =
            List.sortBy (\( cell, _ ) -> lineCoord cell) placed

        placedCells : List ( Int, Int )
        placedCells =
            List.map Tuple.first sorted
    in
    case ( List.head placedCells, List.Extra.last placedCells ) of
        ( Just startCell, Just endCell ) ->
            let
                -- Every cell between the first and last placed tile must be filled, either by a
                -- tile placed this turn or a committed tile.
                contiguous : Bool
                contiguous =
                    List.range (lineCoord startCell) (lineCoord endCell)
                        |> List.all
                            (\n ->
                                let
                                    cell : ( Int, Int )
                                    cell =
                                        if isVertical then
                                            ( Tuple.first startCell, n )

                                        else
                                            ( n, Tuple.second startCell )
                                in
                                List.member cell placedCells || SeqDict.member cell shared.board
                            )

                connected : Bool
                connected =
                    placementConnects shared.board placedCells
            in
            case ( contiguous && connected, nonemptyLetters sorted ) of
                ( True, Just letters ) ->
                    Ok { start = startCell, isVertical = isVertical, letters = letters }

                _ ->
                    Err ()

        _ ->
            Err ()


{-| Whether a placement connects to the rest of the board, so words can't float in empty space.
The very first word of the game (when the board is empty) has to cover the centre square; every word
after that has to touch a tile already on the board, either by sitting orthogonally next to one or
by extending through one in its own line (the latter is also adjacency, so this single check covers
it). `placedCells` are the cells the player filled this turn, none of which are on `board` yet.
-}
placementConnects : SeqDict ( Int, Int ) LetterOrWildcard -> List ( Int, Int ) -> Bool
placementConnects board placedCells =
    if SeqDict.isEmpty board then
        List.member centerCell placedCells

    else
        List.any
            (\cell ->
                List.any (\neighbor -> SeqDict.member neighbor board) (orthogonalNeighbors cell)
            )
            placedCells


{-| The centre square, which the first word of the game must cover.
-}
centerCell : ( Int, Int )
centerCell =
    ( gridSize // 2, gridSize // 2 )


{-| The four cells directly above, below, left and right of a cell.
-}
orthogonalNeighbors : ( Int, Int ) -> List ( Int, Int )
orthogonalNeighbors ( x, y ) =
    [ ( x - 1, y ), ( x + 1, y ), ( x, y - 1 ), ( x, y + 1 ) ]


{-| Pull the tiles (letters and wildcards) out of the placed cells in order, failing only if there
are no tiles. Wildcards are kept as `Wildcard`; the letter they stand for is worked out later when
the word is checked against the dictionary (see `wordIsValid`).
-}
nonemptyLetters : List ( ( Int, Int ), LetterOrWildcard ) -> Maybe (Nonempty LetterOrWildcard)
nonemptyLetters list =
    List.map Tuple.second list
        |> List.Nonempty.fromList


validateSetup : Id UserId -> Time.Posix -> SetupModel -> Result String ValidatedSetup
validateSetup createdBy time setup =
    case parseTimeControl setup of
        Err error ->
            Err error

        Ok timeControls ->
            case OneOrGreater.fromInt setup.traySize of
                Just traySize ->
                    case parseLetters setup.letters |> Result.andThen (withLetterValues setup) of
                        Ok letters ->
                            { createdBy = createdBy
                            , timeControls = timeControls
                            , traySize = traySize
                            , fullTrayBonus = setup.fullTrayBonus
                            , seed =
                                -- Round the time to the nearest 10 seconds so that small timing changes don't break an end-to-end test
                                Time.posixToMillis time // 10000 |> (*) 10000 |> (+) (Id.toInt createdBy)
                            , letters = letters
                            }
                                |> Ok

                        Err error ->
                            Err error

                Nothing ->
                    Err "Tray size must be at least 1"


{-| Pair each tile in the distribution with the value the user chose for it in the setup view
(wildcards are always worth 0 points).
-}
withLetterValues :
    SetupModel
    -> NonemptyDict LetterOrWildcard OneOrGreater
    -> Result String (NonemptyDict LetterOrWildcard { count : OneOrGreater, value : Int })
withLetterValues setup counts =
    NonemptyDict.toNonemptyList counts
        |> List.Nonempty.foldl
            (\( letterOrWildcard, count ) result ->
                case result of
                    Ok list ->
                        case letterOrWildcard of
                            Letter (LetterChar char) ->
                                case String.toInt (String.trim (letterValueInputFor char setup)) of
                                    Just value ->
                                        Ok (( letterOrWildcard, { count = count, value = value } ) :: list)

                                    Nothing ->
                                        Err ("Letter values: enter a whole number for " ++ String.fromChar char)

                            Wildcard ->
                                Ok (( letterOrWildcard, { count = count, value = 0 } ) :: list)

                    Err error ->
                        Err error
            )
            (Ok [])
        |> Result.andThen
            (\list ->
                -- The fold prepends, so reverse to keep the distribution's original tile order
                -- (the bag is built and shuffled in this order, so it affects the drawn trays).
                case NonemptyDict.fromList (List.reverse list) of
                    Just nonempty ->
                        Ok nonempty

                    Nothing ->
                        Err "Letters: enter at least one letter"
            )


{-| The current text of a letter's value input, falling back to the letter's default value if the
user hasn't edited it.
-}
letterValueInputFor : Char -> SetupModel -> String
letterValueInputFor char setup =
    case SeqDict.get char setup.letterValues of
        Just input ->
            input

        Nothing ->
            String.fromInt (defaultLetterValue char)


parseTimeControl : SetupModel -> Result String TimeControl
parseTimeControl setup =
    case String.toFloat (String.trim setup.mainTimeInput) of
        Nothing ->
            Err "Main time: enter a number of minutes"

        Just minutes ->
            if minutes <= 0 then
                Err "Main time must be greater than 0"

            else
                case String.toFloat (String.trim setup.incrementInput) of
                    Nothing ->
                        Err "Increment: enter a number of seconds"

                    Just increment ->
                        if increment < 0 then
                            Err "Increment cannot be negative"

                        else
                            Ok { mainTime = Duration.minutes minutes, increment = Duration.seconds increment }


boardX : Coord CssPixels -> Int
boardX windowSize =
    if MyUi.isMobile { windowSize = windowSize } then
        0

    else
        MyUi.channelAndGuildColumnWidth windowSize


boardY : number
boardY =
    MyUi.channelHeaderHeight


trayX : Coord CssPixels -> Int
trayX =
    boardX


trayY : OneOrGreater -> Coord CssPixels -> Int
trayY traySize windowSize =
    boardY + boardWidth traySize windowSize


boardWidth : OneOrGreater -> Coord CssPixels -> Int
boardWidth traySize windowSize =
    cellSize traySize windowSize * gridSize


boardHeight : OneOrGreater -> Coord CssPixels -> Int
boardHeight traySize windowSize =
    boardWidth traySize windowSize + trayHeight traySize windowSize


insideBoard : ValidatedSetup -> Coord CssPixels -> Coord CssPixels -> Bool
insideBoard setup windowSize coord =
    let
        x =
            boardX windowSize
    in
    (Coord.xRaw coord > x)
        && (Coord.xRaw coord < (x + boardWidth setup.traySize windowSize))
        && (Coord.yRaw coord > boardY)
        && (Coord.yRaw coord < boardY + boardHeight setup.traySize windowSize)


{-| Which board cell (if any) a screen position is over.
-}
cellAtPosition : ValidatedSetup -> Coord CssPixels -> Coord CssPixels -> Maybe ( Int, Int )
cellAtPosition setup windowSize coord =
    let
        size : Int
        size =
            cellSize setup.traySize windowSize

        relX : Int
        relX =
            Coord.xRaw coord - boardX windowSize

        relY : Int
        relY =
            Coord.yRaw coord - boardY
    in
    if relX >= 0 && relY >= 0 && (relX // size) < gridSize && (relY // size) < gridSize then
        Just ( relX // size, relY // size )

    else
        Nothing


{-| How much the board is scaled up on mobile once the player has tiles placed on the board this
turn.
-}
boardZoomScale : Float
boardZoomScale =
    1.75


{-| How long, in milliseconds, the board takes to ease to a new zoom/translation.
-}
zoomAnimationDuration : Float
zoomAnimationDuration =
    250


{-| The zoom shown when nothing is placed: fully zoomed out, centred (the focus is irrelevant while
zoomed out, but a stable value keeps the ease-out from panning oddly).
-}
zoomedOutState : ZoomState
zoomedOutState =
    { amount = 0, focusX = 0.5, focusY = 0.5 }


{-| The zoom the board should settle on given the tiles currently placed: fully zoomed in and
centred on their centroid, or fully zoomed out when the board is empty.
-}
zoomTarget : GameData -> ZoomState
zoomTarget model =
    Array.toList model.tiles
        |> List.filterMap
            (\tile ->
                case tile.position of
                    TileOnBoard cell _ ->
                        Just cell

                    TileInTray _ _ ->
                        Nothing
            )
        |> zoomStateForCells


{-| The settled zoom for a board with these tiles placed on it: fully zoomed in and centred on their
centroid, or fully zoomed out when none are placed.
-}
zoomStateForCells : List ( Int, Int ) -> ZoomState
zoomStateForCells placed =
    case placed of
        [] ->
            zoomedOutState

        _ ->
            let
                count : Float
                count =
                    toFloat (List.length placed)

                focusFraction : Int -> Float
                focusFraction total =
                    (toFloat total / count + 0.5) / toFloat gridSize
            in
            { amount = 1
            , focusX = focusFraction (List.sum (List.map Tuple.first placed))
            , focusY = focusFraction (List.sum (List.map Tuple.second placed))
            }


{-| The zoom the board is showing right now: the stored `from` eased towards `zoomTarget` over
`zoomAnimationDuration`.
-}
animatedZoomState : Time.Posix -> GameData -> ZoomState
animatedZoomState time model =
    let
        from : ZoomState
        from =
            model.zoomAnimation.from

        target : ZoomState
        target =
            zoomTarget model

        eased : Float
        eased =
            easeOutCubic (clamp 0 1 (elapsedMs time model.zoomAnimation.start / zoomAnimationDuration))

        lerp : Float -> Float -> Float
        lerp a b =
            a + eased * (b - a)
    in
    { amount = lerp from.amount target.amount
    , focusX = lerp from.focusX target.focusX
    , focusY = lerp from.focusY target.focusY
    }


{-| Start a new zoom animation when a change to the placed tiles moves the zoom target, easing from
whatever the board is showing at `time` towards the new target. When the target is unchanged the
in-flight animation (if any) is left running.
-}
withZoomAnimation : Time.Posix -> GameData -> GameData -> GameData
withZoomAnimation time before after =
    if zoomTarget before == zoomTarget after then
        after

    else
        { after | zoomAnimation = { start = time, from = animatedZoomState time before } }


{-| Whether the mobile board zoom is mid-animation, so the view keeps redrawing each frame.
-}
isZoomAnimating : Time.Posix -> Coord CssPixels -> GameData -> Bool
isZoomAnimating time windowSize model =
    MyUi.isMobile { windowSize = windowSize }
        && (zoomTarget model /= model.zoomAnimation.from)
        && (elapsedMs time model.zoomAnimation.start < zoomAnimationDuration)


{-| On mobile the board is zoomed in and centred on the centroid of the placed tiles so the
surrounding cells are larger and easier to tap. The board's on-screen square stays the same size, so
the zoomed-in board is clipped to it. The centre is clamped so the visible window never runs off the
edge of the board (no blank space shows beyond the board), which means the centroid sits dead centre
only when it's far enough from every edge.

Returns the drawn (zoomed) cell size and the board-local translation that positions the zoomed grid
for the board's current (mid-animation) zoom, or `Nothing` when there's effectively no zoom (not on
mobile, or zoomed all the way out). Both `project` in `boardView` and `unprojectTouch` are defined in
terms of these two values, so the drawn board and the touch hit-testing always agree.

-}
boardZoom : Time.Posix -> OneOrGreater -> Coord CssPixels -> GameData -> Maybe { zoomedCellSize : Int, translate : Coord CssPixels }
boardZoom time traySize windowSize model =
    if MyUi.isMobile { windowSize = windowSize } then
        resolveZoom traySize windowSize (animatedZoomState time model)

    else
        Nothing


{-| Turn a `ZoomState` into the drawn cell size and board-local translation, or `Nothing` when it's
so close to zoomed out that it's indistinguishable from an unzoomed board (which also lets the grid
background stay cached instead of redrawing).
-}
resolveZoom : OneOrGreater -> Coord CssPixels -> ZoomState -> Maybe { zoomedCellSize : Int, translate : Coord CssPixels }
resolveZoom traySize windowSize zoomState =
    if zoomState.amount < 0.02 then
        Nothing

    else
        let
            size : Int
            size =
                cellSize traySize windowSize

            zc : Int
            zc =
                round ((1 + zoomState.amount * (boardZoomScale - 1)) * toFloat size)

            -- The effective scale is derived from the rounded cell size so that the drawn grid, the
            -- tiles and the touch hit-testing all line up exactly.
            effScale : Float
            effScale =
                toFloat zc / toFloat size

            boardPx : Int
            boardPx =
                gridSize * size

            -- The width/height, in unzoomed board pixels, of the region that stays visible.
            window : Float
            window =
                toFloat boardPx / effScale

            -- The board-local translation for one axis: centre the visible window on the focus, but
            -- clamp it so the window can't run past either edge of the board.
            axisTranslate : Float -> Int
            axisTranslate focusFraction =
                let
                    focusLocal : Float
                    focusLocal =
                        focusFraction * toFloat boardPx

                    left : Float
                    left =
                        clamp 0 (toFloat boardPx - window) (focusLocal - window / 2)
                in
                round (-effScale * left)
        in
        if zc == size then
            -- No visible zoom yet (the amount rounds away); treat it as unzoomed.
            Nothing

        else
            Just
                { zoomedCellSize = zc
                , translate = Coord.xy (axisTranslate zoomState.focusX) (axisTranslate zoomState.focusY)
                }


{-| Map a screen touch position back into the board's unzoomed coordinate space, so the existing
cell math (`cellAtPosition`) resolves it to the right cell even while the board is zoomed in. This is
the exact inverse of the `project` transform in `boardView`. Without zoom it's the identity.
-}
unprojectTouch : Time.Posix -> Coord CssPixels -> ValidatedSetup -> GameData -> Coord CssPixels -> Coord CssPixels
unprojectTouch time windowSize setup model coord =
    case boardZoom time setup.traySize windowSize model of
        Just { zoomedCellSize, translate } ->
            let
                effScale : Float
                effScale =
                    toFloat zoomedCellSize / toFloat (cellSize setup.traySize windowSize)

                unproject : Int -> Int -> Int -> Int
                unproject axis boardOrigin axisTranslate =
                    boardOrigin + round ((toFloat (axis - boardOrigin) - toFloat axisTranslate) / effScale)
            in
            Coord.xy
                (unproject (Coord.xRaw coord) (boardX windowSize) (Coord.xRaw translate))
                (unproject (Coord.yRaw coord) boardY (Coord.yRaw translate))

        Nothing ->
            coord


{-| Which board cell (if any) a screen touch is over, taking the mobile zoom into account. Only a
touch actually within the board's on-screen square counts; a touch over the tray (or anywhere else
outside the board) is `Nothing`. Without this guard the zoom un-projection could pull a touch just
below the board (e.g. dropping a tile back on the tray) up into the board's cell range.
-}
boardCellAtPosition : Time.Posix -> Coord CssPixels -> ValidatedSetup -> GameData -> Coord CssPixels -> Maybe ( Int, Int )
boardCellAtPosition time windowSize setup model coord =
    let
        relX : Int
        relX =
            Coord.xRaw coord - boardX windowSize

        relY : Int
        relY =
            Coord.yRaw coord - boardY

        width : Int
        width =
            boardWidth setup.traySize windowSize
    in
    if relX >= 0 && relX < width && relY >= 0 && relY < width then
        cellAtPosition setup windowSize (unprojectTouch time windowSize setup model coord)

    else
        Nothing


trayTileSize : OneOrGreater -> Coord CssPixels -> Float
trayTileSize traySize windowSize =
    let
        -- One slot per tray tile plus one more for the replace-tray button drawn next to the tray.
        slots : Float
        slots =
            toFloat (OneOrGreater.toInt traySize + 1)
    in
    min 50 ((toFloat (Coord.xRaw windowSize) - (trayTileSpacing * (slots - 1))) / slots)


trayTileSpacing : number
trayTileSpacing =
    4


trayTilePos : OneOrGreater -> Coord CssPixels -> TrayIndex -> Coord CssPixels
trayTilePos traySize windowSize (TrayIndex index) =
    Coord.xy
        (boardX windowSize + round (toFloat index * (trayTileSize traySize windowSize + trayTileSpacing)))
        (trayY traySize windowSize)


{-| The screen coordinate at the centre of a tray slot, used by end-to-end tests to touch a tile.
-}
trayTouchCoord : OneOrGreater -> Coord CssPixels -> Int -> Coord CssPixels
trayTouchCoord traySize windowSize slot =
    let
        pos : Coord CssPixels
        pos =
            trayTilePos traySize windowSize (TrayIndex slot)

        half : Int
        half =
            round (trayTileSize traySize windowSize) // 2
    in
    Coord.xy (Coord.xRaw pos + half) (Coord.yRaw pos + half)


{-| The screen coordinate to touch to drop a tile on board cell `( tx, ty )`, given the tiles the
current player has already placed this turn (which is what the mobile zoom centres on). Used by
end-to-end tests, this is the forward of the `unprojectTouch` hit-test: touching here resolves back
to `( tx, ty )`. The zoom is taken as settled (as it is a frame after the previous drop).
-}
boardTouchCoord : OneOrGreater -> Coord CssPixels -> List ( Int, Int ) -> ( Int, Int ) -> Coord CssPixels
boardTouchCoord traySize windowSize placedCells ( tx, ty ) =
    let
        size : Int
        size =
            cellSize traySize windowSize
    in
    case resolveZoom traySize windowSize (zoomStateForCells placedCells) of
        Just { zoomedCellSize, translate } ->
            let
                effScale : Float
                effScale =
                    toFloat zoomedCellSize / toFloat size

                project : Int -> Int -> Int -> Int
                project cell boardOrigin axisTranslate =
                    boardOrigin + axisTranslate + round (effScale * (toFloat (cell * size) + toFloat size / 2))
            in
            Coord.xy
                (project tx (boardX windowSize) (Coord.xRaw translate))
                (project ty boardY (Coord.yRaw translate))

        Nothing ->
            Coord.xy
                (boardX windowSize + tx * size + size // 2)
                (boardY + ty * size + size // 2)


{-| Where a tray tile is currently drawn. While a shift animation is in progress the tile eases
from the slot it was shifted out of toward its current slot; otherwise it sits at its current slot.
-}
animatedTrayTilePos : ValidatedSetup -> Coord CssPixels -> Time.Posix -> TrayIndex -> Maybe ( Time.Posix, Int ) -> Coord CssPixels
animatedTrayTilePos setup windowSize currentTime trayIndex shiftAnimation =
    let
        dest : Coord CssPixels
        dest =
            trayTilePos setup.traySize windowSize trayIndex
    in
    case shiftAnimation of
        Just ( startTime, fromSlot ) ->
            let
                eased : Float
                eased =
                    clamp 0 1 (elapsedMs currentTime startTime / trayShiftDuration)

                from : Coord CssPixels
                from =
                    trayTilePos setup.traySize windowSize (TrayIndex fromSlot)

                lerp : Int -> Int -> Int
                lerp a b =
                    round (toFloat a + eased * toFloat (b - a))
            in
            Coord.xy
                (lerp (Coord.xRaw from) (Coord.xRaw dest))
                (lerp (Coord.yRaw from) (Coord.yRaw dest))

        Nothing ->
            dest


{-| Which tray slot (if any) a screen position is over.
-}
trayIndexAtPosition : ValidatedSetup -> Coord CssPixels -> Coord CssPixels -> Int -> Maybe Int
trayIndexAtPosition setup windowSize coord trayLength =
    let
        relX : Int
        relX =
            Coord.xRaw coord - trayX windowSize

        relY : Int
        relY =
            Coord.yRaw coord - trayY setup.traySize windowSize

        index =
            toFloat relX / (trayTileSize setup.traySize windowSize + trayTileSpacing) |> floor
    in
    if relX >= 0 && relY >= 0 && relY < trayHeight setup.traySize windowSize && index < trayLength then
        Just index

    else
        Nothing


getPlayer : Id UserId -> Shared -> Maybe Player
getPlayer userId gameState =
    List.Extra.find (\player -> player.userId == userId) (List.Nonempty.toList gameState.players)


dragStart : Time.Posix -> Coord CssPixels -> NonemptyDict Int Touch -> ValidatedSetup -> GameData -> GameData
dragStart time windowSize touches setup gameModel =
    let
        touchPosition : Coord CssPixels
        touchPosition =
            Touch.touchCentroid touches

        trayList =
            Array.toList gameModel.tiles
    in
    case boardCellAtPosition time windowSize setup gameModel touchPosition of
        Just cell ->
            case
                List.Extra.findIndex
                    (\tile ->
                        case tile.position of
                            TileOnBoard boardPosition _ ->
                                boardPosition == cell

                            TileInTray _ _ ->
                                False
                    )
                    trayList
            of
                Just tileIndex ->
                    { gameModel | dragging = Dragging tileIndex }

                Nothing ->
                    gameModel

        Nothing ->
            case trayIndexAtPosition setup windowSize touchPosition (OneOrGreater.toInt setup.traySize) of
                Just index ->
                    case
                        List.Extra.findIndex
                            (\tile ->
                                case tile.position of
                                    TileOnBoard _ _ ->
                                        False

                                    TileInTray trayIndex _ ->
                                        trayIndex == TrayIndex index
                            )
                            trayList
                    of
                        Just tileIndex ->
                            { gameModel | dragging = Dragging tileIndex }

                        Nothing ->
                            gameModel

                Nothing ->
                    gameModel


dragEnd : Time.Posix -> Coord CssPixels -> NonemptyDict Int Touch -> ValidatedSetup -> Shared -> GameData -> GameData
dragEnd currentTime windowSize newTouches setup shared model =
    (case model.dragging of
        Dragging tileIndex ->
            let
                position : Coord CssPixels
                position =
                    Touch.touchCentroid newTouches

                returnToTray : GameData
                returnToTray =
                    if distanceToTray setup windowSize position (Array.length model.tiles) <= maxTraySnapDistance then
                        insertIntoTray currentTime windowSize tileIndex position setup model

                    else
                        { model
                            | dragging = NotDragging
                            , tiles =
                                Array.Extra.update
                                    tileIndex
                                    (\tile -> { tile | position = TileInTray (firstOpenTrayIndex (Just tileIndex) model.tiles) Nothing })
                                    model.tiles
                        }
            in
            case boardCellAtPosition currentTime windowSize setup model position of
                Just cell ->
                    if SeqDict.member cell shared.board || cellOccupiedByOtherTile tileIndex cell model.tiles then
                        returnToTray

                    else
                        { model
                            | dragging = NotDragging
                            , tiles =
                                Array.Extra.update
                                    tileIndex
                                    (\tile -> { tile | position = TileOnBoard cell currentTime })
                                    model.tiles
                        }

                Nothing ->
                    returnToTray

        NotDragging ->
            model
    )
        |> withZoomAnimation currentTime model


{-| The tray slots currently occupied by tiles resting in the tray (board tiles don't count).
-}
trayIndicesInUse : Array Tile -> Set Int
trayIndicesInUse tiles =
    Array.foldl
        (\tile set ->
            case tile.position of
                TileInTray (TrayIndex index) _ ->
                    Set.insert index set

                TileOnBoard _ _ ->
                    set
        )
        Set.empty
        tiles


{-| The lowest tray index at or above `n` that isn't in `taken`.
-}
lowestFreeTrayIndex : Int -> Set Int -> Int
lowestFreeTrayIndex n taken =
    if Set.member n taken then
        lowestFreeTrayIndex (n + 1) taken

    else
        n


{-| The lowest tray slot not occupied by another tile, used when a dragged tile is returned to
the tray.
-}
firstOpenTrayIndex : Maybe Int -> Array Tile -> TrayIndex
firstOpenTrayIndex draggedIndex tiles =
    let
        occupied : List Int
        occupied =
            Array.toIndexedList tiles
                |> List.filterMap
                    (\( index, tile ) ->
                        if Just index == draggedIndex then
                            Nothing

                        else
                            case tile.position of
                                TileInTray (TrayIndex trayIndex) _ ->
                                    Just trayIndex

                                TileOnBoard _ _ ->
                                    Nothing
                    )

        find : Int -> Int
        find n =
            if List.member n occupied then
                find (n + 1)

            else
                n
    in
    TrayIndex (find 0)


cellOccupiedByOtherTile : Int -> ( Int, Int ) -> Array Tile -> Bool
cellOccupiedByOtherTile draggedIndex cell tiles =
    Array.toIndexedList tiles
        |> List.any
            (\( index, tile ) ->
                case tile.position of
                    TileOnBoard pos _ ->
                        (index /= draggedIndex) && pos == cell

                    TileInTray _ _ ->
                        False
            )


{-| How close (in CSS pixels) the cursor has to be to the tray for a dropped tile to snap into it
rather than fall back to the first open slot.
-}
maxTraySnapDistance : number
maxTraySnapDistance =
    100


{-| The distance (in CSS pixels) from a screen position to the nearest edge of the tray rectangle,
or 0 when the position is inside it.
-}
distanceToTray : ValidatedSetup -> Coord CssPixels -> Coord CssPixels -> Int -> Float
distanceToTray setup windowSize coord slotCount =
    let
        left : Int
        left =
            trayX windowSize

        right : Int
        right =
            left + round (toFloat slotCount * trayTileSize setup.traySize windowSize) + (slotCount - 1) * trayTileSpacing

        top : Int
        top =
            trayY setup.traySize windowSize

        bottom : Int
        bottom =
            top + trayHeight setup.traySize windowSize

        dx : Int
        dx =
            max 0 (max (left - Coord.xRaw coord) (Coord.xRaw coord - right))

        dy : Int
        dy =
            max 0 (max (top - Coord.yRaw coord) (Coord.yRaw coord - bottom))
    in
    sqrt (toFloat (dx * dx + dy * dy))


{-| The tray slot a dropped tile lands in, given the tray tile size, the tray's left edge, the
dropped tile's centre x (the tile is drawn centred on the cursor while dragging) and the number of
slots.

We snap to the slot whose centre is nearest the cursor. Subtracting half a tile is what lines the
cursor up with slot _centres_ rather than slot _left edges_: without it a tile dropped anywhere right
of a slot's centre snaps a whole slot too far to the right.

-}
trayDropSlot : Float -> Int -> Int -> Int -> Int
trayDropSlot tileSize trayLeft centerX slotCount =
    (toFloat (centerX - trayLeft) - tileSize / 2)
        / (tileSize + trayTileSpacing)
        |> round
        |> clamp 0 (slotCount - 1)


{-| Drop the dragged tile into the tray slot nearest the cursor, shifting the tiles between that
slot and the nearest empty slot over by one to make room.
-}
insertIntoTray : Time.Posix -> Coord CssPixels -> Int -> Coord CssPixels -> ValidatedSetup -> GameData -> GameData
insertIntoTray currentTime windowSize tileIndex position setup gameModel =
    let
        slotCount : Int
        slotCount =
            Array.length gameModel.tiles

        target : Int
        target =
            trayDropSlot (trayTileSize setup.traySize windowSize) (trayX windowSize) (Coord.xRaw position) slotCount

        occupied : Set Int
        occupied =
            Array.toIndexedList gameModel.tiles
                |> List.filterMap
                    (\( index, tile ) ->
                        if index == tileIndex then
                            Nothing

                        else
                            case tile.position of
                                TileInTray (TrayIndex slot) _ ->
                                    Just slot

                                TileOnBoard _ _ ->
                                    Nothing
                    )
                |> Set.fromList

        rightFree : Maybe Int
        rightFree =
            List.range (target + 1) (slotCount - 1)
                |> List.filter (\slot -> not (Set.member slot occupied))
                |> List.head

        leftFree : Maybe Int
        leftFree =
            List.range 0 (target - 1)
                |> List.filter (\slot -> not (Set.member slot occupied))
                |> List.maximum

        shiftRight : Int -> Int -> Int
        shiftRight free slot =
            if slot >= target && slot < free then
                slot + 1

            else
                slot

        shiftLeft : Int -> Int -> Int
        shiftLeft free slot =
            if slot > free && slot <= target then
                slot - 1

            else
                slot

        slotMapping : Int -> Int
        slotMapping =
            if not (Set.member target occupied) then
                identity

            else
                case ( leftFree, rightFree ) of
                    ( Just l, Just r ) ->
                        if target - l <= r - target then
                            shiftLeft l

                        else
                            shiftRight r

                    ( Just l, Nothing ) ->
                        shiftLeft l

                    ( Nothing, Just r ) ->
                        shiftRight r

                    ( Nothing, Nothing ) ->
                        identity
    in
    { gameModel
        | dragging = NotDragging
        , tiles =
            Array.indexedMap
                (\index tile ->
                    if index == tileIndex then
                        -- The dropped tile appears straight at its slot (it was following the
                        -- cursor, so there's no old tray slot to slide from).
                        { tile | position = TileInTray (TrayIndex target) Nothing }

                    else
                        case tile.position of
                            TileInTray (TrayIndex slot) _ ->
                                let
                                    newSlot : Int
                                    newSlot =
                                        slotMapping slot
                                in
                                if newSlot == slot then
                                    tile

                                else
                                    { tile | position = TileInTray (TrayIndex newSlot) (Just ( currentTime, slot )) }

                            TileOnBoard _ _ ->
                                tile
                )
                gameModel.tiles
    }


type UserStatus
    = NotJoined
    | Joined
    | JoinedAndItsTheirTurn


isPlayerTurn : Id UserId -> Shared -> UserStatus
isPlayerTurn userId shared =
    case List.Extra.findIndex (\player -> player.userId == userId) (List.Nonempty.toList shared.players) of
        Just index ->
            if index == modBy (List.Nonempty.length shared.players) shared.turnCount then
                JoinedAndItsTheirTurn

            else
                Joined

        Nothing ->
            NotJoined


tileSlideDuration : Duration
tileSlideDuration =
    Duration.milliseconds 250


tileSlideStagger : Duration
tileSlideStagger =
    Duration.milliseconds 80


{-| How long, in milliseconds, rejected tiles sit on the board (turned red) before sliding back
off again.
-}
invalidHoldDuration : Duration
invalidHoldDuration =
    Duration.milliseconds 2000


tileFadeDelay : Duration
tileFadeDelay =
    Duration.milliseconds 1000


{-| How long, in milliseconds, the fade-and-drift into place itself takes, once it starts.
-}
tileFadeDuration : Float
tileFadeDuration =
    100


{-| How far, as a fraction of a tile's size, a new tile starts above its final spot before it
descends into place.
-}
tileFadeDrift : Float
tileFadeDrift =
    0.2


{-| How long, in milliseconds, a tray tile takes to slide from its old slot to its new one when
another tile is inserted next to it.
-}
trayShiftDuration : Float
trayShiftDuration =
    200


{-| Whether a tile is still within its fade-in window, so the view keeps redrawing each animation
frame until it has settled.
-}
isTileFading : Time.Posix -> Time.Posix -> Bool
isTileFading currentTime createdAt =
    elapsedMs currentTime createdAt < Duration.inMilliseconds tileFadeDelay + tileFadeDuration


{-| Whether a tray tile is partway through sliding from an old slot to a new one.
-}
isTileShifting : Time.Posix -> Tile -> Bool
isTileShifting currentTime tile =
    case tile.position of
        TileInTray _ (Just ( startTime, _ )) ->
            elapsedMs currentTime startTime < trayShiftDuration

        _ ->
            False


elapsedMs : Time.Posix -> Time.Posix -> Float
elapsedMs currentTime startTime =
    toFloat (Time.posixToMillis currentTime - Time.posixToMillis startTime)


{-| The moment, in milliseconds since the placement started, at which the last tile has finished
sliding in.
-}
slideInEnd : Int -> Duration
slideInEnd tileCount =
    Quantity.multiplyBy (toFloat (max 0 (tileCount - 1))) (Quantity.plus tileSlideStagger tileSlideDuration)


{-| The total length of a placement's animation. A valid placement just slides in; a rejected one
also holds and then slides back off.
-}
placementAnimationDuration : ToBeFilledInByBackend IsValid -> Int -> Duration
placementAnimationDuration isValid tileCount =
    case isValid of
        FilledInByBackend IsNotValid ->
            Quantity.sum [ slideInEnd tileCount, invalidHoldDuration, slideInEnd tileCount ]

        _ ->
            slideInEnd tileCount


{-| Whether a placement animation is currently in progress, so the view should keep redrawing
each animation frame.
-}
isAnimating : Time.Posix -> Shared -> Bool
isAnimating currentTime shared =
    case shared.lastPlacement of
        Just placement ->
            elapsedMs currentTime placement.startTime
                < Duration.inMilliseconds (placementAnimationDuration placement.isValid (List.length placement.cells))

        Nothing ->
            False


{-| Whether any tile is still fading in, so the view should keep redrawing each animation frame.
-}
anyTileAnimating : Time.Posix -> GameData -> Bool
anyTileAnimating currentTime model =
    Array.Extra.any (\tile -> isTileFading currentTime tile.createdAt || isTileShifting currentTime tile) model.tiles


{-| The opacity and downward drift of a tile as it fades into place. It stays hidden for
`tileFadeDelay` after being created, then quickly fades and drifts down over `tileFadeDuration`.
`opacity` runs 0 to 1; `drift` is the fraction of a tile's size the tile still sits above its final
spot (1 before/at the start of the fade, easing to 0 once settled).
-}
tileFade : Time.Posix -> Time.Posix -> { opacity : Float, drift : Float }
tileFade currentTime createdAt =
    let
        progress : Float
        progress =
            clamp 0 1 ((elapsedMs currentTime createdAt - Duration.inMilliseconds tileFadeDelay) / tileFadeDuration)
    in
    { opacity = progress, drift = 1 - easeOutCubic progress }


easeOutCubic : Float -> Float
easeOutCubic t =
    let
        clamped : Float
        clamped =
            clamp 0 1 t
    in
    1 - (1 - clamped) ^ 3


{-| Where one placed tile is in its animation, given the time elapsed since the placement, the
total number of tiles (for the staggering) and the tile's index. `progress` is 0 when the tile is
at the board's top-left corner and 1 when it's resting on its destination cell; `red` is set once
a rejected tile has landed and is on its way back off. `Nothing` means the tile shouldn't be drawn
(a rejected tile that has finished leaving).
-}
animatedTilePlacement : Bool -> Float -> ToBeFilledInByBackend IsValid -> Int -> Int -> Maybe { progress : Float, red : Bool }
animatedTilePlacement isPlayerWhoPlacedTiles elapsed isValid tileCount index =
    let
        launch : Float
        launch =
            toFloat index * Duration.inMilliseconds tileSlideStagger

        slideEnd : Float
        slideEnd =
            launch + Duration.inMilliseconds tileSlideDuration

        slideInProgress : Float
        slideInProgress =
            if isPlayerWhoPlacedTiles then
                1

            else if elapsed < launch then
                0

            else
                easeOutCubic ((elapsed - launch) / Duration.inMilliseconds tileSlideDuration)
    in
    case isValid of
        FilledInByBackend IsNotValid ->
            let
                leaveStart : Float
                leaveStart =
                    Quantity.sum
                        [ invalidHoldDuration
                        , Quantity.multiplyBy (toFloat index) tileSlideStagger
                        , slideInEnd tileCount
                        ]
                        |> Duration.inMilliseconds

                leaveEnd : Float
                leaveEnd =
                    leaveStart + Duration.inMilliseconds tileSlideDuration
            in
            if elapsed < slideEnd then
                Just { progress = slideInProgress, red = False }

            else if elapsed < (leaveStart + slideEnd) * 0.5 then
                Just { progress = 1, red = False }

            else if elapsed < leaveStart then
                Just { progress = 1, red = True }

            else if elapsed < leaveEnd then
                Just
                    { progress = 1 - easeOutCubic ((elapsed - leaveStart) / Duration.inMilliseconds tileSlideDuration)
                    , red = True
                    }

            else
                Nothing

        _ ->
            Just { progress = slideInProgress, red = False }


{-| The board cells currently being drawn by the placement animation, which are therefore left out
of the ordinary committed-tile rendering to avoid drawing them twice.
-}
animatingCells : Time.Posix -> Shared -> Set ( Int, Int )
animatingCells currentTime shared =
    case shared.lastPlacement of
        Just placement ->
            if isAnimating currentTime shared then
                List.map Tuple.first placement.cells |> Set.fromList

            else
                Set.empty

        Nothing ->
            Set.empty


type PassBehavior
    = ShouldReplaceTray
    | ShouldPass
    | ShouldEndGame


passBehavior : ValidatedSetup -> Shared -> PassBehavior
passBehavior setup shared =
    if remainingLettersInBag setup shared.board (List.Nonempty.toList shared.players) == SeqDict.empty then
        case shared.passingStartedAt of
            Just passingStartedAt ->
                if List.Nonempty.length shared.players > shared.turnCount + 1 - passingStartedAt then
                    ShouldPass

                else
                    ShouldEndGame

            Nothing ->
                ShouldPass

    else
        ShouldReplaceTray


gameView :
    Time.Posix
    -> Coord CssPixels
    -> Maybe (NonemptyDict Int Touch)
    -> Bool
    -> LocalUser
    -> ValidatedSetup
    -> Array ActionWithTime
    -> Shared
    -> GameData
    -> Element GameMsg
gameView currentTime windowSize maybeDragging isPersonalDm localUser setup actions shared model =
    let
        isMobile =
            MyUi.isMobile { windowSize = windowSize }
    in
    (if isMobile then
        Ui.column

     else
        Ui.row
    )
        [ Ui.height (Ui.px (tabBodyHeight windowSize setup.traySize))
        , Ui.background MyUi.tabBackground
        , Ui.borderWith { left = 0, right = 0, top = 0, bottom = 1 }
        , Ui.borderColor MyUi.border2
        , MyUi.noShrinking
        , MyUi.htmlStyle "user-select" "none"
        ]
        [ boardView currentTime windowSize maybeDragging localUser.session.userId setup shared model
        , statusView windowSize isPersonalDm localUser setup actions shared
        ]


playerRow : LocalUser -> Id UserId -> Bool -> String -> Element GameMsg
playerRow localUser userId highlight suffix =
    let
        maybeUser : Maybe User.FrontendUser
        maybeUser =
            User.getUser userId localUser
    in
    Ui.row
        [ Ui.spacing 8
        , Ui.width Ui.shrink
        , if highlight then
            Ui.background MyUi.mentionColor

          else
            Ui.noAttr
        , Ui.paddingWith { left = 4, top = 4, bottom = 4, right = 8 }
        ]
        [ User.profileImage userId (Maybe.andThen .icon maybeUser)
        , Ui.row
            [ MyUi.prewrap ]
            [ Ui.el
                [ Ui.Font.bold ]
                (Ui.text
                    (case maybeUser of
                        Just user ->
                            PersonName.toString user.name

                        Nothing ->
                            "Unknown"
                    )
                )
            , Ui.text suffix
            ]
        ]


leaderboardView : Bool -> Nonempty (Id UserId) -> Shared -> LocalUser -> Element GameMsg
leaderboardView isMobile winners shared localUser =
    let
        isTie : Bool
        isTie =
            List.Nonempty.length winners > 1

        sortedPlayers : List Player
        sortedPlayers =
            List.Nonempty.toList shared.players
                |> List.sortBy (\player -> negate player.score)
    in
    Ui.column
        [ Ui.height (Ui.px statusHeight), Ui.paddingXY 16 0 ]
        (Ui.el
            [ Ui.Font.bold, Ui.paddingXY 0 4 ]
            (Ui.text
                (if isTie then
                    "Game over — it's a tie!"

                 else
                    "Game over"
                )
            )
            :: List.filterMap
                (\player ->
                    let
                        isWinner : Bool
                        isWinner =
                            List.Nonempty.member player.userId winners
                    in
                    if isMobile && not isWinner then
                        Nothing

                    else
                        playerRow
                            localUser
                            player.userId
                            isWinner
                            (": "
                                ++ String.fromInt player.score
                                ++ (if isWinner then
                                        if isTie then
                                            " (tied for first)"

                                        else
                                            " (winner)"

                                    else
                                        ""
                                   )
                            )
                            |> Just
                )
                sortedPlayers
        )


statusView : Coord CssPixels -> Bool -> LocalUser -> ValidatedSetup -> Array ActionWithTime -> Shared -> Element GameMsg
statusView windowSize isPersonalDm localUser setup actions shared =
    let
        currentPlayer : Player
        currentPlayer =
            List.Nonempty.get shared.turnCount shared.players

        nextPlayer : Player
        nextPlayer =
            List.Nonempty.get (shared.turnCount + 1) shared.players

        playerCount =
            List.Nonempty.length shared.players

        isMobile =
            MyUi.isMobile { windowSize = windowSize }

        -- A solo game (nobody else has joined) stops accepting new players once its creator plays a
        -- second move, because `canJoin` only holds while `turnCount <= playerCount`. Warn the lone
        -- player before that second move so they know they're about to lock everyone else out. There's
        -- no one to lock out in a personal DM (the player is talking to themselves), so skip it there.
        soloJoinWarning : Bool
        soloJoinWarning =
            not isPersonalDm
                && (playerCount == 1)
                && (shared.turnCount == 1)
                && (isPlayerTurn localUser.session.userId shared == JoinedAndItsTheirTurn)

        joinWarning : Element GameMsg
        joinWarning =
            if soloJoinWarning then
                Ui.el
                    [ Ui.Font.color MyUi.errorColor, MyUi.prewrap ]
                    (Ui.text "No one else has joined yet.\nOnce you make a second move no one can join.")

            else
                Ui.none
    in
    case getWinner shared of
        Just winners ->
            leaderboardView isMobile winners shared localUser

        Nothing ->
            let
                contextButton : Element GameMsg
                contextButton =
                    case isPlayerTurn localUser.session.userId shared of
                        JoinedAndItsTheirTurn ->
                            -- The player replaces their tray with the delete button next to the
                            -- tray (see `boardView`). When no letters are left to draw, replacing
                            -- isn't possible, so instead offer to pass the turn or end the game.
                            case passBehavior setup shared of
                                ShouldReplaceTray ->
                                    Ui.none

                                ShouldPass ->
                                    MyUi.simpleButton (Dom.id "wordSpellingGame_passOrEndTurn") PressedReplaceTrayOrPass (Ui.text "Pass turn")

                                ShouldEndGame ->
                                    MyUi.simpleButton (Dom.id "wordSpellingGame_passOrEndTurn") PressedReplaceTrayOrPass (Ui.text "End game")

                        Joined ->
                            Ui.none

                        NotJoined ->
                            if canJoin shared then
                                MyUi.simpleButton (Dom.id "wordSpellingGame_joinGame") PressedJoinGame (Ui.text "Join game")

                            else
                                Ui.none
            in
            if isMobile then
                Ui.row
                    [ Ui.spacing 8, Ui.height (Ui.px statusHeight), MyUi.prewrap ]
                    [ Ui.column
                        [ Ui.centerY ]
                        [ case User.getUser currentPlayer.userId localUser of
                            Just user ->
                                Ui.row
                                    [ Ui.width Ui.shrink, Ui.paddingXY 8 2, Ui.background MyUi.mentionColor ]
                                    [ Ui.el [ Ui.Font.bold ] (Ui.text (PersonName.toString user.name))
                                    , Ui.text ("'s turn (" ++ String.fromInt currentPlayer.score ++ ")")
                                    ]

                            Nothing ->
                                Ui.none
                        , case User.getUser nextPlayer.userId localUser of
                            Just user ->
                                Ui.row
                                    [ Ui.width Ui.shrink, Ui.paddingXY 8 2 ]
                                    [ Ui.el [ Ui.Font.bold ] (Ui.text (PersonName.toString user.name))
                                    , Ui.text (" is next (" ++ String.fromInt nextPlayer.score ++ ")")
                                    ]

                            Nothing ->
                                Ui.none
                        , joinWarning
                        ]
                    , contextButton
                    ]

            else
                Ui.column
                    [ Ui.spacing 8, Ui.paddingXY 16 0 ]
                    [ Ui.column
                        []
                        (("Letters remaining: "
                            ++ String.fromInt (remainingLettersInBagCount setup shared.board (List.Nonempty.toList shared.players))
                            |> Ui.text
                            |> Ui.el [ Ui.paddingXY 0 4 ]
                         )
                            :: List.indexedMap
                                (\index player ->
                                    playerRow
                                        localUser
                                        player.userId
                                        (index == modBy playerCount shared.turnCount)
                                        (if index == modBy playerCount shared.turnCount then
                                            "'s turn (" ++ String.fromInt player.score ++ ")"

                                         else if index == modBy playerCount (shared.turnCount + 1) then
                                            " is next (" ++ String.fromInt player.score ++ ")"

                                         else
                                            " (" ++ String.fromInt player.score ++ ")"
                                        )
                                )
                                (List.Nonempty.toList shared.players)
                        )
                    , Ui.Lazy.lazy3 recentActionsView localUser setup actions
                    , joinWarning
                    , contextButton
                    ]


{-| The most recent couple of actions, shown beneath the player list on non-mobile so it's easy to
see what just happened (who played which word for how many points, who passed, and so on).
-}
recentActionsView : LocalUser -> ValidatedSetup -> Array ActionWithTime -> Element GameMsg
recentActionsView localUser setup actions =
    let
        log : List { userId : Id UserId, description : String }
        log =
            actionLog setup actions
    in
    case List.drop (max 0 (List.length log - 4)) log of
        [] ->
            Ui.none

        recent ->
            Ui.el [ Ui.Font.color MyUi.font3, Ui.Font.size 14 ] (Ui.text "Recent moves")
                :: List.map
                    (\entry ->
                        let
                            name : String
                            name =
                                case User.getUser entry.userId localUser of
                                    Just user ->
                                        PersonName.toString user.name

                                    Nothing ->
                                        "Someone"
                        in
                        Ui.row
                            [ MyUi.prewrap, Ui.width Ui.shrink, Ui.Font.color MyUi.font3 ]
                            [ Ui.el [ Ui.Font.bold ] (Ui.text name)
                            , Ui.text (" " ++ entry.description)
                            ]
                    )
                    (List.reverse recent)
                |> Ui.column [ Ui.spacing 4 ]


{-| Replay the whole action list from the start (the same fold `updateAction` builds the live board
from), pairing each action with a short human-readable description. Word text and score are worked
out from the board as it stood just before the action, which is why the running `Shared` state is
carried through the fold.
-}
actionLog : ValidatedSetup -> Array ActionWithTime -> List { userId : Id UserId, description : String }
actionLog setup actions =
    Array.foldl
        (\action ( shared, acc ) ->
            ( updateAction setup action shared
            , { userId = action.userId, description = describeAction setup shared action } :: acc
            )
        )
        ( initShared setup, [] )
        actions
        |> Tuple.second
        |> List.reverse


{-| A short description of a single action, phrased to read after the player's name (e.g.
"played CAT (+5)"). Uses the board state from just before the action to recover the word and score.
-}
describeAction : ValidatedSetup -> Shared -> ActionWithTime -> String
describeAction setup shared action =
    case action.change of
        PlaceWord placedWord isValid ->
            case isValid of
                FilledInByBackend IsNotValid ->
                    "played an invalid word"

                _ ->
                    case placeWord setup shared.board placedWord of
                        Just result ->
                            let
                                bonus : Int
                                bonus =
                                    fullTrayBonusScore setup placedWord
                            in
                            "played "
                                ++ headlineWord result.words
                                ++ " (+"
                                ++ String.fromInt (result.score + bonus)
                                ++ (if bonus == 0 then
                                        ""

                                    else
                                        ", bingo!"
                                   )
                                ++ ")"

                        Nothing ->
                            "played a word"

        ReplaceTrayOrPass ->
            case passBehavior setup shared of
                ShouldReplaceTray ->
                    "swapped their tiles"

                ShouldPass ->
                    "passed"

                ShouldEndGame ->
                    "ended the game"

        JoinGame ->
            "joined the game"


{-| The longest of the words a placement formed, rendered as uppercase text, used as the headline
word in an action description.
-}
headlineWord : List (List LetterOrWildcard) -> String
headlineWord words =
    words
        |> List.sortBy (\word -> negate (List.length word))
        |> List.head
        |> Maybe.map letterOrWildcardsToString
        |> Maybe.withDefault "a word"


{-| Render placed tiles as uppercase text, showing a wildcard as an underscore since the board
doesn't record which letter it stands for.
-}
letterOrWildcardsToString : List LetterOrWildcard -> String
letterOrWildcardsToString letters =
    List.map
        (\letterOrWildcard ->
            case letterOrWildcard of
                Letter (LetterChar letter) ->
                    String.fromChar letter

                Wildcard ->
                    "_"
        )
        letters
        |> String.concat


trayHeight : OneOrGreater -> Coord CssPixels -> Int
trayHeight traySize windowSize =
    trayTileSize traySize windowSize |> round


boardView :
    Time.Posix
    -> Coord CssPixels
    -> Maybe (NonemptyDict Int Touch)
    -> Id UserId
    -> ValidatedSetup
    -> Shared
    -> GameData
    -> Element GameMsg
boardView currentTime windowSize maybeDragging currentUserId setup shared model =
    let
        cellSize2 : Int
        cellSize2 =
            cellSize setup.traySize windowSize

        zoom : Maybe { zoomedCellSize : Int, translate : Coord CssPixels }
        zoom =
            boardZoom currentTime setup.traySize windowSize model

        -- The zoomed-in cell size, i.e. how big a board cell is drawn once the mobile zoom is
        -- applied (the same as `cellSize2` when there's no zoom).
        zoomedCellSize : Int
        zoomedCellSize =
            case zoom of
                Just z ->
                    z.zoomedCellSize

                Nothing ->
                    cellSize2

        -- How far the zoomed board content is shifted (in board-local coordinates) so the visible
        -- window is centred on the centroid of the placed tiles (clamped to the board edges).
        boardTranslate : Coord CssPixels
        boardTranslate =
            case zoom of
                Just z ->
                    z.translate

                Nothing ->
                    Coord.origin

        -- A board cell's top-left position (in board-local coordinates, relative to the board's
        -- top-left corner) and drawn size, with the mobile zoom applied.
        project : Int -> Int -> { pos : Coord CssPixels, size : Int }
        project x y =
            { pos =
                Coord.xy
                    (Coord.xRaw boardTranslate + zoomedCellSize * x)
                    (Coord.yRaw boardTranslate + zoomedCellSize * y)
            , size = zoomedCellSize
            }

        animatingCellSet : Set ( Int, Int )
        animatingCellSet =
            animatingCells currentTime shared

        boardTiles : List (Ui.Attribute GameMsg)
        boardTiles =
            SeqDict.foldl
                (\( x, y ) letter list ->
                    if Set.member ( x, y ) animatingCellSet then
                        -- This tile is being animated into place, so the animation layer draws it.
                        list

                    else
                        let
                            p : { pos : Coord CssPixels, size : Int }
                            p =
                                project x y
                        in
                        boardTileInFront setup p.size p.pos letter :: list
                )
                []
                shared.board

        isPreviousPlayer : Bool
        isPreviousPlayer =
            List.Nonempty.get (shared.turnCount - 1) shared.players |> .userId |> (==) currentUserId

        animatedTiles : List (Ui.Attribute GameMsg)
        animatedTiles =
            case shared.lastPlacement of
                Just placement ->
                    if isAnimating currentTime shared then
                        let
                            elapsed : Float
                            elapsed =
                                elapsedMs currentTime placement.startTime

                            tileCount : Int
                            tileCount =
                                List.length placement.cells
                        in
                        List.indexedMap
                            (\index ( ( x, y ), letterOrWildcard ) ->
                                case animatedTilePlacement isPreviousPlayer elapsed placement.isValid tileCount index of
                                    Just { progress, red } ->
                                        let
                                            p : { pos : Coord CssPixels, size : Int }
                                            p =
                                                project x y

                                            startX : Int
                                            startX =
                                                if red && isPreviousPlayer then
                                                    -p.size + (cellSize2 * gridSize) // 2

                                                else
                                                    -p.size

                                            startY : Int
                                            startY =
                                                if red && isPreviousPlayer then
                                                    cellSize2 * gridSize

                                                else
                                                    -p.size

                                            destX : Int
                                            destX =
                                                Coord.xRaw p.pos

                                            destY : Int
                                            destY =
                                                Coord.yRaw p.pos
                                        in
                                        animatedTileInFront
                                            setup
                                            p.size
                                            (Coord.xy
                                                (round (toFloat startX + progress * toFloat (destX - startX)))
                                                (round (toFloat startY + progress * toFloat (destY - startY)))
                                            )
                                            red
                                            letterOrWildcard
                                            |> Just

                                    Nothing ->
                                        Nothing
                            )
                            placement.cells
                            |> List.filterMap identity

                    else
                        []

                Nothing ->
                    []

        -- The player's held tiles, split into those resting on the board (drawn in the zoomed,
        -- clipped board layer) and those in the tray or being dragged (drawn unzoomed on top).
        ( boardHeldTiles, trayHeldTiles ) =
            List.map2
                Tuple.pair
                (Array.toList model.tiles)
                (case getPlayer currentUserId shared of
                    Just player ->
                        IdArray.toList player.tray

                    Nothing ->
                        []
                )
                |> List.indexedMap Tuple.pair
                |> List.foldr
                    (\( index, ( tile, letter ) ) ( boardAcc, trayAcc ) ->
                        case ( maybeDragging, Dragging index == model.dragging ) of
                            ( Just dragging2, True ) ->
                                let
                                    center : Coord CssPixels
                                    center =
                                        Touch.touchCentroid dragging2
                                in
                                ( boardAcc
                                , tileInFront
                                    setup
                                    currentTime
                                    tile.createdAt
                                    zoomedCellSize
                                    (Coord.xy
                                        (Coord.xRaw center - zoomedCellSize // 2)
                                        (Coord.yRaw center - zoomedCellSize // 2)
                                    )
                                    letter
                                    :: trayAcc
                                )

                            _ ->
                                case tile.position of
                                    TileInTray trayIndex shiftAnimation ->
                                        ( boardAcc
                                        , tileInFront
                                            setup
                                            currentTime
                                            tile.createdAt
                                            (trayTileSize setup.traySize windowSize |> round)
                                            (animatedTrayTilePos setup windowSize currentTime trayIndex shiftAnimation)
                                            letter
                                            :: trayAcc
                                        )

                                    TileOnBoard ( x, y ) _ ->
                                        let
                                            p : { pos : Coord CssPixels, size : Int }
                                            p =
                                                project x y
                                        in
                                        ( tileInFront setup currentTime tile.createdAt p.size p.pos letter :: boardAcc
                                        , trayAcc
                                        )
                    )
                    ( [], [] )

        dragHighlight : Ui.Attribute GameMsg
        dragHighlight =
            case ( model.dragging, maybeDragging ) of
                ( Dragging _, Just dragging2 ) ->
                    case boardCellAtPosition currentTime windowSize setup model (Touch.touchCentroid dragging2) of
                        Just ( x, y ) ->
                            if
                                SeqDict.member ( x, y ) shared.board
                                    || Array.Extra.any
                                        (\tile ->
                                            case tile.position of
                                                TileOnBoard pos _ ->
                                                    pos == ( x, y )

                                                TileInTray _ _ ->
                                                    False
                                        )
                                        model.tiles
                            then
                                Ui.noAttr

                            else
                                let
                                    p : { pos : Coord CssPixels, size : Int }
                                    p =
                                        project x y
                                in
                                Ui.inFront
                                    (Ui.el
                                        [ Ui.borderColor (Ui.rgb 0 200 255)
                                        , Ui.border 3
                                        , Ui.width (Ui.px p.size)
                                        , Ui.height (Ui.px p.size)
                                        , Ui.move { x = Coord.xRaw p.pos, y = Coord.yRaw p.pos, z = 0 }
                                        , MyUi.noPointerEvents
                                        ]
                                        Ui.none
                                    )

                        Nothing ->
                            Ui.noAttr

                _ ->
                    Ui.noAttr

        selectedHighlight : Ui.Attribute GameMsg
        selectedHighlight =
            case model.selectedCell of
                Just ( x, y ) ->
                    let
                        p : { pos : Coord CssPixels, size : Int }
                        p =
                            project x y
                    in
                    Ui.inFront
                        (Ui.el
                            [ Ui.borderColor (Ui.rgb 0 200 255)
                            , Ui.border 4
                            , Ui.width (Ui.px p.size)
                            , Ui.height (Ui.px p.size)
                            , Ui.move { x = Coord.xRaw p.pos, y = Coord.yRaw p.pos, z = 0 }
                            , MyUi.noPointerEvents
                            ]
                            Ui.none
                        )

                Nothing ->
                    Ui.noAttr

        -- A small send-icon button next to every valid word the player has placed. Hidden while a
        -- tile is being dragged, when it isn't the player's turn, or once the game is over.
        lineButtons : List (Ui.Attribute GameMsg)
        lineButtons =
            case ( model.dragging, getWinner shared, isPlayerTurn currentUserId shared ) of
                ( NotDragging, Nothing, JoinedAndItsTheirTurn ) ->
                    submittableLines currentUserId shared model
                        |> List.map
                            (\line ->
                                let
                                    ( bx, by ) =
                                        line.buttonCell

                                    p : { pos : Coord CssPixels, size : Int }
                                    p =
                                        project bx by

                                    idString : String
                                    idString =
                                        "wordSpellingGame_submitLine_"
                                            ++ (if line.placedWord.isVertical then
                                                    "v"

                                                else
                                                    "h"
                                               )
                                            ++ "_"
                                            ++ String.fromInt (Tuple.first line.placedWord.start)
                                            ++ "_"
                                            ++ String.fromInt (Tuple.second line.placedWord.start)
                                in
                                MyUi.elButton (Dom.id idString)
                                    (PressedSubmitWord line.placedWord)
                                    [ Ui.move { x = Coord.xRaw p.pos, y = Coord.yRaw p.pos, z = 0 }
                                    , Ui.width (Ui.px p.size)
                                    , Ui.height (Ui.px p.size)
                                    , Ui.background MyUi.buttonBackground
                                    , Ui.rounded (p.size // 4)
                                    , Ui.borderColor (Ui.rgb 255 255 255)
                                    , Ui.border 2
                                    , Ui.contentCenterX
                                    , Ui.contentCenterY
                                    , Ui.Font.color (Ui.rgb 255 255 255)
                                    ]
                                    (Ui.html Icons.sendMessage)
                                    |> Ui.inFront
                            )

                _ ->
                    []

        trayHeight2 : Int
        trayHeight2 =
            trayHeight setup.traySize windowSize

        trayWidth : Int
        trayWidth =
            Coord.xRaw (trayTilePos setup.traySize windowSize (TrayIndex (OneOrGreater.toInt setup.traySize))) - trayTileSpacing - trayX windowSize

        -- A tray-tile sized button next to the tray that replaces the player's tray with fresh
        -- letters. It's greyed out and does nothing once the letter bag is empty (there's nothing
        -- to draw); the pass/end button in `statusView` takes over then.
        replaceTrayButton : Ui.Attribute GameMsg
        replaceTrayButton =
            if getWinner shared == Nothing && isPlayerTurn currentUserId shared == JoinedAndItsTheirTurn then
                let
                    pos : Coord CssPixels
                    pos =
                        trayTilePos setup.traySize windowSize (TrayIndex (OneOrGreater.toInt setup.traySize))

                    buttonSize : Int
                    buttonSize =
                        round (trayTileSize setup.traySize windowSize)

                    canReplace : Bool
                    canReplace =
                        passBehavior setup shared == ShouldReplaceTray

                    attributes : List (Ui.Attribute GameMsg)
                    attributes =
                        [ Ui.move { x = Coord.xRaw pos, y = Coord.yRaw pos, z = 0 }
                        , Ui.width (Ui.px buttonSize)
                        , Ui.height (Ui.px buttonSize)
                        , Ui.rounded (buttonSize // 6)
                        , Ui.contentCenterX
                        , Ui.contentCenterY
                        , Ui.Font.color (Ui.rgb 255 255 255)
                        , Ui.background
                            (if canReplace then
                                MyUi.buttonBackground

                             else
                                MyUi.disabledButtonBackground
                            )
                        ]
                in
                Ui.inFront
                    (if canReplace then
                        MyUi.elButton (Dom.id "wordSpellingGame_replaceTray") PressedReplaceTrayOrPass attributes (Ui.html Icons.recycle)

                     else
                        Ui.el attributes (Ui.html Icons.recycle)
                    )

            else
                Ui.noAttr

        boardPx : Int
        boardPx =
            gridSize * cellSize2

        -- A large clear button pinned to a top corner of the board viewport, shown only while the
        -- player has tiles resting on the board. It sits in whichever top corner is farther from the
        -- tiles being placed, so it stays out of the way, and is drawn bigger than a grid cell to
        -- stand out. Clicking it returns every placed tile to the tray (see `PressedClearBoard`).
        clearButton : Ui.Attribute GameMsg
        clearButton =
            let
                placed : List ( ( Int, Int ), LetterOrWildcard )
                placed =
                    placedTiles currentUserId shared model
            in
            case ( getWinner shared, placed ) of
                ( Nothing, _ :: _ ) ->
                    let
                        buttonSize : Int
                        buttonSize =
                            round (toFloat cellSize2 * 1.6)

                        -- Centre of each placed tile in on-screen viewport coordinates (so the zoom is
                        -- accounted for), used to decide which top corner is farther away.
                        centers : List ( Float, Float )
                        centers =
                            List.map
                                (\( ( x, y ), _ ) ->
                                    let
                                        p : { pos : Coord CssPixels, size : Int }
                                        p =
                                            project x y
                                    in
                                    ( toFloat (Coord.xRaw p.pos) + toFloat p.size / 2
                                    , toFloat (Coord.yRaw p.pos) + toFloat p.size / 2
                                    )
                                )
                                placed

                        count : Float
                        count =
                            toFloat (List.length placed)

                        centroidX : Float
                        centroidX =
                            List.sum (List.map Tuple.first centers) / count

                        centroidY : Float
                        centroidY =
                            List.sum (List.map Tuple.second centers) / count

                        distanceSquaredTo : Float -> Float
                        distanceSquaredTo cornerX =
                            (centroidX - cornerX) ^ 2 + centroidY ^ 2

                        buttonX : Int
                        buttonX =
                            if distanceSquaredTo (toFloat boardPx) > distanceSquaredTo 0 then
                                boardPx - buttonSize

                            else
                                0
                    in
                    Ui.inFront
                        (MyUi.elButton (Dom.id "wordSpellingGame_clearBoard")
                            PressedClearBoard
                            [ Ui.move { x = buttonX, y = 0, z = 0 }
                            , Ui.width (Ui.px buttonSize)
                            , Ui.height (Ui.px buttonSize)
                            , Ui.background MyUi.buttonBackground
                            , Ui.rounded (buttonSize // 5)
                            , Ui.borderColor (Ui.rgb 255 255 255)
                            , Ui.border 2
                            , Ui.contentCenterX
                            , Ui.contentCenterY
                            , Ui.Font.color (Ui.rgb 255 255 255)
                            ]
                            (Ui.html Icons.delete)
                        )

                _ ->
                    Ui.noAttr

        -- The zoomed board: grid background plus the tiles/highlights that live on the board,
        -- clipped to the board's fixed on-screen square so the zoomed-in content doesn't spill over
        -- the tray or grow the viewport.
        boardLayer : Element GameMsg
        boardLayer =
            Ui.el
                (Ui.width (Ui.px boardPx)
                    :: Ui.height (Ui.px boardPx)
                    :: Ui.clip
                    -- elm-ui's base element class sets `min-height: min-content`, and Chrome (unlike
                    -- Firefox and Safari) lets that beat the explicit `height` above. When the board is
                    -- zoomed in, the in-flow background grid is taller than the board square, so on
                    -- Chrome this element itself grew to the grid's full height and `Ui.clip` clipped at
                    -- the enlarged box, letting the zoomed board spill out the bottom (only the bottom:
                    -- elm-ui resets `min-width` but not `min-height`). Resetting min-height keeps the
                    -- element at boardPx so the clip actually cuts the zoomed content off.
                    :: MyUi.htmlStyle "min-height" "0"
                    :: clearButton
                    :: lineButtons
                    ++ boardTiles
                    ++ animatedTiles
                    ++ boardHeldTiles
                    ++ [ selectedHighlight, dragHighlight ]
                )
                (Ui.el
                    [ Ui.move { x = Coord.xRaw boardTranslate, y = Coord.yRaw boardTranslate, z = 0 } ]
                    (Ui.Lazy.lazy boardViewBackground zoomedCellSize)
                )

        -- The tray tiles, tray background and any tile currently being dragged, drawn unzoomed on
        -- top of the board. Positions are in screen coordinates, so the layer is shifted back to the
        -- board's top-left corner.
        trayLayer : Ui.Attribute GameMsg
        trayLayer =
            Ui.inFront
                (Ui.el
                    (Ui.move { x = -(boardX windowSize), y = -boardY, z = 0 }
                        :: replaceTrayButton
                        :: trayHeldTiles
                        ++ [ Ui.inFront
                                (Ui.el
                                    [ Ui.background (Ui.rgb 119 97 97)
                                    , Ui.move { x = trayX windowSize, y = trayY setup.traySize windowSize, z = 0 }
                                    , Ui.width (Ui.px trayWidth)
                                    , Ui.height (Ui.px (trayHeight2 + 4))
                                    ]
                                    Ui.none
                                )
                           ]
                    )
                    Ui.none
                )
    in
    Ui.el
        [ Ui.width (Ui.px boardPx)
        , Ui.height (Ui.px (boardPx + trayHeight2))
        , Ui.pointer
        , trayLayer
        ]
        boardLayer


tileInFront : ValidatedSetup -> Time.Posix -> Time.Posix -> Int -> Coord CssPixels -> LetterOrWildcard -> Ui.Attribute GameMsg
tileInFront setup currentTime createdAt cellSize2 offset letterOrWildcard =
    let
        fade : { opacity : Float, drift : Float }
        fade =
            tileFade currentTime createdAt
    in
    Ui.inFront
        (Ui.el
            [ Ui.background (Ui.rgb 240 220 130)
            , Ui.width (Ui.px (cellSize2 - 1))
            , Ui.height (Ui.px (cellSize2 - 1))
            , Ui.contentCenterX
            , Ui.contentCenterY
            , toFloat cellSize2 * 0.7 |> ceiling |> Ui.Font.size
            , Ui.Font.bold
            , Ui.move
                { x = Coord.xRaw offset
                , y = Coord.yRaw offset - round (fade.drift * tileFadeDrift * toFloat cellSize2)
                , z = 0
                }
            , Ui.Font.color (Ui.rgb 0 0 0)
            , Ui.opacity fade.opacity
            , MyUi.noPointerEvents
            , tileScoreView setup cellSize2 letterOrWildcard
            ]
            (Ui.text (letterOrWildcardText letterOrWildcard))
        )


boardTileInFront : ValidatedSetup -> Int -> Coord CssPixels -> LetterOrWildcard -> Ui.Attribute GameMsg
boardTileInFront setup cellSize2 offset letterOrWildcard =
    Ui.inFront
        (Ui.el
            [ Ui.background (Ui.rgb 186 171 103)
            , Ui.width (Ui.px (cellSize2 - 1))
            , Ui.height (Ui.px (cellSize2 - 1))
            , Ui.contentCenterX
            , Ui.contentCenterY
            , toFloat cellSize2 * 0.7 |> ceiling |> Ui.Font.size
            , Ui.Font.bold
            , Ui.move { x = Coord.xRaw offset, y = Coord.yRaw offset, z = 0 }
            , Ui.Font.color (Ui.rgb 0 0 0)
            , MyUi.noPointerEvents
            , tileScoreView setup cellSize2 letterOrWildcard
            ]
            (Ui.text (letterOrWildcardText letterOrWildcard))
        )


tileScoreView : ValidatedSetup -> Int -> LetterOrWildcard -> Ui.Attribute msg
tileScoreView setup cellSize2 letterOrWildcard =
    Ui.text
        (case letterOrWildcard of
            Letter letter ->
                letterValue setup letter |> String.fromInt

            Wildcard ->
                ""
        )
        |> Ui.el
            [ toFloat cellSize2 * 0.3 |> ceiling |> Ui.Font.size
            , Ui.alignBottom
            , Ui.alignRight
            , Ui.move { x = -2, y = 0, z = 0 }
            ]
        |> Ui.inFront


{-| A tile drawn by the placement animation. It looks like a committed board tile, except a
rejected tile (on its way back off the board) is shown in red.
-}
animatedTileInFront : ValidatedSetup -> Int -> Coord CssPixels -> Bool -> LetterOrWildcard -> Ui.Attribute GameMsg
animatedTileInFront setup cellSize2 offset red letterOrWildcard =
    Ui.inFront
        (Ui.el
            [ Ui.background
                (if red then
                    Ui.rgb 214 69 69

                 else
                    Ui.rgb 186 171 103
                )
            , Ui.width (Ui.px (cellSize2 - 1))
            , Ui.height (Ui.px (cellSize2 - 1))
            , Ui.contentCenterX
            , Ui.contentCenterY
            , toFloat cellSize2 * 0.7 |> ceiling |> Ui.Font.size
            , Ui.Font.bold
            , Ui.move { x = Coord.xRaw offset, y = Coord.yRaw offset, z = 0 }
            , Ui.Font.color
                (if red then
                    Ui.rgb 255 255 255

                 else
                    Ui.rgb 0 0 0
                )
            , MyUi.noPointerEvents
            , tileScoreView setup cellSize2 letterOrWildcard
            ]
            (Ui.text (letterOrWildcardText letterOrWildcard))
        )


letterOrWildcardText : LetterOrWildcard -> String
letterOrWildcardText letterOrWildcard =
    case letterOrWildcard of
        Letter (LetterChar letter) ->
            String.fromChar letter

        Wildcard ->
            " "


boardViewBackground : Int -> Element GameMsg
boardViewBackground cellSize2 =
    List.map
        (\y ->
            Ui.row
                []
                (List.map (\x -> cellView cellSize2 ( x, y )) (List.range 0 (gridSize - 1)))
        )
        (List.range 0 (gridSize - 1))
        |> Ui.column [ MyUi.noPointerEvents ]


statusHeight : number
statusHeight =
    70


tabBodyHeight : Coord CssPixels -> OneOrGreater -> Int
tabBodyHeight windowSize traySize =
    cellSize traySize windowSize
        * gridSize
        + trayHeight traySize windowSize
        + (if MyUi.isMobile { windowSize = windowSize } then
            statusHeight

           else
            0
          )
        + 10


cellSize : OneOrGreater -> Coord CssPixels -> Int
cellSize traySize windowSize =
    let
        availableSize : Int
        availableSize =
            min
                (round (toFloat (Coord.yRaw windowSize) * 0.7)
                    - trayHeight traySize windowSize
                    - (if MyUi.isMobile { windowSize = windowSize } then
                        statusHeight

                       else
                        0
                      )
                )
                (Coord.xRaw windowSize)
    in
    min 30 (availableSize // gridSize)


cellView : Int -> ( Int, Int ) -> Element GameMsg
cellView cellSize2 position =
    let
        maybeBonus : Maybe BonusCells
        maybeBonus =
            SeqDict.get position bonusCells
    in
    Ui.el
        [ case maybeBonus of
            Just specialCell ->
                Ui.background (bonusCellColor specialCell)

            Nothing ->
                Ui.background (Ui.rgb 250 250 250)
        , Ui.width (Ui.px cellSize2)
        , Ui.height (Ui.px cellSize2)

        -- The center cell's star label has a line box taller than the cell (font-size 0.8×cell with
        -- inherited line-height 1.4). On Chrome, elm-ui's `min-height: min-content` beats the explicit
        -- `height` above, so that one cell — and with it the whole center row — grew taller than the
        -- other rows, showing two horizontal strips of page background across the board. Resetting
        -- min-height keeps every cell exactly cellSize2 tall.
        , MyUi.htmlStyle "min-height" "0"
        , Ui.borderWith { left = 0, right = 1, top = 0, bottom = 1 }
        , Ui.borderColor MyUi.inputBorder
        , Ui.contentCenterX
        , Ui.contentCenterY
        ]
        (case maybeBonus of
            Just bonus ->
                Ui.el
                    [ Ui.centerX
                    , Ui.centerY
                    , (case bonus of
                        CenterCell ->
                            round (toFloat cellSize2 * 0.8)

                        _ ->
                            round (toFloat cellSize2 * 0.5)
                      )
                        |> Ui.Font.size
                    , Ui.Font.color (bonusCellColor bonus |> Color.Manipulate.darken 0.3)
                    , Ui.Font.bold
                    ]
                    (Ui.text (bonusCellLabel bonus))

            Nothing ->
                Ui.none
        )


type BonusCells
    = DoubleWord
    | TripleWord
    | DoubleLetter
    | TripleLetter
    | CenterCell


bonusCellColor : BonusCells -> Ui.Color
bonusCellColor bonus =
    case bonus of
        DoubleWord ->
            Ui.rgb 225 163 163

        TripleWord ->
            Ui.rgb 228 46 46

        DoubleLetter ->
            Ui.rgb 123 208 232

        TripleLetter ->
            Ui.rgb 24 116 191

        CenterCell ->
            Ui.rgb 241 154 154


bonusCellLabel : BonusCells -> String
bonusCellLabel bonus =
    case bonus of
        DoubleWord ->
            "DW"

        TripleWord ->
            "TW"

        DoubleLetter ->
            "DL"

        TripleLetter ->
            "TL"

        CenterCell ->
            "★"


bonusCells : SeqDict ( Int, Int ) BonusCells
bonusCells =
    ( ( 7, 7 ), CenterCell )
        :: List.map (\position -> ( position, TripleWord )) tripleWordCells
        ++ List.map (\position -> ( position, DoubleWord )) doubleWordCells
        ++ List.map (\position -> ( position, TripleLetter )) tripleLetterCells
        ++ List.map (\position -> ( position, DoubleLetter )) doubleLetterCells
        |> SeqDict.fromList


tripleWordCells : List ( Int, Int )
tripleWordCells =
    [ ( 0, 0 )
    , ( 7, 0 )
    , ( 14, 0 )
    , ( 0, 7 )
    , ( 14, 7 )
    , ( 0, 14 )
    , ( 7, 14 )
    , ( 14, 14 )
    ]


doubleWordCells : List ( Int, Int )
doubleWordCells =
    [ ( 1, 1 )
    , ( 2, 2 )
    , ( 3, 3 )
    , ( 4, 4 )
    , ( 13, 1 )
    , ( 12, 2 )
    , ( 11, 3 )
    , ( 10, 4 )
    , ( 1, 13 )
    , ( 2, 12 )
    , ( 3, 11 )
    , ( 4, 10 )
    , ( 13, 13 )
    , ( 12, 12 )
    , ( 11, 11 )
    , ( 10, 10 )
    ]


tripleLetterCells : List ( Int, Int )
tripleLetterCells =
    [ ( 5, 1 )
    , ( 9, 1 )
    , ( 1, 5 )
    , ( 5, 5 )
    , ( 9, 5 )
    , ( 13, 5 )
    , ( 1, 9 )
    , ( 5, 9 )
    , ( 9, 9 )
    , ( 13, 9 )
    , ( 5, 13 )
    , ( 9, 13 )
    ]


doubleLetterCells : List ( Int, Int )
doubleLetterCells =
    [ ( 3, 0 )
    , ( 11, 0 )
    , ( 6, 2 )
    , ( 8, 2 )
    , ( 0, 3 )
    , ( 7, 3 )
    , ( 14, 3 )
    , ( 2, 6 )
    , ( 6, 6 )
    , ( 8, 6 )
    , ( 12, 6 )
    , ( 3, 7 )
    , ( 11, 7 )
    , ( 2, 8 )
    , ( 6, 8 )
    , ( 8, 8 )
    , ( 12, 8 )
    , ( 0, 11 )
    , ( 7, 11 )
    , ( 14, 11 )
    , ( 6, 12 )
    , ( 8, 12 )
    , ( 3, 14 )
    , ( 11, 14 )
    ]


setupView : Coord CssPixels -> SetupModel -> Element SetupMsg
setupView windowSize setup =
    let
        isMobile : Bool
        isMobile =
            MyUi.isMobile { windowSize = windowSize }
    in
    Ui.column
        [ Ui.spacing
            (if isMobile then
                12

             else
                16
            )
        , Ui.paddingXY
            0
            (if isMobile then
                12

             else
                24
            )
        , Ui.background MyUi.tabBackground
        , Ui.height (Ui.px (tabBodyHeight windowSize OneOrGreater.seven))
        , Ui.heightMin 0
        , Ui.scrollable
        ]
        [ setupSection
            (Ui.text "Time control")
            (Ui.row [ Ui.spacing 8, Ui.width Ui.shrink, Ui.contentBottom ]
                [ timeInput "wsg_mainTimeInput" "Main time (minutes)" setup.mainTimeInput ChangedMainTimeInput
                , timeInput "wsg_incrementInput" "Increment (seconds)" setup.incrementInput ChangedIncrementInput
                ]
            )
        , MyUi.container
            MyUi.background1
            isMobile
            "Advanced settings"
            [ setupSection
                (Ui.row
                    []
                    [ Ui.text "Bingo bonus"
                    , Ui.el [ Ui.Font.color MyUi.font3 ] (Ui.text " (points for using a full tray)")
                    ]
                )
                (numberInput
                    { htmlId = "wsg_fullTrayBonusInput"
                    , width = 60
                    , minValue = -999
                    , maxValue = 999
                    , value = String.fromInt setup.fullTrayBonus
                    , onChange = ChangedFullTrayBonusInput
                    }
                )
            , setupSection
                (Ui.row
                    []
                    [ Ui.text "Tray size"
                    , Ui.el [ Ui.Font.color MyUi.font3 ] (Ui.text " (how many letters each player has)")
                    ]
                )
                (numberInput
                    { htmlId = "wsg_traySizeInput"
                    , width = 60
                    , minValue = 1
                    , maxValue = 10
                    , value = String.fromInt setup.traySize
                    , onChange = ChangedTraySizeInput
                    }
                )
            , setupSection
                (Ui.row
                    []
                    [ Ui.text "Letter distribution"
                    , Ui.el [ Ui.Font.color MyUi.font3 ] (Ui.text " (spaces are wildcards)")
                    ]
                )
                (lettersInput setup.letters)
            , case distributionInputLetters setup.letters of
                [] ->
                    Ui.none

                distributionChars ->
                    setupSection
                        (Ui.row
                            []
                            [ Ui.text "Letter values"
                            , Ui.el [ Ui.Font.color MyUi.font3 ] (Ui.text " (points for each letter)")
                            ]
                        )
                        (Ui.row
                            [ Ui.spacing 8, Ui.wrap, Ui.width Ui.shrink ]
                            (List.map (\char -> letterValueInput char (letterValueInputFor char setup)) distributionChars)
                        )
            , if setup.letters == defaultLetters && SeqDict.isEmpty setup.letterValues then
                Ui.none

              else
                MyUi.simpleButton (Dom.id "wsg_resetLetters") PressedResetLetters (Ui.text "Reset to default")
            ]
        , case setup.error of
            Just error ->
                Ui.el [ Ui.Font.color (Ui.rgb 200 50 50) ] (Ui.text error)

            Nothing ->
                Ui.none
        , MyUi.simpleButton (Dom.id "wsg_start") PressedStartGame (Ui.text "Start game")
        ]


setupSection : Element SetupMsg -> Element SetupMsg -> Element SetupMsg
setupSection title content =
    Ui.column
        [ Ui.spacing 8, MyUi.prewrap ]
        [ Ui.el [ Ui.Font.weight 600 ] title
        , content
        ]


numberInput :
    { htmlId : String
    , width : Int
    , minValue : Int
    , maxValue : Int
    , value : String
    , onChange : String -> SetupMsg
    }
    -> Element SetupMsg
numberInput args =
    Html.input
        [ Html.Attributes.id args.htmlId
        , Html.Attributes.type_ "number"
        , Html.Attributes.min (String.fromInt args.minValue)
        , Html.Attributes.max (String.fromInt args.maxValue)
        , Html.Attributes.value args.value
        , Html.Attributes.style "font-size" "inherit"
        , Html.Attributes.style "width" (String.fromInt args.width ++ "px")
        , Html.Attributes.style "padding" "4px 4px 4px 8px"
        , Html.Attributes.style "border" ("1px solid " ++ MyUi.colorToStyle MyUi.inputBorder)
        , Html.Attributes.style "border-radius" "4px"
        , Html.Attributes.style "text-align" "right"
        , Html.Events.onInput args.onChange
        ]
        []
        |> Ui.html


{-| The distinct letters in the distribution input, sorted, one value input each. Uses the same
reading of the string as `parseLetters` (space is a wildcard, other whitespace is ignored) but
doesn't care about case so the value inputs don't vanish while the user is fixing a case error.
-}
distributionInputLetters : String -> List Char
distributionInputLetters string =
    String.toList string
        |> List.filter (\char -> not (List.member char [ ' ', '\n', '\u{000D}', '\t' ]))
        |> List.map Char.toUpper
        |> List.Extra.unique
        |> List.sort


letterValueInput : Char -> String -> Element SetupMsg
letterValueInput char value =
    Ui.row
        [ Ui.spacing 4, Ui.width Ui.shrink ]
        [ Ui.el [ Ui.Font.bold, Ui.Font.family [ Ui.Font.monospace ] ] (Ui.text (String.fromChar char))
        , numberInput
            { htmlId = "wsg_letterValue_" ++ String.fromChar char
            , width = 44
            , minValue = 0
            , maxValue = 999
            , value = value
            , onChange = ChangedLetterValue char
            }
        ]


lettersInput : String -> Element SetupMsg
lettersInput value =
    Html.textarea
        [ Html.Attributes.id "wsg_lettersInput"
        , Html.Attributes.value value
        , Html.Attributes.style "font-size" "inherit"
        , Html.Attributes.style "font-family" "monospace"
        , Html.Attributes.style "width" "100%"
        , Html.Attributes.style "min-width" "260px"
        , Html.Attributes.style "height" "80px"

        -- Wrap at any character (letter wrap) rather than only at spaces, since the distribution is
        -- essentially one long word.
        , Html.Attributes.style "word-break" "break-all"
        , Html.Attributes.style "white-space" "pre-wrap"
        , Html.Attributes.style "padding" "8px"
        , Html.Attributes.style "box-sizing" "border-box"
        , Html.Attributes.style "border" ("1px solid " ++ MyUi.colorToStyle MyUi.inputBorder)
        , Html.Attributes.style "border-radius" "4px"
        , Html.Events.onInput ChangedLettersInput
        ]
        []
        |> Ui.html


timeInput : String -> String -> String -> (String -> SetupMsg) -> Element SetupMsg
timeInput htmlId label value onChange =
    Ui.column [ Ui.spacing 4, Ui.width Ui.shrink ]
        [ Ui.el [ Ui.Font.size 12 ] (Ui.text label)
        , Html.input
            [ Html.Attributes.id htmlId
            , Html.Attributes.type_ "number"
            , Html.Attributes.min "0"
            , Html.Attributes.step "1"
            , Html.Attributes.value value
            , Html.Attributes.style "font-size" "inherit"
            , Html.Attributes.style "width" "70px"
            , Html.Attributes.style "padding" "8px"
            , Html.Attributes.style "border" ("1px solid " ++ MyUi.colorToStyle MyUi.inputBorder)
            , Html.Attributes.style "border-radius" "4px"
            , Html.Events.onInput onChange
            ]
            []
            |> Ui.html
        ]


{-| The standard Scrabble letter distribution: two wildcards (spaces) followed by each letter
repeated as many times as it occurs in the bag.
-}
defaultLetters : String
defaultLetters =
    "  AAAAAAAAABBCCDDDDEEEEEEEEEEEEFFGGGHHIIIIIIIIIJKLLLLMMNNNNNNOOOOOOOOPPQRRRRRRSSSSTTTTTTUUUUVVWWXYYZ"


{-| How many points a letter tile scores, as configured in the game setup.
-}
letterValue : ValidatedSetup -> Letter -> Int
letterValue setup letter =
    case NonemptyDict.get (Letter letter) setup.letters of
        Just data ->
            data.value

        Nothing ->
            0


{-| The default value for a letter when it first appears in the distribution: the standard
Scrabble score for A-Z, and 1 for any other character (the setup lets the user adjust it).
-}
defaultLetterValue : Char -> Int
defaultLetterValue char =
    case char of
        'A' ->
            1

        'B' ->
            3

        'C' ->
            3

        'D' ->
            2

        'E' ->
            1

        'F' ->
            4

        'G' ->
            2

        'H' ->
            4

        'I' ->
            1

        'J' ->
            8

        'K' ->
            5

        'L' ->
            1

        'M' ->
            3

        'N' ->
            1

        'O' ->
            1

        'P' ->
            3

        'Q' ->
            10

        'R' ->
            1

        'S' ->
            1

        'T' ->
            1

        'U' ->
            1

        'V' ->
            4

        'W' ->
            4

        'X' ->
            8

        'Y' ->
            4

        'Z' ->
            10

        _ ->
            1


{-| Read a letter distribution string back into a count of each tile. Spaces are wildcards and
every other printable character is a letter tile, so any alphabet works (Swedish ÅÄÖ, digits,
whatever). Letters must be upper case since that's how they appear on tiles and in the word list.
Fails if there isn't at least one (non-wildcard) letter, since words can't be formed out of
wildcards alone.
-}
parseLetters : String -> Result String (NonemptyDict LetterOrWildcard OneOrGreater)
parseLetters string =
    let
        distributionChars : List Char
        distributionChars =
            String.toList string |> List.filter (\char -> not (List.member char [ '\n', '\u{000D}', '\t' ]))
    in
    if List.any (\char -> char /= ' ' && Char.toUpper char /= char) distributionChars then
        Err "Letters: all letters must be upper case"

    else
        let
            counts : SeqDict LetterOrWildcard OneOrGreater
            counts =
                List.foldl
                    (\char acc ->
                        if char == ' ' then
                            SeqDictHelper.increment Wildcard acc

                        else
                            SeqDictHelper.increment (Letter (LetterChar char)) acc
                    )
                    SeqDict.empty
                    distributionChars
        in
        case NonemptyDict.fromSeqDict counts of
            Just nonempty ->
                if List.any isLetter (SeqDict.keys counts) then
                    Ok nonempty

                else
                    Err "Letters: enter at least one letter"

            Nothing ->
                Err "Letters: enter at least one letter"


isLetter : LetterOrWildcard -> Bool
isLetter letterOrWildcard =
    case letterOrWildcard of
        Letter _ ->
            True

        Wildcard ->
            False


audio : Audio.Source -> Id UserId -> Shared -> GameData -> Audio
audio popSound currentUserId shared model =
    Audio.group
        [ case getPlayer currentUserId shared of
            Just _ ->
                Array.toList model.tiles
                    |> List.map
                        (\tile ->
                            Audio.group
                                [ Audio.audio popSound (Duration.addTo tile.createdAt tileFadeDelay)
                                , case tile.position of
                                    TileInTray _ _ ->
                                        Audio.silence

                                    TileOnBoard _ placedAt ->
                                        Audio.audio popSound placedAt
                                ]
                        )
                    |> Audio.group

            Nothing ->
                Audio.silence
        , case model.lastWordPlaced of
            Just { time, letterCount } ->
                List.range 0 (letterCount - 1)
                    |> List.map
                        (\index ->
                            Quantity.plus tileSlideDuration (Quantity.multiplyBy (toFloat index) tileSlideStagger)
                                |> Duration.addTo time
                                |> Audio.audio popSound
                        )
                    |> Audio.group

            Nothing ->
                Audio.silence
        ]
