module Evergreen.V149.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V149.CssPixels
import Evergreen.V149.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V149.Point2d.Point2d Evergreen.V149.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
