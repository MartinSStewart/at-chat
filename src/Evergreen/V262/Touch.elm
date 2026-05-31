module Evergreen.V262.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V262.CssPixels
import Evergreen.V262.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V262.Point2d.Point2d Evergreen.V262.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
