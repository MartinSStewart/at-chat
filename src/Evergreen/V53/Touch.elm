module Evergreen.V53.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V53.CssPixels
import Evergreen.V53.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V53.Point2d.Point2d Evergreen.V53.CssPixels.CssPixels ScreenCoordinate
    , target : Effect.Browser.Dom.HtmlId
    }
