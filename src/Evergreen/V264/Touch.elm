module Evergreen.V264.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V264.CssPixels
import Evergreen.V264.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V264.Point2d.Point2d Evergreen.V264.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
