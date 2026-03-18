module Evergreen.V158.DmChannel exposing (..)

import Array
import Evergreen.V158.Discord
import Evergreen.V158.Id
import Evergreen.V158.Message
import Evergreen.V158.NonemptyDict
import Evergreen.V158.OneToOne
import Evergreen.V158.Thread
import Evergreen.V158.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V158.Message.MessageState Evergreen.V158.Id.ChannelMessageId (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId))
    , visibleMessages : Evergreen.V158.VisibleMessages.VisibleMessages Evergreen.V158.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId) (Evergreen.V158.Thread.LastTypedAt Evergreen.V158.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId) Evergreen.V158.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V158.Message.MessageState Evergreen.V158.Id.ChannelMessageId (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId))
    , visibleMessages : Evergreen.V158.VisibleMessages.VisibleMessages Evergreen.V158.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) (Evergreen.V158.Thread.LastTypedAt Evergreen.V158.Id.ChannelMessageId)
    , members :
        Evergreen.V158.NonemptyDict.NonemptyDict
            (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId)
            { messagesSent : Int
            }
    }


type DmChannelId
    = DmChannelId (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId) (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V158.Message.Message Evergreen.V158.Id.ChannelMessageId (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId) (Evergreen.V158.Thread.LastTypedAt Evergreen.V158.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId) Evergreen.V158.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V158.Message.Message Evergreen.V158.Id.ChannelMessageId (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId) (Evergreen.V158.Thread.LastTypedAt Evergreen.V158.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V158.OneToOne.OneToOne (Evergreen.V158.Discord.Id Evergreen.V158.Discord.MessageId) (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId)
    , members :
        Evergreen.V158.NonemptyDict.NonemptyDict
            (Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId)
            { messagesSent : Int
            }
    }
