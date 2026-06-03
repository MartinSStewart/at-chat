module ImageViewer exposing (Model, Msg(..), init, isPressMsg, update, view)

{-| A fullscreen overlay for viewing an image. The image is shown on top of a
black background and can be zoomed and dragged around.

This is rendered as an overlay (instead of navigating away or opening a new tab)
so that the channel underneath keeps rendering and doesn't lose its scroll
position.

On desktop there are +/- buttons to zoom and an x button (top right) to close.
On mobile those buttons are hidden (taps on them are swallowed by the touch
handlers used for dragging); instead you pinch to zoom and drag the image off
the edge of the screen to dismiss it.

-}

import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Html
import Html.Attributes
import Html.Events
import Html.Events.Extra.Touch
import Icons
import Json.Decode
import MyUi
import Ui exposing (Element)
import Ui.Font


type alias Model =
    { imageUrl : String
    , imageSize : Coord CssPixels
    , scale : Float
    , offsetX : Float
    , offsetY : Float
    , interaction : Interaction
    }


type Interaction
    = NoInteraction
    | Dragging
        { startX : Float
        , startY : Float
        , offsetStartX : Float
        , offsetStartY : Float
        }
    | Pinching
        { startDistance : Float
        , startScale : Float
        }


type Msg
    = PressedClose
    | PressedZoomIn
    | PressedZoomOut
    | MouseDown Float Float
    | MouseMove Float Float
    | MouseUp
    | Wheeled Float Float Float
    | TouchStart (List ( Float, Float ))
    | TouchMove (List ( Float, Float ))
    | TouchEnd


init : { url : String, imageSize : Coord CssPixels } -> Model
init { url, imageSize } =
    { imageUrl = url
    , imageSize = imageSize
    , scale = 1
    , offsetX = 0
    , offsetY = 0
    , interaction = NoInteraction
    }


{-| Returns Nothing when the viewer should be closed (the close button was
pressed, or the image was dragged off the screen).
-}
update : Coord CssPixels -> Msg -> Model -> Maybe Model
update windowSize msg model =
    case msg of
        PressedClose ->
            Nothing

        PressedZoomIn ->
            Just { model | scale = clampScale (model.scale * 1.25) }

        PressedZoomOut ->
            Just { model | scale = clampScale (model.scale / 1.25) }

        MouseDown x y ->
            Just { model | interaction = startDrag x y model }

        MouseMove x y ->
            Just (continueDrag x y model)

        MouseUp ->
            endInteraction windowSize model

        Wheeled deltaY x y ->
            Just
                (zoomAround windowSize
                    x
                    y
                    (model.scale
                        * (if deltaY > 0 then
                            0.9

                           else
                            1.1
                          )
                    )
                    model
                )

        TouchStart positions ->
            case positions of
                first :: second :: _ ->
                    Just
                        { model
                            | interaction =
                                Pinching
                                    { startDistance = max 1 (distance first second)
                                    , startScale = model.scale
                                    }
                        }

                [ ( x, y ) ] ->
                    Just { model | interaction = startDrag x y model }

                [] ->
                    Just model

        TouchMove positions ->
            case ( model.interaction, positions ) of
                ( Pinching pinch, first :: second :: _ ) ->
                    let
                        ( midX, midY ) =
                            midpoint first second
                    in
                    Just
                        (zoomAround windowSize
                            midX
                            midY
                            (pinch.startScale * distance first second / pinch.startDistance)
                            model
                        )

                ( Dragging _, ( x, y ) :: _ ) ->
                    Just (continueDrag x y model)

                _ ->
                    Just model

        TouchEnd ->
            endInteraction windowSize model


startDrag : Float -> Float -> Model -> Interaction
startDrag x y model =
    Dragging
        { startX = x
        , startY = y
        , offsetStartX = model.offsetX
        , offsetStartY = model.offsetY
        }


continueDrag : Float -> Float -> Model -> Model
continueDrag x y model =
    case model.interaction of
        Dragging drag ->
            { model
                | offsetX = drag.offsetStartX + (x - drag.startX)
                , offsetY = drag.offsetStartY + (y - drag.startY)
            }

        _ ->
            model


