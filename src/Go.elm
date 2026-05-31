module Go exposing
    ( Action(..)
    , ActionWithTime
    , BoardSize(..)
    , DeadContext
    , GameModel
    , GameMsg(..)
    , GameState
    , KomiHalfPoints(..)
    , LocalChange(..)
    , MatchData
    , Model(..)
    , Msg(..)
    , OutMsg(..)
    , Phase
    , PublicGoMatchData
    , PublicGoMatchResponse
    , SetupModel
    , SetupMsg(..)
    , SizeSelection(..)
    , Snapshot
    , SpectatorMsg(..)
    , Stone(..)
    , TimeControl
    , ValidatedSetup
    , addAction
    , addPublicLink
    , boardSize9
    , currentPlayersTurn
    , deadStones
    , foldActions
    , hasPendingTurn
    , initGame
    , initMatchData
    , pressedKey
    , spectatorView
    , update
    , updateSpectator
    , view
    )

import Array exposing (Array)
import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Dict exposing (Dict)
import Effect.Browser.Dom as Dom
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Time as Time
import Env
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Icons
import Id exposing (ChannelMessageId, GoMatchPublicId, Id, UserId)
import MyUi
import Ports
import SecretId exposing (SecretId)
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
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
import UserSession exposing (ToBeFilledInByBackend(..))


type alias PublicGoMatchData =
    { setup : ValidatedSetup
    , actions : Array ActionWithTime
    , cache : GameState
    , blackPlayer : FrontendUser
    , whitePlayer : FrontendUser
    }


type alias PublicGoMatchResponse =
    { setup : ValidatedSetup
    , actions : Array ActionWithTime
    , blackPlayer : FrontendUser
    , whitePlayer : FrontendUser
    }


type Stone
    = Black
    | White


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
    , blackPlayer : Id UserId
    , whitePlayer : Id UserId
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


{-| OpaqueVariants
-}
type Model
    = Setup SetupModel
    | Game GameModel


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
    { viewingMovesBack = 0, lastError = Nothing }


initMatchData : ValidatedSetup -> Array ActionWithTime -> Maybe (SecretId GoMatchPublicId) -> MatchData
initMatchData setup actions publicLink =
    { setup = setup, actions = actions, cache = foldActions setup actions, publicLink = publicLink } |> MatchData


addAction : ActionWithTime -> MatchData -> MatchData
addAction action (MatchData match) =
    { match
        | actions = Array.push action match.actions
        , cache = updateAction match.setup action match.cache
    }
        |> MatchData


addPublicLink : SecretId GoMatchPublicId -> MatchData -> MatchData
addPublicLink publicLink (MatchData match) =
    { match | publicLink = Just publicLink } |> MatchData


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


{-| OpaqueVariants
-}
type Msg
    = GameMsg GameMsg
    | SetupMsg SetupMsg
    | SelectedMatch (Maybe (Id ChannelMessageId))
    | PressedReset
    | PressedShareGoMatch (Id ChannelMessageId)
    | PressedCopyLink String
    | NoOpMsg


