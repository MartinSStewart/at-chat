module Evergreen.V215.DmChannel exposing (..)

import Array
import Evergreen.V215.Discord
import Evergreen.V215.Id
import Evergreen.V215.Message
import Evergreen.V215.NonemptyDict
import Evergreen.V215.OneToOne
import Evergreen.V215.Thread
import Evergreen.V215.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V215.Message.MessageState Evergreen.V215.Id.ChannelMessageId (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId))
    , visibleMessages : Evergreen.V215.VisibleMessages.VisibleMessages Evergreen.V215.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) (Evergreen.V215.Thread.LastTypedAt Evergreen.V215.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId) Evergreen.V215.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V215.Message.MessageState Evergreen.V215.Id.ChannelMessageId (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId))
    , visibleMessages : Evergreen.V215.VisibleMessages.VisibleMessages Evergreen.V215.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) (Evergreen.V215.Thread.LastTypedAt Evergreen.V215.Id.ChannelMessageId)
    , members :
        Evergreen.V215.NonemptyDict.NonemptyDict
            (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId)
            { messagesSent : Int
            }
    }


type DmChannelId
    = DmChannelId (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V215.Message.Message Evergreen.V215.Id.ChannelMessageId (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) (Evergreen.V215.Thread.LastTypedAt Evergreen.V215.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId) Evergreen.V215.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V215.Message.Message Evergreen.V215.Id.ChannelMessageId (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId) (Evergreen.V215.Thread.LastTypedAt Evergreen.V215.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V215.OneToOne.OneToOne (Evergreen.V215.Discord.Id Evergreen.V215.Discord.MessageId) (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId)
    , members :
        Evergreen.V215.NonemptyDict.NonemptyDict
            (Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId)
            { messagesSent : Int
            }
    }
