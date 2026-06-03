module ImageViewer exposing (Model, Msg(..), init, isPressMsg, update, view)

{-| A fullscreen overlay for viewing an image. The image is shown on top of a
black background and can be zoomed (mouse wheel or the +/- buttons) and dragged
around. An x button in the top right closes the overlay.

This is rendered as an overlay (instead of navigating away or opening a new tab)
so that the channel underneath keeps rendering and doesn't lose its scroll
position.

-}

import Effect.Browser.Dom as Dom exposing (HtmlId)
import Html
import Html.Attributes
import Html.Events
import Html.Events.Extra.Touch
import Icons
import Json.Decode
import List.Extra as List
import MyUi
import Ui exposing (Element)
import Ui.Font


type alias Model =
    { imageUrl : String
    , scale : Float
    , offsetX : Float
    , offsetY : Float
    , drag : Maybe DragState
    }


type alias DragState =
    { startX : Float
    , startY : Float
    , offsetStartX : Float
    , offsetStartY : Float
    }


type Msg
    = PressedClose
    | PointerDown Float Float
    | PointerMove Float Float
    | PointerUp
    | Wheeled Float
    | PressedZoomIn
    | PressedZoomOut


init : String -> Model
init imageUrl =
    { imageUrl = imageUrl
    , scale = 1
    , offsetX = 0
    , offsetY = 0
    , drag = Nothing
    }


{-| Returns Nothing when the viewer should be closed.
-}
update : Msg -> Model -> Maybe Model
update msg model =
    case msg of
        PressedClose ->
            Nothing

        PointerDown x y ->
            Just
                { model
                    | drag =
                        Just
                            { startX = x
                            , startY = y
                            , offsetStartX = model.offsetX
                            , offsetStartY = model.offsetY
                            }
                }

        PointerMove x y ->
            case model.drag of
                Just drag ->
                    Just
                        { model
                            | offsetX = drag.offsetStartX + (x - drag.startX)
                            , offsetY = drag.offsetStartY + (y - drag.startY)
                        }

                Nothing ->
                    Just model

        PointerUp ->
            Just { model | drag = Nothing }

        Wheeled deltaY ->
            Just
                { model
                    | scale =
                        clampScale
                            (model.scale
                                * (if deltaY > 0 then
                                    0.9

                                   else
                                    1.1
                                  )
                            )
                }

        PressedZoomIn ->
            Just { model | scale = clampScale (model.scale * 1.25) }

        PressedZoomOut ->
            Just { model | scale = clampScale (model.scale / 1.25) }


{-| Pressing the close/zoom buttons counts as a press, but dragging and zooming
with the wheel does not (so it doesn't interfere with other press handling).
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

        PointerDown _ _ ->
            False

        PointerMove _ _ ->
            False

        PointerUp ->
            False

        Wheeled _ ->
            False


clampScale : Float -> Float
clampScale scale =
    clamp 0.2 8 scale


clientPositionDecoder : (Float -> Float -> Msg) -> Json.Decode.Decoder Msg
clientPositionDecoder toMsg =
    Json.Decode.map2 toMsg
        (Json.Decode.field "clientX" Json.Decode.float)
        (Json.Decode.field "clientY" Json.Decode.float)


firstTouchPosition : Html.Events.Extra.Touch.Event -> ( Float, Float )
firstTouchPosition event =
    case List.head event.touches of
        Just touch ->
            touch.clientPos

        Nothing ->
            ( 0, 0 )


view : Model -> Element Msg
view model =
    Ui.el
        [ Ui.id "imageViewer_overlay"
        , Ui.width Ui.fill
        , Ui.height Ui.fill
        , Ui.background (Ui.rgb 0 0 0)
        , Ui.clip
        , Json.Decode.map (\msg -> ( msg, True )) (clientPositionDecoder PointerDown)
            |> Html.Events.preventDefaultOn "mousedown"
            |> Ui.htmlAttribute
        , case model.drag of
            Just _ ->
                clientPositionDecoder PointerMove
                    |> Html.Events.on "mousemove"
                    |> Ui.htmlAttribute

            Nothing ->
                Ui.noAttr
        , Html.Events.on "mouseup" (Json.Decode.succeed PointerUp) |> Ui.htmlAttribute
        , Html.Events.Extra.Touch.onStart (\event -> firstTouchPosition event |> (\( x, y ) -> PointerDown x y))
            |> Ui.htmlAttribute
        , Html.Events.Extra.Touch.onMove (\event -> firstTouchPosition event |> (\( x, y ) -> PointerMove x y))
            |> Ui.htmlAttribute
        , Html.Events.Extra.Touch.onEnd (\_ -> PointerUp) |> Ui.htmlAttribute
        , Json.Decode.map (\deltaY -> ( Wheeled deltaY, True ))
            (Json.Decode.field "deltaY" Json.Decode.float)
            |> Html.Events.preventDefaultOn "wheel"
            |> Ui.htmlAttribute
        , Ui.inFront closeButton
        , Ui.inFront zoomButtons
        ]
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
