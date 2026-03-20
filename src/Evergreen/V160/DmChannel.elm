module Evergreen.V160.DmChannel exposing (..)

import Array
import Evergreen.V160.Discord
import Evergreen.V160.Id
import Evergreen.V160.Message
import Evergreen.V160.NonemptyDict
import Evergreen.V160.OneToOne
import Evergreen.V160.Thread
import Evergreen.V160.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V160.Message.MessageState Evergreen.V160.Id.ChannelMessageId (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId))
    , visibleMessages : Evergreen.V160.VisibleMessages.VisibleMessages Evergreen.V160.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId) (Evergreen.V160.Thread.LastTypedAt Evergreen.V160.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId) Evergreen.V160.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V160.Message.MessageState Evergreen.V160.Id.ChannelMessageId (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId))
    , visibleMessages : Evergreen.V160.VisibleMessages.VisibleMessages Evergreen.V160.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) (Evergreen.V160.Thread.LastTypedAt Evergreen.V160.Id.ChannelMessageId)
    , members :
        Evergreen.V160.NonemptyDict.NonemptyDict
            (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId)
            { messagesSent : Int
            }
    }


type DmChannelId
    = DmChannelId (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId) (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V160.Message.Message Evergreen.V160.Id.ChannelMessageId (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId) (Evergreen.V160.Thread.LastTypedAt Evergreen.V160.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId) Evergreen.V160.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V160.Message.Message Evergreen.V160.Id.ChannelMessageId (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId) (Evergreen.V160.Thread.LastTypedAt Evergreen.V160.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V160.OneToOne.OneToOne (Evergreen.V160.Discord.Id Evergreen.V160.Discord.MessageId) (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId)
    , members :
        Evergreen.V160.NonemptyDict.NonemptyDict
            (Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId)
            { messagesSent : Int
            }
    }
