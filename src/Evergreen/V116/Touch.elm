module Evergreen.V116.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V116.CssPixels
import Evergreen.V116.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V116.Point2d.Point2d Evergreen.V116.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
