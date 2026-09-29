module Evergreen.V392.Touch exposing (..)

import Effect.Time
import Evergreen.V392.CssPixels
import Evergreen.V392.NonemptyDict
import Evergreen.V392.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V392.Point2d.Point2d Evergreen.V392.CssPixels.CssPixels ScreenCoordinate
    , targetIsTextInput : Bool
    }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V392.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V392.NonemptyDict.NonemptyDict Int Touch
        , target : DragTarget
        }
