module Evergreen.V146.DmChannel exposing (..)

import Array
import Evergreen.V146.Discord
import Evergreen.V146.Id
import Evergreen.V146.Message
import Evergreen.V146.NonemptySet
import Evergreen.V146.OneToOne
import Evergreen.V146.Thread
import Evergreen.V146.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V146.Message.MessageState Evergreen.V146.Id.ChannelMessageId (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId))
    , visibleMessages : Evergreen.V146.VisibleMessages.VisibleMessages Evergreen.V146.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId) (Evergreen.V146.Thread.LastTypedAt Evergreen.V146.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelMessageId) Evergreen.V146.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V146.Message.MessageState Evergreen.V146.Id.ChannelMessageId (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId))
    , visibleMessages : Evergreen.V146.VisibleMessages.VisibleMessages Evergreen.V146.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) (Evergreen.V146.Thread.LastTypedAt Evergreen.V146.Id.ChannelMessageId)
    , members : Evergreen.V146.NonemptySet.NonemptySet (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId)
    }


type DmChannelId
    = DmChannelId (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId) (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V146.Message.Message Evergreen.V146.Id.ChannelMessageId (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId) (Evergreen.V146.Thread.LastTypedAt Evergreen.V146.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelMessageId) Evergreen.V146.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V146.Message.Message Evergreen.V146.Id.ChannelMessageId (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId) (Evergreen.V146.Thread.LastTypedAt Evergreen.V146.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V146.OneToOne.OneToOne (Evergreen.V146.Discord.Id Evergreen.V146.Discord.MessageId) (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelMessageId)
    , members : Evergreen.V146.NonemptySet.NonemptySet (Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId)
    }
