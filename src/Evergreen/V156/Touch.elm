module Evergreen.V156.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V156.CssPixels
import Evergreen.V156.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V156.Point2d.Point2d Evergreen.V156.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
