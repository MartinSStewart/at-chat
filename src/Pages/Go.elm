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


type alias Model =
    { board : Dict ( Int, Int ) Stone
    , currentPlayer : Stone
    , blackCaptures : Int
    , whiteCaptures : Int
    , passes : Int
    , gameOver : Bool
    , lastError : Maybe String
    }


init : Model
init =
    { board = Dict.empty
    , currentPlayer = Black
    , blackCaptures = 0
    , whiteCaptures = 0
    , passes = 0
    , gameOver = False
    , lastError = Nothing
    }


type Msg
    = PressedCell Int Int
    | PressedPass
    | PressedReset


otherStone : Stone -> Stone
otherStone stone =
    case stone of
        Black ->
            White

        White ->
            Black


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


tryPlace : Int -> Int -> Model -> Model
tryPlace x y model =
    if model.gameOver then
        model

    else if Dict.member ( x, y ) model.board then
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

        else
            { model
                | board = boardAfterCapture
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


update : Msg -> Model -> Model
update msg model =
    case msg of
        PressedCell x y ->
            tryPlace x y model

        PressedPass ->
            let
                newPasses : Int
                newPasses =
                    model.passes + 1
            in
            { model
                | passes = newPasses
                , currentPlayer = otherStone model.currentPlayer
                , gameOver = newPasses >= 2
                , lastError = Nothing
            }

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
        , controlsView
        , case model.lastError of
            Just err ->
                Ui.el [ Ui.Font.color (Ui.rgb 200 50 50) ] (Ui.text err)

            Nothing ->
                Ui.none
        , Ui.el [ Ui.Font.size 14 ] (Ui.text "One device, two players. Pass twice to end the game.")
        ]


statusView : Model -> Element msg
statusView model =
    let
        turnText : String
        turnText =
            if model.gameOver then
                "Game over - both players passed"

            else
                case model.currentPlayer of
                    Black ->
                        "Black to move"

                    White ->
                        "White to move"
    in
    Ui.column
        [ Ui.spacing 4 ]
        [ Ui.el [ Ui.Font.weight 600 ] (Ui.text turnText)
        , Ui.text ("Black has captured: " ++ String.fromInt model.blackCaptures)
        , Ui.text ("White has captured: " ++ String.fromInt model.whiteCaptures)
        ]


controlsView : Element Msg
controlsView =
    Ui.row
        [ Ui.spacing 8, Ui.width Ui.shrink ]
        [ MyUi.simpleButton (Dom.id "go_pass") PressedPass (Ui.text "Pass")
        , MyUi.simpleButton (Dom.id "go_reset") PressedReset (Ui.text "Reset")
        ]


boardView : Model -> Element Msg
boardView model =
    let
        size : Int
        size =
            boardSize * cellPx
    in
    Svg.svg
        [ Svg.Attributes.width (String.fromInt size)
        , Svg.Attributes.height (String.fromInt size)
        , Svg.Attributes.viewBox ("0 0 " ++ String.fromInt size ++ " " ++ String.fromInt size)
        , Svg.Attributes.style "background:#dcb35c;display:block"
        ]
        (gridLines ++ stoneShapes model.board ++ clickTargets)
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


stoneShapes : Dict ( Int, Int ) Stone -> List (Svg.Svg Msg)
stoneShapes board =
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
                in
                Svg.circle
                    [ Svg.Attributes.cx (String.fromInt cx)
                    , Svg.Attributes.cy (String.fromInt cy)
                    , Svg.Attributes.r (String.fromInt (cellPx // 2 - 2))
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
