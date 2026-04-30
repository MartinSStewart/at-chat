module Evergreen.V211.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V211.CssPixels
import Evergreen.V211.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V211.Point2d.Point2d Evergreen.V211.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
