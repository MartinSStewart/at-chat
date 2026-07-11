module Evergreen.V312.DmChannel exposing (..)

import Date
import Evergreen.V312.Discord
import Evergreen.V312.Drawing
import Evergreen.V312.Game
import Evergreen.V312.Id
import Evergreen.V312.IdArray
import Evergreen.V312.Message
import Evergreen.V312.NonemptyDict
import Evergreen.V312.OneToOne
import Evergreen.V312.Thread
import Evergreen.V312.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V312.IdArray.IdArray Evergreen.V312.Id.ChannelMessageId (Evergreen.V312.Message.MessageState Evergreen.V312.Id.ChannelMessageId (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId))
    , visibleMessages : Evergreen.V312.VisibleMessages.VisibleMessages Evergreen.V312.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) (Evergreen.V312.Thread.LastTypedAt Evergreen.V312.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId) Evergreen.V312.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId) Evergreen.V312.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V312.Drawing.Drawing (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V312.IdArray.IdArray Evergreen.V312.Id.ChannelMessageId (Evergreen.V312.Message.MessageState Evergreen.V312.Id.ChannelMessageId (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId))
    , visibleMessages : Evergreen.V312.VisibleMessages.VisibleMessages Evergreen.V312.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) (Evergreen.V312.Thread.LastTypedAt Evergreen.V312.Id.ChannelMessageId)
    , members :
        Evergreen.V312.NonemptyDict.NonemptyDict
            (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V312.Drawing.Drawing (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V312.IdArray.IdArray Evergreen.V312.Id.ChannelMessageId (Evergreen.V312.Message.Message Evergreen.V312.Id.ChannelMessageId (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) (Evergreen.V312.Thread.LastTypedAt Evergreen.V312.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId) Evergreen.V312.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId) Evergreen.V312.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V312.Drawing.Drawing (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V312.IdArray.IdArray Evergreen.V312.Id.ChannelMessageId (Evergreen.V312.Message.Message Evergreen.V312.Id.ChannelMessageId (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId) (Evergreen.V312.Thread.LastTypedAt Evergreen.V312.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V312.OneToOne.OneToOne (Evergreen.V312.Discord.Id Evergreen.V312.Discord.MessageId) (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId)
    , members :
        Evergreen.V312.NonemptyDict.NonemptyDict
            (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V312.Drawing.Drawing (Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId))
    }
