module Evergreen.V22.DmChannel exposing (..)

import Array
import Evergreen.V22.Discord.Id
import Evergreen.V22.Id
import Evergreen.V22.Message
import Evergreen.V22.OneToOne
import SeqDict
import Time


type alias LastTypedAt =
    { time : Time.Posix
    , messageIndex : Maybe Int
    }


type alias DmChannel =
    { messages : Array.Array Evergreen.V22.Message.Message
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) LastTypedAt
    , linkedMessageIds : Evergreen.V22.OneToOne.OneToOne (Evergreen.V22.Discord.Id.Id Evergreen.V22.Discord.Id.MessageId) Int
    }


type DmChannelId
    = DirectMessageChannelId (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId) (Evergreen.V22.Id.Id Evergreen.V22.Id.UserId)
