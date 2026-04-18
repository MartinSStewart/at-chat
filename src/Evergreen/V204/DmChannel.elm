module Evergreen.V204.DmChannel exposing (..)

import Array
import Evergreen.V204.Discord
import Evergreen.V204.Id
import Evergreen.V204.Message
import Evergreen.V204.NonemptyDict
import Evergreen.V204.OneToOne
import Evergreen.V204.Thread
import Evergreen.V204.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V204.Message.MessageState Evergreen.V204.Id.ChannelMessageId (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId))
    , visibleMessages : Evergreen.V204.VisibleMessages.VisibleMessages Evergreen.V204.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId) (Evergreen.V204.Thread.LastTypedAt Evergreen.V204.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId) Evergreen.V204.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V204.Message.MessageState Evergreen.V204.Id.ChannelMessageId (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId))
    , visibleMessages : Evergreen.V204.VisibleMessages.VisibleMessages Evergreen.V204.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) (Evergreen.V204.Thread.LastTypedAt Evergreen.V204.Id.ChannelMessageId)
    , members :
        Evergreen.V204.NonemptyDict.NonemptyDict
            (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId)
            { messagesSent : Int
            }
    }


type DmChannelId
    = DmChannelId (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId) (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V204.Message.Message Evergreen.V204.Id.ChannelMessageId (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.UserId) (Evergreen.V204.Thread.LastTypedAt Evergreen.V204.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId) Evergreen.V204.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V204.Message.Message Evergreen.V204.Id.ChannelMessageId (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId) (Evergreen.V204.Thread.LastTypedAt Evergreen.V204.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V204.OneToOne.OneToOne (Evergreen.V204.Discord.Id Evergreen.V204.Discord.MessageId) (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId)
    , members :
        Evergreen.V204.NonemptyDict.NonemptyDict
            (Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId)
            { messagesSent : Int
            }
    }
