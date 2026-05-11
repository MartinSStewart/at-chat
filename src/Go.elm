module Go exposing
    ( Action(..)
    , ActionWithTime
    , CurrentGoMatch
    , GameState
    , LocalChange(..)
    , Model
    , Msg
    , ServerChange
    , Stone(..)
    , ValidatedSetup
    , deadStones
    , foldActions
    , init
    , pressedKey
    , update
    , view
    )

import Array exposing (Array)
import Dict exposing (Dict)
import Duration
import Effect.Browser.Dom as Dom
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Subscription as Subscription exposing (Subscription)
import Effect.Time as Time
import Html
import Html.Attributes
import Html.Events
import Icons
import Id exposing (ChannelMessageId, Id, UserId)
import MyUi
import Ports
import SeqSet exposing (SeqSet)
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


type alias CurrentGoMatch =
    { matchId : Id ChannelMessageId, setup : ValidatedSetup, actions : Array ActionWithTime }


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


type alias GameState =
    { board : Dict ( Int, Int ) Stone
    , lastMove : Maybe ( Int, Int )
    , blackCaptures : Int
    , whiteCaptures : Int
    , territoryMarks : Dict ( Int, Int ) Stone
    , currentPlayer : Stone
    , phase : Phase
    , lastTick : Maybe Time.Posix
    , blackTime : Float
    , whiteTime : Float
    , history : List Snapshot
    }


type alias GameModel =
    { viewingMovesBack : Int
    , lastError : Maybe String
    , id : Id ChannelMessageId
    }


type BoardSize
    = BoardSize Int


boardSize9 : BoardSize
boardSize9 =
    BoardSize 9


boardSize13 : BoardSize
boardSize13 =
    BoardSize 13


boardSize19 : BoardSize
boardSize19 =
    BoardSize 19


boardSizeFromString : String -> Result String BoardSize
boardSizeFromString text =
    case String.toInt (String.trim text) of
        Just n ->
            if n < minDimension then
                Err ("Minimum dimension is " ++ String.fromInt minDimension)

            else if n > maxDimension then
                Err ("Maximum dimension is " ++ String.fromInt maxDimension)

            else
                Ok (BoardSize n)

        Nothing ->
            Err "Enter a number"


boardSizeToInt : BoardSize -> Int
boardSizeToInt (BoardSize a) =
    a


type alias ValidatedSetup =
    { width : BoardSize
    , height : BoardSize
    , handicap : Int
    , komiHalfPoints : KomiHalfPoints
    , timeControl : Maybe TimeControl
    }


type KomiHalfPoints
    = KomiHalfPoints Int


komiHalfPointsFromString : String -> Result String KomiHalfPoints
komiHalfPointsFromString input =
    let
        trimmed : String
        trimmed =
            String.trim input
    in
    if trimmed == "" then
        Ok (KomiHalfPoints 0)

    else
        case String.toFloat trimmed of
            Just n ->
                let
                    halfStones : Int
                    halfStones =
                        round (n * 2)
                in
                if abs (toFloat halfStones - (n * 2)) < 0.0001 then
                    Ok (KomiHalfPoints halfStones)

                else
                    Err "Value must be a value such as 0.5, 1, 2.5"

            Nothing ->
                Err "Enter a number"


komiHalfPointsToString : KomiHalfPoints -> String
komiHalfPointsToString (KomiHalfPoints a) =
    String.fromInt (a // 2)
        ++ (if modBy 2 a == 0 then
                ""

            else
                ".5"
           )


komiHalfPointsToFloat : KomiHalfPoints -> Float
komiHalfPointsToFloat (KomiHalfPoints a) =
    toFloat a / 2


type alias SetupModel =
    { widthInput : String
    , heightInput : String
    , handicapInput : String
    , komiInput : String
    , mainTimeInput : String
    , incrementInput : String
    , sizeSelection : SizeSelection
    , error : Maybe String
    }


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
        , error = Nothing
        }


