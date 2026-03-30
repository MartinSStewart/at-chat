module Evergreen.V179.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V179.CssPixels
import Evergreen.V179.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V179.Point2d.Point2d Evergreen.V179.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
