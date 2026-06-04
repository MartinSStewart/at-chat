module Evergreen.V275.DmChannel exposing (..)

import Array
import Evergreen.V275.Discord
import Evergreen.V275.Go
import Evergreen.V275.Id
import Evergreen.V275.Message
import Evergreen.V275.NonemptyDict
import Evergreen.V275.OneToOne
import Evergreen.V275.Thread
import Evergreen.V275.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId)


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V275.Message.MessageState Evergreen.V275.Id.ChannelMessageId (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId))
    , visibleMessages : Evergreen.V275.VisibleMessages.VisibleMessages Evergreen.V275.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) (Evergreen.V275.Thread.LastTypedAt Evergreen.V275.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId) Evergreen.V275.Thread.FrontendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId) Evergreen.V275.Go.MatchData
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V275.Message.MessageState Evergreen.V275.Id.ChannelMessageId (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId))
    , visibleMessages : Evergreen.V275.VisibleMessages.VisibleMessages Evergreen.V275.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) (Evergreen.V275.Thread.LastTypedAt Evergreen.V275.Id.ChannelMessageId)
    , members :
        Evergreen.V275.NonemptyDict.NonemptyDict
            (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId)
            { messagesSent : Int
            }
    }


type alias DmChannel =
    { messages : Array.Array (Evergreen.V275.Message.Message Evergreen.V275.Id.ChannelMessageId (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) (Evergreen.V275.Thread.LastTypedAt Evergreen.V275.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId) Evergreen.V275.Thread.BackendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId) ( Evergreen.V275.Go.ValidatedSetup, Array.Array Evergreen.V275.Go.ActionWithTime )
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V275.Message.Message Evergreen.V275.Id.ChannelMessageId (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId) (Evergreen.V275.Thread.LastTypedAt Evergreen.V275.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V275.OneToOne.OneToOne (Evergreen.V275.Discord.Id Evergreen.V275.Discord.MessageId) (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId)
    , members :
        Evergreen.V275.NonemptyDict.NonemptyDict
            (Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId)
            { messagesSent : Int
            }
    }
