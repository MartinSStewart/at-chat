module Evergreen.V236.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V236.CssPixels
import Evergreen.V236.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V236.Point2d.Point2d Evergreen.V236.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
