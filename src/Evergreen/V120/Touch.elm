module Evergreen.V120.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V120.CssPixels
import Evergreen.V120.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V120.Point2d.Point2d Evergreen.V120.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
