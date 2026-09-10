module Evergreen.V376.MessageArray exposing (..)

import Array
import Evergreen.V376.Message


type alias Run messageId userId =
    { start : Int
    , values : Array.Array (Evergreen.V376.Message.Message messageId userId)
    }


type MessageArray messageId userId
    = MessageArray
        { start : Int
        , end : Int
        , runs : Array.Array (Run messageId userId)
        }
