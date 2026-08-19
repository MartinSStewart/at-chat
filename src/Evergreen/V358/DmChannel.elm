module Evergreen.V358.DmChannel exposing (..)

import Date
import Evergreen.V358.Discord
import Evergreen.V358.Drawing
import Evergreen.V358.Game
import Evergreen.V358.Id
import Evergreen.V358.IdArray
import Evergreen.V358.Message
import Evergreen.V358.MessageArray
import Evergreen.V358.NonemptyDict
import Evergreen.V358.OneToOne
import Evergreen.V358.Thread
import Evergreen.V358.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V358.MessageArray.MessageArray Evergreen.V358.Id.ChannelMessageId (Evergreen.V358.Message.Message Evergreen.V358.Id.ChannelMessageId (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId))
    , visibleMessages : Evergreen.V358.VisibleMessages.VisibleMessages Evergreen.V358.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) (Evergreen.V358.Thread.LastTypedAt Evergreen.V358.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) Evergreen.V358.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) Evergreen.V358.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V358.Drawing.Drawing (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V358.MessageArray.MessageArray Evergreen.V358.Id.ChannelMessageId (Evergreen.V358.Message.Message Evergreen.V358.Id.ChannelMessageId (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId))
    , visibleMessages : Evergreen.V358.VisibleMessages.VisibleMessages Evergreen.V358.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Evergreen.V358.Thread.LastTypedAt Evergreen.V358.Id.ChannelMessageId)
    , members :
        Evergreen.V358.NonemptyDict.NonemptyDict
            (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V358.Drawing.Drawing (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V358.IdArray.IdArray Evergreen.V358.Id.ChannelMessageId (Evergreen.V358.Message.Message Evergreen.V358.Id.ChannelMessageId (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) (Evergreen.V358.Thread.LastTypedAt Evergreen.V358.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) Evergreen.V358.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) Evergreen.V358.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V358.Drawing.Drawing (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V358.IdArray.IdArray Evergreen.V358.Id.ChannelMessageId (Evergreen.V358.Message.Message Evergreen.V358.Id.ChannelMessageId (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId) (Evergreen.V358.Thread.LastTypedAt Evergreen.V358.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V358.OneToOne.OneToOne (Evergreen.V358.Discord.Id Evergreen.V358.Discord.MessageId) (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId)
    , members :
        Evergreen.V358.NonemptyDict.NonemptyDict
            (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V358.Drawing.Drawing (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId))
    }
