module Evergreen.V9.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V9.CssPixels
import Evergreen.V9.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V9.Point2d.Point2d Evergreen.V9.CssPixels.CssPixels ScreenCoordinate
    , target : Effect.Browser.Dom.HtmlId
    }
