module Evergreen.V1.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V1.CssPixels
import Evergreen.V1.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V1.Point2d.Point2d Evergreen.V1.CssPixels.CssPixels ScreenCoordinate
    , target : Effect.Browser.Dom.HtmlId
    }
