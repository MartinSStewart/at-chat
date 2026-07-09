module Evergreen.V309.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V309.CssPixels
import Evergreen.V309.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V309.Point2d.Point2d Evergreen.V309.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
