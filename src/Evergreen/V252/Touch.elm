module Evergreen.V252.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V252.CssPixels
import Evergreen.V252.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V252.Point2d.Point2d Evergreen.V252.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
