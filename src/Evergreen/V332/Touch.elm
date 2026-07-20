module Evergreen.V332.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V332.CssPixels
import Evergreen.V332.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V332.Point2d.Point2d Evergreen.V332.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
