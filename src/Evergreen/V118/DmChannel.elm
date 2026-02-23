module Evergreen.V118.DmChannel exposing (..)

import Array
import Evergreen.V118.Discord.Id
import Evergreen.V118.Id
import Evergreen.V118.Message
import Evergreen.V118.NonemptySet
import Evergreen.V118.OneToOne
import Evergreen.V118.Thread
import Evergreen.V118.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V118.Message.MessageState Evergreen.V118.Id.ChannelMessageId (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId))
    , visibleMessages : Evergreen.V118.VisibleMessages.VisibleMessages Evergreen.V118.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId) (Evergreen.V118.Thread.LastTypedAt Evergreen.V118.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelMessageId) Evergreen.V118.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V118.Message.MessageState Evergreen.V118.Id.ChannelMessageId (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId))
    , visibleMessages : Evergreen.V118.VisibleMessages.VisibleMessages Evergreen.V118.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId) (Evergreen.V118.Thread.LastTypedAt Evergreen.V118.Id.ChannelMessageId)
    , members : Evergreen.V118.NonemptySet.NonemptySet (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId)
    }


type DmChannelId
    = DmChannelId (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId) (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V118.Message.Message Evergreen.V118.Id.ChannelMessageId (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId) (Evergreen.V118.Thread.LastTypedAt Evergreen.V118.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelMessageId) Evergreen.V118.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V118.Message.Message Evergreen.V118.Id.ChannelMessageId (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId) (Evergreen.V118.Thread.LastTypedAt Evergreen.V118.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V118.OneToOne.OneToOne (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.MessageId) (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelMessageId)
    , members : Evergreen.V118.NonemptySet.NonemptySet (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId)
    }
