module Pages.Go exposing
    ( Model
    , Msg
    , Stone(..)
    , deadStones
    , init
    , keyMsg
    , subscriptions
    , update
    , view
    )

import Dict exposing (Dict)
import Duration
import Effect.Browser.Dom as Dom
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Http as Http
import Effect.Subscription as Subscription exposing (Subscription)
import Effect.Time as Time
import Env
import Html
import Html.Attributes
import Html.Events
import Icons
import Json.Decode
import Json.Encode
import MyUi
import Set exposing (Set)
import Svg
import Svg.Attributes
import Svg.Events
import Ui exposing (Element)
import Ui.Font
import Ui.Input


type Stone
    = Black
    | White


type Phase
    = Playing { previousPlayerPassed : Bool }
    | Marking { markingPlayer : Stone }
    | Confirming { markingPlayer : Stone }
    | Scored { markingPlayer : Stone, blackScore : Float, whiteScore : Float }


type alias Snapshot =
    { board : Dict ( Int, Int ) Stone
    , currentPlayer : Stone
    , blackCaptures : Int
    , whiteCaptures : Int
    }


type alias TimeControl =
    { mainTime : Float
    , increment : Float
    }


type alias GameModel =
    { width : Int
    , height : Int
    , komi : Float
    , timeControl : Maybe TimeControl
    , blackTime : Float
    , whiteTime : Float
    , lastTick : Maybe Time.Posix
    , board : Dict ( Int, Int ) Stone
    , history : List Snapshot
    , viewingMovesBack : Int
    , currentPlayer : Stone
    , blackCaptures : Int
    , whiteCaptures : Int
    , phase : Phase
    , territoryMarks : Dict ( Int, Int ) Stone
    , lastError : Maybe String
    , aiPlayer : Maybe Stone
    , aiThinking : Bool
    }


type alias SetupModel =
    { widthInput : String
    , heightInput : String
    , handicapInput : String
    , komiInput : String
    , mainTimeInput : String
    , incrementInput : String
    , sizeSelection : SizeSelection
    , aiSelection : AiSelection
    , error : Maybe String
    }


type AiSelection
    = AiOff
    | AiPlaysWhite
    | AiPlaysBlack


type SizeSelection
    = Standard9
    | Standard13
    | Standard19
    | CustomSize


type Model
    = Setup SetupModel
    | Game GameModel


init : Model
init =
    Setup
        { widthInput = "9"
        , heightInput = "9"
        , handicapInput = "0"
        , komiInput = "6.5"
        , mainTimeInput = "10"
        , incrementInput = "5"
        , sizeSelection = Standard9
        , aiSelection = AiOff
        , error = Nothing
        }


maxHandicap : Int
maxHandicap =
    9


handicapPositions : Int -> Int -> Int -> List ( Int, Int )
handicapPositions handicap width height =
    let
        margin : Int
        margin =
            if min width height >= 13 then
                3

            else if min width height >= 9 then
                2

            else
                1

        leftX : Int
        leftX =
            margin

        rightX : Int
        rightX =
            width - 1 - margin

        topY : Int
        topY =
            margin

        bottomY : Int
        bottomY =
            height - 1 - margin

        midX : Int
        midX =
            width // 2

        midY : Int
        midY =
            height // 2

        corners : List ( Int, Int )
        corners =
            [ ( leftX, bottomY ), ( rightX, topY ), ( leftX, topY ), ( rightX, bottomY ) ]

        center : ( Int, Int )
        center =
            ( midX, midY )

        positions : List ( Int, Int )
        positions =
            case handicap of
                0 ->
                    []

                1 ->
                    [ ( leftX, bottomY ) ]

                2 ->
                    [ ( leftX, bottomY ), ( rightX, topY ) ]

                3 ->
                    [ ( leftX, bottomY ), ( rightX, topY ), ( leftX, topY ) ]

                4 ->
                    corners

                5 ->
                    corners ++ [ center ]

                6 ->
                    corners ++ [ ( leftX, midY ), ( rightX, midY ) ]

                7 ->
                    corners ++ [ ( leftX, midY ), ( rightX, midY ), center ]

                8 ->
                    corners ++ [ ( leftX, midY ), ( rightX, midY ), ( midX, topY ), ( midX, bottomY ) ]

                _ ->
                    corners ++ [ ( leftX, midY ), ( rightX, midY ), ( midX, topY ), ( midX, bottomY ), center ]
    in
    positions
        |> List.filter (\( x, y ) -> x >= 0 && x < width && y >= 0 && y < height)
        |> Set.fromList
        |> Set.toList


startGame : Int -> Int -> Int -> Float -> Maybe TimeControl -> Maybe Stone -> GameModel
startGame width height handicap komi timeControl aiPlayer =
    let
        positions : List ( Int, Int )
        positions =
            handicapPositions handicap width height

        board : Dict ( Int, Int ) Stone
        board =
            positions
                |> List.map (\p -> ( p, Black ))
                |> Dict.fromList

        startingPlayer : Stone
        startingPlayer =
            if List.isEmpty positions then
                Black

            else
                White
    in
    { width = width
    , height = height
    , komi = komi
    , timeControl = timeControl
    , blackTime =
        case timeControl of
            Just tc ->
                tc.mainTime

            Nothing ->
                0
    , whiteTime =
        case timeControl of
            Just tc ->
                tc.mainTime

            Nothing ->
                0
    , lastTick = Nothing
    , board = board
    , history = []
    , viewingMovesBack = 0
    , currentPlayer = startingPlayer
    , blackCaptures = 0
    , whiteCaptures = 0
    , phase = Playing { previousPlayerPassed = False }
    , territoryMarks = Dict.empty
    , lastError = Nothing
    , aiPlayer = aiPlayer
    , aiThinking = False
    }


minDimension : Int
minDimension =
    2


maxDimension : Int
maxDimension =
    25


type Msg
    = PressedCell Int Int
    | PressedPass
    | PressedReset
    | PressedDoneMarking
    | PressedAgree
    | PressedDisagree
    | ChangedViewingMove Int
    | PressedArrowLeft
    | PressedArrowRight
    | ChangedWidthInput String
    | ChangedHeightInput String
    | ChangedHandicapInput String
    | ChangedKomiInput String
    | ChangedMainTimeInput String
    | ChangedIncrementInput String
    | SelectedSize SizeSelection
    | SelectedAi AiSelection
    | PressedStartGame
    | Tick Time.Posix
    | GotAiMove (Result Http.Error AiMove)


