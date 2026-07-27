module Evergreen.V336.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V336.CssPixels
import Evergreen.V336.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V336.Point2d.Point2d Evergreen.V336.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
