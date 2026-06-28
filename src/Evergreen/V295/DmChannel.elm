module Evergreen.V295.DmChannel exposing (..)

import Date
import Evergreen.V295.Discord
import Evergreen.V295.Drawing
import Evergreen.V295.Game
import Evergreen.V295.Id
import Evergreen.V295.IdArray
import Evergreen.V295.Message
import Evergreen.V295.NonemptyDict
import Evergreen.V295.OneToOne
import Evergreen.V295.Thread
import Evergreen.V295.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId)


type alias FrontendDmChannel =
    { messages : Evergreen.V295.IdArray.IdArray Evergreen.V295.Id.ChannelMessageId (Evergreen.V295.Message.MessageState Evergreen.V295.Id.ChannelMessageId (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId))
    , visibleMessages : Evergreen.V295.VisibleMessages.VisibleMessages Evergreen.V295.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) (Evergreen.V295.Thread.LastTypedAt Evergreen.V295.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId) Evergreen.V295.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId) Evergreen.V295.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V295.Drawing.Drawing (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V295.IdArray.IdArray Evergreen.V295.Id.ChannelMessageId (Evergreen.V295.Message.MessageState Evergreen.V295.Id.ChannelMessageId (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId))
    , visibleMessages : Evergreen.V295.VisibleMessages.VisibleMessages Evergreen.V295.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) (Evergreen.V295.Thread.LastTypedAt Evergreen.V295.Id.ChannelMessageId)
    , members :
        Evergreen.V295.NonemptyDict.NonemptyDict
            (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V295.Drawing.Drawing (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V295.IdArray.IdArray Evergreen.V295.Id.ChannelMessageId (Evergreen.V295.Message.Message Evergreen.V295.Id.ChannelMessageId (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) (Evergreen.V295.Thread.LastTypedAt Evergreen.V295.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId) Evergreen.V295.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId) Evergreen.V295.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V295.Drawing.Drawing (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V295.IdArray.IdArray Evergreen.V295.Id.ChannelMessageId (Evergreen.V295.Message.Message Evergreen.V295.Id.ChannelMessageId (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId) (Evergreen.V295.Thread.LastTypedAt Evergreen.V295.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V295.OneToOne.OneToOne (Evergreen.V295.Discord.Id Evergreen.V295.Discord.MessageId) (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId)
    , members :
        Evergreen.V295.NonemptyDict.NonemptyDict
            (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V295.Drawing.Drawing (Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId))
    }