type AiMove
    = AiPlay Int Int
    | AiPass


keyMsg : String -> Maybe Msg
keyMsg key =
    case key of
        "ArrowLeft" ->
            Just PressedArrowLeft

        "ArrowRight" ->
            Just PressedArrowRight

        _ ->
            Nothing


subscriptions : Model -> Subscription FrontendOnly Msg
subscriptions model =
    case model of
        Game game ->
            case ( game.timeControl, game.phase ) of
                ( Just _, Playing _ ) ->
                    if isViewingPast game then
                        Subscription.none

                    else
                        Time.every (Duration.milliseconds 250) Tick

                _ ->
                    Subscription.none

        Setup _ ->
            Subscription.none


otherStone : Stone -> Stone
otherStone stone =
    case stone of
        Black ->
            White

        White ->
            Black


stoneName : Stone -> String
stoneName stone =
    case stone of
        Black ->
            "Black"

        White ->
            "White"


neighbors : Int -> Int -> ( Int, Int ) -> List ( Int, Int )
neighbors width height ( x, y ) =
    [ ( x - 1, y ), ( x + 1, y ), ( x, y - 1 ), ( x, y + 1 ) ]
        |> List.filter (\( a, b ) -> a >= 0 && a < width && b >= 0 && b < height)


type alias GroupInfo =
    { stones : Set ( Int, Int )
    , liberties : Set ( Int, Int )
    }


groupAt : Int -> Int -> Dict ( Int, Int ) Stone -> ( Int, Int ) -> GroupInfo
groupAt width height board start =
    case Dict.get start board of
        Nothing ->
            { stones = Set.empty, liberties = Set.empty }

        Just stone ->
            floodFill width height board stone [ start ] (Set.singleton start) Set.empty


floodFill :
    Int
    -> Int
    -> Dict ( Int, Int ) Stone
    -> Stone
    -> List ( Int, Int )
    -> Set ( Int, Int )
    -> Set ( Int, Int )
    -> GroupInfo
floodFill width height board stone queue stones liberties =
    case queue of
        [] ->
            { stones = stones, liberties = liberties }

        pos :: rest ->
            let
                ( newQueue, newStones, newLiberties ) =
                    List.foldl
                        (\n ( q, s, l ) ->
                            if Set.member n s then
                                ( q, s, l )

                            else
                                case Dict.get n board of
                                    Nothing ->
                                        ( q, s, Set.insert n l )

                                    Just neighborStone ->
                                        if neighborStone == stone then
                                            ( n :: q, Set.insert n s, l )

                                        else
                                            ( q, s, l )
                        )
                        ( rest, stones, liberties )
                        (neighbors width height pos)
            in
            floodFill width height board stone newQueue newStones newLiberties


findRegion : Int -> Int -> Dict ( Int, Int ) Stone -> ( Int, Int ) -> Set ( Int, Int )
findRegion width height board start =
    if Dict.member start board then
        Set.empty

    else
        regionFlood width height board [ start ] (Set.singleton start)


regionFlood :
    Int
    -> Int
    -> Dict ( Int, Int ) Stone
    -> List ( Int, Int )
    -> Set ( Int, Int )
    -> Set ( Int, Int )
regionFlood width height board queue visited =
    case queue of
        [] ->
            visited

        pos :: rest ->
            let
                ( newQueue, newVisited ) =
                    List.foldl
                        (\n ( q, v ) ->
                            if Set.member n v || Dict.member n board then
                                ( q, v )

                            else
                                ( n :: q, Set.insert n v )
                        )
                        ( rest, visited )
                        (neighbors width height pos)
            in
            regionFlood width height board newQueue newVisited


currentSnapshot : GameModel -> Snapshot
currentSnapshot model =
    { board = model.board
    , currentPlayer = model.currentPlayer
    , blackCaptures = model.blackCaptures
    , whiteCaptures = model.whiteCaptures
    }


applyIncrement : Stone -> GameModel -> GameModel
applyIncrement mover model =
    case model.timeControl of
        Just tc ->
            case mover of
                Black ->
                    { model | blackTime = model.blackTime + tc.increment, lastTick = Nothing }

                White ->
                    { model | whiteTime = model.whiteTime + tc.increment, lastTick = Nothing }

        Nothing ->
            { model | lastTick = Nothing }


performPass : GameModel -> GameModel
performPass model =
    case model.phase of
        Playing { previousPlayerPassed } ->
            if previousPlayerPassed then
                applyIncrement
                    model.currentPlayer
                    { model
                        | phase = Marking { markingPlayer = model.currentPlayer }
                        , lastError = Nothing
                    }

            else
                applyIncrement
                    model.currentPlayer
                    { model
                        | currentPlayer = otherStone model.currentPlayer
                        , lastError = Nothing
                        , phase = Playing { previousPlayerPassed = True }
                    }

        _ ->
            model


timeoutPass : GameModel -> GameModel
timeoutPass model =
    let
        timedOutPlayer : Stone
        timedOutPlayer =
            model.currentPlayer

        passed : GameModel
        passed =
            performPass model
    in
    { passed
        | lastError = Just (stoneName timedOutPlayer ++ " ran out of time and passed.")
        , lastTick = Nothing
    }


tickClock : Time.Posix -> GameModel -> GameModel
tickClock now model =
    case model.timeControl of
        Nothing ->
            model

        Just _ ->
            case ( model.phase, isViewingPast model ) of
                ( Playing _, False ) ->
                    let
                        elapsed : Float
                        elapsed =
                            case model.lastTick of
                                Just last ->
                                    max 0 (Duration.from last now |> Duration.inSeconds)

                                Nothing ->
                                    0

                        decremented : GameModel
                        decremented =
                            case model.currentPlayer of
                                Black ->
                                    { model | blackTime = max 0 (model.blackTime - elapsed) }

                                White ->
                                    { model | whiteTime = max 0 (model.whiteTime - elapsed) }

                        currentRemaining : Float
                        currentRemaining =
                            case decremented.currentPlayer of
                                Black ->
                                    decremented.blackTime

                                White ->
                                    decremented.whiteTime
                    in
                    if currentRemaining <= 0 then
                        timeoutPass { decremented | lastTick = Just now }

                    else
                        { decremented | lastTick = Just now }

                _ ->
                    { model | lastTick = Just now }


