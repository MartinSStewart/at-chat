module Evergreen.V176.DmChannel exposing (..)

import Array
import Evergreen.V176.Discord
import Evergreen.V176.Id
import Evergreen.V176.Message
import Evergreen.V176.NonemptyDict
import Evergreen.V176.OneToOne
import Evergreen.V176.Thread
import Evergreen.V176.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V176.Message.MessageState Evergreen.V176.Id.ChannelMessageId (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId))
    , visibleMessages : Evergreen.V176.VisibleMessages.VisibleMessages Evergreen.V176.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId) (Evergreen.V176.Thread.LastTypedAt Evergreen.V176.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId) Evergreen.V176.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V176.Message.MessageState Evergreen.V176.Id.ChannelMessageId (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId))
    , visibleMessages : Evergreen.V176.VisibleMessages.VisibleMessages Evergreen.V176.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) (Evergreen.V176.Thread.LastTypedAt Evergreen.V176.Id.ChannelMessageId)
    , members :
        Evergreen.V176.NonemptyDict.NonemptyDict
            (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId)
            { messagesSent : Int
            }
    }


type DmChannelId
    = DmChannelId (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId) (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V176.Message.Message Evergreen.V176.Id.ChannelMessageId (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId) (Evergreen.V176.Thread.LastTypedAt Evergreen.V176.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId) Evergreen.V176.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V176.Message.Message Evergreen.V176.Id.ChannelMessageId (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId) (Evergreen.V176.Thread.LastTypedAt Evergreen.V176.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V176.OneToOne.OneToOne (Evergreen.V176.Discord.Id Evergreen.V176.Discord.MessageId) (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId)
    , members :
        Evergreen.V176.NonemptyDict.NonemptyDict
            (Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId)
            { messagesSent : Int
            }
    }
