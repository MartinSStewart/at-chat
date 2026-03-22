module Evergreen.V167.DmChannel exposing (..)

import Array
import Evergreen.V167.Discord
import Evergreen.V167.Id
import Evergreen.V167.Message
import Evergreen.V167.NonemptyDict
import Evergreen.V167.OneToOne
import Evergreen.V167.Thread
import Evergreen.V167.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V167.Message.MessageState Evergreen.V167.Id.ChannelMessageId (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId))
    , visibleMessages : Evergreen.V167.VisibleMessages.VisibleMessages Evergreen.V167.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId) (Evergreen.V167.Thread.LastTypedAt Evergreen.V167.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId) Evergreen.V167.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V167.Message.MessageState Evergreen.V167.Id.ChannelMessageId (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId))
    , visibleMessages : Evergreen.V167.VisibleMessages.VisibleMessages Evergreen.V167.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) (Evergreen.V167.Thread.LastTypedAt Evergreen.V167.Id.ChannelMessageId)
    , members :
        Evergreen.V167.NonemptyDict.NonemptyDict
            (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId)
            { messagesSent : Int
            }
    }


type DmChannelId
    = DmChannelId (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId) (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V167.Message.Message Evergreen.V167.Id.ChannelMessageId (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId) (Evergreen.V167.Thread.LastTypedAt Evergreen.V167.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId) Evergreen.V167.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V167.Message.Message Evergreen.V167.Id.ChannelMessageId (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId) (Evergreen.V167.Thread.LastTypedAt Evergreen.V167.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V167.OneToOne.OneToOne (Evergreen.V167.Discord.Id Evergreen.V167.Discord.MessageId) (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId)
    , members :
        Evergreen.V167.NonemptyDict.NonemptyDict
            (Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId)
            { messagesSent : Int
            }
    }
