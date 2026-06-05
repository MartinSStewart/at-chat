module Evergreen.V277.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V277.CssPixels
import Evergreen.V277.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V277.Point2d.Point2d Evergreen.V277.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
