module Evergreen.V384.Touch exposing (..)

import Effect.Time
import Evergreen.V384.CssPixels
import Evergreen.V384.NonemptyDict
import Evergreen.V384.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V384.Point2d.Point2d Evergreen.V384.CssPixels.CssPixels ScreenCoordinate
    , targetIsTextInput : Bool
    }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V384.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V384.NonemptyDict.NonemptyDict Int Touch
        , target : DragTarget
        }
