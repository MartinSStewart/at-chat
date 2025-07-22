module Evergreen.V14.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V14.CssPixels
import Evergreen.V14.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V14.Point2d.Point2d Evergreen.V14.CssPixels.CssPixels ScreenCoordinate
    , target : Effect.Browser.Dom.HtmlId
    }
