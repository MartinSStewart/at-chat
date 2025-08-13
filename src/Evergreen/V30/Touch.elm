module Evergreen.V30.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V30.CssPixels
import Evergreen.V30.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V30.Point2d.Point2d Evergreen.V30.CssPixels.CssPixels ScreenCoordinate
    , target : Effect.Browser.Dom.HtmlId
    }
