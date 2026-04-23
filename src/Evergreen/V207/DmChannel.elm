module Evergreen.V207.DmChannel exposing (..)

import Array
import Evergreen.V207.Discord
import Evergreen.V207.Id
import Evergreen.V207.Message
import Evergreen.V207.NonemptyDict
import Evergreen.V207.OneToOne
import Evergreen.V207.Thread
import Evergreen.V207.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V207.Message.MessageState Evergreen.V207.Id.ChannelMessageId (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId))
    , visibleMessages : Evergreen.V207.VisibleMessages.VisibleMessages Evergreen.V207.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId) (Evergreen.V207.Thread.LastTypedAt Evergreen.V207.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId) Evergreen.V207.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V207.Message.MessageState Evergreen.V207.Id.ChannelMessageId (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId))
    , visibleMessages : Evergreen.V207.VisibleMessages.VisibleMessages Evergreen.V207.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) (Evergreen.V207.Thread.LastTypedAt Evergreen.V207.Id.ChannelMessageId)
    , members :
        Evergreen.V207.NonemptyDict.NonemptyDict
            (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId)
            { messagesSent : Int
            }
    }


type DmChannelId
    = DmChannelId (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId) (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V207.Message.Message Evergreen.V207.Id.ChannelMessageId (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.UserId) (Evergreen.V207.Thread.LastTypedAt Evergreen.V207.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId) Evergreen.V207.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V207.Message.Message Evergreen.V207.Id.ChannelMessageId (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId) (Evergreen.V207.Thread.LastTypedAt Evergreen.V207.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V207.OneToOne.OneToOne (Evergreen.V207.Discord.Id Evergreen.V207.Discord.MessageId) (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId)
    , members :
        Evergreen.V207.NonemptyDict.NonemptyDict
            (Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId)
            { messagesSent : Int
            }
    }
