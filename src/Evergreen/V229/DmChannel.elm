module Evergreen.V229.DmChannel exposing (..)

import Array
import Evergreen.V229.Discord
import Evergreen.V229.Go
import Evergreen.V229.Id
import Evergreen.V229.Message
import Evergreen.V229.NonemptyDict
import Evergreen.V229.OneToOne
import Evergreen.V229.Thread
import Evergreen.V229.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId)


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V229.Message.MessageState Evergreen.V229.Id.ChannelMessageId (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId))
    , visibleMessages : Evergreen.V229.VisibleMessages.VisibleMessages Evergreen.V229.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) (Evergreen.V229.Thread.LastTypedAt Evergreen.V229.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId) Evergreen.V229.Thread.FrontendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId) ( Evergreen.V229.Go.ValidatedSetup, Array.Array Evergreen.V229.Go.ActionWithTime )
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V229.Message.MessageState Evergreen.V229.Id.ChannelMessageId (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId))
    , visibleMessages : Evergreen.V229.VisibleMessages.VisibleMessages Evergreen.V229.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) (Evergreen.V229.Thread.LastTypedAt Evergreen.V229.Id.ChannelMessageId)
    , members :
        Evergreen.V229.NonemptyDict.NonemptyDict
            (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId)
            { messagesSent : Int
            }
    }


type alias DmChannel =
    { messages : Array.Array (Evergreen.V229.Message.Message Evergreen.V229.Id.ChannelMessageId (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) (Evergreen.V229.Thread.LastTypedAt Evergreen.V229.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId) Evergreen.V229.Thread.BackendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId) ( Evergreen.V229.Go.ValidatedSetup, Array.Array Evergreen.V229.Go.ActionWithTime )
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V229.Message.Message Evergreen.V229.Id.ChannelMessageId (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId) (Evergreen.V229.Thread.LastTypedAt Evergreen.V229.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V229.OneToOne.OneToOne (Evergreen.V229.Discord.Id Evergreen.V229.Discord.MessageId) (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId)
    , members :
        Evergreen.V229.NonemptyDict.NonemptyDict
            (Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId)
            { messagesSent : Int
            }
    }
