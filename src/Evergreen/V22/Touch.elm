module Evergreen.V22.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V22.CssPixels
import Evergreen.V22.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V22.Point2d.Point2d Evergreen.V22.CssPixels.CssPixels ScreenCoordinate
    , target : Effect.Browser.Dom.HtmlId
    }
