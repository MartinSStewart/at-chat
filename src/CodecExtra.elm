module CodecExtra exposing (quantityInt)

import Codec exposing (Codec)
import Quantity exposing (Quantity)


quantityInt : Codec (Quantity Int units)
quantityInt =
    Codec.map Quantity.unsafe Quantity.unwrap Codec.int
