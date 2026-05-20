module Evergreen.V242.DmChannel exposing (..)

import Array
import Evergreen.V242.Discord
import Evergreen.V242.Go
import Evergreen.V242.Id
import Evergreen.V242.Message
import Evergreen.V242.NonemptyDict
import Evergreen.V242.OneToOne
import Evergreen.V242.Thread
import Evergreen.V242.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId)


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V242.Message.MessageState Evergreen.V242.Id.ChannelMessageId (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId))
    , visibleMessages : Evergreen.V242.VisibleMessages.VisibleMessages Evergreen.V242.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) (Evergreen.V242.Thread.LastTypedAt Evergreen.V242.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId) Evergreen.V242.Thread.FrontendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId) ( Evergreen.V242.Go.ValidatedSetup, Array.Array Evergreen.V242.Go.ActionWithTime )
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V242.Message.MessageState Evergreen.V242.Id.ChannelMessageId (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId))
    , visibleMessages : Evergreen.V242.VisibleMessages.VisibleMessages Evergreen.V242.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) (Evergreen.V242.Thread.LastTypedAt Evergreen.V242.Id.ChannelMessageId)
    , members :
        Evergreen.V242.NonemptyDict.NonemptyDict
            (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId)
            { messagesSent : Int
            }
    }


type alias DmChannel =
    { messages : Array.Array (Evergreen.V242.Message.Message Evergreen.V242.Id.ChannelMessageId (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.UserId) (Evergreen.V242.Thread.LastTypedAt Evergreen.V242.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId) Evergreen.V242.Thread.BackendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId) ( Evergreen.V242.Go.ValidatedSetup, Array.Array Evergreen.V242.Go.ActionWithTime )
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V242.Message.Message Evergreen.V242.Id.ChannelMessageId (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId) (Evergreen.V242.Thread.LastTypedAt Evergreen.V242.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V242.OneToOne.OneToOne (Evergreen.V242.Discord.Id Evergreen.V242.Discord.MessageId) (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId)
    , members :
        Evergreen.V242.NonemptyDict.NonemptyDict
            (Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId)
            { messagesSent : Int
            }
    }
