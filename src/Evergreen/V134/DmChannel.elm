module Evergreen.V134.DmChannel exposing (..)

import Array
import Evergreen.V134.Discord.Id
import Evergreen.V134.Id
import Evergreen.V134.Message
import Evergreen.V134.NonemptySet
import Evergreen.V134.OneToOne
import Evergreen.V134.Thread
import Evergreen.V134.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V134.Message.MessageState Evergreen.V134.Id.ChannelMessageId (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId))
    , visibleMessages : Evergreen.V134.VisibleMessages.VisibleMessages Evergreen.V134.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) (Evergreen.V134.Thread.LastTypedAt Evergreen.V134.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelMessageId) Evergreen.V134.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V134.Message.MessageState Evergreen.V134.Id.ChannelMessageId (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId))
    , visibleMessages : Evergreen.V134.VisibleMessages.VisibleMessages Evergreen.V134.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) (Evergreen.V134.Thread.LastTypedAt Evergreen.V134.Id.ChannelMessageId)
    , members : Evergreen.V134.NonemptySet.NonemptySet (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId)
    }


type DmChannelId
    = DmChannelId (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V134.Message.Message Evergreen.V134.Id.ChannelMessageId (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) (Evergreen.V134.Thread.LastTypedAt Evergreen.V134.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelMessageId) Evergreen.V134.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V134.Message.Message Evergreen.V134.Id.ChannelMessageId (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId) (Evergreen.V134.Thread.LastTypedAt Evergreen.V134.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V134.OneToOne.OneToOne (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.MessageId) (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelMessageId)
    , members : Evergreen.V134.NonemptySet.NonemptySet (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId)
    }
