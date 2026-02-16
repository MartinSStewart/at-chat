module Evergreen.V112.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V112.CssPixels
import Evergreen.V112.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V112.Point2d.Point2d Evergreen.V112.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
