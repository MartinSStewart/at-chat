module Evergreen.V186.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V186.CssPixels
import Evergreen.V186.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V186.Point2d.Point2d Evergreen.V186.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
