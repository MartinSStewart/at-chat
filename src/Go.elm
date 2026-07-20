module Go exposing
    ( Action(..)
    , ActionWithTime
    , BoardSize(..)
    , DeadContext
    , GameModel
    , GameMsg(..)
    , KomiHalfPoints(..)
    , LocalChange(..)
    , Phase(..)
    , PublicGoMatchData
    , PublicGoMatchResponse
    , SetupModel
    , SetupMsg(..)
    , SetupOrGame(..)
    , Shared
    , SizeSelection(..)
    , Snapshot
    , SpectatorMsg(..)
    , Stone(..)
    , TimeControl
    , ValidatedSetup
    , audio
    , boardSize9
    , currentPlayersTurn
    , deadStones
    , dragEnd
    , dragStart
    , foldActions
    , gameView
    , initGame
    , initSetup
    , inputBackgroundColor
    , joinedUser
    , numberInput
    , pressedKey
    , publicGoMatchUrl
    , setupView
    , spectatorView
    , startOrCancel
    , updateAction
    , updateGame
    , updateSetup
    , updateSpectator
    , viewHeight
    )

import Array exposing (Array)
import Audio exposing (Audio)
import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Dict exposing (Dict)
import Duration exposing (Duration)
import Effect.Browser.Dom as Dom
import Effect.Time as Time
import Env
import Html
import Html.Attributes
import Html.Events
import Icons
import Id exposing (GamePublicId, Id, UserId)
import List.Extra
import MyUi
import Quantity
import SecretId exposing (SecretId)
import Set exposing (Set)
import StringExtra
import Svg exposing (Svg)
import Svg.Attributes
import Svg.Events
import Ui exposing (Element)
import Ui.Font
import Ui.Input
import Ui.Lazy
import Ui.Shadow
import User exposing (FrontendUser, LocalUser)


type alias PublicGoMatchData =
    { setup : ValidatedSetup
    , actions : Array ActionWithTime
    , cache : Shared
    , creatorUser : FrontendUser
    , joinedUser : Maybe FrontendUser
    }


type alias PublicGoMatchResponse =
    { setup : ValidatedSetup
    , actions : Array ActionWithTime
    , creatorUser : FrontendUser
    , joinedUser : Maybe FrontendUser
    }


type Stone
    = Black
    | White


{-| OpaqueVariants
-}
type Phase
    = Playing { previousPlayerPassed : Bool }
    | Marking
    | Confirming
    | Scored { blackScore : Float, whiteScore : Float }


type alias Snapshot =
    { board : Dict ( Int, Int ) Stone
    , currentPlayer : Stone
    , blackCaptures : Int
    , whiteCaptures : Int
    }


type alias TimeControl =
    { mainTime : Duration
    , increment : Duration
    }


type alias Shared =
    { board : Dict ( Int, Int ) Stone
    , lastMove : Maybe ( Int, Int )
    , blackCaptures : Int
    , whiteCaptures : Int
    , territoryMarks : Dict ( Int, Int ) Stone
    , currentPlayer : Stone
    , phase : Phase
    , lastAction : Maybe Time.Posix
    , timeLeft : Maybe { white : Duration, black : Duration }
    , history : List Snapshot
    , joinedUserId : Maybe (Id UserId)

    -- How many turn-consuming actions (stone placements and passes) have happened. The clocks
    -- only start counting down once both players have moved, i.e. turnCount reaches 2.
    , turnCount : Int
    }


type alias GameModel =
    { viewingMovesBack : Int
    , lastError : Maybe String
    , lastPlacedStone : Maybe Time.Posix
    }


{-| OpaqueVariants
-}
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
    , createdBy : Id UserId
    , gameCreatorPlayingAs : Stone
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
    , gameCreatorPlayingAs : Stone
    , error : Maybe String
    }


{-| OpaqueVariants
-}
type SizeSelection
    = Standard9
    | Standard13
    | Standard19
    | CustomSize


