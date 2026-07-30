module Evergreen.V340.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V340.CssPixels
import Evergreen.V340.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V340.Point2d.Point2d Evergreen.V340.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
