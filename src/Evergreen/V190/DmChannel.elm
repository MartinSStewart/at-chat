module Evergreen.V190.DmChannel exposing (..)

import Array
import Evergreen.V190.Discord
import Evergreen.V190.Id
import Evergreen.V190.Message
import Evergreen.V190.NonemptyDict
import Evergreen.V190.OneToOne
import Evergreen.V190.Thread
import Evergreen.V190.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V190.Message.MessageState Evergreen.V190.Id.ChannelMessageId (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId))
    , visibleMessages : Evergreen.V190.VisibleMessages.VisibleMessages Evergreen.V190.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId) (Evergreen.V190.Thread.LastTypedAt Evergreen.V190.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId) Evergreen.V190.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V190.Message.MessageState Evergreen.V190.Id.ChannelMessageId (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId))
    , visibleMessages : Evergreen.V190.VisibleMessages.VisibleMessages Evergreen.V190.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) (Evergreen.V190.Thread.LastTypedAt Evergreen.V190.Id.ChannelMessageId)
    , members :
        Evergreen.V190.NonemptyDict.NonemptyDict
            (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId)
            { messagesSent : Int
            }
    }


type DmChannelId
    = DmChannelId (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId) (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V190.Message.Message Evergreen.V190.Id.ChannelMessageId (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId) (Evergreen.V190.Thread.LastTypedAt Evergreen.V190.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId) Evergreen.V190.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V190.Message.Message Evergreen.V190.Id.ChannelMessageId (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId) (Evergreen.V190.Thread.LastTypedAt Evergreen.V190.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V190.OneToOne.OneToOne (Evergreen.V190.Discord.Id Evergreen.V190.Discord.MessageId) (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId)
    , members :
        Evergreen.V190.NonemptyDict.NonemptyDict
            (Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId)
            { messagesSent : Int
            }
    }
