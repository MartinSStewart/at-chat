module Evergreen.V264.DmChannel exposing (..)

import Array
import Evergreen.V264.Discord
import Evergreen.V264.Go
import Evergreen.V264.Id
import Evergreen.V264.Message
import Evergreen.V264.NonemptyDict
import Evergreen.V264.OneToOne
import Evergreen.V264.Thread
import Evergreen.V264.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId)


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V264.Message.MessageState Evergreen.V264.Id.ChannelMessageId (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId))
    , visibleMessages : Evergreen.V264.VisibleMessages.VisibleMessages Evergreen.V264.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) (Evergreen.V264.Thread.LastTypedAt Evergreen.V264.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId) Evergreen.V264.Thread.FrontendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId) Evergreen.V264.Go.MatchData
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V264.Message.MessageState Evergreen.V264.Id.ChannelMessageId (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId))
    , visibleMessages : Evergreen.V264.VisibleMessages.VisibleMessages Evergreen.V264.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) (Evergreen.V264.Thread.LastTypedAt Evergreen.V264.Id.ChannelMessageId)
    , members :
        Evergreen.V264.NonemptyDict.NonemptyDict
            (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId)
            { messagesSent : Int
            }
    }


type alias DmChannel =
    { messages : Array.Array (Evergreen.V264.Message.Message Evergreen.V264.Id.ChannelMessageId (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) (Evergreen.V264.Thread.LastTypedAt Evergreen.V264.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId) Evergreen.V264.Thread.BackendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId) ( Evergreen.V264.Go.ValidatedSetup, Array.Array Evergreen.V264.Go.ActionWithTime )
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V264.Message.Message Evergreen.V264.Id.ChannelMessageId (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId) (Evergreen.V264.Thread.LastTypedAt Evergreen.V264.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V264.OneToOne.OneToOne (Evergreen.V264.Discord.Id Evergreen.V264.Discord.MessageId) (Evergreen.V264.Id.Id Evergreen.V264.Id.ChannelMessageId)
    , members :
        Evergreen.V264.NonemptyDict.NonemptyDict
            (Evergreen.V264.Discord.Id Evergreen.V264.Discord.UserId)
            { messagesSent : Int
            }
    }
