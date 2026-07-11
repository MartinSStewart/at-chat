module Evergreen.V316.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V316.CssPixels
import Evergreen.V316.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V316.Point2d.Point2d Evergreen.V316.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
