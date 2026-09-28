module Evergreen.V389.Touch exposing (..)

import Effect.Time
import Evergreen.V389.CssPixels
import Evergreen.V389.NonemptyDict
import Evergreen.V389.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V389.Point2d.Point2d Evergreen.V389.CssPixels.CssPixels ScreenCoordinate
    , targetIsTextInput : Bool
    }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V389.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V389.NonemptyDict.NonemptyDict Int Touch
        , target : DragTarget
        }
