module Evergreen.V108.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V108.CssPixels
import Evergreen.V108.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V108.Point2d.Point2d Evergreen.V108.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
