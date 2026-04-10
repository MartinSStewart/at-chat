module Evergreen.V192.DmChannel exposing (..)

import Array
import Evergreen.V192.Discord
import Evergreen.V192.Id
import Evergreen.V192.Message
import Evergreen.V192.NonemptyDict
import Evergreen.V192.OneToOne
import Evergreen.V192.Thread
import Evergreen.V192.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V192.Message.MessageState Evergreen.V192.Id.ChannelMessageId (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId))
    , visibleMessages : Evergreen.V192.VisibleMessages.VisibleMessages Evergreen.V192.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId) (Evergreen.V192.Thread.LastTypedAt Evergreen.V192.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId) Evergreen.V192.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V192.Message.MessageState Evergreen.V192.Id.ChannelMessageId (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId))
    , visibleMessages : Evergreen.V192.VisibleMessages.VisibleMessages Evergreen.V192.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) (Evergreen.V192.Thread.LastTypedAt Evergreen.V192.Id.ChannelMessageId)
    , members :
        Evergreen.V192.NonemptyDict.NonemptyDict
            (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId)
            { messagesSent : Int
            }
    }


type DmChannelId
    = DmChannelId (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId) (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V192.Message.Message Evergreen.V192.Id.ChannelMessageId (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId) (Evergreen.V192.Thread.LastTypedAt Evergreen.V192.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId) Evergreen.V192.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V192.Message.Message Evergreen.V192.Id.ChannelMessageId (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId) (Evergreen.V192.Thread.LastTypedAt Evergreen.V192.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V192.OneToOne.OneToOne (Evergreen.V192.Discord.Id Evergreen.V192.Discord.MessageId) (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId)
    , members :
        Evergreen.V192.NonemptyDict.NonemptyDict
            (Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId)
            { messagesSent : Int
            }
    }
