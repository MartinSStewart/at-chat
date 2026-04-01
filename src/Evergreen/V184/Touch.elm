module Evergreen.V184.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V184.CssPixels
import Evergreen.V184.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V184.Point2d.Point2d Evergreen.V184.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