{-| Opaque
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


{-| Opaque
-}
type GameMsg
    = PressedCell Int Int
    | PressedPass
    | PressedDoneMarking
    | PressedAgree
    | PressedDisagree
    | SpectatorMsg SpectatorMsg


type SpectatorMsg
    = PressedArrowLeft
    | PressedArrowRight
    | ChangedViewingMove Int


type Action
    = PlaceStone Int Int
    | PassTurn
    | MarkTerritory Int Int
    | FinishedMarking
    | AcceptTerritory
    | RejectTerritory


type alias ActionWithTime =
    { time : Time.Posix, change : Action }


{-| OpaqueVariants
-}
type MatchData
    = MatchData
        { setup : ValidatedSetup
        , actions : Array ActionWithTime
        , cache : GameState
        , publicLink : Maybe (SecretId GoMatchPublicId)
        }


type LocalChange
    = StartMatch Time.Posix ValidatedSetup
    | Action (Id ChannelMessageId) ActionWithTime
    | CreatePublicLink (Id ChannelMessageId) (ToBeFilledInByBackend (SecretId GoMatchPublicId))


type OutMsg
    = NoOutMsg
    | OutLocalChange LocalChange
    | OutSelectMatch (Maybe (Id ChannelMessageId))
    | CopyText String


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
                    { model | phase = Marking, currentPlayer = otherStone model.currentPlayer }

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


update :
    Time.Posix
    -> Id UserId
    -> Id UserId
    -> Msg
    -> Maybe (Id ChannelMessageId)
    -> SeqDict (Id ChannelMessageId) MatchData
    -> Maybe Model
    -> ( Maybe Model, Command FrontendOnly toMsg Msg, OutMsg )
update time currentUserId otherUserId msg maybeMatchId matches model =
    case msg of
        PressedReset ->
            ( model, Command.none, OutSelectMatch Nothing )

        SelectedMatch newMatchId ->
            ( model, Command.none, OutSelectMatch newMatchId )

        GameMsg gameMsg ->
            case maybeMatchId of
                Just matchId ->
                    case SeqDict.get matchId matches of
                        Just (MatchData match) ->
                            let
                                ( game2, cmd, maybeChange ) =
                                    updateGame
                                        currentUserId
                                        gameMsg
                                        match.setup
                                        match.cache
                                        (case model of
                                            Just (Game game) ->
                                                game

                                            Just (Setup _) ->
                                                initGame

                                            Nothing ->
                                                initGame
                                        )
                            in
                            ( Just game2
                            , cmd
                            , Maybe.map (\change -> Action matchId { time = time, change = change }) maybeChange
                                |> localChangeToOut
                            )

                        Nothing ->
                            ( model, Command.none, NoOutMsg )

                Nothing ->
                    ( model, Command.none, NoOutMsg )

        SetupMsg setupMsg ->
            case maybeMatchId of
                Just _ ->
                    ( model, Command.none, NoOutMsg )

                Nothing ->
                    let
                        ( model2, cmd, maybeChange ) =
                            updateSetup
                                time
                                currentUserId
                                otherUserId
                                setupMsg
                                (case model of
                                    Just (Game _) ->
                                        initSetup

                                    Just (Setup setup) ->
                                        setup

                                    Nothing ->
                                        initSetup
                                )
                    in
                    ( Just model2, cmd, localChangeToOut maybeChange )

        PressedShareGoMatch matchId ->
            ( model, Command.none, OutLocalChange (CreatePublicLink matchId EmptyPlaceholder) )

        PressedCopyLink text ->
            ( model, Command.none, CopyText text )

        NoOpMsg ->
            ( model, Command.none, NoOutMsg )


localChangeToOut : Maybe LocalChange -> OutMsg
localChangeToOut maybeChange =
    case maybeChange of
        Just change ->
            OutLocalChange change

        Nothing ->
            NoOutMsg


pressedKey :
    String
    -> Maybe (Id ChannelMessageId)
    -> SeqDict (Id ChannelMessageId) MatchData
    -> Maybe Model
    -> Maybe Model
pressedKey key maybeMatchId matches model =
    case maybeMatchId of
        Just matchId ->
            case ( model, SeqDict.get matchId matches ) of
                ( Just (Game model2), Just (MatchData match) ) ->
                    case key of
                        "ArrowLeft" ->
                            stepBack match.cache model2 |> Game |> Just

                        "ArrowRight" ->
                            stepForward model2 |> Game |> Just

                        _ ->
                            Game model2 |> Just

                _ ->
                    model

        Nothing ->
            model


stepBack : GameState -> GameModel -> GameModel
stepBack state model =
    { model
        | viewingMovesBack = min (List.length state.history) (model.viewingMovesBack + 1)
        , lastError = Nothing
    }


stepForward : GameModel -> GameModel
stepForward model =
    { model
        | viewingMovesBack = max 0 (model.viewingMovesBack - 1)
        , lastError = Nothing
    }


validateSetup : Id UserId -> Id UserId -> SetupModel -> Result String ValidatedSetup
validateSetup creatorId otherPlayerId model =
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
                                    let
                                        ( blackPlayer, whitePlayer ) =
                                            case model.gameCreatorPlayingAs of
                                                Black ->
                                                    ( creatorId, otherPlayerId )

                                                White ->
                                                    ( otherPlayerId, creatorId )
                                    in
                                    { width = width
                                    , height = height
                                    , handicap = handicap
                                    , komiHalfPoints = komiHalfPoints
                                    , timeControl = timeControl
                                    , blackPlayer = blackPlayer
                                    , whitePlayer = whitePlayer
                                    }
                                        |> Ok

        Err err ->
            Err err


updateSetup :
    Time.Posix
    -> Id UserId
    -> Id UserId
    -> SetupMsg
    -> SetupModel
    -> ( Model, Command FrontendOnly toMsg Msg, Maybe LocalChange )
updateSetup time creatorId otherPlayerId msg model =
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

        SelectedPlayingAs stone ->
            ( Setup { model | gameCreatorPlayingAs = stone, error = Nothing }, Command.none, Nothing )

        PressedStartGame ->
            case validateSetup creatorId otherPlayerId model of
                Ok setup ->
                    ( Game initGame, Command.none, Just (StartMatch time setup) )

                Err error ->
                    ( Setup { model | error = Just error }, Command.none, Nothing )


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


foldActions : ValidatedSetup -> Array ActionWithTime -> GameState
foldActions setup actions =
    Array.foldl (updateAction setup) (initGameState setup) actions


updateAction : ValidatedSetup -> ActionWithTime -> GameState -> GameState
updateAction setup action model =
    case action.change of
        PlaceStone x y ->
            tryPlace setup x y model |> Result.withDefault model

        PassTurn ->
            applyIncrement setup model.currentPlayer (performPass setup model)

        MarkTerritory x y ->
            cycleTerritory setup x y model

        FinishedMarking ->
            case model.phase of
                Marking ->
                    { model | phase = Confirming, currentPlayer = otherStone model.currentPlayer }

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
                    }

                _ ->
                    model

        RejectTerritory ->
            case model.phase of
                Confirming ->
                    { model
                        | phase = Playing { previousPlayerPassed = False }
                        , currentPlayer = otherStone model.currentPlayer
                        , territoryMarks = Dict.empty
                    }

                _ ->
                    model


