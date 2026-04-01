module Evergreen.V185.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V185.CssPixels
import Evergreen.V185.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V185.Point2d.Point2d Evergreen.V185.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
