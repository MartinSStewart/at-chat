module Evergreen.V373.Touch exposing (..)

import Effect.Time
import Evergreen.V373.CssPixels
import Evergreen.V373.NonemptyDict
import Evergreen.V373.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V373.Point2d.Point2d Evergreen.V373.CssPixels.CssPixels ScreenCoordinate
    , targetIsTextInput : Bool
    }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V373.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V373.NonemptyDict.NonemptyDict Int Touch
        , target : DragTarget
        }
