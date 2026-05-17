module Evergreen.V228.DmChannel exposing (..)

import Array
import Evergreen.V228.Discord
import Evergreen.V228.Go
import Evergreen.V228.Id
import Evergreen.V228.Message
import Evergreen.V228.NonemptyDict
import Evergreen.V228.OneToOne
import Evergreen.V228.Thread
import Evergreen.V228.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId)


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V228.Message.MessageState Evergreen.V228.Id.ChannelMessageId (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId))
    , visibleMessages : Evergreen.V228.VisibleMessages.VisibleMessages Evergreen.V228.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) (Evergreen.V228.Thread.LastTypedAt Evergreen.V228.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId) Evergreen.V228.Thread.FrontendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId) ( Evergreen.V228.Go.ValidatedSetup, Array.Array Evergreen.V228.Go.ActionWithTime )
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V228.Message.MessageState Evergreen.V228.Id.ChannelMessageId (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId))
    , visibleMessages : Evergreen.V228.VisibleMessages.VisibleMessages Evergreen.V228.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) (Evergreen.V228.Thread.LastTypedAt Evergreen.V228.Id.ChannelMessageId)
    , members :
        Evergreen.V228.NonemptyDict.NonemptyDict
            (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId)
            { messagesSent : Int
            }
    }


type alias DmChannel =
    { messages : Array.Array (Evergreen.V228.Message.Message Evergreen.V228.Id.ChannelMessageId (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.UserId) (Evergreen.V228.Thread.LastTypedAt Evergreen.V228.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId) Evergreen.V228.Thread.BackendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId) ( Evergreen.V228.Go.ValidatedSetup, Array.Array Evergreen.V228.Go.ActionWithTime )
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V228.Message.Message Evergreen.V228.Id.ChannelMessageId (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId) (Evergreen.V228.Thread.LastTypedAt Evergreen.V228.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V228.OneToOne.OneToOne (Evergreen.V228.Discord.Id Evergreen.V228.Discord.MessageId) (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId)
    , members :
        Evergreen.V228.NonemptyDict.NonemptyDict
            (Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId)
            { messagesSent : Int
            }
    }