updateGame : Id UserId -> GameMsg -> ValidatedSetup -> GameState -> GameModel -> ( Model, Command FrontendOnly toMsg Msg, Maybe Action )
updateGame currentUserId msg setup state model =
    case msg of
        PressedCell x y ->
            if isViewingPast model then
                ( Game (jumpToLatest model), Command.none, Nothing )

            else
                case state.phase of
                    Playing _ ->
                        if isLocalUsersTurn currentUserId setup state then
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

                        else
                            ( Game model, Command.none, Nothing )

                    Marking ->
                        ( Game model, Command.none, MarkTerritory x y |> Just )

                    Confirming ->
                        ( Game model, Command.none, Nothing )

                    Scored _ ->
                        ( Game model, Command.none, Nothing )

        PressedPass ->
            if isViewingPast model then
                ( Game (jumpToLatest model), Command.none, Nothing )

            else
                case state.phase of
                    Playing _ ->
                        if isLocalUsersTurn currentUserId setup state then
                            ( Game model
                            , Command.none
                            , Just PassTurn
                            )

                        else
                            ( Game model, Command.none, Nothing )

                    _ ->
                        ( Game model, Command.none, Nothing )

        PressedDoneMarking ->
            case state.phase of
                Marking ->
                    ( Game model, Command.none, Just FinishedMarking )

                _ ->
                    ( Game model, Command.none, Nothing )

        PressedAgree ->
            case state.phase of
                Confirming ->
                    ( Game model
                    , Command.none
                    , Just AcceptTerritory
                    )

                _ ->
                    ( Game model, Command.none, Nothing )

        PressedDisagree ->
            case state.phase of
                Confirming ->
                    ( Game model
                    , Command.none
                    , Just RejectTerritory
                    )

                _ ->
                    ( Game model, Command.none, Nothing )

        SpectatorMsg spectatorMsg ->
            ( Game (updateSpectator spectatorMsg state model), Command.none, Nothing )


updateSpectator : SpectatorMsg -> GameState -> GameModel -> GameModel
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

        --( Game (tickClock now model), Command.none, Nothing )
        PressedArrowLeft ->
            stepBack state model

        PressedArrowRight ->
            stepForward model


cellPx : Int
cellPx =
    40


boardChromeHeight : Int
boardChromeHeight =
    260


viewHeight : Coord CssPixels -> Int
viewHeight windowSize =
    round (toFloat (Coord.yRaw windowSize * 2) / 3)


view :
    Coord CssPixels
    -> Maybe MyUi.LastCopy
    -> LocalUser
    -> Id UserId
    -> Maybe (Id ChannelMessageId)
    -> SeqDict (Id ChannelMessageId) MatchData
    -> Maybe Model
    -> Element Msg