initSetup : SetupModel
initSetup =
    { widthInput = "9"
    , heightInput = "9"
    , handicapInput = "0"
    , komiInput = "6.5"
    , mainTimeInput = "10"
    , incrementInput = "5"
    , sizeSelection = Standard9
    , gameCreatorPlayingAs = Black
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


initGame : GameModel
initGame =
    { viewingMovesBack = 0, lastError = Nothing, lastPlacedStone = Nothing }


initShared : ValidatedSetup -> Shared
initShared setup =
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
    { timeLeft =
        case setup.timeControl of
            Just tc ->
                Just { white = tc.mainTime, black = tc.mainTime }

            Nothing ->
                Nothing
    , lastAction = Nothing
    , board = board
    , lastMove = Nothing
    , history = []
    , currentPlayer = startingPlayer
    , blackCaptures = 0
    , whiteCaptures = 0
    , phase = Playing { previousPlayerPassed = False }
    , territoryMarks = Dict.empty
    , joinedUserId = Nothing
    , turnCount = 0
    }


minDimension : Int
minDimension =
    2


maxDimension : Int
maxDimension =
    25


{-| OpaqueVariants
-}
type SetupMsg
    = ChangedWidthInput String
    | ChangedHeightInput String
    | ChangedHandicapInput String
    | ChangedKomiInput String
    | ChangedMainTimeInput String
    | ChangedIncrementInput String
    | SelectedSize SizeSelection
    | SelectedPlayingAs Stone
    | PressedStartGame
    | PressedCancel


{-| OpaqueVariants
-}
type GameMsg
    = PressedCell ( Int, Int )
    | PressedPass
    | PressedDoneMarking
    | PressedAgree
    | PressedDisagree
    | PressedJoinGame
    | SpectatorMsg SpectatorMsg


type SpectatorMsg
    = PressedArrowLeft
    | PressedArrowRight
    | ChangedViewingMove Int
    | Spectator_PressedCell ( Int, Int )


type Action
    = PlaceStone Int Int
    | PassTurn
    | MarkTerritory Int Int
    | FinishedMarking
    | AcceptTerritory
    | RejectTerritory
    | Joined (Id UserId)


type alias ActionWithTime =
    { time : Time.Posix, change : Action }


type LocalChange
    = StartMatch Time.Posix ValidatedSetup
    | Action ActionWithTime


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


currentSnapshot : Shared -> Snapshot
currentSnapshot model =
    { board = model.board
    , currentPlayer = model.currentPlayer
    , blackCaptures = model.blackCaptures
    , whiteCaptures = model.whiteCaptures
    }


actualTimeLeft : Time.Posix -> Stone -> Stone -> Duration -> Shared -> Duration
actualTimeLeft currentTime player currentPlayer timeLeft model =
    case model.phase of
        Playing _ ->
            -- The clocks only start once both players have made a move, so that the creator's
            -- opening move doesn't start the countdown for an opponent who hasn't joined yet.
            if player == currentPlayer && model.turnCount >= 2 then
                let
                    elapsedTime =
                        Duration.from (Maybe.withDefault currentTime model.lastAction) currentTime
                in
                timeLeft |> Quantity.minus elapsedTime

            else
                timeLeft

        Marking ->
            timeLeft

        Confirming ->
            timeLeft

        Scored _ ->
            timeLeft


applyIncrement : Time.Posix -> ValidatedSetup -> Stone -> Shared -> Shared
applyIncrement currentTime setup mover model =
    case ( setup.timeControl, model.timeLeft ) of
        ( Just tc, Just { white, black } ) ->
            case mover of
                Black ->
                    { model
                        | timeLeft =
                            { white = white
                            , black = actualTimeLeft currentTime Black mover black model |> Quantity.plus tc.increment
                            }
                                |> Just
                        , lastAction = Just currentTime
                        , turnCount = model.turnCount + 1
                    }

                White ->
                    { model
                        | timeLeft =
                            { white = actualTimeLeft currentTime White mover white model |> Quantity.plus tc.increment
                            , black = black
                            }
                                |> Just
                        , lastAction = Just currentTime
                        , turnCount = model.turnCount + 1
                    }

        _ ->
            { model | lastAction = Just currentTime, turnCount = model.turnCount + 1 }


performPass : Time.Posix -> ValidatedSetup -> Shared -> Shared
performPass currentTime setup model =
    case model.phase of
        Playing { previousPlayerPassed } ->
            if previousPlayerPassed then
                applyIncrement
                    currentTime
                    setup
                    model.currentPlayer
                    { model | phase = Marking, currentPlayer = otherStone model.currentPlayer }

            else
                applyIncrement
                    currentTime
                    setup
                    model.currentPlayer
                    { model
                        | currentPlayer = otherStone model.currentPlayer
                        , phase = Playing { previousPlayerPassed = True }
                        , lastMove = Nothing
                    }

        _ ->
            model


viewingSnapshot : Shared -> GameModel -> Snapshot
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


tryPlace : ValidatedSetup -> Int -> Int -> Shared -> Result String Shared
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


cycleTerritory : ValidatedSetup -> Int -> Int -> Shared -> Shared
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


computeScore : ValidatedSetup -> Shared -> ( Float, Float )
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


gameDeadContext : ValidatedSetup -> Shared -> DeadContext
gameDeadContext setup model =
    { setup = setup
    , board = model.board
    , territoryMarks = model.territoryMarks
    }


deadStonePositions : ValidatedSetup -> Shared -> Set ( Int, Int )
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
                                Ok (Just { mainTime = Duration.minutes minutes, increment = Duration.seconds inc })


pressedKey : String -> Shared -> GameModel -> GameModel
pressedKey key shared model =
    case key of
        "ArrowLeft" ->
            stepBack shared model

        "ArrowRight" ->
            stepForward model

        _ ->
            model


stepBack : Shared -> GameModel -> GameModel
stepBack shared model =
    { model
        | viewingMovesBack = min (List.length shared.history) (model.viewingMovesBack + 1)
        , lastError = Nothing
    }


stepForward : GameModel -> GameModel
stepForward model =
    { model
        | viewingMovesBack = max 0 (model.viewingMovesBack - 1)
        , lastError = Nothing
    }


validateSetup : Id UserId -> SetupModel -> Result String ValidatedSetup
validateSetup creatorId model =
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
                                    , createdBy = creatorId
                                    , gameCreatorPlayingAs = model.gameCreatorPlayingAs
                                    }
                                        |> Ok

        Err err ->
            Err err


