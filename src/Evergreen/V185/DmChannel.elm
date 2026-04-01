module Evergreen.V185.DmChannel exposing (..)

import Array
import Evergreen.V185.Discord
import Evergreen.V185.Id
import Evergreen.V185.Message
import Evergreen.V185.NonemptyDict
import Evergreen.V185.OneToOne
import Evergreen.V185.Thread
import Evergreen.V185.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V185.Message.MessageState Evergreen.V185.Id.ChannelMessageId (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId))
    , visibleMessages : Evergreen.V185.VisibleMessages.VisibleMessages Evergreen.V185.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId) (Evergreen.V185.Thread.LastTypedAt Evergreen.V185.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId) Evergreen.V185.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V185.Message.MessageState Evergreen.V185.Id.ChannelMessageId (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId))
    , visibleMessages : Evergreen.V185.VisibleMessages.VisibleMessages Evergreen.V185.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) (Evergreen.V185.Thread.LastTypedAt Evergreen.V185.Id.ChannelMessageId)
    , members :
        Evergreen.V185.NonemptyDict.NonemptyDict
            (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId)
            { messagesSent : Int
            }
    }


type DmChannelId
    = DmChannelId (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId) (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V185.Message.Message Evergreen.V185.Id.ChannelMessageId (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId) (Evergreen.V185.Thread.LastTypedAt Evergreen.V185.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId) Evergreen.V185.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V185.Message.Message Evergreen.V185.Id.ChannelMessageId (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId) (Evergreen.V185.Thread.LastTypedAt Evergreen.V185.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V185.OneToOne.OneToOne (Evergreen.V185.Discord.Id Evergreen.V185.Discord.MessageId) (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId)
    , members :
        Evergreen.V185.NonemptyDict.NonemptyDict
            (Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId)
            { messagesSent : Int
            }
    }