maxHandicap : Int
maxHandicap =
    9


handicapPositions : ValidatedSetup -> List ( Int, Int )
handicapPositions setup =
    let
        width =
            boardSizeToInt setup.width

        height =
            boardSizeToInt setup.height

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
            case setup.handicap of
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


startGame : Id ChannelMessageId -> GameModel
startGame id =
    { viewingMovesBack = 0
    , lastError = Nothing
    , id = id
    }


initGameState : ValidatedSetup -> GameState
initGameState setup =
    let
        positions : List ( Int, Int )
        positions =
            handicapPositions setup

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
    { blackTime =
        case setup.timeControl of
            Just tc ->
                tc.mainTime

            Nothing ->
                0
    , whiteTime =
        case setup.timeControl of
            Just tc ->
                tc.mainTime

            Nothing ->
                0
    , lastTick = Nothing
    , board = board
    , lastMove = Nothing
    , history = []
    , currentPlayer = startingPlayer
    , blackCaptures = 0
    , whiteCaptures = 0
    , phase = Playing { previousPlayerPassed = False }
    , territoryMarks = Dict.empty
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
    | PressedArrowLeft
    | PressedArrowRight
    | ChangedViewingMove Int
    | ChangedWidthInput String
    | ChangedHeightInput String
    | ChangedHandicapInput String
    | ChangedKomiInput String
    | ChangedMainTimeInput String
    | ChangedIncrementInput String
    | SelectedSize SizeSelection
    | PressedStartGame
    | Tick Time.Posix


type Action
    = PlaceStone Int Int
    | PassTurn
    | MarkTerritory Int Int
    | FinishedMarking
    | AcceptTerritory
    | RejectTerritory


type alias ActionWithTime =
    { time : Time.Posix, change : Action }


type LocalChange
    = StartMatch Time.Posix ValidatedSetup
    | Action ActionWithTime


type alias ServerChange =
    { userId : Id UserId, change : LocalChange }


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


neighbors : ValidatedSetup -> ( Int, Int ) -> List ( Int, Int )
neighbors setup ( x, y ) =
    let
        width =
            boardSizeToInt setup.width

        height =
            boardSizeToInt setup.height
    in
    [ ( x - 1, y ), ( x + 1, y ), ( x, y - 1 ), ( x, y + 1 ) ]
        |> List.filter (\( a, b ) -> a >= 0 && a < width && b >= 0 && b < height)


type alias GroupInfo =
    { stones : Set ( Int, Int )
    , liberties : Set ( Int, Int )
    }


groupAt : ValidatedSetup -> Dict ( Int, Int ) Stone -> ( Int, Int ) -> GroupInfo
groupAt setup board start =
    case Dict.get start board of
        Nothing ->
            { stones = Set.empty, liberties = Set.empty }

        Just stone ->
            floodFill setup board stone [ start ] (Set.singleton start) Set.empty


floodFill :
    ValidatedSetup
    -> Dict ( Int, Int ) Stone
    -> Stone
    -> List ( Int, Int )
    -> Set ( Int, Int )
    -> Set ( Int, Int )
    -> GroupInfo
floodFill setup board stone queue stones liberties =
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
                        (neighbors setup pos)
            in
            floodFill setup board stone newQueue newStones newLiberties


findRegion : ValidatedSetup -> Dict ( Int, Int ) Stone -> ( Int, Int ) -> Set ( Int, Int )
findRegion setup board start =
    if Dict.member start board then
        Set.empty

    else
        regionFlood setup board [ start ] (Set.singleton start)


regionFlood :
    ValidatedSetup
    -> Dict ( Int, Int ) Stone
    -> List ( Int, Int )
    -> Set ( Int, Int )
    -> Set ( Int, Int )
regionFlood setup board queue visited =
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
                        (neighbors setup pos)
            in
            regionFlood setup board newQueue newVisited


currentSnapshot : GameState -> Snapshot
currentSnapshot model =
    { board = model.board
    , currentPlayer = model.currentPlayer
    , blackCaptures = model.blackCaptures
    , whiteCaptures = model.whiteCaptures
    }


applyIncrement : ValidatedSetup -> Stone -> GameState -> GameState
applyIncrement setup mover model =
    case setup.timeControl of
        Just tc ->
            case mover of
                Black ->
                    { model | blackTime = model.blackTime + tc.increment, lastTick = Nothing }

                White ->
                    { model | whiteTime = model.whiteTime + tc.increment, lastTick = Nothing }

        Nothing ->
            { model | lastTick = Nothing }


performPass : ValidatedSetup -> GameState -> GameState
performPass setup model =
    case model.phase of
        Playing { previousPlayerPassed } ->
            if previousPlayerPassed then
                applyIncrement
                    setup
                    model.currentPlayer
                    { model
                        | phase = Marking { markingPlayer = model.currentPlayer }
                    }

            else
                applyIncrement
                    setup
                    model.currentPlayer
                    { model
                        | currentPlayer = otherStone model.currentPlayer
                        , phase = Playing { previousPlayerPassed = True }
                        , lastMove = Nothing
                    }

        _ ->
            model


timeoutPass : ValidatedSetup -> GameState -> GameState
timeoutPass setup model =
    let
        passed : GameState
        passed =
            performPass setup model
    in
    { passed
        | lastTick = Nothing
    }



--
--tickClock : Time.Posix -> GameModel -> GameModel
--tickClock now model =
--    case model.setup.timeControl of
--        Nothing ->
--            model
--
--        Just _ ->
--            case ( model.state.phase, isViewingPast model ) of
--                ( Playing _, False ) ->
--                    let
--                        elapsed : Float
--                        elapsed =
--                            case model.state.lastTick of
--                                Just last ->
--                                    max 0 (Duration.from last now |> Duration.inSeconds)
--
--                                Nothing ->
--                                    0
--
--                        decremented : GameState
--                        decremented =
--                            case model.state.currentPlayer of
--                                Black ->
--                                    { model | blackTime = max 0 (model.state.blackTime - elapsed) }
--
--                                White ->
--                                    { model | whiteTime = max 0 (model.state.whiteTime - elapsed) }
--
--                        currentRemaining : Float
--                        currentRemaining =
--                            case decremented.currentPlayer of
--                                Black ->
--                                    decremented.blackTime
--
--                                White ->
--                                    decremented.whiteTime
--                    in
--                    if currentRemaining <= 0 then
--                        timeoutPass model.setup { decremented | lastTick = Just now }
--
--                    else
--                        { decremented | lastTick = Just now }
--
--                _ ->
--                    { model | lastTick = Just now }


viewingSnapshot : GameState -> GameModel -> Snapshot
viewingSnapshot state model =
    if model.viewingMovesBack <= 0 then
        currentSnapshot state

    else
        case List.drop (model.viewingMovesBack - 1) state.history |> List.head of
            Just snapshot ->
                snapshot

            Nothing ->
                currentSnapshot state


isViewingPast : GameModel -> Bool
isViewingPast model =
    model.viewingMovesBack > 0


jumpToLatest : GameModel -> GameModel
jumpToLatest model =
    { model | viewingMovesBack = 0, lastError = Nothing }


tryPlace : ValidatedSetup -> Int -> Int -> GameState -> Result String GameState
tryPlace setup x y model =
    if Dict.member ( x, y ) model.board then
        Err "There's already a stone there"

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
                                            groupAt setup b n
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
                    (neighbors setup ( x, y ))

            myGroup : GroupInfo
            myGroup =
                groupAt setup boardAfterCapture ( x, y )

            recentBoards : List (Dict ( Int, Int ) Stone)
            recentBoards =
                List.take 10 model.history |> List.map .board
        in
        if Set.isEmpty myGroup.liberties then
            Err "Suicide move not allowed"

        else if List.member boardAfterCapture recentBoards then
            Err "Move repeats a board state"

        else
            applyIncrement
                setup
                stone
                { model
                    | board = boardAfterCapture
                    , lastMove = Just ( x, y )
                    , history = currentSnapshot model :: model.history
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
                }
                |> Ok


cycleOwner : Maybe Stone -> Maybe Stone
cycleOwner current =
    case current of
        Nothing ->
            Just Black

        Just Black ->
            Just White

        Just White ->
            Nothing


cycleTerritory : ValidatedSetup -> Int -> Int -> GameState -> GameState
cycleTerritory setup x y model =
    if Dict.member ( x, y ) model.board then
        model

    else
        let
            region : Set ( Int, Int )
            region =
                findRegion setup model.board ( x, y )

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
        { model | territoryMarks = newMarks }


computeScore : ValidatedSetup -> GameState -> ( Float, Float )
computeScore setup model =
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
            gameDeadContext setup model

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
    , toFloat (whiteTerritory + model.whiteCaptures + 2 * deadBlack) + komiHalfPointsToFloat setup.komiHalfPoints
    )


