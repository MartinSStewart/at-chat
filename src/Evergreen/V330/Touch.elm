module Evergreen.V330.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V330.CssPixels
import Evergreen.V330.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V330.Point2d.Point2d Evergreen.V330.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
