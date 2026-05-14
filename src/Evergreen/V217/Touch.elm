module Evergreen.V217.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V217.CssPixels
import Evergreen.V217.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V217.Point2d.Point2d Evergreen.V217.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
