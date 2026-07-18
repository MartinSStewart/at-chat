module Evergreen.V328.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V328.CssPixels
import Evergreen.V328.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V328.Point2d.Point2d Evergreen.V328.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
