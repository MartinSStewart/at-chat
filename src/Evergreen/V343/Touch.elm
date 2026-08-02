module Evergreen.V343.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V343.CssPixels
import Evergreen.V343.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V343.Point2d.Point2d Evergreen.V343.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
