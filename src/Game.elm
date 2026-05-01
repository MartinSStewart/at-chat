module Game exposing (Model, Msg, Shape(..), init, update, view)

import Coord exposing (Coord)
import Effect.Browser.Dom as Dom
import Html
import Html.Attributes
import Html.Events
import Id exposing (Id)
import Json.Decode
import List.Nonempty exposing (Nonempty(..))
import MyUi
import NonemptyDict exposing (NonemptyDict)
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import Ui exposing (Element)
import Ui.Font
import Ui.Input


type Shape
    = Player
    | Block


type GridPos
    = CellPos Never


type HorizontalWallPos
    = HorizontalWallPos Never


type VerticalWallPos
    = VerticalWallPos Never


type FrameId
    = FrameId Never


type alias Frame =
    NonemptyDict (Coord GridPos) Shape


type alias Model =
    { selectedShape : Shape
    , frames : SeqDict (Id FrameId) Frame
    , currentFrame : Id FrameId
    , autoAdvance : Bool
    , horizontalWalls : SeqSet (Coord HorizontalWallPos)
    , verticalWalls : SeqSet (Coord VerticalWallPos)
    , start : Coord GridPos
    , exit : Coord GridPos
    }


type Msg
    = SelectedShape Shape
    | ClickedCell (Coord GridPos) Bool
    | PressedStepBackward
    | PressedStepForward
    | SliderChanged (Id FrameId)
    | ToggledAutoAdvance


gridSize : Int
gridSize =
    6


init : Model
init =
    { selectedShape = Player
    , frames = SeqDict.empty
    , currentFrame = Id.fromInt 0
    , autoAdvance = False
    , horizontalWalls = SeqSet.fromList [ Coord.xy 1 2, Coord.xy 3 1, Coord.xy 5 4, Coord.xy 0 3 ]
    , verticalWalls = SeqSet.fromList [ Coord.xy 2 1, Coord.xy 4 3, Coord.xy 1 5, Coord.xy 3 0 ]
    , start = Coord.xy 1 1
    , exit = Coord.xy 2 4
    }


currentFrameData : Model -> Maybe Frame
currentFrameData model =
    SeqDict.get model.currentFrame model.frames


update : Msg -> Model -> Model
update msg model =
    case msg of
        SelectedShape shape ->
            { model | selectedShape = shape }

        ClickedCell pos shiftHeld ->
            { model
                | frames =
                    SeqDict.update
                        model.currentFrame
                        (\maybe ->
                            case maybe of
                                Just frame2 ->
                                    case NonemptyDict.get pos frame2 of
                                        Just shape ->
                                            if shape == model.selectedShape then
                                                NonemptyDict.remove pos frame2 |> NonemptyDict.fromSeqDict

                                            else
                                                NonemptyDict.insert pos model.selectedShape frame2 |> Just

                                        Nothing ->
                                            NonemptyDict.insert pos model.selectedShape frame2 |> Just

                                Nothing ->
                                    NonemptyDict.singleton pos model.selectedShape |> Just
                        )
                        model.frames
                , currentFrame =
                    if model.autoAdvance || shiftHeld then
                        Id.increment model.currentFrame

                    else
                        model.currentFrame
            }

        PressedStepBackward ->
            { model | currentFrame = Id.decrement model.currentFrame }

        PressedStepForward ->
            { model | currentFrame = Id.increment model.currentFrame }

        SliderChanged index ->
            { model | currentFrame = index }

        ToggledAutoAdvance ->
            { model | autoAdvance = not model.autoAdvance }


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
        , autoAdvanceToggle model.autoAdvance
        , timeControls model
        , gridWithWalls model
        ]


cellSize : Int
cellSize =
    48


gridGap : Int
gridGap =
    4


gridStride : Int
gridStride =
    cellSize + gridGap


gridPixelSize : Int
gridPixelSize =
    gridSize * cellSize + (gridSize - 1) * gridGap


wallThickness : Int
wallThickness =
    4


