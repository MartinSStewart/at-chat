module Evergreen.V115.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V115.CssPixels
import Evergreen.V115.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V115.Point2d.Point2d Evergreen.V115.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
