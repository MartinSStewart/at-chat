module Evergreen.V294.DmChannel exposing (..)

import Array
import Date
import Evergreen.V294.Discord
import Evergreen.V294.Drawing
import Evergreen.V294.Go
import Evergreen.V294.Id
import Evergreen.V294.Message
import Evergreen.V294.NonemptyDict
import Evergreen.V294.OneToOne
import Evergreen.V294.Thread
import Evergreen.V294.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId)


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V294.Message.MessageState Evergreen.V294.Id.ChannelMessageId (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId))
    , visibleMessages : Evergreen.V294.VisibleMessages.VisibleMessages Evergreen.V294.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) (Evergreen.V294.Thread.LastTypedAt Evergreen.V294.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId) Evergreen.V294.Thread.FrontendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId) Evergreen.V294.Go.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V294.Drawing.Drawing (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V294.Message.MessageState Evergreen.V294.Id.ChannelMessageId (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId))
    , visibleMessages : Evergreen.V294.VisibleMessages.VisibleMessages Evergreen.V294.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) (Evergreen.V294.Thread.LastTypedAt Evergreen.V294.Id.ChannelMessageId)
    , members :
        Evergreen.V294.NonemptyDict.NonemptyDict
            (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V294.Drawing.Drawing (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId))
    }


type alias DmChannel =
    { messages : Array.Array (Evergreen.V294.Message.Message Evergreen.V294.Id.ChannelMessageId (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) (Evergreen.V294.Thread.LastTypedAt Evergreen.V294.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId) Evergreen.V294.Thread.BackendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId) ( Evergreen.V294.Go.ValidatedSetup, Array.Array Evergreen.V294.Go.ActionWithTime )
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V294.Drawing.Drawing (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V294.Message.Message Evergreen.V294.Id.ChannelMessageId (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId) (Evergreen.V294.Thread.LastTypedAt Evergreen.V294.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V294.OneToOne.OneToOne (Evergreen.V294.Discord.Id Evergreen.V294.Discord.MessageId) (Evergreen.V294.Id.Id Evergreen.V294.Id.ChannelMessageId)
    , members :
        Evergreen.V294.NonemptyDict.NonemptyDict
            (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V294.Drawing.Drawing (Evergreen.V294.Discord.Id Evergreen.V294.Discord.UserId))
    }
