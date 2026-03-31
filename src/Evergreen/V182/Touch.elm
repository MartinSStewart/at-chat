module Evergreen.V182.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V182.CssPixels
import Evergreen.V182.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V182.Point2d.Point2d Evergreen.V182.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
