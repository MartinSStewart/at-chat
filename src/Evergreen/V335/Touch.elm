module Evergreen.V335.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V335.CssPixels
import Evergreen.V335.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V335.Point2d.Point2d Evergreen.V335.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
