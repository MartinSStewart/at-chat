module Evergreen.V45.DmChannel exposing (..)

import Array
import Evergreen.V45.Discord.Id
import Evergreen.V45.Id
import Evergreen.V45.Message
import Evergreen.V45.OneToOne
import SeqDict
import Time


type alias LastTypedAt messageId =
    { time : Time.Posix
    , messageIndex : Maybe (Evergreen.V45.Id.Id messageId)
    }


type alias Thread =
    { messages : Array.Array Evergreen.V45.Message.Message
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId) (LastTypedAt Evergreen.V45.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V45.OneToOne.OneToOne (Evergreen.V45.Discord.Id.Id Evergreen.V45.Discord.Id.MessageId) (Evergreen.V45.Id.Id Evergreen.V45.Id.ThreadMessageId)
    }


type alias DmChannel =
    { messages : Array.Array Evergreen.V45.Message.Message
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId) (LastTypedAt Evergreen.V45.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V45.OneToOne.OneToOne (Evergreen.V45.Discord.Id.Id Evergreen.V45.Discord.Id.MessageId) (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelMessageId) Thread
    , linkedThreadIds : Evergreen.V45.OneToOne.OneToOne (Evergreen.V45.Discord.Id.Id Evergreen.V45.Discord.Id.ChannelId) (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelMessageId)
    }


type DmChannelId
    = DirectMessageChannelId (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId) (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId)
