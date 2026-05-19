module Evergreen.V240.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V240.CssPixels
import Evergreen.V240.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V240.Point2d.Point2d Evergreen.V240.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
