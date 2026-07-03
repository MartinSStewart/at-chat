module Evergreen.V301.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V301.CssPixels
import Evergreen.V301.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V301.Point2d.Point2d Evergreen.V301.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
