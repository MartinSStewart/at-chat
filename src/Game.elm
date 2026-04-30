module Game exposing (Model, Msg, Shape(..), init, update, view)

import Array exposing (Array)
import Effect.Browser.Dom as Dom
import Html
import Html.Attributes
import Html.Events
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


type alias Frame =
    SeqDict CellPos (SeqSet Shape)


type alias Model =
    { selectedShape : Shape
    , frames : Array Frame
    , currentFrame : Int
    }


type Msg
    = SelectedShape Shape
    | ClickedCell CellPos
    | PressedStepBackward
    | PressedStepForward
    | SliderChanged Int


gridSize : Int
gridSize =
    6


init : Model
init =
    { selectedShape = Circle
    , frames = Array.fromList [ SeqDict.empty ]
    , currentFrame = 0
    }


getFrame : Int -> Array Frame -> Maybe Frame
getFrame index frames =
    Array.get index frames


currentFrameData : Model -> Frame
currentFrameData model =
    getFrame model.currentFrame model.frames |> Maybe.withDefault SeqDict.empty


update : Msg -> Model -> Model
update msg model =
    case msg of
        SelectedShape shape ->
            { model | selectedShape = shape }

        ClickedCell pos ->
            let
                frame : Frame
                frame =
                    SeqDict.insert pos (SeqSet.singleton model.selectedShape) (currentFrameData model)
            in
            { model | frames = Array.set model.currentFrame frame model.frames }

        PressedStepBackward ->
            { model | currentFrame = max 0 (model.currentFrame - 1) }

        PressedStepForward ->
            let
                next : Int
                next =
                    model.currentFrame + 1
            in
            if next >= Array.length model.frames then
                { model
                    | frames = Array.push SeqDict.empty model.frames
                    , currentFrame = next
                }

            else
                { model | currentFrame = next }

        SliderChanged index ->
            { model
                | currentFrame =
                    clamp 0 (Array.length model.frames - 1) index
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
        , timeControls model
        , grid
            { previous = getFrame (model.currentFrame - 1) model.frames
            , current = currentFrameData model
            , next = getFrame (model.currentFrame + 1) model.frames
            }
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


timeControls : Model -> Element Msg
timeControls model =
    let
        frameCount : Int
        frameCount =
            Array.length model.frames

        label : String
        label =
            "Frame "
                ++ String.fromInt (model.currentFrame + 1)
                ++ " / "
                ++ String.fromInt frameCount
    in
    Ui.column [ Ui.spacing 8, Ui.width Ui.fill ]
        [ Ui.row [ Ui.spacing 8, Ui.width Ui.shrink, Ui.contentCenterY, Ui.centerX ]
            [ stepButton stepBackId PressedStepBackward "<"
            , Ui.el [ Ui.Font.size 16, Ui.paddingXY 12 0, Ui.width Ui.shrink ] (Ui.text label)
            , stepButton stepForwardId PressedStepForward ">"
            ]
        , slider model
        ]


stepButton : Dom.HtmlId -> Msg -> String -> Element Msg
stepButton htmlId msg label =
    Ui.el
        [ Ui.Input.button msg
        , Ui.id (Dom.idToString htmlId)
        , Ui.width (Ui.px 48)
        , Ui.height (Ui.px 36)
        , Ui.background MyUi.buttonBackground
        , Ui.borderColor MyUi.buttonBorder
        , Ui.border 1
        , Ui.rounded 4
        , Ui.contentCenterX
        , Ui.contentCenterY
        ]
        (Ui.el [ Ui.Font.size 18, Ui.Font.weight 700 ] (Ui.text label))


slider : Model -> Element Msg
slider model =
    let
        maxIndex : Int
        maxIndex =
            max 0 (Array.length model.frames - 1)
    in
    Html.input
        [ Html.Attributes.type_ "range"
        , Html.Attributes.min "0"
        , Html.Attributes.max (String.fromInt maxIndex)
        , Html.Attributes.value (String.fromInt model.currentFrame)
        , Html.Attributes.style "width" "100%"
        , Dom.idToAttribute sliderId
        , Html.Events.onInput
            (\str -> String.toInt str |> Maybe.withDefault model.currentFrame |> SliderChanged)
        ]
        []
        |> Ui.html
        |> Ui.el [ Ui.width Ui.fill ]


grid :
    { previous : Maybe Frame, current : Frame, next : Maybe Frame }
    -> Element Msg
grid frames =
    Ui.column [ Ui.spacing 4, Ui.width Ui.shrink ]
        (List.map (gridRow frames) (List.range 0 (gridSize - 1)))


gridRow :
    { previous : Maybe Frame, current : Frame, next : Maybe Frame }
    -> Int
    -> Element Msg
gridRow frames row =
    Ui.row [ Ui.spacing 4, Ui.width Ui.shrink ]
        (List.map (\col -> gridCell frames ( col, row )) (List.range 0 (gridSize - 1)))


gridCell :
    { previous : Maybe Frame, current : Frame, next : Maybe Frame }
    -> CellPos
    -> Element Msg
gridCell frames pos =
    let
        ( col, row ) =
            pos

        ghostAttrs : List (Ui.Attribute Msg)
        ghostAttrs =
            List.filterMap identity
                [ frames.previous
                    |> Maybe.andThen (cellShape pos)
                    |> Maybe.map (\s -> Ui.behindContent (ghostShape s ghostPreviousColor))
                , frames.next
                    |> Maybe.andThen (cellShape pos)
                    |> Maybe.map (\s -> Ui.behindContent (ghostShape s ghostNextColor))
                ]
    in
    Ui.el
        ([ Ui.Input.button (ClickedCell pos)
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
            ++ ghostAttrs
        )
        (case cellShape pos frames.current of
            Just shape ->
                shapeIcon shape

            Nothing ->
                Ui.none
        )


cellShape : CellPos -> Frame -> Maybe Shape
cellShape pos frame =
    SeqDict.get pos frame
        |> Maybe.andThen (\set -> SeqSet.toList set |> List.head)


ghostPreviousColor : Ui.Color
ghostPreviousColor =
    Ui.rgb 255 110 110


ghostNextColor : Ui.Color
ghostNextColor =
    Ui.rgb 110 180 255


ghostShape : Shape -> Ui.Color -> Element msg
ghostShape shape color =
    Ui.el
        [ Ui.opacity 0.3
        , Ui.Font.color color
        , Ui.width Ui.fill
        , Ui.height Ui.fill
        , Ui.contentCenterX
        , Ui.contentCenterY
        ]
        (shapeIcon shape)


paletteId : Shape -> Dom.HtmlId
paletteId shape =
    Dom.id ("game_palette_" ++ shapeToString shape)


cellId : Int -> Int -> Dom.HtmlId
cellId col row =
    Dom.id ("game_cell_" ++ String.fromInt col ++ "_" ++ String.fromInt row)


stepBackId : Dom.HtmlId
stepBackId =
    Dom.id "game_step_back"


stepForwardId : Dom.HtmlId
stepForwardId =
    Dom.id "game_step_forward"


sliderId : Dom.HtmlId
sliderId =
    Dom.id "game_slider"


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
