module Evergreen.V167.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V167.CssPixels
import Evergreen.V167.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V167.Point2d.Point2d Evergreen.V167.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
