module Evergreen.V297.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V297.CssPixels
import Evergreen.V297.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V297.Point2d.Point2d Evergreen.V297.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
