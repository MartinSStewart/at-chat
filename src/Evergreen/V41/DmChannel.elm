module Evergreen.V41.DmChannel exposing (..)

import Array
import Evergreen.V41.Discord.Id
import Evergreen.V41.Id
import Evergreen.V41.Message
import Evergreen.V41.OneToOne
import SeqDict
import Time


type alias LastTypedAt messageId =
    { time : Time.Posix
    , messageIndex : Maybe (Evergreen.V41.Id.Id messageId)
    }


type alias Thread =
    { messages : Array.Array Evergreen.V41.Message.Message
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId) (LastTypedAt Evergreen.V41.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V41.OneToOne.OneToOne (Evergreen.V41.Discord.Id.Id Evergreen.V41.Discord.Id.MessageId) (Evergreen.V41.Id.Id Evergreen.V41.Id.ThreadMessageId)
    }


type alias DmChannel =
    { messages : Array.Array Evergreen.V41.Message.Message
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId) (LastTypedAt Evergreen.V41.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V41.OneToOne.OneToOne (Evergreen.V41.Discord.Id.Id Evergreen.V41.Discord.Id.MessageId) (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId) Thread
    , linkedThreadIds : Evergreen.V41.OneToOne.OneToOne (Evergreen.V41.Discord.Id.Id Evergreen.V41.Discord.Id.ChannelId) (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId)
    }


type DmChannelId
    = DirectMessageChannelId (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId) (Evergreen.V41.Id.Id Evergreen.V41.Id.UserId)
