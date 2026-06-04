module Evergreen.V271.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V271.CssPixels
import Evergreen.V271.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V271.Point2d.Point2d Evergreen.V271.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
