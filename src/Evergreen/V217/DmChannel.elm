module Evergreen.V217.DmChannel exposing (..)

import Array
import Evergreen.V217.Discord
import Evergreen.V217.Go
import Evergreen.V217.Id
import Evergreen.V217.Message
import Evergreen.V217.NonemptyDict
import Evergreen.V217.OneToOne
import Evergreen.V217.Thread
import Evergreen.V217.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId)


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V217.Message.MessageState Evergreen.V217.Id.ChannelMessageId (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId))
    , visibleMessages : Evergreen.V217.VisibleMessages.VisibleMessages Evergreen.V217.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) (Evergreen.V217.Thread.LastTypedAt Evergreen.V217.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId) Evergreen.V217.Thread.FrontendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId) ( Evergreen.V217.Go.ValidatedSetup, Array.Array Evergreen.V217.Go.ActionWithTime )
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V217.Message.MessageState Evergreen.V217.Id.ChannelMessageId (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId))
    , visibleMessages : Evergreen.V217.VisibleMessages.VisibleMessages Evergreen.V217.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) (Evergreen.V217.Thread.LastTypedAt Evergreen.V217.Id.ChannelMessageId)
    , members :
        Evergreen.V217.NonemptyDict.NonemptyDict
            (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId)
            { messagesSent : Int
            }
    }


type alias DmChannel =
    { messages : Array.Array (Evergreen.V217.Message.Message Evergreen.V217.Id.ChannelMessageId (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) (Evergreen.V217.Thread.LastTypedAt Evergreen.V217.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId) Evergreen.V217.Thread.BackendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId) ( Evergreen.V217.Go.ValidatedSetup, Array.Array Evergreen.V217.Go.ActionWithTime )
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V217.Message.Message Evergreen.V217.Id.ChannelMessageId (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId) (Evergreen.V217.Thread.LastTypedAt Evergreen.V217.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V217.OneToOne.OneToOne (Evergreen.V217.Discord.Id Evergreen.V217.Discord.MessageId) (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId)
    , members :
        Evergreen.V217.NonemptyDict.NonemptyDict
            (Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId)
            { messagesSent : Int
            }
    }
