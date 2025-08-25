module Evergreen.V33.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V33.CssPixels
import Evergreen.V33.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V33.Point2d.Point2d Evergreen.V33.CssPixels.CssPixels ScreenCoordinate
    , target : Effect.Browser.Dom.HtmlId
    }
