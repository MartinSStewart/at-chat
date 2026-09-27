module Evergreen.V388.Touch exposing (..)

import Effect.Time
import Evergreen.V388.CssPixels
import Evergreen.V388.NonemptyDict
import Evergreen.V388.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V388.Point2d.Point2d Evergreen.V388.CssPixels.CssPixels ScreenCoordinate
    , targetIsTextInput : Bool
    }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V388.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V388.NonemptyDict.NonemptyDict Int Touch
        , target : DragTarget
        }
