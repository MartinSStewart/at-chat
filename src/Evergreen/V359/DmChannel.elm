module Evergreen.V359.DmChannel exposing (..)

import Date
import Evergreen.V359.Discord
import Evergreen.V359.Drawing
import Evergreen.V359.Game
import Evergreen.V359.Id
import Evergreen.V359.IdArray
import Evergreen.V359.Message
import Evergreen.V359.MessageArray
import Evergreen.V359.NonemptyDict
import Evergreen.V359.OneToOne
import Evergreen.V359.Thread
import Evergreen.V359.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V359.MessageArray.MessageArray Evergreen.V359.Id.ChannelMessageId (Evergreen.V359.Message.Message Evergreen.V359.Id.ChannelMessageId (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId))
    , visibleMessages : Evergreen.V359.VisibleMessages.VisibleMessages Evergreen.V359.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId) (Evergreen.V359.Thread.LastTypedAt Evergreen.V359.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId) Evergreen.V359.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId) Evergreen.V359.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V359.Drawing.Drawing (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V359.MessageArray.MessageArray Evergreen.V359.Id.ChannelMessageId (Evergreen.V359.Message.Message Evergreen.V359.Id.ChannelMessageId (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId))
    , visibleMessages : Evergreen.V359.VisibleMessages.VisibleMessages Evergreen.V359.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (Evergreen.V359.Thread.LastTypedAt Evergreen.V359.Id.ChannelMessageId)
    , members :
        Evergreen.V359.NonemptyDict.NonemptyDict
            (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V359.Drawing.Drawing (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V359.IdArray.IdArray Evergreen.V359.Id.ChannelMessageId (Evergreen.V359.Message.Message Evergreen.V359.Id.ChannelMessageId (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId) (Evergreen.V359.Thread.LastTypedAt Evergreen.V359.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId) Evergreen.V359.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId) Evergreen.V359.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V359.Drawing.Drawing (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V359.IdArray.IdArray Evergreen.V359.Id.ChannelMessageId (Evergreen.V359.Message.Message Evergreen.V359.Id.ChannelMessageId (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId) (Evergreen.V359.Thread.LastTypedAt Evergreen.V359.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V359.OneToOne.OneToOne (Evergreen.V359.Discord.Id Evergreen.V359.Discord.MessageId) (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId)
    , members :
        Evergreen.V359.NonemptyDict.NonemptyDict
            (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V359.Drawing.Drawing (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId))
    }
