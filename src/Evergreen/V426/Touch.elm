module Evergreen.V426.Touch exposing (..)

import Effect.Time
import Evergreen.V426.CssPixels
import Evergreen.V426.NonemptyDict
import Evergreen.V426.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V426.Point2d.Point2d Evergreen.V426.CssPixels.CssPixels ScreenCoordinate
    , targetIsTextInput : Bool
    }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V426.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V426.NonemptyDict.NonemptyDict Int Touch
        , target : DragTarget
        }
