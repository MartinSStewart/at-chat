module Evergreen.V183.DmChannel exposing (..)

import Array
import Evergreen.V183.Discord
import Evergreen.V183.Id
import Evergreen.V183.Message
import Evergreen.V183.NonemptyDict
import Evergreen.V183.OneToOne
import Evergreen.V183.Thread
import Evergreen.V183.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V183.Message.MessageState Evergreen.V183.Id.ChannelMessageId (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId))
    , visibleMessages : Evergreen.V183.VisibleMessages.VisibleMessages Evergreen.V183.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId) (Evergreen.V183.Thread.LastTypedAt Evergreen.V183.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId) Evergreen.V183.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V183.Message.MessageState Evergreen.V183.Id.ChannelMessageId (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId))
    , visibleMessages : Evergreen.V183.VisibleMessages.VisibleMessages Evergreen.V183.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) (Evergreen.V183.Thread.LastTypedAt Evergreen.V183.Id.ChannelMessageId)
    , members :
        Evergreen.V183.NonemptyDict.NonemptyDict
            (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId)
            { messagesSent : Int
            }
    }


type DmChannelId
    = DmChannelId (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId) (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V183.Message.Message Evergreen.V183.Id.ChannelMessageId (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId) (Evergreen.V183.Thread.LastTypedAt Evergreen.V183.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId) Evergreen.V183.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V183.Message.Message Evergreen.V183.Id.ChannelMessageId (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId) (Evergreen.V183.Thread.LastTypedAt Evergreen.V183.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V183.OneToOne.OneToOne (Evergreen.V183.Discord.Id Evergreen.V183.Discord.MessageId) (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId)
    , members :
        Evergreen.V183.NonemptyDict.NonemptyDict
            (Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId)
            { messagesSent : Int
            }
    }
