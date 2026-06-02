module Evergreen.V266.DmChannel exposing (..)

import Array
import Evergreen.V266.Discord
import Evergreen.V266.Go
import Evergreen.V266.Id
import Evergreen.V266.Message
import Evergreen.V266.NonemptyDict
import Evergreen.V266.OneToOne
import Evergreen.V266.Thread
import Evergreen.V266.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId)


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V266.Message.MessageState Evergreen.V266.Id.ChannelMessageId (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId))
    , visibleMessages : Evergreen.V266.VisibleMessages.VisibleMessages Evergreen.V266.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) (Evergreen.V266.Thread.LastTypedAt Evergreen.V266.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId) Evergreen.V266.Thread.FrontendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId) Evergreen.V266.Go.MatchData
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V266.Message.MessageState Evergreen.V266.Id.ChannelMessageId (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId))
    , visibleMessages : Evergreen.V266.VisibleMessages.VisibleMessages Evergreen.V266.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) (Evergreen.V266.Thread.LastTypedAt Evergreen.V266.Id.ChannelMessageId)
    , members :
        Evergreen.V266.NonemptyDict.NonemptyDict
            (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId)
            { messagesSent : Int
            }
    }


type alias DmChannel =
    { messages : Array.Array (Evergreen.V266.Message.Message Evergreen.V266.Id.ChannelMessageId (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) (Evergreen.V266.Thread.LastTypedAt Evergreen.V266.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId) Evergreen.V266.Thread.BackendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId) ( Evergreen.V266.Go.ValidatedSetup, Array.Array Evergreen.V266.Go.ActionWithTime )
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V266.Message.Message Evergreen.V266.Id.ChannelMessageId (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId) (Evergreen.V266.Thread.LastTypedAt Evergreen.V266.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V266.OneToOne.OneToOne (Evergreen.V266.Discord.Id Evergreen.V266.Discord.MessageId) (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId)
    , members :
        Evergreen.V266.NonemptyDict.NonemptyDict
            (Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId)
            { messagesSent : Int
            }
    }
