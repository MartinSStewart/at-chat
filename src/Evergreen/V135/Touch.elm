module Evergreen.V135.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V135.CssPixels
import Evergreen.V135.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V135.Point2d.Point2d Evergreen.V135.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
