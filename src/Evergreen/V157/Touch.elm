module Evergreen.V157.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V157.CssPixels
import Evergreen.V157.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V157.Point2d.Point2d Evergreen.V157.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
