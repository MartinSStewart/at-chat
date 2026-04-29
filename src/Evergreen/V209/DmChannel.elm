module Evergreen.V209.DmChannel exposing (..)

import Array
import Evergreen.V209.Discord
import Evergreen.V209.Id
import Evergreen.V209.Message
import Evergreen.V209.NonemptyDict
import Evergreen.V209.OneToOne
import Evergreen.V209.Thread
import Evergreen.V209.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V209.Message.MessageState Evergreen.V209.Id.ChannelMessageId (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId))
    , visibleMessages : Evergreen.V209.VisibleMessages.VisibleMessages Evergreen.V209.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId) (Evergreen.V209.Thread.LastTypedAt Evergreen.V209.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId) Evergreen.V209.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V209.Message.MessageState Evergreen.V209.Id.ChannelMessageId (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId))
    , visibleMessages : Evergreen.V209.VisibleMessages.VisibleMessages Evergreen.V209.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) (Evergreen.V209.Thread.LastTypedAt Evergreen.V209.Id.ChannelMessageId)
    , members :
        Evergreen.V209.NonemptyDict.NonemptyDict
            (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId)
            { messagesSent : Int
            }
    }


type DmChannelId
    = DmChannelId (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId) (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V209.Message.Message Evergreen.V209.Id.ChannelMessageId (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId) (Evergreen.V209.Thread.LastTypedAt Evergreen.V209.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId) Evergreen.V209.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V209.Message.Message Evergreen.V209.Id.ChannelMessageId (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId) (Evergreen.V209.Thread.LastTypedAt Evergreen.V209.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V209.OneToOne.OneToOne (Evergreen.V209.Discord.Id Evergreen.V209.Discord.MessageId) (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId)
    , members :
        Evergreen.V209.NonemptyDict.NonemptyDict
            (Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId)
            { messagesSent : Int
            }
    }
