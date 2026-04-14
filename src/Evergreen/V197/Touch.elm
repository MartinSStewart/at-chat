module Evergreen.V197.Touch exposing (..)

import Effect.Browser.Dom
import Evergreen.V197.CssPixels
import Evergreen.V197.Point2d


type ScreenCoordinate
    = ScreenCoordinate Never


type alias Touch =
    { client : Evergreen.V197.Point2d.Point2d Evergreen.V197.CssPixels.CssPixels ScreenCoordinate
    , target : Maybe Effect.Browser.Dom.HtmlId
    }