viewingSnapshot : GameModel -> Snapshot
viewingSnapshot model =
    if model.viewingMovesBack <= 0 then
        currentSnapshot model

    else
        case List.drop (model.viewingMovesBack - 1) model.history |> List.head of
            Just snapshot ->
                snapshot

            Nothing ->
                currentSnapshot model


isViewingPast : GameModel -> Bool
isViewingPast model =
    model.viewingMovesBack > 0


jumpToLatest : GameModel -> GameModel
jumpToLatest model =
    { model | viewingMovesBack = 0, lastError = Nothing }


tryPlace : Int -> Int -> GameModel -> GameModel
tryPlace x y model =
    if Dict.member ( x, y ) model.board then
        { model | lastError = Just "There's already a stone there" }

    else
        let
            stone : Stone
            stone =
                model.currentPlayer

            opponent : Stone
            opponent =
                otherStone stone

            boardWithStone : Dict ( Int, Int ) Stone
            boardWithStone =
                Dict.insert ( x, y ) stone model.board

            ( boardAfterCapture, captured ) =
                List.foldl
                    (\n ( b, captures ) ->
                        case Dict.get n b of
                            Just neighborStone ->
                                if neighborStone == opponent then
                                    let
                                        group : GroupInfo
                                        group =
                                            groupAt model.width model.height b n
                                    in
                                    if Set.isEmpty group.liberties then
                                        ( Set.foldl Dict.remove b group.stones
                                        , captures + Set.size group.stones
                                        )

                                    else
                                        ( b, captures )

                                else
                                    ( b, captures )

                            Nothing ->
                                ( b, captures )
                    )
                    ( boardWithStone, 0 )
                    (neighbors model.width model.height ( x, y ))

            myGroup : GroupInfo
            myGroup =
                groupAt model.width model.height boardAfterCapture ( x, y )

            recentBoards : List (Dict ( Int, Int ) Stone)
            recentBoards =
                List.take 10 model.history |> List.map .board
        in
        if Set.isEmpty myGroup.liberties then
            { model | lastError = Just "Suicide move not allowed" }

        else if List.member boardAfterCapture recentBoards then
            { model | lastError = Just "Move repeats a board state" }

        else
            applyIncrement stone
                { model
                    | board = boardAfterCapture
                    , history = currentSnapshot model :: model.history
                    , viewingMovesBack = 0
                    , currentPlayer = opponent
                    , blackCaptures =
                        if stone == Black then
                            model.blackCaptures + captured

                        else
                            model.blackCaptures
                    , whiteCaptures =
                        if stone == White then
                            model.whiteCaptures + captured

                        else
                            model.whiteCaptures
                    , phase = Playing { previousPlayerPassed = False }
                    , lastError = Nothing
                }


cycleOwner : Maybe Stone -> Maybe Stone
cycleOwner current =
    case current of
        Nothing ->
            Just Black

        Just Black ->
            Just White

        Just White ->
            Nothing


cycleTerritory : Int -> Int -> GameModel -> GameModel
cycleTerritory x y model =
    if Dict.member ( x, y ) model.board then
        model

    else
        let
            region : Set ( Int, Int )
            region =
                findRegion model.width model.height model.board ( x, y )

            currentOwner : Maybe Stone
            currentOwner =
                Set.toList region
                    |> List.head
                    |> Maybe.andThen (\p -> Dict.get p model.territoryMarks)

            newOwner : Maybe Stone
            newOwner =
                cycleOwner currentOwner

            cleared : Dict ( Int, Int ) Stone
            cleared =
                Set.foldl Dict.remove model.territoryMarks region

            newMarks : Dict ( Int, Int ) Stone
            newMarks =
                case newOwner of
                    Just s ->
                        Set.foldl (\p d -> Dict.insert p s d) cleared region

                    Nothing ->
                        cleared
        in
        { model | territoryMarks = newMarks, lastError = Nothing }


computeScore : GameModel -> ( Float, Float )
computeScore model =
    let
        ( blackTerritory, whiteTerritory ) =
            Dict.foldl
                (\_ s ( b, w ) ->
                    case s of
                        Black ->
                            ( b + 1, w )

                        White ->
                            ( b, w + 1 )
                )
                ( 0, 0 )
                model.territoryMarks

        ctx : DeadContext
        ctx =
            gameDeadContext model

        ( deadBlack, deadWhite ) =
            Dict.foldl
                (\pos stone ( db, dw ) ->
                    if isStoneDead ctx pos stone then
                        case stone of
                            Black ->
                                ( db + 1, dw )

                            White ->
                                ( db, dw + 1 )

                    else
                        ( db, dw )
                )
                ( 0, 0 )
                model.board
    in
    ( toFloat (blackTerritory + model.blackCaptures + 2 * deadWhite)
    , toFloat (whiteTerritory + model.whiteCaptures + 2 * deadBlack) + model.komi
    )


type alias DeadContext =
    { width : Int
    , height : Int
    , board : Dict ( Int, Int ) Stone
    , territoryMarks : Dict ( Int, Int ) Stone
    }


isStoneDead : DeadContext -> ( Int, Int ) -> Stone -> Bool
isStoneDead ctx pos stone =
    let
        group : GroupInfo
        group =
            groupAt ctx.width ctx.height ctx.board pos

        liberties : List ( Int, Int )
        liberties =
            Set.toList group.liberties
    in
    case liberties of
        [] ->
            False

        _ ->
            List.all
                (\lib ->
                    Dict.get lib ctx.territoryMarks == Just (otherStone stone)
                )
                liberties


deadStones :
    { width : Int
    , height : Int
    , board : Dict ( Int, Int ) Stone
    , territoryMarks : Dict ( Int, Int ) Stone
    }
    -> Set ( Int, Int )
deadStones ctx =
    Dict.foldl
        (\pos stone acc ->
            if isStoneDead ctx pos stone then
                Set.insert pos acc

            else
                acc
        )
        Set.empty
        ctx.board


gameDeadContext : GameModel -> DeadContext
gameDeadContext model =
    { width = model.width
    , height = model.height
    , board = model.board
    , territoryMarks = model.territoryMarks
    }


