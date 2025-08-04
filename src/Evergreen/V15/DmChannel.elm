module Evergreen.V15.DmChannel exposing (..)

import Array
import Evergreen.V15.Discord.Id
import Evergreen.V15.Id
import Evergreen.V15.Message
import Evergreen.V15.OneToOne
import SeqDict
import Time


type alias LastTypedAt =
    { time : Time.Posix
    , messageIndex : Maybe Int
    }


type alias DmChannel =
    { messages : Array.Array Evergreen.V15.Message.Message
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId) LastTypedAt
    , linkedMessageIds : Evergreen.V15.OneToOne.OneToOne (Evergreen.V15.Discord.Id.Id Evergreen.V15.Discord.Id.MessageId) Int
    }


type DmChannelId
    = DirectMessageChannelId (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId) (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId)
