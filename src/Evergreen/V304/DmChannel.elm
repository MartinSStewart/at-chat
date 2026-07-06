module Evergreen.V304.DmChannel exposing (..)

import Date
import Evergreen.V304.Discord
import Evergreen.V304.Drawing
import Evergreen.V304.Game
import Evergreen.V304.Id
import Evergreen.V304.IdArray
import Evergreen.V304.Message
import Evergreen.V304.NonemptyDict
import Evergreen.V304.OneToOne
import Evergreen.V304.Thread
import Evergreen.V304.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V304.IdArray.IdArray Evergreen.V304.Id.ChannelMessageId (Evergreen.V304.Message.MessageState Evergreen.V304.Id.ChannelMessageId (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId))
    , visibleMessages : Evergreen.V304.VisibleMessages.VisibleMessages Evergreen.V304.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) (Evergreen.V304.Thread.LastTypedAt Evergreen.V304.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId) Evergreen.V304.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId) Evergreen.V304.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V304.Drawing.Drawing (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V304.IdArray.IdArray Evergreen.V304.Id.ChannelMessageId (Evergreen.V304.Message.MessageState Evergreen.V304.Id.ChannelMessageId (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId))
    , visibleMessages : Evergreen.V304.VisibleMessages.VisibleMessages Evergreen.V304.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) (Evergreen.V304.Thread.LastTypedAt Evergreen.V304.Id.ChannelMessageId)
    , members :
        Evergreen.V304.NonemptyDict.NonemptyDict
            (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V304.Drawing.Drawing (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V304.IdArray.IdArray Evergreen.V304.Id.ChannelMessageId (Evergreen.V304.Message.Message Evergreen.V304.Id.ChannelMessageId (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId) (Evergreen.V304.Thread.LastTypedAt Evergreen.V304.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId) Evergreen.V304.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId) Evergreen.V304.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V304.Drawing.Drawing (Evergreen.V304.Id.Id Evergreen.V304.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V304.IdArray.IdArray Evergreen.V304.Id.ChannelMessageId (Evergreen.V304.Message.Message Evergreen.V304.Id.ChannelMessageId (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId) (Evergreen.V304.Thread.LastTypedAt Evergreen.V304.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V304.OneToOne.OneToOne (Evergreen.V304.Discord.Id Evergreen.V304.Discord.MessageId) (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId)
    , members :
        Evergreen.V304.NonemptyDict.NonemptyDict
            (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V304.Drawing.Drawing (Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId))
    }
