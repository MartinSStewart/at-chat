module Evergreen.V147.DmChannel exposing (..)

import Array
import Evergreen.V147.Discord
import Evergreen.V147.Id
import Evergreen.V147.Message
import Evergreen.V147.NonemptySet
import Evergreen.V147.OneToOne
import Evergreen.V147.Thread
import Evergreen.V147.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V147.Message.MessageState Evergreen.V147.Id.ChannelMessageId (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId))
    , visibleMessages : Evergreen.V147.VisibleMessages.VisibleMessages Evergreen.V147.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId) (Evergreen.V147.Thread.LastTypedAt Evergreen.V147.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelMessageId) Evergreen.V147.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V147.Message.MessageState Evergreen.V147.Id.ChannelMessageId (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId))
    , visibleMessages : Evergreen.V147.VisibleMessages.VisibleMessages Evergreen.V147.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) (Evergreen.V147.Thread.LastTypedAt Evergreen.V147.Id.ChannelMessageId)
    , members : Evergreen.V147.NonemptySet.NonemptySet (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId)
    }


type DmChannelId
    = DmChannelId (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId) (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V147.Message.Message Evergreen.V147.Id.ChannelMessageId (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId) (Evergreen.V147.Thread.LastTypedAt Evergreen.V147.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelMessageId) Evergreen.V147.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V147.Message.Message Evergreen.V147.Id.ChannelMessageId (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId) (Evergreen.V147.Thread.LastTypedAt Evergreen.V147.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V147.OneToOne.OneToOne (Evergreen.V147.Discord.Id Evergreen.V147.Discord.MessageId) (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelMessageId)
    , members : Evergreen.V147.NonemptySet.NonemptySet (Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId)
    }
