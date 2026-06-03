module Evergreen.V269.ImageViewer exposing (..)

import Duration
import Evergreen.V269.Coord
import Evergreen.V269.CssPixels


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


type alias Model =
    { imageUrl : String
    , imageSize : Evergreen.V269.Coord.Coord Evergreen.V269.CssPixels.CssPixels
    , scale : Float
    , offsetX : Float
    , offsetY : Float
    , interaction : Interaction
    , velocityX : Float
    , velocityY : Float
    , prevOffsetX : Float
    , prevOffsetY : Float
    , targetScale : Float
    , zoomFocusX : Float
    , zoomFocusY : Float
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
    | AnimationFrame Duration.Duration
