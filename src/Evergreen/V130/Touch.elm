module Evergreen.V130.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V130.CssPixels
import Evergreen.V130.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V130.Point2d.Point2d Evergreen.V130.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
