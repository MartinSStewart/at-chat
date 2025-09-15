module Evergreen.V59.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V59.CssPixels
import Evergreen.V59.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V59.Point2d.Point2d Evergreen.V59.CssPixels.CssPixels ScreenCoordinate
    , target : Effect.Browser.Dom.HtmlId
    }
