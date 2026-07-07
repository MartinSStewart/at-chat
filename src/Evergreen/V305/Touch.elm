module Evergreen.V305.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V305.CssPixels
import Evergreen.V305.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V305.Point2d.Point2d Evergreen.V305.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
