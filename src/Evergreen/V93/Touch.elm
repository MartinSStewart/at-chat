module Evergreen.V93.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V93.CssPixels
import Evergreen.V93.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V93.Point2d.Point2d Evergreen.V93.CssPixels.CssPixels ScreenCoordinate
    , target : Effect.Browser.Dom.HtmlId
    }
