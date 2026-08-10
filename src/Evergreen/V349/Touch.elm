module Evergreen.V349.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V349.CssPixels
import Evergreen.V349.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V349.Point2d.Point2d Evergreen.V349.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
