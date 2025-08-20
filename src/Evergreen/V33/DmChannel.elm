module Evergreen.V33.DmChannel exposing (..)

import Array
import Evergreen.V33.Discord.Id
import Evergreen.V33.Id
import Evergreen.V33.Message
import Evergreen.V33.OneToOne
import SeqDict
import Time


type alias LastTypedAt =
    { time : Time.Posix
    , messageIndex : Maybe Int
    }


type alias Thread =
    { messages : Array.Array Evergreen.V33.Message.Message
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) LastTypedAt
    , linkedMessageIds : Evergreen.V33.OneToOne.OneToOne (Evergreen.V33.Discord.Id.Id Evergreen.V33.Discord.Id.MessageId) Int
    }


type alias DmChannel =
    { messages : Array.Array Evergreen.V33.Message.Message
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) LastTypedAt
    , linkedMessageIds : Evergreen.V33.OneToOne.OneToOne (Evergreen.V33.Discord.Id.Id Evergreen.V33.Discord.Id.MessageId) Int
    , threads : SeqDict.SeqDict Int Thread
    , linkedThreadIds : Evergreen.V33.OneToOne.OneToOne (Evergreen.V33.Discord.Id.Id Evergreen.V33.Discord.Id.ChannelId) Int
    }


type DmChannelId
    = DirectMessageChannelId (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId)