type SetupOrGame
    = Setup SetupModel
    | Game GameModel
    | CancelSetup


joinedUser : Array ActionWithTime -> Maybe (Id UserId)
joinedUser array =
    List.Extra.findMap
        (\action ->
            case action.change of
                Joined userId ->
                    Just userId

                _ ->
                    Nothing
        )
        (Array.toList array)


updateSetup :
    Id UserId
    -> SetupMsg
    -> SetupModel
    -> ( SetupOrGame, Maybe ValidatedSetup )
updateSetup creatorId msg model =
    case msg of
        ChangedWidthInput input ->
            ( Setup { model | widthInput = input, error = Nothing }, Nothing )

        ChangedHeightInput input ->
            ( Setup { model | heightInput = input, error = Nothing }, Nothing )

        ChangedHandicapInput input ->
            ( Setup { model | handicapInput = input, error = Nothing }, Nothing )

        ChangedKomiInput input ->
            ( Setup { model | komiInput = input, error = Nothing }, Nothing )

        ChangedMainTimeInput input ->
            ( Setup { model | mainTimeInput = input, error = Nothing }, Nothing )

        ChangedIncrementInput input ->
            ( Setup { model | incrementInput = input, error = Nothing }, Nothing )

        SelectedSize selection ->
            ( Setup { model | sizeSelection = selection, error = Nothing }, Nothing )

        SelectedPlayingAs stone ->
            ( Setup { model | gameCreatorPlayingAs = stone, error = Nothing }, Nothing )

        PressedStartGame ->
            case validateSetup creatorId model of
                Ok setup ->
                    ( Game initGame, Just setup )

                Err error ->
                    ( Setup { model | error = Just error }, Nothing )

        PressedCancel ->
            ( CancelSetup, Nothing )


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


foldActions : ValidatedSetup -> Array ActionWithTime -> Shared
foldActions setup actions =
    Array.foldl (updateAction setup) (initShared setup) actions


updateAction : ValidatedSetup -> ActionWithTime -> Shared -> Shared
updateAction setup action model =
    let
        currentPlayer =
            model.currentPlayer
    in
    if hasTimeToDoAction action.time model then
        case action.change of
            PlaceStone x y ->
                case tryPlace setup x y model of
                    Ok model2 ->
                        applyIncrement action.time setup currentPlayer model2

                    Err _ ->
                        model

            PassTurn ->
                performPass action.time setup model

            MarkTerritory x y ->
                cycleTerritory setup x y model

            FinishedMarking ->
                case model.phase of
                    Marking ->
                        { model
                            | phase = Confirming
                            , currentPlayer = otherStone currentPlayer
                            , lastAction = Just action.time
                        }

                    _ ->
                        model

            AcceptTerritory ->
                case model.phase of
                    Confirming ->
                        let
                            ( b, w ) =
                                computeScore setup model
                        in
                        { model
                            | phase =
                                Scored
                                    { blackScore = b
                                    , whiteScore = w
                                    }
                            , lastAction = Just action.time
                        }

                    _ ->
                        model

            RejectTerritory ->
                case model.phase of
                    Confirming ->
                        { model
                            | phase = Playing { previousPlayerPassed = False }
                            , currentPlayer = otherStone currentPlayer
                            , territoryMarks = Dict.empty
                            , lastAction = Just action.time
                        }

                    _ ->
                        model

            Joined userId ->
                case model.joinedUserId of
                    Just _ ->
                        model

                    Nothing ->
                        { model | joinedUserId = Just userId }

    else
        model


hasTimeToDoAction : Time.Posix -> Shared -> Bool
hasTimeToDoAction time model =
    case model.timeLeft of
        Just { black, white } ->
            actualTimeLeft
                time
                model.currentPlayer
                model.currentPlayer
                (case model.currentPlayer of
                    White ->
                        white

                    Black ->
                        black
                )
                model
                |> Quantity.greaterThanZero

        Nothing ->
            True


updateGame :
    Time.Posix
    -> Id UserId
    -> GameMsg
    -> ValidatedSetup
    -> Shared
    -> GameModel
    -> ( GameModel, Maybe ActionWithTime )
