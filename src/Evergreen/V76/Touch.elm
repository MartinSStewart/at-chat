module Evergreen.V76.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V76.CssPixels
import Evergreen.V76.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V76.Point2d.Point2d Evergreen.V76.CssPixels.CssPixels ScreenCoordinate
    , target : Effect.Browser.Dom.HtmlId
    }
