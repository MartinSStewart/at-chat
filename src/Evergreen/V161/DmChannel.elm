module Evergreen.V161.DmChannel exposing (..)

import Array
import Evergreen.V161.Discord
import Evergreen.V161.Id
import Evergreen.V161.Message
import Evergreen.V161.NonemptyDict
import Evergreen.V161.OneToOne
import Evergreen.V161.Thread
import Evergreen.V161.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V161.Message.MessageState Evergreen.V161.Id.ChannelMessageId (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId))
    , visibleMessages : Evergreen.V161.VisibleMessages.VisibleMessages Evergreen.V161.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId) (Evergreen.V161.Thread.LastTypedAt Evergreen.V161.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId) Evergreen.V161.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V161.Message.MessageState Evergreen.V161.Id.ChannelMessageId (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId))
    , visibleMessages : Evergreen.V161.VisibleMessages.VisibleMessages Evergreen.V161.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) (Evergreen.V161.Thread.LastTypedAt Evergreen.V161.Id.ChannelMessageId)
    , members :
        Evergreen.V161.NonemptyDict.NonemptyDict
            (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId)
            { messagesSent : Int
            }
    }


type DmChannelId
    = DmChannelId (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId) (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V161.Message.Message Evergreen.V161.Id.ChannelMessageId (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId) (Evergreen.V161.Thread.LastTypedAt Evergreen.V161.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId) Evergreen.V161.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V161.Message.Message Evergreen.V161.Id.ChannelMessageId (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId) (Evergreen.V161.Thread.LastTypedAt Evergreen.V161.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V161.OneToOne.OneToOne (Evergreen.V161.Discord.Id Evergreen.V161.Discord.MessageId) (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId)
    , members :
        Evergreen.V161.NonemptyDict.NonemptyDict
            (Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId)
            { messagesSent : Int
            }
    }
