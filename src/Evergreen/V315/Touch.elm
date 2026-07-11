module Evergreen.V315.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V315.CssPixels
import Evergreen.V315.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V315.Point2d.Point2d Evergreen.V315.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
