module Evergreen.V425.Touch exposing (..)

import Effect.Time
import Evergreen.V425.CssPixels
import Evergreen.V425.NonemptyDict
import Evergreen.V425.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V425.Point2d.Point2d Evergreen.V425.CssPixels.CssPixels ScreenCoordinate
    , targetIsTextInput : Bool
    }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V425.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V425.NonemptyDict.NonemptyDict Int Touch
        , target : DragTarget
        }
