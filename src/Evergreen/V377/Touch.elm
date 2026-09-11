module Evergreen.V377.Touch exposing (..)

import Effect.Time
import Evergreen.V377.CssPixels
import Evergreen.V377.NonemptyDict
import Evergreen.V377.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V377.Point2d.Point2d Evergreen.V377.CssPixels.CssPixels ScreenCoordinate
    , targetIsTextInput : Bool
    }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V377.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V377.NonemptyDict.NonemptyDict Int Touch
        , target : DragTarget
        }