updateGame currentTime currentUserId msg setup state model =
    case msg of
        PressedCell ( x, y ) ->
            if isViewingPast model then
                ( jumpToLatest model, Nothing )

            else
                case state.phase of
                    Playing _ ->
                        if isLocalUsersTurn currentUserId setup state && hasTimeToDoAction currentTime state then
                            case tryPlace setup x y state of
                                Ok _ ->
                                    ( { model | lastPlacedStone = Just currentTime }
                                    , Just { time = currentTime, change = PlaceStone x y }
                                    )

                                Err error ->
                                    ( { model | lastError = Just error }, Nothing )

                        else
                            ( model, Nothing )

                    Marking ->
                        if isLocalUsersTurn currentUserId setup state then
                            ( model
                            , Just { time = currentTime, change = MarkTerritory x y }
                            )

                        else
                            ( model, Nothing )

                    Confirming ->
                        ( model, Nothing )

                    Scored _ ->
                        ( model, Nothing )

        PressedPass ->
            if isViewingPast model then
                ( jumpToLatest model, Nothing )

            else
                case ( state.phase, hasTimeToDoAction currentTime state ) of
                    ( Playing _, True ) ->
                        if isLocalUsersTurn currentUserId setup state then
                            ( model
                            , Just { time = currentTime, change = PassTurn }
                            )

                        else
                            ( model, Nothing )

                    _ ->
                        ( model, Nothing )

        PressedDoneMarking ->
            case state.phase of
                Marking ->
                    ( model
                    , Just { time = currentTime, change = FinishedMarking }
                    )

                _ ->
                    ( model, Nothing )

        PressedAgree ->
            case state.phase of
                Confirming ->
                    ( model
                    , Just { time = currentTime, change = AcceptTerritory }
                    )

                _ ->
                    ( model, Nothing )

        PressedDisagree ->
            case state.phase of
                Confirming ->
                    ( model
                    , Just { time = currentTime, change = RejectTerritory }
                    )

                _ ->
                    ( model, Nothing )

        PressedJoinGame ->
            if state.joinedUserId == Nothing then
                ( model
                , Just { time = currentTime, change = Joined currentUserId }
                )

            else
                ( model, Nothing )

        SpectatorMsg spectatorMsg ->
            ( updateSpectator spectatorMsg state model, Nothing )


updateSpectator : SpectatorMsg -> Shared -> GameModel -> GameModel
updateSpectator msg state model =
    case msg of
        ChangedViewingMove moveNumber ->
            let
                total : Int
                total =
                    List.length state.history

                clamped : Int
                clamped =
                    clamp 0 total moveNumber
            in
            { model | viewingMovesBack = total - clamped, lastError = Nothing }

        PressedArrowLeft ->
            stepBack state model

        PressedArrowRight ->
            stepForward model

        Spectator_PressedCell _ ->
            model


cellPx : Int
cellPx =
    40


boardChromeHeight : Int
boardChromeHeight =
    260


viewHeight : Coord CssPixels -> Int
viewHeight windowSize =
    round (toFloat (Coord.yRaw windowSize * 2) / 3)


publicGoMatchUrl : SecretId GamePublicId -> String
publicGoMatchUrl publicLink =
    Env.domain ++ "/go-match/" ++ SecretId.toString publicLink


setupView : Bool -> Coord CssPixels -> SetupModel -> Element SetupMsg
setupView playingAgainstSelf windowSize model =
    let
        isMobile : Bool
        isMobile =
            MyUi.isMobileAlt windowSize
    in
    Ui.column
        [ Ui.spacing
            (if isMobile then
                12

             else
                16
            )
        , Ui.paddingXY 0 16
        , Ui.background MyUi.tabBackground
        ]
        [ Ui.column
            [ Ui.paddingXY
                (if isMobile then
                    8

                 else
                    16
                )
                0
            , Ui.spacing 16
            ]
            [ setupSection
                "Board size"
                (Ui.Input.chooseOne Ui.row
                    [ Ui.spacing 24, Ui.wrap ]
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
                                    [ Ui.text "Custom"
                                    , dimensionInput "go_widthInput" model.widthInput ChangedWidthInput
                                    , Ui.text "x"
                                    , dimensionInput "go_heightInput" model.heightInput ChangedHeightInput
                                    ]
                                )
                            )
                        ]
                    }
                )
            , if playingAgainstSelf then
                Ui.none

              else
                setupSection
                    "Playing as"
                    (Ui.Input.chooseOne
                        Ui.row
                        [ Ui.spacing 24 ]
                        { onChange = SelectedPlayingAs
                        , selected = Just model.gameCreatorPlayingAs
                        , label = Ui.Input.labelHidden "go_boardSize"
                        , options =
                            [ Ui.Input.option Black (Ui.text "Black")
                            , Ui.Input.option White (Ui.text "White")
                            ]
                        }
                    )
            , setupSection
                "Handicap (Black starts with this many stones; White moves first)"
                (numberInput
                    { htmlId = "go_handicapInput"
                    , width = 60
                    , minValue = 0
                    , maxValue = maxHandicap
                    , value = model.handicapInput
                    , isReadonly = False
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
                    Ui.el [ Ui.Font.color MyUi.dangerRed ] (Ui.text err)

                Nothing ->
                    Ui.none
            ]
        , startOrCancel "go" isMobile PressedCancel PressedStartGame
        ]


