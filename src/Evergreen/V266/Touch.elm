module Evergreen.V266.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V266.CssPixels
import Evergreen.V266.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V266.Point2d.Point2d Evergreen.V266.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
