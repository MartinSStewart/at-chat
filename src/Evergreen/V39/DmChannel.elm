module Evergreen.V39.DmChannel exposing (..)

import Array
import Evergreen.V39.Discord.Id
import Evergreen.V39.Id
import Evergreen.V39.Message
import Evergreen.V39.OneToOne
import SeqDict
import Time


type alias LastTypedAt messageId =
    { time : Time.Posix
    , messageIndex : Maybe (Evergreen.V39.Id.Id messageId)
    }


type alias Thread =
    { messages : Array.Array Evergreen.V39.Message.Message
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId) (LastTypedAt Evergreen.V39.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V39.OneToOne.OneToOne (Evergreen.V39.Discord.Id.Id Evergreen.V39.Discord.Id.MessageId) (Evergreen.V39.Id.Id Evergreen.V39.Id.ThreadMessageId)
    }


type alias DmChannel =
    { messages : Array.Array Evergreen.V39.Message.Message
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId) (LastTypedAt Evergreen.V39.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V39.OneToOne.OneToOne (Evergreen.V39.Discord.Id.Id Evergreen.V39.Discord.Id.MessageId) (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId) Thread
    , linkedThreadIds : Evergreen.V39.OneToOne.OneToOne (Evergreen.V39.Discord.Id.Id Evergreen.V39.Discord.Id.ChannelId) (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId)
    }


type DmChannelId
    = DirectMessageChannelId (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId) (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId)
