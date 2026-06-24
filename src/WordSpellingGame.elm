module WordSpellingGame exposing
    ( Action
    , ActionWithTime
    , GameModel
    , GameState
    , LocalChange(..)
    , Model(..)
    , Msg(..)
    , OutMsg(..)
    , Player
    , SetupModel
    , ValidatedSetup
    , dragEnd
    , dragStart
    , dragging
    , foldActions
    , gameView
    , initGame
    , initSetup
    , insideBoard
    , setupView
    , update
    , validateSetup
    )

{-| Were calling it this to avoid the Scrabble trademark
-}

import Array exposing (Array)
import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Duration
import Effect.Browser.Dom as Dom
import Effect.Time as Time
import Go exposing (TimeControl)
import Html
import Html.Attributes
import Html.Events
import Id exposing (ChannelMessageId, Id, UserId)
import List.Extra
import List.Nonempty exposing (Nonempty(..))
import MyUi
import NonemptyDict exposing (NonemptyDict)
import NonemptyExtra
import OneOrGreater exposing (OneOrGreater)
import Point2d
import Random
import SeqDict exposing (SeqDict)
import SeqDictHelper
import Touch exposing (Touch)
import Ui exposing (Element)
import Ui.Events
import Ui.Font
import Ui.Lazy


type Model
    = Setup SetupModel
    | Game GameModel


type alias GameModel =
    { selectedCell : Maybe ( Int, Int )
    , placedTiles : SeqDict ( Int, Int ) PlacedTile
    , dragging : Maybe DraggingTile
    }


{-| A tile the local player has dragged onto the board this turn but hasn't submitted yet.
`trayIndex` is the slot in the player's tray it came from.
-}
type alias PlacedTile =
    { trayIndex : Int
    , letterOrWildcard : LetterOrWildcard
    }


type alias DraggingTile =
    { trayIndex : Int
    , letterOrWildcard : LetterOrWildcard
    , position : Coord CssPixels
    }


type Msg
    = GameMsg GameMsg
    | ChangedMainTimeInput String
    | ChangedIncrementInput String
    | ChangedTraySizeInput String
    | PressedStartGame


type GameMsg
    = PressedGridCell ( Int, Int )


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


initGame : GameModel
initGame =
    { selectedCell = Nothing, placedTiles = SeqDict.empty, dragging = Nothing }


type OutMsg
    = OutLocalChange LocalChange


type LocalChange
    = StartMatch Time.Posix ValidatedSetup
    | Action ActionWithTime


type Action
    = PlaceWord ( Int, Int ) Direction (Nonempty Letter)
    | ReplaceTray


type alias ActionWithTime =
    { time : Time.Posix, change : Action }


type alias GameState =
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


type Direction
    = Left
    | Right
    | Up
    | Down


type LetterOrWildcard
    = Letter Letter
    | Wildcard


