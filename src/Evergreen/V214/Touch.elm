module Evergreen.V214.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V214.CssPixels
import Evergreen.V214.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V214.Point2d.Point2d Evergreen.V214.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
