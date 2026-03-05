module Evergreen.V135.DmChannel exposing (..)

import Array
import Evergreen.V135.Discord.Id
import Evergreen.V135.Id
import Evergreen.V135.Message
import Evergreen.V135.NonemptySet
import Evergreen.V135.OneToOne
import Evergreen.V135.Thread
import Evergreen.V135.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V135.Message.MessageState Evergreen.V135.Id.ChannelMessageId (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId))
    , visibleMessages : Evergreen.V135.VisibleMessages.VisibleMessages Evergreen.V135.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId) (Evergreen.V135.Thread.LastTypedAt Evergreen.V135.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelMessageId) Evergreen.V135.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V135.Message.MessageState Evergreen.V135.Id.ChannelMessageId (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId))
    , visibleMessages : Evergreen.V135.VisibleMessages.VisibleMessages Evergreen.V135.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) (Evergreen.V135.Thread.LastTypedAt Evergreen.V135.Id.ChannelMessageId)
    , members : Evergreen.V135.NonemptySet.NonemptySet (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId)
    }


type DmChannelId
    = DmChannelId (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId) (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V135.Message.Message Evergreen.V135.Id.ChannelMessageId (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId) (Evergreen.V135.Thread.LastTypedAt Evergreen.V135.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelMessageId) Evergreen.V135.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V135.Message.Message Evergreen.V135.Id.ChannelMessageId (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId) (Evergreen.V135.Thread.LastTypedAt Evergreen.V135.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V135.OneToOne.OneToOne (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.MessageId) (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelMessageId)
    , members : Evergreen.V135.NonemptySet.NonemptySet (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId)
    }
