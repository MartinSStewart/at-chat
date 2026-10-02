module Evergreen.V396.Touch exposing (..)

import Effect.Time
import Evergreen.V396.CssPixels
import Evergreen.V396.NonemptyDict
import Evergreen.V396.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V396.Point2d.Point2d Evergreen.V396.CssPixels.CssPixels ScreenCoordinate
    , targetIsTextInput : Bool
    }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V396.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V396.NonemptyDict.NonemptyDict Int Touch
        , target : DragTarget
        }
