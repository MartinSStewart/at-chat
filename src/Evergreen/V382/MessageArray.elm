module Evergreen.V382.MessageArray exposing (..)

import Array
import Evergreen.V382.Message


type alias Run messageId userId =
    { start : Int
    , values : Array.Array (Evergreen.V382.Message.Message messageId userId)
    }


type MessageArray messageId userId
    = MessageArray
        { start : Int
        , end : Int
        , runs : Array.Array (Run messageId userId)
        }
