module Evergreen.V397.Touch exposing (..)

import Effect.Time
import Evergreen.V397.CssPixels
import Evergreen.V397.NonemptyDict
import Evergreen.V397.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V397.Point2d.Point2d Evergreen.V397.CssPixels.CssPixels ScreenCoordinate
    , targetIsTextInput : Bool
    }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V397.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V397.NonemptyDict.NonemptyDict Int Touch
        , target : DragTarget
        }
