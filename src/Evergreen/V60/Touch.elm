module Evergreen.V60.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V60.CssPixels
import Evergreen.V60.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V60.Point2d.Point2d Evergreen.V60.CssPixels.CssPixels ScreenCoordinate
    , target : Effect.Browser.Dom.HtmlId
    }
