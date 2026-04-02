module Evergreen.V187.DmChannel exposing (..)

import Array
import Evergreen.V187.Discord
import Evergreen.V187.Id
import Evergreen.V187.Message
import Evergreen.V187.NonemptyDict
import Evergreen.V187.OneToOne
import Evergreen.V187.Thread
import Evergreen.V187.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V187.Message.MessageState Evergreen.V187.Id.ChannelMessageId (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId))
    , visibleMessages : Evergreen.V187.VisibleMessages.VisibleMessages Evergreen.V187.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId) (Evergreen.V187.Thread.LastTypedAt Evergreen.V187.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId) Evergreen.V187.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V187.Message.MessageState Evergreen.V187.Id.ChannelMessageId (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId))
    , visibleMessages : Evergreen.V187.VisibleMessages.VisibleMessages Evergreen.V187.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) (Evergreen.V187.Thread.LastTypedAt Evergreen.V187.Id.ChannelMessageId)
    , members :
        Evergreen.V187.NonemptyDict.NonemptyDict
            (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId)
            { messagesSent : Int
            }
    }


type DmChannelId
    = DmChannelId (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId) (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V187.Message.Message Evergreen.V187.Id.ChannelMessageId (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId) (Evergreen.V187.Thread.LastTypedAt Evergreen.V187.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId) Evergreen.V187.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V187.Message.Message Evergreen.V187.Id.ChannelMessageId (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId) (Evergreen.V187.Thread.LastTypedAt Evergreen.V187.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V187.OneToOne.OneToOne (Evergreen.V187.Discord.Id Evergreen.V187.Discord.MessageId) (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId)
    , members :
        Evergreen.V187.NonemptyDict.NonemptyDict
            (Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId)
            { messagesSent : Int
            }
    }
