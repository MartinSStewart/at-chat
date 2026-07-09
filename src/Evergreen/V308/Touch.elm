module Evergreen.V308.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V308.CssPixels
import Evergreen.V308.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V308.Point2d.Point2d Evergreen.V308.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
