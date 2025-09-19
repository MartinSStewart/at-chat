module Evergreen.V90.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V90.CssPixels
import Evergreen.V90.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V90.Point2d.Point2d Evergreen.V90.CssPixels.CssPixels ScreenCoordinate
    , target : Effect.Browser.Dom.HtmlId
    }
