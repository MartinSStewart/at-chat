module Evergreen.V262.DmChannel exposing (..)

import Array
import Evergreen.V262.Discord
import Evergreen.V262.Go
import Evergreen.V262.Id
import Evergreen.V262.Message
import Evergreen.V262.NonemptyDict
import Evergreen.V262.OneToOne
import Evergreen.V262.Thread
import Evergreen.V262.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V262.Id.Id Evergreen.V262.Id.UserId) (Evergreen.V262.Id.Id Evergreen.V262.Id.UserId)


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V262.Message.MessageState Evergreen.V262.Id.ChannelMessageId (Evergreen.V262.Id.Id Evergreen.V262.Id.UserId))
    , visibleMessages : Evergreen.V262.VisibleMessages.VisibleMessages Evergreen.V262.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V262.Id.Id Evergreen.V262.Id.UserId) (Evergreen.V262.Thread.LastTypedAt Evergreen.V262.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V262.Id.Id Evergreen.V262.Id.ChannelMessageId) Evergreen.V262.Thread.FrontendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V262.Id.Id Evergreen.V262.Id.ChannelMessageId) Evergreen.V262.Go.MatchData
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V262.Message.MessageState Evergreen.V262.Id.ChannelMessageId (Evergreen.V262.Discord.Id Evergreen.V262.Discord.UserId))
    , visibleMessages : Evergreen.V262.VisibleMessages.VisibleMessages Evergreen.V262.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V262.Discord.Id Evergreen.V262.Discord.UserId) (Evergreen.V262.Thread.LastTypedAt Evergreen.V262.Id.ChannelMessageId)
    , members :
        Evergreen.V262.NonemptyDict.NonemptyDict
            (Evergreen.V262.Discord.Id Evergreen.V262.Discord.UserId)
            { messagesSent : Int
            }
    }


type alias DmChannel =
    { messages : Array.Array (Evergreen.V262.Message.Message Evergreen.V262.Id.ChannelMessageId (Evergreen.V262.Id.Id Evergreen.V262.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V262.Id.Id Evergreen.V262.Id.UserId) (Evergreen.V262.Thread.LastTypedAt Evergreen.V262.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V262.Id.Id Evergreen.V262.Id.ChannelMessageId) Evergreen.V262.Thread.BackendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V262.Id.Id Evergreen.V262.Id.ChannelMessageId) ( Evergreen.V262.Go.ValidatedSetup, Array.Array Evergreen.V262.Go.ActionWithTime )
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V262.Message.Message Evergreen.V262.Id.ChannelMessageId (Evergreen.V262.Discord.Id Evergreen.V262.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V262.Discord.Id Evergreen.V262.Discord.UserId) (Evergreen.V262.Thread.LastTypedAt Evergreen.V262.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V262.OneToOne.OneToOne (Evergreen.V262.Discord.Id Evergreen.V262.Discord.MessageId) (Evergreen.V262.Id.Id Evergreen.V262.Id.ChannelMessageId)
    , members :
        Evergreen.V262.NonemptyDict.NonemptyDict
            (Evergreen.V262.Discord.Id Evergreen.V262.Discord.UserId)
            { messagesSent : Int
            }
    }