deadStonePositions : GameModel -> Set ( Int, Int )
deadStonePositions model =
    deadStones (gameDeadContext model)


parseDimension : String -> Result String Int
parseDimension input =
    case String.toInt (String.trim input) of
        Just n ->
            if n < minDimension then
                Err ("Minimum dimension is " ++ String.fromInt minDimension)

            else if n > maxDimension then
                Err ("Maximum dimension is " ++ String.fromInt maxDimension)

            else
                Ok n

        Nothing ->
            Err "Enter a number"


parseHandicap : String -> Result String Int
parseHandicap input =
    let
        trimmed : String
        trimmed =
            String.trim input
    in
    if trimmed == "" then
        Ok 0

    else
        case String.toInt trimmed of
            Just n ->
                if n < 0 then
                    Err "Cannot be negative"

                else if n > maxHandicap then
                    Err ("Maximum is " ++ String.fromInt maxHandicap)

                else
                    Ok n

            Nothing ->
                Err "Enter a number"


parseKomi : String -> Result String Float
parseKomi input =
    let
        trimmed : String
        trimmed =
            String.trim input
    in
    if trimmed == "" then
        Ok 0

    else
        case String.toFloat trimmed of
            Just n ->
                Ok n

            Nothing ->
                Err "Enter a number"


parseTimeControl : SetupModel -> Result String (Maybe TimeControl)
parseTimeControl model =
    let
        trimmedMain : String
        trimmedMain =
            String.trim model.mainTimeInput
    in
    if trimmedMain == "" then
        Ok Nothing

    else
        case String.toFloat trimmedMain of
            Nothing ->
                Err "Main time: enter a number of minutes"

            Just minutes ->
                if minutes <= 0 then
                    Ok Nothing

                else
                    case String.toFloat (String.trim model.incrementInput) of
                        Nothing ->
                            Err "Increment: enter a number of seconds"

                        Just inc ->
                            if inc < 0 then
                                Err "Increment cannot be negative"

                            else
                                Ok (Just { mainTime = minutes * 60, increment = inc })


update : Msg -> Model -> ( Model, Command FrontendOnly toMsg Msg )
update msg model =
    case model of
        Setup setup ->
            updateSetup msg setup

        Game game ->
            updateGame msg game


aiSelectionToStone : AiSelection -> Maybe Stone
aiSelectionToStone selection =
    case selection of
        AiOff ->
            Nothing

        AiPlaysWhite ->
            Just White

        AiPlaysBlack ->
            Just Black


startWithSettings : Int -> Int -> SetupModel -> ( Model, Command FrontendOnly toMsg Msg )
startWithSettings w h model =
    case parseHandicap model.handicapInput of
        Err err ->
            ( Setup { model | error = Just ("Handicap: " ++ err) }, Command.none )

        Ok handicap ->
            case parseKomi model.komiInput of
                Err err ->
                    ( Setup { model | error = Just ("Komi: " ++ err) }, Command.none )

                Ok komi ->
                    case parseTimeControl model of
                        Err err ->
                            ( Setup { model | error = Just err }, Command.none )

                        Ok timeControl ->
                            let
                                game : GameModel
                                game =
                                    startGame w h handicap komi timeControl (aiSelectionToStone model.aiSelection)
                            in
                            wrapGameWithAi game


updateSetup : Msg -> SetupModel -> ( Model, Command FrontendOnly toMsg Msg )
updateSetup msg model =
    case msg of
        ChangedWidthInput input ->
            ( Setup { model | widthInput = input, error = Nothing }, Command.none )

        ChangedHeightInput input ->
            ( Setup { model | heightInput = input, error = Nothing }, Command.none )

        ChangedHandicapInput input ->
            ( Setup { model | handicapInput = input, error = Nothing }, Command.none )

        ChangedKomiInput input ->
            ( Setup { model | komiInput = input, error = Nothing }, Command.none )

        ChangedMainTimeInput input ->
            ( Setup { model | mainTimeInput = input, error = Nothing }, Command.none )

        ChangedIncrementInput input ->
            ( Setup { model | incrementInput = input, error = Nothing }, Command.none )

        SelectedSize selection ->
            ( Setup { model | sizeSelection = selection, error = Nothing }, Command.none )

        SelectedAi selection ->
            ( Setup { model | aiSelection = selection, error = Nothing }, Command.none )

        PressedStartGame ->
            case selectedDimensions model of
                Ok ( w, h ) ->
                    startWithSettings w h model

                Err err ->
                    ( Setup { model | error = Just err }, Command.none )

        _ ->
            ( Setup model, Command.none )


selectedDimensions : SetupModel -> Result String ( Int, Int )
selectedDimensions model =
    case model.sizeSelection of
        Standard9 ->
            Ok ( 9, 9 )

        Standard13 ->
            Ok ( 13, 13 )

        Standard19 ->
            Ok ( 19, 19 )

        CustomSize ->
            case ( parseDimension model.widthInput, parseDimension model.heightInput ) of
                ( Ok w, Ok h ) ->
                    Ok ( w, h )

                ( Err err, _ ) ->
                    Err ("Width: " ++ err)

                ( _, Err err ) ->
                    Err ("Height: " ++ err)


