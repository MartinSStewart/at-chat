module Evergreen.V149.DmChannel exposing (..)

import Array
import Evergreen.V149.Discord
import Evergreen.V149.Id
import Evergreen.V149.Message
import Evergreen.V149.NonemptySet
import Evergreen.V149.OneToOne
import Evergreen.V149.Thread
import Evergreen.V149.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V149.Message.MessageState Evergreen.V149.Id.ChannelMessageId (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId))
    , visibleMessages : Evergreen.V149.VisibleMessages.VisibleMessages Evergreen.V149.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId) (Evergreen.V149.Thread.LastTypedAt Evergreen.V149.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelMessageId) Evergreen.V149.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V149.Message.MessageState Evergreen.V149.Id.ChannelMessageId (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId))
    , visibleMessages : Evergreen.V149.VisibleMessages.VisibleMessages Evergreen.V149.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) (Evergreen.V149.Thread.LastTypedAt Evergreen.V149.Id.ChannelMessageId)
    , members : Evergreen.V149.NonemptySet.NonemptySet (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId)
    }


type DmChannelId
    = DmChannelId (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId) (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V149.Message.Message Evergreen.V149.Id.ChannelMessageId (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId) (Evergreen.V149.Thread.LastTypedAt Evergreen.V149.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelMessageId) Evergreen.V149.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V149.Message.Message Evergreen.V149.Id.ChannelMessageId (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId) (Evergreen.V149.Thread.LastTypedAt Evergreen.V149.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V149.OneToOne.OneToOne (Evergreen.V149.Discord.Id Evergreen.V149.Discord.MessageId) (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelMessageId)
    , members : Evergreen.V149.NonemptySet.NonemptySet (Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId)
    }
