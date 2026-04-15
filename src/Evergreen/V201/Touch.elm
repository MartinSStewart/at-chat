module Evergreen.V201.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V201.CssPixels
import Evergreen.V201.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V201.Point2d.Point2d Evergreen.V201.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
