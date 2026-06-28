module Evergreen.V296.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V296.CssPixels
import Evergreen.V296.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V296.Point2d.Point2d Evergreen.V296.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
