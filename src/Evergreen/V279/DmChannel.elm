module Evergreen.V279.DmChannel exposing (..)

import Array
import Evergreen.V279.Discord
import Evergreen.V279.Go
import Evergreen.V279.Id
import Evergreen.V279.Message
import Evergreen.V279.NonemptyDict
import Evergreen.V279.OneToOne
import Evergreen.V279.Thread
import Evergreen.V279.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId)


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V279.Message.MessageState Evergreen.V279.Id.ChannelMessageId (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId))
    , visibleMessages : Evergreen.V279.VisibleMessages.VisibleMessages Evergreen.V279.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) (Evergreen.V279.Thread.LastTypedAt Evergreen.V279.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId) Evergreen.V279.Thread.FrontendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId) Evergreen.V279.Go.MatchData
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V279.Message.MessageState Evergreen.V279.Id.ChannelMessageId (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId))
    , visibleMessages : Evergreen.V279.VisibleMessages.VisibleMessages Evergreen.V279.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) (Evergreen.V279.Thread.LastTypedAt Evergreen.V279.Id.ChannelMessageId)
    , members :
        Evergreen.V279.NonemptyDict.NonemptyDict
            (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId)
            { messagesSent : Int
            }
    }


type alias DmChannel =
    { messages : Array.Array (Evergreen.V279.Message.Message Evergreen.V279.Id.ChannelMessageId (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) (Evergreen.V279.Thread.LastTypedAt Evergreen.V279.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId) Evergreen.V279.Thread.BackendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId) ( Evergreen.V279.Go.ValidatedSetup, Array.Array Evergreen.V279.Go.ActionWithTime )
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V279.Message.Message Evergreen.V279.Id.ChannelMessageId (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId) (Evergreen.V279.Thread.LastTypedAt Evergreen.V279.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V279.OneToOne.OneToOne (Evergreen.V279.Discord.Id Evergreen.V279.Discord.MessageId) (Evergreen.V279.Id.Id Evergreen.V279.Id.ChannelMessageId)
    , members :
        Evergreen.V279.NonemptyDict.NonemptyDict
            (Evergreen.V279.Discord.Id Evergreen.V279.Discord.UserId)
            { messagesSent : Int
            }
    }
