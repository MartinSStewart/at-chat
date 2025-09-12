module Evergreen.V56.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V56.CssPixels
import Evergreen.V56.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V56.Point2d.Point2d Evergreen.V56.CssPixels.CssPixels ScreenCoordinate
    , target : Effect.Browser.Dom.HtmlId
    }
