module CodecExtra exposing (htmlId, quantityInt)

import Codec exposing (Codec)
import Effect.Browser.Dom as Dom
import Quantity exposing (Quantity)


quantityInt : Codec (Quantity Int units)
quantityInt =
    Codec.map Quantity.unsafe Quantity.unwrap Codec.int


htmlId : Codec Dom.HtmlId
htmlId =
    Codec.map Dom.id Dom.idToString Codec.string
