module Evergreen.V293.DmChannel exposing (..)

import Array
import Date
import Evergreen.V293.Discord
import Evergreen.V293.Drawing
import Evergreen.V293.Go
import Evergreen.V293.Id
import Evergreen.V293.Message
import Evergreen.V293.NonemptyDict
import Evergreen.V293.OneToOne
import Evergreen.V293.Thread
import Evergreen.V293.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId)


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V293.Message.MessageState Evergreen.V293.Id.ChannelMessageId (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId))
    , visibleMessages : Evergreen.V293.VisibleMessages.VisibleMessages Evergreen.V293.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) (Evergreen.V293.Thread.LastTypedAt Evergreen.V293.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId) Evergreen.V293.Thread.FrontendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId) Evergreen.V293.Go.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V293.Drawing.Drawing (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V293.Message.MessageState Evergreen.V293.Id.ChannelMessageId (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId))
    , visibleMessages : Evergreen.V293.VisibleMessages.VisibleMessages Evergreen.V293.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) (Evergreen.V293.Thread.LastTypedAt Evergreen.V293.Id.ChannelMessageId)
    , members :
        Evergreen.V293.NonemptyDict.NonemptyDict
            (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V293.Drawing.Drawing (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId))
    }


type alias DmChannel =
    { messages : Array.Array (Evergreen.V293.Message.Message Evergreen.V293.Id.ChannelMessageId (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) (Evergreen.V293.Thread.LastTypedAt Evergreen.V293.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId) Evergreen.V293.Thread.BackendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId) ( Evergreen.V293.Go.ValidatedSetup, Array.Array Evergreen.V293.Go.ActionWithTime )
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V293.Drawing.Drawing (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V293.Message.Message Evergreen.V293.Id.ChannelMessageId (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId) (Evergreen.V293.Thread.LastTypedAt Evergreen.V293.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V293.OneToOne.OneToOne (Evergreen.V293.Discord.Id Evergreen.V293.Discord.MessageId) (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId)
    , members :
        Evergreen.V293.NonemptyDict.NonemptyDict
            (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V293.Drawing.Drawing (Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId))
    }