view windowSize lastCopied localUser otherUserId maybeMatchId matches model =
    let
        isMobile : Bool
        isMobile =
            MyUi.isMobile { windowSize = windowSize }
    in
    Ui.el
        [ Ui.height (Ui.px (viewHeight windowSize))
        , Ui.scrollable
        , Ui.background MyUi.tabBackground
        , Ui.borderWith { left = 0, right = 0, top = 0, bottom = 1 }
        , Ui.borderColor MyUi.border2
        , MyUi.noShrinking
        ]
        (Ui.column
            []
            [ Ui.Lazy.lazy4 matchSwitcherView isMobile lastCopied maybeMatchId matches
            , case maybeMatchId of
                Just matchId ->
                    case SeqDict.get matchId matches of
                        Just match ->
                            Ui.Lazy.lazy4
                                gameView
                                windowSize
                                localUser
                                match
                                (case model of
                                    Just (Game game) ->
                                        game

                                    Just (Setup _) ->
                                        initGame

                                    Nothing ->
                                        initGame
                                )
                                |> Ui.map GameMsg

                        Nothing ->
                            Ui.text "Match not found"

                Nothing ->
                    Ui.Lazy.lazy3
                        setupView
                        (localUser.session.userId == otherUserId)
                        windowSize
                        (case model of
                            Just (Game _) ->
                                initSetup

                            Just (Setup setup) ->
                                setup

                            Nothing ->
                                initSetup
                        )
                        |> Ui.map SetupMsg
            ]
        )


matchSwitcherView : Bool -> Maybe MyUi.LastCopy -> Maybe (Id ChannelMessageId) -> SeqDict (Id ChannelMessageId) MatchData -> Element Msg
matchSwitcherView isMobile lastCopied maybeMatchId matches =
    if SeqDict.isEmpty matches then
        Ui.none

    else
        let
            newMatchValue : String
            newMatchValue =
                " "

            currentValue : String
            currentValue =
                case maybeMatchId of
                    Just matchId ->
                        String.fromInt (Id.toInt matchId)

                    Nothing ->
                        newMatchValue

            onSelect : String -> Msg
            onSelect text =
                if text == newMatchValue then
                    SelectedMatch Nothing

                else
                    case String.toInt text of
                        Just n ->
                            SelectedMatch (Just (Id.fromInt n))

                        Nothing ->
                            SelectedMatch Nothing
        in
        Ui.row
            [ Ui.spacing 8
            , Ui.padding
                (if isMobile then
                    8

                 else
                    12
                )
            , Ui.height Ui.fill
            ]
            [ Ui.el [ Ui.Font.weight 600, Ui.width Ui.shrink ] (Ui.text "View match")
            , Ui.html
                (Html.select
                    [ Html.Attributes.id "go_matchSwitcher"
                    , Html.Attributes.value currentValue
                    , Html.Events.onInput onSelect
                    , Html.Attributes.style "height" "100%"
                    , Html.Attributes.attribute "aria-label" "View match"
                    , Html.Attributes.style "padding"
                        (if isMobile then
                            "4px"

                         else
                            "7px 8px"
                        )
                    , Html.Attributes.style "border" "1px solid rgb(97,104,124)"
                    , Html.Attributes.style "border-radius" "4px"
                    , Html.Attributes.style "font-size"
                        (if isMobile then
                            "14px"

                         else
                            "16px"
                        )
                    , Html.Attributes.style "background-color" "rgb(32,40,70)"
                    , Html.Attributes.style "color" "rgb(255,255,255)"
                    , Html.Attributes.style "cursor" "pointer"
                    ]
                    (Html.option
                        [ Html.Attributes.value newMatchValue
                        , Html.Attributes.selected (maybeMatchId == Nothing)
                        ]
                        [ Html.text "Setup new match" ]
                        :: List.map
                            (\( matchId, _ ) ->
                                let
                                    value : String
                                    value =
                                        Id.toString matchId
                                in
                                Html.option
                                    [ Html.Attributes.value value
                                    , Html.Attributes.selected (Just matchId == maybeMatchId)
                                    ]
                                    [ Html.text ("Match #" ++ value) ]
                            )
                            (SeqDict.toList matches)
                    )
                )
            , MyUi.simpleButton (Dom.id "go_reset") PressedReset (Ui.text "New game")
            , case maybeMatchId of
                Just matchId ->
                    Ui.row
                        [ Ui.spacing 4, Ui.alignRight ]
                        (case SeqDict.get matchId matches of
                            Just (MatchData match) ->
                                case match.publicLink of
                                    Just publicLink ->
                                        [ Ui.text "Share"
                                        , MyUi.copyBox
                                            (Dom.id "go_shareLink")
                                            PressedCopyLink
                                            NoOpMsg
                                            { lastCopied = lastCopied }
                                            (publicGoMatchUrl publicLink)
                                        ]

                                    Nothing ->
                                        [ MyUi.simpleButton
                                            (Dom.id "go_share")
                                            (PressedShareGoMatch matchId)
                                            (Ui.text "Share")
                                        ]

                            Nothing ->
                                [ MyUi.simpleButton
                                    (Dom.id "go_share")
                                    (PressedShareGoMatch matchId)
                                    (Ui.text "Share")
                                ]
                        )

                Nothing ->
                    Ui.none
            ]


