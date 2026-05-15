module Evergreen.V223.DmChannel exposing (..)

import Array
import Evergreen.V223.Discord
import Evergreen.V223.Go
import Evergreen.V223.Id
import Evergreen.V223.Message
import Evergreen.V223.NonemptyDict
import Evergreen.V223.OneToOne
import Evergreen.V223.Thread
import Evergreen.V223.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V223.Id.Id Evergreen.V223.Id.UserId) (Evergreen.V223.Id.Id Evergreen.V223.Id.UserId)


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V223.Message.MessageState Evergreen.V223.Id.ChannelMessageId (Evergreen.V223.Id.Id Evergreen.V223.Id.UserId))
    , visibleMessages : Evergreen.V223.VisibleMessages.VisibleMessages Evergreen.V223.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V223.Id.Id Evergreen.V223.Id.UserId) (Evergreen.V223.Thread.LastTypedAt Evergreen.V223.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V223.Id.Id Evergreen.V223.Id.ChannelMessageId) Evergreen.V223.Thread.FrontendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V223.Id.Id Evergreen.V223.Id.ChannelMessageId) ( Evergreen.V223.Go.ValidatedSetup, Array.Array Evergreen.V223.Go.ActionWithTime )
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V223.Message.MessageState Evergreen.V223.Id.ChannelMessageId (Evergreen.V223.Discord.Id Evergreen.V223.Discord.UserId))
    , visibleMessages : Evergreen.V223.VisibleMessages.VisibleMessages Evergreen.V223.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V223.Discord.Id Evergreen.V223.Discord.UserId) (Evergreen.V223.Thread.LastTypedAt Evergreen.V223.Id.ChannelMessageId)
    , members :
        Evergreen.V223.NonemptyDict.NonemptyDict
            (Evergreen.V223.Discord.Id Evergreen.V223.Discord.UserId)
            { messagesSent : Int
            }
    }


type alias DmChannel =
    { messages : Array.Array (Evergreen.V223.Message.Message Evergreen.V223.Id.ChannelMessageId (Evergreen.V223.Id.Id Evergreen.V223.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V223.Id.Id Evergreen.V223.Id.UserId) (Evergreen.V223.Thread.LastTypedAt Evergreen.V223.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V223.Id.Id Evergreen.V223.Id.ChannelMessageId) Evergreen.V223.Thread.BackendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V223.Id.Id Evergreen.V223.Id.ChannelMessageId) ( Evergreen.V223.Go.ValidatedSetup, Array.Array Evergreen.V223.Go.ActionWithTime )
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V223.Message.Message Evergreen.V223.Id.ChannelMessageId (Evergreen.V223.Discord.Id Evergreen.V223.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V223.Discord.Id Evergreen.V223.Discord.UserId) (Evergreen.V223.Thread.LastTypedAt Evergreen.V223.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V223.OneToOne.OneToOne (Evergreen.V223.Discord.Id Evergreen.V223.Discord.MessageId) (Evergreen.V223.Id.Id Evergreen.V223.Id.ChannelMessageId)
    , members :
        Evergreen.V223.NonemptyDict.NonemptyDict
            (Evergreen.V223.Discord.Id Evergreen.V223.Discord.UserId)
            { messagesSent : Int
            }
    }
