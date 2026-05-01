module Evergreen.V213.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V213.CssPixels
import Evergreen.V213.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V213.Point2d.Point2d Evergreen.V213.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
