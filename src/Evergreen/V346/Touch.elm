module Evergreen.V346.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V346.CssPixels
import Evergreen.V346.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V346.Point2d.Point2d Evergreen.V346.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
