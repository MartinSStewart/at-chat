module Evergreen.V263.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V263.CssPixels
import Evergreen.V263.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V263.Point2d.Point2d Evergreen.V263.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
