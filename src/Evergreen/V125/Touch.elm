module Evergreen.V125.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V125.CssPixels
import Evergreen.V125.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V125.Point2d.Point2d Evergreen.V125.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