publicGoMatchUrl : SecretId GoMatchPublicId -> String
publicGoMatchUrl publicLink =
    Env.domain ++ "/go-match/" ++ SecretId.toString publicLink


setupView : Bool -> Coord CssPixels -> SetupModel -> Element SetupMsg
setupView playingAgainstSelf windowSize model =
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


sizeOptionView : Element SetupMsg -> Ui.Input.OptionState -> Element SetupMsg
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
        , minValue = minDimension
        , maxValue = maxDimension
        , value = value
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


clockView : Maybe FrontendUser -> Maybe FrontendUser -> GameState -> ValidatedSetup -> Element msg
clockView blackUser whiteUser state setup =
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
            setup.blackPlayer
            blackUser
            state.blackTime
            (gameActive && state.currentPlayer == Black)
            Black
            setup
            (currentScore setup state Black)
        , clockChip
            setup.whitePlayer
            whiteUser
            state.whiteTime
            (gameActive && state.currentPlayer == White)
            White
            setup
            (currentScore setup state White)
        ]


currentScore : ValidatedSetup -> GameState -> Stone -> Float
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
        )
        Black
        actions


clockChip : Id UserId -> Maybe FrontendUser -> Float -> Bool -> Stone -> ValidatedSetup -> Float -> Element msg
clockChip userId maybeUser seconds isActive stone setup score =
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
            Just user ->
                User.profileImageNoRounding userId user.icon

            Nothing ->
                User.profileImageNoRounding userId Nothing
          )
            |> Ui.el [ Ui.move { x = -1, y = 0, z = 0 } ]
        , Ui.row
            [ Ui.spacing 16, Ui.alignRight ]
            [ case setup.timeControl of
                Just _ ->
                    Ui.el
                        [ Ui.Font.weight 600
                        , Ui.width Ui.shrink
                        , Ui.Font.size 20
                        , Ui.Font.color colorB
                        ]
                        (Ui.text (formatClock seconds))

                Nothing ->
                    Ui.none
            , Ui.row
                [ Ui.Font.color
                    (case stone of
                        White ->
                            Ui.rgb 20 20 20

                        Black ->
                            Ui.rgb 230 230 230
                    )
                , Ui.spacing 4
                , Ui.contentCenterY
                , Ui.Font.letterSpacing -1
                , Ui.Font.bold
                ]
                [ Ui.el
                    [ Ui.width (Ui.px 16)
                    , Ui.height (Ui.px 16)
                    , Ui.background colorB
                    , Ui.rounded 99
                    ]
                    Ui.none
                , StringExtra.removeTrailing0s 1 score |> Ui.text
                ]
            ]
        ]


isLocalUsersTurn : Id UserId -> ValidatedSetup -> GameState -> Bool
isLocalUsersTurn currentUserId setup state =
    case state.currentPlayer of
        Black ->
            setup.blackPlayer == currentUserId

        White ->
            setup.whitePlayer == currentUserId


hasPendingTurn : Id UserId -> SeqDict (Id ChannelMessageId) MatchData -> SeqSet (Id ChannelMessageId)
hasPendingTurn userId matches =
    SeqDict.foldl
        (\matchId (MatchData match) set ->
            case match.cache.phase of
                Scored _ ->
                    set

                _ ->
                    if isLocalUsersTurn userId match.setup match.cache then
                        SeqSet.insert matchId set

                    else
                        set
        )
        SeqSet.empty
        matches