{-| When an interaction ends, close the viewer if the image has been dragged
entirely off the screen, otherwise just clear the interaction state.
-}
endInteraction : Coord CssPixels -> Model -> Maybe Model
endInteraction windowSize model =
    if isOffScreen windowSize model then
        Nothing

    else
        Just { model | interaction = NoInteraction }


{-| The size the image is actually drawn at, accounting for the `max-width: 90vw`
and `max-height: 90vh` constraints and the current zoom level.
-}
displayedSize : Coord CssPixels -> Model -> ( Float, Float )
displayedSize windowSize model =
    let
        vw : Float
        vw =
            toFloat (Coord.xRaw windowSize)

        vh : Float
        vh =
            toFloat (Coord.yRaw windowSize)

        w : Float
        w =
            toFloat (Coord.xRaw model.imageSize) |> max 1

        h : Float
        h =
            toFloat (Coord.yRaw model.imageSize) |> max 1

        fit : Float
        fit =
            min 1 (min (0.9 * vw / w) (0.9 * vh / h))
    in
    ( w * fit * model.scale, h * fit * model.scale )


isOffScreen : Coord CssPixels -> Model -> Bool
isOffScreen windowSize model =
    let
        vw : Float
        vw =
            toFloat (Coord.xRaw windowSize)

        vh : Float
        vh =
            toFloat (Coord.yRaw windowSize)

        ( dw, dh ) =
            displayedSize windowSize model

        centerX : Float
        centerX =
            vw / 2 + model.offsetX

        centerY : Float
        centerY =
            vh / 2 + model.offsetY
    in
    (centerX + dw / 2 < 0)
        || (centerX - dw / 2 > vw)
        || (centerY + dh / 2 < 0)
        || (centerY - dh / 2 > vh)


distance : ( Float, Float ) -> ( Float, Float ) -> Float
distance ( x1, y1 ) ( x2, y2 ) =
    sqrt (((x2 - x1) ^ 2) + ((y2 - y1) ^ 2))


midpoint : ( Float, Float ) -> ( Float, Float ) -> ( Float, Float )
midpoint ( x1, y1 ) ( x2, y2 ) =
    ( (x1 + x2) / 2, (y1 + y2) / 2 )


{-| Change the zoom level while keeping the point under (focusX, focusY) (in
screen coordinates) anchored in place. The image is centered in the viewport,
so we adjust the pan offset to compensate for the change in scale.
-}
zoomAround : Coord CssPixels -> Float -> Float -> Float -> Model -> Model
zoomAround windowSize focusX focusY newScaleRaw model =
    let
        newScale : Float
        newScale =
            clampScale newScaleRaw

        ratio : Float
        ratio =
            newScale / model.scale

        -- The focus point relative to the viewport center, which is where the
        -- (un-offset) image is centered.
        px : Float
        px =
            focusX - toFloat (Coord.xRaw windowSize) / 2

        py : Float
        py =
            focusY - toFloat (Coord.yRaw windowSize) / 2
    in
    { model
        | scale = newScale
        , offsetX = (px * (1 - ratio)) + (ratio * model.offsetX)
        , offsetY = (py * (1 - ratio)) + (ratio * model.offsetY)
    }


