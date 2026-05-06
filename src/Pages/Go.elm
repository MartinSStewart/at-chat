module Pages.Go exposing (Model, Msg, init, update, view)

import Dict exposing (Dict)
import Effect.Browser.Dom as Dom
import MyUi
import Set exposing (Set)
import Svg
import Svg.Attributes
import Svg.Events
import Ui exposing (Element)
import Ui.Font


boardSize : Int
boardSize =
    9


type Stone
    = Black
    | White


type Phase
    = Playing
    | Marking { markingPlayer : Stone }
    | Confirming { markingPlayer : Stone }
    | Scored { markingPlayer : Stone, blackScore : Int, whiteScore : Int }


type alias Model =
    { board : Dict ( Int, Int ) Stone
    , history : List (Dict ( Int, Int ) Stone)
    , currentPlayer : Stone
    , blackCaptures : Int
    , whiteCaptures : Int
    , passes : Int
    , phase : Phase
    , territoryMarks : Dict ( Int, Int ) Stone
    , lastError : Maybe String
    }


init : Model
init =
    { board = Dict.empty
    , history = []
    , currentPlayer = Black
    , blackCaptures = 0
    , whiteCaptures = 0
    , passes = 0
    , phase = Playing
    , territoryMarks = Dict.empty
    , lastError = Nothing
    }


historyLimit : Int
historyLimit =
    10


type Msg
    = PressedCell Int Int
    | PressedPass
    | PressedReset
    | PressedDoneMarking
    | PressedAgree
    | PressedDisagree


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


neighbors : ( Int, Int ) -> List ( Int, Int )
neighbors ( x, y ) =
    [ ( x - 1, y ), ( x + 1, y ), ( x, y - 1 ), ( x, y + 1 ) ]
        |> List.filter (\( a, b ) -> a >= 0 && a < boardSize && b >= 0 && b < boardSize)


type alias GroupInfo =
    { stones : Set ( Int, Int )
    , liberties : Set ( Int, Int )
    }


groupAt : Dict ( Int, Int ) Stone -> ( Int, Int ) -> GroupInfo
groupAt board start =
    case Dict.get start board of
        Nothing ->
            { stones = Set.empty, liberties = Set.empty }

        Just stone ->
            floodFill board stone [ start ] (Set.singleton start) Set.empty


floodFill :
    Dict ( Int, Int ) Stone
    -> Stone
    -> List ( Int, Int )
    -> Set ( Int, Int )
    -> Set ( Int, Int )
    -> GroupInfo
floodFill board stone queue stones liberties =
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
                        (neighbors pos)
            in
            floodFill board stone newQueue newStones newLiberties


findRegion : Dict ( Int, Int ) Stone -> ( Int, Int ) -> Set ( Int, Int )
findRegion board start =
    if Dict.member start board then
        Set.empty

    else
        regionFlood board [ start ] (Set.singleton start)


regionFlood :
    Dict ( Int, Int ) Stone
    -> List ( Int, Int )
    -> Set ( Int, Int )
    -> Set ( Int, Int )
regionFlood board queue visited =
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
                        (neighbors pos)
            in
            regionFlood board newQueue newVisited


