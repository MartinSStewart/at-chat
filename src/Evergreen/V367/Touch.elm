module Evergreen.V367.Touch exposing (..)

import Effect.Browser.Dom
import Effect.Time
import Evergreen.V367.CssPixels
import Evergreen.V367.NonemptyDict
import Evergreen.V367.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V367.Point2d.Point2d Evergreen.V367.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V367.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V367.NonemptyDict.NonemptyDict Int Touch
        , target : DragTarget
        }
