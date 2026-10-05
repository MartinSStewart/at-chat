module Evergreen.V398.MessageArray exposing (..)

import Array
import Evergreen.V398.Message


type alias Run messageId userId channelId =
    { start : Int
    , values : Array.Array (Evergreen.V398.Message.Message messageId userId channelId)
    }


type MessageArray messageId userId channelId
    = MessageArray
        { start : Int
        , end : Int
        , runs : Array.Array (Run messageId userId channelId)
        }
