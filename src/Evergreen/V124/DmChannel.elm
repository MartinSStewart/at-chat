module Evergreen.V124.DmChannel exposing (..)

import Array
import Evergreen.V124.Discord.Id
import Evergreen.V124.Id
import Evergreen.V124.Message
import Evergreen.V124.NonemptySet
import Evergreen.V124.OneToOne
import Evergreen.V124.Thread
import Evergreen.V124.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V124.Message.MessageState Evergreen.V124.Id.ChannelMessageId (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId))
    , visibleMessages : Evergreen.V124.VisibleMessages.VisibleMessages Evergreen.V124.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) (Evergreen.V124.Thread.LastTypedAt Evergreen.V124.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelMessageId) Evergreen.V124.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V124.Message.MessageState Evergreen.V124.Id.ChannelMessageId (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId))
    , visibleMessages : Evergreen.V124.VisibleMessages.VisibleMessages Evergreen.V124.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId) (Evergreen.V124.Thread.LastTypedAt Evergreen.V124.Id.ChannelMessageId)
    , members : Evergreen.V124.NonemptySet.NonemptySet (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId)
    }


type DmChannelId
    = DmChannelId (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V124.Message.Message Evergreen.V124.Id.ChannelMessageId (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) (Evergreen.V124.Thread.LastTypedAt Evergreen.V124.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelMessageId) Evergreen.V124.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V124.Message.Message Evergreen.V124.Id.ChannelMessageId (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId) (Evergreen.V124.Thread.LastTypedAt Evergreen.V124.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V124.OneToOne.OneToOne (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.MessageId) (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelMessageId)
    , members : Evergreen.V124.NonemptySet.NonemptySet (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId)
    }
