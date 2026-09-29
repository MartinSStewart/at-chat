module Evergreen.V394.Touch exposing (..)

import Effect.Time
import Evergreen.V394.CssPixels
import Evergreen.V394.NonemptyDict
import Evergreen.V394.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V394.Point2d.Point2d Evergreen.V394.CssPixels.CssPixels ScreenCoordinate
    , targetIsTextInput : Bool
    }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V394.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V394.NonemptyDict.NonemptyDict Int Touch
        , target : DragTarget
        }
