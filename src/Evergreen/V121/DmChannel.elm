module Evergreen.V121.DmChannel exposing (..)

import Array
import Evergreen.V121.Discord.Id
import Evergreen.V121.Id
import Evergreen.V121.Message
import Evergreen.V121.NonemptySet
import Evergreen.V121.OneToOne
import Evergreen.V121.Thread
import Evergreen.V121.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V121.Message.MessageState Evergreen.V121.Id.ChannelMessageId (Evergreen.V121.Id.Id Evergreen.V121.Id.UserId))
    , visibleMessages : Evergreen.V121.VisibleMessages.VisibleMessages Evergreen.V121.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V121.Id.Id Evergreen.V121.Id.UserId) (Evergreen.V121.Thread.LastTypedAt Evergreen.V121.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V121.Id.Id Evergreen.V121.Id.ChannelMessageId) Evergreen.V121.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V121.Message.MessageState Evergreen.V121.Id.ChannelMessageId (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.UserId))
    , visibleMessages : Evergreen.V121.VisibleMessages.VisibleMessages Evergreen.V121.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.UserId) (Evergreen.V121.Thread.LastTypedAt Evergreen.V121.Id.ChannelMessageId)
    , members : Evergreen.V121.NonemptySet.NonemptySet (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.UserId)
    }


type DmChannelId
    = DmChannelId (Evergreen.V121.Id.Id Evergreen.V121.Id.UserId) (Evergreen.V121.Id.Id Evergreen.V121.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V121.Message.Message Evergreen.V121.Id.ChannelMessageId (Evergreen.V121.Id.Id Evergreen.V121.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V121.Id.Id Evergreen.V121.Id.UserId) (Evergreen.V121.Thread.LastTypedAt Evergreen.V121.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V121.Id.Id Evergreen.V121.Id.ChannelMessageId) Evergreen.V121.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V121.Message.Message Evergreen.V121.Id.ChannelMessageId (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.UserId) (Evergreen.V121.Thread.LastTypedAt Evergreen.V121.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V121.OneToOne.OneToOne (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.MessageId) (Evergreen.V121.Id.Id Evergreen.V121.Id.ChannelMessageId)
    , members : Evergreen.V121.NonemptySet.NonemptySet (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.UserId)
    }
