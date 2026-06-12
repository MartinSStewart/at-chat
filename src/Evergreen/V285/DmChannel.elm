module Evergreen.V285.DmChannel exposing (..)

import Array
import Date
import Evergreen.V285.Discord
import Evergreen.V285.Drawing
import Evergreen.V285.Go
import Evergreen.V285.Id
import Evergreen.V285.Message
import Evergreen.V285.NonemptyDict
import Evergreen.V285.OneToOne
import Evergreen.V285.Thread
import Evergreen.V285.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId)


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V285.Message.MessageState Evergreen.V285.Id.ChannelMessageId (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId))
    , visibleMessages : Evergreen.V285.VisibleMessages.VisibleMessages Evergreen.V285.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) (Evergreen.V285.Thread.LastTypedAt Evergreen.V285.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId) Evergreen.V285.Thread.FrontendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId) Evergreen.V285.Go.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V285.Drawing.Drawing (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V285.Message.MessageState Evergreen.V285.Id.ChannelMessageId (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId))
    , visibleMessages : Evergreen.V285.VisibleMessages.VisibleMessages Evergreen.V285.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) (Evergreen.V285.Thread.LastTypedAt Evergreen.V285.Id.ChannelMessageId)
    , members :
        Evergreen.V285.NonemptyDict.NonemptyDict
            (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V285.Drawing.Drawing (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId))
    }


type alias DmChannel =
    { messages : Array.Array (Evergreen.V285.Message.Message Evergreen.V285.Id.ChannelMessageId (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId) (Evergreen.V285.Thread.LastTypedAt Evergreen.V285.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId) Evergreen.V285.Thread.BackendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId) ( Evergreen.V285.Go.ValidatedSetup, Array.Array Evergreen.V285.Go.ActionWithTime )
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V285.Drawing.Drawing (Evergreen.V285.Id.Id Evergreen.V285.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V285.Message.Message Evergreen.V285.Id.ChannelMessageId (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId) (Evergreen.V285.Thread.LastTypedAt Evergreen.V285.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V285.OneToOne.OneToOne (Evergreen.V285.Discord.Id Evergreen.V285.Discord.MessageId) (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId)
    , members :
        Evergreen.V285.NonemptyDict.NonemptyDict
            (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V285.Drawing.Drawing (Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId))
    }
