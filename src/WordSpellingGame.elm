module WordSpellingGame exposing
    ( Action
    , ActionWithTime
    , GameData
    , GameMsg
    , Letter
    , LetterOrWildcard
    , LocalChange(..)
    , Model(..)
    , OutMsg(..)
    , PlacedWord
    , Player
    , SetupModel
    , SetupMsg
    , Shared
    , Tile
    , TilePosition
    , UserStatus(..)
    , ValidatedSetup
    , dragEnd
    , dragStart
    , foldActions
    , gameView
    , initGame
    , initSetup
    , insideBoard
    , isPlayerTurn
    , setupView
    , updateAction
    , updateGame
    , updateSetup
    )

{-| Were calling it this to avoid the Scrabble trademark
-}

import Array exposing (Array)
import Array.Extra
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
import List.Extra
import List.Nonempty exposing (Nonempty(..))
import MyUi
import NonemptyDict exposing (NonemptyDict)
import NonemptyExtra
import OneOrGreater exposing (OneOrGreater)
import Random
import SeqDict exposing (SeqDict)
import SeqDictHelper
import Touch exposing (Touch)
import Ui exposing (Element)
import Ui.Font
import Ui.Lazy


type Model
    = Setup SetupModel
    | Game GameData


type alias GameData =
    { selectedCell : Maybe ( Int, Int )
    , tiles : Array Tile
    , dragging : Maybe Int
    }


type alias Tile =
    { position : TilePosition }


type TilePosition
    = TileInTray TrayIndex
    | TileOnBoard ( Int, Int )


type TrayIndex
    = TrayIndex Int


type SetupMsg
    = ChangedMainTimeInput String
    | ChangedIncrementInput String
    | ChangedTraySizeInput String
    | PressedStartGame


type GameMsg
    = PressedSubmitWord
    | PressedJoinGame
    | PressedReplaceTray


type alias SetupModel =
    { mainTimeInput : String
    , incrementInput : String
    , traySize : Int
    , error : Maybe String
    }


type alias ValidatedSetup =
    { timeControls : TimeControl
    , traySize : OneOrGreater
    , createdBy : Id UserId
    , seed : Int
    }


initSetup : SetupModel
initSetup =
    { mainTimeInput = "10"
    , incrementInput = "5"
    , traySize = 7
    , error = Nothing
    }


initGame : ValidatedSetup -> GameData
initGame setup =
    { selectedCell = Nothing
    , tiles =
        List.range 0 (OneOrGreater.toInt setup.traySize - 1)
            |> List.map (\index -> { position = TileInTray (TrayIndex index) })
            |> Array.fromList
    , dragging = Nothing
    }


type OutMsg
    = OutLocalChange LocalChange


type LocalChange
    = StartMatch Time.Posix ValidatedSetup
    | Action ActionWithTime


type Action
    = PlaceWord PlacedWord
    | ReplaceTray
    | JoinGame


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
    }


type alias Player =
    { userId : Id UserId
    , tray : List LetterOrWildcard
    , score : Int
    }


gridSize : number
gridSize =
    15


type LetterOrWildcard
    = Letter Letter
    | Wildcard


initGameState : ValidatedSetup -> Shared
initGameState setup =
    let
        initialBoard : SeqDict ( Int, Int ) { letter : Letter, isWildcard : Bool }
        initialBoard =
            SeqDict.empty
    in
    { board = initialBoard
    , players = Nonempty (initPlayer setup.createdBy initialBoard setup []) []
    , turnCount = 0
    }


getLetters :
    OneOrGreater
    -> ValidatedSetup
    -> SeqDict ( Int, Int ) { letter : Letter, isWildcard : Bool }
    -> List Player
    -> Int
    -> List LetterOrWildcard
