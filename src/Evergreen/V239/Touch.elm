module Evergreen.V239.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V239.CssPixels
import Evergreen.V239.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V239.Point2d.Point2d Evergreen.V239.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
