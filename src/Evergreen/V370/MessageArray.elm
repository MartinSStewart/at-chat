module Evergreen.V370.MessageArray exposing (..)

import Array
import Evergreen.V370.Message


type alias Run messageId userId =
    { start : Int
    , values : Array.Array (Evergreen.V370.Message.Message messageId userId)
    }


type MessageArray messageId userId
    = MessageArray
        { start : Int
        , end : Int
        , runs : Array.Array (Run messageId userId)
        }
