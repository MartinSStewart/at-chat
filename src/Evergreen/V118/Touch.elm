module Evergreen.V118.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V118.CssPixels
import Evergreen.V118.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V118.Point2d.Point2d Evergreen.V118.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
