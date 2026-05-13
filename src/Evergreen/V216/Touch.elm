module Evergreen.V216.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V216.CssPixels
import Evergreen.V216.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V216.Point2d.Point2d Evergreen.V216.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
