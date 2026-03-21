module Evergreen.V162.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V162.CssPixels
import Evergreen.V162.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V162.Point2d.Point2d Evergreen.V162.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
