module Evergreen.V404.Touch exposing (..)

import Effect.Time
import Evergreen.V404.CssPixels
import Evergreen.V404.NonemptyDict
import Evergreen.V404.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V404.Point2d.Point2d Evergreen.V404.CssPixels.CssPixels ScreenCoordinate
    , targetIsTextInput : Bool
    }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V404.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V404.NonemptyDict.NonemptyDict Int Touch
        , target : DragTarget
        }
