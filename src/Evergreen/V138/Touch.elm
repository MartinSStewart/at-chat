module Evergreen.V138.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V138.CssPixels
import Evergreen.V138.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V138.Point2d.Point2d Evergreen.V138.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
