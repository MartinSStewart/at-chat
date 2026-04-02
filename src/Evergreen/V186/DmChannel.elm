module Evergreen.V186.DmChannel exposing (..)

import Array
import Evergreen.V186.Discord
import Evergreen.V186.Id
import Evergreen.V186.Message
import Evergreen.V186.NonemptyDict
import Evergreen.V186.OneToOne
import Evergreen.V186.Thread
import Evergreen.V186.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V186.Message.MessageState Evergreen.V186.Id.ChannelMessageId (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId))
    , visibleMessages : Evergreen.V186.VisibleMessages.VisibleMessages Evergreen.V186.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId) (Evergreen.V186.Thread.LastTypedAt Evergreen.V186.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId) Evergreen.V186.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V186.Message.MessageState Evergreen.V186.Id.ChannelMessageId (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId))
    , visibleMessages : Evergreen.V186.VisibleMessages.VisibleMessages Evergreen.V186.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) (Evergreen.V186.Thread.LastTypedAt Evergreen.V186.Id.ChannelMessageId)
    , members :
        Evergreen.V186.NonemptyDict.NonemptyDict
            (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId)
            { messagesSent : Int
            }
    }


type DmChannelId
    = DmChannelId (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId) (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V186.Message.Message Evergreen.V186.Id.ChannelMessageId (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId) (Evergreen.V186.Thread.LastTypedAt Evergreen.V186.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId) Evergreen.V186.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V186.Message.Message Evergreen.V186.Id.ChannelMessageId (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId) (Evergreen.V186.Thread.LastTypedAt Evergreen.V186.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V186.OneToOne.OneToOne (Evergreen.V186.Discord.Id Evergreen.V186.Discord.MessageId) (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId)
    , members :
        Evergreen.V186.NonemptyDict.NonemptyDict
            (Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId)
            { messagesSent : Int
            }
    }
