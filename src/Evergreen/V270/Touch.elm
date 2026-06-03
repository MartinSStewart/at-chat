module Evergreen.V270.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V270.CssPixels
import Evergreen.V270.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V270.Point2d.Point2d Evergreen.V270.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
