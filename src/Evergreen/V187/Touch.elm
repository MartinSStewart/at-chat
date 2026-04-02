module Evergreen.V187.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V187.CssPixels
import Evergreen.V187.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V187.Point2d.Point2d Evergreen.V187.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
