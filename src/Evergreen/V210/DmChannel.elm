module Evergreen.V210.DmChannel exposing (..)

import Array
import Evergreen.V210.Discord
import Evergreen.V210.Id
import Evergreen.V210.Message
import Evergreen.V210.NonemptyDict
import Evergreen.V210.OneToOne
import Evergreen.V210.Thread
import Evergreen.V210.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V210.Message.MessageState Evergreen.V210.Id.ChannelMessageId (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId))
    , visibleMessages : Evergreen.V210.VisibleMessages.VisibleMessages Evergreen.V210.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) (Evergreen.V210.Thread.LastTypedAt Evergreen.V210.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId) Evergreen.V210.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V210.Message.MessageState Evergreen.V210.Id.ChannelMessageId (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId))
    , visibleMessages : Evergreen.V210.VisibleMessages.VisibleMessages Evergreen.V210.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) (Evergreen.V210.Thread.LastTypedAt Evergreen.V210.Id.ChannelMessageId)
    , members :
        Evergreen.V210.NonemptyDict.NonemptyDict
            (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId)
            { messagesSent : Int
            }
    }


type DmChannelId
    = DmChannelId (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V210.Message.Message Evergreen.V210.Id.ChannelMessageId (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.UserId) (Evergreen.V210.Thread.LastTypedAt Evergreen.V210.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId) Evergreen.V210.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V210.Message.Message Evergreen.V210.Id.ChannelMessageId (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId) (Evergreen.V210.Thread.LastTypedAt Evergreen.V210.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V210.OneToOne.OneToOne (Evergreen.V210.Discord.Id Evergreen.V210.Discord.MessageId) (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId)
    , members :
        Evergreen.V210.NonemptyDict.NonemptyDict
            (Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId)
            { messagesSent : Int
            }
    }
