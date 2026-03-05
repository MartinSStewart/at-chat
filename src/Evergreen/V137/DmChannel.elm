module Evergreen.V137.DmChannel exposing (..)

import Array
import Evergreen.V137.Discord.Id
import Evergreen.V137.Id
import Evergreen.V137.Message
import Evergreen.V137.NonemptySet
import Evergreen.V137.OneToOne
import Evergreen.V137.Thread
import Evergreen.V137.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V137.Message.MessageState Evergreen.V137.Id.ChannelMessageId (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId))
    , visibleMessages : Evergreen.V137.VisibleMessages.VisibleMessages Evergreen.V137.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId) (Evergreen.V137.Thread.LastTypedAt Evergreen.V137.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelMessageId) Evergreen.V137.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V137.Message.MessageState Evergreen.V137.Id.ChannelMessageId (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId))
    , visibleMessages : Evergreen.V137.VisibleMessages.VisibleMessages Evergreen.V137.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) (Evergreen.V137.Thread.LastTypedAt Evergreen.V137.Id.ChannelMessageId)
    , members : Evergreen.V137.NonemptySet.NonemptySet (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId)
    }


type DmChannelId
    = DmChannelId (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId) (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V137.Message.Message Evergreen.V137.Id.ChannelMessageId (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId) (Evergreen.V137.Thread.LastTypedAt Evergreen.V137.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelMessageId) Evergreen.V137.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V137.Message.Message Evergreen.V137.Id.ChannelMessageId (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId) (Evergreen.V137.Thread.LastTypedAt Evergreen.V137.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V137.OneToOne.OneToOne (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.MessageId) (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelMessageId)
    , members : Evergreen.V137.NonemptySet.NonemptySet (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId)
    }