spectatorView : Coord CssPixels -> PublicGoMatchData -> GameModel -> Element SpectatorMsg
spectatorView windowSize data model =
    let
        isMobile : Bool
        isMobile =
            MyUi.isMobile { windowSize = windowSize }

        state : GameState
        state =
            data.cache
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
        [ statusView state
        , Ui.column
            [ Ui.width Ui.shrink
            , Ui.background boardColor
            , Ui.rounded 4
            ]
            [ clockView (Just data.blackPlayer) (Just data.whitePlayer) state data.setup
            , boardView windowSize [] data.setup state model
            ]
        , if isMobile then
            Ui.none

          else
            historyView state model
        ]


gameView :
    Coord CssPixels
    -> LocalUser
    -> MatchData
    -> GameModel
    -> Element GameMsg
gameView windowSize localUser (MatchData data) model =
    let
        isMobile : Bool
        isMobile =
            MyUi.isMobile { windowSize = windowSize }

        state : GameState
        state =
            data.cache

        clickable : Bool
        clickable =
            if isViewingPast model then
                True

            else
                case state.phase of
                    Playing _ ->
                        isLocalUsersTurn localUser.session.userId data.setup state

                    Marking ->
                        True

                    _ ->
                        False
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
        [ statusView state
        , Ui.column
            [ Ui.width Ui.shrink
            , Ui.background boardColor
            , Ui.rounded 4
            ]
            [ clockView
                (User.getUser data.setup.blackPlayer localUser)
                (User.getUser data.setup.whitePlayer localUser)
                state
                data.setup
            , boardView
                windowSize
                (if clickable then
                    clickTargets (boardSizeToInt data.setup.width) (boardSizeToInt data.setup.height)

                 else
                    []
                )
                data.setup
                state
                model
            ]
        , if isMobile then
            Ui.none

          else
            historyView state model |> Ui.map SpectatorMsg
        , if isLocalUsersTurn localUser.session.userId data.setup state then
            controlsView state

          else
            Ui.none
        , case model.lastError of
            Just err ->
                Ui.el [ Ui.Font.color (Ui.rgb 200 50 50) ] (Ui.text err)

            Nothing ->
                Ui.none
        ]


statusView : GameState -> Element msg
statusView state =
    let
        turnText : String
        turnText =
            case state.phase of
                Playing _ ->
                    stoneName state.currentPlayer ++ " to move"

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
    in
    Ui.column
        [ Ui.spacing 4, Ui.paddingXY 16 0 ]
        [ Ui.el [ Ui.Font.weight 600 ] (Ui.text turnText) ]


winnerSuffix : Float -> Float -> String
winnerSuffix b w =
    if b > w then
        " (Black wins)"

    else if w > b then
        " (White wins)"

    else
        " (tie)"


controlsView : GameState -> Element GameMsg
controlsView state =
    let
        phaseButtons : List (Element GameMsg)
        phaseButtons =
            case state.phase of
                Playing { previousPlayerPassed } ->
                    [ MyUi.simpleButton
                        (Dom.id "go_pass")
                        PressedPass
                        (Ui.text
                            (if previousPlayerPassed then
                                "Pass and mark territory"

                             else
                                "Pass"
                            )
                        )
                    ]

                Marking ->
                    [ MyUi.simpleButton (Dom.id "go_doneMarking") PressedDoneMarking (Ui.text "Done marking") ]

                Confirming ->
                    [ MyUi.simpleButton (Dom.id "go_agree") PressedAgree (Ui.text "Agree")
                    , MyUi.simpleButton (Dom.id "go_disagree") PressedDisagree (Ui.text "Disagree")
                    ]

                Scored _ ->
                    []
    in
    Ui.row
        [ Ui.spacing 8, Ui.width Ui.shrink, Ui.paddingXY 16 0 ]
        phaseButtons


historyView : GameState -> GameModel -> Element SpectatorMsg
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


boardView : Coord CssPixels -> List (Html msg) -> ValidatedSetup -> GameState -> GameModel -> Element msg
boardView windowSize overlay setup state model =
    let
        isMobile : Bool
        isMobile =
            MyUi.isMobile { windowSize = windowSize }

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
            ++ overlay
        )
        |> Ui.html
        |> Ui.el
            [ Ui.width Ui.shrink
            , if isMobile then
                Ui.centerX

              else
                Ui.noAttr
            ]


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


lastMoveMarker : Bool -> GameState -> List (Svg msg)
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


clickTargets : Int -> Int -> List (Svg GameMsg)
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
                                , Svg.Events.onClick (PressedCell x y)
                                ]
                                []
                        )
            )
