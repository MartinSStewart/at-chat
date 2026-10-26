module Evergreen.V412.Touch exposing (..)

import Effect.Time
import Evergreen.V412.CssPixels
import Evergreen.V412.NonemptyDict
import Evergreen.V412.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V412.Point2d.Point2d Evergreen.V412.CssPixels.CssPixels ScreenCoordinate
    , targetIsTextInput : Bool
    }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V412.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V412.NonemptyDict.NonemptyDict Int Touch
        , target : DragTarget
        }
