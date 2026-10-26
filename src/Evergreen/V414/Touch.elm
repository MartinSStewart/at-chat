module Evergreen.V414.Touch exposing (..)

import Effect.Time
import Evergreen.V414.CssPixels
import Evergreen.V414.NonemptyDict
import Evergreen.V414.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V414.Point2d.Point2d Evergreen.V414.CssPixels.CssPixels ScreenCoordinate
    , targetIsTextInput : Bool
    }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V414.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V414.NonemptyDict.NonemptyDict Int Touch
        , target : DragTarget
        }
