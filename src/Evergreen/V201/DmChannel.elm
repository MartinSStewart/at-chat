module Evergreen.V201.DmChannel exposing (..)

import Array
import Evergreen.V201.Discord
import Evergreen.V201.Id
import Evergreen.V201.Message
import Evergreen.V201.NonemptyDict
import Evergreen.V201.OneToOne
import Evergreen.V201.Thread
import Evergreen.V201.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V201.Message.MessageState Evergreen.V201.Id.ChannelMessageId (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId))
    , visibleMessages : Evergreen.V201.VisibleMessages.VisibleMessages Evergreen.V201.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId) (Evergreen.V201.Thread.LastTypedAt Evergreen.V201.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId) Evergreen.V201.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V201.Message.MessageState Evergreen.V201.Id.ChannelMessageId (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId))
    , visibleMessages : Evergreen.V201.VisibleMessages.VisibleMessages Evergreen.V201.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) (Evergreen.V201.Thread.LastTypedAt Evergreen.V201.Id.ChannelMessageId)
    , members :
        Evergreen.V201.NonemptyDict.NonemptyDict
            (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId)
            { messagesSent : Int
            }
    }


type DmChannelId
    = DmChannelId (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId) (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V201.Message.Message Evergreen.V201.Id.ChannelMessageId (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId) (Evergreen.V201.Thread.LastTypedAt Evergreen.V201.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId) Evergreen.V201.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V201.Message.Message Evergreen.V201.Id.ChannelMessageId (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId) (Evergreen.V201.Thread.LastTypedAt Evergreen.V201.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V201.OneToOne.OneToOne (Evergreen.V201.Discord.Id Evergreen.V201.Discord.MessageId) (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId)
    , members :
        Evergreen.V201.NonemptyDict.NonemptyDict
            (Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId)
            { messagesSent : Int
            }
    }
