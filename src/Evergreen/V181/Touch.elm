module Evergreen.V181.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V181.CssPixels
import Evergreen.V181.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V181.Point2d.Point2d Evergreen.V181.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
