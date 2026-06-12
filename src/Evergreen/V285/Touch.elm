module Evergreen.V285.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V285.CssPixels
import Evergreen.V285.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V285.Point2d.Point2d Evergreen.V285.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
