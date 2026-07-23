module Evergreen.V333.DmChannel exposing (..)

import Date
import Evergreen.V333.Discord
import Evergreen.V333.Drawing
import Evergreen.V333.Game
import Evergreen.V333.Id
import Evergreen.V333.IdArray
import Evergreen.V333.Message
import Evergreen.V333.NonemptyDict
import Evergreen.V333.OneToOne
import Evergreen.V333.Thread
import Evergreen.V333.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V333.IdArray.IdArray Evergreen.V333.Id.ChannelMessageId (Evergreen.V333.Message.MessageState Evergreen.V333.Id.ChannelMessageId (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId))
    , visibleMessages : Evergreen.V333.VisibleMessages.VisibleMessages Evergreen.V333.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) (Evergreen.V333.Thread.LastTypedAt Evergreen.V333.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId) Evergreen.V333.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId) Evergreen.V333.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V333.Drawing.Drawing (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V333.IdArray.IdArray Evergreen.V333.Id.ChannelMessageId (Evergreen.V333.Message.MessageState Evergreen.V333.Id.ChannelMessageId (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId))
    , visibleMessages : Evergreen.V333.VisibleMessages.VisibleMessages Evergreen.V333.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) (Evergreen.V333.Thread.LastTypedAt Evergreen.V333.Id.ChannelMessageId)
    , members :
        Evergreen.V333.NonemptyDict.NonemptyDict
            (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V333.Drawing.Drawing (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V333.IdArray.IdArray Evergreen.V333.Id.ChannelMessageId (Evergreen.V333.Message.Message Evergreen.V333.Id.ChannelMessageId (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) (Evergreen.V333.Thread.LastTypedAt Evergreen.V333.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId) Evergreen.V333.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId) Evergreen.V333.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V333.Drawing.Drawing (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V333.IdArray.IdArray Evergreen.V333.Id.ChannelMessageId (Evergreen.V333.Message.Message Evergreen.V333.Id.ChannelMessageId (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId) (Evergreen.V333.Thread.LastTypedAt Evergreen.V333.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V333.OneToOne.OneToOne (Evergreen.V333.Discord.Id Evergreen.V333.Discord.MessageId) (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId)
    , members :
        Evergreen.V333.NonemptyDict.NonemptyDict
            (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V333.Drawing.Drawing (Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId))
    }
