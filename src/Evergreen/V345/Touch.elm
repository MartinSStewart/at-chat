module Evergreen.V345.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V345.CssPixels
import Evergreen.V345.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V345.Point2d.Point2d Evergreen.V345.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
