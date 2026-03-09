module Evergreen.V146.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V146.CssPixels
import Evergreen.V146.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V146.Point2d.Point2d Evergreen.V146.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
