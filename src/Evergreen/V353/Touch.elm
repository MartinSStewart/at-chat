module Evergreen.V353.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V353.CssPixels
import Evergreen.V353.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V353.Point2d.Point2d Evergreen.V353.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
