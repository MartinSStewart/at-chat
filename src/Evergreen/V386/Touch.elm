module Evergreen.V386.Touch exposing (..)

import Effect.Time
import Evergreen.V386.CssPixels
import Evergreen.V386.NonemptyDict
import Evergreen.V386.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V386.Point2d.Point2d Evergreen.V386.CssPixels.CssPixels ScreenCoordinate
    , targetIsTextInput : Bool
    }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V386.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V386.NonemptyDict.NonemptyDict Int Touch
        , target : DragTarget
        }
