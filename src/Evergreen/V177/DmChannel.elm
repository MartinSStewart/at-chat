module Evergreen.V177.DmChannel exposing (..)

import Array
import Evergreen.V177.Discord
import Evergreen.V177.Id
import Evergreen.V177.Message
import Evergreen.V177.NonemptyDict
import Evergreen.V177.OneToOne
import Evergreen.V177.Thread
import Evergreen.V177.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V177.Message.MessageState Evergreen.V177.Id.ChannelMessageId (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId))
    , visibleMessages : Evergreen.V177.VisibleMessages.VisibleMessages Evergreen.V177.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId) (Evergreen.V177.Thread.LastTypedAt Evergreen.V177.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId) Evergreen.V177.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V177.Message.MessageState Evergreen.V177.Id.ChannelMessageId (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId))
    , visibleMessages : Evergreen.V177.VisibleMessages.VisibleMessages Evergreen.V177.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) (Evergreen.V177.Thread.LastTypedAt Evergreen.V177.Id.ChannelMessageId)
    , members :
        Evergreen.V177.NonemptyDict.NonemptyDict
            (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId)
            { messagesSent : Int
            }
    }


type DmChannelId
    = DmChannelId (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId) (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V177.Message.Message Evergreen.V177.Id.ChannelMessageId (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId) (Evergreen.V177.Thread.LastTypedAt Evergreen.V177.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId) Evergreen.V177.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V177.Message.Message Evergreen.V177.Id.ChannelMessageId (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId) (Evergreen.V177.Thread.LastTypedAt Evergreen.V177.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V177.OneToOne.OneToOne (Evergreen.V177.Discord.Id Evergreen.V177.Discord.MessageId) (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId)
    , members :
        Evergreen.V177.NonemptyDict.NonemptyDict
            (Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId)
            { messagesSent : Int
            }
    }