getLetters count setup board players turnCount =
    let
        startingLetters : SeqDict LetterOrWildcard OneOrGreater
        startingLetters =
            ( Wildcard, OneOrGreater.two )
                :: List.map (\letter -> ( Letter letter, (letterData letter).total )) allLetters
                |> SeqDict.fromList

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
                startingLetters
                board

        remainingLetters3 : SeqDict LetterOrWildcard OneOrGreater
        remainingLetters3 =
            List.foldl
                (\player remainingLetters2 -> List.foldl SeqDictHelper.decrement remainingLetters2 player.tray)
                remainingLetters
                players
    in
    Random.step
        (SeqDict.foldl
            (\letter count2 list -> List.repeat (OneOrGreater.toInt count2) letter ++ list)
            []
            remainingLetters3
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


foldActions : ValidatedSetup -> Array ActionWithTime -> Shared
foldActions setup actions =
    Array.foldl (updateAction setup) (initGameState setup) actions


updateAction : ValidatedSetup -> ActionWithTime -> Shared -> Shared
updateAction setup action state =
    case action.change of
        PlaceWord { start, isVertical, letters } ->
            let
                placement : Placement
                placement =
                    walkPlacement
                        state.board
                        start
                        (if isVertical then
                            ( 0, 1 )

                         else
                            ( 1, 0 )
                        )
                        (List.Nonempty.toList letters)

                totalScore : Int
                totalScore =
                    placement.lettersScore * placement.wordMultiplier
            in
            { state
                | board = placement.board
                , players =
                    NonemptyExtra.update
                        state.turnCount
                        (\player ->
                            let
                                remainingTray : List LetterOrWildcard
                                remainingTray =
                                    List.foldl removeFromTray player.tray (List.map Letter placement.placedLetters)

                                drawn : List LetterOrWildcard
                                drawn =
                                    case OneOrGreater.fromInt (OneOrGreater.toInt setup.traySize - List.length remainingTray) of
                                        Just drawCount ->
                                            getLetters
                                                drawCount
                                                setup
                                                placement.board
                                                (NonemptyExtra.set state.turnCount { player | tray = remainingTray } state.players
                                                    |> List.Nonempty.toList
                                                )
                                                state.turnCount

                                        Nothing ->
                                            []
                            in
                            { player | tray = remainingTray ++ drawn, score = player.score + totalScore }
                        )
                        state.players
                , turnCount = state.turnCount + 1
            }

        ReplaceTray ->
            { state
                | players =
                    NonemptyExtra.update
                        state.turnCount
                        (\player ->
                            { player
                                | tray =
                                    getLetters
                                        setup.traySize
                                        setup
                                        state.board
                                        (NonemptyExtra.set state.turnCount { player | tray = [] } state.players
                                            |> List.Nonempty.toList
                                        )
                                        state.turnCount
                            }
                        )
                        state.players
                , turnCount = state.turnCount + 1
            }

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
    , tray = getLetters setup.traySize setup board existingPlayers 0
    , score = 0
    }


type alias Placement =
    { board : SeqDict ( Int, Int ) { letter : Letter, isWildcard : Bool }
    , lettersScore : Int
    , wordMultiplier : Int
    , placedLetters : List Letter
    }


