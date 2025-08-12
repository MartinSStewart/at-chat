module Evergreen.V24.DmChannel exposing (..)

import Array
import Evergreen.V24.Discord.Id
import Evergreen.V24.Id
import Evergreen.V24.Message
import Evergreen.V24.OneToOne
import SeqDict
import Time


type alias LastTypedAt =
    { time : Time.Posix
    , messageIndex : Maybe Int
    }


type alias DmChannel =
    { messages : Array.Array Evergreen.V24.Message.Message
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId) LastTypedAt
    , linkedMessageIds : Evergreen.V24.OneToOne.OneToOne (Evergreen.V24.Discord.Id.Id Evergreen.V24.Discord.Id.MessageId) Int
    }


type DmChannelId
    = DirectMessageChannelId (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId) (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId)
