module Evergreen.V148.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V148.CssPixels
import Evergreen.V148.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V148.Point2d.Point2d Evergreen.V148.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
