module Evergreen.V31.DmChannel exposing (..)

import Array
import Evergreen.V31.Discord.Id
import Evergreen.V31.Id
import Evergreen.V31.Message
import Evergreen.V31.OneToOne
import SeqDict
import Time


type alias LastTypedAt =
    { time : Time.Posix
    , messageIndex : Maybe Int
    }


type alias DmChannel =
    { messages : Array.Array Evergreen.V31.Message.Message
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V31.Id.Id Evergreen.V31.Id.UserId) LastTypedAt
    , linkedMessageIds : Evergreen.V31.OneToOne.OneToOne (Evergreen.V31.Discord.Id.Id Evergreen.V31.Discord.Id.MessageId) Int
    }


type DmChannelId
    = DirectMessageChannelId (Evergreen.V31.Id.Id Evergreen.V31.Id.UserId) (Evergreen.V31.Id.Id Evergreen.V31.Id.UserId)
