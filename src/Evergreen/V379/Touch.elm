module Evergreen.V379.Touch exposing (..)

import Effect.Time
import Evergreen.V379.CssPixels
import Evergreen.V379.NonemptyDict
import Evergreen.V379.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V379.Point2d.Point2d Evergreen.V379.CssPixels.CssPixels ScreenCoordinate
    , targetIsTextInput : Bool
    }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V379.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V379.NonemptyDict.NonemptyDict Int Touch
        , target : DragTarget
        }
