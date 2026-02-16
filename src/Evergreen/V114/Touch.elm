module Evergreen.V114.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V114.CssPixels
import Evergreen.V114.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V114.Point2d.Point2d Evergreen.V114.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
