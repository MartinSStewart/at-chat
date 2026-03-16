module Evergreen.V154.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V154.CssPixels
import Evergreen.V154.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V154.Point2d.Point2d Evergreen.V154.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
