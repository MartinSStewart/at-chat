module Evergreen.V302.ImageViewer exposing (..)

import Duration
import Evergreen.V302.Coord
import Evergreen.V302.CssPixels


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
        , prevMidX : Float
        , prevMidY : Float
        }


type alias Model =
    { imageUrl : String
    , imageSize : Evergreen.V302.Coord.Coord Evergreen.V302.CssPixels.CssPixels
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
