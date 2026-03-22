module Evergreen.V166.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V166.CssPixels
import Evergreen.V166.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V166.Point2d.Point2d Evergreen.V166.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
