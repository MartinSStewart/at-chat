module Evergreen.V270.DmChannel exposing (..)

import Array
import Evergreen.V270.Discord
import Evergreen.V270.Go
import Evergreen.V270.Id
import Evergreen.V270.Message
import Evergreen.V270.NonemptyDict
import Evergreen.V270.OneToOne
import Evergreen.V270.Thread
import Evergreen.V270.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId)


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V270.Message.MessageState Evergreen.V270.Id.ChannelMessageId (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId))
    , visibleMessages : Evergreen.V270.VisibleMessages.VisibleMessages Evergreen.V270.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) (Evergreen.V270.Thread.LastTypedAt Evergreen.V270.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId) Evergreen.V270.Thread.FrontendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId) Evergreen.V270.Go.MatchData
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V270.Message.MessageState Evergreen.V270.Id.ChannelMessageId (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId))
    , visibleMessages : Evergreen.V270.VisibleMessages.VisibleMessages Evergreen.V270.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) (Evergreen.V270.Thread.LastTypedAt Evergreen.V270.Id.ChannelMessageId)
    , members :
        Evergreen.V270.NonemptyDict.NonemptyDict
            (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId)
            { messagesSent : Int
            }
    }


type alias DmChannel =
    { messages : Array.Array (Evergreen.V270.Message.Message Evergreen.V270.Id.ChannelMessageId (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) (Evergreen.V270.Thread.LastTypedAt Evergreen.V270.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId) Evergreen.V270.Thread.BackendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId) ( Evergreen.V270.Go.ValidatedSetup, Array.Array Evergreen.V270.Go.ActionWithTime )
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V270.Message.Message Evergreen.V270.Id.ChannelMessageId (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId) (Evergreen.V270.Thread.LastTypedAt Evergreen.V270.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V270.OneToOne.OneToOne (Evergreen.V270.Discord.Id Evergreen.V270.Discord.MessageId) (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId)
    , members :
        Evergreen.V270.NonemptyDict.NonemptyDict
            (Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId)
            { messagesSent : Int
            }
    }
