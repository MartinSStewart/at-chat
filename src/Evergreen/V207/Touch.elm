module Evergreen.V207.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V207.CssPixels
import Evergreen.V207.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V207.Point2d.Point2d Evergreen.V207.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
