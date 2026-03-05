module Evergreen.V136.DmChannel exposing (..)

import Array
import Evergreen.V136.Discord.Id
import Evergreen.V136.Id
import Evergreen.V136.Message
import Evergreen.V136.NonemptySet
import Evergreen.V136.OneToOne
import Evergreen.V136.Thread
import Evergreen.V136.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V136.Message.MessageState Evergreen.V136.Id.ChannelMessageId (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId))
    , visibleMessages : Evergreen.V136.VisibleMessages.VisibleMessages Evergreen.V136.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId) (Evergreen.V136.Thread.LastTypedAt Evergreen.V136.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelMessageId) Evergreen.V136.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V136.Message.MessageState Evergreen.V136.Id.ChannelMessageId (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId))
    , visibleMessages : Evergreen.V136.VisibleMessages.VisibleMessages Evergreen.V136.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) (Evergreen.V136.Thread.LastTypedAt Evergreen.V136.Id.ChannelMessageId)
    , members : Evergreen.V136.NonemptySet.NonemptySet (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId)
    }


type DmChannelId
    = DmChannelId (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId) (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V136.Message.Message Evergreen.V136.Id.ChannelMessageId (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId) (Evergreen.V136.Thread.LastTypedAt Evergreen.V136.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelMessageId) Evergreen.V136.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V136.Message.Message Evergreen.V136.Id.ChannelMessageId (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId) (Evergreen.V136.Thread.LastTypedAt Evergreen.V136.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V136.OneToOne.OneToOne (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.MessageId) (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelMessageId)
    , members : Evergreen.V136.NonemptySet.NonemptySet (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId)
    }
