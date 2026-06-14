module Evergreen.V289.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V289.CssPixels
import Evergreen.V289.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V289.Point2d.Point2d Evergreen.V289.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
