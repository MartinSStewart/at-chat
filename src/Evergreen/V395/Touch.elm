module Evergreen.V395.Touch exposing (..)

import Effect.Time
import Evergreen.V395.CssPixels
import Evergreen.V395.NonemptyDict
import Evergreen.V395.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V395.Point2d.Point2d Evergreen.V395.CssPixels.CssPixels ScreenCoordinate
    , targetIsTextInput : Bool
    }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V395.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V395.NonemptyDict.NonemptyDict Int Touch
        , target : DragTarget
        }
