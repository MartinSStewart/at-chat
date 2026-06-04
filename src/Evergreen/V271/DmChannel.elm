module Evergreen.V271.DmChannel exposing (..)

import Array
import Evergreen.V271.Discord
import Evergreen.V271.Go
import Evergreen.V271.Id
import Evergreen.V271.Message
import Evergreen.V271.NonemptyDict
import Evergreen.V271.OneToOne
import Evergreen.V271.Thread
import Evergreen.V271.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId)


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V271.Message.MessageState Evergreen.V271.Id.ChannelMessageId (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId))
    , visibleMessages : Evergreen.V271.VisibleMessages.VisibleMessages Evergreen.V271.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) (Evergreen.V271.Thread.LastTypedAt Evergreen.V271.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId) Evergreen.V271.Thread.FrontendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId) Evergreen.V271.Go.MatchData
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V271.Message.MessageState Evergreen.V271.Id.ChannelMessageId (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId))
    , visibleMessages : Evergreen.V271.VisibleMessages.VisibleMessages Evergreen.V271.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) (Evergreen.V271.Thread.LastTypedAt Evergreen.V271.Id.ChannelMessageId)
    , members :
        Evergreen.V271.NonemptyDict.NonemptyDict
            (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId)
            { messagesSent : Int
            }
    }


type alias DmChannel =
    { messages : Array.Array (Evergreen.V271.Message.Message Evergreen.V271.Id.ChannelMessageId (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) (Evergreen.V271.Thread.LastTypedAt Evergreen.V271.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId) Evergreen.V271.Thread.BackendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId) ( Evergreen.V271.Go.ValidatedSetup, Array.Array Evergreen.V271.Go.ActionWithTime )
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V271.Message.Message Evergreen.V271.Id.ChannelMessageId (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId) (Evergreen.V271.Thread.LastTypedAt Evergreen.V271.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V271.OneToOne.OneToOne (Evergreen.V271.Discord.Id Evergreen.V271.Discord.MessageId) (Evergreen.V271.Id.Id Evergreen.V271.Id.ChannelMessageId)
    , members :
        Evergreen.V271.NonemptyDict.NonemptyDict
            (Evergreen.V271.Discord.Id Evergreen.V271.Discord.UserId)
            { messagesSent : Int
            }
    }
