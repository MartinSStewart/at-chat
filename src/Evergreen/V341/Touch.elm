module Evergreen.V341.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V341.CssPixels
import Evergreen.V341.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V341.Point2d.Point2d Evergreen.V341.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
