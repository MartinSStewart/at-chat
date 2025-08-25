module Evergreen.V27.DmChannel exposing (..)

import Array
import Evergreen.V27.Discord.Id
import Evergreen.V27.Id
import Evergreen.V27.Message
import Evergreen.V27.OneToOne
import SeqDict
import Time


type alias LastTypedAt =
    { time : Time.Posix
    , messageIndex : Maybe Int
    }


type alias DmChannel =
    { messages : Array.Array Evergreen.V27.Message.Message
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) LastTypedAt
    , linkedMessageIds : Evergreen.V27.OneToOne.OneToOne (Evergreen.V27.Discord.Id.Id Evergreen.V27.Discord.Id.MessageId) Int
    }


type DmChannelId
    = DirectMessageChannelId (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId)
