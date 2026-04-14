module Evergreen.V199.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V199.CssPixels
import Evergreen.V199.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V199.Point2d.Point2d Evergreen.V199.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
