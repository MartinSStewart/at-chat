module Evergreen.V313.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V313.CssPixels
import Evergreen.V313.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V313.Point2d.Point2d Evergreen.V313.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
