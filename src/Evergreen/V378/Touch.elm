module Evergreen.V378.Touch exposing (..)

import Effect.Time
import Evergreen.V378.CssPixels
import Evergreen.V378.NonemptyDict
import Evergreen.V378.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V378.Point2d.Point2d Evergreen.V378.CssPixels.CssPixels ScreenCoordinate
    , targetIsTextInput : Bool
    }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V378.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V378.NonemptyDict.NonemptyDict Int Touch
        , target : DragTarget
        }
