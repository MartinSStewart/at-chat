module CssPixels exposing (CssPixels(..), cssPixels)

import Quantity exposing (Quantity)


{-| OpaqueVariants
-}
type CssPixels
    = CssPixels Never


cssPixels : number -> Quantity number CssPixels
cssPixels =
    Quantity.unsafe
