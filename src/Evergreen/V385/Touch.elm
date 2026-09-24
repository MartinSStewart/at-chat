module Evergreen.V385.Touch exposing (..)

import Effect.Time
import Evergreen.V385.CssPixels
import Evergreen.V385.NonemptyDict
import Evergreen.V385.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V385.Point2d.Point2d Evergreen.V385.CssPixels.CssPixels ScreenCoordinate
    , targetIsTextInput : Bool
    }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V385.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V385.NonemptyDict.NonemptyDict Int Touch
        , target : DragTarget
        }
