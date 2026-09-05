module Evergreen.V368.ImageViewer exposing (..)

import Duration
import Evergreen.V368.Coord
import Evergreen.V368.CssPixels


type Msg
    = PressedClose
    | PressedZoomIn
    | PressedZoomOut
    | PressStartedOnButton
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
    , imageSize : Evergreen.V368.Coord.Coord Evergreen.V368.CssPixels.CssPixels
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
