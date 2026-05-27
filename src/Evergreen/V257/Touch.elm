module Evergreen.V257.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V257.CssPixels
import Evergreen.V257.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V257.Point2d.Point2d Evergreen.V257.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
