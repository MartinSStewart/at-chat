module Evergreen.V52.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V52.CssPixels
import Evergreen.V52.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V52.Point2d.Point2d Evergreen.V52.CssPixels.CssPixels ScreenCoordinate
    , target : Effect.Browser.Dom.HtmlId
    }
