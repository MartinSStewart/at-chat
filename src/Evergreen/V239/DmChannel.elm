module Evergreen.V239.DmChannel exposing (..)

import Array
import Evergreen.V239.Discord
import Evergreen.V239.Go
import Evergreen.V239.Id
import Evergreen.V239.Message
import Evergreen.V239.NonemptyDict
import Evergreen.V239.OneToOne
import Evergreen.V239.Thread
import Evergreen.V239.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId)


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V239.Message.MessageState Evergreen.V239.Id.ChannelMessageId (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId))
    , visibleMessages : Evergreen.V239.VisibleMessages.VisibleMessages Evergreen.V239.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) (Evergreen.V239.Thread.LastTypedAt Evergreen.V239.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId) Evergreen.V239.Thread.FrontendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId) ( Evergreen.V239.Go.ValidatedSetup, Array.Array Evergreen.V239.Go.ActionWithTime )
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V239.Message.MessageState Evergreen.V239.Id.ChannelMessageId (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId))
    , visibleMessages : Evergreen.V239.VisibleMessages.VisibleMessages Evergreen.V239.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) (Evergreen.V239.Thread.LastTypedAt Evergreen.V239.Id.ChannelMessageId)
    , members :
        Evergreen.V239.NonemptyDict.NonemptyDict
            (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId)
            { messagesSent : Int
            }
    }


type alias DmChannel =
    { messages : Array.Array (Evergreen.V239.Message.Message Evergreen.V239.Id.ChannelMessageId (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) (Evergreen.V239.Thread.LastTypedAt Evergreen.V239.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId) Evergreen.V239.Thread.BackendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId) ( Evergreen.V239.Go.ValidatedSetup, Array.Array Evergreen.V239.Go.ActionWithTime )
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V239.Message.Message Evergreen.V239.Id.ChannelMessageId (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId) (Evergreen.V239.Thread.LastTypedAt Evergreen.V239.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V239.OneToOne.OneToOne (Evergreen.V239.Discord.Id Evergreen.V239.Discord.MessageId) (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId)
    , members :
        Evergreen.V239.NonemptyDict.NonemptyDict
            (Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId)
            { messagesSent : Int
            }
    }
