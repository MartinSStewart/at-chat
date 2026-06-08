module Evergreen.V279.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V279.CssPixels
import Evergreen.V279.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V279.Point2d.Point2d Evergreen.V279.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
