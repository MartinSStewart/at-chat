module Evergreen.V104.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V104.CssPixels
import Evergreen.V104.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V104.Point2d.Point2d Evergreen.V104.CssPixels.CssPixels ScreenCoordinate
    , target : Effect.Browser.Dom.HtmlId
    }
