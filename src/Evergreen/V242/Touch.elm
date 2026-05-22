module Evergreen.V242.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V242.CssPixels
import Evergreen.V242.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V242.Point2d.Point2d Evergreen.V242.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
