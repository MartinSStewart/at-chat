module Evergreen.V287.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V287.CssPixels
import Evergreen.V287.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V287.Point2d.Point2d Evergreen.V287.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
