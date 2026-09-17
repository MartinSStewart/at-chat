module Evergreen.V383.Touch exposing (..)

import Effect.Time
import Evergreen.V383.CssPixels
import Evergreen.V383.NonemptyDict
import Evergreen.V383.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V383.Point2d.Point2d Evergreen.V383.CssPixels.CssPixels ScreenCoordinate
    , targetIsTextInput : Bool
    }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V383.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V383.NonemptyDict.NonemptyDict Int Touch
        , target : DragTarget
        }
