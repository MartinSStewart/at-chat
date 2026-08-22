module Evergreen.V360.DmChannel exposing (..)

import Date
import Evergreen.V360.Discord
import Evergreen.V360.Drawing
import Evergreen.V360.Game
import Evergreen.V360.Id
import Evergreen.V360.IdArray
import Evergreen.V360.Message
import Evergreen.V360.MessageArray
import Evergreen.V360.NonemptyDict
import Evergreen.V360.OneToOne
import Evergreen.V360.Thread
import Evergreen.V360.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V360.MessageArray.MessageArray Evergreen.V360.Id.ChannelMessageId (Evergreen.V360.Message.Message Evergreen.V360.Id.ChannelMessageId (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId))
    , visibleMessages : Evergreen.V360.VisibleMessages.VisibleMessages Evergreen.V360.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) (Evergreen.V360.Thread.LastTypedAt Evergreen.V360.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) Evergreen.V360.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) Evergreen.V360.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V360.Drawing.Drawing (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V360.MessageArray.MessageArray Evergreen.V360.Id.ChannelMessageId (Evergreen.V360.Message.Message Evergreen.V360.Id.ChannelMessageId (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId))
    , visibleMessages : Evergreen.V360.VisibleMessages.VisibleMessages Evergreen.V360.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Evergreen.V360.Thread.LastTypedAt Evergreen.V360.Id.ChannelMessageId)
    , members :
        Evergreen.V360.NonemptyDict.NonemptyDict
            (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V360.Drawing.Drawing (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V360.IdArray.IdArray Evergreen.V360.Id.ChannelMessageId (Evergreen.V360.Message.Message Evergreen.V360.Id.ChannelMessageId (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) (Evergreen.V360.Thread.LastTypedAt Evergreen.V360.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) Evergreen.V360.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) Evergreen.V360.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V360.Drawing.Drawing (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V360.IdArray.IdArray Evergreen.V360.Id.ChannelMessageId (Evergreen.V360.Message.Message Evergreen.V360.Id.ChannelMessageId (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId) (Evergreen.V360.Thread.LastTypedAt Evergreen.V360.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V360.OneToOne.OneToOne (Evergreen.V360.Discord.Id Evergreen.V360.Discord.MessageId) (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId)
    , members :
        Evergreen.V360.NonemptyDict.NonemptyDict
            (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V360.Drawing.Drawing (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId))
    }
