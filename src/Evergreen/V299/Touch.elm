module Evergreen.V299.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V299.CssPixels
import Evergreen.V299.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V299.Point2d.Point2d Evergreen.V299.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
