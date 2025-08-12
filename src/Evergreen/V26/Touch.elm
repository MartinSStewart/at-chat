module Evergreen.V26.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V26.CssPixels
import Evergreen.V26.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V26.Point2d.Point2d Evergreen.V26.CssPixels.CssPixels ScreenCoordinate
    , target : Effect.Browser.Dom.HtmlId
    }
