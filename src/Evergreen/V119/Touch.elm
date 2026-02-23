module Evergreen.V119.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V119.CssPixels
import Evergreen.V119.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V119.Point2d.Point2d Evergreen.V119.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
