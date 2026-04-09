module Range exposing (Range, SelectionDirection(..), codec, rangeSize)

import Codec exposing (Codec)


type alias Range =
    { start : Int, end : Int }


type SelectionDirection
    = SelectForward
    | SelectBackward


rangeSize : Range -> Int
rangeSize range =
    range.end - range.start


codec : Codec Range
codec =
    Codec.object Range
        |> Codec.field "start" .start Codec.int
        |> Codec.field "end" .end Codec.int
        |> Codec.buildObject
