module Evergreen.V286.DmChannel exposing (..)

import Array
import Date
import Evergreen.V286.Discord
import Evergreen.V286.Drawing
import Evergreen.V286.Go
import Evergreen.V286.Id
import Evergreen.V286.Message
import Evergreen.V286.NonemptyDict
import Evergreen.V286.OneToOne
import Evergreen.V286.Thread
import Evergreen.V286.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId)


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V286.Message.MessageState Evergreen.V286.Id.ChannelMessageId (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId))
    , visibleMessages : Evergreen.V286.VisibleMessages.VisibleMessages Evergreen.V286.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) (Evergreen.V286.Thread.LastTypedAt Evergreen.V286.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId) Evergreen.V286.Thread.FrontendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId) Evergreen.V286.Go.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V286.Drawing.Drawing (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V286.Message.MessageState Evergreen.V286.Id.ChannelMessageId (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId))
    , visibleMessages : Evergreen.V286.VisibleMessages.VisibleMessages Evergreen.V286.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) (Evergreen.V286.Thread.LastTypedAt Evergreen.V286.Id.ChannelMessageId)
    , members :
        Evergreen.V286.NonemptyDict.NonemptyDict
            (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V286.Drawing.Drawing (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId))
    }


type alias DmChannel =
    { messages : Array.Array (Evergreen.V286.Message.Message Evergreen.V286.Id.ChannelMessageId (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId) (Evergreen.V286.Thread.LastTypedAt Evergreen.V286.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId) Evergreen.V286.Thread.BackendThread
    , goMatches : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId) ( Evergreen.V286.Go.ValidatedSetup, Array.Array Evergreen.V286.Go.ActionWithTime )
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V286.Drawing.Drawing (Evergreen.V286.Id.Id Evergreen.V286.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V286.Message.Message Evergreen.V286.Id.ChannelMessageId (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId) (Evergreen.V286.Thread.LastTypedAt Evergreen.V286.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V286.OneToOne.OneToOne (Evergreen.V286.Discord.Id Evergreen.V286.Discord.MessageId) (Evergreen.V286.Id.Id Evergreen.V286.Id.ChannelMessageId)
    , members :
        Evergreen.V286.NonemptyDict.NonemptyDict
            (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V286.Drawing.Drawing (Evergreen.V286.Discord.Id Evergreen.V286.Discord.UserId))
    }
