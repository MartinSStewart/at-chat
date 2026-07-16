module Evergreen.V326.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V326.CssPixels
import Evergreen.V326.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V326.Point2d.Point2d Evergreen.V326.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
