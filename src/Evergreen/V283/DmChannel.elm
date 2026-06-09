module Evergreen.V283.DmChannel exposing (..)

import Array
import Evergreen.V283.Discord
import Evergreen.V283.Go
import Evergreen.V283.Id
import Evergreen.V283.Message
import Evergreen.V283.NonemptyDict
import Evergreen.V283.OneToOne
import Evergreen.V283.Thread
import Evergreen.V283.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId) (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId)


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V283.Message.MessageState Evergreen.V283.Id.ChannelMessageId (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId))
    , visibleMessages : Evergreen.V283.VisibleMessages.VisibleMessages Evergreen.V283.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId) (Evergreen.V283.Thread.LastTypedAt Evergreen.V283.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId) Evergreen.V283.Thread.FrontendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId) Evergreen.V283.Go.MatchData
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V283.Message.MessageState Evergreen.V283.Id.ChannelMessageId (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId))
    , visibleMessages : Evergreen.V283.VisibleMessages.VisibleMessages Evergreen.V283.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) (Evergreen.V283.Thread.LastTypedAt Evergreen.V283.Id.ChannelMessageId)
    , members :
        Evergreen.V283.NonemptyDict.NonemptyDict
            (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId)
            { messagesSent : Int
            }
    }


type alias DmChannel =
    { messages : Array.Array (Evergreen.V283.Message.Message Evergreen.V283.Id.ChannelMessageId (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId) (Evergreen.V283.Thread.LastTypedAt Evergreen.V283.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId) Evergreen.V283.Thread.BackendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId) ( Evergreen.V283.Go.ValidatedSetup, Array.Array Evergreen.V283.Go.ActionWithTime )
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V283.Message.Message Evergreen.V283.Id.ChannelMessageId (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId) (Evergreen.V283.Thread.LastTypedAt Evergreen.V283.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V283.OneToOne.OneToOne (Evergreen.V283.Discord.Id Evergreen.V283.Discord.MessageId) (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId)
    , members :
        Evergreen.V283.NonemptyDict.NonemptyDict
            (Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId)
            { messagesSent : Int
            }
    }
