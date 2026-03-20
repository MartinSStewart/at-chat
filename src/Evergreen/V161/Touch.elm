module Evergreen.V161.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V161.CssPixels
import Evergreen.V161.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V161.Point2d.Point2d Evergreen.V161.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
