module Evergreen.V311.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V311.CssPixels
import Evergreen.V311.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V311.Point2d.Point2d Evergreen.V311.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
