module Evergreen.V134.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V134.CssPixels
import Evergreen.V134.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V134.Point2d.Point2d Evergreen.V134.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
