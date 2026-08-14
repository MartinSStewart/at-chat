module Evergreen.V352.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V352.CssPixels
import Evergreen.V352.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V352.Point2d.Point2d Evergreen.V352.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
