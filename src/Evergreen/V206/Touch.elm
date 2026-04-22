module Evergreen.V206.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V206.CssPixels
import Evergreen.V206.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V206.Point2d.Point2d Evergreen.V206.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
