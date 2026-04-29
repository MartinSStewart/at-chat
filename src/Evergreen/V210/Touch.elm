module Evergreen.V210.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V210.CssPixels
import Evergreen.V210.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V210.Point2d.Point2d Evergreen.V210.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
