module Evergreen.V232.DmChannel exposing (..)

import Array
import Evergreen.V232.Discord
import Evergreen.V232.Go
import Evergreen.V232.Id
import Evergreen.V232.Message
import Evergreen.V232.NonemptyDict
import Evergreen.V232.OneToOne
import Evergreen.V232.Thread
import Evergreen.V232.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId)


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V232.Message.MessageState Evergreen.V232.Id.ChannelMessageId (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId))
    , visibleMessages : Evergreen.V232.VisibleMessages.VisibleMessages Evergreen.V232.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) (Evergreen.V232.Thread.LastTypedAt Evergreen.V232.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId) Evergreen.V232.Thread.FrontendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId) ( Evergreen.V232.Go.ValidatedSetup, Array.Array Evergreen.V232.Go.ActionWithTime )
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V232.Message.MessageState Evergreen.V232.Id.ChannelMessageId (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId))
    , visibleMessages : Evergreen.V232.VisibleMessages.VisibleMessages Evergreen.V232.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) (Evergreen.V232.Thread.LastTypedAt Evergreen.V232.Id.ChannelMessageId)
    , members :
        Evergreen.V232.NonemptyDict.NonemptyDict
            (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId)
            { messagesSent : Int
            }
    }


type alias DmChannel =
    { messages : Array.Array (Evergreen.V232.Message.Message Evergreen.V232.Id.ChannelMessageId (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) (Evergreen.V232.Thread.LastTypedAt Evergreen.V232.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId) Evergreen.V232.Thread.BackendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId) ( Evergreen.V232.Go.ValidatedSetup, Array.Array Evergreen.V232.Go.ActionWithTime )
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V232.Message.Message Evergreen.V232.Id.ChannelMessageId (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId) (Evergreen.V232.Thread.LastTypedAt Evergreen.V232.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V232.OneToOne.OneToOne (Evergreen.V232.Discord.Id Evergreen.V232.Discord.MessageId) (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId)
    , members :
        Evergreen.V232.NonemptyDict.NonemptyDict
            (Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId)
            { messagesSent : Int
            }
    }
