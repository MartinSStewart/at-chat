module Evergreen.V342.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V342.CssPixels
import Evergreen.V342.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V342.Point2d.Point2d Evergreen.V342.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
