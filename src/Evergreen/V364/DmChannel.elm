module Evergreen.V364.DmChannel exposing (..)

import Date
import Evergreen.V364.Discord
import Evergreen.V364.Drawing
import Evergreen.V364.Game
import Evergreen.V364.Id
import Evergreen.V364.IdArray
import Evergreen.V364.Message
import Evergreen.V364.MessageArray
import Evergreen.V364.NonemptyDict
import Evergreen.V364.OneToOne
import Evergreen.V364.Thread
import Evergreen.V364.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V364.MessageArray.MessageArray Evergreen.V364.Id.ChannelMessageId (Evergreen.V364.Message.Message Evergreen.V364.Id.ChannelMessageId (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId))
    , visibleMessages : Evergreen.V364.VisibleMessages.VisibleMessages Evergreen.V364.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) (Evergreen.V364.Thread.LastTypedAt Evergreen.V364.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) Evergreen.V364.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) Evergreen.V364.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V364.Drawing.Drawing (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V364.MessageArray.MessageArray Evergreen.V364.Id.ChannelMessageId (Evergreen.V364.Message.Message Evergreen.V364.Id.ChannelMessageId (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId))
    , visibleMessages : Evergreen.V364.VisibleMessages.VisibleMessages Evergreen.V364.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Evergreen.V364.Thread.LastTypedAt Evergreen.V364.Id.ChannelMessageId)
    , members :
        Evergreen.V364.NonemptyDict.NonemptyDict
            (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V364.Drawing.Drawing (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V364.IdArray.IdArray Evergreen.V364.Id.ChannelMessageId (Evergreen.V364.Message.Message Evergreen.V364.Id.ChannelMessageId (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) (Evergreen.V364.Thread.LastTypedAt Evergreen.V364.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) Evergreen.V364.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) Evergreen.V364.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V364.Drawing.Drawing (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V364.IdArray.IdArray Evergreen.V364.Id.ChannelMessageId (Evergreen.V364.Message.Message Evergreen.V364.Id.ChannelMessageId (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId) (Evergreen.V364.Thread.LastTypedAt Evergreen.V364.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V364.OneToOne.OneToOne (Evergreen.V364.Discord.Id Evergreen.V364.Discord.MessageId) (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId)
    , members :
        Evergreen.V364.NonemptyDict.NonemptyDict
            (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V364.Drawing.Drawing (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId))
    }
