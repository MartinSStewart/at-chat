module Evergreen.V16.DmChannel exposing (..)

import Array
import Evergreen.V16.Discord.Id
import Evergreen.V16.Id
import Evergreen.V16.Message
import Evergreen.V16.OneToOne
import SeqDict
import Time


type alias LastTypedAt =
    { time : Time.Posix
    , messageIndex : Maybe Int
    }


type alias DmChannel =
    { messages : Array.Array Evergreen.V16.Message.Message
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId) LastTypedAt
    , linkedMessageIds : Evergreen.V16.OneToOne.OneToOne (Evergreen.V16.Discord.Id.Id Evergreen.V16.Discord.Id.MessageId) Int
    }


type DmChannelId
    = DirectMessageChannelId (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId) (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId)
