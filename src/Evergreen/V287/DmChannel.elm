module Evergreen.V287.DmChannel exposing (..)

import Array
import Date
import Evergreen.V287.Discord
import Evergreen.V287.Drawing
import Evergreen.V287.Go
import Evergreen.V287.Id
import Evergreen.V287.Message
import Evergreen.V287.NonemptyDict
import Evergreen.V287.OneToOne
import Evergreen.V287.Thread
import Evergreen.V287.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId)


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V287.Message.MessageState Evergreen.V287.Id.ChannelMessageId (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId))
    , visibleMessages : Evergreen.V287.VisibleMessages.VisibleMessages Evergreen.V287.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) (Evergreen.V287.Thread.LastTypedAt Evergreen.V287.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId) Evergreen.V287.Thread.FrontendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId) Evergreen.V287.Go.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V287.Drawing.Drawing (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V287.Message.MessageState Evergreen.V287.Id.ChannelMessageId (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId))
    , visibleMessages : Evergreen.V287.VisibleMessages.VisibleMessages Evergreen.V287.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) (Evergreen.V287.Thread.LastTypedAt Evergreen.V287.Id.ChannelMessageId)
    , members :
        Evergreen.V287.NonemptyDict.NonemptyDict
            (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V287.Drawing.Drawing (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId))
    }


type alias DmChannel =
    { messages : Array.Array (Evergreen.V287.Message.Message Evergreen.V287.Id.ChannelMessageId (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) (Evergreen.V287.Thread.LastTypedAt Evergreen.V287.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId) Evergreen.V287.Thread.BackendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId) ( Evergreen.V287.Go.ValidatedSetup, Array.Array Evergreen.V287.Go.ActionWithTime )
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V287.Drawing.Drawing (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V287.Message.Message Evergreen.V287.Id.ChannelMessageId (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId) (Evergreen.V287.Thread.LastTypedAt Evergreen.V287.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V287.OneToOne.OneToOne (Evergreen.V287.Discord.Id Evergreen.V287.Discord.MessageId) (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId)
    , members :
        Evergreen.V287.NonemptyDict.NonemptyDict
            (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V287.Drawing.Drawing (Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId))
    }
