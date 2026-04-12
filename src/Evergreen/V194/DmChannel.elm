module Evergreen.V194.DmChannel exposing (..)

import Array
import Evergreen.V194.Discord
import Evergreen.V194.Id
import Evergreen.V194.Message
import Evergreen.V194.NonemptyDict
import Evergreen.V194.OneToOne
import Evergreen.V194.Thread
import Evergreen.V194.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V194.Message.MessageState Evergreen.V194.Id.ChannelMessageId (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId))
    , visibleMessages : Evergreen.V194.VisibleMessages.VisibleMessages Evergreen.V194.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId) (Evergreen.V194.Thread.LastTypedAt Evergreen.V194.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId) Evergreen.V194.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V194.Message.MessageState Evergreen.V194.Id.ChannelMessageId (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId))
    , visibleMessages : Evergreen.V194.VisibleMessages.VisibleMessages Evergreen.V194.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) (Evergreen.V194.Thread.LastTypedAt Evergreen.V194.Id.ChannelMessageId)
    , members :
        Evergreen.V194.NonemptyDict.NonemptyDict
            (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId)
            { messagesSent : Int
            }
    }


type DmChannelId
    = DmChannelId (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId) (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V194.Message.Message Evergreen.V194.Id.ChannelMessageId (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.UserId) (Evergreen.V194.Thread.LastTypedAt Evergreen.V194.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId) Evergreen.V194.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V194.Message.Message Evergreen.V194.Id.ChannelMessageId (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId) (Evergreen.V194.Thread.LastTypedAt Evergreen.V194.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V194.OneToOne.OneToOne (Evergreen.V194.Discord.Id Evergreen.V194.Discord.MessageId) (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId)
    , members :
        Evergreen.V194.NonemptyDict.NonemptyDict
            (Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId)
            { messagesSent : Int
            }
    }
