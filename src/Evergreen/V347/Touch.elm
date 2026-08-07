module Evergreen.V347.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V347.CssPixels
import Evergreen.V347.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V347.Point2d.Point2d Evergreen.V347.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
