module Evergreen.V46.DmChannel exposing (..)

import Array
import Evergreen.V46.Discord.Id
import Evergreen.V46.Id
import Evergreen.V46.Message
import Evergreen.V46.OneToOne
import SeqDict
import Time


type alias LastTypedAt messageId =
    { time : Time.Posix
    , messageIndex : Maybe (Evergreen.V46.Id.Id messageId)
    }


type alias Thread =
    { messages : Array.Array (Evergreen.V46.Message.Message Evergreen.V46.Id.ThreadMessageId)
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) (LastTypedAt Evergreen.V46.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V46.OneToOne.OneToOne (Evergreen.V46.Discord.Id.Id Evergreen.V46.Discord.Id.MessageId) (Evergreen.V46.Id.Id Evergreen.V46.Id.ThreadMessageId)
    }


type alias DmChannel =
    { messages : Array.Array (Evergreen.V46.Message.Message Evergreen.V46.Id.ChannelMessageId)
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) (LastTypedAt Evergreen.V46.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V46.OneToOne.OneToOne (Evergreen.V46.Discord.Id.Id Evergreen.V46.Discord.Id.MessageId) (Evergreen.V46.Id.Id Evergreen.V46.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V46.Id.Id Evergreen.V46.Id.ChannelMessageId) Thread
    , linkedThreadIds : Evergreen.V46.OneToOne.OneToOne (Evergreen.V46.Discord.Id.Id Evergreen.V46.Discord.Id.ChannelId) (Evergreen.V46.Id.Id Evergreen.V46.Id.ChannelMessageId)
    }


type DmChannelId
    = DirectMessageChannelId (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId)
