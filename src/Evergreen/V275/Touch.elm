module Evergreen.V275.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V275.CssPixels
import Evergreen.V275.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V275.Point2d.Point2d Evergreen.V275.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
