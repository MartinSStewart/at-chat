module Evergreen.V288.DmChannel exposing (..)

import Array
import Date
import Evergreen.V288.Discord
import Evergreen.V288.Drawing
import Evergreen.V288.Go
import Evergreen.V288.Id
import Evergreen.V288.Message
import Evergreen.V288.NonemptyDict
import Evergreen.V288.OneToOne
import Evergreen.V288.Thread
import Evergreen.V288.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId)


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V288.Message.MessageState Evergreen.V288.Id.ChannelMessageId (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId))
    , visibleMessages : Evergreen.V288.VisibleMessages.VisibleMessages Evergreen.V288.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) (Evergreen.V288.Thread.LastTypedAt Evergreen.V288.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId) Evergreen.V288.Thread.FrontendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId) Evergreen.V288.Go.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V288.Drawing.Drawing (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V288.Message.MessageState Evergreen.V288.Id.ChannelMessageId (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId))
    , visibleMessages : Evergreen.V288.VisibleMessages.VisibleMessages Evergreen.V288.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) (Evergreen.V288.Thread.LastTypedAt Evergreen.V288.Id.ChannelMessageId)
    , members :
        Evergreen.V288.NonemptyDict.NonemptyDict
            (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V288.Drawing.Drawing (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId))
    }


type alias DmChannel =
    { messages : Array.Array (Evergreen.V288.Message.Message Evergreen.V288.Id.ChannelMessageId (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId) (Evergreen.V288.Thread.LastTypedAt Evergreen.V288.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId) Evergreen.V288.Thread.BackendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId) ( Evergreen.V288.Go.ValidatedSetup, Array.Array Evergreen.V288.Go.ActionWithTime )
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V288.Drawing.Drawing (Evergreen.V288.Id.Id Evergreen.V288.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V288.Message.Message Evergreen.V288.Id.ChannelMessageId (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId) (Evergreen.V288.Thread.LastTypedAt Evergreen.V288.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V288.OneToOne.OneToOne (Evergreen.V288.Discord.Id Evergreen.V288.Discord.MessageId) (Evergreen.V288.Id.Id Evergreen.V288.Id.ChannelMessageId)
    , members :
        Evergreen.V288.NonemptyDict.NonemptyDict
            (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V288.Drawing.Drawing (Evergreen.V288.Discord.Id Evergreen.V288.Discord.UserId))
    }
