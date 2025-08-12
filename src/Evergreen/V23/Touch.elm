module Evergreen.V23.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V23.CssPixels
import Evergreen.V23.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V23.Point2d.Point2d Evergreen.V23.CssPixels.CssPixels ScreenCoordinate
    , target : Effect.Browser.Dom.HtmlId
    }
