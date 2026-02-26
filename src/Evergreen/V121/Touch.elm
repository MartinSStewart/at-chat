module Evergreen.V121.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V121.CssPixels
import Evergreen.V121.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V121.Point2d.Point2d Evergreen.V121.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
