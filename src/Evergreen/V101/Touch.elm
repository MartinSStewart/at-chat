module Evergreen.V101.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V101.CssPixels
import Evergreen.V101.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V101.Point2d.Point2d Evergreen.V101.CssPixels.CssPixels ScreenCoordinate
    , target : Effect.Browser.Dom.HtmlId
    }
