module Evergreen.V364.MessageArray exposing (..)

import Array


type alias Run v =
    { start : Int
    , values : Array.Array v
    }


type MessageArray k v
    = MessageArray
        { start : Int
        , end : Int
        , runs : Array.Array (Run v)
        }
