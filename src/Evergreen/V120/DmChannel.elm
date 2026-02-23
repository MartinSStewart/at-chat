module Evergreen.V120.DmChannel exposing (..)

import Array
import Evergreen.V120.Discord.Id
import Evergreen.V120.Id
import Evergreen.V120.Message
import Evergreen.V120.NonemptySet
import Evergreen.V120.OneToOne
import Evergreen.V120.Thread
import Evergreen.V120.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V120.Message.MessageState Evergreen.V120.Id.ChannelMessageId (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId))
    , visibleMessages : Evergreen.V120.VisibleMessages.VisibleMessages Evergreen.V120.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId) (Evergreen.V120.Thread.LastTypedAt Evergreen.V120.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelMessageId) Evergreen.V120.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V120.Message.MessageState Evergreen.V120.Id.ChannelMessageId (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId))
    , visibleMessages : Evergreen.V120.VisibleMessages.VisibleMessages Evergreen.V120.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId) (Evergreen.V120.Thread.LastTypedAt Evergreen.V120.Id.ChannelMessageId)
    , members : Evergreen.V120.NonemptySet.NonemptySet (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId)
    }


type DmChannelId
    = DmChannelId (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId) (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V120.Message.Message Evergreen.V120.Id.ChannelMessageId (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId) (Evergreen.V120.Thread.LastTypedAt Evergreen.V120.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelMessageId) Evergreen.V120.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V120.Message.Message Evergreen.V120.Id.ChannelMessageId (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId) (Evergreen.V120.Thread.LastTypedAt Evergreen.V120.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V120.OneToOne.OneToOne (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.MessageId) (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelMessageId)
    , members : Evergreen.V120.NonemptySet.NonemptySet (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId)
    }
