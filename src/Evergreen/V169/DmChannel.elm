module Evergreen.V169.DmChannel exposing (..)

import Array
import Evergreen.V169.Discord
import Evergreen.V169.Id
import Evergreen.V169.Message
import Evergreen.V169.NonemptyDict
import Evergreen.V169.OneToOne
import Evergreen.V169.Thread
import Evergreen.V169.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V169.Message.MessageState Evergreen.V169.Id.ChannelMessageId (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId))
    , visibleMessages : Evergreen.V169.VisibleMessages.VisibleMessages Evergreen.V169.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId) (Evergreen.V169.Thread.LastTypedAt Evergreen.V169.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId) Evergreen.V169.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V169.Message.MessageState Evergreen.V169.Id.ChannelMessageId (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId))
    , visibleMessages : Evergreen.V169.VisibleMessages.VisibleMessages Evergreen.V169.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) (Evergreen.V169.Thread.LastTypedAt Evergreen.V169.Id.ChannelMessageId)
    , members :
        Evergreen.V169.NonemptyDict.NonemptyDict
            (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId)
            { messagesSent : Int
            }
    }


type DmChannelId
    = DmChannelId (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId) (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V169.Message.Message Evergreen.V169.Id.ChannelMessageId (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId) (Evergreen.V169.Thread.LastTypedAt Evergreen.V169.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId) Evergreen.V169.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V169.Message.Message Evergreen.V169.Id.ChannelMessageId (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId) (Evergreen.V169.Thread.LastTypedAt Evergreen.V169.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V169.OneToOne.OneToOne (Evergreen.V169.Discord.Id Evergreen.V169.Discord.MessageId) (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId)
    , members :
        Evergreen.V169.NonemptyDict.NonemptyDict
            (Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId)
            { messagesSent : Int
            }
    }
