module Evergreen.V401.Touch exposing (..)

import Effect.Time
import Evergreen.V401.CssPixels
import Evergreen.V401.NonemptyDict
import Evergreen.V401.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V401.Point2d.Point2d Evergreen.V401.CssPixels.CssPixels ScreenCoordinate
    , targetIsTextInput : Bool
    }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V401.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V401.NonemptyDict.NonemptyDict Int Touch
        , target : DragTarget
        }
