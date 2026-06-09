module Evergreen.V283.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V283.CssPixels
import Evergreen.V283.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V283.Point2d.Point2d Evergreen.V283.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
