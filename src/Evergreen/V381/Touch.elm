module Evergreen.V381.Touch exposing (..)

import Effect.Time
import Evergreen.V381.CssPixels
import Evergreen.V381.NonemptyDict
import Evergreen.V381.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V381.Point2d.Point2d Evergreen.V381.CssPixels.CssPixels ScreenCoordinate
    , targetIsTextInput : Bool
    }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V381.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V381.NonemptyDict.NonemptyDict Int Touch
        , target : DragTarget
        }
