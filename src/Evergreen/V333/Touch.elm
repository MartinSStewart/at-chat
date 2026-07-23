module Evergreen.V333.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V333.CssPixels
import Evergreen.V333.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V333.Point2d.Point2d Evergreen.V333.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
