module Evergreen.V299.DmChannel exposing (..)

import Date
import Evergreen.V299.Discord
import Evergreen.V299.Drawing
import Evergreen.V299.Game
import Evergreen.V299.Id
import Evergreen.V299.IdArray
import Evergreen.V299.Message
import Evergreen.V299.NonemptyDict
import Evergreen.V299.OneToOne
import Evergreen.V299.Thread
import Evergreen.V299.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId)


type alias FrontendDmChannel =
    { messages : Evergreen.V299.IdArray.IdArray Evergreen.V299.Id.ChannelMessageId (Evergreen.V299.Message.MessageState Evergreen.V299.Id.ChannelMessageId (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId))
    , visibleMessages : Evergreen.V299.VisibleMessages.VisibleMessages Evergreen.V299.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) (Evergreen.V299.Thread.LastTypedAt Evergreen.V299.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId) Evergreen.V299.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId) Evergreen.V299.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V299.Drawing.Drawing (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V299.IdArray.IdArray Evergreen.V299.Id.ChannelMessageId (Evergreen.V299.Message.MessageState Evergreen.V299.Id.ChannelMessageId (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId))
    , visibleMessages : Evergreen.V299.VisibleMessages.VisibleMessages Evergreen.V299.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) (Evergreen.V299.Thread.LastTypedAt Evergreen.V299.Id.ChannelMessageId)
    , members :
        Evergreen.V299.NonemptyDict.NonemptyDict
            (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V299.Drawing.Drawing (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V299.IdArray.IdArray Evergreen.V299.Id.ChannelMessageId (Evergreen.V299.Message.Message Evergreen.V299.Id.ChannelMessageId (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) (Evergreen.V299.Thread.LastTypedAt Evergreen.V299.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId) Evergreen.V299.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId) Evergreen.V299.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V299.Drawing.Drawing (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V299.IdArray.IdArray Evergreen.V299.Id.ChannelMessageId (Evergreen.V299.Message.Message Evergreen.V299.Id.ChannelMessageId (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId) (Evergreen.V299.Thread.LastTypedAt Evergreen.V299.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V299.OneToOne.OneToOne (Evergreen.V299.Discord.Id Evergreen.V299.Discord.MessageId) (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId)
    , members :
        Evergreen.V299.NonemptyDict.NonemptyDict
            (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V299.Drawing.Drawing (Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId))
    }
