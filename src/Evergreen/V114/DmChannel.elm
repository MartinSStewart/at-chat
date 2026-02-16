module Evergreen.V114.DmChannel exposing (..)

import Array
import Evergreen.V114.Discord.Id
import Evergreen.V114.Id
import Evergreen.V114.Message
import Evergreen.V114.NonemptySet
import Evergreen.V114.OneToOne
import Evergreen.V114.Thread
import Evergreen.V114.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V114.Message.MessageState Evergreen.V114.Id.ChannelMessageId (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId))
    , visibleMessages : Evergreen.V114.VisibleMessages.VisibleMessages Evergreen.V114.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) (Evergreen.V114.Thread.LastTypedAt Evergreen.V114.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelMessageId) Evergreen.V114.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V114.Message.MessageState Evergreen.V114.Id.ChannelMessageId (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId))
    , visibleMessages : Evergreen.V114.VisibleMessages.VisibleMessages Evergreen.V114.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId) (Evergreen.V114.Thread.LastTypedAt Evergreen.V114.Id.ChannelMessageId)
    , members : Evergreen.V114.NonemptySet.NonemptySet (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId)
    }


type DmChannelId
    = DmChannelId (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V114.Message.Message Evergreen.V114.Id.ChannelMessageId (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) (Evergreen.V114.Thread.LastTypedAt Evergreen.V114.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelMessageId) Evergreen.V114.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V114.Message.Message Evergreen.V114.Id.ChannelMessageId (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId) (Evergreen.V114.Thread.LastTypedAt Evergreen.V114.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V114.OneToOne.OneToOne (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.MessageId) (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelMessageId)
    , members : Evergreen.V114.NonemptySet.NonemptySet (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId)
    }
