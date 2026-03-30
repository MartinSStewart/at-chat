module Evergreen.V181.DmChannel exposing (..)

import Array
import Evergreen.V181.Discord
import Evergreen.V181.Id
import Evergreen.V181.Message
import Evergreen.V181.NonemptyDict
import Evergreen.V181.OneToOne
import Evergreen.V181.Thread
import Evergreen.V181.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V181.Message.MessageState Evergreen.V181.Id.ChannelMessageId (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId))
    , visibleMessages : Evergreen.V181.VisibleMessages.VisibleMessages Evergreen.V181.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId) (Evergreen.V181.Thread.LastTypedAt Evergreen.V181.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId) Evergreen.V181.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V181.Message.MessageState Evergreen.V181.Id.ChannelMessageId (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId))
    , visibleMessages : Evergreen.V181.VisibleMessages.VisibleMessages Evergreen.V181.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) (Evergreen.V181.Thread.LastTypedAt Evergreen.V181.Id.ChannelMessageId)
    , members :
        Evergreen.V181.NonemptyDict.NonemptyDict
            (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId)
            { messagesSent : Int
            }
    }


type DmChannelId
    = DmChannelId (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId) (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V181.Message.Message Evergreen.V181.Id.ChannelMessageId (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId) (Evergreen.V181.Thread.LastTypedAt Evergreen.V181.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId) Evergreen.V181.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V181.Message.Message Evergreen.V181.Id.ChannelMessageId (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId) (Evergreen.V181.Thread.LastTypedAt Evergreen.V181.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V181.OneToOne.OneToOne (Evergreen.V181.Discord.Id Evergreen.V181.Discord.MessageId) (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId)
    , members :
        Evergreen.V181.NonemptyDict.NonemptyDict
            (Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId)
            { messagesSent : Int
            }
    }
