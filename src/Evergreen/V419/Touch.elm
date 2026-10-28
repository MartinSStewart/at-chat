module Evergreen.V419.Touch exposing (..)

import Effect.Time
import Evergreen.V419.CssPixels
import Evergreen.V419.NonemptyDict
import Evergreen.V419.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V419.Point2d.Point2d Evergreen.V419.CssPixels.CssPixels ScreenCoordinate
    , targetIsTextInput : Bool
    }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V419.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V419.NonemptyDict.NonemptyDict Int Touch
        , target : DragTarget
        }
