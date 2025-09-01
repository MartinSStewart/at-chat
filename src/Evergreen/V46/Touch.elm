module Evergreen.V46.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V46.CssPixels
import Evergreen.V46.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V46.Point2d.Point2d Evergreen.V46.CssPixels.CssPixels ScreenCoordinate
    , target : Effect.Browser.Dom.HtmlId
    }
