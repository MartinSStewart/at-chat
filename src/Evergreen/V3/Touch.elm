module Evergreen.V3.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V3.CssPixels
import Evergreen.V3.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V3.Point2d.Point2d Evergreen.V3.CssPixels.CssPixels ScreenCoordinate
    , target : Effect.Browser.Dom.HtmlId
    }
