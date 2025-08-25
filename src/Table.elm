module Table exposing
    ( Column
    , Model
    , Msg(..)
    , init
    , tableConfig
    , update
    )

import Effect.Browser.Dom as Dom exposing (HtmlId)
import Icons
import List.Extra
import MyUi
import Ui exposing (Element)
import Ui.Font
import Ui.Input
import Ui.Lazy
import Ui.Table


type alias Model =
    { columnToSortBy : Int, ascendingOrder : Bool, showAll : Bool }


type Msg
    = PressedSortBy Int
    | PressedShowAll


type alias Column msg data =
    { title : String, view : data -> Element msg, sortBy : Maybe (List data -> List data) }


init : Int -> Model
init columnToSortBy =
    { columnToSortBy = columnToSortBy
    , ascendingOrder = False
    , showAll = False
    }


update : Msg -> Model -> Model
update msg model =
    case msg of
        PressedSortBy sortBy ->
            { model
                | columnToSortBy = sortBy
                , ascendingOrder =
                    if sortBy == model.columnToSortBy then
                        not model.ascendingOrder

                    else
                        model.ascendingOrder
                , showAll = False
            }

        PressedShowAll ->
            { model | showAll = True }


headerBackgroundColor : Ui.Attribute msg
headerBackgroundColor =
    Ui.background (Ui.rgb 247 250 252)


cellBorderColor : Ui.Attribute msg
cellBorderColor =
    Ui.borderColor (Ui.rgb 237 242 247)


header : Maybe (Int -> msg) -> Int -> String -> Model -> Ui.Table.Cell msg
header maybePressedSortBy columnIndex name model =
    Ui.row
        [ Ui.spacing 4 ]
        [ Ui.text name
        , case maybePressedSortBy of
            Just _ ->
                Ui.el
                    [ Ui.width (Ui.px 16), Ui.move { x = 0, y = -1, z = 0 } ]
                    (if columnIndex == model.columnToSortBy then
                        if model.ascendingOrder then
                            Icons.sortAscending

                        else
                            Icons.sortDescending

                     else
                        Ui.text ""
                    )

            Nothing ->
                Ui.text ""
        ]
        |> Ui.Table.cell
            [ Ui.borderWith { left = 1, right = 0, top = 0, bottom = 1 }
            , Ui.Font.size 14
            , Ui.Font.bold
            , Ui.contentCenterY
            , headerBackgroundColor
            , cellBorderColor
            , Ui.paddingWith { left = 8, right = 8, top = 0, bottom = 0 }
            , Ui.height (Ui.px headerHeight)
            , case maybePressedSortBy of
                Just pressedSortBy ->
                    Ui.Input.button (pressedSortBy columnIndex)

                Nothing ->
                    Ui.noAttr
            ]


rowOrder : List (Column msg data) -> Model -> List data -> List data
rowOrder userColumns model data =
    case List.Extra.getAt model.columnToSortBy userColumns of
        Just column ->
            case column.sortBy of
                Just sortBy ->
                    let
                        sorted : List data
                        sorted =
                            if model.ascendingOrder then
                                sortBy data |> List.reverse

                            else
                                sortBy data
                    in
                    if model.showAll then
                        sorted

                    else
                        List.take (lastRow + 1) sorted

                Nothing ->
                    data

        _ ->
            data


lastRow : number
lastRow =
    99


headerHeight : number
headerHeight =
    30


tableConfig :
    HtmlId
    -> Bool
    -> (Msg -> msg)
    -> (model -> Model)
    -> List (Column msg data)
    -> Ui.Table.Config model rowState data msg
tableConfig id showAll onMsg getModel userColumns =
    Ui.Table.columns
        (List.indexedMap
            (\columnIndex userColumn ->
                Ui.Table.columnWithState
                    { header =
                        \model ->
                            header
                                (case userColumn.sortBy of
                                    Just _ ->
                                        Just (\index -> PressedSortBy index |> onMsg)

                                    Nothing ->
                                        Nothing
                                )
                                columnIndex
                                userColumn.title
                                (getModel model)
                    , view =
                        \index _ data ->
                            Ui.Table.cell
                                [ Ui.contentCenterY
                                , Ui.padding 0
                                , Ui.borderWith { left = 1, bottom = 1, top = 0, right = 0 }
                                , Ui.height Ui.fill
                                , cellBorderColor
                                ]
                                (if not showAll && index == lastRow then
                                    if columnIndex == 3 then
                                        Ui.el
                                            [ Ui.paddingXY 0 16 ]
                                            (Ui.el
                                                [ Ui.Input.button (onMsg PressedShowAll)
                                                , Dom.idToString id ++ "_showAll" |> Ui.id
                                                , Ui.background MyUi.secondaryGray
                                                , MyUi.focusEffect
                                                , Ui.Font.color (Ui.rgb 0 0 0)
                                                , Ui.rounded 4
                                                , Ui.width Ui.fill
                                                , Ui.Font.center
                                                ]
                                                (Ui.text "Show all")
                                            )

                                    else
                                        Ui.none

                                 else
                                    Ui.Lazy.lazy userColumn.view data
                                )
                    }
            )
            userColumns
        )
        |> Ui.Table.withScrollable { stickFirstColumn = False }
        |> Ui.Table.withSort (\model list -> rowOrder userColumns (getModel model) list)
