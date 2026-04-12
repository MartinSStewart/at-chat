module Evergreen.V194.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V194.CssPixels
import Evergreen.V194.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V194.Point2d.Point2d Evergreen.V194.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
