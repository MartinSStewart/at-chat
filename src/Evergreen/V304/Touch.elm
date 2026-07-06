module Evergreen.V304.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V304.CssPixels
import Evergreen.V304.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V304.Point2d.Point2d Evergreen.V304.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
