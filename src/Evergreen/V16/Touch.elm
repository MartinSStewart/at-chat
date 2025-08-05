module Evergreen.V16.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V16.CssPixels
import Evergreen.V16.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V16.Point2d.Point2d Evergreen.V16.CssPixels.CssPixels ScreenCoordinate
    , target : Effect.Browser.Dom.HtmlId
    }
