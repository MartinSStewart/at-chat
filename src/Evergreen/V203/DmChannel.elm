module Evergreen.V203.DmChannel exposing (..)

import Array
import Evergreen.V203.Discord
import Evergreen.V203.Id
import Evergreen.V203.Message
import Evergreen.V203.NonemptyDict
import Evergreen.V203.OneToOne
import Evergreen.V203.Thread
import Evergreen.V203.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V203.Message.MessageState Evergreen.V203.Id.ChannelMessageId (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId))
    , visibleMessages : Evergreen.V203.VisibleMessages.VisibleMessages Evergreen.V203.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId) (Evergreen.V203.Thread.LastTypedAt Evergreen.V203.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId) Evergreen.V203.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V203.Message.MessageState Evergreen.V203.Id.ChannelMessageId (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId))
    , visibleMessages : Evergreen.V203.VisibleMessages.VisibleMessages Evergreen.V203.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) (Evergreen.V203.Thread.LastTypedAt Evergreen.V203.Id.ChannelMessageId)
    , members :
        Evergreen.V203.NonemptyDict.NonemptyDict
            (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId)
            { messagesSent : Int
            }
    }


type DmChannelId
    = DmChannelId (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId) (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V203.Message.Message Evergreen.V203.Id.ChannelMessageId (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId) (Evergreen.V203.Thread.LastTypedAt Evergreen.V203.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId) Evergreen.V203.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V203.Message.Message Evergreen.V203.Id.ChannelMessageId (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId) (Evergreen.V203.Thread.LastTypedAt Evergreen.V203.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V203.OneToOne.OneToOne (Evergreen.V203.Discord.Id Evergreen.V203.Discord.MessageId) (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId)
    , members :
        Evergreen.V203.NonemptyDict.NonemptyDict
            (Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId)
            { messagesSent : Int
            }
    }
