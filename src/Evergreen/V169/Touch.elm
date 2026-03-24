module Evergreen.V169.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V169.CssPixels
import Evergreen.V169.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V169.Point2d.Point2d Evergreen.V169.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