type alias DeadContext =
    { setup : ValidatedSetup
    , board : Dict ( Int, Int ) Stone
    , territoryMarks : Dict ( Int, Int ) Stone
    }


isStoneDead : DeadContext -> ( Int, Int ) -> Stone -> Bool
isStoneDead ctx pos stone =
    let
        group : GroupInfo
        group =
            groupAt ctx.setup ctx.board pos

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


deadStones : DeadContext -> Set ( Int, Int )
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


gameDeadContext : ValidatedSetup -> GameState -> DeadContext
gameDeadContext setup model =
    { setup = setup
    , board = model.board
    , territoryMarks = model.territoryMarks
    }


deadStonePositions : ValidatedSetup -> GameState -> Set ( Int, Int )
deadStonePositions setup model =
    deadStones (gameDeadContext setup model)


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


update : Time.Posix -> Msg -> Maybe CurrentGoMatch -> Model -> ( Model, Command FrontendOnly toMsg Msg, Maybe LocalChange )
update time msg state model =
    case ( model, state ) of
        ( Game game, Just state2 ) ->
            let
                ( game2, cmd, maybeChange ) =
                    updateGame msg state2.setup (foldActions state2.actions state2.setup) game
            in
            ( game2, cmd, Maybe.map (\change -> Action { time = time, change = change }) maybeChange )

        ( Setup _, Just state2 ) ->
            let
                ( game2, cmd, maybeChange ) =
                    updateGame msg state2.setup (foldActions state2.actions state2.setup) (startGame state2.matchId)
            in
            ( game2, cmd, Maybe.map (\change -> Action { time = time, change = change }) maybeChange )

        ( Setup setup, Nothing ) ->
            updateSetup time msg setup

        ( Game _, Nothing ) ->
            ( model, Command.none, Nothing )


