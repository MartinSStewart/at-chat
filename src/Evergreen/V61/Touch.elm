module Evergreen.V61.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V61.CssPixels
import Evergreen.V61.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V61.Point2d.Point2d Evergreen.V61.CssPixels.CssPixels ScreenCoordinate
    , target : Effect.Browser.Dom.HtmlId
    }
