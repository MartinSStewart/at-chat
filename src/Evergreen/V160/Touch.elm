module Evergreen.V160.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V160.CssPixels
import Evergreen.V160.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V160.Point2d.Point2d Evergreen.V160.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