pressedKey : String -> CurrentGoMatch -> Model -> Model
pressedKey key state model =
    case key of
        "ArrowLeft" ->
            stepBack (foldActions state.actions state.setup) model

        "ArrowRight" ->
            stepForward model

        _ ->
            model


stepBack : GameState -> Model -> Model
stepBack state model =
    case model of
        Setup setupModel ->
            model

        Game game ->
            Game
                { game
                    | viewingMovesBack = min (List.length state.history) (game.viewingMovesBack + 1)
                    , lastError = Nothing
                }


stepForward : Model -> Model
stepForward model =
    case model of
        Setup setupModel ->
            model

        Game game ->
            Game
                { game
                    | viewingMovesBack = max 0 (game.viewingMovesBack - 1)
                    , lastError = Nothing
                }


validateSetup : SetupModel -> Result String ValidatedSetup
validateSetup model =
    case selectedDimensions model of
        Ok ( width, height ) ->
            case parseHandicap model.handicapInput of
                Err err ->
                    Err ("Handicap: " ++ err)

                Ok handicap ->
                    case komiHalfPointsFromString model.komiInput of
                        Err err ->
                            Err ("Komi: " ++ err)

                        Ok komiHalfPoints ->
                            case parseTimeControl model of
                                Err err ->
                                    Err err

                                Ok timeControl ->
                                    { width = width
                                    , height = height
                                    , handicap = handicap
                                    , komiHalfPoints = komiHalfPoints
                                    , timeControl = timeControl
                                    }
                                        |> Ok

        Err err ->
            Err err


