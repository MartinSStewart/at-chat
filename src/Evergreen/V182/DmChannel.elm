module Evergreen.V182.DmChannel exposing (..)

import Array
import Evergreen.V182.Discord
import Evergreen.V182.Id
import Evergreen.V182.Message
import Evergreen.V182.NonemptyDict
import Evergreen.V182.OneToOne
import Evergreen.V182.Thread
import Evergreen.V182.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V182.Message.MessageState Evergreen.V182.Id.ChannelMessageId (Evergreen.V182.Id.Id Evergreen.V182.Id.UserId))
    , visibleMessages : Evergreen.V182.VisibleMessages.VisibleMessages Evergreen.V182.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V182.Id.Id Evergreen.V182.Id.UserId) (Evergreen.V182.Thread.LastTypedAt Evergreen.V182.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V182.Id.Id Evergreen.V182.Id.ChannelMessageId) Evergreen.V182.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V182.Message.MessageState Evergreen.V182.Id.ChannelMessageId (Evergreen.V182.Discord.Id Evergreen.V182.Discord.UserId))
    , visibleMessages : Evergreen.V182.VisibleMessages.VisibleMessages Evergreen.V182.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V182.Discord.Id Evergreen.V182.Discord.UserId) (Evergreen.V182.Thread.LastTypedAt Evergreen.V182.Id.ChannelMessageId)
    , members :
        Evergreen.V182.NonemptyDict.NonemptyDict
            (Evergreen.V182.Discord.Id Evergreen.V182.Discord.UserId)
            { messagesSent : Int
            }
    }


type DmChannelId
    = DmChannelId (Evergreen.V182.Id.Id Evergreen.V182.Id.UserId) (Evergreen.V182.Id.Id Evergreen.V182.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V182.Message.Message Evergreen.V182.Id.ChannelMessageId (Evergreen.V182.Id.Id Evergreen.V182.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V182.Id.Id Evergreen.V182.Id.UserId) (Evergreen.V182.Thread.LastTypedAt Evergreen.V182.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V182.Id.Id Evergreen.V182.Id.ChannelMessageId) Evergreen.V182.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V182.Message.Message Evergreen.V182.Id.ChannelMessageId (Evergreen.V182.Discord.Id Evergreen.V182.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V182.Discord.Id Evergreen.V182.Discord.UserId) (Evergreen.V182.Thread.LastTypedAt Evergreen.V182.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V182.OneToOne.OneToOne (Evergreen.V182.Discord.Id Evergreen.V182.Discord.MessageId) (Evergreen.V182.Id.Id Evergreen.V182.Id.ChannelMessageId)
    , members :
        Evergreen.V182.NonemptyDict.NonemptyDict
            (Evergreen.V182.Discord.Id Evergreen.V182.Discord.UserId)
            { messagesSent : Int
            }
    }
