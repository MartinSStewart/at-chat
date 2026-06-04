module CodecExtra exposing (htmlId, quantityInt, url)

import Codec exposing (Codec)
import Effect.Browser.Dom as Dom
import Quantity exposing (Quantity)
import Url exposing (Url)


quantityInt : Codec (Quantity Int units)
quantityInt =
    Codec.map Quantity.unsafe Quantity.unwrap Codec.int


htmlId : Codec Dom.HtmlId
htmlId =
    Codec.map Dom.id Dom.idToString Codec.string


url : Codec Url
url =
    Codec.andThen
        (\text ->
            case Url.fromString text of
                Just url2 ->
                    Codec.succeed url2

                Nothing ->
                    Codec.fail ("Invalid url: " ++ text)
        )
        Url.toString
        Codec.string
