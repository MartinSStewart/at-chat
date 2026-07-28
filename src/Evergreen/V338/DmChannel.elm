module Evergreen.V338.DmChannel exposing (..)

import Date
import Evergreen.V338.Discord
import Evergreen.V338.Drawing
import Evergreen.V338.Game
import Evergreen.V338.Id
import Evergreen.V338.IdArray
import Evergreen.V338.Message
import Evergreen.V338.MessageArray
import Evergreen.V338.NonemptyDict
import Evergreen.V338.OneToOne
import Evergreen.V338.Thread
import Evergreen.V338.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V338.MessageArray.MessageArray Evergreen.V338.Id.ChannelMessageId (Evergreen.V338.Message.Message Evergreen.V338.Id.ChannelMessageId (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId))
    , visibleMessages : Evergreen.V338.VisibleMessages.VisibleMessages Evergreen.V338.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) (Evergreen.V338.Thread.LastTypedAt Evergreen.V338.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId) Evergreen.V338.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId) Evergreen.V338.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V338.Drawing.Drawing (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V338.MessageArray.MessageArray Evergreen.V338.Id.ChannelMessageId (Evergreen.V338.Message.Message Evergreen.V338.Id.ChannelMessageId (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId))
    , visibleMessages : Evergreen.V338.VisibleMessages.VisibleMessages Evergreen.V338.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) (Evergreen.V338.Thread.LastTypedAt Evergreen.V338.Id.ChannelMessageId)
    , members :
        Evergreen.V338.NonemptyDict.NonemptyDict
            (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V338.Drawing.Drawing (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V338.IdArray.IdArray Evergreen.V338.Id.ChannelMessageId (Evergreen.V338.Message.Message Evergreen.V338.Id.ChannelMessageId (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) (Evergreen.V338.Thread.LastTypedAt Evergreen.V338.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId) Evergreen.V338.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId) Evergreen.V338.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V338.Drawing.Drawing (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V338.IdArray.IdArray Evergreen.V338.Id.ChannelMessageId (Evergreen.V338.Message.Message Evergreen.V338.Id.ChannelMessageId (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId) (Evergreen.V338.Thread.LastTypedAt Evergreen.V338.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V338.OneToOne.OneToOne (Evergreen.V338.Discord.Id Evergreen.V338.Discord.MessageId) (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId)
    , members :
        Evergreen.V338.NonemptyDict.NonemptyDict
            (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V338.Drawing.Drawing (Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId))
    }
