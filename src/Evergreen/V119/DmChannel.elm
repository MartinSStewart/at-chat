module Evergreen.V119.DmChannel exposing (..)

import Array
import Evergreen.V119.Discord.Id
import Evergreen.V119.Id
import Evergreen.V119.Message
import Evergreen.V119.NonemptySet
import Evergreen.V119.OneToOne
import Evergreen.V119.Thread
import Evergreen.V119.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V119.Message.MessageState Evergreen.V119.Id.ChannelMessageId (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId))
    , visibleMessages : Evergreen.V119.VisibleMessages.VisibleMessages Evergreen.V119.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId) (Evergreen.V119.Thread.LastTypedAt Evergreen.V119.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelMessageId) Evergreen.V119.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V119.Message.MessageState Evergreen.V119.Id.ChannelMessageId (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId))
    , visibleMessages : Evergreen.V119.VisibleMessages.VisibleMessages Evergreen.V119.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId) (Evergreen.V119.Thread.LastTypedAt Evergreen.V119.Id.ChannelMessageId)
    , members : Evergreen.V119.NonemptySet.NonemptySet (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId)
    }


type DmChannelId
    = DmChannelId (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId) (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V119.Message.Message Evergreen.V119.Id.ChannelMessageId (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId) (Evergreen.V119.Thread.LastTypedAt Evergreen.V119.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelMessageId) Evergreen.V119.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V119.Message.Message Evergreen.V119.Id.ChannelMessageId (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId) (Evergreen.V119.Thread.LastTypedAt Evergreen.V119.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V119.OneToOne.OneToOne (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.MessageId) (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelMessageId)
    , members : Evergreen.V119.NonemptySet.NonemptySet (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId)
    }
