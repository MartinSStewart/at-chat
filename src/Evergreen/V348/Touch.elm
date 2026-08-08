module Evergreen.V348.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V348.CssPixels
import Evergreen.V348.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V348.Point2d.Point2d Evergreen.V348.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
