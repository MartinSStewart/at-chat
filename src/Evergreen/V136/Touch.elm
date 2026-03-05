module Evergreen.V136.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V136.CssPixels
import Evergreen.V136.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V136.Point2d.Point2d Evergreen.V136.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
