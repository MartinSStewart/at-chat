module Evergreen.V112.DmChannel exposing (..)

import Array
import Evergreen.V112.Discord.Id
import Evergreen.V112.Id
import Evergreen.V112.Message
import Evergreen.V112.NonemptySet
import Evergreen.V112.OneToOne
import Evergreen.V112.Thread
import Evergreen.V112.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V112.Message.MessageState Evergreen.V112.Id.ChannelMessageId (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId))
    , visibleMessages : Evergreen.V112.VisibleMessages.VisibleMessages Evergreen.V112.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) (Evergreen.V112.Thread.LastTypedAt Evergreen.V112.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelMessageId) Evergreen.V112.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V112.Message.MessageState Evergreen.V112.Id.ChannelMessageId (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId))
    , visibleMessages : Evergreen.V112.VisibleMessages.VisibleMessages Evergreen.V112.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId) (Evergreen.V112.Thread.LastTypedAt Evergreen.V112.Id.ChannelMessageId)
    , members : Evergreen.V112.NonemptySet.NonemptySet (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId)
    }


type DmChannelId
    = DmChannelId (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V112.Message.Message Evergreen.V112.Id.ChannelMessageId (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) (Evergreen.V112.Thread.LastTypedAt Evergreen.V112.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelMessageId) Evergreen.V112.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V112.Message.Message Evergreen.V112.Id.ChannelMessageId (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId) (Evergreen.V112.Thread.LastTypedAt Evergreen.V112.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V112.OneToOne.OneToOne (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.MessageId) (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelMessageId)
    , members : Evergreen.V112.NonemptySet.NonemptySet (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId)
    }
