module Evergreen.V375.Touch exposing (..)

import Effect.Time
import Evergreen.V375.CssPixels
import Evergreen.V375.NonemptyDict
import Evergreen.V375.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V375.Point2d.Point2d Evergreen.V375.CssPixels.CssPixels ScreenCoordinate
    , targetIsTextInput : Bool
    }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V375.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V375.NonemptyDict.NonemptyDict Int Touch
        , target : DragTarget
        }
