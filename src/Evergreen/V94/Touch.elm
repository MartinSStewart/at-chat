module Evergreen.V94.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V94.CssPixels
import Evergreen.V94.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V94.Point2d.Point2d Evergreen.V94.CssPixels.CssPixels ScreenCoordinate
    , target : Effect.Browser.Dom.HtmlId
    }
