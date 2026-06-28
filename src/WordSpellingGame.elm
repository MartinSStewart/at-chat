module WordSpellingGame exposing
    ( Action(..)
    , ActionWithTime
    , AnimatedPlacement
    , Board
    , GameData
    , GameMsg
    , IsValid(..)
    , Letter(..)
    , LetterId
    , LetterOrWildcard
    , LocalChange(..)
    , Model(..)
    , OutMsg(..)
    , PlacedWord
    , PlacementResult
    , Player
    , SetupModel
    , SetupMsg
    , Shared
    , Tile
    , TilePosition
    , UserStatus(..)
    , ValidatedSetup
    , animatedTilePlacement
    , anyTileAnimating
    , boardY
    , dragEnd
    , dragStart
    , gameView
    , initGame
    , initSetup
    , initShared
    , insideBoard
    , isAnimating
    , isPlayerTurn
    , placeWord
    , placementLandTime
    , setupView
    , trayY
    , updateAction
    , updateGame
    , updateSetup
    , validatePlacement
    )

{-| Were calling it this to avoid the Scrabble trademark
-}

import Array exposing (Array)
import Array.Extra
import Char
import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Duration
import Effect.Browser.Dom as Dom
import Effect.Time as Time
import Go exposing (TimeControl)
import Html
import Html.Attributes
import Html.Events
import Id exposing (Id, UserId)
import IdArray exposing (IdArray)
import List.Extra
import List.Nonempty exposing (Nonempty(..))
import MyUi
import NonemptyDict exposing (NonemptyDict)
import NonemptyExtra
import OneOrGreater exposing (OneOrGreater)
import PersonName
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


type Model
    = Setup SetupModel
    | Game GameData


type alias GameData =
    { selectedCell : Maybe ( Int, Int )
    , tiles : Array Tile
    , dragging : Maybe Int
    }


type alias Tile =
    { position : TilePosition, createdAt : Time.Posix }


type TilePosition
    = -- The `Maybe ( Time.Posix, Int )` records, when the tile was shifted to make room for an
      -- inserted tile, the moment the shift started and the slot it shifted from, so the view can
      -- animate it sliding from its old slot to this one.
      TileInTray TrayIndex (Maybe ( Time.Posix, Int ))
    | TileOnBoard ( Int, Int )


type TrayIndex
    = TrayIndex Int


type SetupMsg
    = ChangedMainTimeInput String
    | ChangedIncrementInput String
    | ChangedTraySizeInput String
    | ChangedLettersInput String
    | PressedResetLetters
    | PressedStartGame


type GameMsg
    = PressedSubmitWord
    | PressedJoinGame
    | PressedReplaceTrayOrPass


type alias SetupModel =
    { mainTimeInput : String
    , incrementInput : String
    , traySize : Int
    , error : Maybe String
    , letters : String
    }


type alias ValidatedSetup =
    { timeControls : TimeControl
    , traySize : OneOrGreater
    , createdBy : Id UserId
    , seed : Int
    , letters : NonemptyDict LetterOrWildcard OneOrGreater
    }


initSetup : SetupModel
initSetup =
    { mainTimeInput = "10"
    , incrementInput = "5"
    , traySize = 7
    , error = Nothing
    , letters = defaultLetters
    }


initGame : Time.Posix -> ValidatedSetup -> ( GameData, List OutMsg )
initGame time setup =
    ( { selectedCell = Nothing
      , tiles =
            List.range 0 (OneOrGreater.toInt setup.traySize - 1)
                |> List.map
                    (\index ->
                        { position = TileInTray (TrayIndex index) Nothing
                        , createdAt = Duration.addTo time (Duration.seconds (0.2 * toFloat index))
                        }
                    )
                |> Array.fromList
      , dragging = Nothing
      }
    , List.map
        (\index -> PlaySound (Duration.addTo time (Duration.seconds (0.2 * toFloat index)) |> Just) "pop")
        (List.range 0 (OneOrGreater.toInt setup.traySize - 1))
    )


type OutMsg
    = OutLocalChange LocalChange
    | PlaySound (Maybe Time.Posix) String


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
    , letters : Nonempty Letter
    }


type alias ActionWithTime =
    { userId : Id UserId, time : Time.Posix, change : Action }


