module Evergreen.V179.DmChannel exposing (..)

import Array
import Evergreen.V179.Discord
import Evergreen.V179.Id
import Evergreen.V179.Message
import Evergreen.V179.NonemptyDict
import Evergreen.V179.OneToOne
import Evergreen.V179.Thread
import Evergreen.V179.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V179.Message.MessageState Evergreen.V179.Id.ChannelMessageId (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId))
    , visibleMessages : Evergreen.V179.VisibleMessages.VisibleMessages Evergreen.V179.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId) (Evergreen.V179.Thread.LastTypedAt Evergreen.V179.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId) Evergreen.V179.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V179.Message.MessageState Evergreen.V179.Id.ChannelMessageId (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId))
    , visibleMessages : Evergreen.V179.VisibleMessages.VisibleMessages Evergreen.V179.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) (Evergreen.V179.Thread.LastTypedAt Evergreen.V179.Id.ChannelMessageId)
    , members :
        Evergreen.V179.NonemptyDict.NonemptyDict
            (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId)
            { messagesSent : Int
            }
    }


type DmChannelId
    = DmChannelId (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId) (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V179.Message.Message Evergreen.V179.Id.ChannelMessageId (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId) (Evergreen.V179.Thread.LastTypedAt Evergreen.V179.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId) Evergreen.V179.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V179.Message.Message Evergreen.V179.Id.ChannelMessageId (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId) (Evergreen.V179.Thread.LastTypedAt Evergreen.V179.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V179.OneToOne.OneToOne (Evergreen.V179.Discord.Id Evergreen.V179.Discord.MessageId) (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId)
    , members :
        Evergreen.V179.NonemptyDict.NonemptyDict
            (Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId)
            { messagesSent : Int
            }
    }
