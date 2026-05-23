module Evergreen.V251.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V251.CssPixels
import Evergreen.V251.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V251.Point2d.Point2d Evergreen.V251.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
