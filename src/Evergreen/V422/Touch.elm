module Evergreen.V422.Touch exposing (..)

import Effect.Time
import Evergreen.V422.CssPixels
import Evergreen.V422.NonemptyDict
import Evergreen.V422.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V422.Point2d.Point2d Evergreen.V422.CssPixels.CssPixels ScreenCoordinate
    , targetIsTextInput : Bool
    }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V422.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V422.NonemptyDict.NonemptyDict Int Touch
        , target : DragTarget
        }
