module Evergreen.V144.DmChannel exposing (..)

import Array
import Evergreen.V144.Discord
import Evergreen.V144.Id
import Evergreen.V144.Message
import Evergreen.V144.NonemptySet
import Evergreen.V144.OneToOne
import Evergreen.V144.Thread
import Evergreen.V144.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V144.Message.MessageState Evergreen.V144.Id.ChannelMessageId (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId))
    , visibleMessages : Evergreen.V144.VisibleMessages.VisibleMessages Evergreen.V144.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId) (Evergreen.V144.Thread.LastTypedAt Evergreen.V144.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelMessageId) Evergreen.V144.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V144.Message.MessageState Evergreen.V144.Id.ChannelMessageId (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId))
    , visibleMessages : Evergreen.V144.VisibleMessages.VisibleMessages Evergreen.V144.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) (Evergreen.V144.Thread.LastTypedAt Evergreen.V144.Id.ChannelMessageId)
    , members : Evergreen.V144.NonemptySet.NonemptySet (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId)
    }


type DmChannelId
    = DmChannelId (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId) (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V144.Message.Message Evergreen.V144.Id.ChannelMessageId (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId) (Evergreen.V144.Thread.LastTypedAt Evergreen.V144.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelMessageId) Evergreen.V144.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V144.Message.Message Evergreen.V144.Id.ChannelMessageId (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId) (Evergreen.V144.Thread.LastTypedAt Evergreen.V144.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V144.OneToOne.OneToOne (Evergreen.V144.Discord.Id Evergreen.V144.Discord.MessageId) (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelMessageId)
    , members : Evergreen.V144.NonemptySet.NonemptySet (Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId)
    }
