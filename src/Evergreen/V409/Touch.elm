module Evergreen.V409.Touch exposing (..)

import Effect.Time
import Evergreen.V409.CssPixels
import Evergreen.V409.NonemptyDict
import Evergreen.V409.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V409.Point2d.Point2d Evergreen.V409.CssPixels.CssPixels ScreenCoordinate
    , targetIsTextInput : Bool
    }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V409.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V409.NonemptyDict.NonemptyDict Int Touch
        , target : DragTarget
        }
