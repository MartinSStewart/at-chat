module Evergreen.V27.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V27.CssPixels
import Evergreen.V27.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V27.Point2d.Point2d Evergreen.V27.CssPixels.CssPixels ScreenCoordinate
    , target : Effect.Browser.Dom.HtmlId
    }
