module Evergreen.V293.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V293.CssPixels
import Evergreen.V293.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V293.Point2d.Point2d Evergreen.V293.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
