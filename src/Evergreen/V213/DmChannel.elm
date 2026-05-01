module Evergreen.V213.DmChannel exposing (..)

import Array
import Evergreen.V213.Discord
import Evergreen.V213.Id
import Evergreen.V213.Message
import Evergreen.V213.NonemptyDict
import Evergreen.V213.OneToOne
import Evergreen.V213.Thread
import Evergreen.V213.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V213.Message.MessageState Evergreen.V213.Id.ChannelMessageId (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId))
    , visibleMessages : Evergreen.V213.VisibleMessages.VisibleMessages Evergreen.V213.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId) (Evergreen.V213.Thread.LastTypedAt Evergreen.V213.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId) Evergreen.V213.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V213.Message.MessageState Evergreen.V213.Id.ChannelMessageId (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId))
    , visibleMessages : Evergreen.V213.VisibleMessages.VisibleMessages Evergreen.V213.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId) (Evergreen.V213.Thread.LastTypedAt Evergreen.V213.Id.ChannelMessageId)
    , members :
        Evergreen.V213.NonemptyDict.NonemptyDict
            (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId)
            { messagesSent : Int
            }
    }


type DmChannelId
    = DmChannelId (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId) (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V213.Message.Message Evergreen.V213.Id.ChannelMessageId (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.UserId) (Evergreen.V213.Thread.LastTypedAt Evergreen.V213.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId) Evergreen.V213.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V213.Message.Message Evergreen.V213.Id.ChannelMessageId (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId) (Evergreen.V213.Thread.LastTypedAt Evergreen.V213.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V213.OneToOne.OneToOne (Evergreen.V213.Discord.Id Evergreen.V213.Discord.MessageId) (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId)
    , members :
        Evergreen.V213.NonemptyDict.NonemptyDict
            (Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId)
            { messagesSent : Int
            }
    }
