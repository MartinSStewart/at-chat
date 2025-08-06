module Evergreen.V17.DmChannel exposing (..)

import Array
import Evergreen.V17.Discord.Id
import Evergreen.V17.Id
import Evergreen.V17.Message
import Evergreen.V17.OneToOne
import SeqDict
import Time


type alias LastTypedAt =
    { time : Time.Posix
    , messageIndex : Maybe Int
    }


type alias DmChannel =
    { messages : Array.Array Evergreen.V17.Message.Message
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId) LastTypedAt
    , linkedMessageIds : Evergreen.V17.OneToOne.OneToOne (Evergreen.V17.Discord.Id.Id Evergreen.V17.Discord.Id.MessageId) Int
    }


type DmChannelId
    = DirectMessageChannelId (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId) (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId)
