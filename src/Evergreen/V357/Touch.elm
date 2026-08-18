module Evergreen.V357.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V357.CssPixels
import Evergreen.V357.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V357.Point2d.Point2d Evergreen.V357.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
