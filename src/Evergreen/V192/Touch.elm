module Evergreen.V192.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V192.CssPixels
import Evergreen.V192.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V192.Point2d.Point2d Evergreen.V192.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
