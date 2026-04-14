module Evergreen.V196.DmChannel exposing (..)

import Array
import Evergreen.V196.Discord
import Evergreen.V196.Id
import Evergreen.V196.Message
import Evergreen.V196.NonemptyDict
import Evergreen.V196.OneToOne
import Evergreen.V196.Thread
import Evergreen.V196.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V196.Message.MessageState Evergreen.V196.Id.ChannelMessageId (Evergreen.V196.Id.Id Evergreen.V196.Id.UserId))
    , visibleMessages : Evergreen.V196.VisibleMessages.VisibleMessages Evergreen.V196.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V196.Id.Id Evergreen.V196.Id.UserId) (Evergreen.V196.Thread.LastTypedAt Evergreen.V196.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V196.Id.Id Evergreen.V196.Id.ChannelMessageId) Evergreen.V196.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V196.Message.MessageState Evergreen.V196.Id.ChannelMessageId (Evergreen.V196.Discord.Id Evergreen.V196.Discord.UserId))
    , visibleMessages : Evergreen.V196.VisibleMessages.VisibleMessages Evergreen.V196.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V196.Discord.Id Evergreen.V196.Discord.UserId) (Evergreen.V196.Thread.LastTypedAt Evergreen.V196.Id.ChannelMessageId)
    , members :
        Evergreen.V196.NonemptyDict.NonemptyDict
            (Evergreen.V196.Discord.Id Evergreen.V196.Discord.UserId)
            { messagesSent : Int
            }
    }


type DmChannelId
    = DmChannelId (Evergreen.V196.Id.Id Evergreen.V196.Id.UserId) (Evergreen.V196.Id.Id Evergreen.V196.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V196.Message.Message Evergreen.V196.Id.ChannelMessageId (Evergreen.V196.Id.Id Evergreen.V196.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V196.Id.Id Evergreen.V196.Id.UserId) (Evergreen.V196.Thread.LastTypedAt Evergreen.V196.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V196.Id.Id Evergreen.V196.Id.ChannelMessageId) Evergreen.V196.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V196.Message.Message Evergreen.V196.Id.ChannelMessageId (Evergreen.V196.Discord.Id Evergreen.V196.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V196.Discord.Id Evergreen.V196.Discord.UserId) (Evergreen.V196.Thread.LastTypedAt Evergreen.V196.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V196.OneToOne.OneToOne (Evergreen.V196.Discord.Id Evergreen.V196.Discord.MessageId) (Evergreen.V196.Id.Id Evergreen.V196.Id.ChannelMessageId)
    , members :
        Evergreen.V196.NonemptyDict.NonemptyDict
            (Evergreen.V196.Discord.Id Evergreen.V196.Discord.UserId)
            { messagesSent : Int
            }
    }
