module Evergreen.V360.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V360.CssPixels
import Evergreen.V360.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V360.Point2d.Point2d Evergreen.V360.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