updateGame : Msg -> GameModel -> ( Model, Command FrontendOnly toMsg Msg )
updateGame msg model =
    case msg of
        PressedCell x y ->
            if isViewingPast model then
                ( Game (jumpToLatest model), Command.none )

            else
                case model.phase of
                    Playing _ ->
                        if isAiTurn model then
                            ( Game model, Command.none )

                        else
                            wrapGameWithAi (tryPlace x y model)

                    Marking _ ->
                        ( Game (cycleTerritory x y model), Command.none )

                    Confirming _ ->
                        ( Game model, Command.none )

                    Scored _ ->
                        ( Game model, Command.none )

        PressedPass ->
            if isViewingPast model then
                ( Game (jumpToLatest model), Command.none )

            else
                case model.phase of
                    Playing _ ->
                        if isAiTurn model then
                            ( Game model, Command.none )

                        else
                            wrapGameWithAi (performPass model)

                    _ ->
                        ( Game model, Command.none )

        PressedDoneMarking ->
            case model.phase of
                Marking r ->
                    ( Game { model | phase = Confirming r, lastError = Nothing }, Command.none )

                _ ->
                    ( Game model, Command.none )

        PressedAgree ->
            case model.phase of
                Confirming r ->
                    let
                        ( b, w ) =
                            computeScore model
                    in
                    ( Game
                        { model
                            | phase =
                                Scored
                                    { markingPlayer = r.markingPlayer
                                    , blackScore = b
                                    , whiteScore = w
                                    }
                            , lastError = Nothing
                        }
                    , Command.none
                    )

                _ ->
                    ( Game model, Command.none )

        PressedDisagree ->
            case model.phase of
                Confirming r ->
                    ( Game
                        { model
                            | phase = Playing { previousPlayerPassed = False }
                            , currentPlayer = otherStone r.markingPlayer
                            , territoryMarks = Dict.empty
                            , lastError = Just "Marking rejected. Resume play."
                        }
                    , Command.none
                    )

                _ ->
                    ( Game model, Command.none )

        PressedReset ->
            ( init, Command.none )

        ChangedViewingMove moveNumber ->
            let
                total : Int
                total =
                    List.length model.history

                clamped : Int
                clamped =
                    clamp 0 total moveNumber
            in
            ( Game { model | viewingMovesBack = total - clamped, lastError = Nothing }, Command.none )

        PressedArrowLeft ->
            ( Game
                { model
                    | viewingMovesBack = min (List.length model.history) (model.viewingMovesBack + 1)
                    , lastError = Nothing
                }
            , Command.none
            )

        PressedArrowRight ->
            ( Game
                { model
                    | viewingMovesBack = max 0 (model.viewingMovesBack - 1)
                    , lastError = Nothing
                }
            , Command.none
            )

        ChangedWidthInput _ ->
            ( Game model, Command.none )

        ChangedHeightInput _ ->
            ( Game model, Command.none )

        ChangedHandicapInput _ ->
            ( Game model, Command.none )

        ChangedKomiInput _ ->
            ( Game model, Command.none )

        ChangedMainTimeInput _ ->
            ( Game model, Command.none )

        ChangedIncrementInput _ ->
            ( Game model, Command.none )

        SelectedSize _ ->
            ( Game model, Command.none )

        SelectedAi _ ->
            ( Game model, Command.none )

        PressedStartGame ->
            ( Game model, Command.none )

        Tick now ->
            ( Game (tickClock now model), Command.none )

        GotAiMove result ->
            handleAiMove result model


isAiTurn : GameModel -> Bool
isAiTurn model =
    case ( model.phase, model.aiPlayer ) of
        ( Playing _, Just stone ) ->
            stone == model.currentPlayer

        _ ->
            False


wrapGameWithAi : GameModel -> ( Model, Command FrontendOnly toMsg Msg )
wrapGameWithAi game =
    if isAiTurn game && not game.aiThinking then
        ( Game { game | aiThinking = True }, requestAiMove game )

    else
        ( Game game, Command.none )


handleAiMove : Result Http.Error AiMove -> GameModel -> ( Model, Command FrontendOnly toMsg Msg )
handleAiMove result model =
    let
        cleared : GameModel
        cleared =
            { model | aiThinking = False }
    in
    case result of
        Err _ ->
            ( Game { cleared | lastError = Just "AI request failed; pass or play to continue." }, Command.none )

        Ok aiMove ->
            case ( cleared.phase, cleared.aiPlayer ) of
                ( Playing _, Just aiStone ) ->
                    if aiStone /= cleared.currentPlayer then
                        ( Game cleared, Command.none )

                    else
                        case aiMove of
                            AiPlay x y ->
                                let
                                    next : GameModel
                                    next =
                                        tryPlace x y cleared
                                in
                                if next.lastError /= Nothing then
                                    -- Fall back to passing so the game doesn't deadlock on a bad move
                                    wrapGameWithAi (performPass cleared)

                                else
                                    wrapGameWithAi next

                            AiPass ->
                                wrapGameWithAi (performPass cleared)

                _ ->
                    ( Game cleared, Command.none )


requestAiMove : GameModel -> Command FrontendOnly toMsg Msg
requestAiMove model =
    Http.post
        { url = Env.domain ++ "/file/go-move"
        , body = Http.jsonBody (encodeAiMoveRequest model)
        , expect = Http.expectJson GotAiMove decodeAiMove
        }


encodeStone : Stone -> Json.Encode.Value
encodeStone stone =
    Json.Encode.string (stoneName stone)


encodeBoardStones : Dict ( Int, Int ) Stone -> Json.Encode.Value
encodeBoardStones board =
    Dict.toList board
        |> List.map
            (\( ( x, y ), stone ) ->
                Json.Encode.object
                    [ ( "x", Json.Encode.int x )
                    , ( "y", Json.Encode.int y )
                    , ( "color", encodeStone stone )
                    ]
            )
        |> Json.Encode.list identity


encodeAiMoveRequest : GameModel -> Json.Encode.Value
encodeAiMoveRequest model =
    let
        playoutsPerMove : Int
        playoutsPerMove =
            if model.width * model.height >= 19 * 19 then
                15

            else if model.width * model.height >= 13 * 13 then
                30

            else
                60
    in
    Json.Encode.object
        ([ ( "width", Json.Encode.int model.width )
         , ( "height", Json.Encode.int model.height )
         , ( "komi", Json.Encode.float model.komi )
         , ( "current_player", encodeStone model.currentPlayer )
         , ( "stones", encodeBoardStones model.board )
         , ( "playouts_per_move", Json.Encode.int playoutsPerMove )
         ]
            ++ (case List.head model.history of
                    Just snapshot ->
                        [ ( "previous_stones", encodeBoardStones snapshot.board ) ]

                    Nothing ->
                        []
               )
        )


decodeAiMove : Json.Decode.Decoder AiMove
decodeAiMove =
    Json.Decode.field "type" Json.Decode.string
        |> Json.Decode.andThen
            (\tag ->
                case tag of
                    "Play" ->
                        Json.Decode.map2 AiPlay
                            (Json.Decode.field "x" Json.Decode.int)
                            (Json.Decode.field "y" Json.Decode.int)

                    "Pass" ->
                        Json.Decode.succeed AiPass

                    other ->
                        Json.Decode.fail ("Unknown move type: " ++ other)
            )


