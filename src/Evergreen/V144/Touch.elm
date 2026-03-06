module Evergreen.V144.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V144.CssPixels
import Evergreen.V144.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V144.Point2d.Point2d Evergreen.V144.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
