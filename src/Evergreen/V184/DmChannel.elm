module Evergreen.V184.DmChannel exposing (..)

import Array
import Evergreen.V184.Discord
import Evergreen.V184.Id
import Evergreen.V184.Message
import Evergreen.V184.NonemptyDict
import Evergreen.V184.OneToOne
import Evergreen.V184.Thread
import Evergreen.V184.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V184.Message.MessageState Evergreen.V184.Id.ChannelMessageId (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId))
    , visibleMessages : Evergreen.V184.VisibleMessages.VisibleMessages Evergreen.V184.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId) (Evergreen.V184.Thread.LastTypedAt Evergreen.V184.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId) Evergreen.V184.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V184.Message.MessageState Evergreen.V184.Id.ChannelMessageId (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId))
    , visibleMessages : Evergreen.V184.VisibleMessages.VisibleMessages Evergreen.V184.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) (Evergreen.V184.Thread.LastTypedAt Evergreen.V184.Id.ChannelMessageId)
    , members :
        Evergreen.V184.NonemptyDict.NonemptyDict
            (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId)
            { messagesSent : Int
            }
    }


type DmChannelId
    = DmChannelId (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId) (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V184.Message.Message Evergreen.V184.Id.ChannelMessageId (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId) (Evergreen.V184.Thread.LastTypedAt Evergreen.V184.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId) Evergreen.V184.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V184.Message.Message Evergreen.V184.Id.ChannelMessageId (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId) (Evergreen.V184.Thread.LastTypedAt Evergreen.V184.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V184.OneToOne.OneToOne (Evergreen.V184.Discord.Id Evergreen.V184.Discord.MessageId) (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId)
    , members :
        Evergreen.V184.NonemptyDict.NonemptyDict
            (Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId)
            { messagesSent : Int
            }
    }
