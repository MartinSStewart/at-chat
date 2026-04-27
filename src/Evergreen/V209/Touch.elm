module Evergreen.V209.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V209.CssPixels
import Evergreen.V209.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V209.Point2d.Point2d Evergreen.V209.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
