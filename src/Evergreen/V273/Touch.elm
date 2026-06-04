module Evergreen.V273.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V273.CssPixels
import Evergreen.V273.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V273.Point2d.Point2d Evergreen.V273.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
