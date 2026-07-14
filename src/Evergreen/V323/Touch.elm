module Evergreen.V323.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V323.CssPixels
import Evergreen.V323.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V323.Point2d.Point2d Evergreen.V323.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