cellPx : Int
cellPx =
    40


view : Model -> Element Msg
view model =
    case model of
        Setup setup ->
            setupView setup

        Game game ->
            gameView game


setupView : SetupModel -> Element Msg
setupView model =
    Ui.column
        [ Ui.spacing 16
        , Ui.padding 24
        , Ui.centerX
        , Ui.width Ui.shrink
        , MyUi.montserrat
        ]
        [ Ui.el [ Ui.Font.size 28, Ui.Font.weight 700 ] (Ui.text "Go - new game")
        , setupSection
            "Board size"
            (Ui.Input.chooseOne Ui.column
                [ Ui.spacing 8 ]
                { onChange = SelectedSize
                , selected = Just model.sizeSelection
                , label = Ui.Input.labelHidden "go_boardSize"
                , options =
                    [ Ui.Input.option Standard9 (Ui.text "9 x 9")
                    , Ui.Input.option Standard13 (Ui.text "13 x 13")
                    , Ui.Input.option Standard19 (Ui.text "19 x 19")
                    , Ui.Input.optionWith CustomSize
                        (sizeOptionView
                            (Ui.row [ Ui.spacing 8, Ui.width Ui.shrink ]
                                [ Ui.text "Custom:"
                                , dimensionInput "go_widthInput" model.widthInput ChangedWidthInput
                                , Ui.text "x"
                                , dimensionInput "go_heightInput" model.heightInput ChangedHeightInput
                                ]
                            )
                        )
                    ]
                }
            )
        , setupSection
            "Handicap (Black starts with this many stones; White moves first)"
            (numberInput
                { htmlId = "go_handicapInput"
                , minValue = 0
                , maxValue = maxHandicap
                , value = model.handicapInput
                , onChange = ChangedHandicapInput
                }
            )
        , setupSection "Komi (extra points for White at scoring)" (komiInput model.komiInput)
        , setupSection
            "Time control (set main time to 0 to disable)"
            (Ui.row [ Ui.spacing 8, Ui.width Ui.shrink, Ui.contentBottom ]
                [ timeInput "go_mainTimeInput" "Main time (minutes)" model.mainTimeInput ChangedMainTimeInput
                , timeInput "go_incrementInput" "Increment (seconds)" model.incrementInput ChangedIncrementInput
                ]
            )
        , setupSection
            "Opponent"
            (Ui.Input.chooseOne Ui.column
                [ Ui.spacing 8 ]
                { onChange = SelectedAi
                , selected = Just model.aiSelection
                , label = Ui.Input.labelHidden "go_opponent"
                , options =
                    [ Ui.Input.option AiOff (Ui.text "Two human players")
                    , Ui.Input.option AiPlaysWhite (Ui.text "AI plays White")
                    , Ui.Input.option AiPlaysBlack (Ui.text "AI plays Black")
                    ]
                }
            )
        , case model.error of
            Just err ->
                Ui.el [ Ui.Font.color (Ui.rgb 200 50 50) ] (Ui.text err)

            Nothing ->
                Ui.none
        , MyUi.simpleButton (Dom.id "go_start") PressedStartGame (Ui.text "Start game")
        ]


sizeOptionView : Element Msg -> Ui.Input.OptionState -> Element Msg
sizeOptionView label status =
    Ui.row
        [ Ui.spacing 10, Ui.alignLeft, Ui.width Ui.shrink, Ui.contentCenterY ]
        [ Ui.el
            [ Ui.width (Ui.px 14)
            , Ui.height (Ui.px 14)
            , Ui.background (Ui.rgb 255 255 255)
            , Ui.rounded 7
            , Ui.borderColor
                (case status of
                    Ui.Input.Selected ->
                        Ui.rgb 59 153 252

                    _ ->
                        Ui.rgb 208 208 208
                )
            , Ui.border
                (case status of
                    Ui.Input.Selected ->
                        5

                    _ ->
                        1
                )
            ]
            Ui.none
        , label
        ]


setupSection : String -> Element msg -> Element msg
setupSection title content =
    Ui.column
        [ Ui.spacing 8 ]
        [ Ui.el [ Ui.Font.weight 600 ] (Ui.text title)
        , content
        ]


dimensionInput : String -> String -> (String -> Msg) -> Element Msg
dimensionInput htmlId value onChange =
    numberInput
        { htmlId = htmlId
        , minValue = minDimension
        , maxValue = maxDimension
        , value = value
        , onChange = onChange
        }


komiInput : String -> Element Msg
komiInput value =
    Html.input
        [ Html.Attributes.id "go_komiInput"
        , Html.Attributes.type_ "number"
        , Html.Attributes.step "0.5"
        , Html.Attributes.value value
        , Html.Attributes.style "font-size" "inherit"
        , Html.Attributes.style "width" "50px"
        , Html.Attributes.style "padding" "8px"
        , Html.Attributes.style "border" ("1px solid " ++ MyUi.colorToStyle MyUi.inputBorder)
        , Html.Attributes.style "border-radius" "4px"
        , Html.Events.onInput ChangedKomiInput
        ]
        []
        |> Ui.html


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


formatClock : Float -> String
formatClock seconds =
    let
        clamped : Int
        clamped =
            max 0 (floor seconds)

        minutes : Int
        minutes =
            clamped // 60

        secs : Int
        secs =
            modBy 60 clamped

        twoDigit : Int -> String
        twoDigit n =
            if n < 10 then
                "0" ++ String.fromInt n

            else
                String.fromInt n
    in
    String.fromInt minutes ++ ":" ++ twoDigit secs


clockView : GameModel -> Element Msg
clockView model =
    case model.timeControl of
        Nothing ->
            Ui.none

        Just _ ->
            Ui.row
                [ Ui.spacing 16, Ui.width Ui.shrink ]
                [ clockChip "Black" model.blackTime (model.currentPlayer == Black && isPlayingPhase model)
                , clockChip "White" model.whiteTime (model.currentPlayer == White && isPlayingPhase model)
                ]


