module Range exposing (Range, SelectionDirection(..), codec, inside, rangeSize, selectionDirectionCodec)

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


selectionDirectionCodec : Codec SelectionDirection
selectionDirectionCodec =
    Codec.enum Codec.string [ ( "forward", SelectForward ), ( "backward", SelectBackward ) ]


inside : Int -> Range -> Bool
inside index range =
    index > range.start && index < range.end
