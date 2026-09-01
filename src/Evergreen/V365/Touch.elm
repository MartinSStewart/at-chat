module Evergreen.V365.Touch exposing (..)

import Effect.Browser.Dom
import Effect.Time
import Evergreen.V365.CssPixels
import Evergreen.V365.NonemptyDict
import Evergreen.V365.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V365.Point2d.Point2d Evergreen.V365.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }


type DragTarget
    = Drag_Channel
    | Drag_CallThumbnail
    | Drag_Game


type Drag
    = NoDrag
    | DragStart Effect.Time.Posix (Evergreen.V365.NonemptyDict.NonemptyDict Int Touch)
    | Dragging
        { horizontalStart : Bool
        , touches : Evergreen.V365.NonemptyDict.NonemptyDict Int Touch
        , target : DragTarget
        }
