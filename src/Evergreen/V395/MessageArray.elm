module Evergreen.V395.MessageArray exposing (..)

import Array
import Evergreen.V395.Message


type alias Run messageId userId channelId =
    { start : Int
    , values : Array.Array (Evergreen.V395.Message.Message messageId userId channelId)
    }


type MessageArray messageId userId channelId
    = MessageArray
        { start : Int
        , end : Int
        , runs : Array.Array (Run messageId userId channelId)
        }
