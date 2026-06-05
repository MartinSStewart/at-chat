module Evergreen.V277.DmChannel exposing (..)

import Array
import Evergreen.V277.Discord
import Evergreen.V277.Go
import Evergreen.V277.Id
import Evergreen.V277.Message
import Evergreen.V277.NonemptyDict
import Evergreen.V277.OneToOne
import Evergreen.V277.Thread
import Evergreen.V277.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId)


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V277.Message.MessageState Evergreen.V277.Id.ChannelMessageId (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId))
    , visibleMessages : Evergreen.V277.VisibleMessages.VisibleMessages Evergreen.V277.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) (Evergreen.V277.Thread.LastTypedAt Evergreen.V277.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId) Evergreen.V277.Thread.FrontendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId) Evergreen.V277.Go.MatchData
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V277.Message.MessageState Evergreen.V277.Id.ChannelMessageId (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId))
    , visibleMessages : Evergreen.V277.VisibleMessages.VisibleMessages Evergreen.V277.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) (Evergreen.V277.Thread.LastTypedAt Evergreen.V277.Id.ChannelMessageId)
    , members :
        Evergreen.V277.NonemptyDict.NonemptyDict
            (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId)
            { messagesSent : Int
            }
    }


type alias DmChannel =
    { messages : Array.Array (Evergreen.V277.Message.Message Evergreen.V277.Id.ChannelMessageId (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) (Evergreen.V277.Thread.LastTypedAt Evergreen.V277.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId) Evergreen.V277.Thread.BackendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId) ( Evergreen.V277.Go.ValidatedSetup, Array.Array Evergreen.V277.Go.ActionWithTime )
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V277.Message.Message Evergreen.V277.Id.ChannelMessageId (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId) (Evergreen.V277.Thread.LastTypedAt Evergreen.V277.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V277.OneToOne.OneToOne (Evergreen.V277.Discord.Id Evergreen.V277.Discord.MessageId) (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId)
    , members :
        Evergreen.V277.NonemptyDict.NonemptyDict
            (Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId)
            { messagesSent : Int
            }
    }
