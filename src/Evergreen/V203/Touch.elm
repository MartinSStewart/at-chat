module Evergreen.V203.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V203.CssPixels
import Evergreen.V203.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V203.Point2d.Point2d Evergreen.V203.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
