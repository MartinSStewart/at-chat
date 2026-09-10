module Evergreen.V376.Touch exposing (..)

import Effect.Time
import Evergreen.V376.CssPixels
import Evergreen.V376.NonemptyDict
import Evergreen.V376.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V376.Point2d.Point2d Evergreen.V376.CssPixels.CssPixels ScreenCoordinate
    , targetIsTextInput : Bool
    }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V376.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V376.NonemptyDict.NonemptyDict Int Touch
        , target : DragTarget
        }
