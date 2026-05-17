module Evergreen.V232.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V232.CssPixels
import Evergreen.V232.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V232.Point2d.Point2d Evergreen.V232.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
