module Evergreen.V38.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V38.CssPixels
import Evergreen.V38.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V38.Point2d.Point2d Evergreen.V38.CssPixels.CssPixels ScreenCoordinate
    , target : Effect.Browser.Dom.HtmlId
    }