initGameState : ValidatedSetup -> GameState
initGameState setup =
    let
        initialBoard : SeqDict ( Int, Int ) { letter : Letter, isWildcard : Bool }
        initialBoard =
            SeqDict.empty
    in
    { board = initialBoard
    , players =
        Nonempty
            { userId = setup.createdBy
            , tray = getLetters setup.traySize setup initialBoard [] 0
            , score = 0
            }
            []
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


foldActions : ValidatedSetup -> Array ActionWithTime -> GameState
foldActions setup actions =
    Array.foldl (updateAction setup) (initGameState setup) actions


updateAction : ValidatedSetup -> ActionWithTime -> GameState -> GameState
updateAction setup action state =
    case action.change of
        PlaceWord start direction letters ->
            let
                placement : Placement
                placement =
                    walkPlacement state.board start (directionDelta direction) (List.Nonempty.toList letters)

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


type alias Placement =
    { board : SeqDict ( Int, Int ) { letter : Letter, isWildcard : Bool }
    , lettersScore : Int
    , wordMultiplier : Int
    , placedLetters : List Letter
    }


directionDelta : Direction -> ( Int, Int )
directionDelta direction =
    case direction of
        Left ->
            ( -1, 0 )

        Right ->
            ( 1, 0 )

        Up ->
            ( 0, -1 )

        Down ->
            ( 0, 1 )


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


update : Time.Posix -> Id UserId -> Msg -> Model -> ( Maybe Model, List OutMsg )
update time currentUserId msg model =
    case msg of
        ChangedMainTimeInput input ->
            ( updateSetup (\setup -> { setup | mainTimeInput = input, error = Nothing }) model |> Just, [] )

        ChangedIncrementInput input ->
            ( updateSetup (\setup -> { setup | incrementInput = input, error = Nothing }) model |> Just, [] )

        ChangedTraySizeInput input ->
            ( updateSetup
                (\setup ->
                    { setup
                        | traySize = String.toInt (String.trim input) |> Maybe.withDefault setup.traySize
                        , error = Nothing
                    }
                )
                model
                |> Just
            , []
            )

        PressedStartGame ->
            case model of
                Setup setup ->
                    case validateSetup currentUserId time setup of
                        Ok validated ->
                            ( Just (Game initGame), [ OutLocalChange (StartMatch time validated) ] )

                        Err error ->
                            ( Just (Setup { setup | error = Just error }), [] )

                Game _ ->
                    ( Just model, [] )

        GameMsg gameMsg ->
            let
                ( gameModel, outMsgs ) =
                    updateGame
                        gameMsg
                        (case model of
                            Setup _ ->
                                initGame

                            Game game ->
                                game
                        )
            in
            ( Game gameModel |> Just, outMsgs )


updateGame : GameMsg -> GameModel -> ( GameModel, List OutMsg )
updateGame msg model =
    case msg of
        PressedGridCell pos ->
            ( { model | selectedCell = Just pos }, [] )


updateSetup : (SetupModel -> SetupModel) -> Model -> Model
updateSetup function model =
    case model of
        Setup setup ->
            Setup (function setup)

        Game _ ->
            model


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


insideBoard : Coord CssPixels -> Coord CssPixels -> ( ValidatedSetup, GameState, GameModel ) -> Bool
insideBoard windowSize coord _ =
    let
        x =
            boardX windowSize

        _ =
            Debug.log "" ( coord, x, boardY )
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


trayTileSpacing =
    4


trayTileX : Coord CssPixels -> Int -> Int
trayTileX windowSize index =
    boardX windowSize + index * (trayTileSize + trayTileSpacing)


trayTileY : Coord CssPixels -> Int -> Int
trayTileY windowSize index =
    trayY windowSize


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


currentPlayerTray : Id UserId -> GameState -> List LetterOrWildcard
currentPlayerTray userId gameState =
    List.Extra.find (\player -> player.userId == userId) (List.Nonempty.toList gameState.players)
        |> Maybe.map .tray
        |> Maybe.withDefault []


{-| A tray slot is in use if its tile is currently on the board or being dragged.
-}
trayIndexInUse : GameModel -> Int -> Bool
trayIndexInUse gameModel index =
    List.any (\placed -> placed.trayIndex == index) (SeqDict.values gameModel.placedTiles)
        || ((gameModel.dragging |> Maybe.map .trayIndex) == Just index)


dragStart : Coord CssPixels -> Id UserId -> NonemptyDict Int Touch -> ( ValidatedSetup, GameState, GameModel ) -> Model
dragStart windowSize currentUserId touches ( _, gameState, gameModel ) =
    let
        position : Coord CssPixels
        position =
            Touch.touchCentroid touches
    in
    case cellAtPosition windowSize position of
        Just cell ->
            -- Pick a tile we placed this turn back up off the board.
            case SeqDict.get cell gameModel.placedTiles of
                Just placed ->
                    Game
                        { gameModel
                            | dragging =
                                Just
                                    { trayIndex = placed.trayIndex
                                    , letterOrWildcard = placed.letterOrWildcard
                                    , position = position
                                    }
                            , placedTiles = SeqDict.remove cell gameModel.placedTiles
                        }

                Nothing ->
                    Game gameModel

        Nothing ->
            let
                tray : List LetterOrWildcard
                tray =
                    currentPlayerTray currentUserId gameState
            in
            case trayIndexAtPosition windowSize position (List.length tray) of
                Just index ->
                    case ( trayIndexInUse gameModel index, List.Extra.getAt index tray ) of
                        ( False, Just letterOrWildcard ) ->
                            Game
                                { gameModel
                                    | dragging =
                                        Just
                                            { trayIndex = index
                                            , letterOrWildcard = letterOrWildcard
                                            , position = position
                                            }
                                }

                        _ ->
                            Game gameModel

                Nothing ->
                    Game gameModel


dragging : NonemptyDict Int Touch -> NonemptyDict Int Touch -> ( ValidatedSetup, GameState, GameModel ) -> Model
dragging oldTouches newTouches ( _, _, gameModel ) =
    case gameModel.dragging of
        Just dragTile ->
            Game { gameModel | dragging = Just { dragTile | position = Touch.touchCentroid newTouches } }

        Nothing ->
            Game gameModel


dragEnd : Coord CssPixels -> ( ValidatedSetup, GameState, GameModel ) -> Model
dragEnd windowSize ( _, gameState, gameModel ) =
    case gameModel.dragging of
        Just dragTile ->
            let
                droppedModel : GameModel
                droppedModel =
                    { gameModel | dragging = Nothing }
            in
            case cellAtPosition windowSize dragTile.position of
                Just cell ->
                    if SeqDict.member cell gameState.board || SeqDict.member cell droppedModel.placedTiles then
                        -- Occupied: the tile goes back to the tray.
                        Game droppedModel

                    else
                        Game
                            { droppedModel
                                | placedTiles =
                                    SeqDict.insert
                                        cell
                                        { trayIndex = dragTile.trayIndex, letterOrWildcard = dragTile.letterOrWildcard }
                                        droppedModel.placedTiles
                            }

                Nothing ->
                    -- Dropped off the board: returns to the tray.
                    Game droppedModel

        Nothing ->
            Game gameModel


gameView : Coord CssPixels -> Id UserId -> ValidatedSetup -> GameState -> GameModel -> Element Msg
gameView windowSize currentUserId validatedSetup gameState model =
    Ui.column
        [ Ui.spacing 16 ]
        [ boardView windowSize currentUserId gameState model
        , statusView currentUserId gameState
        ]
        |> Ui.map GameMsg


statusView : Id UserId -> GameState -> Element GameMsg
statusView currentUserId gameState =
    let
        currentPlayer : Player
        currentPlayer =
            List.Nonempty.get gameState.turnCount gameState.players
    in
    Ui.column
        [ Ui.spacing 4, Ui.paddingXY 16 0 ]
        (List.Nonempty.toList gameState.players
            |> List.map
                (\player ->
                    let
                        name : String
                        name =
                            if player.userId == currentUserId then
                                "You"

                            else
                                "Opponent"

                        turnMarker : String
                        turnMarker =
                            if player.userId == currentPlayer.userId then
                                " (their turn)"

                            else
                                ""
                    in
                    Ui.el
                        [ if player.userId == currentPlayer.userId then
                            Ui.Font.weight 700

                          else
                            Ui.Font.weight 400
                        ]
                        (Ui.text (name ++ ": " ++ String.fromInt player.score ++ turnMarker))
                )
        )


trayHeight : number
trayHeight =
    trayTileSize


boardView : Coord CssPixels -> Id UserId -> GameState -> GameModel -> Element GameMsg
boardView windowSize currentUserId gameState model =
    let
        cellSize2 : Int
        cellSize2 =
            cellSize windowSize

        committedTiles : List (Ui.Attribute GameMsg)
        committedTiles =
            List.map
                (\( ( x, y ), { letter, isWildcard } ) ->
                    tileInFront cellSize2
                        { x = x * cellSize2, y = y * cellSize2 }
                        []
                        (if isWildcard then
                            Wildcard

                         else
                            Letter letter
                        )
                )
                (SeqDict.toList gameState.board)

        pendingTiles : List (Ui.Attribute GameMsg)
        pendingTiles =
            List.map
                (\( ( x, y ), placed ) ->
                    tileInFront cellSize2
                        { x = x * cellSize2, y = y * cellSize2 }
                        [ Ui.border 2, Ui.borderColor (Ui.rgb 0 150 0) ]
                        placed.letterOrWildcard
                )
                (SeqDict.toList model.placedTiles)

        trayTiles : List (Ui.Attribute GameMsg)
        trayTiles =
            currentPlayerTray currentUserId gameState
                |> List.indexedMap
                    (\index letterOrWildcard ->
                        if trayIndexInUse model index then
                            Ui.noAttr

                        else
                            tileInFront
                                trayTileSize
                                { x = index * (trayTileSize + trayTileSpacing)
                                , y = gridSize * cellSize2
                                }
                                []
                                letterOrWildcard
                    )

        dragHighlight : Ui.Attribute GameMsg
        dragHighlight =
            case model.dragging of
                Just dragTile ->
                    case cellAtPosition windowSize dragTile.position of
                        Just ( x, y ) ->
                            if SeqDict.member ( x, y ) gameState.board || SeqDict.member ( x, y ) model.placedTiles then
                                Ui.noAttr

                            else
                                Ui.inFront
                                    (Ui.el
                                        [ Ui.borderColor (Ui.rgb 0 200 255)
                                        , Ui.border 3
                                        , Ui.width (Ui.px cellSize2)
                                        , Ui.height (Ui.px cellSize2)
                                        , Ui.move { x = x * cellSize2, y = y * cellSize2, z = 0 }
                                        , MyUi.noPointerEvents
                                        ]
                                        Ui.none
                                    )

                        Nothing ->
                            Ui.noAttr

                Nothing ->
                    Ui.noAttr

        draggingTile : Ui.Attribute GameMsg
        draggingTile =
            case model.dragging of
                Just dragTile ->
                    tileInFront cellSize2
                        { x = Coord.xRaw dragTile.position - boardX windowSize - cellSize2 // 2
                        , y = Coord.yRaw dragTile.position - boardY - cellSize2 // 2
                        }
                        []
                        dragTile.letterOrWildcard

                Nothing ->
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
        ([ Ui.width Ui.shrink
         , Ui.height (Ui.px (gridSize * cellSize2 + trayHeight))
         , Ui.pointer
         ]
            ++ (committedTiles ++ pendingTiles ++ trayTiles)
            ++ [ selectedHighlight, dragHighlight, draggingTile ]
        )
        (Ui.Lazy.lazy boardViewBackground cellSize2)


tileInFront : Int -> { x : Int, y : Int } -> List (Ui.Attribute GameMsg) -> LetterOrWildcard -> Ui.Attribute GameMsg
tileInFront cellSize2 offset extraAttributes letterOrWildcard =
    Ui.inFront
        (Ui.el
            ([ Ui.background (Ui.rgb 240 220 130)
             , Ui.width (Ui.px cellSize2)
             , Ui.height (Ui.px cellSize2)
             , Ui.contentCenterX
             , Ui.contentCenterY
             , Ui.Font.size 16
             , Ui.Font.weight 600
             , Ui.move { x = offset.x, y = offset.y, z = 0 }
             , MyUi.noPointerEvents
             ]
                ++ extraAttributes
            )
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
        ((case maybeBonus of
            Just specialCell ->
                Ui.background (bonusCellColor specialCell)

            Nothing ->
                Ui.background (Ui.rgb 250 250 250)
         )
            :: [ Ui.width (Ui.px cellSize2)
               , Ui.height (Ui.px cellSize2)
               , Ui.border 1
               , Ui.borderColor MyUi.inputBorder
               , Ui.contentCenterX
               , Ui.contentCenterY
               , Ui.Events.onClick (PressedGridCell position)
               ]
        )
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
    SeqDict.fromList
        ([ ( 7, 7 ) ]
            |> List.map (\position -> ( position, CenterCell ))
            |> (++) (List.map (\position -> ( position, TripleWord )) tripleWordCells)
            |> (++) (List.map (\position -> ( position, DoubleWord )) doubleWordCells)
            |> (++) (List.map (\position -> ( position, TripleLetter )) tripleLetterCells)
            |> (++) (List.map (\position -> ( position, DoubleLetter )) doubleLetterCells)
        )


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


setupView : Coord CssPixels -> SetupModel -> Element Msg
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


setupSection : String -> Element Msg -> Element Msg
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
    , onChange : String -> Msg
    }
    -> Element Msg
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


timeInput : String -> String -> String -> (String -> Msg) -> Element Msg
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
