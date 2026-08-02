module Evergreen.V343.DmChannel exposing (..)

import Date
import Evergreen.V343.Discord
import Evergreen.V343.Drawing
import Evergreen.V343.Game
import Evergreen.V343.Id
import Evergreen.V343.IdArray
import Evergreen.V343.Message
import Evergreen.V343.MessageArray
import Evergreen.V343.NonemptyDict
import Evergreen.V343.OneToOne
import Evergreen.V343.Thread
import Evergreen.V343.VisibleMessages
import SeqDict


type alias FrontendDmChannel =
    { messages : Evergreen.V343.MessageArray.MessageArray Evergreen.V343.Id.ChannelMessageId (Evergreen.V343.Message.Message Evergreen.V343.Id.ChannelMessageId (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId))
    , visibleMessages : Evergreen.V343.VisibleMessages.VisibleMessages Evergreen.V343.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) (Evergreen.V343.Thread.LastTypedAt Evergreen.V343.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) Evergreen.V343.Thread.FrontendThread
    , games : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) Evergreen.V343.Game.MatchData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V343.Drawing.Drawing (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId))
    }


type alias DiscordFrontendDmChannel =
    { messages : Evergreen.V343.MessageArray.MessageArray Evergreen.V343.Id.ChannelMessageId (Evergreen.V343.Message.Message Evergreen.V343.Id.ChannelMessageId (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId))
    , visibleMessages : Evergreen.V343.VisibleMessages.VisibleMessages Evergreen.V343.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) (Evergreen.V343.Thread.LastTypedAt Evergreen.V343.Id.ChannelMessageId)
    , members :
        Evergreen.V343.NonemptyDict.NonemptyDict
            (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V343.Drawing.Drawing (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId))
    }


type alias DmChannel =
    { messages : Evergreen.V343.IdArray.IdArray Evergreen.V343.Id.ChannelMessageId (Evergreen.V343.Message.Message Evergreen.V343.Id.ChannelMessageId (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) (Evergreen.V343.Thread.LastTypedAt Evergreen.V343.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) Evergreen.V343.Thread.BackendThread
    , games : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) Evergreen.V343.Game.BackendGameData
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V343.Drawing.Drawing (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId))
    }


type alias DiscordDmChannel =
    { messages : Evergreen.V343.IdArray.IdArray Evergreen.V343.Id.ChannelMessageId (Evergreen.V343.Message.Message Evergreen.V343.Id.ChannelMessageId (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId) (Evergreen.V343.Thread.LastTypedAt Evergreen.V343.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V343.OneToOne.OneToOne (Evergreen.V343.Discord.Id Evergreen.V343.Discord.MessageId) (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId)
    , members :
        Evergreen.V343.NonemptyDict.NonemptyDict
            (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId)
            { messagesSent : Int
            }
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V343.Drawing.Drawing (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId))
    }
