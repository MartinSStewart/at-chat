module Evergreen.V193.DmChannel exposing (..)

import Array
import Evergreen.V193.Discord
import Evergreen.V193.Id
import Evergreen.V193.Message
import Evergreen.V193.NonemptyDict
import Evergreen.V193.OneToOne
import Evergreen.V193.Thread
import Evergreen.V193.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V193.Message.MessageState Evergreen.V193.Id.ChannelMessageId (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId))
    , visibleMessages : Evergreen.V193.VisibleMessages.VisibleMessages Evergreen.V193.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId) (Evergreen.V193.Thread.LastTypedAt Evergreen.V193.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId) Evergreen.V193.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V193.Message.MessageState Evergreen.V193.Id.ChannelMessageId (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId))
    , visibleMessages : Evergreen.V193.VisibleMessages.VisibleMessages Evergreen.V193.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) (Evergreen.V193.Thread.LastTypedAt Evergreen.V193.Id.ChannelMessageId)
    , members :
        Evergreen.V193.NonemptyDict.NonemptyDict
            (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId)
            { messagesSent : Int
            }
    }


type DmChannelId
    = DmChannelId (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId) (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V193.Message.Message Evergreen.V193.Id.ChannelMessageId (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.UserId) (Evergreen.V193.Thread.LastTypedAt Evergreen.V193.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId) Evergreen.V193.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V193.Message.Message Evergreen.V193.Id.ChannelMessageId (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId) (Evergreen.V193.Thread.LastTypedAt Evergreen.V193.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V193.OneToOne.OneToOne (Evergreen.V193.Discord.Id Evergreen.V193.Discord.MessageId) (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId)
    , members :
        Evergreen.V193.NonemptyDict.NonemptyDict
            (Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId)
            { messagesSent : Int
            }
    }
