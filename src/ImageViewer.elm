module ImageViewer exposing (Model, Msg(..), init, isPressMsg, subscriptions, update, view)

{-| A fullscreen overlay for viewing an image. The image is shown on top of a
black background and can be zoomed and dragged around, both with a bit of
inertia: flinging the image keeps it moving and gradually slows down, and
zooming glides to its target instead of snapping.

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
import Duration exposing (Duration)
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Browser.Events
import Effect.Command exposing (FrontendOnly)
import Effect.Subscription as Subscription exposing (Subscription)
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

    -- Pan momentum (in CSS pixels per 60fps frame) applied after a fling.
    , velocityX : Float
    , velocityY : Float

    -- Offset sampled on the previous animation frame, used to measure the drag
    -- velocity so a paused drag doesn't fling.
    , prevOffsetX : Float
    , prevOffsetY : Float

    -- The zoom level glides toward targetScale, anchored on (zoomFocusX, zoomFocusY).
    , targetScale : Float
    , zoomFocusX : Float
    , zoomFocusY : Float
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
    | AnimationFrame Duration


init : { url : String, imageSize : Coord CssPixels } -> Model
init { url, imageSize } =
    { imageUrl = url
    , imageSize = imageSize
    , scale = 1
    , offsetX = 0
    , offsetY = 0
    , interaction = NoInteraction
    , velocityX = 0
    , velocityY = 0
    , prevOffsetX = 0
    , prevOffsetY = 0
    , targetScale = 1
    , zoomFocusX = 0
    , zoomFocusY = 0
    }


{-| Animation frames are only needed while something is moving: an active drag
or pinch, leftover pan momentum, or a zoom still gliding toward its target.
-}
subscriptions : Model -> Subscription FrontendOnly Msg
subscriptions model =
    if isAnimating model then
        Effect.Browser.Events.onAnimationFrameDelta AnimationFrame

    else
        Subscription.none


isAnimating : Model -> Bool
isAnimating model =
    (model.interaction /= NoInteraction)
        || (abs model.velocityX > panVelocityThreshold)
        || (abs model.velocityY > panVelocityThreshold)
        -- Keep ticking until the zoom easing snaps scale exactly onto targetScale.
        || (model.scale /= model.targetScale)


{-| Returns Nothing when the viewer should be closed (the close button was
pressed, or the image was dragged/flung off the screen).
-}
update : Coord CssPixels -> Msg -> Model -> Maybe Model
update windowSize msg model =
    case msg of
        PressedClose ->
            Nothing

        PressedZoomIn ->
            Just (zoomTowards (centerX windowSize) (centerY windowSize) (model.targetScale * 1.25) model)

        PressedZoomOut ->
            Just (zoomTowards (centerX windowSize) (centerY windowSize) (model.targetScale / 1.25) model)

        MouseDown x y ->
            Just (beginDrag x y model)

        MouseMove x y ->
            Just (continueDrag x y model)

        MouseUp ->
            endInteraction windowSize model

        Wheeled deltaY x y ->
            Just
                (zoomTowards x
                    y
                    (model.targetScale
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
                            , velocityX = 0
                            , velocityY = 0
                        }

                [ ( x, y ) ] ->
                    Just (beginDrag x y model)

                [] ->
                    Just model

        TouchMove positions ->
            case ( model.interaction, positions ) of
                ( Pinching pinch, first :: second :: _ ) ->
                    let
                        ( midX, midY ) =
                            midpoint first second

                        zoomed : Model
                        zoomed =
                            zoomAround windowSize
                                midX
                                midY
                                (pinch.startScale * distance first second / pinch.startDistance)
                                model
                    in
                    -- Pinch tracks the fingers directly, so keep targetScale in
                    -- sync to avoid the easing fighting the gesture.
                    Just { zoomed | targetScale = zoomed.scale, zoomFocusX = midX, zoomFocusY = midY }

                ( Dragging _, ( x, y ) :: _ ) ->
                    Just (continueDrag x y model)

                _ ->
                    Just model

        TouchEnd ->
            endInteraction windowSize model

        AnimationFrame duration ->
            let
                frames : Float
                frames =
                    Duration.inMilliseconds duration / frameMs

                eased : Model
                eased =
                    applyZoomEasing windowSize frames model
            in
            case eased.interaction of
                Dragging _ ->
                    Just (sampleDragVelocity frames eased)

                Pinching _ ->
                    Just eased

                NoInteraction ->
                    let
                        moved : Model
                        moved =
                            applyMomentum frames eased
                    in
                    if isOffScreen windowSize moved then
                        Nothing

                    else
                        Just moved


beginDrag : Float -> Float -> Model -> Model
beginDrag x y model =
    { model
        | interaction =
            Dragging
                { startX = x
                , startY = y
                , offsetStartX = model.offsetX
                , offsetStartY = model.offsetY
                }
        , velocityX = 0
        , velocityY = 0
        , prevOffsetX = model.offsetX
        , prevOffsetY = model.offsetY
    }


continueDrag : Float -> Float -> Model -> Model
continueDrag x y model =
    case model.interaction of
        Dragging drag ->
            let
                newOffsetX : Float
                newOffsetX =
                    drag.offsetStartX + (x - drag.startX)

                newOffsetY : Float
                newOffsetY =
                    drag.offsetStartY + (y - drag.startY)
            in
            { model
                | offsetX = newOffsetX
                , offsetY = newOffsetY

                -- Capture an immediate velocity so a quick flick (released before
                -- the next animation frame) still has momentum.
                , velocityX = newOffsetX - model.offsetX
                , velocityY = newOffsetY - model.offsetY
            }

        _ ->
            model


{-| Measure the drag velocity from how far the image moved since the previous
frame. If the drag paused, the velocity decays to zero and there's no fling.
-}
sampleDragVelocity : Float -> Model -> Model
sampleDragVelocity frames model =
    { model
        | velocityX = (model.offsetX - model.prevOffsetX) / frames
        , velocityY = (model.offsetY - model.prevOffsetY) / frames
        , prevOffsetX = model.offsetX
        , prevOffsetY = model.offsetY
    }


applyMomentum : Float -> Model -> Model
applyMomentum frames model =
    let
        decay : Float
        decay =
            panDecay ^ frames

        newVelocityX : Float
        newVelocityX =
            model.velocityX * decay

        newVelocityY : Float
        newVelocityY =
            model.velocityY * decay

        stopped : Bool
        stopped =
            (newVelocityX * newVelocityX) + (newVelocityY * newVelocityY) < (panVelocityThreshold * panVelocityThreshold)
    in
    { model
        | offsetX = model.offsetX + (model.velocityX * frames)
        , offsetY = model.offsetY + (model.velocityY * frames)
        , velocityX =
            if stopped then
                0

            else
                newVelocityX
        , velocityY =
            if stopped then
                0

            else
                newVelocityY
    }


{-| Set a new zoom target. The actual scale glides towards it on each animation
frame, anchored on the given focus point.
-}
zoomTowards : Float -> Float -> Float -> Model -> Model
zoomTowards focusX focusY newTargetScale model =
    { model
        | targetScale = clampScale newTargetScale
        , zoomFocusX = focusX
        , zoomFocusY = focusY
    }


applyZoomEasing : Coord CssPixels -> Float -> Model -> Model
applyZoomEasing windowSize frames model =
    let
        diff : Float
        diff =
            model.targetScale - model.scale
    in
    if abs diff < scaleEpsilon then
        if model.scale == model.targetScale then
            model

        else
            zoomAround windowSize model.zoomFocusX model.zoomFocusY model.targetScale model

    else
        let
            t : Float
            t =
                1 - ((1 - zoomEaseRate) ^ frames)
        in
        zoomAround windowSize model.zoomFocusX model.zoomFocusY (model.scale + (diff * t)) model


{-| When an interaction ends, close the viewer if the image has been dragged
entirely off the screen, otherwise keep whatever fling velocity was built up.
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

        imageCenterX : Float
        imageCenterX =
            vw / 2 + model.offsetX

        imageCenterY : Float
        imageCenterY =
            vh / 2 + model.offsetY
    in
    (imageCenterX + dw / 2 < 0)
        || (imageCenterX - dw / 2 > vw)
        || (imageCenterY + dh / 2 < 0)
        || (imageCenterY - dh / 2 > vh)


distance : ( Float, Float ) -> ( Float, Float ) -> Float
distance ( x1, y1 ) ( x2, y2 ) =
    sqrt (((x2 - x1) ^ 2) + ((y2 - y1) ^ 2))


midpoint : ( Float, Float ) -> ( Float, Float ) -> ( Float, Float )
midpoint ( x1, y1 ) ( x2, y2 ) =
    ( (x1 + x2) / 2, (y1 + y2) / 2 )


centerX : Coord CssPixels -> Float
centerX windowSize =
    toFloat (Coord.xRaw windowSize) / 2


centerY : Coord CssPixels -> Float
centerY windowSize =
    toFloat (Coord.yRaw windowSize) / 2


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

        AnimationFrame _ ->
            False


frameMs : Float
frameMs =
    1000 / 60


panDecay : Float
panDecay =
    0.9


panVelocityThreshold : Float
panVelocityThreshold =
    0.3


zoomEaseRate : Float
zoomEaseRate =
    0.22


scaleEpsilon : Float
scaleEpsilon =
    0.0005


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
        , Ui.background (Ui.rgba 255 255 255 0.15)
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
