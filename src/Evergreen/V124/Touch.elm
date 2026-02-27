module Evergreen.V124.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V124.CssPixels
import Evergreen.V124.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V124.Point2d.Point2d Evergreen.V124.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
