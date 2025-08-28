module Evergreen.V42.DmChannel exposing (..)

import Array
import Evergreen.V42.Discord.Id
import Evergreen.V42.Id
import Evergreen.V42.Message
import Evergreen.V42.OneToOne
import SeqDict
import Time


type alias LastTypedAt messageId =
    { time : Time.Posix
    , messageIndex : Maybe (Evergreen.V42.Id.Id messageId)
    }


type alias Thread =
    { messages : Array.Array Evergreen.V42.Message.Message
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId) (LastTypedAt Evergreen.V42.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V42.OneToOne.OneToOne (Evergreen.V42.Discord.Id.Id Evergreen.V42.Discord.Id.MessageId) (Evergreen.V42.Id.Id Evergreen.V42.Id.ThreadMessageId)
    }


type alias DmChannel =
    { messages : Array.Array Evergreen.V42.Message.Message
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId) (LastTypedAt Evergreen.V42.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V42.OneToOne.OneToOne (Evergreen.V42.Discord.Id.Id Evergreen.V42.Discord.Id.MessageId) (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId) Thread
    , linkedThreadIds : Evergreen.V42.OneToOne.OneToOne (Evergreen.V42.Discord.Id.Id Evergreen.V42.Discord.Id.ChannelId) (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId)
    }


type DmChannelId
    = DirectMessageChannelId (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId) (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId)
