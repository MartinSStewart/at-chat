module Evergreen.V156.DmChannel exposing (..)

import Array
import Evergreen.V156.Discord
import Evergreen.V156.Id
import Evergreen.V156.Message
import Evergreen.V156.NonemptyDict
import Evergreen.V156.OneToOne
import Evergreen.V156.Thread
import Evergreen.V156.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V156.Message.MessageState Evergreen.V156.Id.ChannelMessageId (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId))
    , visibleMessages : Evergreen.V156.VisibleMessages.VisibleMessages Evergreen.V156.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId) (Evergreen.V156.Thread.LastTypedAt Evergreen.V156.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelMessageId) Evergreen.V156.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V156.Message.MessageState Evergreen.V156.Id.ChannelMessageId (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId))
    , visibleMessages : Evergreen.V156.VisibleMessages.VisibleMessages Evergreen.V156.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) (Evergreen.V156.Thread.LastTypedAt Evergreen.V156.Id.ChannelMessageId)
    , members :
        Evergreen.V156.NonemptyDict.NonemptyDict
            (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId)
            { messagesSent : Int
            }
    }


type DmChannelId
    = DmChannelId (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId) (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V156.Message.Message Evergreen.V156.Id.ChannelMessageId (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId) (Evergreen.V156.Thread.LastTypedAt Evergreen.V156.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelMessageId) Evergreen.V156.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V156.Message.Message Evergreen.V156.Id.ChannelMessageId (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId) (Evergreen.V156.Thread.LastTypedAt Evergreen.V156.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V156.OneToOne.OneToOne (Evergreen.V156.Discord.Id Evergreen.V156.Discord.MessageId) (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelMessageId)
    , members :
        Evergreen.V156.NonemptyDict.NonemptyDict
            (Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId)
            { messagesSent : Int
            }
    }
