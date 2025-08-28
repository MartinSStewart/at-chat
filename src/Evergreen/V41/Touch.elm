module Evergreen.V41.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V41.CssPixels
import Evergreen.V41.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V41.Point2d.Point2d Evergreen.V41.CssPixels.CssPixels ScreenCoordinate
    , target : Effect.Browser.Dom.HtmlId
    }
