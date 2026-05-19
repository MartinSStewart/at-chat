module Evergreen.V240.DmChannel exposing (..)

import Array
import Evergreen.V240.Discord
import Evergreen.V240.Go
import Evergreen.V240.Id
import Evergreen.V240.Message
import Evergreen.V240.NonemptyDict
import Evergreen.V240.OneToOne
import Evergreen.V240.Thread
import Evergreen.V240.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId) (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId)


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V240.Message.MessageState Evergreen.V240.Id.ChannelMessageId (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId))
    , visibleMessages : Evergreen.V240.VisibleMessages.VisibleMessages Evergreen.V240.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId) (Evergreen.V240.Thread.LastTypedAt Evergreen.V240.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelMessageId) Evergreen.V240.Thread.FrontendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelMessageId) ( Evergreen.V240.Go.ValidatedSetup, Array.Array Evergreen.V240.Go.ActionWithTime )
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V240.Message.MessageState Evergreen.V240.Id.ChannelMessageId (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId))
    , visibleMessages : Evergreen.V240.VisibleMessages.VisibleMessages Evergreen.V240.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) (Evergreen.V240.Thread.LastTypedAt Evergreen.V240.Id.ChannelMessageId)
    , members :
        Evergreen.V240.NonemptyDict.NonemptyDict
            (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId)
            { messagesSent : Int
            }
    }


type alias DmChannel =
    { messages : Array.Array (Evergreen.V240.Message.Message Evergreen.V240.Id.ChannelMessageId (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId) (Evergreen.V240.Thread.LastTypedAt Evergreen.V240.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelMessageId) Evergreen.V240.Thread.BackendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelMessageId) ( Evergreen.V240.Go.ValidatedSetup, Array.Array Evergreen.V240.Go.ActionWithTime )
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V240.Message.Message Evergreen.V240.Id.ChannelMessageId (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId) (Evergreen.V240.Thread.LastTypedAt Evergreen.V240.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V240.OneToOne.OneToOne (Evergreen.V240.Discord.Id Evergreen.V240.Discord.MessageId) (Evergreen.V240.Id.Id Evergreen.V240.Id.ChannelMessageId)
    , members :
        Evergreen.V240.NonemptyDict.NonemptyDict
            (Evergreen.V240.Discord.Id Evergreen.V240.Discord.UserId)
            { messagesSent : Int
            }
    }
