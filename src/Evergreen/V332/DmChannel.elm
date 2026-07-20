module Evergreen.V332.DmChannel exposing (..)

import Date
import Evergreen.V332.Discord
import Evergreen.V332.Drawing
import Evergreen.V332.Game
import Evergreen.V332.Id
import Evergreen.V332.IdArray
import Evergreen.V332.Message
import Evergreen.V332.NonemptyDict
import Evergreen.V332.OneToOne
import Evergreen.V332.Thread
import Evergreen.V332.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V332.IdArray.IdArray Evergreen.V332.Id.ChannelMessageId (Evergreen.V332.Message.MessageState Evergreen.V332.Id.ChannelMessageId (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId))
    , visibleMessages : Evergreen.V332.VisibleMessages.VisibleMessages Evergreen.V332.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) (Evergreen.V332.Thread.LastTypedAt Evergreen.V332.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId) Evergreen.V332.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId) Evergreen.V332.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V332.Drawing.Drawing (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V332.IdArray.IdArray Evergreen.V332.Id.ChannelMessageId (Evergreen.V332.Message.MessageState Evergreen.V332.Id.ChannelMessageId (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId))
    , visibleMessages : Evergreen.V332.VisibleMessages.VisibleMessages Evergreen.V332.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) (Evergreen.V332.Thread.LastTypedAt Evergreen.V332.Id.ChannelMessageId)
    , members :
        Evergreen.V332.NonemptyDict.NonemptyDict
            (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V332.Drawing.Drawing (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V332.IdArray.IdArray Evergreen.V332.Id.ChannelMessageId (Evergreen.V332.Message.Message Evergreen.V332.Id.ChannelMessageId (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) (Evergreen.V332.Thread.LastTypedAt Evergreen.V332.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId) Evergreen.V332.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId) Evergreen.V332.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V332.Drawing.Drawing (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V332.IdArray.IdArray Evergreen.V332.Id.ChannelMessageId (Evergreen.V332.Message.Message Evergreen.V332.Id.ChannelMessageId (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId) (Evergreen.V332.Thread.LastTypedAt Evergreen.V332.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V332.OneToOne.OneToOne (Evergreen.V332.Discord.Id Evergreen.V332.Discord.MessageId) (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId)
    , members :
        Evergreen.V332.NonemptyDict.NonemptyDict
            (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V332.Drawing.Drawing (Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId))
    }
