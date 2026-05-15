module Evergreen.V223.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V223.CssPixels
import Evergreen.V223.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V223.Point2d.Point2d Evergreen.V223.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
