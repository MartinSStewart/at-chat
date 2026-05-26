module Evergreen.V255.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V255.CssPixels
import Evergreen.V255.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V255.Point2d.Point2d Evergreen.V255.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
