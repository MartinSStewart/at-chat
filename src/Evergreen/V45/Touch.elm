module Evergreen.V45.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V45.CssPixels
import Evergreen.V45.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V45.Point2d.Point2d Evergreen.V45.CssPixels.CssPixels ScreenCoordinate
    , target : Effect.Browser.Dom.HtmlId
    }
