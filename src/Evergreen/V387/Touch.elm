module Evergreen.V387.Touch exposing (..)

import Effect.Time
import Evergreen.V387.CssPixels
import Evergreen.V387.NonemptyDict
import Evergreen.V387.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V387.Point2d.Point2d Evergreen.V387.CssPixels.CssPixels ScreenCoordinate
    , targetIsTextInput : Bool
    }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V387.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V387.NonemptyDict.NonemptyDict Int Touch
        , target : DragTarget
        }
