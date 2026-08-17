module Evergreen.V354.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V354.CssPixels
import Evergreen.V354.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V354.Point2d.Point2d Evergreen.V354.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
