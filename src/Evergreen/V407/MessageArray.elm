module Evergreen.V407.MessageArray exposing (..)

import Array
import Evergreen.V407.Message


type alias Run messageId userId channelId =
    { start : Int
    , values : Array.Array (Evergreen.V407.Message.Message messageId userId channelId)
    }


type MessageArray messageId userId channelId
    = MessageArray
        { start : Int
        , end : Int
        , runs : Array.Array (Run messageId userId channelId)
        }