updateSetup : Time.Posix -> Msg -> SetupModel -> ( Model, Command FrontendOnly toMsg Msg, Maybe LocalChange )
updateSetup time msg model =
    case msg of
        ChangedWidthInput input ->
            ( Setup { model | widthInput = input, error = Nothing }, Command.none, Nothing )

        ChangedHeightInput input ->
            ( Setup { model | heightInput = input, error = Nothing }, Command.none, Nothing )

        ChangedHandicapInput input ->
            ( Setup { model | handicapInput = input, error = Nothing }, Command.none, Nothing )

        ChangedKomiInput input ->
            ( Setup { model | komiInput = input, error = Nothing }, Command.none, Nothing )

        ChangedMainTimeInput input ->
            ( Setup { model | mainTimeInput = input, error = Nothing }, Command.none, Nothing )

        ChangedIncrementInput input ->
            ( Setup { model | incrementInput = input, error = Nothing }, Command.none, Nothing )

        SelectedSize selection ->
            ( Setup { model | sizeSelection = selection, error = Nothing }, Command.none, Nothing )

        PressedStartGame ->
            case validateSetup model of
                Ok setup ->
                    ( Setup model, Command.none, Just (StartMatch time setup) )

                Err error ->
                    ( Setup { model | error = Just error }, Command.none, Nothing )

        _ ->
            ( Setup model, Command.none, Nothing )


selectedDimensions : SetupModel -> Result String ( BoardSize, BoardSize )
selectedDimensions model =
    case model.sizeSelection of
        Standard9 ->
            Ok ( boardSize9, boardSize9 )

        Standard13 ->
            Ok ( boardSize13, boardSize13 )

        Standard19 ->
            Ok ( boardSize19, boardSize19 )

        CustomSize ->
            case ( boardSizeFromString model.widthInput, boardSizeFromString model.heightInput ) of
                ( Ok w, Ok h ) ->
                    Ok ( w, h )

                ( Err err, _ ) ->
                    Err ("Width: " ++ err)

                ( _, Err err ) ->
                    Err ("Height: " ++ err)


foldActions : Array ActionWithTime -> ValidatedSetup -> GameState
foldActions actions setup =
    Array.foldl (updateAction setup) (initGameState setup) actions


updateAction : ValidatedSetup -> ActionWithTime -> GameState -> GameState
updateAction setup { change, time } model =
    case change of
        PlaceStone x y ->
            tryPlace setup x y model |> Result.withDefault model

        PassTurn ->
            applyIncrement setup model.currentPlayer (performPass setup model)

        MarkTerritory x y ->
            cycleTerritory setup x y model

        FinishedMarking ->
            case model.phase of
                Confirming r ->
                    { model | phase = Confirming r }

                _ ->
                    model

        AcceptTerritory ->
            case model.phase of
                Confirming r ->
                    let
                        ( b, w ) =
                            computeScore setup model
                    in
                    { model
                        | phase =
                            Scored
                                { markingPlayer = r.markingPlayer
                                , blackScore = b
                                , whiteScore = w
                                }
                    }

                _ ->
                    model

        RejectTerritory ->
            case model.phase of
                Confirming r ->
                    { model
                        | phase = Playing { previousPlayerPassed = False }
                        , currentPlayer = otherStone r.markingPlayer
                        , territoryMarks = Dict.empty
                    }

                _ ->
                    model


