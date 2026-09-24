module Evergreen.V385.MessageArray exposing (..)

import Array
import Evergreen.V385.Message


type alias Run messageId userId =
    { start : Int
    , values : Array.Array (Evergreen.V385.Message.Message messageId userId)
    }


type MessageArray messageId userId
    = MessageArray
        { start : Int
        , end : Int
        , runs : Array.Array (Run messageId userId)
        }
