module Evergreen.V236.DmChannel exposing (..)

import Array
import Evergreen.V236.Discord
import Evergreen.V236.Go
import Evergreen.V236.Id
import Evergreen.V236.Message
import Evergreen.V236.NonemptyDict
import Evergreen.V236.OneToOne
import Evergreen.V236.Thread
import Evergreen.V236.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId)


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V236.Message.MessageState Evergreen.V236.Id.ChannelMessageId (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId))
    , visibleMessages : Evergreen.V236.VisibleMessages.VisibleMessages Evergreen.V236.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) (Evergreen.V236.Thread.LastTypedAt Evergreen.V236.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId) Evergreen.V236.Thread.FrontendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId) ( Evergreen.V236.Go.ValidatedSetup, Array.Array Evergreen.V236.Go.ActionWithTime )
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V236.Message.MessageState Evergreen.V236.Id.ChannelMessageId (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId))
    , visibleMessages : Evergreen.V236.VisibleMessages.VisibleMessages Evergreen.V236.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) (Evergreen.V236.Thread.LastTypedAt Evergreen.V236.Id.ChannelMessageId)
    , members :
        Evergreen.V236.NonemptyDict.NonemptyDict
            (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId)
            { messagesSent : Int
            }
    }


type alias DmChannel =
    { messages : Array.Array (Evergreen.V236.Message.Message Evergreen.V236.Id.ChannelMessageId (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.UserId) (Evergreen.V236.Thread.LastTypedAt Evergreen.V236.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId) Evergreen.V236.Thread.BackendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId) ( Evergreen.V236.Go.ValidatedSetup, Array.Array Evergreen.V236.Go.ActionWithTime )
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V236.Message.Message Evergreen.V236.Id.ChannelMessageId (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId) (Evergreen.V236.Thread.LastTypedAt Evergreen.V236.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V236.OneToOne.OneToOne (Evergreen.V236.Discord.Id Evergreen.V236.Discord.MessageId) (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId)
    , members :
        Evergreen.V236.NonemptyDict.NonemptyDict
            (Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId)
            { messagesSent : Int
            }
    }