clockChip : String -> Float -> Bool -> Element msg
clockChip label seconds isActive =
    Ui.row
        [ Ui.spacing 8
        , Ui.padding 8
        , Ui.width (Ui.px 150)
        , Ui.rounded 4
        , Ui.border 1
        , Ui.borderColor
            (if isActive then
                Ui.rgb 59 153 252

             else
                Ui.rgb 200 200 200
            )
        , if isActive then
            Ui.background MyUi.background2

          else
            Ui.noAttr
        ]
        [ Ui.el [ Ui.Font.weight 600 ] (Ui.text label)
        , Ui.text (formatClock seconds)
        ]


isPlayingPhase : GameModel -> Bool
isPlayingPhase model =
    case model.phase of
        Playing _ ->
            True

        _ ->
            False


gameView : GameModel -> Element Msg
gameView model =
    Ui.column
        [ Ui.spacing 16
        , Ui.padding 24
        , Ui.centerX
        , Ui.width Ui.shrink
        , MyUi.montserrat
        ]
        [ Ui.el [ Ui.Font.size 28, Ui.Font.weight 700 ]
            (Ui.text
                ("Go ("
                    ++ String.fromInt model.width
                    ++ " x "
                    ++ String.fromInt model.height
                    ++ ")"
                )
            )
        , statusView model
        , clockView model
        , boardView model
        , historyView model
        , controlsView model
        , case model.lastError of
            Just err ->
                Ui.el [ Ui.Font.color (Ui.rgb 200 50 50) ] (Ui.text err)

            Nothing ->
                Ui.none
        , Ui.el [ Ui.Font.size 14 ] (Ui.text "One device, two players. Pass twice to score. Arrow keys or slider to review past moves.")
        ]


statusView : GameModel -> Element msg
statusView model =
    let
        snapshot : Snapshot
        snapshot =
            viewingSnapshot model

        turnText : String
        turnText =
            case model.phase of
                Playing _ ->
                    stoneName model.currentPlayer ++ " to move"

                Marking r ->
                    stoneName r.markingPlayer
                        ++ " marks territory: tap an empty region to cycle owner (none → Black → White)."

                Confirming r ->
                    stoneName (otherStone r.markingPlayer)
                        ++ ": agree with the marking, or disagree to resume play."

                Scored s ->
                    "Final score - Black: "
                        ++ formatScore s.blackScore
                        ++ ", White: "
                        ++ formatScore s.whiteScore
                        ++ winnerSuffix s.blackScore s.whiteScore
    in
    Ui.column
        [ Ui.spacing 4 ]
        [ Ui.el [ Ui.Font.weight 600 ] (Ui.text turnText)
        , Ui.text ("Black has captured: " ++ String.fromInt snapshot.blackCaptures)
        , Ui.text ("White has captured: " ++ String.fromInt snapshot.whiteCaptures)
        , Ui.text ("Komi: " ++ formatScore model.komi)
        ]


formatScore : Float -> String
formatScore score =
    if score == toFloat (floor score) then
        String.fromInt (floor score)

    else
        String.fromFloat score


winnerSuffix : Float -> Float -> String
winnerSuffix b w =
    if b > w then
        " (Black wins)"

    else if w > b then
        " (White wins)"

    else
        " (tie)"


controlsView : GameModel -> Element Msg
controlsView model =
    let
        phaseButtons : List (Element Msg)
        phaseButtons =
            case model.phase of
                Playing { previousPlayerPassed } ->
                    [ MyUi.simpleButton (Dom.id "go_pass")
                        PressedPass
                        (Ui.text
                            (if previousPlayerPassed then
                                "Pass and mark territory"

                             else
                                "Pass"
                            )
                        )
                    ]

                Marking _ ->
                    [ MyUi.simpleButton (Dom.id "go_doneMarking") PressedDoneMarking (Ui.text "Done marking") ]

                Confirming _ ->
                    [ MyUi.simpleButton (Dom.id "go_agree") PressedAgree (Ui.text "Agree")
                    , MyUi.simpleButton (Dom.id "go_disagree") PressedDisagree (Ui.text "Disagree")
                    ]

                Scored _ ->
                    []
    in
    Ui.row
        [ Ui.spacing 8, Ui.width Ui.shrink ]
        (phaseButtons
            ++ [ MyUi.simpleButton (Dom.id "go_reset") PressedReset (Ui.text "New game") ]
        )


historyView : GameModel -> Element Msg
historyView model =
    let
        total : Int
        total =
            List.length model.history

        currentMove : Int
        currentMove =
            total - model.viewingMovesBack
    in
    if total == 0 then
        Ui.none

    else
        Ui.row
            [ Ui.spacing 8, Ui.width Ui.shrink ]
            [ MyUi.simpleButton (Dom.id "go_arrowLeft") PressedArrowLeft (Ui.html (Icons.arrowLeft 20))
            , Html.input
                [ Html.Attributes.type_ "range"
                , Html.Attributes.min "0"
                , Html.Attributes.max (String.fromInt total)
                , Html.Attributes.value (String.fromInt currentMove)
                , Html.Attributes.style "width" "200px"
                , Html.Events.onInput (\s -> String.toInt s |> Maybe.withDefault currentMove |> ChangedViewingMove)
                ]
                []
                |> Ui.html
                |> Ui.el [ Ui.width (Ui.px 220) ]
            , MyUi.simpleButton (Dom.id "go_arrowRight") PressedArrowRight (Ui.html (Icons.arrowRight 20))
            , Ui.el [ Ui.Font.size 14 ]
                (Ui.text ("Move " ++ String.fromInt currentMove ++ " / " ++ String.fromInt total))
            ]


boardView : GameModel -> Element Msg
boardView model =
    let
        widthPx : Int
        widthPx =
            model.width * cellPx

        heightPx : Int
        heightPx =
            model.height * cellPx

        viewing : Bool
        viewing =
            isViewingPast model

        snapshot : Snapshot
        snapshot =
            viewingSnapshot model

        clickable : Bool
        clickable =
            if viewing then
                True

            else
                case model.phase of
                    Playing _ ->
                        True

                    Marking _ ->
                        True

                    _ ->
                        False

        marks : Dict ( Int, Int ) Stone
        marks =
            if viewing then
                Dict.empty

            else
                model.territoryMarks

        deadSet : Set ( Int, Int )
        deadSet =
            if viewing then
                Set.empty

            else
                deadStonePositions model
    in
    Svg.svg
        [ Svg.Attributes.width (String.fromInt widthPx)
        , Svg.Attributes.height (String.fromInt heightPx)
        , Svg.Attributes.viewBox ("0 0 " ++ String.fromInt widthPx ++ " " ++ String.fromInt heightPx)
        , Svg.Attributes.style "background:#dcb35c;display:block"
        ]
        (gridLines model.width model.height
            ++ starPointShapes model.width model.height
            ++ territoryShapes marks
            ++ stoneShapes deadSet snapshot.board
            ++ (if clickable then
                    clickTargets model.width model.height

                else
                    []
               )
        )
        |> Ui.html
        |> Ui.el [ Ui.width Ui.shrink ]


