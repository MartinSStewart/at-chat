module Evergreen.V372.Touch exposing (..)

import Effect.Time
import Evergreen.V372.CssPixels
import Evergreen.V372.NonemptyDict
import Evergreen.V372.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V372.Point2d.Point2d Evergreen.V372.CssPixels.CssPixels ScreenCoordinate
    , targetIsTextInput : Bool
    }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V372.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V372.NonemptyDict.NonemptyDict Int Touch
        , target : DragTarget
        }