updateGame : Msg -> ValidatedSetup -> GameState -> GameModel -> ( Model, Command FrontendOnly toMsg Msg, Maybe Action )
updateGame msg setup state model =
    case msg of
        PressedCell x y ->
            if isViewingPast model then
                ( Game (jumpToLatest model), Command.none, Nothing )

            else
                case state.phase of
                    Playing _ ->
                        case tryPlace setup x y state of
                            Ok updated ->
                                let
                                    placed : Bool
                                    placed =
                                        updated.lastMove /= state.lastMove
                                in
                                ( Game model
                                , if placed then
                                    Ports.playSound "pop"

                                  else
                                    Command.none
                                , PlaceStone x y |> Just
                                )

                            Err error ->
                                ( Game { model | lastError = Just error }, Command.none, Nothing )

                    Marking _ ->
                        ( Game model, Command.none, MarkTerritory x y |> Just )

                    Confirming _ ->
                        ( Game model, Command.none, Nothing )

                    Scored _ ->
                        ( Game model, Command.none, Nothing )

        PressedPass ->
            if isViewingPast model then
                ( Game (jumpToLatest model), Command.none, Nothing )

            else
                case state.phase of
                    Playing _ ->
                        ( Game model
                        , Command.none
                        , Just PassTurn
                        )

                    _ ->
                        ( Game model, Command.none, Nothing )

        PressedDoneMarking ->
            case state.phase of
                Marking r ->
                    ( Game model, Command.none, Just FinishedMarking )

                _ ->
                    ( Game model, Command.none, Nothing )

        PressedAgree ->
            case state.phase of
                Confirming r ->
                    ( Game model
                    , Command.none
                    , Just AcceptTerritory
                    )

                _ ->
                    ( Game model, Command.none, Nothing )

        PressedDisagree ->
            case state.phase of
                Confirming r ->
                    ( Game model
                    , Command.none
                    , Just RejectTerritory
                    )

                _ ->
                    ( Game model, Command.none, Nothing )

        PressedReset ->
            ( init, Command.none, Nothing )

        ChangedViewingMove moveNumber ->
            let
                total : Int
                total =
                    List.length state.history

                clamped : Int
                clamped =
                    clamp 0 total moveNumber
            in
            ( Game { model | viewingMovesBack = total - clamped, lastError = Nothing }, Command.none, Nothing )

        ChangedWidthInput _ ->
            ( Game model, Command.none, Nothing )

        ChangedHeightInput _ ->
            ( Game model, Command.none, Nothing )

        ChangedHandicapInput _ ->
            ( Game model, Command.none, Nothing )

        ChangedKomiInput _ ->
            ( Game model, Command.none, Nothing )

        ChangedMainTimeInput _ ->
            ( Game model, Command.none, Nothing )

        ChangedIncrementInput _ ->
            ( Game model, Command.none, Nothing )

        SelectedSize _ ->
            ( Game model, Command.none, Nothing )

        PressedStartGame ->
            ( Game model, Command.none, Nothing )

        Tick now ->
            ( Game model, Command.none, Nothing )

        --( Game (tickClock now model), Command.none, Nothing )
        PressedArrowLeft ->
            ( stepBack state (Game model), Command.none, Nothing )

        PressedArrowRight ->
            ( stepForward (Game model), Command.none, Nothing )


cellPx : Int
cellPx =
    40


view : Maybe CurrentGoMatch -> Model -> Element Msg
view state model =
    case ( model, state ) of
        ( Game game, Just state2 ) ->
            gameView state2.setup (foldActions state2.actions state2.setup) game

        ( Setup _, Just state2 ) ->
            gameView state2.setup (foldActions state2.actions state2.setup) (startGame state2.matchId)

        ( Setup setup, Nothing ) ->
            setupView setup

        ( Game _, Nothing ) ->
            Ui.text "Game error"


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


