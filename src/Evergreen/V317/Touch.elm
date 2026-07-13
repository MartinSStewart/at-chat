module Evergreen.V317.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V317.CssPixels
import Evergreen.V317.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V317.Point2d.Point2d Evergreen.V317.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
