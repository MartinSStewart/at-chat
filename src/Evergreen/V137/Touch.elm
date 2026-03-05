module Evergreen.V137.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V137.CssPixels
import Evergreen.V137.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V137.Point2d.Point2d Evergreen.V137.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
