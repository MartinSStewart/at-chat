module Evergreen.V157.DmChannel exposing (..)

import Array
import Evergreen.V157.Discord
import Evergreen.V157.Id
import Evergreen.V157.Message
import Evergreen.V157.NonemptyDict
import Evergreen.V157.OneToOne
import Evergreen.V157.Thread
import Evergreen.V157.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V157.Message.MessageState Evergreen.V157.Id.ChannelMessageId (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId))
    , visibleMessages : Evergreen.V157.VisibleMessages.VisibleMessages Evergreen.V157.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId) (Evergreen.V157.Thread.LastTypedAt Evergreen.V157.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId) Evergreen.V157.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V157.Message.MessageState Evergreen.V157.Id.ChannelMessageId (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId))
    , visibleMessages : Evergreen.V157.VisibleMessages.VisibleMessages Evergreen.V157.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) (Evergreen.V157.Thread.LastTypedAt Evergreen.V157.Id.ChannelMessageId)
    , members :
        Evergreen.V157.NonemptyDict.NonemptyDict
            (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId)
            { messagesSent : Int
            }
    }


type DmChannelId
    = DmChannelId (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId) (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V157.Message.Message Evergreen.V157.Id.ChannelMessageId (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId) (Evergreen.V157.Thread.LastTypedAt Evergreen.V157.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId) Evergreen.V157.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V157.Message.Message Evergreen.V157.Id.ChannelMessageId (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId) (Evergreen.V157.Thread.LastTypedAt Evergreen.V157.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V157.OneToOne.OneToOne (Evergreen.V157.Discord.Id Evergreen.V157.Discord.MessageId) (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId)
    , members :
        Evergreen.V157.NonemptyDict.NonemptyDict
            (Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId)
            { messagesSent : Int
            }
    }
