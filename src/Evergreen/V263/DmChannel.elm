module Evergreen.V263.DmChannel exposing (..)

import Array
import Evergreen.V263.Discord
import Evergreen.V263.Go
import Evergreen.V263.Id
import Evergreen.V263.Message
import Evergreen.V263.NonemptyDict
import Evergreen.V263.OneToOne
import Evergreen.V263.Thread
import Evergreen.V263.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId)


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V263.Message.MessageState Evergreen.V263.Id.ChannelMessageId (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId))
    , visibleMessages : Evergreen.V263.VisibleMessages.VisibleMessages Evergreen.V263.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) (Evergreen.V263.Thread.LastTypedAt Evergreen.V263.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId) Evergreen.V263.Thread.FrontendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId) Evergreen.V263.Go.MatchData
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V263.Message.MessageState Evergreen.V263.Id.ChannelMessageId (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId))
    , visibleMessages : Evergreen.V263.VisibleMessages.VisibleMessages Evergreen.V263.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) (Evergreen.V263.Thread.LastTypedAt Evergreen.V263.Id.ChannelMessageId)
    , members :
        Evergreen.V263.NonemptyDict.NonemptyDict
            (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId)
            { messagesSent : Int
            }
    }


type alias DmChannel =
    { messages : Array.Array (Evergreen.V263.Message.Message Evergreen.V263.Id.ChannelMessageId (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.UserId) (Evergreen.V263.Thread.LastTypedAt Evergreen.V263.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId) Evergreen.V263.Thread.BackendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId) ( Evergreen.V263.Go.ValidatedSetup, Array.Array Evergreen.V263.Go.ActionWithTime )
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V263.Message.Message Evergreen.V263.Id.ChannelMessageId (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId) (Evergreen.V263.Thread.LastTypedAt Evergreen.V263.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V263.OneToOne.OneToOne (Evergreen.V263.Discord.Id Evergreen.V263.Discord.MessageId) (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId)
    , members :
        Evergreen.V263.NonemptyDict.NonemptyDict
            (Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId)
            { messagesSent : Int
            }
    }
