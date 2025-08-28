module Evergreen.V38.DmChannel exposing (..)

import Array
import Evergreen.V38.Discord.Id
import Evergreen.V38.Id
import Evergreen.V38.Message
import Evergreen.V38.OneToOne
import SeqDict
import Time


type alias LastTypedAt messageId =
    { time : Time.Posix
    , messageIndex : Maybe (Evergreen.V38.Id.Id messageId)
    }


type alias Thread =
    { messages : Array.Array Evergreen.V38.Message.Message
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId) (LastTypedAt Evergreen.V38.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V38.OneToOne.OneToOne (Evergreen.V38.Discord.Id.Id Evergreen.V38.Discord.Id.MessageId) (Evergreen.V38.Id.Id Evergreen.V38.Id.ThreadMessageId)
    }


type alias DmChannel =
    { messages : Array.Array Evergreen.V38.Message.Message
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId) (LastTypedAt Evergreen.V38.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V38.OneToOne.OneToOne (Evergreen.V38.Discord.Id.Id Evergreen.V38.Discord.Id.MessageId) (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId) Thread
    , linkedThreadIds : Evergreen.V38.OneToOne.OneToOne (Evergreen.V38.Discord.Id.Id Evergreen.V38.Discord.Id.ChannelId) (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId)
    }


type DmChannelId
    = DirectMessageChannelId (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId) (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId)
