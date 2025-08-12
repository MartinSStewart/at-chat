module Evergreen.V24.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V24.CssPixels
import Evergreen.V24.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V24.Point2d.Point2d Evergreen.V24.CssPixels.CssPixels ScreenCoordinate
    , target : Effect.Browser.Dom.HtmlId
    }
