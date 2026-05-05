module Evergreen.V214.DmChannel exposing (..)

import Array
import Evergreen.V214.Discord
import Evergreen.V214.Id
import Evergreen.V214.Message
import Evergreen.V214.NonemptyDict
import Evergreen.V214.OneToOne
import Evergreen.V214.Thread
import Evergreen.V214.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V214.Message.MessageState Evergreen.V214.Id.ChannelMessageId (Evergreen.V214.Id.Id Evergreen.V214.Id.UserId))
    , visibleMessages : Evergreen.V214.VisibleMessages.VisibleMessages Evergreen.V214.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V214.Id.Id Evergreen.V214.Id.UserId) (Evergreen.V214.Thread.LastTypedAt Evergreen.V214.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V214.Id.Id Evergreen.V214.Id.ChannelMessageId) Evergreen.V214.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V214.Message.MessageState Evergreen.V214.Id.ChannelMessageId (Evergreen.V214.Discord.Id Evergreen.V214.Discord.UserId))
    , visibleMessages : Evergreen.V214.VisibleMessages.VisibleMessages Evergreen.V214.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V214.Discord.Id Evergreen.V214.Discord.UserId) (Evergreen.V214.Thread.LastTypedAt Evergreen.V214.Id.ChannelMessageId)
    , members :
        Evergreen.V214.NonemptyDict.NonemptyDict
            (Evergreen.V214.Discord.Id Evergreen.V214.Discord.UserId)
            { messagesSent : Int
            }
    }


type DmChannelId
    = DmChannelId (Evergreen.V214.Id.Id Evergreen.V214.Id.UserId) (Evergreen.V214.Id.Id Evergreen.V214.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V214.Message.Message Evergreen.V214.Id.ChannelMessageId (Evergreen.V214.Id.Id Evergreen.V214.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V214.Id.Id Evergreen.V214.Id.UserId) (Evergreen.V214.Thread.LastTypedAt Evergreen.V214.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V214.Id.Id Evergreen.V214.Id.ChannelMessageId) Evergreen.V214.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V214.Message.Message Evergreen.V214.Id.ChannelMessageId (Evergreen.V214.Discord.Id Evergreen.V214.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V214.Discord.Id Evergreen.V214.Discord.UserId) (Evergreen.V214.Thread.LastTypedAt Evergreen.V214.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V214.OneToOne.OneToOne (Evergreen.V214.Discord.Id Evergreen.V214.Discord.MessageId) (Evergreen.V214.Id.Id Evergreen.V214.Id.ChannelMessageId)
    , members :
        Evergreen.V214.NonemptyDict.NonemptyDict
            (Evergreen.V214.Discord.Id Evergreen.V214.Discord.UserId)
            { messagesSent : Int
            }
    }
