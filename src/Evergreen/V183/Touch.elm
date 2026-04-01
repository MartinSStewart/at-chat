module Evergreen.V183.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V183.CssPixels
import Evergreen.V183.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V183.Point2d.Point2d Evergreen.V183.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
