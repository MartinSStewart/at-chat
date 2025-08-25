module CssPixels exposing (CssPixels(..), cssPixels, inCssPixels)

import Quantity exposing (Quantity)


{-| OpaqueVariants
-}
type CssPixels
    = CssPixels Never


cssPixels : number -> Quantity number CssPixels
cssPixels =
    Quantity.unsafe


inCssPixels : Quantity number CssPixels -> number
inCssPixels =
    Quantity.unwrap
