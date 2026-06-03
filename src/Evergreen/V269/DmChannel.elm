module Evergreen.V269.DmChannel exposing (..)

import Array
import Evergreen.V269.Discord
import Evergreen.V269.Go
import Evergreen.V269.Id
import Evergreen.V269.Message
import Evergreen.V269.NonemptyDict
import Evergreen.V269.OneToOne
import Evergreen.V269.Thread
import Evergreen.V269.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId)


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V269.Message.MessageState Evergreen.V269.Id.ChannelMessageId (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId))
    , visibleMessages : Evergreen.V269.VisibleMessages.VisibleMessages Evergreen.V269.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) (Evergreen.V269.Thread.LastTypedAt Evergreen.V269.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId) Evergreen.V269.Thread.FrontendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId) Evergreen.V269.Go.MatchData
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V269.Message.MessageState Evergreen.V269.Id.ChannelMessageId (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId))
    , visibleMessages : Evergreen.V269.VisibleMessages.VisibleMessages Evergreen.V269.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) (Evergreen.V269.Thread.LastTypedAt Evergreen.V269.Id.ChannelMessageId)
    , members :
        Evergreen.V269.NonemptyDict.NonemptyDict
            (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId)
            { messagesSent : Int
            }
    }


type alias DmChannel =
    { messages : Array.Array (Evergreen.V269.Message.Message Evergreen.V269.Id.ChannelMessageId (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) (Evergreen.V269.Thread.LastTypedAt Evergreen.V269.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId) Evergreen.V269.Thread.BackendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId) ( Evergreen.V269.Go.ValidatedSetup, Array.Array Evergreen.V269.Go.ActionWithTime )
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V269.Message.Message Evergreen.V269.Id.ChannelMessageId (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId) (Evergreen.V269.Thread.LastTypedAt Evergreen.V269.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V269.OneToOne.OneToOne (Evergreen.V269.Discord.Id Evergreen.V269.Discord.MessageId) (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId)
    , members :
        Evergreen.V269.NonemptyDict.NonemptyDict
            (Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId)
            { messagesSent : Int
            }
    }
