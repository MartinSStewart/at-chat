module Evergreen.V130.DmChannel exposing (..)

import Array
import Evergreen.V130.Discord.Id
import Evergreen.V130.Id
import Evergreen.V130.Message
import Evergreen.V130.NonemptySet
import Evergreen.V130.OneToOne
import Evergreen.V130.Thread
import Evergreen.V130.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V130.Message.MessageState Evergreen.V130.Id.ChannelMessageId (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId))
    , visibleMessages : Evergreen.V130.VisibleMessages.VisibleMessages Evergreen.V130.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId) (Evergreen.V130.Thread.LastTypedAt Evergreen.V130.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelMessageId) Evergreen.V130.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V130.Message.MessageState Evergreen.V130.Id.ChannelMessageId (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId))
    , visibleMessages : Evergreen.V130.VisibleMessages.VisibleMessages Evergreen.V130.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId) (Evergreen.V130.Thread.LastTypedAt Evergreen.V130.Id.ChannelMessageId)
    , members : Evergreen.V130.NonemptySet.NonemptySet (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId)
    }


type DmChannelId
    = DmChannelId (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId) (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V130.Message.Message Evergreen.V130.Id.ChannelMessageId (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId) (Evergreen.V130.Thread.LastTypedAt Evergreen.V130.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelMessageId) Evergreen.V130.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V130.Message.Message Evergreen.V130.Id.ChannelMessageId (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId) (Evergreen.V130.Thread.LastTypedAt Evergreen.V130.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V130.OneToOne.OneToOne (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.MessageId) (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelMessageId)
    , members : Evergreen.V130.NonemptySet.NonemptySet (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId)
    }
