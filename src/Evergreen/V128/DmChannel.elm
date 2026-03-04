module Evergreen.V128.DmChannel exposing (..)

import Array
import Evergreen.V128.Discord.Id
import Evergreen.V128.Id
import Evergreen.V128.Message
import Evergreen.V128.NonemptySet
import Evergreen.V128.OneToOne
import Evergreen.V128.Thread
import Evergreen.V128.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V128.Message.MessageState Evergreen.V128.Id.ChannelMessageId (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId))
    , visibleMessages : Evergreen.V128.VisibleMessages.VisibleMessages Evergreen.V128.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId) (Evergreen.V128.Thread.LastTypedAt Evergreen.V128.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelMessageId) Evergreen.V128.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V128.Message.MessageState Evergreen.V128.Id.ChannelMessageId (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId))
    , visibleMessages : Evergreen.V128.VisibleMessages.VisibleMessages Evergreen.V128.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) (Evergreen.V128.Thread.LastTypedAt Evergreen.V128.Id.ChannelMessageId)
    , members : Evergreen.V128.NonemptySet.NonemptySet (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId)
    }


type DmChannelId
    = DmChannelId (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId) (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V128.Message.Message Evergreen.V128.Id.ChannelMessageId (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId) (Evergreen.V128.Thread.LastTypedAt Evergreen.V128.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelMessageId) Evergreen.V128.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V128.Message.Message Evergreen.V128.Id.ChannelMessageId (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId) (Evergreen.V128.Thread.LastTypedAt Evergreen.V128.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V128.OneToOne.OneToOne (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.MessageId) (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelMessageId)
    , members : Evergreen.V128.NonemptySet.NonemptySet (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId)
    }