type alias Shared =
    { board : SeqDict ( Int, Int ) { letter : Letter, isWildcard : Bool }
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
    , cells : List ( ( Int, Int ), Letter )
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
        initialBoard : SeqDict ( Int, Int ) { letter : Letter, isWildcard : Bool }
        initialBoard =
            SeqDict.empty
    in
    { board = initialBoard
    , players = Nonempty (initPlayer setup.createdBy initialBoard setup []) []
    , turnCount = 0
    , lastPlacement = Nothing
    , passingStartedAt = Nothing
    }


remainingLettersInBag :
    ValidatedSetup
    -> SeqDict a { b | letter : Letter, isWildcard : Bool }
    -> List Player
    -> SeqDict LetterOrWildcard OneOrGreater
remainingLettersInBag setup board players =
    let
        remainingLetters : SeqDict LetterOrWildcard OneOrGreater
        remainingLetters =
            SeqDict.foldl
                (\_ { letter, isWildcard } startingLetters2 ->
                    SeqDictHelper.decrement
                        (if isWildcard then
                            Wildcard

                         else
                            Letter letter
                        )
                        startingLetters2
                )
                (NonemptyDict.toSeqDict setup.letters)
                board
    in
    List.foldl
        (\player remainingLetters2 -> IdArray.foldl SeqDictHelper.decrement remainingLetters2 player.tray)
        remainingLetters
        players


getLetters :
    OneOrGreater
    -> ValidatedSetup
    -> SeqDict ( Int, Int ) { letter : Letter, isWildcard : Bool }
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


getWinner : Shared -> Maybe (Nonempty (Id UserId))
getWinner shared =
    case shared.passingStartedAt of
        Just passingStartedAt ->
            if List.Nonempty.length shared.players <= shared.turnCount - passingStartedAt then
                let
                    player =
                        NonemptyExtra.maximumBy .score shared.players
                in
                List.Nonempty.filter (\a -> a.score == player.score) player shared.players
                    |> List.Nonempty.map .userId
                    |> Just

            else
                Nothing

        Nothing ->
            Nothing


updateAction : ValidatedSetup -> ActionWithTime -> Shared -> Shared
updateAction setup action state =
    case action.change of
        PlaceWord placedWord isValid ->
            case ( getWinner state, getPlayer action.userId state ) of
                ( Nothing, Just player ) ->
                    case placeWord state.board placedWord of
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
                                        (List.map Letter (List.Nonempty.toList placedWord.letters))

                                drawn : List LetterOrWildcard
                                drawn =
                                    case OneOrGreater.fromInt (OneOrGreater.toInt setup.traySize - List.length remainingTray) of
                                        Just drawCount ->
                                            getLetters
                                                drawCount
                                                setup
                                                result.board
                                                (NonemptyExtra.set state.turnCount { player | tray = IdArray.fromList remainingTray } state.players
                                                    |> List.Nonempty.toList
                                                )
                                                state.turnCount

                                        Nothing ->
                                            []

                                tray =
                                    remainingTray ++ drawn |> IdArray.fromList
                            in
                            { state
                                | board =
                                    case isValid of
                                        FilledInByBackend IsNotValid ->
                                            state.board

                                        _ ->
                                            result.board
                                , players =
                                    NonemptyExtra.set
                                        state.turnCount
                                        { player
                                            | tray = tray
                                            , score =
                                                case isValid of
                                                    FilledInByBackend IsNotValid ->
                                                        player.score

                                                    _ ->
                                                        player.score + result.score
                                        }
                                        state.players
                                , turnCount = state.turnCount + 1
                                , lastPlacement = animatedPlacement
                                , passingStartedAt =
                                    if tray == IdArray.empty then
                                        case state.passingStartedAt of
                                            Nothing ->
                                                Just state.turnCount

                                            Just _ ->
                                                state.passingStartedAt

                                    else
                                        Nothing
                            }

                        Nothing ->
                            state

                _ ->
                    state

        ReplaceTrayOrPass ->
            case ( getWinner state, getPlayer action.userId state ) of
                ( Nothing, Just player ) ->
                    case passBehavior setup state of
                        ShouldReplaceTray ->
                            { state
                                | players =
                                    NonemptyExtra.set
                                        state.turnCount
                                        { player
                                            | tray =
                                                getLetters
                                                    setup.traySize
                                                    setup
                                                    state.board
                                                    (NonemptyExtra.set state.turnCount { player | tray = IdArray.empty } state.players
                                                        |> List.Nonempty.toList
                                                    )
                                                    state.turnCount
                                                    |> IdArray.fromList
                                        }
                                        state.players
                                , turnCount = state.turnCount + 1
                                , passingStartedAt = Nothing
                            }

                        ShouldPass ->
                            { state
                                | passingStartedAt =
                                    case state.passingStartedAt of
                                        Nothing ->
                                            Just state.turnCount

                                        Just _ ->
                                            state.passingStartedAt
                                , turnCount = state.turnCount + 1
                            }

                        ShouldEndGame ->
                            { state | turnCount = state.turnCount + 1 }

                _ ->
                    state

        JoinGame ->
            if state.turnCount > List.Nonempty.length state.players then
                state

            else
                { state
                    | players =
                        List.Nonempty.append
                            state.players
                            (Nonempty
                                (initPlayer action.userId state.board setup (List.Nonempty.toList state.players))
                                []
                            )
                }


initPlayer : Id UserId -> SeqDict ( Int, Int ) { letter : Letter, isWildcard : Bool } -> ValidatedSetup -> List Player -> Player
initPlayer userId board setup existingPlayers =
    { userId = userId
    , tray = getLetters setup.traySize setup board existingPlayers 0 |> IdArray.fromList
    , score = 0
    }


type alias Board =
    SeqDict ( Int, Int ) { letter : Letter, isWildcard : Bool }


type alias PlacementResult =
    { board : Board
    , words : List String
    , score : Int
    , placedCells : List ( ( Int, Int ), Letter )
    }


{-| Lay a word's new letters out along the placement direction starting from `start`, stepping
over any tiles already on the board (which aren't placed again), then work out every word that
the placement forms: the main word along the placement direction, plus any perpendicular
cross-word that runs through a newly-placed tile. Returns `Nothing` if the letters run off the
edge of the board.

The returned `words` are lowercased so they can be looked up directly in the word list, and
`score` is the combined Scrabble score of all the formed words (letter and word multipliers only
apply to the squares the new tiles land on; wildcards score zero).

-}
placeWord : Board -> PlacedWord -> Maybe PlacementResult
placeWord board placedWord =
    let
        ( dx, dy ) =
            if placedWord.isVertical then
                ( 0, 1 )

            else
                ( 1, 0 )

        -- Lay out the new letters, stepping over tiles already committed to the board.
        layout : ( Int, Int ) -> List Letter -> List ( ( Int, Int ), Letter ) -> Maybe (List ( ( Int, Int ), Letter ))
        layout ( cx, cy ) remaining acc =
            case remaining of
                [] ->
                    Just (List.reverse acc)

                letter :: rest ->
                    if cx < 0 || cy < 0 || cx >= gridSize || cy >= gridSize then
                        Nothing

                    else
                        case SeqDict.get ( cx, cy ) board of
                            Just _ ->
                                layout ( cx + dx, cy + dy ) remaining acc

                            Nothing ->
                                layout ( cx + dx, cy + dy ) rest (( ( cx, cy ), letter ) :: acc)
    in
    case layout placedWord.start (List.Nonempty.toList placedWord.letters) [] of
        Just placedCells ->
            let
                newBoard : Board
                newBoard =
                    List.foldl
                        (\( cell, letter ) acc -> SeqDict.insert cell { letter = letter, isWildcard = False } acc)
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
                , score = List.sum (List.map (wordScore newBoard placedSet) allWords)
                , placedCells = placedCells
                }

        Nothing ->
            Nothing


{-| The maximal contiguous run of tiles through `cell` in the direction `( dirX, dirY )`.
-}
lineWord : Board -> ( Int, Int ) -> ( Int, Int ) -> List ( Int, Int )
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


{-| The lowercased text of the word formed by the given cells.
-}
wordString : Board -> List ( Int, Int ) -> String
wordString board cells =
    List.filterMap
        (\cell -> SeqDict.get cell board |> Maybe.map (\{ letter } -> (letterData letter).text))
        cells
        |> String.concat
        |> String.toLower


{-| The Scrabble score of a single word. Letter and word multipliers only apply to the squares
that the newly-placed tiles (`placedSet`) land on; wildcards always score zero.
-}
wordScore : Board -> Set ( Int, Int ) -> List ( Int, Int ) -> Int
wordScore board placedSet cells =
    let
        letterSum : Int
        letterSum =
            List.map
                (\cell ->
                    case SeqDict.get cell board of
                        Just { letter, isWildcard } ->
                            if isWildcard then
                                0

                            else if Set.member cell placedSet then
                                (letterData letter).score * letterScoreMultiplier cell

                            else
                                (letterData letter).score

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
exists in `wordList`.
-}
validatePlacement : Set String -> Board -> PlacedWord -> Result () PlacementResult
validatePlacement wordList board placedWord =
    case placeWord board placedWord of
        Just result ->
            if List.isEmpty result.words then
                Err ()

            else if List.all (\word -> Set.member word wordList) result.words then
                Ok result

            else
                Err ()

        Nothing ->
            Err ()


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


updateSetup :
    Time.Posix
    -> Id UserId
    -> SetupMsg
    -> SetupModel
    -> ( Model, List OutMsg )
updateSetup time currentUserId msg setup =
    case msg of
        ChangedMainTimeInput input ->
            ( Setup { setup | mainTimeInput = input, error = Nothing }, [] )

        ChangedIncrementInput input ->
            ( Setup { setup | incrementInput = input, error = Nothing }, [] )

        ChangedTraySizeInput input ->
            ( { setup
                | traySize = String.toInt (String.trim input) |> Maybe.withDefault setup.traySize
                , error = Nothing
              }
                |> Setup
            , []
            )

        ChangedLettersInput input ->
            ( Setup { setup | letters = input, error = Nothing }, [] )

        PressedResetLetters ->
            ( Setup { setup | letters = defaultLetters, error = Nothing }, [] )

        PressedStartGame ->
            case validateSetup currentUserId time setup of
                Ok validated ->
                    let
                        ( model, outMsgs ) =
                            initGame time validated
                    in
                    ( Game model, OutLocalChange (StartMatch time validated) :: outMsgs )

                Err error ->
                    ( Setup { setup | error = Just error }, [] )


updateGame : Time.Posix -> Id UserId -> ValidatedSetup -> Shared -> GameMsg -> GameData -> ( GameData, List OutMsg )
updateGame time currentUserId setup shared msg model =
    case msg of
        PressedSubmitWord ->
            case checkValidPlacement currentUserId shared model of
                Ok placement ->
                    let
                        remainingTray =
                            Array.filter
                                (\tile ->
                                    case tile.position of
                                        TileInTray _ _ ->
                                            True

                                        TileOnBoard _ ->
                                            False
                                )
                                model.tiles
                    in
                    ( { model
                        | tiles =
                            List.range 0 (OneOrGreater.toInt setup.traySize - Array.length remainingTray - 1)
                                |> List.foldl
                                    (\index tray ->
                                        Array.push
                                            { position = TileInTray (firstOpenTrayIndex Nothing tray) Nothing
                                            , createdAt = Duration.addTo time (Duration.seconds (0.1 * toFloat index))
                                            }
                                            tray
                                    )
                                    remainingTray
                      }
                    , [ { userId = currentUserId, change = PlaceWord placement EmptyPlaceholder, time = time }
                            |> Action
                            |> OutLocalChange

                      -- The refilled tray tiles fade in tileFadeDelay later, so pop then.
                      , PlaySound (Just (addMs tileFadeDelay time)) "pop"
                      ]
                    )

                Err () ->
                    ( model, [] )

        PressedJoinGame ->
            ( model, [ OutLocalChange (Action { userId = currentUserId, change = JoinGame, time = time }) ] )

        PressedReplaceTrayOrPass ->
            ( model, [ OutLocalChange (Action { userId = currentUserId, change = ReplaceTrayOrPass, time = time }) ] )


{-| Turn the tiles the local player has dragged onto the board into a `PlacedWord`, or `Err` if
the placement isn't a valid word. The tiles the player holds are the current player's tray, in
the same order as `GameData.tiles` (see `boardView`).

A placement is valid when:

  - at least one tile was placed on the board,
  - the placed tiles all lie in a single row or column, and
  - the run from the first to the last placed tile has no gaps (any cell between them that wasn't
    placed must already hold a committed tile).

Wildcard tiles aren't supported yet (there's no way to pick which letter they represent), so a
placement containing one is rejected.

-}
checkValidPlacement : Id UserId -> Shared -> GameData -> Result () PlacedWord
checkValidPlacement currentUserId shared notShared =
    let
        placed : List ( ( Int, Int ), LetterOrWildcard )
        placed =
            case getPlayer currentUserId shared of
                Just player ->
                    List.map2 Tuple.pair (Array.toList notShared.tiles) (IdArray.toList player.tray)
                        |> List.filterMap
                            (\( tile, letter ) ->
                                case tile.position of
                                    TileOnBoard cell ->
                                        Just ( cell, letter )

                                    TileInTray _ _ ->
                                        Nothing
                            )

                Nothing ->
                    []
    in
    case placed of
        ( firstCell, _ ) :: _ ->
            let
                cells : List ( Int, Int )
                cells =
                    List.map Tuple.first placed

                sameRow : Bool
                sameRow =
                    List.all (\( _, y ) -> y == Tuple.second firstCell) cells

                sameColumn : Bool
                sameColumn =
                    List.all (\( x, _ ) -> x == Tuple.first firstCell) cells
            in
            if sameRow then
                buildPlacedWord False shared placed

            else if sameColumn then
                buildPlacedWord True shared placed

            else
                Err ()

        [] ->
            Err ()


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
            in
            case ( contiguous, nonemptyLetters sorted ) of
                ( True, Just letters ) ->
                    Ok { start = startCell, isVertical = isVertical, letters = letters }

                _ ->
                    Err ()

        _ ->
            Err ()


