module Evergreen.V417.Touch exposing (..)

import Effect.Time
import Evergreen.V417.CssPixels
import Evergreen.V417.NonemptyDict
import Evergreen.V417.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V417.Point2d.Point2d Evergreen.V417.CssPixels.CssPixels ScreenCoordinate
    , targetIsTextInput : Bool
    }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V417.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V417.NonemptyDict.NonemptyDict Int Touch
        , target : DragTarget
        }
