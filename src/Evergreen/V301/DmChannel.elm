module Evergreen.V301.DmChannel exposing (..)

import Date
import Evergreen.V301.Discord
import Evergreen.V301.Drawing
import Evergreen.V301.Game
import Evergreen.V301.Id
import Evergreen.V301.IdArray
import Evergreen.V301.Message
import Evergreen.V301.NonemptyDict
import Evergreen.V301.OneToOne
import Evergreen.V301.Thread
import Evergreen.V301.VisibleMessages
import SeqDict


type DmChannelId
    = DmChannelId (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId) (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId)


type alias FrontendDmChannel =
    { messages : Evergreen.V301.IdArray.IdArray Evergreen.V301.Id.ChannelMessageId (Evergreen.V301.Message.MessageState Evergreen.V301.Id.ChannelMessageId (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId))
    , visibleMessages : Evergreen.V301.VisibleMessages.VisibleMessages Evergreen.V301.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId) (Evergreen.V301.Thread.LastTypedAt Evergreen.V301.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId) Evergreen.V301.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId) Evergreen.V301.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V301.Drawing.Drawing (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V301.IdArray.IdArray Evergreen.V301.Id.ChannelMessageId (Evergreen.V301.Message.MessageState Evergreen.V301.Id.ChannelMessageId (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId))
    , visibleMessages : Evergreen.V301.VisibleMessages.VisibleMessages Evergreen.V301.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) (Evergreen.V301.Thread.LastTypedAt Evergreen.V301.Id.ChannelMessageId)
    , members :
        Evergreen.V301.NonemptyDict.NonemptyDict
            (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V301.Drawing.Drawing (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V301.IdArray.IdArray Evergreen.V301.Id.ChannelMessageId (Evergreen.V301.Message.Message Evergreen.V301.Id.ChannelMessageId (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId) (Evergreen.V301.Thread.LastTypedAt Evergreen.V301.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId) Evergreen.V301.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId) Evergreen.V301.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V301.Drawing.Drawing (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V301.IdArray.IdArray Evergreen.V301.Id.ChannelMessageId (Evergreen.V301.Message.Message Evergreen.V301.Id.ChannelMessageId (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId) (Evergreen.V301.Thread.LastTypedAt Evergreen.V301.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V301.OneToOne.OneToOne (Evergreen.V301.Discord.Id Evergreen.V301.Discord.MessageId) (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId)
    , members :
        Evergreen.V301.NonemptyDict.NonemptyDict
            (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V301.Drawing.Drawing (Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId))
    }
