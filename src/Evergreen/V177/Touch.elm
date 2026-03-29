module Evergreen.V177.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V177.CssPixels
import Evergreen.V177.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V177.Point2d.Point2d Evergreen.V177.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
