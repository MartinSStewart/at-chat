module Evergreen.V42.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V42.CssPixels
import Evergreen.V42.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V42.Point2d.Point2d Evergreen.V42.CssPixels.CssPixels ScreenCoordinate
    , target : Effect.Browser.Dom.HtmlId
    }
