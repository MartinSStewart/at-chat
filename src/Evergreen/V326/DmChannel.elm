module Evergreen.V326.DmChannel exposing (..)

import Date
import Evergreen.V326.Discord
import Evergreen.V326.Drawing
import Evergreen.V326.Game
import Evergreen.V326.Id
import Evergreen.V326.IdArray
import Evergreen.V326.Message
import Evergreen.V326.NonemptyDict
import Evergreen.V326.OneToOne
import Evergreen.V326.Thread
import Evergreen.V326.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V326.IdArray.IdArray Evergreen.V326.Id.ChannelMessageId (Evergreen.V326.Message.MessageState Evergreen.V326.Id.ChannelMessageId (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId))
    , visibleMessages : Evergreen.V326.VisibleMessages.VisibleMessages Evergreen.V326.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId) (Evergreen.V326.Thread.LastTypedAt Evergreen.V326.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId) Evergreen.V326.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId) Evergreen.V326.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V326.Drawing.Drawing (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V326.IdArray.IdArray Evergreen.V326.Id.ChannelMessageId (Evergreen.V326.Message.MessageState Evergreen.V326.Id.ChannelMessageId (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId))
    , visibleMessages : Evergreen.V326.VisibleMessages.VisibleMessages Evergreen.V326.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) (Evergreen.V326.Thread.LastTypedAt Evergreen.V326.Id.ChannelMessageId)
    , members :
        Evergreen.V326.NonemptyDict.NonemptyDict
            (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V326.Drawing.Drawing (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V326.IdArray.IdArray Evergreen.V326.Id.ChannelMessageId (Evergreen.V326.Message.Message Evergreen.V326.Id.ChannelMessageId (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId) (Evergreen.V326.Thread.LastTypedAt Evergreen.V326.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId) Evergreen.V326.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId) Evergreen.V326.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V326.Drawing.Drawing (Evergreen.V326.Id.Id Evergreen.V326.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V326.IdArray.IdArray Evergreen.V326.Id.ChannelMessageId (Evergreen.V326.Message.Message Evergreen.V326.Id.ChannelMessageId (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId) (Evergreen.V326.Thread.LastTypedAt Evergreen.V326.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V326.OneToOne.OneToOne (Evergreen.V326.Discord.Id Evergreen.V326.Discord.MessageId) (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId)
    , members :
        Evergreen.V326.NonemptyDict.NonemptyDict
            (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V326.Drawing.Drawing (Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId))
    }
