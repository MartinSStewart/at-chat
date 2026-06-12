module Evergreen.V286.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V286.CssPixels
import Evergreen.V286.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V286.Point2d.Point2d Evergreen.V286.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
