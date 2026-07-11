module Evergreen.V312.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V312.CssPixels
import Evergreen.V312.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V312.Point2d.Point2d Evergreen.V312.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
