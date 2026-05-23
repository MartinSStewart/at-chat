module Evergreen.V250.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V250.CssPixels
import Evergreen.V250.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V250.Point2d.Point2d Evergreen.V250.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
