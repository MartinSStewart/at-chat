module Evergreen.V405.Touch exposing (..)

import Effect.Time
import Evergreen.V405.CssPixels
import Evergreen.V405.NonemptyDict
import Evergreen.V405.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V405.Point2d.Point2d Evergreen.V405.CssPixels.CssPixels ScreenCoordinate
    , targetIsTextInput : Bool
    }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V405.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V405.NonemptyDict.NonemptyDict Int Touch
        , target : DragTarget
        }
