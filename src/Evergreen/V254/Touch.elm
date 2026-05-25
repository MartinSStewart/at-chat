module Evergreen.V254.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V254.CssPixels
import Evergreen.V254.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V254.Point2d.Point2d Evergreen.V254.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
