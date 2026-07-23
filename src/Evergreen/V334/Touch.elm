module Evergreen.V334.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V334.CssPixels
import Evergreen.V334.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V334.Point2d.Point2d Evergreen.V334.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
