module Evergreen.V171.DmChannel exposing (..)

import Array
import Evergreen.V171.Discord
import Evergreen.V171.Id
import Evergreen.V171.Message
import Evergreen.V171.NonemptyDict
import Evergreen.V171.OneToOne
import Evergreen.V171.Thread
import Evergreen.V171.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V171.Message.MessageState Evergreen.V171.Id.ChannelMessageId (Evergreen.V171.Id.Id Evergreen.V171.Id.UserId))
    , visibleMessages : Evergreen.V171.VisibleMessages.VisibleMessages Evergreen.V171.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V171.Id.Id Evergreen.V171.Id.UserId) (Evergreen.V171.Thread.LastTypedAt Evergreen.V171.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V171.Id.Id Evergreen.V171.Id.ChannelMessageId) Evergreen.V171.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V171.Message.MessageState Evergreen.V171.Id.ChannelMessageId (Evergreen.V171.Discord.Id Evergreen.V171.Discord.UserId))
    , visibleMessages : Evergreen.V171.VisibleMessages.VisibleMessages Evergreen.V171.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V171.Discord.Id Evergreen.V171.Discord.UserId) (Evergreen.V171.Thread.LastTypedAt Evergreen.V171.Id.ChannelMessageId)
    , members :
        Evergreen.V171.NonemptyDict.NonemptyDict
            (Evergreen.V171.Discord.Id Evergreen.V171.Discord.UserId)
            { messagesSent : Int
            }
    }


type DmChannelId
    = DmChannelId (Evergreen.V171.Id.Id Evergreen.V171.Id.UserId) (Evergreen.V171.Id.Id Evergreen.V171.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V171.Message.Message Evergreen.V171.Id.ChannelMessageId (Evergreen.V171.Id.Id Evergreen.V171.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V171.Id.Id Evergreen.V171.Id.UserId) (Evergreen.V171.Thread.LastTypedAt Evergreen.V171.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V171.Id.Id Evergreen.V171.Id.ChannelMessageId) Evergreen.V171.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V171.Message.Message Evergreen.V171.Id.ChannelMessageId (Evergreen.V171.Discord.Id Evergreen.V171.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V171.Discord.Id Evergreen.V171.Discord.UserId) (Evergreen.V171.Thread.LastTypedAt Evergreen.V171.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V171.OneToOne.OneToOne (Evergreen.V171.Discord.Id Evergreen.V171.Discord.MessageId) (Evergreen.V171.Id.Id Evergreen.V171.Id.ChannelMessageId)
    , members :
        Evergreen.V171.NonemptyDict.NonemptyDict
            (Evergreen.V171.Discord.Id Evergreen.V171.Discord.UserId)
            { messagesSent : Int
            }
    }
