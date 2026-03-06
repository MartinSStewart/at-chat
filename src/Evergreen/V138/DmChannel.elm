module Evergreen.V138.DmChannel exposing (..)

import Array
import Evergreen.V138.Discord.Id
import Evergreen.V138.Id
import Evergreen.V138.Message
import Evergreen.V138.NonemptySet
import Evergreen.V138.OneToOne
import Evergreen.V138.Thread
import Evergreen.V138.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V138.Message.MessageState Evergreen.V138.Id.ChannelMessageId (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId))
    , visibleMessages : Evergreen.V138.VisibleMessages.VisibleMessages Evergreen.V138.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId) (Evergreen.V138.Thread.LastTypedAt Evergreen.V138.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelMessageId) Evergreen.V138.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V138.Message.MessageState Evergreen.V138.Id.ChannelMessageId (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId))
    , visibleMessages : Evergreen.V138.VisibleMessages.VisibleMessages Evergreen.V138.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) (Evergreen.V138.Thread.LastTypedAt Evergreen.V138.Id.ChannelMessageId)
    , members : Evergreen.V138.NonemptySet.NonemptySet (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId)
    }


type DmChannelId
    = DmChannelId (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId) (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V138.Message.Message Evergreen.V138.Id.ChannelMessageId (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId) (Evergreen.V138.Thread.LastTypedAt Evergreen.V138.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelMessageId) Evergreen.V138.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V138.Message.Message Evergreen.V138.Id.ChannelMessageId (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId) (Evergreen.V138.Thread.LastTypedAt Evergreen.V138.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V138.OneToOne.OneToOne (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.MessageId) (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelMessageId)
    , members : Evergreen.V138.NonemptySet.NonemptySet (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId)
    }