{-| Pull the letters out of the placed tiles in order, failing if any tile is a wildcard or if
there are no tiles.
-}
nonemptyLetters : List ( ( Int, Int ), LetterOrWildcard ) -> Maybe (Nonempty Letter)
nonemptyLetters list =
    List.foldr
        (\( _, letterOrWildcard ) acc ->
            case letterOrWildcard of
                Letter letter ->
                    Maybe.map ((::) letter) acc

                Wildcard ->
                    Nothing
        )
        (Just [])
        list
        |> Maybe.andThen List.Nonempty.fromList


validateSetup : Id UserId -> Time.Posix -> SetupModel -> Result String ValidatedSetup
validateSetup createdBy time setup =
    case parseTimeControl setup of
        Err error ->
            Err error

        Ok timeControls ->
            case OneOrGreater.fromInt setup.traySize of
                Just traySize ->
                    case parseLetters setup.letters of
                        Ok nonempty ->
                            { createdBy = createdBy
                            , timeControls = timeControls
                            , traySize = traySize
                            , seed =
                                -- Round the time to the nearest 10 seconds so that small timing changes don't break an end-to-end test
                                Time.posixToMillis time // 10000 |> (*) 10000 |> (+) (Id.toInt createdBy)
                            , letters = nonempty
                            }
                                |> Ok

                        Err error ->
                            Err error

                Nothing ->
                    Err "Tray size must be at least 1"


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
    MyUi.channelAndGuildColumnWidth windowSize


