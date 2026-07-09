module Evergreen.V308.DmChannel exposing (..)

import Date
import Evergreen.V308.Discord
import Evergreen.V308.Drawing
import Evergreen.V308.Game
import Evergreen.V308.Id
import Evergreen.V308.IdArray
import Evergreen.V308.Message
import Evergreen.V308.NonemptyDict
import Evergreen.V308.OneToOne
import Evergreen.V308.Thread
import Evergreen.V308.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V308.IdArray.IdArray Evergreen.V308.Id.ChannelMessageId (Evergreen.V308.Message.MessageState Evergreen.V308.Id.ChannelMessageId (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId))
    , visibleMessages : Evergreen.V308.VisibleMessages.VisibleMessages Evergreen.V308.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) (Evergreen.V308.Thread.LastTypedAt Evergreen.V308.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId) Evergreen.V308.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId) Evergreen.V308.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V308.Drawing.Drawing (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V308.IdArray.IdArray Evergreen.V308.Id.ChannelMessageId (Evergreen.V308.Message.MessageState Evergreen.V308.Id.ChannelMessageId (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId))
    , visibleMessages : Evergreen.V308.VisibleMessages.VisibleMessages Evergreen.V308.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) (Evergreen.V308.Thread.LastTypedAt Evergreen.V308.Id.ChannelMessageId)
    , members :
        Evergreen.V308.NonemptyDict.NonemptyDict
            (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V308.Drawing.Drawing (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V308.IdArray.IdArray Evergreen.V308.Id.ChannelMessageId (Evergreen.V308.Message.Message Evergreen.V308.Id.ChannelMessageId (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) (Evergreen.V308.Thread.LastTypedAt Evergreen.V308.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId) Evergreen.V308.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId) Evergreen.V308.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V308.Drawing.Drawing (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V308.IdArray.IdArray Evergreen.V308.Id.ChannelMessageId (Evergreen.V308.Message.Message Evergreen.V308.Id.ChannelMessageId (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId) (Evergreen.V308.Thread.LastTypedAt Evergreen.V308.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V308.OneToOne.OneToOne (Evergreen.V308.Discord.Id Evergreen.V308.Discord.MessageId) (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId)
    , members :
        Evergreen.V308.NonemptyDict.NonemptyDict
            (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V308.Drawing.Drawing (Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId))
    }
