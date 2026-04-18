module Evergreen.V204.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V204.CssPixels
import Evergreen.V204.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V204.Point2d.Point2d Evergreen.V204.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
