module Evergreen.V421.Touch exposing (..)

import Effect.Time
import Evergreen.V421.CssPixels
import Evergreen.V421.NonemptyDict
import Evergreen.V421.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V421.Point2d.Point2d Evergreen.V421.CssPixels.CssPixels ScreenCoordinate
    , targetIsTextInput : Bool
    }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V421.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V421.NonemptyDict.NonemptyDict Int Touch
        , target : DragTarget
        }
