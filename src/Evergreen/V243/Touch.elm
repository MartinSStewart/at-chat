module Evergreen.V243.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V243.CssPixels
import Evergreen.V243.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V243.Point2d.Point2d Evergreen.V243.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
