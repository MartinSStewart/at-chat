module Game exposing (Model, Msg, Shape(..), init, update, view)

import Effect.Browser.Dom as Dom
import MyUi
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import Ui exposing (Element)
import Ui.Font
import Ui.Input


type Shape
    = Circle
    | Square
    | Triangle


type alias CellPos =
    ( Int, Int )


type alias Model =
    { selectedShape : Shape
    , cells : SeqDict CellPos (SeqSet Shape)
    }


type Msg
    = SelectedShape Shape
    | ClickedCell CellPos


gridSize : Int
gridSize =
    6


init : Model
init =
    { selectedShape = Circle
    , cells = SeqDict.empty
    }


update : Msg -> Model -> Model
update msg model =
    case msg of
        SelectedShape shape ->
            { model | selectedShape = shape }

        ClickedCell pos ->
            { model
                | cells =
                    SeqDict.insert pos (SeqSet.singleton model.selectedShape) model.cells
            }


view : Model -> Element Msg
view model =
    Ui.column
        [ Ui.spacing 16
        , Ui.padding 16
        , Ui.width Ui.shrink
        , Ui.centerX
        , Ui.contentCenterY
        ]
        [ Ui.el [ Ui.Font.size 24, Ui.Font.weight 600 ] (Ui.text "Game")
        , palette model.selectedShape
        , grid model.cells
        ]


palette : Shape -> Element Msg
palette selected =
    Ui.row
        [ Ui.spacing 8, Ui.width Ui.shrink ]
        (List.map (paletteButton selected) [ Circle, Square, Triangle ])


paletteButton : Shape -> Shape -> Element Msg
paletteButton selected shape =
    let
        isSelected : Bool
        isSelected =
            shape == selected
    in
    Ui.el
        [ Ui.Input.button (SelectedShape shape)
        , Ui.id (Dom.idToString (paletteId shape))
        , Ui.width (Ui.px 56)
        , Ui.height (Ui.px 56)
        , Ui.borderColor
            (if isSelected then
                Ui.rgb 100 200 255

             else
                MyUi.buttonBorder
            )
        , Ui.border
            (if isSelected then
                3

             else
                1
            )
        , Ui.background MyUi.buttonBackground
        , Ui.rounded 4
        , Ui.contentCenterX
        , Ui.contentCenterY
        ]
        (shapeIcon shape)


grid : SeqDict CellPos (SeqSet Shape) -> Element Msg
grid cells =
    Ui.column [ Ui.spacing 4, Ui.width Ui.shrink ]
        (List.map (gridRow cells) (List.range 0 (gridSize - 1)))


gridRow : SeqDict CellPos (SeqSet Shape) -> Int -> Element Msg
gridRow cells row =
    Ui.row [ Ui.spacing 4, Ui.width Ui.shrink ]
        (List.map (\col -> gridCell cells ( col, row )) (List.range 0 (gridSize - 1)))


gridCell : SeqDict CellPos (SeqSet Shape) -> CellPos -> Element Msg
gridCell cells pos =
    let
        ( col, row ) =
            pos

        contents : Element Msg
        contents =
            case SeqDict.get pos cells |> Maybe.map SeqSet.toList of
                Just (first :: _) ->
                    shapeIcon first

                _ ->
                    Ui.none
    in
    Ui.el
        [ Ui.Input.button (ClickedCell pos)
        , Ui.id (Dom.idToString (cellId col row))
        , Ui.width (Ui.px 48)
        , Ui.height (Ui.px 48)
        , Ui.borderColor MyUi.buttonBorder
        , Ui.border 1
        , Ui.background MyUi.background1
        , Ui.rounded 2
        , Ui.contentCenterX
        , Ui.contentCenterY
        ]
        contents


paletteId : Shape -> Dom.HtmlId
paletteId shape =
    Dom.id ("game_palette_" ++ shapeToString shape)


cellId : Int -> Int -> Dom.HtmlId
cellId col row =
    Dom.id ("game_cell_" ++ String.fromInt col ++ "_" ++ String.fromInt row)


shapeToString : Shape -> String
shapeToString shape =
    case shape of
        Circle ->
            "circle"

        Square ->
            "square"

        Triangle ->
            "triangle"


shapeIcon : Shape -> Element msg
shapeIcon shape =
    let
        glyph : String
        glyph =
            case shape of
                Circle ->
                    "●"

                Square ->
                    "■"

                Triangle ->
                    "▲"
    in
    Ui.el [ Ui.Font.size 28, Ui.Font.center ] (Ui.text glyph)