gridWithWalls : Model -> Element Msg
gridWithWalls model =
    Ui.el
        [ Ui.width (Ui.px gridPixelSize)
        , Ui.height (Ui.px gridPixelSize)
        , Ui.inFront (markersLayer model)
        , Ui.inFront (wallsLayer model)
        ]
        (grid
            { previous = SeqDict.get (Id.decrement model.currentFrame) model.frames
            , current = currentFrameData model
            , next = SeqDict.get (Id.increment model.currentFrame) model.frames
            }
        )


markersLayer : Model -> Element msg
markersLayer model =
    Html.div
        [ Html.Attributes.style "position" "absolute"
        , Html.Attributes.style "inset" "0"
        , Html.Attributes.style "pointer-events" "none"
        ]
        [ markerView model.start "S" "rgba(80,200,120,0.35)" "rgb(150,255,180)"
        , markerView model.exit "E" "rgba(220,140,60,0.35)" "rgb(255,210,140)"
        ]
        |> Ui.html


markerView : Coord GridPos -> String -> String -> String -> Html.Html msg
markerView coord letter fillColor textColor =
    Html.div
        [ Html.Attributes.style "position" "absolute"
        , Html.Attributes.style "left" (px (Coord.xRaw coord * gridStride))
        , Html.Attributes.style "top" (px (Coord.yRaw coord * gridStride))
        , Html.Attributes.style "width" (px cellSize)
        , Html.Attributes.style "height" (px cellSize)
        , Html.Attributes.style "background-color" fillColor
        , Html.Attributes.style "border-radius" "2px"
        , Html.Attributes.style "display" "flex"
        , Html.Attributes.style "align-items" "center"
        , Html.Attributes.style "justify-content" "center"
        , Html.Attributes.style "color" textColor
        , Html.Attributes.style "font-weight" "700"
        , Html.Attributes.style "font-size" "22px"
        ]
        [ Html.text letter ]


wallsLayer : Model -> Element msg
wallsLayer model =
    Html.div
        [ Html.Attributes.style "position" "absolute"
        , Html.Attributes.style "inset" "0"
        , Html.Attributes.style "pointer-events" "none"
        ]
        ((SeqSet.toList model.horizontalWalls |> List.map horizontalWallView)
            ++ (SeqSet.toList model.verticalWalls |> List.map verticalWallView)
        )
        |> Ui.html