startOrCancel : String -> Bool -> msg -> msg -> Element msg
startOrCancel domIdPrefix isMobile pressedCancel pressedStart =
    let
        cancel : Element msg
        cancel =
            Ui.el
                [ Ui.Input.button pressedCancel
                , Ui.id (domIdPrefix ++ "_cancel")
                , Ui.background MyUi.secondaryGray
                , MyUi.focusEffect
                , Ui.border 1
                , Ui.Font.color MyUi.black
                , Ui.contentCenterX
                , Ui.rounded 4
                , Ui.paddingXY
                    16
                    (if isMobile then
                        16

                     else
                        8
                    )
                , Ui.Font.weight 500
                ]
                (Ui.text "Cancel")

        start : Element msg
        start =
            Ui.el
                [ Ui.Input.button pressedStart
                , Ui.borderColor MyUi.buttonBorder
                , Ui.border 1
                , Ui.background MyUi.buttonBackground
                , Ui.rounded 4
                , Ui.id (domIdPrefix ++ "_start")
                , Ui.paddingXY
                    16
                    (if isMobile then
                        16

                     else
                        8
                    )
                , Ui.contentCenterX
                , MyUi.focusEffect
                , Ui.Font.weight 500
                ]
                (Ui.text "Start game")
    in
    if isMobile then
        Ui.column
            [ Ui.paddingXY 8 0, Ui.spacing 8 ]
            [ cancel
            , start
            ]

    else
        Ui.row
            [ Ui.paddingXY 16 0, Ui.spacing 16, Ui.width Ui.shrink ]
            [ start
            , cancel
            ]


