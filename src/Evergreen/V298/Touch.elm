module Evergreen.V298.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V298.CssPixels
import Evergreen.V298.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V298.Point2d.Point2d Evergreen.V298.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
