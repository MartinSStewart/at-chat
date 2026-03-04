module Evergreen.V128.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V128.CssPixels
import Evergreen.V128.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V128.Point2d.Point2d Evergreen.V128.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
