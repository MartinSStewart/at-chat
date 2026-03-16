module Evergreen.V154.DmChannel exposing (..)

import Array
import Evergreen.V154.Discord
import Evergreen.V154.Id
import Evergreen.V154.Message
import Evergreen.V154.NonemptyDict
import Evergreen.V154.OneToOne
import Evergreen.V154.Thread
import Evergreen.V154.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V154.Message.MessageState Evergreen.V154.Id.ChannelMessageId (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId))
    , visibleMessages : Evergreen.V154.VisibleMessages.VisibleMessages Evergreen.V154.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId) (Evergreen.V154.Thread.LastTypedAt Evergreen.V154.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelMessageId) Evergreen.V154.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V154.Message.MessageState Evergreen.V154.Id.ChannelMessageId (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId))
    , visibleMessages : Evergreen.V154.VisibleMessages.VisibleMessages Evergreen.V154.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) (Evergreen.V154.Thread.LastTypedAt Evergreen.V154.Id.ChannelMessageId)
    , members :
        Evergreen.V154.NonemptyDict.NonemptyDict
            (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId)
            { messagesSent : Int
            }
    }


type DmChannelId
    = DmChannelId (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId) (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V154.Message.Message Evergreen.V154.Id.ChannelMessageId (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId) (Evergreen.V154.Thread.LastTypedAt Evergreen.V154.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelMessageId) Evergreen.V154.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V154.Message.Message Evergreen.V154.Id.ChannelMessageId (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId) (Evergreen.V154.Thread.LastTypedAt Evergreen.V154.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V154.OneToOne.OneToOne (Evergreen.V154.Discord.Id Evergreen.V154.Discord.MessageId) (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelMessageId)
    , members :
        Evergreen.V154.NonemptyDict.NonemptyDict
            (Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId)
            { messagesSent : Int
            }
    }
