module Evergreen.V206.DmChannel exposing (..)

import Array
import Evergreen.V206.Discord
import Evergreen.V206.Id
import Evergreen.V206.Message
import Evergreen.V206.NonemptyDict
import Evergreen.V206.OneToOne
import Evergreen.V206.Thread
import Evergreen.V206.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V206.Message.MessageState Evergreen.V206.Id.ChannelMessageId (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId))
    , visibleMessages : Evergreen.V206.VisibleMessages.VisibleMessages Evergreen.V206.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId) (Evergreen.V206.Thread.LastTypedAt Evergreen.V206.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelMessageId) Evergreen.V206.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V206.Message.MessageState Evergreen.V206.Id.ChannelMessageId (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId))
    , visibleMessages : Evergreen.V206.VisibleMessages.VisibleMessages Evergreen.V206.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) (Evergreen.V206.Thread.LastTypedAt Evergreen.V206.Id.ChannelMessageId)
    , members :
        Evergreen.V206.NonemptyDict.NonemptyDict
            (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId)
            { messagesSent : Int
            }
    }


type DmChannelId
    = DmChannelId (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId) (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V206.Message.Message Evergreen.V206.Id.ChannelMessageId (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.UserId) (Evergreen.V206.Thread.LastTypedAt Evergreen.V206.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelMessageId) Evergreen.V206.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V206.Message.Message Evergreen.V206.Id.ChannelMessageId (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId) (Evergreen.V206.Thread.LastTypedAt Evergreen.V206.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V206.OneToOne.OneToOne (Evergreen.V206.Discord.Id Evergreen.V206.Discord.MessageId) (Evergreen.V206.Id.Id Evergreen.V206.Id.ChannelMessageId)
    , members :
        Evergreen.V206.NonemptyDict.NonemptyDict
            (Evergreen.V206.Discord.Id Evergreen.V206.Discord.UserId)
            { messagesSent : Int
            }
    }
