module Evergreen.V340.DmChannel exposing (..)

import Date
import Evergreen.V340.Discord
import Evergreen.V340.Drawing
import Evergreen.V340.Game
import Evergreen.V340.Id
import Evergreen.V340.IdArray
import Evergreen.V340.Message
import Evergreen.V340.MessageArray
import Evergreen.V340.NonemptyDict
import Evergreen.V340.OneToOne
import Evergreen.V340.Thread
import Evergreen.V340.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V340.MessageArray.MessageArray Evergreen.V340.Id.ChannelMessageId (Evergreen.V340.Message.Message Evergreen.V340.Id.ChannelMessageId (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId))
    , visibleMessages : Evergreen.V340.VisibleMessages.VisibleMessages Evergreen.V340.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) (Evergreen.V340.Thread.LastTypedAt Evergreen.V340.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) Evergreen.V340.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) Evergreen.V340.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V340.Drawing.Drawing (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V340.MessageArray.MessageArray Evergreen.V340.Id.ChannelMessageId (Evergreen.V340.Message.Message Evergreen.V340.Id.ChannelMessageId (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId))
    , visibleMessages : Evergreen.V340.VisibleMessages.VisibleMessages Evergreen.V340.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Evergreen.V340.Thread.LastTypedAt Evergreen.V340.Id.ChannelMessageId)
    , members :
        Evergreen.V340.NonemptyDict.NonemptyDict
            (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V340.Drawing.Drawing (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V340.IdArray.IdArray Evergreen.V340.Id.ChannelMessageId (Evergreen.V340.Message.Message Evergreen.V340.Id.ChannelMessageId (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) (Evergreen.V340.Thread.LastTypedAt Evergreen.V340.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) Evergreen.V340.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) Evergreen.V340.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V340.Drawing.Drawing (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V340.IdArray.IdArray Evergreen.V340.Id.ChannelMessageId (Evergreen.V340.Message.Message Evergreen.V340.Id.ChannelMessageId (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId) (Evergreen.V340.Thread.LastTypedAt Evergreen.V340.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V340.OneToOne.OneToOne (Evergreen.V340.Discord.Id Evergreen.V340.Discord.MessageId) (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId)
    , members :
        Evergreen.V340.NonemptyDict.NonemptyDict
            (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V340.Drawing.Drawing (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId))
    }
