module Evergreen.V318.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V318.CssPixels
import Evergreen.V318.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V318.Point2d.Point2d Evergreen.V318.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