sizeOptionView : Element SetupMsg -> Ui.Input.OptionState -> Element SetupMsg
sizeOptionView label status =
    Ui.row
        [ Ui.spacing 10, Ui.alignLeft, Ui.width Ui.shrink, Ui.contentCenterY ]
        [ Ui.el
            [ Ui.width (Ui.px 14)
            , Ui.height (Ui.px 14)
            , Ui.background MyUi.white
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


setupSection : String -> Element SetupMsg -> Element SetupMsg
setupSection title content =
    Ui.column
        [ Ui.spacing 8 ]
        [ Ui.el [ Ui.Font.weight 600 ] (Ui.text title)
        , content
        ]


dimensionInput : String -> String -> (String -> SetupMsg) -> Element SetupMsg
dimensionInput htmlId value onChange =
    numberInput
        { htmlId = htmlId
        , width = 60
        , minValue = minDimension
        , maxValue = maxDimension
        , value = value
        , isReadonly = False
        , onChange = onChange
        }


komiInput : String -> Element SetupMsg
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
    , width : Int
    , minValue : Int
    , maxValue : Int
    , value : String
    , isReadonly : Bool
    , onChange : String -> msg
    }
    -> Element msg
numberInput args =
    Html.input
        [ Html.Attributes.id args.htmlId
        , Html.Attributes.type_ "number"
        , Html.Attributes.min (String.fromInt args.minValue)
        , Html.Attributes.max (String.fromInt args.maxValue)
        , Html.Attributes.value args.value
        , Html.Attributes.disabled args.isReadonly
        , inputBackgroundColor args.isReadonly
        , Html.Attributes.style "font-size" "inherit"
        , Html.Attributes.style "color" "black"
        , Html.Attributes.style "width" (String.fromInt args.width ++ "px")
        , Html.Attributes.style "padding" "4px"
        , Html.Attributes.style "border" ("1px solid " ++ MyUi.colorToStyle MyUi.inputBorder)
        , Html.Attributes.style "border-radius" "4px"
        , Html.Attributes.style "text-align" "right"
        , Html.Events.onInput args.onChange
        ]
        []
        |> Ui.html


inputBackgroundColor : Bool -> Html.Attribute msg
inputBackgroundColor isReadonly =
    Html.Attributes.style
        "background-color"
        (if isReadonly then
            MyUi.colorToStyle MyUi.secondaryGray

         else
            "white"
        )


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


formatClock : Duration -> String
formatClock seconds =
    let
        clamped : Int
        clamped =
            max 0 (floor (Duration.inSeconds seconds))

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


getPlayers : ValidatedSetup -> Shared -> { black : Maybe (Id UserId), white : Maybe (Id UserId) }
getPlayers setup shared =
    case setup.gameCreatorPlayingAs of
        White ->
            { white = Just setup.createdBy, black = shared.joinedUserId }

        Black ->
            { black = Just setup.createdBy, white = shared.joinedUserId }


getPlayersWithUser : PublicGoMatchData -> { black : Maybe ( Id UserId, FrontendUser ), white : Maybe ( Id UserId, FrontendUser ) }
getPlayersWithUser data =
    case data.setup.gameCreatorPlayingAs of
        White ->
            { white = Just ( data.setup.createdBy, data.creatorUser )
            , black = Maybe.map2 Tuple.pair data.cache.joinedUserId data.joinedUser
            }

        Black ->
            { black = Just ( data.setup.createdBy, data.creatorUser )
            , white = Maybe.map2 Tuple.pair data.cache.joinedUserId data.joinedUser
            }


clockView : Time.Posix -> Maybe ( Id UserId, FrontendUser ) -> Maybe ( Id UserId, FrontendUser ) -> Shared -> ValidatedSetup -> Element msg
clockView currentTime blackUser whiteUser state setup =
    let
        gameActive : Bool
        gameActive =
            case state.phase of
                Playing _ ->
                    True

                Marking ->
                    True

                Confirming ->
                    True

                Scored _ ->
                    False
    in
    Ui.row
        [ Ui.spacing 8
        , Ui.paddingXY 16 16
        , Ui.contentCenterX
        ]
        [ clockChip
            blackUser
            (case state.timeLeft of
                Just timeLeft ->
                    actualTimeLeft currentTime Black state.currentPlayer timeLeft.black state |> Just

                Nothing ->
                    Nothing
            )
            (gameActive && state.currentPlayer == Black)
            Black
            (currentScore setup state Black)
        , clockChip
            whiteUser
            (case state.timeLeft of
                Just timeLeft ->
                    actualTimeLeft currentTime White state.currentPlayer timeLeft.white state |> Just

                Nothing ->
                    Nothing
            )
            (gameActive && state.currentPlayer == White)
            White
            (currentScore setup state White)
        ]


currentScore : ValidatedSetup -> Shared -> Stone -> Float
currentScore setup state stone =
    case state.phase of
        Scored s ->
            case stone of
                Black ->
                    s.blackScore

                White ->
                    s.whiteScore

        _ ->
            case stone of
                Black ->
                    toFloat state.blackCaptures

                White ->
                    toFloat state.whiteCaptures + komiHalfPointsToFloat setup.komiHalfPoints


currentPlayersTurn : Array ActionWithTime -> Stone
currentPlayersTurn actions =
    Array.foldl
        (\{ change } stone ->
            case change of
                PlaceStone _ _ ->
                    otherStone stone

                PassTurn ->
                    otherStone stone

                MarkTerritory _ _ ->
                    stone

                FinishedMarking ->
                    otherStone stone

                AcceptTerritory ->
                    otherStone stone

                RejectTerritory ->
                    otherStone stone

                Joined _ ->
                    stone
        )
        Black
        actions


clockChip : Maybe ( Id UserId, FrontendUser ) -> Maybe Duration -> Bool -> Stone -> Float -> Element msg
clockChip maybeUser maybeTimeLeft isActive stone score =
    let
        ( colorA, colorB ) =
            case stone of
                White ->
                    ( Ui.rgb 230 230 230, Ui.rgb 20 20 20 )

                Black ->
                    ( Ui.rgb 20 20 20, MyUi.white )
    in
    Ui.row
        [ Ui.rounded User.profileImageRounding
        , Ui.width (Ui.px 170)
        , Ui.border 2
        , Ui.spacing 8
        , Ui.paddingRight 8
        , Ui.contentCenterY
        , Ui.clip
        , Ui.borderColor
            (case ( isActive, stone ) of
                ( True, Black ) ->
                    Ui.rgb 59 153 252

                ( False, Black ) ->
                    colorA

                ( True, White ) ->
                    Ui.rgb 59 153 252

                ( False, White ) ->
                    colorA
            )
        , Ui.background colorA
        , if isActive then
            Ui.Shadow.shadows [ { x = 0, y = 0, size = 0, blur = 6, color = Ui.rgba 59 153 252 1 } ]

          else
            Ui.noAttr
        ]
        [ (case maybeUser of
            Just ( userId, user ) ->
                User.profileImageNoRounding userId user.icon

            Nothing ->
                Ui.el
                    [ Ui.width (Ui.px User.profileImageSize)
                    , Ui.height (Ui.px User.profileImageSize)
                    ]
                    Ui.none
          )
            |> Ui.el [ Ui.move { x = -1, y = 0, z = 0 }, Ui.width Ui.shrink ]
        , Ui.row
            [ Ui.spacing 20, Ui.alignRight, Ui.Font.size 20, Ui.Font.color colorB ]
            [ case maybeTimeLeft of
                Just timeLeft ->
                    Ui.el
                        [ Ui.Font.bold
                        , Ui.width Ui.shrink
                        , if Quantity.lessThanZero timeLeft then
                            Ui.Font.color
                                (case stone of
                                    White ->
                                        Ui.rgb 175 0 21

                                    Black ->
                                        MyUi.errorColor
                                )

                          else
                            Ui.noAttr
                        ]
                        (Ui.text (formatClock timeLeft))

                Nothing ->
                    Ui.none
            , StringExtra.removeTrailing0s 1 score |> Ui.text
            ]
        ]


isLocalUsersTurn : Id UserId -> ValidatedSetup -> Shared -> Bool
isLocalUsersTurn currentUserId setup shared =
    case shared.phase of
        Scored _ ->
            False

        _ ->
            let
                players =
                    getPlayers setup shared
            in
            case shared.currentPlayer of
                Black ->
                    players.black == Just currentUserId

                White ->
                    players.white == Just currentUserId


spectatorView : Time.Posix -> Coord CssPixels -> PublicGoMatchData -> GameModel -> Element SpectatorMsg
spectatorView currentTime windowSize data model =
    let
        isMobile : Bool
        isMobile =
            MyUi.isMobileAlt windowSize

        state : Shared
        state =
            data.cache

        players =
            getPlayersWithUser data
    in
    Ui.column
        [ Ui.spacing
            (if isMobile then
                8

             else
                16
            )
        , Ui.paddingXY
            0
            (if isMobile then
                8

             else
                16
            )
        , Ui.background MyUi.background1
        ]
        [ statusView currentTime state
        , Ui.column
            [ Ui.width Ui.shrink
            , Ui.background boardColor
            , Ui.rounded 4
            ]
            [ clockView currentTime players.black players.white state data.setup
            , Ui.Lazy.lazy4 boardView windowSize data.setup state model |> Ui.map Spectator_PressedCell
            ]
        , if isMobile then
            Ui.none

          else
            historyView state model
        ]


gameView :
    Time.Posix
    -> Coord CssPixels
    -> LocalUser
    -> ValidatedSetup
    -> Shared
    -> GameModel
    -> Element GameMsg
gameView currentTime windowSize localUser setup shared model =
    let
        isMobile : Bool
        isMobile =
            MyUi.isMobileAlt windowSize

        players =
            getPlayers setup shared
    in
    Ui.column
        [ Ui.spacing
            (if isMobile then
                8

             else
                16
            )
        , Ui.paddingXY
            0
            (if isMobile then
                8

             else
                16
            )
        , Ui.background MyUi.background1
        ]
        [ Ui.column
            []
            [ statusView currentTime shared
            , (if shared.joinedUserId == Nothing && setup.createdBy /= localUser.session.userId then
                Ui.el
                    [ Ui.paddingXY 16 0 ]
                    (MyUi.simpleButton (Dom.id "go_joinGame") PressedJoinGame (Ui.text "Join game"))

               else if isLocalUsersTurn localUser.session.userId setup shared && hasTimeToDoAction currentTime shared then
                case shared.phase of
                    Playing { previousPlayerPassed } ->
                        Ui.el
                            [ Ui.paddingXY 16 0 ]
                            (MyUi.simpleButton
                                (Dom.id "go_pass")
                                PressedPass
                                (Ui.text
                                    (if previousPlayerPassed then
                                        "Pass and mark territory"

                                     else
                                        "Pass"
                                    )
                                )
                            )

                    Marking ->
                        Ui.el
                            [ Ui.paddingXY 16 0 ]
                            (MyUi.simpleButton (Dom.id "go_doneMarking") PressedDoneMarking (Ui.text "Done marking"))

                    Confirming ->
                        Ui.row
                            [ Ui.spacing 8, Ui.paddingXY 16 0 ]
                            [ MyUi.simpleButton (Dom.id "go_agree") PressedAgree (Ui.text "Agree")
                            , MyUi.simpleButton (Dom.id "go_disagree") PressedDisagree (Ui.text "Disagree")
                            ]

                    Scored _ ->
                        Ui.none

               else
                Ui.none
              )
                |> Ui.el [ Ui.height (Ui.px 44), Ui.contentCenterY ]
            ]
        , Ui.column
            [ Ui.width Ui.shrink
            , Ui.background boardColor
            , Ui.rounded 4
            ]
            [ clockView
                currentTime
                (case players.black of
                    Just userId ->
                        User.getUser userId localUser |> Maybe.map (Tuple.pair userId)

                    Nothing ->
                        Nothing
                )
                (case players.white of
                    Just userId ->
                        User.getUser userId localUser |> Maybe.map (Tuple.pair userId)

                    Nothing ->
                        Nothing
                )
                shared
                setup
            , Ui.Lazy.lazy4 boardView windowSize setup shared model |> Ui.map PressedCell
            ]
        , if isMobile then
            Ui.none

          else
            Ui.Lazy.lazy2 historyView shared model |> Ui.map SpectatorMsg
        , case model.lastError of
            Just err ->
                Ui.el [ Ui.Font.color MyUi.dangerRed ] (Ui.text err)

            Nothing ->
                Ui.none
        ]


statusView : Time.Posix -> Shared -> Element msg
statusView currentTime state =
    Ui.el
        [ Ui.Font.weight 600, Ui.paddingXY 16 0 ]
        (Ui.text
            (case state.phase of
                Playing { previousPlayerPassed } ->
                    if hasTimeToDoAction currentTime state then
                        (if previousPlayerPassed then
                            stoneName (otherStone state.currentPlayer) ++ " passed. "

                         else
                            ""
                        )
                            ++ stoneName state.currentPlayer
                            ++ " to move"

                    else
                        case state.currentPlayer of
                            White ->
                                "Black wins! White loses on time."

                            Black ->
                                "White wins! Black loses on time."

                Marking ->
                    stoneName state.currentPlayer
                        ++ " marks territory: tap an empty region to cycle owner (none → Black → White)."

                Confirming ->
                    stoneName (otherStone state.currentPlayer)
                        ++ ": agree with the marking, or disagree to resume play."

                Scored s ->
                    "Final score - Black: "
                        ++ StringExtra.removeTrailing0s 1 s.blackScore
                        ++ ", White: "
                        ++ StringExtra.removeTrailing0s 1 s.whiteScore
                        ++ winnerSuffix s.blackScore s.whiteScore
            )
        )


winnerSuffix : Float -> Float -> String
winnerSuffix b w =
    if b > w then
        " (Black wins)"

    else if w > b then
        " (White wins)"

    else
        " (tie)"


historyView : Shared -> GameModel -> Element SpectatorMsg
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
            [ Ui.spacing 8, Ui.width Ui.shrink, Ui.paddingXY 16 0 ]
            [ MyUi.simpleButton (Dom.id "go_arrowLeft") PressedArrowLeft (Ui.el [ MyUi.hoverText "Previous move" ] (Ui.html (Icons.arrowLeft 20)))
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
            , MyUi.simpleButton (Dom.id "go_arrowRight") PressedArrowRight (Ui.el [ MyUi.hoverText "Next move" ] (Ui.html (Icons.arrowRight 20)))
            , Ui.el [ Ui.Font.bold ] (Ui.text (String.fromInt currentMove ++ " / " ++ String.fromInt total))
            ]


boardView : Coord CssPixels -> ValidatedSetup -> Shared -> GameModel -> Element ( Int, Int )
boardView windowSize setup state model =
    let
        isMobile : Bool
        isMobile =
            MyUi.isMobileAlt windowSize

        width : Int
        width =
            boardSizeToInt setup.width

        height : Int
        height =
            boardSizeToInt setup.height

        widthPx : Int
        widthPx =
            width * cellPx

        heightPx : Int
        heightPx =
            height * cellPx

        availWidthPx : Int
        availWidthPx =
            if isMobile then
                Coord.xRaw windowSize |> max 200

            else
                Coord.xRaw windowSize - MyUi.channelAndGuildColumnWidth windowSize - 64 |> clamp 280 600

        availHeightPx : Int
        availHeightPx =
            viewHeight windowSize - boardChromeHeight |> max 180

        scale : Float
        scale =
            min
                (toFloat availWidthPx / toFloat widthPx)
                (toFloat availHeightPx / toFloat heightPx)
                |> clamp 0.35 1.5

        displayWidth : Int
        displayWidth =
            round (toFloat widthPx * scale)

        displayHeight : Int
        displayHeight =
            round (toFloat heightPx * scale)

        viewing : Bool
        viewing =
            isViewingPast model

        snapshot : Snapshot
        snapshot =
            viewingSnapshot state model

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
        [ Svg.Attributes.width (String.fromInt displayWidth)
        , Svg.Attributes.height (String.fromInt displayHeight)
        , Svg.Attributes.viewBox ("0 0 " ++ String.fromInt widthPx ++ " " ++ String.fromInt heightPx)
        , Svg.Attributes.preserveAspectRatio "xMidYMid meet"
        , Svg.Attributes.style "display:block"
        ]
        (gridLines width height
            ++ starPointShapes width height
            ++ territoryShapes marks
            ++ stoneShapes deadSet snapshot.board
            ++ lastMoveMarker viewing state
            ++ clickTargets (boardSizeToInt setup.width) (boardSizeToInt setup.height)
        )
        |> Ui.html
        |> Ui.el [ Ui.width Ui.shrink, Ui.centerX ]


boardColor : Ui.Color
boardColor =
    Ui.rgb 220 179 92


gridLines : Int -> Int -> List (Svg msg)
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

        horizontal : List (Svg msg)
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

        vertical : List (Svg msg)
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


lastMoveMarker : Bool -> Shared -> List (Svg msg)
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


starPointShapes : Int -> Int -> List (Svg msg)
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


stoneShapes : Set ( Int, Int ) -> Dict ( Int, Int ) Stone -> List (Svg msg)
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


territoryShapes : Dict ( Int, Int ) Stone -> List (Svg msg)
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


clickTargets : Int -> Int -> List (Svg ( Int, Int ))
clickTargets width height =
    List.range 0 (width - 1)
        |> List.concatMap
            (\x ->
                List.range 0 (height - 1)
                    |> List.map
                        (\y ->
                            Svg.rect
                                [ Svg.Attributes.id ("go_cell_" ++ String.fromInt x ++ "_" ++ String.fromInt y)
                                , Svg.Attributes.x (String.fromInt (x * cellPx))
                                , Svg.Attributes.y (String.fromInt (y * cellPx))
                                , Svg.Attributes.width (String.fromInt cellPx)
                                , Svg.Attributes.height (String.fromInt cellPx)
                                , Svg.Attributes.fill "transparent"
                                , Svg.Attributes.style "cursor:pointer"
                                , Svg.Events.onClick ( x, y )
                                ]
                                []
                        )
            )


audio : Audio.Source -> GameModel -> Audio
audio popSound model =
    case model.lastPlacedStone of
        Just placedAt ->
            Audio.audio popSound placedAt

        Nothing ->
            Audio.silence


dragStart : GameModel -> GameModel
dragStart model =
    model


dragEnd : GameModel -> GameModel
dragEnd model =
    model
