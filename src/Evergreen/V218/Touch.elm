module Evergreen.V218.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V218.CssPixels
import Evergreen.V218.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V218.Point2d.Point2d Evergreen.V218.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
