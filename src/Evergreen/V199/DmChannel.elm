module Evergreen.V199.DmChannel exposing (..)

import Array
import Evergreen.V199.Discord
import Evergreen.V199.Id
import Evergreen.V199.Message
import Evergreen.V199.NonemptyDict
import Evergreen.V199.OneToOne
import Evergreen.V199.Thread
import Evergreen.V199.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V199.Message.MessageState Evergreen.V199.Id.ChannelMessageId (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId))
    , visibleMessages : Evergreen.V199.VisibleMessages.VisibleMessages Evergreen.V199.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId) (Evergreen.V199.Thread.LastTypedAt Evergreen.V199.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId) Evergreen.V199.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V199.Message.MessageState Evergreen.V199.Id.ChannelMessageId (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId))
    , visibleMessages : Evergreen.V199.VisibleMessages.VisibleMessages Evergreen.V199.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) (Evergreen.V199.Thread.LastTypedAt Evergreen.V199.Id.ChannelMessageId)
    , members :
        Evergreen.V199.NonemptyDict.NonemptyDict
            (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId)
            { messagesSent : Int
            }
    }


type DmChannelId
    = DmChannelId (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId) (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V199.Message.Message Evergreen.V199.Id.ChannelMessageId (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.UserId) (Evergreen.V199.Thread.LastTypedAt Evergreen.V199.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId) Evergreen.V199.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V199.Message.Message Evergreen.V199.Id.ChannelMessageId (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId) (Evergreen.V199.Thread.LastTypedAt Evergreen.V199.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V199.OneToOne.OneToOne (Evergreen.V199.Discord.Id Evergreen.V199.Discord.MessageId) (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId)
    , members :
        Evergreen.V199.NonemptyDict.NonemptyDict
            (Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId)
            { messagesSent : Int
            }
    }
