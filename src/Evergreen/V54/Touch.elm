module Evergreen.V54.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V54.CssPixels
import Evergreen.V54.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V54.Point2d.Point2d Evergreen.V54.CssPixels.CssPixels ScreenCoordinate
    , target : Effect.Browser.Dom.HtmlId
    }
