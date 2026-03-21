module Evergreen.V162.DmChannel exposing (..)

import Array
import Evergreen.V162.Discord
import Evergreen.V162.Id
import Evergreen.V162.Message
import Evergreen.V162.NonemptyDict
import Evergreen.V162.OneToOne
import Evergreen.V162.Thread
import Evergreen.V162.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V162.Message.MessageState Evergreen.V162.Id.ChannelMessageId (Evergreen.V162.Id.Id Evergreen.V162.Id.UserId))
    , visibleMessages : Evergreen.V162.VisibleMessages.VisibleMessages Evergreen.V162.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V162.Id.Id Evergreen.V162.Id.UserId) (Evergreen.V162.Thread.LastTypedAt Evergreen.V162.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V162.Id.Id Evergreen.V162.Id.ChannelMessageId) Evergreen.V162.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V162.Message.MessageState Evergreen.V162.Id.ChannelMessageId (Evergreen.V162.Discord.Id Evergreen.V162.Discord.UserId))
    , visibleMessages : Evergreen.V162.VisibleMessages.VisibleMessages Evergreen.V162.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V162.Discord.Id Evergreen.V162.Discord.UserId) (Evergreen.V162.Thread.LastTypedAt Evergreen.V162.Id.ChannelMessageId)
    , members :
        Evergreen.V162.NonemptyDict.NonemptyDict
            (Evergreen.V162.Discord.Id Evergreen.V162.Discord.UserId)
            { messagesSent : Int
            }
    }


type DmChannelId
    = DmChannelId (Evergreen.V162.Id.Id Evergreen.V162.Id.UserId) (Evergreen.V162.Id.Id Evergreen.V162.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V162.Message.Message Evergreen.V162.Id.ChannelMessageId (Evergreen.V162.Id.Id Evergreen.V162.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V162.Id.Id Evergreen.V162.Id.UserId) (Evergreen.V162.Thread.LastTypedAt Evergreen.V162.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V162.Id.Id Evergreen.V162.Id.ChannelMessageId) Evergreen.V162.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V162.Message.Message Evergreen.V162.Id.ChannelMessageId (Evergreen.V162.Discord.Id Evergreen.V162.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V162.Discord.Id Evergreen.V162.Discord.UserId) (Evergreen.V162.Thread.LastTypedAt Evergreen.V162.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V162.OneToOne.OneToOne (Evergreen.V162.Discord.Id Evergreen.V162.Discord.MessageId) (Evergreen.V162.Id.Id Evergreen.V162.Id.ChannelMessageId)
    , members :
        Evergreen.V162.NonemptyDict.NonemptyDict
            (Evergreen.V162.Discord.Id Evergreen.V162.Discord.UserId)
            { messagesSent : Int
            }
    }