gridLines : Int -> Int -> List (Svg.Svg Msg)
gridLines width height =
    let
        offset : Int
        offset =
            cellPx // 2

        endX : Int
        endX =
            (width - 1) * cellPx + offset

        endY : Int
        endY =
            (height - 1) * cellPx + offset

        horizontal : List (Svg.Svg Msg)
        horizontal =
            List.range 0 (height - 1)
                |> List.map
                    (\j ->
                        let
                            p : Int
                            p =
                                j * cellPx + offset
                        in
                        Svg.line
                            [ Svg.Attributes.x1 (String.fromInt offset)
                            , Svg.Attributes.y1 (String.fromInt p)
                            , Svg.Attributes.x2 (String.fromInt endX)
                            , Svg.Attributes.y2 (String.fromInt p)
                            , Svg.Attributes.stroke "black"
                            , Svg.Attributes.strokeWidth "1"
                            ]
                            []
                    )

        vertical : List (Svg.Svg Msg)
        vertical =
            List.range 0 (width - 1)
                |> List.map
                    (\i ->
                        let
                            p : Int
                            p =
                                i * cellPx + offset
                        in
                        Svg.line
                            [ Svg.Attributes.x1 (String.fromInt p)
                            , Svg.Attributes.y1 (String.fromInt offset)
                            , Svg.Attributes.x2 (String.fromInt p)
                            , Svg.Attributes.y2 (String.fromInt endY)
                            , Svg.Attributes.stroke "black"
                            , Svg.Attributes.strokeWidth "1"
                            ]
                            []
                    )
    in
    horizontal ++ vertical


starPoints : Int -> Int -> List ( Int, Int )
starPoints width height =
    case ( width, height ) of
        ( 9, 9 ) ->
            [ ( 2, 2 ), ( 6, 2 ), ( 4, 4 ), ( 2, 6 ), ( 6, 6 ) ]

        ( 13, 13 ) ->
            [ ( 3, 3 ), ( 9, 3 ), ( 6, 6 ), ( 3, 9 ), ( 9, 9 ) ]

        ( 19, 19 ) ->
            [ ( 3, 3 )
            , ( 9, 3 )
            , ( 15, 3 )
            , ( 3, 9 )
            , ( 9, 9 )
            , ( 15, 9 )
            , ( 3, 15 )
            , ( 9, 15 )
            , ( 15, 15 )
            ]

        _ ->
            []


starPointShapes : Int -> Int -> List (Svg.Svg Msg)
starPointShapes width height =
    starPoints width height
        |> List.map
            (\( x, y ) ->
                Svg.circle
                    [ Svg.Attributes.cx (String.fromInt (x * cellPx + cellPx // 2))
                    , Svg.Attributes.cy (String.fromInt (y * cellPx + cellPx // 2))
                    , Svg.Attributes.r "3"
                    , Svg.Attributes.fill "black"
                    ]
                    []
            )


stoneShapes : Set ( Int, Int ) -> Dict ( Int, Int ) Stone -> List (Svg.Svg Msg)
stoneShapes dead board =
    Dict.toList board
        |> List.map
            (\( ( x, y ), stone ) ->
                let
                    cx : Int
                    cx =
                        x * cellPx + cellPx // 2

                    cy : Int
                    cy =
                        y * cellPx + cellPx // 2

                    color : String
                    color =
                        case stone of
                            Black ->
                                "black"

                            White ->
                                "white"

                    isDead : Bool
                    isDead =
                        Set.member ( x, y ) dead
                in
                Svg.circle
                    [ Svg.Attributes.cx (String.fromInt cx)
                    , Svg.Attributes.cy (String.fromInt cy)
                    , Svg.Attributes.r (String.fromInt (cellPx // 2 - 2))
                    , Svg.Attributes.fill color
                    , Svg.Attributes.stroke "black"
                    , Svg.Attributes.strokeWidth "1"
                    , Svg.Attributes.opacity
                        (if isDead then
                            "0.35"

                         else
                            "1"
                        )
                    ]
                    []
            )


territoryShapes : Dict ( Int, Int ) Stone -> List (Svg.Svg Msg)
territoryShapes marks =
    Dict.toList marks
        |> List.map
            (\( ( x, y ), stone ) ->
                let
                    cx : Int
                    cx =
                        x * cellPx + cellPx // 2

                    cy : Int
                    cy =
                        y * cellPx + cellPx // 2

                    side : Int
                    side =
                        cellPx // 4

                    color : String
                    color =
                        case stone of
                            Black ->
                                "black"

                            White ->
                                "white"
                in
                Svg.rect
                    [ Svg.Attributes.x (String.fromInt (cx - side // 2))
                    , Svg.Attributes.y (String.fromInt (cy - side // 2))
                    , Svg.Attributes.width (String.fromInt side)
                    , Svg.Attributes.height (String.fromInt side)
                    , Svg.Attributes.fill color
                    , Svg.Attributes.stroke "black"
                    , Svg.Attributes.strokeWidth "1"
                    ]
                    []
            )


clickTargets : Int -> Int -> List (Svg.Svg Msg)
clickTargets width height =
    List.range 0 (width - 1)
        |> List.concatMap
            (\x ->
                List.range 0 (height - 1)
                    |> List.map
                        (\y ->
                            Svg.rect
                                [ Svg.Attributes.x (String.fromInt (x * cellPx))
                                , Svg.Attributes.y (String.fromInt (y * cellPx))
                                , Svg.Attributes.width (String.fromInt cellPx)
                                , Svg.Attributes.height (String.fromInt cellPx)
                                , Svg.Attributes.fill "transparent"
                                , Svg.Attributes.style "cursor:pointer"
                                , Svg.Events.onClick (PressedCell x y)
                                ]
                                []
                        )
            )
