module Evergreen.V176.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V176.CssPixels
import Evergreen.V176.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V176.Point2d.Point2d Evergreen.V176.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
