module Evergreen.V358.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V358.CssPixels
import Evergreen.V358.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V358.Point2d.Point2d Evergreen.V358.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