clockView : GameState -> ValidatedSetup -> Element Msg
clockView state setup =
    case setup.timeControl of
        Nothing ->
            Ui.none

        Just _ ->
            Ui.row
                [ Ui.spacing 16, Ui.width Ui.shrink ]
                [ clockChip "Black" state.blackTime (state.currentPlayer == Black && isPlayingPhase state)
                , clockChip "White" state.whiteTime (state.currentPlayer == White && isPlayingPhase state)
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


isPlayingPhase : GameState -> Bool
isPlayingPhase state =
    case state.phase of
        Playing _ ->
            True

        _ ->
            False


gameView : ValidatedSetup -> GameState -> GameModel -> Element Msg
gameView setup state model =
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
                    ++ String.fromInt (boardSizeToInt setup.width)
                    ++ " x "
                    ++ String.fromInt (boardSizeToInt setup.height)
                    ++ ")"
                )
            )
        , statusView setup state model
        , clockView state setup
        , boardView setup state model
        , historyView state model
        , controlsView state
        , case model.lastError of
            Just err ->
                Ui.el [ Ui.Font.color (Ui.rgb 200 50 50) ] (Ui.text err)

            Nothing ->
                Ui.none
        ]


statusView : ValidatedSetup -> GameState -> GameModel -> Element msg
statusView setup state model =
    let
        snapshot : Snapshot
        snapshot =
            viewingSnapshot state model

        turnText : String
        turnText =
            case state.phase of
                Playing _ ->
                    stoneName state.currentPlayer ++ " to move"

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
        , Ui.text ("Komi: " ++ komiHalfPointsToString setup.komiHalfPoints)
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


controlsView : GameState -> Element Msg
controlsView state =
    let
        phaseButtons : List (Element Msg)
        phaseButtons =
            case state.phase of
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


historyView : GameState -> GameModel -> Element Msg
historyView state model =
    let
        total : Int
        total =
            List.length state.history

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


boardView : ValidatedSetup -> GameState -> GameModel -> Element Msg
boardView setup state model =
    let
        width =
            boardSizeToInt setup.width

        height =
            boardSizeToInt setup.height

        widthPx : Int
        widthPx =
            width * cellPx

        heightPx : Int
        heightPx =
            height * cellPx

        viewing : Bool
        viewing =
            isViewingPast model

        snapshot : Snapshot
        snapshot =
            viewingSnapshot state model

        clickable : Bool
        clickable =
            if viewing then
                True

            else
                case state.phase of
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
                state.territoryMarks

        deadSet : Set ( Int, Int )
        deadSet =
            if viewing then
                Set.empty

            else
                deadStonePositions setup state
    in
    Svg.svg
        [ Svg.Attributes.width (String.fromInt widthPx)
        , Svg.Attributes.height (String.fromInt heightPx)
        , Svg.Attributes.viewBox ("0 0 " ++ String.fromInt widthPx ++ " " ++ String.fromInt heightPx)
        , Svg.Attributes.style "background:#dcb35c;display:block"
        ]
        (gridLines width height
            ++ starPointShapes width height
            ++ territoryShapes marks
            ++ stoneShapes deadSet snapshot.board
            ++ lastMoveMarker viewing state
            ++ (if clickable then
                    clickTargets width height

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


lastMoveMarker : Bool -> GameState -> List (Svg.Svg Msg)
lastMoveMarker viewingPast state =
    case ( viewingPast, state.lastMove ) of
        ( False, Just ( x, y ) ) ->
            [ Svg.circle
                [ Svg.Attributes.cx (String.fromInt (x * cellPx + cellPx // 2))
                , Svg.Attributes.cy (String.fromInt (y * cellPx + cellPx // 2))
                , Svg.Attributes.r (String.fromInt (cellPx // 8))
                , Svg.Attributes.fill "rebeccapurple"
                ]
                []
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
