module Evergreen.V163.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V163.CssPixels
import Evergreen.V163.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V163.Point2d.Point2d Evergreen.V163.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
