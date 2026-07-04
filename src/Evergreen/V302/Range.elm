module Evergreen.V302.Range exposing (..)


type alias Range =
    { start : Int
    , end : Int
    }


type SelectionDirection
    = SelectForward
    | SelectBackward
