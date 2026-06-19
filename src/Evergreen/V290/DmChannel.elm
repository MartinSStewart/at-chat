module Evergreen.V290.DmChannel exposing (..)

import Array
import Date
import Evergreen.V290.Discord
import Evergreen.V290.Drawing
import Evergreen.V290.Go
import Evergreen.V290.Id
import Evergreen.V290.Message
import Evergreen.V290.NonemptyDict
import Evergreen.V290.OneToOne
import Evergreen.V290.Thread
import Evergreen.V290.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId)


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V290.Message.MessageState Evergreen.V290.Id.ChannelMessageId (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId))
    , visibleMessages : Evergreen.V290.VisibleMessages.VisibleMessages Evergreen.V290.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) (Evergreen.V290.Thread.LastTypedAt Evergreen.V290.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId) Evergreen.V290.Thread.FrontendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId) Evergreen.V290.Go.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V290.Drawing.Drawing (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V290.Message.MessageState Evergreen.V290.Id.ChannelMessageId (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId))
    , visibleMessages : Evergreen.V290.VisibleMessages.VisibleMessages Evergreen.V290.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) (Evergreen.V290.Thread.LastTypedAt Evergreen.V290.Id.ChannelMessageId)
    , members :
        Evergreen.V290.NonemptyDict.NonemptyDict
            (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V290.Drawing.Drawing (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId))
    }


type alias DmChannel =
    { messages : Array.Array (Evergreen.V290.Message.Message Evergreen.V290.Id.ChannelMessageId (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) (Evergreen.V290.Thread.LastTypedAt Evergreen.V290.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId) Evergreen.V290.Thread.BackendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId) ( Evergreen.V290.Go.ValidatedSetup, Array.Array Evergreen.V290.Go.ActionWithTime )
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V290.Drawing.Drawing (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V290.Message.Message Evergreen.V290.Id.ChannelMessageId (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId) (Evergreen.V290.Thread.LastTypedAt Evergreen.V290.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V290.OneToOne.OneToOne (Evergreen.V290.Discord.Id Evergreen.V290.Discord.MessageId) (Evergreen.V290.Id.Id Evergreen.V290.Id.ChannelMessageId)
    , members :
        Evergreen.V290.NonemptyDict.NonemptyDict
            (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V290.Drawing.Drawing (Evergreen.V290.Discord.Id Evergreen.V290.Discord.UserId))
    }
