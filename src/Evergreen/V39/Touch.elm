module Evergreen.V39.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V39.CssPixels
import Evergreen.V39.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V39.Point2d.Point2d Evergreen.V39.CssPixels.CssPixels ScreenCoordinate
    , target : Effect.Browser.Dom.HtmlId
    }
