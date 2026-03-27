module Evergreen.V173.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V173.CssPixels
import Evergreen.V173.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V173.Point2d.Point2d Evergreen.V173.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
