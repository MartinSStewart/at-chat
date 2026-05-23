module Evergreen.V248.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V248.CssPixels
import Evergreen.V248.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V248.Point2d.Point2d Evergreen.V248.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
