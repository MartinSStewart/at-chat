module Evergreen.V218.DmChannel exposing (..)

import Array
import Evergreen.V218.Discord
import Evergreen.V218.Go
import Evergreen.V218.Id
import Evergreen.V218.Message
import Evergreen.V218.NonemptyDict
import Evergreen.V218.OneToOne
import Evergreen.V218.Thread
import Evergreen.V218.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId)


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V218.Message.MessageState Evergreen.V218.Id.ChannelMessageId (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId))
    , visibleMessages : Evergreen.V218.VisibleMessages.VisibleMessages Evergreen.V218.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) (Evergreen.V218.Thread.LastTypedAt Evergreen.V218.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId) Evergreen.V218.Thread.FrontendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId) ( Evergreen.V218.Go.ValidatedSetup, Array.Array Evergreen.V218.Go.ActionWithTime )
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V218.Message.MessageState Evergreen.V218.Id.ChannelMessageId (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId))
    , visibleMessages : Evergreen.V218.VisibleMessages.VisibleMessages Evergreen.V218.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) (Evergreen.V218.Thread.LastTypedAt Evergreen.V218.Id.ChannelMessageId)
    , members :
        Evergreen.V218.NonemptyDict.NonemptyDict
            (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId)
            { messagesSent : Int
            }
    }


type alias DmChannel =
    { messages : Array.Array (Evergreen.V218.Message.Message Evergreen.V218.Id.ChannelMessageId (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) (Evergreen.V218.Thread.LastTypedAt Evergreen.V218.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId) Evergreen.V218.Thread.BackendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId) ( Evergreen.V218.Go.ValidatedSetup, Array.Array Evergreen.V218.Go.ActionWithTime )
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V218.Message.Message Evergreen.V218.Id.ChannelMessageId (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId) (Evergreen.V218.Thread.LastTypedAt Evergreen.V218.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V218.OneToOne.OneToOne (Evergreen.V218.Discord.Id Evergreen.V218.Discord.MessageId) (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId)
    , members :
        Evergreen.V218.NonemptyDict.NonemptyDict
            (Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId)
            { messagesSent : Int
            }
    }
