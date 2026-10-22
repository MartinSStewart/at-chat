module Evergreen.V408.Touch exposing (..)

import Effect.Time
import Evergreen.V408.CssPixels
import Evergreen.V408.NonemptyDict
import Evergreen.V408.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V408.Point2d.Point2d Evergreen.V408.CssPixels.CssPixels ScreenCoordinate
    , targetIsTextInput : Bool
    }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V408.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V408.NonemptyDict.NonemptyDict Int Touch
        , target : DragTarget
        }
