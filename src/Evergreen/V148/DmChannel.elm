module Evergreen.V148.DmChannel exposing (..)

import Array
import Evergreen.V148.Discord
import Evergreen.V148.Id
import Evergreen.V148.Message
import Evergreen.V148.NonemptySet
import Evergreen.V148.OneToOne
import Evergreen.V148.Thread
import Evergreen.V148.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V148.Message.MessageState Evergreen.V148.Id.ChannelMessageId (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId))
    , visibleMessages : Evergreen.V148.VisibleMessages.VisibleMessages Evergreen.V148.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId) (Evergreen.V148.Thread.LastTypedAt Evergreen.V148.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelMessageId) Evergreen.V148.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V148.Message.MessageState Evergreen.V148.Id.ChannelMessageId (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId))
    , visibleMessages : Evergreen.V148.VisibleMessages.VisibleMessages Evergreen.V148.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) (Evergreen.V148.Thread.LastTypedAt Evergreen.V148.Id.ChannelMessageId)
    , members : Evergreen.V148.NonemptySet.NonemptySet (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId)
    }


type DmChannelId
    = DmChannelId (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId) (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V148.Message.Message Evergreen.V148.Id.ChannelMessageId (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId) (Evergreen.V148.Thread.LastTypedAt Evergreen.V148.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelMessageId) Evergreen.V148.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V148.Message.Message Evergreen.V148.Id.ChannelMessageId (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId) (Evergreen.V148.Thread.LastTypedAt Evergreen.V148.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V148.OneToOne.OneToOne (Evergreen.V148.Discord.Id Evergreen.V148.Discord.MessageId) (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelMessageId)
    , members : Evergreen.V148.NonemptySet.NonemptySet (Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId)
    }
