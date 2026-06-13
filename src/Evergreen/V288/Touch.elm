module Evergreen.V288.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V288.CssPixels
import Evergreen.V288.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V288.Point2d.Point2d Evergreen.V288.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
