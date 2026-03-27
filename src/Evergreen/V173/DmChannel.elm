module Evergreen.V173.DmChannel exposing (..)

import Array
import Evergreen.V173.Discord
import Evergreen.V173.Id
import Evergreen.V173.Message
import Evergreen.V173.NonemptyDict
import Evergreen.V173.OneToOne
import Evergreen.V173.Thread
import Evergreen.V173.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V173.Message.MessageState Evergreen.V173.Id.ChannelMessageId (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId))
    , visibleMessages : Evergreen.V173.VisibleMessages.VisibleMessages Evergreen.V173.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId) (Evergreen.V173.Thread.LastTypedAt Evergreen.V173.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId) Evergreen.V173.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V173.Message.MessageState Evergreen.V173.Id.ChannelMessageId (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId))
    , visibleMessages : Evergreen.V173.VisibleMessages.VisibleMessages Evergreen.V173.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) (Evergreen.V173.Thread.LastTypedAt Evergreen.V173.Id.ChannelMessageId)
    , members :
        Evergreen.V173.NonemptyDict.NonemptyDict
            (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId)
            { messagesSent : Int
            }
    }


type DmChannelId
    = DmChannelId (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId) (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V173.Message.Message Evergreen.V173.Id.ChannelMessageId (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId) (Evergreen.V173.Thread.LastTypedAt Evergreen.V173.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId) Evergreen.V173.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V173.Message.Message Evergreen.V173.Id.ChannelMessageId (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId) (Evergreen.V173.Thread.LastTypedAt Evergreen.V173.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V173.OneToOne.OneToOne (Evergreen.V173.Discord.Id Evergreen.V173.Discord.MessageId) (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId)
    , members :
        Evergreen.V173.NonemptyDict.NonemptyDict
            (Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId)
            { messagesSent : Int
            }
    }
