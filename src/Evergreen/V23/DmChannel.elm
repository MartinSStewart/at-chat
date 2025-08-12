module Evergreen.V23.DmChannel exposing (..)

import Array
import Evergreen.V23.Discord.Id
import Evergreen.V23.Id
import Evergreen.V23.Message
import Evergreen.V23.OneToOne
import SeqDict
import Time


type alias LastTypedAt =
    { time : Time.Posix
    , messageIndex : Maybe Int
    }


type alias DmChannel =
    { messages : Array.Array Evergreen.V23.Message.Message
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId) LastTypedAt
    , linkedMessageIds : Evergreen.V23.OneToOne.OneToOne (Evergreen.V23.Discord.Id.Id Evergreen.V23.Discord.Id.MessageId) Int
    }


type DmChannelId
    = DirectMessageChannelId (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId) (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId)
