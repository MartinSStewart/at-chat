module Evergreen.V295.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V295.CssPixels
import Evergreen.V295.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V295.Point2d.Point2d Evergreen.V295.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
