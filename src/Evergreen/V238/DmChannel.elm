module Evergreen.V238.DmChannel exposing (..)

import Array
import Evergreen.V238.Discord
import Evergreen.V238.Go
import Evergreen.V238.Id
import Evergreen.V238.Message
import Evergreen.V238.NonemptyDict
import Evergreen.V238.OneToOne
import Evergreen.V238.Thread
import Evergreen.V238.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId)


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V238.Message.MessageState Evergreen.V238.Id.ChannelMessageId (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId))
    , visibleMessages : Evergreen.V238.VisibleMessages.VisibleMessages Evergreen.V238.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) (Evergreen.V238.Thread.LastTypedAt Evergreen.V238.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId) Evergreen.V238.Thread.FrontendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId) ( Evergreen.V238.Go.ValidatedSetup, Array.Array Evergreen.V238.Go.ActionWithTime )
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V238.Message.MessageState Evergreen.V238.Id.ChannelMessageId (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId))
    , visibleMessages : Evergreen.V238.VisibleMessages.VisibleMessages Evergreen.V238.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) (Evergreen.V238.Thread.LastTypedAt Evergreen.V238.Id.ChannelMessageId)
    , members :
        Evergreen.V238.NonemptyDict.NonemptyDict
            (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId)
            { messagesSent : Int
            }
    }


type alias DmChannel =
    { messages : Array.Array (Evergreen.V238.Message.Message Evergreen.V238.Id.ChannelMessageId (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.UserId) (Evergreen.V238.Thread.LastTypedAt Evergreen.V238.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId) Evergreen.V238.Thread.BackendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId) ( Evergreen.V238.Go.ValidatedSetup, Array.Array Evergreen.V238.Go.ActionWithTime )
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V238.Message.Message Evergreen.V238.Id.ChannelMessageId (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId) (Evergreen.V238.Thread.LastTypedAt Evergreen.V238.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V238.OneToOne.OneToOne (Evergreen.V238.Discord.Id Evergreen.V238.Discord.MessageId) (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId)
    , members :
        Evergreen.V238.NonemptyDict.NonemptyDict
            (Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId)
            { messagesSent : Int
            }
    }
