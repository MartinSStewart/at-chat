module Evergreen.V289.DmChannel exposing (..)

import Array
import Date
import Evergreen.V289.Discord
import Evergreen.V289.Drawing
import Evergreen.V289.Go
import Evergreen.V289.Id
import Evergreen.V289.Message
import Evergreen.V289.NonemptyDict
import Evergreen.V289.OneToOne
import Evergreen.V289.Thread
import Evergreen.V289.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId)


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V289.Message.MessageState Evergreen.V289.Id.ChannelMessageId (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId))
    , visibleMessages : Evergreen.V289.VisibleMessages.VisibleMessages Evergreen.V289.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) (Evergreen.V289.Thread.LastTypedAt Evergreen.V289.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId) Evergreen.V289.Thread.FrontendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId) Evergreen.V289.Go.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V289.Drawing.Drawing (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V289.Message.MessageState Evergreen.V289.Id.ChannelMessageId (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId))
    , visibleMessages : Evergreen.V289.VisibleMessages.VisibleMessages Evergreen.V289.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) (Evergreen.V289.Thread.LastTypedAt Evergreen.V289.Id.ChannelMessageId)
    , members :
        Evergreen.V289.NonemptyDict.NonemptyDict
            (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V289.Drawing.Drawing (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId))
    }


type alias DmChannel =
    { messages : Array.Array (Evergreen.V289.Message.Message Evergreen.V289.Id.ChannelMessageId (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId) (Evergreen.V289.Thread.LastTypedAt Evergreen.V289.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId) Evergreen.V289.Thread.BackendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId) ( Evergreen.V289.Go.ValidatedSetup, Array.Array Evergreen.V289.Go.ActionWithTime )
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V289.Drawing.Drawing (Evergreen.V289.Id.Id Evergreen.V289.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V289.Message.Message Evergreen.V289.Id.ChannelMessageId (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId) (Evergreen.V289.Thread.LastTypedAt Evergreen.V289.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V289.OneToOne.OneToOne (Evergreen.V289.Discord.Id Evergreen.V289.Discord.MessageId) (Evergreen.V289.Id.Id Evergreen.V289.Id.ChannelMessageId)
    , members :
        Evergreen.V289.NonemptyDict.NonemptyDict
            (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V289.Drawing.Drawing (Evergreen.V289.Discord.Id Evergreen.V289.Discord.UserId))
    }
