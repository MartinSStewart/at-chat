module Evergreen.V117.DmChannel exposing (..)

import Array
import Evergreen.V117.Discord.Id
import Evergreen.V117.Id
import Evergreen.V117.Message
import Evergreen.V117.NonemptySet
import Evergreen.V117.OneToOne
import Evergreen.V117.Thread
import Evergreen.V117.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V117.Message.MessageState Evergreen.V117.Id.ChannelMessageId (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId))
    , visibleMessages : Evergreen.V117.VisibleMessages.VisibleMessages Evergreen.V117.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId) (Evergreen.V117.Thread.LastTypedAt Evergreen.V117.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelMessageId) Evergreen.V117.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V117.Message.MessageState Evergreen.V117.Id.ChannelMessageId (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId))
    , visibleMessages : Evergreen.V117.VisibleMessages.VisibleMessages Evergreen.V117.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId) (Evergreen.V117.Thread.LastTypedAt Evergreen.V117.Id.ChannelMessageId)
    , members : Evergreen.V117.NonemptySet.NonemptySet (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId)
    }


type DmChannelId
    = DmChannelId (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId) (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V117.Message.Message Evergreen.V117.Id.ChannelMessageId (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId) (Evergreen.V117.Thread.LastTypedAt Evergreen.V117.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelMessageId) Evergreen.V117.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V117.Message.Message Evergreen.V117.Id.ChannelMessageId (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId) (Evergreen.V117.Thread.LastTypedAt Evergreen.V117.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V117.OneToOne.OneToOne (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.MessageId) (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelMessageId)
    , members : Evergreen.V117.NonemptySet.NonemptySet (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId)
    }
