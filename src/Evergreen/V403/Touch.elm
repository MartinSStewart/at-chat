module Evergreen.V403.Touch exposing (..)

import Effect.Time
import Evergreen.V403.CssPixels
import Evergreen.V403.NonemptyDict
import Evergreen.V403.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V403.Point2d.Point2d Evergreen.V403.CssPixels.CssPixels ScreenCoordinate
    , targetIsTextInput : Bool
    }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V403.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V403.NonemptyDict.NonemptyDict Int Touch
        , target : DragTarget
        }