{-| Lay a word's new letters out along the direction starting from `start`, stepping over any
tiles already on the board (which count toward the score but aren't placed again), and tallying
the score using the bonus squares the new letters land on.
-}
walkPlacement : SeqDict ( Int, Int ) { letter : Letter, isWildcard : Bool } -> ( Int, Int ) -> ( Int, Int ) -> List Letter -> Placement
walkPlacement committedBoard start ( dx, dy ) letters =
    let
        go : ( Int, Int ) -> List Letter -> Placement -> Placement
        go ( cx, cy ) remaining acc =
            case remaining of
                [] ->
                    acc

                letter :: rest ->
                    if cx < 0 || cy < 0 || cx >= gridSize || cy >= gridSize then
                        acc

                    else
                        case SeqDict.get ( cx, cy ) committedBoard of
                            Just existing ->
                                go ( cx + dx, cy + dy )
                                    remaining
                                    { acc | lettersScore = acc.lettersScore + (letterData existing.letter).score }

                            Nothing ->
                                go ( cx + dx, cy + dy )
                                    rest
                                    { board = SeqDict.insert ( cx, cy ) { letter = letter, isWildcard = False } acc.board
                                    , lettersScore = acc.lettersScore + (letterData letter).score * letterScoreMultiplier ( cx, cy )
                                    , wordMultiplier = acc.wordMultiplier * wordScoreMultiplier ( cx, cy )
                                    , placedLetters = letter :: acc.placedLetters
                                    }
    in
    go start letters { board = committedBoard, lettersScore = 0, wordMultiplier = 1, placedLetters = [] }


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

        PressedStartGame ->
            case validateSetup currentUserId time setup of
                Ok validated ->
                    ( Game (initGame validated), [ OutLocalChange (StartMatch time validated) ] )

                Err error ->
                    ( Setup { setup | error = Just error }, [] )


updateGame : Time.Posix -> Id UserId -> Shared -> GameMsg -> GameData -> ( GameData, List OutMsg )
updateGame time currentUserId shared msg model =
    case msg of
        PressedSubmitWord ->
            case checkValidPlacement currentUserId shared model of
                Ok placement ->
                    ( { model
                        | tiles =
                            Array.foldl
                                (\tile ( index, tiles ) ->
                                    ( index + 1
                                    , Array.set
                                        index
                                        { tile
                                            | position =
                                                case tile.position of
                                                    TileInTray _ ->
                                                        tile.position

                                                    TileOnBoard _ ->
                                                        firstOpenTrayIndex index tiles |> TileInTray
                                        }
                                        tiles
                                    )
                                )
                                ( 0, model.tiles )
                                model.tiles
                                |> Tuple.second
                      }
                    , [ OutLocalChange (Action { userId = currentUserId, change = PlaceWord placement, time = time }) ]
                    )

                Err () ->
                    ( model, [] )

        PressedJoinGame ->
            ( model, [ OutLocalChange (Action { userId = currentUserId, change = JoinGame, time = time }) ] )

        PressedReplaceTray ->
            ( model, [ OutLocalChange (Action { userId = currentUserId, change = ReplaceTray, time = time }) ] )


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
                    List.map2 Tuple.pair (Array.toList notShared.tiles) player.tray
                        |> List.filterMap
                            (\( tile, letter ) ->
                                case tile.position of
                                    TileOnBoard cell ->
                                        Just ( cell, letter )

                                    TileInTray _ ->
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
                    Ok
                        { createdBy = createdBy
                        , timeControls = timeControls
                        , traySize = traySize
                        , seed =
                            -- Round the time to the nearest 10 seconds so that small timing changes don't break an end-to-end test
                            Time.posixToMillis time // 10000 |> (*) 10000 |> (+) (Id.toInt createdBy)
                        }

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
    MyUi.matchSwitcherHeight + MyUi.channelHeaderHeight


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


insideBoard : Coord CssPixels -> Coord CssPixels -> ( ValidatedSetup, Shared, GameData ) -> Bool
insideBoard windowSize coord _ =
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


dragStart : Coord CssPixels -> NonemptyDict Int Touch -> ( ValidatedSetup, Shared, GameData ) -> Model
dragStart windowSize touches ( setup, _, gameModel ) =
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

                            TileInTray _ ->
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

                                    TileInTray trayIndex ->
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


dragEnd : Coord CssPixels -> NonemptyDict Int Touch -> ( ValidatedSetup, Shared, GameData ) -> Model
dragEnd windowSize newTouches ( _, gameState, gameModel ) =
    case gameModel.dragging of
        Just tileIndex ->
            let
                position : Coord CssPixels
                position =
                    Touch.touchCentroid newTouches

                returnToTray : Model
                returnToTray =
                    Game
                        { gameModel
                            | dragging = Nothing
                            , tiles =
                                Array.Extra.update
                                    tileIndex
                                    (\tile -> { tile | position = TileInTray (firstOpenTrayIndex tileIndex gameModel.tiles) })
                                    gameModel.tiles
                        }
            in
            case cellAtPosition windowSize position of
                Just cell ->
                    if SeqDict.member cell gameState.board || cellOccupiedByOtherTile tileIndex cell gameModel.tiles then
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
firstOpenTrayIndex : Int -> Array Tile -> TrayIndex
firstOpenTrayIndex draggedIndex tiles =
    let
        occupied : List Int
        occupied =
            Array.toIndexedList tiles
                |> List.filterMap
                    (\( index, tile ) ->
                        if index == draggedIndex then
                            Nothing

                        else
                            case tile.position of
                                TileInTray (TrayIndex trayIndex) ->
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


gameView :
    Coord CssPixels
    -> Maybe (NonemptyDict Int Touch)
    -> Id UserId
    -> Shared
    -> GameData
    -> Element GameMsg
gameView windowSize maybeDragging currentUserId shared model =
    Ui.column
        [ Ui.spacing 16 ]
        [ boardView windowSize maybeDragging currentUserId shared model
        , statusView currentUserId shared
        , case isPlayerTurn currentUserId shared of
            JoinedAndItsTheirTurn ->
                Ui.row
                    [ Ui.spacing 16 ]
                    [ MyUi.simpleButton (Dom.id "wordSpellingGame_submitWord") PressedSubmitWord (Ui.text "Submit word")
                    , MyUi.simpleButton (Dom.id "wordSpellingGame_replaceTray") PressedReplaceTray (Ui.text "Replace tray")
                    ]

            Joined ->
                Ui.none

            NotJoined ->
                MyUi.simpleButton (Dom.id "wordSpellingGame_joinGame") PressedJoinGame (Ui.text "Join game")
        ]


statusView : Id UserId -> Shared -> Element GameMsg
statusView currentUserId shared =
    let
        currentPlayer : Player
        currentPlayer =
            List.Nonempty.get shared.turnCount shared.players

        playerCount =
            List.Nonempty.length shared.players
    in
    Ui.column
        [ Ui.spacing 4, Ui.paddingXY 16 0 ]
        (List.Nonempty.toList shared.players
            |> List.indexedMap
                (\index player ->
                    (if player.userId == currentUserId then
                        "You"

                     else
                        "Opponent"
                    )
                        ++ ": "
                        ++ String.fromInt player.score
                        ++ (if index == modBy playerCount shared.turnCount then
                                if player.userId == currentUserId then
                                    " (your turn)"

                                else
                                    " (their turn)"

                            else
                                ""
                           )
                        |> Ui.text
                        |> Ui.el
                            [ if player.userId == currentPlayer.userId then
                                Ui.Font.weight 700

                              else
                                Ui.Font.weight 400
                            ]
                )
        )


trayHeight : number
trayHeight =
    trayTileSize


boardView : Coord CssPixels -> Maybe (NonemptyDict Int Touch) -> Id UserId -> Shared -> GameData -> Element GameMsg
boardView windowSize maybeDragging currentUserId shared model =
    let
        cellSize2 : Int
        cellSize2 =
            cellSize windowSize

        boardTiles : List (Ui.Attribute GameMsg)
        boardTiles =
            SeqDict.foldl
                (\( x, y ) { letter, isWildcard } list ->
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

        trayTiles : List (Ui.Attribute GameMsg)
        trayTiles =
            List.map2
                Tuple.pair
                (Array.toList model.tiles)
                (case getPlayer currentUserId shared of
                    Just player ->
                        player.tray

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
                                    cellSize2
                                    (Coord.xy
                                        (Coord.xRaw center - cellSize2 // 2)
                                        (Coord.yRaw center - cellSize2 // 2)
                                    )
                                    letter

                            _ ->
                                case tile.position of
                                    TileInTray trayIndex ->
                                        tileInFront
                                            trayTileSize
                                            (trayTilePos windowSize trayIndex)
                                            letter

                                    TileOnBoard ( x, y ) ->
                                        tileInFront
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
    in
    Ui.el
        [ Ui.width Ui.shrink
        , Ui.height (Ui.px (gridSize * cellSize2 + trayHeight))
        , Ui.pointer
        , Ui.el
            (Ui.move { x = -(boardX windowSize), y = -boardY, z = 0 }
                :: trayTiles
                ++ boardTiles
                ++ [ selectedHighlight, dragHighlight ]
            )
            Ui.none
            |> Ui.inFront
        ]
        (Ui.Lazy.lazy boardViewBackground cellSize2)


tileInFront : Int -> Coord CssPixels -> LetterOrWildcard -> Ui.Attribute GameMsg
tileInFront cellSize2 offset letterOrWildcard =
    Ui.inFront
        (Ui.el
            [ Ui.background (Ui.rgb 240 220 130)
            , Ui.width (Ui.px cellSize2)
            , Ui.height (Ui.px cellSize2)
            , Ui.contentCenterX
            , Ui.contentCenterY
            , toFloat cellSize2 * 0.7 |> ceiling |> Ui.Font.size
            , Ui.Font.bold
            , Ui.move { x = Coord.xRaw offset, y = Coord.yRaw offset, z = 0 }
            , Ui.Font.color (Ui.rgb 0 0 0)
            , MyUi.noPointerEvents
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


type alias LetterData =
    { score : Int
    , text : String
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
