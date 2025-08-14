module Evergreen.V31.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V31.CssPixels
import Evergreen.V31.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V31.Point2d.Point2d Evergreen.V31.CssPixels.CssPixels ScreenCoordinate
    , target : Effect.Browser.Dom.HtmlId
    }
