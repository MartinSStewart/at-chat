module Evergreen.V77.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V77.CssPixels
import Evergreen.V77.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V77.Point2d.Point2d Evergreen.V77.CssPixels.CssPixels ScreenCoordinate
    , target : Effect.Browser.Dom.HtmlId
    }
