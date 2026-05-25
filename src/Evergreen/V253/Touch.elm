module Evergreen.V253.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V253.CssPixels
import Evergreen.V253.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V253.Point2d.Point2d Evergreen.V253.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
