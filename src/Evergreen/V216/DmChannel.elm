module Evergreen.V216.DmChannel exposing (..)

import Array
import Evergreen.V216.Discord
import Evergreen.V216.Go
import Evergreen.V216.Id
import Evergreen.V216.Message
import Evergreen.V216.NonemptyDict
import Evergreen.V216.OneToOne
import Evergreen.V216.Thread
import Evergreen.V216.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId)


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V216.Message.MessageState Evergreen.V216.Id.ChannelMessageId (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId))
    , visibleMessages : Evergreen.V216.VisibleMessages.VisibleMessages Evergreen.V216.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) (Evergreen.V216.Thread.LastTypedAt Evergreen.V216.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId) Evergreen.V216.Thread.FrontendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId) ( Evergreen.V216.Go.ValidatedSetup, Array.Array Evergreen.V216.Go.ActionWithTime )
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V216.Message.MessageState Evergreen.V216.Id.ChannelMessageId (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId))
    , visibleMessages : Evergreen.V216.VisibleMessages.VisibleMessages Evergreen.V216.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) (Evergreen.V216.Thread.LastTypedAt Evergreen.V216.Id.ChannelMessageId)
    , members :
        Evergreen.V216.NonemptyDict.NonemptyDict
            (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId)
            { messagesSent : Int
            }
    }


type alias DmChannel =
    { messages : Array.Array (Evergreen.V216.Message.Message Evergreen.V216.Id.ChannelMessageId (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) (Evergreen.V216.Thread.LastTypedAt Evergreen.V216.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId) Evergreen.V216.Thread.BackendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId) ( Evergreen.V216.Go.ValidatedSetup, Array.Array Evergreen.V216.Go.ActionWithTime )
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V216.Message.Message Evergreen.V216.Id.ChannelMessageId (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId) (Evergreen.V216.Thread.LastTypedAt Evergreen.V216.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V216.OneToOne.OneToOne (Evergreen.V216.Discord.Id Evergreen.V216.Discord.MessageId) (Evergreen.V216.Id.Id Evergreen.V216.Id.ChannelMessageId)
    , members :
        Evergreen.V216.NonemptyDict.NonemptyDict
            (Evergreen.V216.Discord.Id Evergreen.V216.Discord.UserId)
            { messagesSent : Int
            }
    }