horizontalWallView : Coord HorizontalWallPos -> Html.Html msg
horizontalWallView coord =
    Html.div
        [ Html.Attributes.style "position" "absolute"
        , Html.Attributes.style "left" (px (Coord.xRaw coord * gridStride))
        , Html.Attributes.style "top" (px (Coord.yRaw coord * gridStride - wallThickness // 2))
        , Html.Attributes.style "width" (px cellSize)
        , Html.Attributes.style "height" (px wallThickness)
        , Html.Attributes.style "background-color" "rgb(255,180,60)"
        , Html.Attributes.style "border-radius" "2px"
        ]
        []


verticalWallView : Coord VerticalWallPos -> Html.Html msg
verticalWallView coord =
    Html.div
        [ Html.Attributes.style "position" "absolute"
        , Html.Attributes.style "left" (px (Coord.xRaw coord * gridStride - wallThickness // 2))
        , Html.Attributes.style "top" (px (Coord.yRaw coord * gridStride))
        , Html.Attributes.style "width" (px wallThickness)
        , Html.Attributes.style "height" (px cellSize)
        , Html.Attributes.style "background-color" "rgb(255,180,60)"
        , Html.Attributes.style "border-radius" "2px"
        ]
        []


px : Int -> String
px n =
    String.fromInt n ++ "px"


palette : Shape -> Element Msg
palette selected =
    Ui.row
        [ Ui.spacing 8, Ui.width Ui.shrink ]
        (List.map (paletteButton selected) [ Player, Block ])


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


autoAdvanceToggle : Bool -> Element Msg
autoAdvanceToggle isOn =
    Ui.row
        [ Ui.Input.button ToggledAutoAdvance
        , Ui.id (Dom.idToString autoAdvanceId)
        , Ui.spacing 8
        , Ui.width Ui.shrink
        , Ui.contentCenterY
        ]
        [ Ui.el
            [ Ui.width (Ui.px 22)
            , Ui.height (Ui.px 22)
            , Ui.background
                (if isOn then
                    Ui.rgb 100 200 255

                 else
                    MyUi.buttonBackground
                )
            , Ui.borderColor MyUi.buttonBorder
            , Ui.border 1
            , Ui.rounded 3
            , Ui.contentCenterX
            , Ui.contentCenterY
            ]
            (if isOn then
                Ui.el [ Ui.Font.size 16, Ui.Font.weight 700 ] (Ui.text "✓")

             else
                Ui.none
            )
        , Ui.el [ Ui.Font.size 14, Ui.width Ui.shrink ] (Ui.text "Auto-advance on placement (or shift+click)")
        ]


autoAdvanceId : Dom.HtmlId
autoAdvanceId =
    Dom.id "game_auto_advance"


timeControls : Model -> Element Msg
timeControls model =
    let
        label : String
        label =
            "Frame " ++ Id.toString model.currentFrame
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
        , Ui.Font.size 18
        , Ui.Font.bold
        ]
        (Ui.text label)


foldFrames : (Id FrameId -> Maybe Frame -> a -> a) -> a -> Model -> a
foldFrames foldFunc startValue model =
    let
        list =
            Nonempty model.currentFrame (SeqDict.keys model.frames)
    in
    foldFramesHelper
        foldFunc
        (List.Nonempty.foldl1 Id.minimum list |> Id.toInt)
        (List.Nonempty.foldl1 Id.maximum list |> Id.toInt)
        model
        startValue


foldFramesHelper : (Id FrameId -> Maybe Frame -> a -> a) -> Int -> Int -> Model -> a -> a
foldFramesHelper foldFunc index endIndex model state =
    if index > endIndex then
        state

    else
        foldFramesHelper
            foldFunc
            (index + 1)
            endIndex
            model
            (foldFunc (Id.fromInt index) (SeqDict.get (Id.fromInt index) model.frames) state)


slider : Model -> Element Msg
slider model =
    foldFrames (\frameId frame list -> sliderSegment model frameId frame :: list) [] model
        |> List.reverse
        |> Ui.row
            [ Ui.spacing 2
            , Ui.width Ui.fill
            , Ui.height (Ui.px 24)
            , Ui.id (Dom.idToString sliderId)
            ]


sliderSegment : Model -> Id FrameId -> Maybe Frame -> Element Msg
sliderSegment model index frame =
    let
        isCurrent : Bool
        isCurrent =
            index == model.currentFrame

        isEmpty : Bool
        isEmpty =
            frame == Nothing

        hasError : Bool
        hasError =
            frameHasError model index frame
    in
    Ui.el
        [ Ui.Input.button (SliderChanged index)
        , Ui.id (Dom.idToString (segmentId index))
        , Ui.background
            (if hasError then
                Ui.rgb 180 50 50

             else if isEmpty then
                Ui.rgb 90 90 100

             else
                Ui.rgb 40 40 50
            )
        , Ui.height Ui.fill
        , Ui.width Ui.fill
        , Ui.rounded 2
        , Ui.border
            (if isCurrent then
                2

             else
                1
            )
        , Ui.borderColor
            (if isCurrent then
                Ui.rgb 100 200 255

             else
                MyUi.buttonBorder
            )
        ]
        Ui.none


frameHasError : Model -> Id FrameId -> Maybe Frame -> Bool
frameHasError model frameId maybeFrame =
    case maybeFrame of
        Just frame ->
            let
                prev : Maybe Frame
                prev =
                    SeqDict.get (Id.decrement frameId) model.frames

                next : Maybe Frame
                next =
                    SeqDict.get (Id.increment frameId) model.frames
            in
            NonemptyDict.any
                (\pos shape ->
                    case shape of
                        Player ->
                            not (linkedToFrame pos prev model.start)
                                || not (linkedToFrame pos next model.exit)

                        Block ->
                            False
                )
                frame

        Nothing ->
            False


linkedToFrame : Coord GridPos -> Maybe Frame -> Coord GridPos -> Bool
linkedToFrame pos otherFrame anchorPos =
    if pos == anchorPos then
        True

    else
        case otherFrame of
            Just frame ->
                List.any
                    (\p -> NonemptyDict.get p frame == Just Player)
                    (pos :: adjacentPositions pos)

            Nothing ->
                False


adjacentPositions : Coord GridPos -> List (Coord GridPos)
adjacentPositions coord =
    let
        x : Int
        x =
            Coord.xRaw coord

        y : Int
        y =
            Coord.yRaw coord
    in
    [ Coord.xy (x - 1) y
    , Coord.xy (x + 1) y
    , Coord.xy x (y - 1)
    , Coord.xy x (y + 1)
    ]


grid :
    { previous : Maybe Frame, current : Maybe Frame, next : Maybe Frame }
    -> Element Msg
grid frames =
    Ui.column [ Ui.spacing 4, Ui.width Ui.shrink ]
        (List.map (gridRow frames) (List.range 0 (gridSize - 1)))


gridRow :
    { previous : Maybe Frame, current : Maybe Frame, next : Maybe Frame }
    -> Int
    -> Element Msg
gridRow frames row =
    Ui.row [ Ui.spacing 4, Ui.width Ui.shrink ]
        (List.map (\col -> gridCell frames (Coord.xy col row)) (List.range 0 (gridSize - 1)))


gridCell :
    { previous : Maybe Frame, current : Maybe Frame, next : Maybe Frame }
    -> Coord GridPos
    -> Element Msg
gridCell frames pos =
    let
        ghostAttrs : List (Ui.Attribute Msg)
        ghostAttrs =
            [ cellShape pos frames.current |> Maybe.map (\s -> Ui.behindContent (shapeIcon s))
            , cellShape pos frames.previous |> Maybe.map (\s -> Ui.behindContent (ghostShape s ghostPreviousColor))
            , cellShape pos frames.next |> Maybe.map (\s -> Ui.behindContent (ghostShape s ghostNextColor))
            ]
                |> List.filterMap identity
                |> List.take 1
    in
    Ui.el
        ([ Ui.htmlAttribute
            (Html.Events.on "click"
                (Json.Decode.field "shiftKey" Json.Decode.bool
                    |> Json.Decode.map (ClickedCell pos)
                )
            )
         , Ui.htmlAttribute (Html.Attributes.style "cursor" "pointer")
         , Ui.id (Dom.idToString (cellId pos))
         , Ui.width (Ui.px 48)
         , Ui.height (Ui.px 48)
         , Ui.borderColor MyUi.buttonBorder
         , Ui.border 1
         , Ui.background MyUi.background1
         , Ui.rounded 2
         ]
            ++ ghostAttrs
        )
        Ui.none


cellShape : Coord GridPos -> Maybe Frame -> Maybe Shape
cellShape pos frame =
    case frame of
        Just frame2 ->
            NonemptyDict.get pos frame2

        Nothing ->
            Nothing


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


cellId : Coord GridPos -> Dom.HtmlId
cellId coord =
    Dom.id ("game_cell_" ++ String.fromInt (Coord.xRaw coord) ++ "_" ++ String.fromInt (Coord.yRaw coord))


stepBackId : Dom.HtmlId
stepBackId =
    Dom.id "game_step_back"


stepForwardId : Dom.HtmlId
stepForwardId =
    Dom.id "game_step_forward"


sliderId : Dom.HtmlId
sliderId =
    Dom.id "game_slider"


segmentId : Id FrameId -> Dom.HtmlId
segmentId index =
    Dom.id ("game_slider_segment_" ++ Id.toString index)


shapeToString : Shape -> String
shapeToString shape =
    case shape of
        Player ->
            "circle"

        Block ->
            "square"


shapeIcon : Shape -> Element msg
shapeIcon shape =
    let
        glyph : String
        glyph =
            case shape of
                Player ->
                    "☺"

                Block ->
                    "■"
    in
    Ui.el
        [ Ui.Font.size 28
        , Ui.Font.center
        , MyUi.htmlStyle "user-select" "none"
        , MyUi.htmlStyle "-webkit-user-select" "none"
        , Ui.centerY
        ]
        (Ui.text glyph)
