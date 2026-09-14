module Evergreen.V382.Touch exposing (..)

import Effect.Time
import Evergreen.V382.CssPixels
import Evergreen.V382.NonemptyDict
import Evergreen.V382.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V382.Point2d.Point2d Evergreen.V382.CssPixels.CssPixels ScreenCoordinate
    , targetIsTextInput : Bool
    }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V382.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V382.NonemptyDict.NonemptyDict Int Touch
        , target : DragTarget
        }
