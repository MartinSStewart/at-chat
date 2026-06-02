module Evergreen.V267.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V267.CssPixels
import Evergreen.V267.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V267.Point2d.Point2d Evergreen.V267.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
