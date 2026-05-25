module Evergreen.V247.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V247.CssPixels
import Evergreen.V247.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V247.Point2d.Point2d Evergreen.V247.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
