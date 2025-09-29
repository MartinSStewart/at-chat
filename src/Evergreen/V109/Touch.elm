module Evergreen.V109.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V109.CssPixels
import Evergreen.V109.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V109.Point2d.Point2d Evergreen.V109.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
