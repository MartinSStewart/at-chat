module Evergreen.V97.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V97.CssPixels
import Evergreen.V97.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V97.Point2d.Point2d Evergreen.V97.CssPixels.CssPixels ScreenCoordinate
    , target : Effect.Browser.Dom.HtmlId
    }
