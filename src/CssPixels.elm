module CssPixels exposing (CssPixels(..), cssPixel, cssPixels, inCssPixels, px)

import Quantity exposing (Quantity)
import Ui


{-| OpaqueVariants
-}
type CssPixels
    = CssPixels Never


cssPixel : Quantity number CssPixels
cssPixel =
    Quantity.unsafe 1


cssPixels : number -> Quantity number CssPixels
cssPixels =
    Quantity.unsafe


inCssPixels : Quantity number CssPixels -> number
inCssPixels =
    Quantity.unwrap


px : Quantity Int CssPixels -> Ui.Length
px quantity =
    inCssPixels quantity |> Ui.px
