module Evergreen.V30.DmChannel exposing (..)

import Array
import Evergreen.V30.Discord.Id
import Evergreen.V30.Id
import Evergreen.V30.Message
import Evergreen.V30.OneToOne
import SeqDict
import Time


type alias LastTypedAt =
    { time : Time.Posix
    , messageIndex : Maybe Int
    }


type alias DmChannel =
    { messages : Array.Array Evergreen.V30.Message.Message
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) LastTypedAt
    , linkedMessageIds : Evergreen.V30.OneToOne.OneToOne (Evergreen.V30.Discord.Id.Id Evergreen.V30.Discord.Id.MessageId) Int
    }


type DmChannelId
    = DirectMessageChannelId (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId)
