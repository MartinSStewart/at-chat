module Evergreen.V92.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V92.CssPixels
import Evergreen.V92.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V92.Point2d.Point2d Evergreen.V92.CssPixels.CssPixels ScreenCoordinate
    , target : Effect.Browser.Dom.HtmlId
    }
