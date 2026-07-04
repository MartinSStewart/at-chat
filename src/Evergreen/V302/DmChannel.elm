module Evergreen.V302.DmChannel exposing (..)

import Date
import Evergreen.V302.Discord
import Evergreen.V302.Drawing
import Evergreen.V302.Game
import Evergreen.V302.Id
import Evergreen.V302.IdArray
import Evergreen.V302.Message
import Evergreen.V302.NonemptyDict
import Evergreen.V302.OneToOne
import Evergreen.V302.Thread
import Evergreen.V302.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId)


type alias FrontendDmChannel =
    { messages : Evergreen.V302.IdArray.IdArray Evergreen.V302.Id.ChannelMessageId (Evergreen.V302.Message.MessageState Evergreen.V302.Id.ChannelMessageId (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId))
    , visibleMessages : Evergreen.V302.VisibleMessages.VisibleMessages Evergreen.V302.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) (Evergreen.V302.Thread.LastTypedAt Evergreen.V302.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId) Evergreen.V302.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId) Evergreen.V302.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V302.Drawing.Drawing (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V302.IdArray.IdArray Evergreen.V302.Id.ChannelMessageId (Evergreen.V302.Message.MessageState Evergreen.V302.Id.ChannelMessageId (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId))
    , visibleMessages : Evergreen.V302.VisibleMessages.VisibleMessages Evergreen.V302.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) (Evergreen.V302.Thread.LastTypedAt Evergreen.V302.Id.ChannelMessageId)
    , members :
        Evergreen.V302.NonemptyDict.NonemptyDict
            (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V302.Drawing.Drawing (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V302.IdArray.IdArray Evergreen.V302.Id.ChannelMessageId (Evergreen.V302.Message.Message Evergreen.V302.Id.ChannelMessageId (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId) (Evergreen.V302.Thread.LastTypedAt Evergreen.V302.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId) Evergreen.V302.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId) Evergreen.V302.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V302.Drawing.Drawing (Evergreen.V302.Id.Id Evergreen.V302.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V302.IdArray.IdArray Evergreen.V302.Id.ChannelMessageId (Evergreen.V302.Message.Message Evergreen.V302.Id.ChannelMessageId (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId) (Evergreen.V302.Thread.LastTypedAt Evergreen.V302.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V302.OneToOne.OneToOne (Evergreen.V302.Discord.Id Evergreen.V302.Discord.MessageId) (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId)
    , members :
        Evergreen.V302.NonemptyDict.NonemptyDict
            (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V302.Drawing.Drawing (Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId))
    }
