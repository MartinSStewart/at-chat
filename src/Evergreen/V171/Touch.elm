module Evergreen.V171.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V171.CssPixels
import Evergreen.V171.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V171.Point2d.Point2d Evergreen.V171.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