boardY : number
boardY =
    MyUi.channelHeaderHeight


trayX : Coord CssPixels -> Int
trayX =
    boardX


trayY : Coord CssPixels -> Int
trayY windowSize =
    boardY + boardWidth windowSize


boardWidth : Coord CssPixels -> Int
boardWidth windowSize =
    cellSize windowSize * gridSize


boardHeight : Coord CssPixels -> Int
boardHeight windowSize =
    boardWidth windowSize + trayHeight


insideBoard : Coord CssPixels -> Coord CssPixels -> Bool
insideBoard windowSize coord =
    let
        x =
            boardX windowSize
    in
    (Coord.xRaw coord > x)
        && (Coord.xRaw coord < (x + boardWidth windowSize))
        && (Coord.yRaw coord > boardY)
        && (Coord.yRaw coord < boardY + boardHeight windowSize)


{-| Which board cell (if any) a screen position is over.
-}
cellAtPosition : Coord CssPixels -> Coord CssPixels -> Maybe ( Int, Int )
cellAtPosition windowSize coord =
    let
        size : Int
        size =
            cellSize windowSize

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


trayTileSize : number
trayTileSize =
    50


trayTileSpacing : number
trayTileSpacing =
    4


trayTilePos : Coord CssPixels -> TrayIndex -> Coord CssPixels
trayTilePos windowSize (TrayIndex index) =
    Coord.xy
        (boardX windowSize + index * (trayTileSize + trayTileSpacing))
        (trayY windowSize)


{-| Where a tray tile is currently drawn. While a shift animation is in progress the tile eases
from the slot it was shifted out of toward its current slot; otherwise it sits at its current slot.
-}
animatedTrayTilePos : Coord CssPixels -> Time.Posix -> TrayIndex -> Maybe ( Time.Posix, Int ) -> Coord CssPixels
animatedTrayTilePos windowSize currentTime trayIndex shiftAnimation =
    let
        dest : Coord CssPixels
        dest =
            trayTilePos windowSize trayIndex
    in
    case shiftAnimation of
        Just ( startTime, fromSlot ) ->
            let
                eased : Float
                eased =
                    easeOutCubic (clamp 0 1 (elapsedMs currentTime startTime / trayShiftDuration))

                from : Coord CssPixels
                from =
                    trayTilePos windowSize (TrayIndex fromSlot)

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
trayIndexAtPosition : Coord CssPixels -> Coord CssPixels -> Int -> Maybe Int
trayIndexAtPosition windowSize coord trayLength =
    let
        relX : Int
        relX =
            Coord.xRaw coord - trayX windowSize

        relY : Int
        relY =
            Coord.yRaw coord - trayY windowSize

        index =
            relX // (trayTileSize + trayTileSpacing)
    in
    if relX >= 0 && relY >= 0 && relY < trayHeight && index < trayLength then
        Just index

    else
        Nothing


getPlayer : Id UserId -> Shared -> Maybe Player
getPlayer userId gameState =
    List.Extra.find (\player -> player.userId == userId) (List.Nonempty.toList gameState.players)


dragStart : Coord CssPixels -> NonemptyDict Int Touch -> ValidatedSetup -> GameData -> Model
dragStart windowSize touches setup gameModel =
    let
        touchPosition : Coord CssPixels
        touchPosition =
            Touch.touchCentroid touches

        trayList =
            Array.toList gameModel.tiles
    in
    case cellAtPosition windowSize touchPosition of
        Just cell ->
            case
                List.Extra.findIndex
                    (\tile ->
                        case tile.position of
                            TileOnBoard boardPosition ->
                                boardPosition == cell

                            TileInTray _ _ ->
                                False
                    )
                    trayList
            of
                Just tileIndex ->
                    Game { gameModel | dragging = Just tileIndex }

                Nothing ->
                    Game gameModel

        Nothing ->
            case trayIndexAtPosition windowSize touchPosition (OneOrGreater.toInt setup.traySize) of
                Just index ->
                    case
                        List.Extra.findIndex
                            (\tile ->
                                case tile.position of
                                    TileOnBoard _ ->
                                        False

                                    TileInTray trayIndex _ ->
                                        trayIndex == TrayIndex index
                            )
                            trayList
                    of
                        Just tileIndex ->
                            Game { gameModel | dragging = Just tileIndex }

                        Nothing ->
                            Game gameModel

                Nothing ->
                    Game gameModel


dragEnd : Time.Posix -> Coord CssPixels -> NonemptyDict Int Touch -> Shared -> GameData -> Model
dragEnd currentTime windowSize newTouches shared gameModel =
    case gameModel.dragging of
        Just tileIndex ->
            let
                position : Coord CssPixels
                position =
                    Touch.touchCentroid newTouches

                returnToTray : Model
                returnToTray =
                    if distanceToTray windowSize position (Array.length gameModel.tiles) <= maxTraySnapDistance then
                        insertIntoTray currentTime windowSize tileIndex position gameModel

                    else
                        Game
                            { gameModel
                                | dragging = Nothing
                                , tiles =
                                    Array.Extra.update
                                        tileIndex
                                        (\tile -> { tile | position = TileInTray (firstOpenTrayIndex (Just tileIndex) gameModel.tiles) Nothing })
                                        gameModel.tiles
                            }
            in
            case cellAtPosition windowSize position of
                Just cell ->
                    if SeqDict.member cell shared.board || cellOccupiedByOtherTile tileIndex cell gameModel.tiles then
                        returnToTray

                    else
                        Game
                            { gameModel
                                | dragging = Nothing
                                , tiles =
                                    Array.Extra.update
                                        tileIndex
                                        (\tile -> { tile | position = TileOnBoard cell })
                                        gameModel.tiles
                            }

                Nothing ->
                    returnToTray

        Nothing ->
            Game gameModel


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

                                TileOnBoard _ ->
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
        |> List.any (\( index, tile ) -> index /= draggedIndex && tile.position == TileOnBoard cell)


