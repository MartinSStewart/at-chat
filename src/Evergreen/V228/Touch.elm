module Evergreen.V228.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V228.CssPixels
import Evergreen.V228.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V228.Point2d.Point2d Evergreen.V228.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
