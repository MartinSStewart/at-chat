module Evergreen.V307.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V307.CssPixels
import Evergreen.V307.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V307.Point2d.Point2d Evergreen.V307.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
