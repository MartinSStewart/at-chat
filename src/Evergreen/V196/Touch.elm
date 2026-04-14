module Evergreen.V196.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V196.CssPixels
import Evergreen.V196.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V196.Point2d.Point2d Evergreen.V196.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
