module Evergreen.V211.DmChannel exposing (..)

import Array
import Evergreen.V211.Discord
import Evergreen.V211.Id
import Evergreen.V211.Message
import Evergreen.V211.NonemptyDict
import Evergreen.V211.OneToOne
import Evergreen.V211.Thread
import Evergreen.V211.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V211.Message.MessageState Evergreen.V211.Id.ChannelMessageId (Evergreen.V211.Id.Id Evergreen.V211.Id.UserId))
    , visibleMessages : Evergreen.V211.VisibleMessages.VisibleMessages Evergreen.V211.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V211.Id.Id Evergreen.V211.Id.UserId) (Evergreen.V211.Thread.LastTypedAt Evergreen.V211.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V211.Id.Id Evergreen.V211.Id.ChannelMessageId) Evergreen.V211.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V211.Message.MessageState Evergreen.V211.Id.ChannelMessageId (Evergreen.V211.Discord.Id Evergreen.V211.Discord.UserId))
    , visibleMessages : Evergreen.V211.VisibleMessages.VisibleMessages Evergreen.V211.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V211.Discord.Id Evergreen.V211.Discord.UserId) (Evergreen.V211.Thread.LastTypedAt Evergreen.V211.Id.ChannelMessageId)
    , members :
        Evergreen.V211.NonemptyDict.NonemptyDict
            (Evergreen.V211.Discord.Id Evergreen.V211.Discord.UserId)
            { messagesSent : Int
            }
    }


type DmChannelId
    = DmChannelId (Evergreen.V211.Id.Id Evergreen.V211.Id.UserId) (Evergreen.V211.Id.Id Evergreen.V211.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V211.Message.Message Evergreen.V211.Id.ChannelMessageId (Evergreen.V211.Id.Id Evergreen.V211.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V211.Id.Id Evergreen.V211.Id.UserId) (Evergreen.V211.Thread.LastTypedAt Evergreen.V211.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V211.Id.Id Evergreen.V211.Id.ChannelMessageId) Evergreen.V211.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V211.Message.Message Evergreen.V211.Id.ChannelMessageId (Evergreen.V211.Discord.Id Evergreen.V211.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V211.Discord.Id Evergreen.V211.Discord.UserId) (Evergreen.V211.Thread.LastTypedAt Evergreen.V211.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V211.OneToOne.OneToOne (Evergreen.V211.Discord.Id Evergreen.V211.Discord.MessageId) (Evergreen.V211.Id.Id Evergreen.V211.Id.ChannelMessageId)
    , members :
        Evergreen.V211.NonemptyDict.NonemptyDict
            (Evergreen.V211.Discord.Id Evergreen.V211.Discord.UserId)
            { messagesSent : Int
            }
    }
