module Evergreen.V261.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V261.CssPixels
import Evergreen.V261.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V261.Point2d.Point2d Evergreen.V261.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
