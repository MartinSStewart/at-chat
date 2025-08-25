module Evergreen.V29.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V29.CssPixels
import Evergreen.V29.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V29.Point2d.Point2d Evergreen.V29.CssPixels.CssPixels ScreenCoordinate
    , target : Effect.Browser.Dom.HtmlId
    }
