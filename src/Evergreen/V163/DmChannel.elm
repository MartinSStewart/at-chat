module Evergreen.V163.DmChannel exposing (..)

import Array
import Evergreen.V163.Discord
import Evergreen.V163.Id
import Evergreen.V163.Message
import Evergreen.V163.NonemptyDict
import Evergreen.V163.OneToOne
import Evergreen.V163.Thread
import Evergreen.V163.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V163.Message.MessageState Evergreen.V163.Id.ChannelMessageId (Evergreen.V163.Id.Id Evergreen.V163.Id.UserId))
    , visibleMessages : Evergreen.V163.VisibleMessages.VisibleMessages Evergreen.V163.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V163.Id.Id Evergreen.V163.Id.UserId) (Evergreen.V163.Thread.LastTypedAt Evergreen.V163.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V163.Id.Id Evergreen.V163.Id.ChannelMessageId) Evergreen.V163.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V163.Message.MessageState Evergreen.V163.Id.ChannelMessageId (Evergreen.V163.Discord.Id Evergreen.V163.Discord.UserId))
    , visibleMessages : Evergreen.V163.VisibleMessages.VisibleMessages Evergreen.V163.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V163.Discord.Id Evergreen.V163.Discord.UserId) (Evergreen.V163.Thread.LastTypedAt Evergreen.V163.Id.ChannelMessageId)
    , members :
        Evergreen.V163.NonemptyDict.NonemptyDict
            (Evergreen.V163.Discord.Id Evergreen.V163.Discord.UserId)
            { messagesSent : Int
            }
    }


type DmChannelId
    = DmChannelId (Evergreen.V163.Id.Id Evergreen.V163.Id.UserId) (Evergreen.V163.Id.Id Evergreen.V163.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V163.Message.Message Evergreen.V163.Id.ChannelMessageId (Evergreen.V163.Id.Id Evergreen.V163.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V163.Id.Id Evergreen.V163.Id.UserId) (Evergreen.V163.Thread.LastTypedAt Evergreen.V163.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V163.Id.Id Evergreen.V163.Id.ChannelMessageId) Evergreen.V163.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V163.Message.Message Evergreen.V163.Id.ChannelMessageId (Evergreen.V163.Discord.Id Evergreen.V163.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V163.Discord.Id Evergreen.V163.Discord.UserId) (Evergreen.V163.Thread.LastTypedAt Evergreen.V163.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V163.OneToOne.OneToOne (Evergreen.V163.Discord.Id Evergreen.V163.Discord.MessageId) (Evergreen.V163.Id.Id Evergreen.V163.Id.ChannelMessageId)
    , members :
        Evergreen.V163.NonemptyDict.NonemptyDict
            (Evergreen.V163.Discord.Id Evergreen.V163.Discord.UserId)
            { messagesSent : Int
            }
    }
