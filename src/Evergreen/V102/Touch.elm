module Evergreen.V102.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V102.CssPixels
import Evergreen.V102.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V102.Point2d.Point2d Evergreen.V102.CssPixels.CssPixels ScreenCoordinate
    , target : Effect.Browser.Dom.HtmlId
    }
