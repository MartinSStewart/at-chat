module Evergreen.V175.DmChannel exposing (..)

import Array
import Evergreen.V175.Discord
import Evergreen.V175.Id
import Evergreen.V175.Message
import Evergreen.V175.NonemptyDict
import Evergreen.V175.OneToOne
import Evergreen.V175.Thread
import Evergreen.V175.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V175.Message.MessageState Evergreen.V175.Id.ChannelMessageId (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId))
    , visibleMessages : Evergreen.V175.VisibleMessages.VisibleMessages Evergreen.V175.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId) (Evergreen.V175.Thread.LastTypedAt Evergreen.V175.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId) Evergreen.V175.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V175.Message.MessageState Evergreen.V175.Id.ChannelMessageId (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId))
    , visibleMessages : Evergreen.V175.VisibleMessages.VisibleMessages Evergreen.V175.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) (Evergreen.V175.Thread.LastTypedAt Evergreen.V175.Id.ChannelMessageId)
    , members :
        Evergreen.V175.NonemptyDict.NonemptyDict
            (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId)
            { messagesSent : Int
            }
    }


type DmChannelId
    = DmChannelId (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId) (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V175.Message.Message Evergreen.V175.Id.ChannelMessageId (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId) (Evergreen.V175.Thread.LastTypedAt Evergreen.V175.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId) Evergreen.V175.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V175.Message.Message Evergreen.V175.Id.ChannelMessageId (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId) (Evergreen.V175.Thread.LastTypedAt Evergreen.V175.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V175.OneToOne.OneToOne (Evergreen.V175.Discord.Id Evergreen.V175.Discord.MessageId) (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId)
    , members :
        Evergreen.V175.NonemptyDict.NonemptyDict
            (Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId)
            { messagesSent : Int
            }
    }
