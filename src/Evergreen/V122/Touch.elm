module Evergreen.V122.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V122.CssPixels
import Evergreen.V122.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V122.Point2d.Point2d Evergreen.V122.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
