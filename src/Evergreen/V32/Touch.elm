module Evergreen.V32.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V32.CssPixels
import Evergreen.V32.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V32.Point2d.Point2d Evergreen.V32.CssPixels.CssPixels ScreenCoordinate
    , target : Effect.Browser.Dom.HtmlId
    }
