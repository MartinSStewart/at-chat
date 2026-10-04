module Evergreen.V397.Range exposing (..)


type alias Range =
    { start : Int
    , end : Int
    }


type SelectionDirection
    = SelectForward
    | SelectBackward
