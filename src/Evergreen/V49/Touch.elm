module Evergreen.V49.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V49.CssPixels
import Evergreen.V49.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V49.Point2d.Point2d Evergreen.V49.CssPixels.CssPixels ScreenCoordinate
    , target : Effect.Browser.Dom.HtmlId
    }
