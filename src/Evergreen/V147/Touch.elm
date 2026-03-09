module Evergreen.V147.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V147.CssPixels
import Evergreen.V147.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V147.Point2d.Point2d Evergreen.V147.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
