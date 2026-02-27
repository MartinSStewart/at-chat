module Evergreen.V122.DmChannel exposing (..)

import Array
import Evergreen.V122.Discord.Id
import Evergreen.V122.Id
import Evergreen.V122.Message
import Evergreen.V122.NonemptySet
import Evergreen.V122.OneToOne
import Evergreen.V122.Thread
import Evergreen.V122.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V122.Message.MessageState Evergreen.V122.Id.ChannelMessageId (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId))
    , visibleMessages : Evergreen.V122.VisibleMessages.VisibleMessages Evergreen.V122.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId) (Evergreen.V122.Thread.LastTypedAt Evergreen.V122.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelMessageId) Evergreen.V122.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V122.Message.MessageState Evergreen.V122.Id.ChannelMessageId (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId))
    , visibleMessages : Evergreen.V122.VisibleMessages.VisibleMessages Evergreen.V122.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId) (Evergreen.V122.Thread.LastTypedAt Evergreen.V122.Id.ChannelMessageId)
    , members : Evergreen.V122.NonemptySet.NonemptySet (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId)
    }


type DmChannelId
    = DmChannelId (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId) (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V122.Message.Message Evergreen.V122.Id.ChannelMessageId (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId) (Evergreen.V122.Thread.LastTypedAt Evergreen.V122.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelMessageId) Evergreen.V122.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V122.Message.Message Evergreen.V122.Id.ChannelMessageId (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId) (Evergreen.V122.Thread.LastTypedAt Evergreen.V122.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V122.OneToOne.OneToOne (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.MessageId) (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelMessageId)
    , members : Evergreen.V122.NonemptySet.NonemptySet (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId)
    }
