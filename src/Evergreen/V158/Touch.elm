module Evergreen.V158.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V158.CssPixels
import Evergreen.V158.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V158.Point2d.Point2d Evergreen.V158.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
