module Evergreen.V215.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V215.CssPixels
import Evergreen.V215.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V215.Point2d.Point2d Evergreen.V215.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
