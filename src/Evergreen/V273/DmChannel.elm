module Evergreen.V273.DmChannel exposing (..)

import Array
import Evergreen.V273.Discord
import Evergreen.V273.Go
import Evergreen.V273.Id
import Evergreen.V273.Message
import Evergreen.V273.NonemptyDict
import Evergreen.V273.OneToOne
import Evergreen.V273.Thread
import Evergreen.V273.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId)


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V273.Message.MessageState Evergreen.V273.Id.ChannelMessageId (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId))
    , visibleMessages : Evergreen.V273.VisibleMessages.VisibleMessages Evergreen.V273.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) (Evergreen.V273.Thread.LastTypedAt Evergreen.V273.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId) Evergreen.V273.Thread.FrontendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId) Evergreen.V273.Go.MatchData
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V273.Message.MessageState Evergreen.V273.Id.ChannelMessageId (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId))
    , visibleMessages : Evergreen.V273.VisibleMessages.VisibleMessages Evergreen.V273.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) (Evergreen.V273.Thread.LastTypedAt Evergreen.V273.Id.ChannelMessageId)
    , members :
        Evergreen.V273.NonemptyDict.NonemptyDict
            (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId)
            { messagesSent : Int
            }
    }


type alias DmChannel =
    { messages : Array.Array (Evergreen.V273.Message.Message Evergreen.V273.Id.ChannelMessageId (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) (Evergreen.V273.Thread.LastTypedAt Evergreen.V273.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId) Evergreen.V273.Thread.BackendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId) ( Evergreen.V273.Go.ValidatedSetup, Array.Array Evergreen.V273.Go.ActionWithTime )
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V273.Message.Message Evergreen.V273.Id.ChannelMessageId (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId) (Evergreen.V273.Thread.LastTypedAt Evergreen.V273.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V273.OneToOne.OneToOne (Evergreen.V273.Discord.Id Evergreen.V273.Discord.MessageId) (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId)
    , members :
        Evergreen.V273.NonemptyDict.NonemptyDict
            (Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId)
            { messagesSent : Int
            }
    }
