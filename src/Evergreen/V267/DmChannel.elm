module Evergreen.V267.DmChannel exposing (..)

import Array
import Evergreen.V267.Discord
import Evergreen.V267.Go
import Evergreen.V267.Id
import Evergreen.V267.Message
import Evergreen.V267.NonemptyDict
import Evergreen.V267.OneToOne
import Evergreen.V267.Thread
import Evergreen.V267.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId) (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId)


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V267.Message.MessageState Evergreen.V267.Id.ChannelMessageId (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId))
    , visibleMessages : Evergreen.V267.VisibleMessages.VisibleMessages Evergreen.V267.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId) (Evergreen.V267.Thread.LastTypedAt Evergreen.V267.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId) Evergreen.V267.Thread.FrontendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId) Evergreen.V267.Go.MatchData
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V267.Message.MessageState Evergreen.V267.Id.ChannelMessageId (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId))
    , visibleMessages : Evergreen.V267.VisibleMessages.VisibleMessages Evergreen.V267.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) (Evergreen.V267.Thread.LastTypedAt Evergreen.V267.Id.ChannelMessageId)
    , members :
        Evergreen.V267.NonemptyDict.NonemptyDict
            (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId)
            { messagesSent : Int
            }
    }


type alias DmChannel =
    { messages : Array.Array (Evergreen.V267.Message.Message Evergreen.V267.Id.ChannelMessageId (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId) (Evergreen.V267.Thread.LastTypedAt Evergreen.V267.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId) Evergreen.V267.Thread.BackendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId) ( Evergreen.V267.Go.ValidatedSetup, Array.Array Evergreen.V267.Go.ActionWithTime )
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V267.Message.Message Evergreen.V267.Id.ChannelMessageId (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId) (Evergreen.V267.Thread.LastTypedAt Evergreen.V267.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V267.OneToOne.OneToOne (Evergreen.V267.Discord.Id Evergreen.V267.Discord.MessageId) (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId)
    , members :
        Evergreen.V267.NonemptyDict.NonemptyDict
            (Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId)
            { messagesSent : Int
            }
    }
