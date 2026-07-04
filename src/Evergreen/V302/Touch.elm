module Evergreen.V302.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V302.CssPixels
import Evergreen.V302.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V302.Point2d.Point2d Evergreen.V302.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
