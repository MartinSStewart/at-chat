module Evergreen.V26.DmChannel exposing (..)

import Array
import Evergreen.V26.Discord.Id
import Evergreen.V26.Id
import Evergreen.V26.Message
import Evergreen.V26.OneToOne
import SeqDict
import Time


type alias LastTypedAt =
    { time : Time.Posix
    , messageIndex : Maybe Int
    }


type alias DmChannel =
    { messages : Array.Array Evergreen.V26.Message.Message
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId) LastTypedAt
    , linkedMessageIds : Evergreen.V26.OneToOne.OneToOne (Evergreen.V26.Discord.Id.Id Evergreen.V26.Discord.Id.MessageId) Int
    }


type DmChannelId
    = DirectMessageChannelId (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId) (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId)