{-| Pressing the close/zoom buttons counts as a press, but dragging and zooming
do not (so they don't interfere with other press handling).
-}
isPressMsg : Msg -> Bool
isPressMsg msg =
    case msg of
        PressedClose ->
            True

        PressedZoomIn ->
            True

        PressedZoomOut ->
            True

        MouseDown _ _ ->
            False

        MouseMove _ _ ->
            False

        MouseUp ->
            False

        Wheeled _ _ _ ->
            False

        TouchStart _ ->
            False

        TouchMove _ ->
            False

        TouchEnd ->
            False


clampScale : Float -> Float
clampScale scale =
    clamp 0.2 8 scale


clientPositionDecoder : (Float -> Float -> Msg) -> Json.Decode.Decoder Msg
clientPositionDecoder toMsg =
    Json.Decode.map2 toMsg
        (Json.Decode.field "clientX" Json.Decode.float)
        (Json.Decode.field "clientY" Json.Decode.float)


touchPositions : Html.Events.Extra.Touch.Event -> List ( Float, Float )
touchPositions event =
    List.map .clientPos event.touches


view : Bool -> Model -> Element Msg
view isMobile model =
    Ui.el
        ([ Ui.id "imageViewer_overlay"
         , Ui.width Ui.fill
         , Ui.height Ui.fill
         , Ui.background (Ui.rgb 0 0 0)
         , Ui.clip
         , Json.Decode.map (\msg -> ( msg, True )) (clientPositionDecoder MouseDown)
            |> Html.Events.preventDefaultOn "mousedown"
            |> Ui.htmlAttribute
         , case model.interaction of
            Dragging _ ->
                clientPositionDecoder MouseMove
                    |> Html.Events.on "mousemove"
                    |> Ui.htmlAttribute

            _ ->
                Ui.noAttr
         , Html.Events.on "mouseup" (Json.Decode.succeed MouseUp) |> Ui.htmlAttribute
         , Html.Events.Extra.Touch.onWithOptions
            "touchstart"
            { stopPropagation = True, preventDefault = True }
            (\event -> TouchStart (touchPositions event))
            |> Ui.htmlAttribute
         , Html.Events.Extra.Touch.onWithOptions
            "touchmove"
            { stopPropagation = True, preventDefault = True }
            (\event -> TouchMove (touchPositions event))
            |> Ui.htmlAttribute
         , Html.Events.Extra.Touch.onWithOptions
            "touchend"
            { stopPropagation = True, preventDefault = True }
            (\_ -> TouchEnd)
            |> Ui.htmlAttribute
         , Json.Decode.map3 (\deltaY x y -> ( Wheeled deltaY x y, True ))
            (Json.Decode.field "deltaY" Json.Decode.float)
            (Json.Decode.field "clientX" Json.Decode.float)
            (Json.Decode.field "clientY" Json.Decode.float)
            |> Html.Events.preventDefaultOn "wheel"
            |> Ui.htmlAttribute
         ]
            ++ (if isMobile then
                    []

                else
                    [ Ui.inFront closeButton
                    , Ui.inFront zoomButtons
                    ]
               )
        )
        (Ui.el
            [ Ui.centerX
            , Ui.centerY
            , MyUi.htmlStyle "pointer-events" "none"
            ]
            (Ui.html
                (Html.img
                    [ Html.Attributes.src model.imageUrl
                    , Html.Attributes.style "max-width" "90vw"
                    , Html.Attributes.style "max-height" "90vh"
                    , Html.Attributes.style "display" "block"
                    , Html.Attributes.style
                        "image-rendering"
                        (if model.scale > 1 then
                            "pixelated"

                         else
                            "auto"
                        )
                    , Html.Attributes.style "transform"
                        ("translate("
                            ++ String.fromFloat model.offsetX
                            ++ "px,"
                            ++ String.fromFloat model.offsetY
                            ++ "px) scale("
                            ++ String.fromFloat model.scale
                            ++ ")"
                        )
                    ]
                    []
                )
            )
        )


closeButton : Element Msg
closeButton =
    MyUi.elButton
        (Dom.id "imageViewer_close")
        PressedClose
        [ Ui.alignRight
        , Ui.alignTop
        , Ui.paddingXY 16 16
        , Ui.Font.color MyUi.white
        , MyUi.htmlStyle "transform" ("translateY(" ++ MyUi.insetTop ++ ")")
        , Ui.background (Ui.rgba 0 0 0 0.5)
        ]
        (Ui.html Icons.x)


zoomButton : HtmlId -> Msg -> String -> Element Msg
zoomButton htmlId onPress label =
    MyUi.elButton
        htmlId
        onPress
        [ Ui.width (Ui.px 40)
        , Ui.height (Ui.px 40)
        , Ui.rounded 20
        , Ui.background (Ui.rgba 0 0 0 0.5)
        , Ui.Font.color MyUi.white
        , Ui.Font.size 24
        , Ui.contentCenterX
        , Ui.contentCenterY
        ]
        (Ui.text label)


zoomButtons : Element Msg
zoomButtons =
    Ui.row
        [ Ui.alignBottom
        , Ui.centerX
        , Ui.width Ui.shrink
        , Ui.spacing 16
        , Ui.paddingXY 16 24
        , MyUi.htmlStyle "transform" ("translateY(-" ++ MyUi.insetBottom ++ ")")
        ]
        [ zoomButton (Dom.id "imageViewer_zoomOut") PressedZoomOut "−"
        , zoomButton (Dom.id "imageViewer_zoomIn") PressedZoomIn "+"
        ]
