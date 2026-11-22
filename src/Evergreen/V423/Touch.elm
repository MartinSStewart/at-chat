module Evergreen.V423.Touch exposing (..)

import Effect.Time
import Evergreen.V423.CssPixels
import Evergreen.V423.NonemptyDict
import Evergreen.V423.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V423.Point2d.Point2d Evergreen.V423.CssPixels.CssPixels ScreenCoordinate
    , targetIsTextInput : Bool
    }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V423.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V423.NonemptyDict.NonemptyDict Int Touch
        , target : DragTarget
        }
