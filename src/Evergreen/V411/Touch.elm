module Evergreen.V411.Touch exposing (..)

import Effect.Time
import Evergreen.V411.CssPixels
import Evergreen.V411.NonemptyDict
import Evergreen.V411.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V411.Point2d.Point2d Evergreen.V411.CssPixels.CssPixels ScreenCoordinate
    , targetIsTextInput : Bool
    }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V411.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V411.NonemptyDict.NonemptyDict Int Touch
        , target : DragTarget
        }
