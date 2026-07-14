module Evergreen.V319.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V319.CssPixels
import Evergreen.V319.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V319.Point2d.Point2d Evergreen.V319.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