{-| How close (in CSS pixels) the cursor has to be to the tray for a dropped tile to snap into it
rather than fall back to the first open slot.
-}
maxTraySnapDistance : number
maxTraySnapDistance =
    100


{-| The distance (in CSS pixels) from a screen position to the nearest edge of the tray rectangle,
or 0 when the position is inside it.
-}
distanceToTray : Coord CssPixels -> Coord CssPixels -> Int -> Float
distanceToTray windowSize coord slotCount =
    let
        left : Int
        left =
            trayX windowSize

        right : Int
        right =
            left + slotCount * trayTileSize + (slotCount - 1) * trayTileSpacing

        top : Int
        top =
            trayY windowSize

        bottom : Int
        bottom =
            top + trayHeight

        dx : Int
        dx =
            max 0 (max (left - Coord.xRaw coord) (Coord.xRaw coord - right))

        dy : Int
        dy =
            max 0 (max (top - Coord.yRaw coord) (Coord.yRaw coord - bottom))
    in
    sqrt (toFloat (dx * dx + dy * dy))


{-| Drop the dragged tile into the tray slot nearest the cursor, shifting the tiles between that
slot and the nearest empty slot over by one to make room.
-}
insertIntoTray : Time.Posix -> Coord CssPixels -> Int -> Coord CssPixels -> GameData -> Model
insertIntoTray currentTime windowSize tileIndex position gameModel =
    let
        slotCount : Int
        slotCount =
            Array.length gameModel.tiles

        target : Int
        target =
            toFloat (Coord.xRaw position - trayX windowSize)
                / (trayTileSize + trayTileSpacing)
                |> round
                |> clamp 0 (slotCount - 1)

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

                                TileOnBoard _ ->
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
    Game
        { gameModel
            | dragging = Nothing
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

                                TileOnBoard _ ->
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


{-| How long, in milliseconds, a single tile takes to slide from the board's top-left corner to
its destination cell.
-}
tileSlideDuration : Float
tileSlideDuration =
    250


{-| How long, in milliseconds, each successive tile waits before it starts sliding in, so the
tiles arrive one after another rather than all at once.
-}
tileSlideStagger : Float
tileSlideStagger =
    80


{-| How long, in milliseconds, rejected tiles sit on the board (turned red) before sliding back
off again.
-}
invalidHoldDuration : Float
invalidHoldDuration =
    2000


{-| How long, in milliseconds, a freshly created tile stays hidden before it fades in.
-}
tileFadeDelay : Float
tileFadeDelay =
    1000


{-| How long, in milliseconds, the fade-and-drift into place itself takes, once it starts.
-}
tileFadeDuration : Float
tileFadeDuration =
    200


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
    150


{-| Whether a tile is still within its fade-in window, so the view keeps redrawing each animation
frame until it has settled.
-}
isTileFading : Time.Posix -> Time.Posix -> Bool
isTileFading currentTime createdAt =
    elapsedMs currentTime createdAt < tileFadeDelay + tileFadeDuration


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


addMs : Float -> Time.Posix -> Time.Posix
addMs ms time =
    Time.millisToPosix (Time.posixToMillis time + round ms)


{-| When the tiles of a placement finish sliding onto the board (as seen by a player watching it
happen), so a sound can be scheduled to land with them.
-}
placementLandTime : Time.Posix -> PlacedWord -> Time.Posix
placementLandTime placementTime placedWord =
    addMs (slideInEnd (List.Nonempty.length placedWord.letters)) placementTime


{-| The moment, in milliseconds since the placement started, at which the last tile has finished
sliding in.
-}
slideInEnd : Int -> Float
slideInEnd tileCount =
    toFloat (max 0 (tileCount - 1)) * tileSlideStagger + tileSlideDuration


{-| The total length of a placement's animation. A valid placement just slides in; a rejected one
also holds and then slides back off.
-}
placementAnimationDuration : ToBeFilledInByBackend IsValid -> Int -> Float
placementAnimationDuration isValid tileCount =
    case isValid of
        FilledInByBackend IsNotValid ->
            slideInEnd tileCount + invalidHoldDuration + slideInEnd tileCount

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
                < placementAnimationDuration placement.isValid (List.length placement.cells)

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
            clamp 0 1 ((elapsedMs currentTime createdAt - tileFadeDelay) / tileFadeDuration)
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
            toFloat index * tileSlideStagger

        slideEnd : Float
        slideEnd =
            launch + tileSlideDuration

        slideInProgress : Float
        slideInProgress =
            if isPlayerWhoPlacedTiles then
                1

            else if elapsed < launch then
                0

            else
                easeOutCubic ((elapsed - launch) / tileSlideDuration)
    in
    case isValid of
        FilledInByBackend IsNotValid ->
            let
                leaveStart : Float
                leaveStart =
                    slideInEnd tileCount + invalidHoldDuration + toFloat index * tileSlideStagger

                leaveEnd : Float
                leaveEnd =
                    leaveStart + tileSlideDuration
            in
            if elapsed < slideEnd then
                Just { progress = slideInProgress, red = False }

            else if elapsed < (leaveStart + slideEnd) * 0.5 then
                Just { progress = 1, red = False }

            else if elapsed < leaveStart then
                Just { progress = 1, red = True }

            else if elapsed < leaveEnd then
                Just { progress = 1 - easeOutCubic ((elapsed - leaveStart) / tileSlideDuration), red = True }

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
    -> LocalUser
    -> ValidatedSetup
    -> Shared
    -> GameData
    -> Element GameMsg
gameView currentTime windowSize maybeDragging localUser setup shared model =
    Ui.row
        [ Ui.spacing 16, Ui.wrap ]
        [ boardView currentTime windowSize maybeDragging localUser.session.userId setup shared model
        , Ui.column
            [ Ui.paddingXY 16 0 ]
            [ statusView localUser.session.userId localUser setup shared
            , case isPlayerTurn localUser.session.userId shared of
                JoinedAndItsTheirTurn ->
                    Ui.row
                        [ Ui.spacing 16 ]
                        [ MyUi.simpleButton (Dom.id "wordSpellingGame_submitWord") PressedSubmitWord (Ui.text "Submit word")
                        , MyUi.simpleButton
                            (Dom.id "wordSpellingGame_replaceTray")
                            PressedReplaceTrayOrPass
                            (case passBehavior setup shared of
                                ShouldReplaceTray ->
                                    Ui.text "Replace tray"

                                ShouldPass ->
                                    Ui.text "Pass turn"

                                ShouldEndGame ->
                                    Ui.text "End game"
                            )
                        ]

                Joined ->
                    Ui.none

                NotJoined ->
                    MyUi.simpleButton (Dom.id "wordSpellingGame_joinGame") PressedJoinGame (Ui.text "Join game")
            ]
        ]


{-| A row showing a player's profile image and name, followed by `suffix` (their score and any
status text). Bolded when `isBold` is True (the current player's turn, or a winner).
-}
playerRow : LocalUser -> Id UserId -> Bool -> String -> Element GameMsg
playerRow localUser userId isBold suffix =
    let
        maybeUser : Maybe User.FrontendUser
        maybeUser =
            User.getUser userId localUser
    in
    Ui.row
        [ Ui.spacing 8
        , Ui.width Ui.shrink
        , if isBold then
            Ui.Font.weight 700

          else
            Ui.Font.weight 400
        ]
        [ User.profileImage userId (Maybe.andThen .icon maybeUser)
        , Ui.text
            ((case maybeUser of
                Just user ->
                    PersonName.toString user.name

                Nothing ->
                    "Unknown"
             )
                ++ suffix
            )
        ]


leaderboardView : Shared -> LocalUser -> Element GameMsg
leaderboardView shared localUser =
    let
        winners : List (Id UserId)
        winners =
            case getWinner shared of
                Just nonempty ->
                    List.Nonempty.toList nonempty

                Nothing ->
                    []

        isTie : Bool
        isTie =
            List.length winners > 1

        sortedPlayers : List Player
        sortedPlayers =
            List.Nonempty.toList shared.players
                |> List.sortBy (\player -> negate player.score)
    in
    Ui.column
        [ Ui.spacing 8 ]
        (Ui.el
            [ Ui.Font.weight 700 ]
            (Ui.text
                (if isTie then
                    "Game over — it's a tie!"

                 else
                    "Game over"
                )
            )
            :: List.map
                (\player ->
                    let
                        isWinner : Bool
                        isWinner =
                            List.member player.userId winners
                    in
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
                )
                sortedPlayers
        )


statusView : Id UserId -> LocalUser -> ValidatedSetup -> Shared -> Element GameMsg
statusView currentUserId localUser setup shared =
    let
        currentPlayer : Player
        currentPlayer =
            List.Nonempty.get shared.turnCount shared.players

        playerCount =
            List.Nonempty.length shared.players

        lettersLeft =
            SeqDict.foldl
                (\_ a total -> OneOrGreater.toInt a + total)
                0
                (remainingLettersInBag setup shared.board (List.Nonempty.toList shared.players))
    in
    case getWinner shared of
        Just winners ->
            leaderboardView shared localUser

        Nothing ->
            Ui.column
                [ Ui.spacing 8 ]
                (Ui.text ("Letters remaining: " ++ String.fromInt lettersLeft)
                    :: List.indexedMap
                        (\index player ->
                            let
                                isTheirTurn : Bool
                                isTheirTurn =
                                    index == modBy playerCount shared.turnCount
                            in
                            playerRow
                                localUser
                                player.userId
                                (player.userId == currentPlayer.userId)
                                (": "
                                    ++ String.fromInt player.score
                                    ++ (if isTheirTurn then
                                            if player.userId == currentUserId then
                                                " (your turn)"

                                            else
                                                " (their turn)"

                                        else
                                            ""
                                       )
                                )
                        )
                        (List.Nonempty.toList shared.players)
                )


trayHeight : number
trayHeight =
    trayTileSize


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
            cellSize windowSize

        animatingCellSet : Set ( Int, Int )
        animatingCellSet =
            animatingCells currentTime shared

        boardTiles : List (Ui.Attribute GameMsg)
        boardTiles =
            SeqDict.foldl
                (\( x, y ) { letter, isWildcard } list ->
                    if Set.member ( x, y ) animatingCellSet then
                        -- This tile is being animated into place, so the animation layer draws it.
                        list

                    else
                        boardTileInFront
                            cellSize2
                            (Coord.xy (boardX windowSize + cellSize2 * x) (boardY + cellSize2 * y))
                            (if isWildcard then
                                Wildcard

                             else
                                Letter letter
                            )
                            :: list
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
                            (\index ( ( x, y ), letter ) ->
                                animatedTilePlacement isPreviousPlayer elapsed placement.isValid tileCount index
                                    |> Maybe.map
                                        (\{ progress, red } ->
                                            let
                                                startX : Int
                                                startX =
                                                    boardX windowSize - cellSize2

                                                startY =
                                                    boardY - cellSize2

                                                destX : Int
                                                destX =
                                                    boardX windowSize + cellSize2 * x

                                                destY : Int
                                                destY =
                                                    boardY + cellSize2 * y
                                            in
                                            animatedTileInFront
                                                cellSize2
                                                (Coord.xy
                                                    (round (toFloat startX + progress * toFloat (destX - startX)))
                                                    (round (toFloat startY + progress * toFloat (destY - startY)))
                                                )
                                                red
                                                (Letter letter)
                                        )
                            )
                            placement.cells
                            |> List.filterMap identity

                    else
                        []

                Nothing ->
                    []

        trayTiles : List (Ui.Attribute GameMsg)
        trayTiles =
            List.map2
                Tuple.pair
                (Array.toList model.tiles)
                (case getPlayer currentUserId shared of
                    Just player ->
                        IdArray.toList player.tray

                    Nothing ->
                        []
                )
                |> List.indexedMap
                    (\index ( tile, letter ) ->
                        case ( maybeDragging, Just index == model.dragging ) of
                            ( Just dragging2, True ) ->
                                let
                                    center : Coord CssPixels
                                    center =
                                        Touch.touchCentroid dragging2
                                in
                                tileInFront
                                    currentTime
                                    tile.createdAt
                                    cellSize2
                                    (Coord.xy
                                        (Coord.xRaw center - cellSize2 // 2)
                                        (Coord.yRaw center - cellSize2 // 2)
                                    )
                                    letter

                            _ ->
                                case tile.position of
                                    TileInTray trayIndex shiftAnimation ->
                                        tileInFront
                                            currentTime
                                            tile.createdAt
                                            trayTileSize
                                            (animatedTrayTilePos windowSize currentTime trayIndex shiftAnimation)
                                            letter

                                    TileOnBoard ( x, y ) ->
                                        tileInFront
                                            currentTime
                                            tile.createdAt
                                            cellSize2
                                            (Coord.xy (boardX windowSize + cellSize2 * x) (boardY + cellSize2 * y))
                                            letter
                    )

        dragHighlight : Ui.Attribute GameMsg
        dragHighlight =
            case ( model.dragging, maybeDragging ) of
                ( Just _, Just dragging2 ) ->
                    case cellAtPosition windowSize (Touch.touchCentroid dragging2) of
                        Just ( x, y ) ->
                            if
                                SeqDict.member ( x, y ) shared.board
                                    || Array.Extra.any (\tile -> tile.position == TileOnBoard ( x, y )) model.tiles
                            then
                                Ui.noAttr

                            else
                                Ui.inFront
                                    (Ui.el
                                        [ Ui.borderColor (Ui.rgb 0 200 255)
                                        , Ui.border 3
                                        , Ui.width (Ui.px cellSize2)
                                        , Ui.height (Ui.px cellSize2)
                                        , Ui.move { x = boardX windowSize + x * cellSize2, y = boardY + y * cellSize2, z = 0 }
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
                    Ui.inFront
                        (Ui.el
                            [ Ui.borderColor (Ui.rgb 0 200 255)
                            , Ui.border 4
                            , Ui.width (Ui.px cellSize2)
                            , Ui.height (Ui.px cellSize2)
                            , Ui.move { x = x * cellSize2, y = y * cellSize2, z = 0 }
                            , MyUi.noPointerEvents
                            ]
                            Ui.none
                        )

                Nothing ->
                    Ui.noAttr

        trayWidth : Int
        trayWidth =
            Coord.xRaw (trayTilePos windowSize (TrayIndex (OneOrGreater.toInt setup.traySize))) - trayX windowSize
    in
    Ui.el
        [ Ui.width Ui.shrink
        , Ui.height (Ui.px (gridSize * cellSize2 + trayHeight))
        , Ui.pointer
        , Ui.el
            (Ui.move { x = -(boardX windowSize), y = -boardY, z = 0 }
                :: trayTiles
                ++ boardTiles
                ++ animatedTiles
                ++ [ selectedHighlight
                   , dragHighlight
                   , Ui.inFront
                        (Ui.el
                            [ Ui.background (Ui.rgb 119 97 97)
                            , Ui.move { x = trayX windowSize, y = trayY windowSize, z = 0 }
                            , Ui.width (Ui.px trayWidth)
                            , Ui.height (Ui.px (trayHeight + 4))
                            ]
                            Ui.none
                        )
                   ]
            )
            Ui.none
            |> Ui.inFront
        ]
        (Ui.Lazy.lazy boardViewBackground cellSize2)


tileInFront : Time.Posix -> Time.Posix -> Int -> Coord CssPixels -> LetterOrWildcard -> Ui.Attribute GameMsg
tileInFront currentTime createdAt cellSize2 offset letterOrWildcard =
    let
        fade : { opacity : Float, drift : Float }
        fade =
            tileFade currentTime createdAt
    in
    Ui.inFront
        (Ui.el
            [ Ui.background (Ui.rgb 240 220 130)
            , Ui.width (Ui.px cellSize2)
            , Ui.height (Ui.px cellSize2)
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
            , tileScoreView cellSize2 letterOrWildcard
            ]
            (Ui.text (letterOrWildcardText letterOrWildcard))
        )


boardTileInFront : Int -> Coord CssPixels -> LetterOrWildcard -> Ui.Attribute GameMsg
boardTileInFront cellSize2 offset letterOrWildcard =
    Ui.inFront
        (Ui.el
            [ Ui.background (Ui.rgb 186 171 103)
            , Ui.width (Ui.px cellSize2)
            , Ui.height (Ui.px cellSize2)
            , Ui.contentCenterX
            , Ui.contentCenterY
            , toFloat cellSize2 * 0.7 |> ceiling |> Ui.Font.size
            , Ui.Font.bold
            , Ui.move { x = Coord.xRaw offset, y = Coord.yRaw offset, z = 0 }
            , Ui.Font.color (Ui.rgb 0 0 0)
            , MyUi.noPointerEvents
            , tileScoreView cellSize2 letterOrWildcard
            ]
            (Ui.text (letterOrWildcardText letterOrWildcard))
        )


tileScoreView : Int -> LetterOrWildcard -> Ui.Attribute msg
tileScoreView cellSize2 letterOrWildcard =
    Ui.text
        (case letterOrWildcard of
            Letter letter ->
                letterData letter |> .score |> String.fromInt

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
animatedTileInFront : Int -> Coord CssPixels -> Bool -> LetterOrWildcard -> Ui.Attribute GameMsg
animatedTileInFront cellSize2 offset red letterOrWildcard =
    Ui.inFront
        (Ui.el
            [ Ui.background
                (if red then
                    Ui.rgb 214 69 69

                 else
                    Ui.rgb 186 171 103
                )
            , Ui.width (Ui.px cellSize2)
            , Ui.height (Ui.px cellSize2)
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
            , tileScoreView cellSize2 letterOrWildcard
            ]
            (Ui.text (letterOrWildcardText letterOrWildcard))
        )


letterOrWildcardText : LetterOrWildcard -> String
letterOrWildcardText letterOrWildcard =
    case letterOrWildcard of
        Letter letter ->
            (letterData letter).text

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


cellSize : Coord CssPixels -> Int
cellSize windowSize =
    if MyUi.isMobile { windowSize = windowSize } then
        Coord.xRaw windowSize // gridSize

    else
        30


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
        , Ui.border 1
        , Ui.borderColor MyUi.inputBorder
        , Ui.contentCenterX
        , Ui.contentCenterY
        ]
        (case maybeBonus of
            Just CenterCell ->
                Ui.el
                    [ Ui.centerX
                    , Ui.centerY
                    , Ui.Font.size 20
                    , Ui.Font.color (Ui.rgb 0 0 0)
                    ]
                    (Ui.text "★")

            _ ->
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
        , Ui.padding
            (if isMobile then
                12

             else
                24
            )
        , Ui.background MyUi.tabBackground
        ]
        [ setupSection
            "Tray size (letters each player holds)"
            (numberInput
                { htmlId = "wsg_traySizeInput"
                , minValue = 1
                , maxValue = 20
                , value = String.fromInt setup.traySize
                , onChange = ChangedTraySizeInput
                }
            )
        , setupSection
            "Time control"
            (Ui.row [ Ui.spacing 8, Ui.width Ui.shrink, Ui.contentBottom ]
                [ timeInput "wsg_mainTimeInput" "Main time (minutes)" setup.mainTimeInput ChangedMainTimeInput
                , timeInput "wsg_incrementInput" "Increment (seconds)" setup.incrementInput ChangedIncrementInput
                ]
            )
        , setupSection
            "Letter distribution (spaces are wildcards)"
            (Ui.column [ Ui.spacing 8, Ui.width Ui.shrink ]
                [ lettersInput setup.letters
                , if setup.letters == defaultLetters then
                    Ui.none

                  else
                    MyUi.simpleButton (Dom.id "wsg_resetLetters") PressedResetLetters (Ui.text "Reset to default")
                ]
            )
        , case setup.error of
            Just error ->
                Ui.el [ Ui.Font.color (Ui.rgb 200 50 50) ] (Ui.text error)

            Nothing ->
                Ui.none
        , MyUi.simpleButton (Dom.id "wsg_start") PressedStartGame (Ui.text "Start game")
        ]


setupSection : String -> Element SetupMsg -> Element SetupMsg
setupSection title content =
    Ui.column
        [ Ui.spacing 8 ]
        [ Ui.el [ Ui.Font.weight 600 ] (Ui.text title)
        , content
        ]


numberInput :
    { htmlId : String
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
        , Html.Attributes.style "width" "50px"
        , Html.Attributes.style "padding" "8px"
        , Html.Attributes.style "border" ("1px solid " ++ MyUi.colorToStyle MyUi.inputBorder)
        , Html.Attributes.style "border-radius" "4px"
        , Html.Events.onInput args.onChange
        ]
        []
        |> Ui.html


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


allLetters : List Letter
allLetters =
    [ A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z ]


{-| How many wildcards (blank tiles) the standard Scrabble distribution has.
-}
defaultWildcardCount : Int
defaultWildcardCount =
    2


{-| The standard Scrabble letter distribution, written as a single long string. Each wildcard is a
space and each letter appears in lowercase as many times as it occurs in the bag, e.g.
`"  aaaaaaaaabbccdddd..."` (two wildcards followed by nine a's, two b's and so on).
-}
defaultLetters : String
defaultLetters =
    String.repeat defaultWildcardCount " "
        ++ (List.map
                (\letter ->
                    String.repeat (OneOrGreater.toInt (letterData letter).total) (String.toLower (letterData letter).text)
                )
                allLetters
                |> String.concat
           )


{-| Read a letter distribution string back into a count of each tile. Spaces are wildcards and any
letter (in either case) is counted; any other character is ignored. Fails if there isn't at least
one (non-wildcard) letter, since words can't be formed out of wildcards alone.
-}
parseLetters : String -> Result String (NonemptyDict LetterOrWildcard OneOrGreater)
parseLetters string =
    let
        counts : SeqDict LetterOrWildcard OneOrGreater
        counts =
            String.foldl
                (\char acc ->
                    if char == ' ' then
                        SeqDictHelper.increment Wildcard acc

                    else
                        case charToLetter char of
                            Just letter ->
                                SeqDictHelper.increment (Letter letter) acc

                            Nothing ->
                                acc
                )
                SeqDict.empty
                string
    in
    case NonemptyDict.fromSeqDict counts of
        Just nonempty ->
            if List.any isLetter (SeqDict.keys counts) then
                Ok nonempty

            else
                Err "Letters: enter at least one letter (A-Z)"

        Nothing ->
            Err "Letters: enter at least one letter (A-Z)"


charToLetter : Char -> Maybe Letter
charToLetter char =
    List.Extra.find
        (\letter -> (letterData letter).text == String.fromChar (Char.toUpper char))
        allLetters


isLetter : LetterOrWildcard -> Bool
isLetter letterOrWildcard =
    case letterOrWildcard of
        Letter _ ->
            True

        Wildcard ->
            False


type alias LetterData =
    { score : Int
    , text : String

    -- The number of this letter in the standard Scrabble distribution, used as the default letter
    -- distribution in the game setup.
    , total : OneOrGreater
    }


letterData : Letter -> LetterData
letterData letter =
    case letter of
        A ->
            { score = 1, text = "A", total = OneOrGreater.nine }

        B ->
            { score = 3, text = "B", total = OneOrGreater.two }

        C ->
            { score = 3, text = "C", total = OneOrGreater.two }

        D ->
            { score = 2, text = "D", total = OneOrGreater.four }

        E ->
            { score = 1, text = "E", total = OneOrGreater.twelve }

        F ->
            { score = 4, text = "F", total = OneOrGreater.two }

        G ->
            { score = 2, text = "G", total = OneOrGreater.three }

        H ->
            { score = 4, text = "H", total = OneOrGreater.two }

        I ->
            { score = 1, text = "I", total = OneOrGreater.nine }

        J ->
            { score = 8, text = "J", total = OneOrGreater.one }

        K ->
            { score = 5, text = "K", total = OneOrGreater.one }

        L ->
            { score = 1, text = "L", total = OneOrGreater.four }

        M ->
            { score = 3, text = "M", total = OneOrGreater.two }

        N ->
            { score = 1, text = "N", total = OneOrGreater.six }

        O ->
            { score = 1, text = "O", total = OneOrGreater.eight }

        P ->
            { score = 3, text = "P", total = OneOrGreater.two }

        Q ->
            { score = 10, text = "Q", total = OneOrGreater.one }

        R ->
            { score = 1, text = "R", total = OneOrGreater.six }

        S ->
            { score = 1, text = "S", total = OneOrGreater.four }

        T ->
            { score = 1, text = "T", total = OneOrGreater.six }

        U ->
            { score = 1, text = "U", total = OneOrGreater.four }

        V ->
            { score = 4, text = "V", total = OneOrGreater.two }

        W ->
            { score = 4, text = "W", total = OneOrGreater.two }

        X ->
            { score = 8, text = "X", total = OneOrGreater.one }

        Y ->
            { score = 4, text = "Y", total = OneOrGreater.two }

        Z ->
            { score = 10, text = "Z", total = OneOrGreater.one }


type Letter
    = A
    | B
    | C
    | D
    | E
    | F
    | G
    | H
    | I
    | J
    | K
    | L
    | M
    | N
    | O
    | P
    | Q
    | R
    | S
    | T
    | U
    | V
    | W
    | X
    | Y
    | Z
