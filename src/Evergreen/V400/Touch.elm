module Evergreen.V400.Touch exposing (..)

import Effect.Time
import Evergreen.V400.CssPixels
import Evergreen.V400.NonemptyDict
import Evergreen.V400.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V400.Point2d.Point2d Evergreen.V400.CssPixels.CssPixels ScreenCoordinate
    , targetIsTextInput : Bool
    }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V400.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V400.NonemptyDict.NonemptyDict Int Touch
        , target : DragTarget
        }
