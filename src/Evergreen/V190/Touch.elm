module Evergreen.V190.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V190.CssPixels
import Evergreen.V190.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V190.Point2d.Point2d Evergreen.V190.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