tryPlace : Int -> Int -> Model -> Model
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
                                            groupAt b n
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
                    (neighbors ( x, y ))

            myGroup : GroupInfo
            myGroup =
                groupAt boardAfterCapture ( x, y )
        in
        if Set.isEmpty myGroup.liberties then
            { model | lastError = Just "Suicide move not allowed" }

        else if List.member boardAfterCapture model.history then
            { model | lastError = Just "Move repeats a recent board state" }

        else
            { model
                | board = boardAfterCapture
                , history = List.take historyLimit (model.board :: model.history)
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
                , passes = 0
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


cycleTerritory : Int -> Int -> Model -> Model
cycleTerritory x y model =
    if Dict.member ( x, y ) model.board then
        model

    else
        let
            region : Set ( Int, Int )
            region =
                findRegion model.board ( x, y )

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


computeScore : Model -> ( Int, Int )
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

        ( deadBlack, deadWhite ) =
            Dict.foldl
                (\pos stone ( db, dw ) ->
                    if isDeadStone model pos stone then
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
    ( blackTerritory + model.blackCaptures + 2 * deadWhite
    , whiteTerritory + model.whiteCaptures + 2 * deadBlack
    )


isDeadStone : Model -> ( Int, Int ) -> Stone -> Bool
isDeadStone model pos stone =
    let
        empties : List ( Int, Int )
        empties =
            neighbors pos
                |> List.filter (\n -> not (Dict.member n model.board))
    in
    case empties of
        [] ->
            False

        _ ->
            List.all
                (\lib ->
                    Dict.get lib model.territoryMarks == Just (otherStone stone)
                )
                empties


deadStonePositions : Model -> Set ( Int, Int )
deadStonePositions model =
    Dict.foldl
        (\pos stone acc ->
            if isDeadStone model pos stone then
                Set.insert pos acc

            else
                acc
        )
        Set.empty
        model.board


update : Msg -> Model -> Model
update msg model =
    case msg of
        PressedCell x y ->
            case model.phase of
                Playing ->
                    tryPlace x y model

                Marking _ ->
                    cycleTerritory x y model

                Confirming _ ->
                    model

                Scored _ ->
                    model

        PressedPass ->
            case model.phase of
                Playing ->
                    if model.passes >= 1 then
                        let
                            firstPasser : Stone
                            firstPasser =
                                otherStone model.currentPlayer
                        in
                        { model
                            | passes = model.passes + 1
                            , phase = Marking { markingPlayer = firstPasser }
                            , lastError = Nothing
                        }

                    else
                        { model
                            | passes = model.passes + 1
                            , currentPlayer = otherStone model.currentPlayer
                            , lastError = Nothing
                        }

                _ ->
                    model

        PressedDoneMarking ->
            case model.phase of
                Marking r ->
                    { model | phase = Confirming r, lastError = Nothing }

                _ ->
                    model

        PressedAgree ->
            case model.phase of
                Confirming r ->
                    let
                        ( b, w ) =
                            computeScore model
                    in
                    { model
                        | phase =
                            Scored
                                { markingPlayer = r.markingPlayer
                                , blackScore = b
                                , whiteScore = w
                                }
                        , lastError = Nothing
                    }

                _ ->
                    model

        PressedDisagree ->
            case model.phase of
                Confirming r ->
                    { model
                        | phase = Playing
                        , passes = 0
                        , currentPlayer = r.markingPlayer
                        , territoryMarks = Dict.empty
                        , lastError = Just "Marking rejected. Resume play."
                    }

                _ ->
                    model

        PressedReset ->
            init


cellPx : Int
cellPx =
    40


view : Model -> Element Msg
view model =
    Ui.column
        [ Ui.spacing 16
        , Ui.padding 24
        , Ui.centerX
        , Ui.width Ui.shrink
        , MyUi.montserrat
        ]
        [ Ui.el [ Ui.Font.size 28, Ui.Font.weight 700 ] (Ui.text "Go")
        , statusView model
        , boardView model
        , controlsView model
        , case model.lastError of
            Just err ->
                Ui.el [ Ui.Font.color (Ui.rgb 200 50 50) ] (Ui.text err)

            Nothing ->
                Ui.none
        , Ui.el [ Ui.Font.size 14 ] (Ui.text "One device, two players. Pass twice to score.")
        ]


statusView : Model -> Element msg
statusView model =
    let
        turnText : String
        turnText =
            case model.phase of
                Playing ->
                    stoneName model.currentPlayer ++ " to move"

                Marking r ->
                    stoneName r.markingPlayer
                        ++ " marks territory: tap an empty region to cycle owner (none → Black → White)."

                Confirming r ->
                    stoneName (otherStone r.markingPlayer)
                        ++ ": agree with the marking, or disagree to resume play."

                Scored s ->
                    "Final score - Black: "
                        ++ String.fromInt s.blackScore
                        ++ ", White: "
                        ++ String.fromInt s.whiteScore
                        ++ winnerSuffix s.blackScore s.whiteScore
    in
    Ui.column
        [ Ui.spacing 4 ]
        [ Ui.el [ Ui.Font.weight 600 ] (Ui.text turnText)
        , Ui.text ("Black has captured: " ++ String.fromInt model.blackCaptures)
        , Ui.text ("White has captured: " ++ String.fromInt model.whiteCaptures)
        ]


winnerSuffix : Int -> Int -> String
winnerSuffix b w =
    if b > w then
        " (Black wins)"

    else if w > b then
        " (White wins)"

    else
        " (tie)"


controlsView : Model -> Element Msg
controlsView model =
    let
        phaseButtons : List (Element Msg)
        phaseButtons =
            case model.phase of
                Playing ->
                    [ MyUi.simpleButton (Dom.id "go_pass") PressedPass (Ui.text "Pass") ]

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
            ++ [ MyUi.simpleButton (Dom.id "go_reset") PressedReset (Ui.text "Reset") ]
        )


boardView : Model -> Element Msg
boardView model =
    let
        size : Int
        size =
            boardSize * cellPx

        clickable : Bool
        clickable =
            case model.phase of
                Playing ->
                    True

                Marking _ ->
                    True

                _ ->
                    False
    in
    Svg.svg
        [ Svg.Attributes.width (String.fromInt size)
        , Svg.Attributes.height (String.fromInt size)
        , Svg.Attributes.viewBox ("0 0 " ++ String.fromInt size ++ " " ++ String.fromInt size)
        , Svg.Attributes.style "background:#dcb35c;display:block"
        ]
        (gridLines
            ++ territoryShapes model.territoryMarks
            ++ stoneShapes (deadStonePositions model) model.board
            ++ (if clickable then
                    clickTargets

                else
                    []
               )
        )
        |> Ui.html
        |> Ui.el [ Ui.width Ui.shrink ]


gridLines : List (Svg.Svg Msg)
gridLines =
    let
        offset : Int
        offset =
            cellPx // 2

        endPx : Int
        endPx =
            (boardSize - 1) * cellPx + offset
    in
    List.range 0 (boardSize - 1)
        |> List.concatMap
            (\i ->
                let
                    p : Int
                    p =
                        i * cellPx + offset
                in
                [ Svg.line
                    [ Svg.Attributes.x1 (String.fromInt offset)
                    , Svg.Attributes.y1 (String.fromInt p)
                    , Svg.Attributes.x2 (String.fromInt endPx)
                    , Svg.Attributes.y2 (String.fromInt p)
                    , Svg.Attributes.stroke "black"
                    , Svg.Attributes.strokeWidth "1"
                    ]
                    []
                , Svg.line
                    [ Svg.Attributes.x1 (String.fromInt p)
                    , Svg.Attributes.y1 (String.fromInt offset)
                    , Svg.Attributes.x2 (String.fromInt p)
                    , Svg.Attributes.y2 (String.fromInt endPx)
                    , Svg.Attributes.stroke "black"
                    , Svg.Attributes.strokeWidth "1"
                    ]
                    []
                ]
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


clickTargets : List (Svg.Svg Msg)
clickTargets =
    List.range 0 (boardSize - 1)
        |> List.concatMap
            (\x ->
                List.range 0 (boardSize - 1)
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
