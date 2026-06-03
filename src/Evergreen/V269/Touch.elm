module Evergreen.V269.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V269.CssPixels
import Evergreen.V269.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V269.Point2d.Point2d Evergreen.V269.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
