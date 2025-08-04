module Evergreen.V15.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V15.CssPixels
import Evergreen.V15.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V15.Point2d.Point2d Evergreen.V15.CssPixels.CssPixels ScreenCoordinate
    , target : Effect.Browser.Dom.HtmlId
    }
