module Evergreen.V116.DmChannel exposing (..)

import Array
import Evergreen.V116.Discord.Id
import Evergreen.V116.Id
import Evergreen.V116.Message
import Evergreen.V116.NonemptySet
import Evergreen.V116.OneToOne
import Evergreen.V116.Thread
import Evergreen.V116.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V116.Message.MessageState Evergreen.V116.Id.ChannelMessageId (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId))
    , visibleMessages : Evergreen.V116.VisibleMessages.VisibleMessages Evergreen.V116.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) (Evergreen.V116.Thread.LastTypedAt Evergreen.V116.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelMessageId) Evergreen.V116.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V116.Message.MessageState Evergreen.V116.Id.ChannelMessageId (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId))
    , visibleMessages : Evergreen.V116.VisibleMessages.VisibleMessages Evergreen.V116.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId) (Evergreen.V116.Thread.LastTypedAt Evergreen.V116.Id.ChannelMessageId)
    , members : Evergreen.V116.NonemptySet.NonemptySet (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId)
    }


type DmChannelId
    = DmChannelId (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V116.Message.Message Evergreen.V116.Id.ChannelMessageId (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) (Evergreen.V116.Thread.LastTypedAt Evergreen.V116.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelMessageId) Evergreen.V116.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V116.Message.Message Evergreen.V116.Id.ChannelMessageId (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId) (Evergreen.V116.Thread.LastTypedAt Evergreen.V116.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V116.OneToOne.OneToOne (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.MessageId) (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelMessageId)
    , members : Evergreen.V116.NonemptySet.NonemptySet (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId)
    }
