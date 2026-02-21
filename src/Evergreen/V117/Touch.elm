module Evergreen.V117.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V117.CssPixels
import Evergreen.V117.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V117.Point2d.Point2d Evergreen.V117.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
