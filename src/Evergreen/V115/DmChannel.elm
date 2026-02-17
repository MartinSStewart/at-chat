module Evergreen.V115.DmChannel exposing (..)

import Array
import Evergreen.V115.Discord.Id
import Evergreen.V115.Id
import Evergreen.V115.Message
import Evergreen.V115.NonemptySet
import Evergreen.V115.OneToOne
import Evergreen.V115.Thread
import Evergreen.V115.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V115.Message.MessageState Evergreen.V115.Id.ChannelMessageId (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId))
    , visibleMessages : Evergreen.V115.VisibleMessages.VisibleMessages Evergreen.V115.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) (Evergreen.V115.Thread.LastTypedAt Evergreen.V115.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelMessageId) Evergreen.V115.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V115.Message.MessageState Evergreen.V115.Id.ChannelMessageId (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId))
    , visibleMessages : Evergreen.V115.VisibleMessages.VisibleMessages Evergreen.V115.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId) (Evergreen.V115.Thread.LastTypedAt Evergreen.V115.Id.ChannelMessageId)
    , members : Evergreen.V115.NonemptySet.NonemptySet (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId)
    }


type DmChannelId
    = DmChannelId (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V115.Message.Message Evergreen.V115.Id.ChannelMessageId (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) (Evergreen.V115.Thread.LastTypedAt Evergreen.V115.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelMessageId) Evergreen.V115.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V115.Message.Message Evergreen.V115.Id.ChannelMessageId (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId) (Evergreen.V115.Thread.LastTypedAt Evergreen.V115.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V115.OneToOne.OneToOne (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.MessageId) (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelMessageId)
    , members : Evergreen.V115.NonemptySet.NonemptySet (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId)
    }
