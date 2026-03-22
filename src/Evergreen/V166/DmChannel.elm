module Evergreen.V166.DmChannel exposing (..)

import Array
import Evergreen.V166.Discord
import Evergreen.V166.Id
import Evergreen.V166.Message
import Evergreen.V166.NonemptyDict
import Evergreen.V166.OneToOne
import Evergreen.V166.Thread
import Evergreen.V166.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V166.Message.MessageState Evergreen.V166.Id.ChannelMessageId (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId))
    , visibleMessages : Evergreen.V166.VisibleMessages.VisibleMessages Evergreen.V166.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId) (Evergreen.V166.Thread.LastTypedAt Evergreen.V166.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId) Evergreen.V166.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V166.Message.MessageState Evergreen.V166.Id.ChannelMessageId (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId))
    , visibleMessages : Evergreen.V166.VisibleMessages.VisibleMessages Evergreen.V166.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) (Evergreen.V166.Thread.LastTypedAt Evergreen.V166.Id.ChannelMessageId)
    , members :
        Evergreen.V166.NonemptyDict.NonemptyDict
            (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId)
            { messagesSent : Int
            }
    }


type DmChannelId
    = DmChannelId (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId) (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V166.Message.Message Evergreen.V166.Id.ChannelMessageId (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId) (Evergreen.V166.Thread.LastTypedAt Evergreen.V166.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId) Evergreen.V166.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V166.Message.Message Evergreen.V166.Id.ChannelMessageId (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId) (Evergreen.V166.Thread.LastTypedAt Evergreen.V166.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V166.OneToOne.OneToOne (Evergreen.V166.Discord.Id Evergreen.V166.Discord.MessageId) (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId)
    , members :
        Evergreen.V166.NonemptyDict.NonemptyDict
            (Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId)
            { messagesSent : Int
            }
    }
